classdef SankeyChart < Chart
    %SANKEYCHART Illustrates the flow between different states.

    % Copyright 2018-2025 The MathWorks, Inc.

    properties ( Dependent )
        % Directed graph representing the Sankey diagram.
        GraphData(1, 1) digraph
        % Node label alignment.
        LabelAlignment(1, 1) string {mustBeMember( LabelAlignment, ...
            ["left", "right", "top", "bottom", "center"] )}
        % Flag to display totals.
        LabelIncludeTotal(1, 1) matlab.lang.OnOffSwitchState
        % Link color.
        LinkColor
        % Curve type.
        LinkType(1, 1) string {mustBeMember( LinkType, ...
            ["tanh", "cos", "vtanh", "vcos", "line"] )}
        % Node color.
        NodeColor
        % Vertical space between nodes.
        NodePadRatio(1, 1) double {mustBeNonnegative, mustBeFinite}
        % Node width.
        NodeWidth(1, 1) double {mustBeNonnegative, mustBeFinite}
        % Node x-coordinates.
        XNodeData(:, 1) double {mustBeReal, mustBeFinite}
        % Node y-coordinates.
        YNodeData(:, 1) double {mustBeReal, mustBeFinite}
    end % properties ( Dependent )

    properties
        % Link transparency.
        LinkAlpha(1, 1) double {mustBeInRange( LinkAlpha, 0, 1 )} = 0.5
        % Link edge color.
        LinkEdgeColor {validatecolor} = "black"
        % Link edge style.
        LinkEdgeStyle(1, 1) string {mustBeLineStyle} = "none"
        % Link edge width.
        LinkEdgeWidth(1, 1) double {mustBePositive, mustBeFinite} = 0.5
        % Font size for link annotations.
        LinkFontSize(1, 1) double {mustBePositive, mustBeFinite} = 10
        % Node transparency.
        NodeAlpha(1, 1) double {mustBeInRange( NodeAlpha, 0, 1 )} = 1
        % Node edge color.
        NodeEdgeColor {validatecolor} = "black"
        % Node edge line style.
        NodeEdgeStyle(1, 1) string {mustBeLineStyle} = "-"
        % Node edge width.
        NodeEdgeWidth(1, 1) double {mustBePositive, mustBeFinite} = 0.5
        % Node label font size.
        NodeFontSize(1, 1) double {mustBePositive, mustBeFinite} = 10
        % Node label visibility.
        NodeLabelsVisible(1, 1) matlab.lang.OnOffSwitchState = "on"
    end % properties

    properties ( Access = private, Transient, NonCopyable )
        % The chart's axes.
        Axes(:, 1) matlab.graphics.axis.Axes {mustBeScalarOrEmpty}
        % Text objects for the link labels.
        LinkLabels(:, 1) matlab.graphics.primitive.Text
        % Patch objects for the links.
        LinkPatches(:, 1) matlab.graphics.primitive.Patch
        % Text objects for the node labels.
        NodeLabels(:, 1) matlab.graphics.primitive.Text
        % Patch objects for the nodes.
        NodePatches(:, 1) matlab.graphics.primitive.Patch
    end % properties ( Access = private, Transient, NonCopyable )

    properties ( Access = private )
        % Logical scalar specifying whether a computation is required.
        ComputationRequired(1, 1) logical = false
        % Backing for LabelAlignment.
        LabelAlignment_(1, 1) string {mustBeMember( LabelAlignment_, ...
            ["left", "right", "top", "bottom", "center"] )} = "right"
        % Backing for LabelIncludeTotal.
        LabelIncludeTotal_(1, 1) matlab.lang.OnOffSwitchState = "off"
        % Backing for LinkColor.
        LinkColor_ = "source"
        % Backing for LinkType.
        LinkType_(1, 1) string {mustBeMember( LinkType_, ...
            ["tanh", "cos", "vtanh", "vcos", "line"] )} = "cos"
        % Link cross type.
        LinkCrossType(1, 1) string {mustBeMember( LinkCrossType, ...
            ["vertical", "normal"] )} = "normal"
        % Backing for GraphData.
        GraphData_(1, 1) digraph = digraph()
        % Backing for NodeColor.
        NodeColor_ = zeros( 0, 3 )
        % Node height.
        NodeHeight(:, 1) double {mustBePositive, mustBeFinite} = ...
            double.empty( 0, 1 )
        % Backing for NodePadRatio.
        NodePadRatio_(1, 1) double {mustBeNonnegative, mustBeFinite} = 0.05
        % Logical array indicating whether nodes are selected.
        NodeSelected(:, 1) logical = false( 0, 1 )
        % Backing for NodeWidth.
        NodeWidth_(1, 1) double {mustBeNonnegative, mustBeFinite} = 0.1
        % Backing for XNodeData.
        XNodeData_(:, 1) double {mustBeReal, mustBeFinite} = zeros( 0, 1 )
        % Backing for YNodeData.
        YNodeData_(:, 1) double {mustBeReal, mustBeFinite} = zeros( 0, 1 )
        % Y link data.
        YLinkData(:, :) double {mustBeReal, mustBeFinite} = zeros( 0, 1 )
    end % properties ( Access = private )

    properties ( Constant, Hidden )
        % Product dependencies.
        Dependencies(1, :) string = "MATLAB"
    end % properties ( Constant, Hidden )

    methods

        function obj = SankeyChart( namedArgs )
            %SANKEYCHART Construct a SankeyChart, given optional name-value
            %arguments.

            arguments ( Input )
                namedArgs.?SankeyChart
            end % arguments ( Input )            

            % Set any user-defined properties.
            set( obj, namedArgs )

        end % constructor

        function set.LabelAlignment( obj, value )

            obj.LabelAlignment_ = value;
            updateNodeLabels( obj )

        end % set.LabelAlignment

        function value = get.LabelAlignment( obj )

            value = obj.LabelAlignment_;

        end % get.LabelAlignment

        function set.LabelIncludeTotal( obj, value )

            obj.LabelIncludeTotal_ = value;
            updateNodeLabels( obj )

        end % set.LabelIncludeTotal

        function value = get.LabelIncludeTotal( obj )

            value = obj.LabelIncludeTotal_;

        end % get.LabelIncludeTotal

        function set.LinkColor( obj, value )

            % Validate.
            value = convertCharsToStrings( value );
            if ~isstring( value ) || ~ismember( value, ...
                    ["source", "target", "gradient"] )
                value = validatecolor( value );
            end % if

            % Update.
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
                obj.LinkType_ = extractBetween( value, pat, ...
                    textBoundary( "end" ) );
                obj.LinkCrossType = "vertical";
            else
                obj.LinkType_ = value;
                obj.LinkCrossType = "normal";
            end % if

        end % set.LinkType

        function value = get.LinkType( obj )

            if obj.LinkCrossType == "vertical"
                value = "v" + obj.LinkType_;
            else
                value = obj.LinkType_;
            end % if

        end % get.LinkType

        function set.GraphData( obj, value )

            % Check.
            if ismultigraph( value ) || ...
                    any( diag( adjacency( obj.GraphData_ ) ) )
                error( "SankeyChart:NotSimpleGraph", ...
                    "The given graph is not simple. Use simplify to " + ...
                    "remove multiple edges and self-loops." )
            end % if

            % Update internal properties.
            obj.ComputationRequired = true;
            obj.GraphData_ = value;

            % Making sure weights are specified.
            if ~ismember( "Weight", ...
                    obj.GraphData_.Edges.Properties.VariableNames )
                obj.GraphData_.Edges.Weight = ...
                    ones( obj.GraphData_.numedges, 1 );
            end % if

            % Compute node flows.
            A = adjacency( obj.GraphData_, "weighted" );
            inflow  = sum( A, 1 )';
            outflow = sum( A, 2 );
            src = inflow == 0;
            snk = outflow == 0;

            % Issue a warning for unbalanced graphs.
            if ~isequal( inflow(~src & ~snk), outflow(~src & ~snk) )
                warning( "SankeyChart:UnbalancedGraph", ...
                    "The given graph is unbalanced." )
            end % if

            % Compute node and link coordinates.
            obj.NodeHeight = full( max( inflow, outflow ) );
            nodeCoordinates( obj )

            % Set node colors.
            obj.NodeColor_ = lines( obj.GraphData_.numnodes );

            % Update the selection.
            obj.NodeSelected = false( obj.GraphData_.numnodes, 1 );

        end % set.GraphData

        function value = get.GraphData( obj )

            value = obj.GraphData_;

        end % get.GraphData

        function set.NodeColor( obj, value )

            % Check.
            nodeColor = validatecolor( value, "multiple" );
            validateattributes( nodeColor, "double", ...
                {"size", size( obj.NodeColor_ )} )

            % Update.
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

            % Check.
            validateattributes( value, "double", ...
                {"size", size( obj.XNodeData_ )} )

            % Update.
            obj.ComputationRequired = true;
            obj.XNodeData_ = value;

        end % set.XNodeData

        function value = get.XNodeData( obj )

            value = obj.XNodeData_;

        end % get.XNodeData

        function set.YNodeData( obj, value )

            % Check.
            validateattributes( value, "double", ...
                {"size", size( obj.YNodeData_ )} )

            % Update.
            obj.ComputationRequired = true;
            obj.YNodeData_ = value;

            % Recompute link coordinates.
            updateLinkCoordinates( obj )

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

        function updateLinkLabels( obj )
            %UPDATELINKLABELS Helper method to update the link labels.

            nLabels  = obj.GraphData_.numedges;
            nCurrent = numel( obj.LinkLabels );

            if nLabels < nCurrent

                delete( obj.LinkLabels(nLabels+1:nCurrent) )
                obj.LinkLabels(nLabels+1:nCurrent) = [];

            elseif nLabels > nCurrent

                for eid = nCurrent+1:nLabels
                    obj.LinkLabels(eid) = text( "Parent", obj.Axes );
                end % for

            end % if

            for eid = 1:nLabels

                linkSource = obj.GraphData_.Edges.EndNodes(eid, 1);
                linkTarget = obj.GraphData_.Edges.EndNodes(eid, 2);
                linkHeight = obj.GraphData_.Edges.Weight(eid);

                linkText = [sprintf( "Source: %s", ...
                    string( linkSource ) ), ...
                    sprintf( "Target: %s", string( linkTarget ) ), ...
                    sprintf( "Weight: %g", linkHeight )];

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
                    "ButtonDownFcn", @(~, ~) onLinkClicked( obj, eid ) )

            end % for

        end % updateLinkLabels

        function onLinkClicked( obj, id )
            %ONLINKCLICKED Link left-click callback.

            set( obj.LinkLabels(id), ...
                "Visible", ~obj.LinkLabels(id).Visible )

        end % onLinkClicked

        function updateLinkCoordinates( obj )
            %UPDATELINKCOORDINATES Helper method to update the link
            %coordinates.

            % Compute link y-coordinates.
            obj.YLinkData = zeros( obj.GraphData_.numedges, 2 );

            for nid = 1:obj.GraphData_.numnodes

                % Outbound links
                [eid, tid] = outedges( obj.GraphData_, nid );
                targetY = obj.YNodeData_(tid) + obj.NodeHeight(tid)/2;
                [~, yOrdIdx] = sort( targetY );
                linkHeight = obj.GraphData_.Edges.Weight(eid(yOrdIdx));
                linkY = cumsum( linkHeight ) - linkHeight;
                obj.YLinkData(eid(yOrdIdx), 1) = ...
                    obj.YNodeData_(nid) + linkY;

                % Inbound links
                [eid, sid] = inedges( obj.GraphData_, nid );
                sourceY = obj.YNodeData_(sid) + obj.NodeHeight(sid)/2;
                [~, yOrdIdx] = sort( sourceY );
                linkHeight = obj.GraphData_.Edges.Weight(eid(yOrdIdx));
                linkY = cumsum( linkHeight ) - linkHeight;
                obj.YLinkData(eid(yOrdIdx), 2) = ...
                    obj.YNodeData_(nid) + linkY;

            end % for

        end % updateLinkCoordinates

        function updateLinks( obj )
            %UPDATELINKS Helper method to update links.

            nLinks   = obj.GraphData_.numedges;
            nCurrent = numel( obj.LinkPatches );

            if nLinks < nCurrent

                delete( obj.LinkPatches(nLinks+1:nCurrent) )
                obj.LinkPatches(nLinks+1:nCurrent) = [];

            elseif nLinks > nCurrent

                for eid = nCurrent+1:nLinks
                    obj.LinkPatches(eid) = patch( "Parent", obj.Axes );
                end % for

            end % if

            expand = @(x) reshape( x, [1, size( x )] );

            for eid = 1:nLinks

                % Compute the patch coordinates and color for the current
                % link.
                linkSource = obj.GraphData_.Edges.EndNodes(eid, 1);
                linkTarget = obj.GraphData_.Edges.EndNodes(eid, 2);
                linkHeight = obj.GraphData_.Edges.Weight(eid);
                sid = findnode( obj.GraphData_, linkSource );
                tid = findnode( obj.GraphData_, linkTarget );
                sx = obj.XNodeData_(sid) + obj.NodeWidth_;
                sy = obj.YLinkData(eid, 1);
                tx = obj.XNodeData_(tid);
                ty = obj.YLinkData(eid, 2);
                [XX, YY, vColor] = wavyLink( [sx, sy], [tx, ty], ...
                    linkHeight, obj.Axes.DataAspectRatio, ...
                    obj.LinkType_, obj.LinkCrossType );

                % Color the link.
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
                    "ButtonDownFcn", @(~,~) onLinkClicked( obj, eid ) )

            end % for

        end % updateLinks

        function updateNodeLabels( obj )
            %UPDATENODELABELS Helper method to update the node labels.

            nLabels  = obj.GraphData_.numnodes;
            nCurrent = numel( obj.NodeLabels );

            if nLabels < nCurrent

                delete( obj.NodeLabels(nLabels+1:nCurrent) )
                obj.NodeLabels(nLabels+1:nCurrent) = [];

            elseif nLabels > nCurrent

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
                nh = obj.NodeHeight(nid);

                if ismember( "Name", ...
                        obj.GraphData_.Nodes.Properties.VariableNames )
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
                        ns = sprintf( "%s: %g \\rightarrow %g", ...
                            ns, ni, no );
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
                    "ButtonDownFcn", @(~,~) nodeButtonDown( obj, nid ) )

            end % for

        end % updateNodeLabels

        function nodeButtonDown( obj, id )

            dimFactor = 8;

            % Setup when selecting first node
            if ~any( obj.NodeSelected )
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

            currentLinks = any( I(obj.NodeSelected,:), 1 );

            obj.NodeSelected(id) = ~obj.NodeSelected(id);

            nextLinks = any( I(obj.NodeSelected,:), 1 );

            % Making changes for selected node
            if obj.NodeSelected(id)

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
            if ~any( obj.NodeSelected )
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

            groupTotFlow = splitapply( @sum, obj.NodeHeight, xGroups );
            groupCount = groupcounts( xGroups );

            nodePad = obj.NodePadRatio_ * max( groupTotFlow );

            obj.YNodeData_ = zeros( obj.GraphData_.numnodes, 1 );
            for gid = 1:max( xGroups )
                groupIdx = xGroups == gid;

                [~, yOrdIdx] = sort( hiddenPlt.YData(groupIdx) );
                yOrdIdxInv = 1:groupCount(gid);
                yOrdIdxInv(yOrdIdx) = yOrdIdxInv;

                groupFlows = obj.NodeHeight(groupIdx);
                groupOrdFlows = groupFlows(yOrdIdx);

                groupOrdY = cumsum( groupOrdFlows ) - groupOrdFlows;
                groupY = groupOrdY(yOrdIdxInv);
                padding = nodePad * (yOrdIdxInv' - 1);
                height = groupTotFlow(gid) + max( padding );

                obj.YNodeData_(groupIdx) = groupY + padding - height/2;
            end % for

            updateLinkCoordinates( obj )

        end % nodeCoordinates

        function updateNodes( obj )
            %UPDATENODES Helper method to update the nodes.

            nNodes  = obj.GraphData_.numnodes;
            nCurrent = numel( obj.NodePatches );

            if nNodes < nCurrent

                delete( obj.NodePatches(nNodes+1:nCurrent) )
                obj.NodePatches(nNodes+1:nCurrent) = [];

            elseif nNodes > nCurrent

                for nid = nCurrent+1:nNodes
                    obj.NodePatches(nid) = patch( "Parent", obj.Axes );
                end % for

            end % if

            expand = @(x) reshape( x, [1, size( x )] );

            for nid = 1:nNodes

                nx = obj.XNodeData_(nid);
                ny = obj.YNodeData_(nid);
                nw = obj.NodeWidth_;
                nh = obj.NodeHeight(nid);

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
                    "ButtonDownFcn", @(~,~) nodeButtonDown( obj, nid ) )

            end % for

        end % updateNodes

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

                % Set optimal data aspect ratio.
                rangeX = range( [obj.XNodeData_; obj.XNodeData_ + ...
                    obj.NodeWidth_] );
                rangeY = range( [obj.YNodeData_; obj.YNodeData_ + ...
                    obj.NodeHeight] );
                obj.Axes.DataAspectRatio = [rangeX, rangeY, 1];

                % Display links.
                updateLinks( obj )

                % Display nodes.
                updateNodes( obj )

                % Display node names.
                updateNodeLabels( obj )

                % Create link labels.
                updateLinkLabels( obj )

                % Reset the node selected state.
                obj.NodeSelected = false( size( obj.NodeSelected ) );

                % Ensuring correct ordering.
                obj.Axes.Children = [  obj.LinkLabels; ...
                    obj.NodeLabels; ...
                    obj.NodePatches; ...
                    obj.LinkPatches ];

                % Reset the flag.
                obj.ComputationRequired = false;

            end % if

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

