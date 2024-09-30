classdef Sankey < matlab.graphics.chartcontainer.ChartContainer
    %SANKEY The Sankey Diagram illustrates the flow between different
    %states.
    %
    % Copyright 2018-2022 The MathWorks, Inc.
    
    properties ( Dependent )
        % Directed graph representing diagram
        GraphData(1,1) digraph
        % Alignment of the nodes' labels
        LabelAlignment(1,1) string {mustBeMember(LabelAlignment,["left","right","top","bottom","center"])}
        % Display nodes' sizes
        LabelIncludeTotal(1,1) matlab.lang.OnOffSwitchState
        % Color of the links
        LinkColor
        % Curve type
        LinkType(1,1) string {mustBeMember(LinkType,["tanh","cos","vtanh","vcos","line"])}
        % Color of the nodes
        NodeColor
        % Vertical space between nodes
        NodePadRatio(1,1) double {mustBeNonnegative}
        % Width of node
        NodeWidth(1,1) double {mustBeNonnegative}
        % X-coordinate of nodes
        XNodeData(:,1) double {mustBeFinite}
        % Y-coordinate of nodes
        YNodeData(:,1) double {mustBeFinite}
    end % properties ( Dependent )
    
    properties
        % Transparency of link
        LinkAlpha(1,1) double {mustBeNonnegative,mustBeLessThanOrEqual(LinkAlpha,1)} = 0.5
        % Color of link's edge
        LinkEdgeColor = "black"
        % Style of link's edge
        LinkEdgeStyle(1,1) string {mustBeMember(LinkEdgeStyle,["-","--",":","-.","none"])} = "none"
        % Width of link's edge
        LinkEdgeWidth(1,1) double {mustBePositive} = 0.5
        % Size of font for link annotations
        LinkFontSize(1,1) double {mustBePositive} = 10
        % Transparancy of node
        NodeAlpha(1,1) double {mustBeNonnegative,mustBeLessThanOrEqual(NodeAlpha,1)} = 1
        % Color of node's edge
        NodeEdgeColor = "black"
        % Style of node's edge
        NodeEdgeStyle(1,1) string {mustBeMember(NodeEdgeStyle,["-","--",":","-.","none"])} = "-"
        % Width of node's edge
        NodeEdgeWidth(1,1) double {mustBePositive} = 0.5
        % Size of font for node labels
        NodeFontSize(1,1) double {mustBePositive} = 10
        % Visibility of the node labels.
        NodeLabelsVisible(1, 1) matlab.lang.OnOffSwitchState = "on"
    end % Public properties
    
    properties ( Access = private, Transient, NonCopyable )
        % Chart axes
        Axes(1, 1) matlab.graphics.axis.Axes
        % Graphic objects for the links' labels
        LinkLabels(:,1) = gobjects( 0, 1 )
        % Graphic objects for the links
        LinkPatches(:,1) = gobjects( 0, 1 )
        % Graphic objects for the nodes' labels
        NodeLabels(:,1) = gobjects( 0, 1 )
        % Graphic objects for the nodes
        NodePatches(:,1) = gobjects( 0, 1 )
    end % properties ( Access = private, Transient, NonCopyable )
    
    properties ( Access = private )
        ComputationRequired = false
        LabelAlignment_ = "right"
        LabelIncludeTotal_ = matlab.lang.OnOffSwitchState.off
        LinkColor_ = "source"
        LinkType_ = "cos"
        LinkCrossType_ = "normal"
        GraphData_ = digraph(  )
        NodeColor_ = zeros( 0, 3 )
        NodeHeight_ = zeros( 0, 1 )
        NodePadRatio_ = 0.05
        NodeSelected_ = false( 0, 1 )
        NodeWidth_ = 0.1
        XNodeData_ = zeros( 0, 1 )
        YNodeData_ = zeros( 0, 1 )
        YLinkData_ = zeros( 0, 1 )
    end % properties ( Access = private )
    
    properties ( Constant, Hidden )
        % Product dependencies.
        Dependencies = "MATLAB"
    end % properties ( Constant, Hidden )
    
    methods

        function set.LabelAlignment( obj, value )
            
            obj.LabelAlignment_ = value;
            nodeLabelUpdate( obj )
            
        end % set.LabelAlignment
        
        function value = get.LabelAlignment( obj )
            value = obj.LabelAlignment_;
        end % get.LabelAlignment
        
        function set.LabelIncludeTotal( obj, value )
            
            obj.LabelIncludeTotal_ = value;
            nodeLabelUpdate( obj )
            
        end % set.LabelIncludeTotal
        
        function value = get.LabelIncludeTotal( obj )
            value = obj.LabelIncludeTotal_;
        end % get.LabelIncludeTotal
        
        function set.LinkColor( obj, value )
            
            if (isstring( value ) || ischar( value )) && ismember( value, ["source", "target", "gradient"] )
                value = string( value );
            else
                value = validatecolor( value );
            end % if
            
            obj.ComputationRequired = true;
            
            obj.LinkColor_ = value;
            
        end % set.LinkColor
        
        function value = get.LinkColor( obj )
            value = obj.LinkColor_;
        end % get.LinkColor
        
        function set.LinkType( obj, value )
            
            obj.ComputationRequired = true;
            
            pat = "v";
            if startsWith( value, pat )
                obj.LinkType_ = extractBetween( value, pat, textBoundary( "end" ) );
                obj.LinkCrossType_ = "vertical";
            else
                obj.LinkType_ = value;
                obj.LinkCrossType_ = "normal";
            end % if
            
        end % set.LinkType
        
        function value = get.LinkType( obj )
            if strcmp( obj.LinkCrossType_, "vertical" )
                value = "v" + obj.LinkType_;
            else
                value = obj.LinkType_;
            end % if
        end % get.LinkType
        
        function set.GraphData( obj, value )
            
            obj.ComputationRequired = true;
            
            if ismultigraph( value ) || any( diag( adjacency( obj.GraphData_ ) ) )
                error( "Provided graph is not simple. Use simplify to remove multiple edges and self-loops." )
            end % if
            
            obj.GraphData_ = value;
            
            % Making sure weights are specified.
            if ~ismember( "Weight", obj.GraphData_.Edges.Properties.VariableNames )
                obj.GraphData_.Edges.Weight = ones( obj.GraphData_.numedges, 1 );
            end % if
            
            % Computing node flows
            A = adjacency( obj.GraphData_, "weighted" );
            inflow  = sum( A, 1 )';
            outflow = sum( A, 2 );
            
            src = inflow == 0;
            snk = outflow == 0;
            
            if ~isequal( inflow(~src & ~snk), outflow(~src & ~snk) )
                warning( "The provided graph is imbalanced" )
            end % if
            
            obj.NodeHeight_ = full( max( inflow, outflow ) );
            
            % Computing node and links coordinates
            nodeCoordinates( obj )
            
            % Setting node colors
            obj.NodeColor_ = lines( obj.GraphData_.numnodes );
            
            % Selection 
            obj.NodeSelected_ = false( obj.GraphData_.numnodes, 1 );
            
        end % set.GraphData
        
        function value = get.GraphData( obj )
             value = obj.GraphData_;
        end % get.GraphData
        
        function set.NodeColor( obj, value )
            
            nodeColor = validatecolor( value, "multiple" );
            validateattributes( nodeColor, "double", ...
                {"size", size( obj.NodeColor_ )} )
            
            obj.ComputationRequired = true;
            
            obj.NodeColor_ = nodeColor;
            
        end % set.NodeColor
        
        function value = get.NodeColor( obj )
            value = obj.NodeColor_;
        end % get.NodeColor
        
        function set.NodePadRatio( obj, value )
            
            obj.ComputationRequired = true;
            
            obj.NodePadRatio_ = value;
            nodeCoordinates( obj )
            
        end % set.NodePadRatio
        
        function value = get.NodePadRatio( obj )
            value = obj.NodePadRatio_;
        end % get.NodePadRatio
        
        function set.NodeWidth( obj, value )
            
            obj.ComputationRequired = true;
            
            obj.NodeWidth_ = value;
            
        end % set.NodeWidth
        
        function value = get.NodeWidth( obj )
            value = obj.NodeWidth_;
        end % get.NodeWidth
        
        function set.XNodeData( obj, value )
            
            validateattributes( value, "double", ...
                {"size", size( obj.XNodeData_ )} )
            
            obj.ComputationRequired = true;

            obj.XNodeData_ = value;
            
        end % set.XNodeData
        
        function value = get.XNodeData( obj )
             value = obj.XNodeData_;
        end % get.XNodeData
        
        function set.YNodeData( obj, value )
            
            validateattributes( value, "double", ...
                {"size", size( obj.YNodeData_ )} )
            
            obj.ComputationRequired = true;
            
            obj.YNodeData_ = value;
            
            % Recompute Link Coordinates
            linkCoordinates( obj )
            
        end % set.YNodeData
        
        function value = get.YNodeData( obj )
             value = obj.YNodeData_;
        end % get.YNodeData
        
    end % methods
    
    methods
        
        function varargout = title( obj, varargin )
            [varargout{1:nargout}] = title( obj.Axes, varargin{:} );
        end % title
        
    end % methods
    
    methods ( Access = private )
        
        function linkLabelUpdate( obj )
            
            nLabels  = obj.GraphData_.numedges;
            nCurrent = numel( obj.LinkLabels );
            if nLabels < nCurrent
                
                delete( obj.LinkLabels(nLabels+1:nCurrent) )
                obj.LinkLabels(nLabels+1:nCurrent) = [];
                
            elseif nLabels > nCurrent
                
                obj.LinkLabels(nCurrent+1:nLabels) = gobjects( nLabels - nCurrent, 1 );
                for eid = nCurrent+1:nLabels
                    obj.LinkLabels(eid) = text( "Parent", obj.Axes );
                end % for
                
            end % if
            
            for eid = 1:nLabels

                linkSource = obj.GraphData_.Edges.EndNodes(eid, 1);
                linkTarget = obj.GraphData_.Edges.EndNodes(eid, 2);
                linkHeight = obj.GraphData_.Edges.Weight(eid);

                linkText = [ sprintf( "Source: %s", string( linkSource ) ), ...
                             sprintf( "Target: %s", string( linkTarget ) ), ...
                             sprintf( "Weight: %g", linkHeight ) ];

                textX = mean( obj.LinkPatches(eid).XData );
                textY = mean( obj.LinkPatches(eid).YData );

                set( obj.LinkLabels(eid), ...
                    "Position", [textX, textY], ...
                    "String", linkText, ...
                    "HorizontalAlignment", "center", ...
                    "VerticalAlignment", "middle", ...
                    "BackgroundColor", [1, 1, 1, 0.25], ...
                    "Margin", 1, ...
                    "Visible", "off", ...
                    "Clipping", "on", ...
                    "Tag", "LinkLabel", ...
                    "ButtonDownFcn", @(~,~) linkButtonDown( obj, eid ) );
            end % for
        end % linkLabelUpdate
        
        function linkButtonDown( obj, id )
            set( obj.LinkLabels(id), ...
                "Visible", ~obj.LinkLabels(id).Visible )
        end % linkButtonDown
        
        function linkCoordinates( obj )
            
            % Computing link y-coordinates
            obj.YLinkData_ = zeros( obj.GraphData_.numedges, 2 );
            
            for nid = 1:obj.GraphData_.numnodes
                % Outbound links
                [eid, tid] = outedges( obj.GraphData_, nid );

                targetY = obj.YNodeData_(tid) + obj.NodeHeight_(tid)/2;
                [~, yOrdIdx] = sort( targetY );

                linkHeight = obj.GraphData_.Edges.Weight(eid(yOrdIdx));
                linkY = cumsum( linkHeight ) - linkHeight;

                obj.YLinkData_(eid(yOrdIdx), 1) = obj.YNodeData_(nid) + linkY;

                % Inbound links
                [eid, sid] = inedges( obj.GraphData_, nid );

                sourceY = obj.YNodeData_(sid) + obj.NodeHeight_(sid)/2;
                [~, yOrdIdx] = sort( sourceY );

                linkHeight = obj.GraphData_.Edges.Weight(eid(yOrdIdx));
                linkY = cumsum( linkHeight ) - linkHeight;

                obj.YLinkData_(eid(yOrdIdx), 2) = obj.YNodeData_(nid) + linkY;
            
            end % for
        end % linkCoordinates
        
        function linkUpdate( obj )
            
            nLinks   = obj.GraphData_.numedges;
            nCurrent = numel( obj.LinkPatches );
            if nLinks < nCurrent
                
                delete( obj.LinkPatches(nLinks+1:nCurrent) )
                obj.LinkPatches(nLinks+1:nCurrent) = [];
                
            elseif nLinks > nCurrent
                
                obj.LinkPatches(nCurrent+1:nLinks) = gobjects( nLinks - nCurrent, 1 );
                for eid = nCurrent+1:nLinks
                    obj.LinkPatches(eid) = patch( "Parent", obj.Axes );
                end % for
                
            end % if

            expand = @(x) reshape( x, [1, size( x )] );
            for eid = 1:nLinks

                linkSource = obj.GraphData_.Edges.EndNodes(eid, 1);
                linkTarget = obj.GraphData_.Edges.EndNodes(eid, 2);
                linkHeight = obj.GraphData_.Edges.Weight(eid);

                sid = findnode( obj.GraphData_, linkSource );
                tid = findnode( obj.GraphData_, linkTarget );

                sx = obj.XNodeData_(sid) + obj.NodeWidth_;
                sy = obj.YLinkData_(eid, 1);

                tx = obj.XNodeData_(tid);
                ty = obj.YLinkData_(eid, 2);
                
                [XX, YY, vColor] = wavyLink( [sx, sy], [tx, ty], ...
                    linkHeight, obj.Axes.DataAspectRatio, ...
                    obj.LinkType_, obj.LinkCrossType_ );

                if isscalar( obj.LinkColor_ )
                    switch obj.LinkColor_
                        case "source"
                            CC = expand( obj.NodeColor_(sid,:) );
                            fColor = "flat";
                        case "target"
                            CC = expand( obj.NodeColor_(tid,:) );
                            fColor = "flat";
                        case "gradient"
                            sColor = expand( obj.NodeColor_(sid,:) );
                            tColor = expand( obj.NodeColor_(tid,:) );
                            CC = (tColor - sColor) .* vColor + sColor;
                            fColor = "interp";
                    end % switch
                else
                    CC = expand( obj.LinkColor_ );
                    fColor = "flat";
                end % if
                
                set( obj.LinkPatches(eid), ... 
                    "XData", XX, ...
                    "YData", YY, ...
                    "CData", CC, ...
                    "FaceColor", fColor, ...
                    "FaceAlpha", obj.LinkAlpha, ...
                    "EdgeAlpha", obj.LinkAlpha, ...
                    "EdgeColor", obj.LinkEdgeColor, ...
                    "LineWidth", obj.LinkEdgeWidth, ...
                    "LineStyle", obj.LinkEdgeStyle, ...
                    "Tag", "Link", ...
                    "ButtonDownFcn", @(~,~) linkButtonDown( obj, eid ) );
            end % for
        end % linkUpdate
        
        function nodeLabelUpdate( obj )
            
            nLabels  = obj.GraphData_.numnodes;
            nCurrent = numel( obj.NodeLabels );
            if nLabels < nCurrent
                
                delete( obj.NodeLabels(nLabels+1:nCurrent) )
                obj.NodeLabels(nLabels+1:nCurrent) = [];
                
            elseif nLabels > nCurrent
                
                obj.NodeLabels(nCurrent+1:nLabels) = gobjects( nLabels - nCurrent, 1 );
                for nid = nCurrent+1:nLabels
                    obj.NodeLabels(nid) = text( "Parent", obj.Axes );
                end % for
                
            end % if
            
            A = adjacency( obj.GraphData_, "weighted" );
            inflow  = sum( A, 1 )';
            outflow = sum( A, 2 );
            
            for nid = 1:nLabels

                nx = obj.XNodeData_(nid);
                ny = obj.YNodeData_(nid);
                nw = obj.NodeWidth_;
                nh = obj.NodeHeight_(nid);

                if ismember( "Name", obj.GraphData_.Nodes.Properties.VariableNames )
                    ns = string( obj.GraphData_.Nodes.Name(nid) );
                else
                    ns = string( nid );
                end % if
                if obj.LabelIncludeTotal_
                    ni = full( inflow(nid) );
                    no = full( outflow(nid) );
                    if ni == no || (ni * no) == 0
                        ns = sprintf( "%s: %g", ns, nh );
                    else
                        ns = sprintf( "%s: %g \\rightarrow %g", ns, ni, no );
                    end % if
                end % if

                switch obj.LabelAlignment_
                    case "left"
                        tx = nx;
                        ty = ny + nh/2;
                        hAlign = "right";
                        vAlign = "middle";
                    case "right"
                        tx = nx + nw;
                        ty = ny + nh/2;
                        hAlign = "left";
                        vAlign = "middle";
                    case "top"
                        tx = nx + nw/2;
                        ty = ny + nh;
                        hAlign = "center";
                        vAlign = "bottom";
                    case "bottom"
                        tx = nx + nw/2;
                        ty = ny;
                        hAlign = "center";
                        vAlign = "top";
                    case "center"
                        tx = nx + nw/2;
                        ty = ny + nh/2;
                        hAlign = "center";
                        vAlign = "middle";
                end % switch

                set( obj.NodeLabels(nid), ...
                    "Position", [tx, ty], ...
                    "String", pad( ns, strlength( ns )+2, "both" ), ...
                    "HorizontalAlignment", hAlign, ...
                    "VerticalAlignment", vAlign, ...
                    "Clipping", "on", ...
                    "Tag", "NodeLabel", ...
                    "ButtonDownFcn", @(~,~) nodeButtonDown( obj, nid ) );
            end % for
        end % nodeLabelUpdate
        
        function nodeButtonDown( obj, id )
            
            dimFactor = 8;
            
            % Setup when selecting first node
            if ~any( obj.NodeSelected_ )
                for nid = 1:obj.GraphData_.numnodes
                    set( obj.NodePatches(nid), ...
                        "CData", obj.NodePatches(nid).CData / dimFactor )
                end % for
                for eid = 1:obj.GraphData_.numedges
                    set( obj.LinkPatches(eid), ...
                        "CData", obj.LinkPatches(eid).CData / dimFactor )
                end % for
            end % if
            
            I = logical( incidence( obj.GraphData_ )  );
            
            currentLinks = any( I(obj.NodeSelected_,:), 1 );
            
            obj.NodeSelected_(id) = ~obj.NodeSelected_(id);
            
            nextLinks = any( I(obj.NodeSelected_,:), 1 );
            
            % Making changes for selected node
            if obj.NodeSelected_(id)
                
                set( obj.NodePatches(id), ...
                        "CData", dimFactor * obj.NodePatches(id).CData )
                    
                eids = find(nextLinks & ~currentLinks);
                for k = 1:numel(eids)
                    eid = eids(k);
                    set( obj.LinkPatches(eid), ...
                        "CData", dimFactor * obj.LinkPatches(eid).CData )
                end % for
                
            else
                
                set( obj.NodePatches(id), ...
                        "CData", obj.NodePatches(id).CData / dimFactor )
                    
                eids = find(~nextLinks & currentLinks);
                for k = 1:numel(eids)
                    eid = eids(k);
                    set( obj.LinkPatches(eid), ...
                        "CData", obj.LinkPatches(eid).CData / dimFactor )
                end % for
                
            end % if
            
            % Putting selected labels on top
            obj.Axes.Children(end-obj.GraphData_.numedges+1:end) = [ ...
                obj.LinkPatches(nextLinks); ...
                obj.LinkPatches(~nextLinks) ];
            
            % Reset colors when no node is selected
            if ~any( obj.NodeSelected_ )
                for nid = 1:obj.GraphData_.numnodes
                    set( obj.NodePatches(nid), ...
                        "CData", dimFactor * obj.NodePatches(nid).CData )
                end % for
                for eid = 1:obj.GraphData_.numedges
                    set( obj.LinkPatches(eid), ...
                        "CData", dimFactor * obj.LinkPatches(eid).CData )
                end % for
            end % if
            
        end % nodeButtonDown
        
        function nodeCoordinates( obj )
            
            % Creating hidden figure to get positions
            hiddenFig = figure( "Visible", "off" );
            oc = onCleanup( @() delete( hiddenFig ) );
            hiddenAx  = axes( hiddenFig );
            hiddenPlt = plot( hiddenAx, obj.GraphData_, ...
                "Layout", "layered", ...
                "Direction", "right" );
            
            % Retrieving node x-coordinates
            obj.XNodeData_ = hiddenPlt.XData';

            % Computing node y-coordinates
            xGroups = findgroups( obj.XNodeData_ );
            
            groupTotFlow = splitapply( @sum, obj.NodeHeight_, xGroups );
            groupCount = groupcounts( xGroups );
            
            nodePad = obj.NodePadRatio_ * max( groupTotFlow );
            
            obj.YNodeData_ = zeros( obj.GraphData_.numnodes, 1 );
            for gid = 1:max( xGroups )
                groupIdx = xGroups == gid;
                
                [~, yOrdIdx] = sort( hiddenPlt.YData(groupIdx) );
                yOrdIdxInv = 1:groupCount(gid);
                yOrdIdxInv(yOrdIdx) = yOrdIdxInv;
                
                groupFlows = obj.NodeHeight_(groupIdx);
                groupOrdFlows = groupFlows(yOrdIdx);
                
                groupOrdY = cumsum( groupOrdFlows ) - groupOrdFlows;
                groupY = groupOrdY(yOrdIdxInv);
                padding = nodePad * (yOrdIdxInv' - 1);
                height = groupTotFlow(gid) + max( padding );
                
                obj.YNodeData_(groupIdx) = groupY + padding - height/2;
            end % for
            
            linkCoordinates( obj )
            
        end % nodeCoordinates
        
        function nodeUpdate( obj )
            
            nNodes  = obj.GraphData_.numnodes;
            nCurrent = numel( obj.NodePatches );
            if nNodes < nCurrent
                
                delete( obj.NodePatches(nNodes+1:nCurrent) )
                obj.NodePatches(nNodes+1:nCurrent) = [];
                
            elseif nNodes > nCurrent
                
                obj.NodePatches(nCurrent+1:nNodes) = gobjects( nNodes - nCurrent, 1 );
                for nid = nCurrent+1:nNodes
                    obj.NodePatches(nid) = patch( "Parent", obj.Axes );
                end % for
                
            end % if
            
            expand = @(x) reshape( x, [1, size( x )] );
            for nid = 1:nNodes

                nx = obj.XNodeData_(nid);
                ny = obj.YNodeData_(nid);
                nw = obj.NodeWidth_;
                nh = obj.NodeHeight_(nid);

                set( obj.NodePatches(nid), ...
                    "XData", nx + nw * [0 1 1 0], ...
                    "YData", ny + nh * [0 0 1 1], ...
                    "CData", expand( obj.NodeColor_(nid,:) ), ...
                    "FaceColor", "flat", ...
                    "EdgeColor", obj.NodeEdgeColor, ...
                    "LineWidth", obj.NodeEdgeWidth, ...
                    "LineStyle", obj.NodeEdgeStyle, ...
                    "FaceAlpha", obj.NodeAlpha, ...
                    "EdgeAlpha", obj.NodeAlpha, ...
                    "Tag", "Node", ...
                    "ButtonDownFcn", @(~,~) nodeButtonDown( obj, nid ) );
            end % for
        end % nodeUpdate
        
    end % methods
    
    methods ( Access = protected )
        
        function setup( obj )
            %SETUP Initialize the chart graphics.
            
            % Create the axes.
            obj.Axes = axes( "Parent", obj.getLayout(), ...                
                "Visible", "off", ...
                "DataAspectRatioMode", "manual" );
            obj.Axes.Title.Visible = "on";
            disableDefaultInteractivity( obj.Axes )
            
        end % setup
        
        function update( obj )
            %UPDATE Refresh the chart graphics.

            if obj.ComputationRequired

                % Setting optimal data aspect ratio
                rangeX = range( [obj.XNodeData_; obj.XNodeData_ + obj.NodeWidth_] );
                rangeY = range( [obj.YNodeData_; obj.YNodeData_ + obj.NodeHeight_] );
                
                obj.Axes.DataAspectRatio = [rangeX, rangeY, 1];
                
                % Displaying links
                linkUpdate( obj )
                
                % Displaying nodes
                nodeUpdate( obj )
                
                % Displaying node names
                nodeLabelUpdate( obj )
               
                % Creating link labels
                linkLabelUpdate( obj )
                
                % Reseting node selected state
                obj.NodeSelected_ = false( size( obj.NodeSelected_ ) );
                
                % Ensuring correct ordering
                obj.Axes.Children = [  obj.LinkLabels; ...
                                       obj.NodeLabels; ...
                                       obj.NodePatches; ...
                                       obj.LinkPatches ];
                
                obj.ComputationRequired = false;
            end
            
            % Refresh the chart's decorative properties.
            set( obj.LinkPatches, ...
                "FaceAlpha", obj.LinkAlpha, ...
                "EdgeAlpha", obj.LinkAlpha, ...
                "EdgeColor", obj.LinkEdgeColor, ...
                "LineStyle", obj.LinkEdgeStyle, ...
                "LineWidth", obj.LinkEdgeWidth )
            
            set( obj.NodePatches, ...
                "FaceAlpha", obj.NodeAlpha, ...
                "EdgeAlpha", obj.NodeAlpha, ...
                "EdgeColor", obj.NodeEdgeColor, ...
                "LineStyle", obj.NodeEdgeStyle, ...
                "LineWidth", obj.NodeEdgeWidth )

            set( obj.NodeLabels, ...
                "FontSize", obj.NodeFontSize, ...
                "Visible", obj.NodeLabelsVisible )

            set( obj.LinkLabels, ...
                "FontSize", obj.LinkFontSize)
            
        end % update
        
    end % methods ( Access = protected )
    
end % class definition

function [XX, YY, CC] = wavyLink( startPoint, endPoint, girth, ratio, type, crossSection, n )
    arguments
        startPoint(1,2) double
        endPoint(1,2) double
        girth(1,1) double {mustBeNonnegative}
        ratio(1,3) double = [1, 1, 1]
        type(1,1) string {mustBeMember(type,["tanh","cos","line"])} = "cos"
        crossSection(1,1) string {mustBeMember(crossSection,["normal","vertical"])} = "normal"
        n(1,1) double {mustBeGreaterThan(n,1)} = 32
    end

    width  = endPoint(1) - startPoint(1);
    height = endPoint(2) - startPoint(2);

    % Creating patch
    if width > 0
        [XX, YY] = forwardLink;
    else
        [XX, YY] = backwardsLink;
    end
    
    % Ensure simple (Jordan) polygons
    warnID = "MATLAB:polyshape:repairedBySimplify";
    warnState = warning( "query", warnID );
    warning( "off", warnID )
    warnCleanup = onCleanup( @() warning( warnState ) );
    poly = polyshape(XX,YY);
    poly = rmholes(poly);
    XX = poly.Vertices(:,1);
    YY = poly.Vertices(:,2);
    
    NN = numel(XX);
    CC = - abs( (2 * linspace( 0, NN, NN ) - NN ) / NN ) + 1;
    
    function [XX, YY] = forwardLink
        
        % Creating reference function ([0,1] -> [0,1]) and derivative
        switch type
            case "tanh"
                curvy = 4;
                g  = @(x) (tanh( curvy * (2 * x - 1) ) + tanh(curvy)) / (2 * tanh(curvy));
                dg = @(x) curvy * sech( curvy * (2 * x - 1) ).^2 / tanh(curvy);
            case "cos"
                g  = @(x) (1 - cos( pi * x )) / 2;
                dg = @(x) pi * sin( pi * x ) /2;
            case "line"
                n = 2;
                g  = @(x) x;
                dg = @(x) ones( size( x ) );
            otherwise
                error("Unrecognized wave type")
        end % switch

        % Enabling vertical cross sections
        if strcmp( crossSection, "vertical" )
            dg = @(x) zeros( size( x ) );
        end % if

        % Scaling function to desired size
        f  = @(x) height * g( x / width );
        df = @(x) height * dg( x / width ) / width;

        % Computing reference line
        x0 = linspace(0, width, n);
        y0 = f(x0);

        % Computing normal vectors at each point
        rr = ratio(1) / ratio(2);
        delta = [df(x0); - ones(size(x0)) / rr];
        delta = girth * diag([rr 1]) * delta ./ vecnorm(delta) / 2;

        % Taking points on each side of reference line
        x1 = x0 + delta(1,:);
        y1 = y0 + delta(2,:);

        x2 = x0 - delta(1,:);
        y2 = y0 - delta(2,:);

        % Cleaning up sides
        x1(1) = 0;
        x2(1) = 0;

        x1(end) = width;
        x2(end) = width;

        if width > 0
            before1 = x1 <= 0;
            before2 = x2 <= 0;
            after1  = x1 >= width;
            after2  = x2 >= width;
        else
            before1 = x1 >= 0;
            before2 = x2 >= 0;
            after1  = x1 <= width;
            after2  = x2 <= width;
        end % if

        x1(before1) = 0;
        y1(before1) = - girth / 2;

        x2(before2) = 0;
        y2(before2) = girth / 2;

        x1(after1) = width;
        y1(after1) = height - girth / 2;

        x2(after2) = width;
        y2(after2) = height + girth / 2;
        
        XX = startPoint(1) + [x1 fliplr(x2)];
        YY = startPoint(2) + [y1 fliplr(y2)] + girth / 2;
    end

    function [XX, YY] = backwardsLink
        
        A = 0.1;
        B = A + girth * ratio(1) / ratio(2);
        C = -girth;
        if height < 0
            C = C + height;
        end
        
        XX = [0, A, A, width-A, width-A, width, ...
              width, width-B, width-B, B, B, 0];
        YY = [0, 0, C, C, height, height, ...
              height+girth, height+girth, C-girth, C-girth, girth, girth];
        
        XX = startPoint(1) + XX;
        YY = startPoint(2) + YY;
    end

end % wavyLink