end % classdef

function [XX, YY, CC] = wavyLink( startPoint, endPoint, ...
    girth, ratio, type, crossSection, n )
%WAVYLINK Compute the (x, y) coordinates and color of the wavy link
%connecting two nodes.

arguments ( Input )
    startPoint(1, 2) double
    endPoint(1, 2) double
    girth(1, 1) double {mustBeNonnegative, mustBeFinite}
    ratio(1, 3) double = [1, 1, 1]
    type(1, 1) string ...
        {mustBeMember( type, ["tanh", "cos", "line"] )} = "cos"
    crossSection(1, 1) string {mustBeMember( crossSection, ...
        ["normal", "vertical"] )} = "normal"
    n(1, 1) double {mustBeGreaterThan( n, 1 )} = 32
end % arguments ( Input )

width  = endPoint(1) - startPoint(1);
height = endPoint(2) - startPoint(2);

% Creating patch
if width > 0
    [XX, YY] = forwardLink();
else
    [XX, YY] = backwardsLink();
end % if

% Ensure simple (Jordan) polygons
warnID = "MATLAB:polyshape:repairedBySimplify";
warnState = warning( "query", warnID );
warning( "off", warnID )
warnCleanup = onCleanup( @() warning( warnState ) );
poly = polyshape( XX, YY );
poly = rmholes( poly );
XX = poly.Vertices(:, 1);
YY = poly.Vertices(:, 2);
NN = numel(XX);
CC = - abs( (2 * linspace( 0, NN, NN ) - NN ) / NN ) + 1;

    function [XX, YY] = forwardLink()

        % Creating reference function ([0,1] -> [0,1]) and derivative
        switch type
            case "tanh"
                curvy = 4;
                g  = @(x) (tanh( curvy * (2 * x - 1) ) + ...
                    tanh(curvy)) / (2 * tanh(curvy));
                dg = @(x) curvy * sech( curvy * ...
                    (2 * x - 1) ).^2 / tanh(curvy);
            case "cos"
                g  = @(x) (1 - cos( pi * x )) / 2;
                dg = @(x) pi * sin( pi * x ) /2;
            case "line"
                n = 2;
                g  = @(x) x;
                dg = @(x) ones( size( x ) );
        end % switch/case

        % Enabling vertical cross sections
        if crossSection == "vertical"
            dg = @(x) zeros( size( x ) );
        end % if

        % Scaling function to desired size
        f  = @(x) height * g( x / width );
        df = @(x) height * dg( x / width ) / width;

        % Computing reference line
        x0 = linspace( 0, width, n );
        y0 = f( x0 );

        % Computing normal vectors at each point
        rr = ratio(1) / ratio(2);
        delta = [df(x0); - ones( size( x0 ) ) / rr];
        delta = girth * diag( [rr, 1] ) * delta ./ vecnorm( delta ) / 2;

        % Taking points on each side of reference line
        x1 = x0 + delta(1, :);
        y1 = y0 + delta(2, :);

        x2 = x0 - delta(1, :);
        y2 = y0 - delta(2, :);

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

    end % forwardLink

    function [XX, YY] = backwardsLink()

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

    end % backwardsLink

end % wavyLink