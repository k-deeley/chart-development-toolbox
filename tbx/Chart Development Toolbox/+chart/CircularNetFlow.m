classdef CircularNetFlow < matlab.graphics.chartcontainer.ChartContainer
    %CIRCULARNETFLOW Illustrates the directed to/from relationships between
    %pairs of categories.
    %
    % Copyright 2018-2021 The MathWorks, Inc.
    
    properties ( Dependent )
        % Chart data table.
        LinkData
        % Offset for the outer labels.
        OuterLabelOffset(1, 1) double {mustBeFinite, mustBePositive} = 35
    end % properties ( Dependent )
    
    properties
        % Transparency of the link patches.
        FaceAlpha(1, 1) double {mustBePositive} = 0.5
    end % Public properties
    
    properties ( Dependent, SetAccess = private )
        % Derived net flow, presented as a table.
        NetFlow
        % Net amounts sent.
        NetSent
        % Net amounts received.
        NetReceived
        % Chart data labels.
        Labels
    end % properties ( Dependent, SetAccess = private )
    
    properties ( Dependent, Access = private )
        % Number of sources/sinks.
        NumSources
        % Row/column indices and values of the positive net flow.
        PositiveNetFlow
        % List of colors used for the various graphics objects.
        Colors
        % Colormap used for the patch objects.
        PatchColormap
        % Angular positions of the arc endpoints, measured in radians
        % anticlockwise from the easterly direction.
        AngularPositions
        % Sizes of the interior, receiving nodes. These are proportional to
        % the total amount received by each node.
        NodeSizes
        % Angular positions of the nodes.
        NodePositions
    end % properties ( Dependent, Access = private )
    
    properties ( Access = private, Transient, NonCopyable )
        % Chart axes.
        Axes(1, 1) matlab.graphics.axis.Axes
        % Circumferential arcs.
        Arcs
        % Receiving nodes in the interior of the disk.
        ReceivingNodes
        % Link patches.
        LinkPatches
        % Link patch text labels.
        PatchLabels
        % Outer labels for each source.
        OuterLabels
        % Inner labels for each node.
        NodeLabels
    end % properties ( Access = private, Transient, NonCopyable )
    
    properties ( Access = private )
        % Backing property for the chart data table.
        LinkData_ = table.empty( 0, 0 )
        % Logical scalar specifying whether a computation is required.
        ComputationRequired = false()
        % Outer radius.
        OuterRadius = 100
        % Inner radius.
        InnerRadius = 30
        % Scale factor for the inner node sizes.
        NodeScaleFactor = 200
        % Number of transition points for interpolated patch shading.
        NumTransitionPoints = 100
        % Angular gap size between the outer circular arcs.
        AngularGap = pi / 400
        % Offset for the circumferential patch labels.
        PatchLabelOffset = 10
        % Patch label font size.
        PatchLabelFontSize = 0.03
        % Backing property for the outer label offset.
        OuterLabelOffset_ = 35
        % Outer label font size.
        OuterLabelFontSize = 0.04
    end % properties ( Access = private )
    
    properties ( Constant, Hidden )
        % Product dependencies.
        Dependencies = "MATLAB"
    end % properties ( Constant, Hidden )
    
    methods
        
        function value = get.LinkData( obj )
            
            value = obj.LinkData_;
            
        end % get.LinkData
        
        function set.LinkData( obj, value )
            
            % Mark the chart for an update.
            obj.ComputationRequired = true;
            
            % Check the proposed chart data.
            validateattributes( value, "table", ["square", "nonempty"], ...
                "CircularNetFlow", "the link data table" )
            try
                A = value{:, :};
            catch MExc
                M = MException( MExc.identifier, ...
                    "Table data cannot be concatenated into a matrix." );
                throw( M )
            end % try/catch
            
            validateattributes( A, "double", ...
                ["real", "square", "finite", "nonnegative"], ...
                "CircularNetFlow", "the link data matrix" )
            d = diag( A );
            assert( ~any( d ), "CircularNetFlow:InvalidLinkData", ...
                "Diagonal elements of the link data must be zero." )
            
            % Set the internal data property.
            obj.LinkData_ = value;
            
        end % set.LinkData
        
        function value = get.Labels( obj )
            
            value = obj.LinkData_.Properties.VariableNames;
            
        end % get.Labels
        
        function value = get.OuterLabelOffset( obj )
            
            value = obj.OuterLabelOffset_;
            
        end % get.OuterLabelOffset
        
        function set.OuterLabelOffset( obj, value )
            
            % Update the internal property.
            obj.OuterLabelOffset_ = value;
            % Reposition the outer labels.
            [outerLabelX, outerLabelY] = pol2cart( obj.NodePositions, ...
                obj.OuterRadius + obj.OuterLabelOffset );
            for k = 1:obj.NumSources
                set( obj.OuterLabels(k), "Position", ...
                    [outerLabelX(k), outerLabelY(k), 0] )
            end % for
            
        end % set.OuterLabelOffset
        
        function value = get.NetFlow( obj )
            
            % Compute the net flow from each source (row) to every sink
            % (column). The set of sources is the same as the set of sinks.
            d = obj.LinkData{:, :};
            flowFromSource = tril( d );
            flowFromSink = triu( d );
            % Compute the net flow, as an upper triangular matrix.
            netflow = flowFromSink - flowFromSource.';
            % Ensure the net flow matrix is skew-symmetric, i.e., populate
            % the lower triangular part.
            netflow = netflow - triu( netflow ).';
            % Tabulate the result.
            value = array2table( netflow, "VariableNames", obj.Labels, ...
                "RowNames", obj.Labels );
            
        end % get.NetFlow
        
        function value = get.NetSent( obj )
            
            % Sum the positive values in each row.
            nf = obj.NetFlow{:, :};
            nf(nf < 0) = 0;
            value = sum( nf, 2 );
            
        end % get.NetSent
        
        function value = get.NetReceived( obj )
            
            % Sum the positive values in each column, returning the results
            % as a column vector.
            nf = obj.NetFlow{:, :};
            nf(nf < 0) = 0;
            value = sum( nf ).';
            
        end % get.NetReceived
        
        function value = get.NumSources( obj )
            
            value = size( obj.LinkData, 1 );
            
        end % get.NumSources
        
        function value = get.PositiveNetFlow( obj )
            
            % Return a three-column matrix containing the row and column
            % indices of the positive net flow values (1st and 2nd
            % columns), together with the positive net flow values.
            nf = obj.NetFlow{:, :};
            posIdx = nf > 0;
            [value(:, 1), value(:, 2)] = find( posIdx );
            value(:, 3) = nf(posIdx);
            
        end % get.PositiveNetFlow
        
        function value = get.Colors( obj )
            
            % Default list of colors used for plotting.
            value = obj.Axes.ColorOrder;
            % Interpolate this list to produce the required number of
            % colors.
            colIdx = 1:size( value, 1 );
            colQueryIdx = linspace( 1, colIdx(end), obj.NumSources );
            value = interp1( colIdx, value, colQueryIdx );
            
        end % get.Colors
        
        function value = get.PatchColormap( obj )
            
            % Preallocate for the patch colormap. The number of patches is
            % equal to the number of positive net flow values. Each patch
            % contributes NumTransitionPoints rows to the overall patch
            % colormap.
            N = obj.NumTransitionPoints;
            numPosFlow = size( obj.PositiveNetFlow, 1 );
            value = NaN( N * numPosFlow, 3 );
            for k = 1 : numPosFlow
                % For each patch, create a smooth transition from the
                % source color to the sink color. Vertically concatenate
                % the results in the overall patch colormap.
                sourceColor = obj.Colors( obj.PositiveNetFlow(k, 1), : );
                sinkColor = obj.Colors( obj.PositiveNetFlow(k, 2), : );
                transitionMap = ...
                    [linspace(sourceColor(1), sinkColor(1), N).', ...
                    linspace(sourceColor(2), sinkColor(2), N).', ...
                    linspace(sourceColor(3), sinkColor(3), N).'];
                value((N * (k-1) + 1) : N * k, :) = transitionMap;
            end % for
            
        end % get.PatchColormap
        
        function value = get.AngularPositions( obj )
            
            % Convert the cumulative net sent amounts to radians.
            cumulativeSourceFlows = cumsum( [0; obj.NetSent] );
            value = 2 * pi * cumulativeSourceFlows / ...
                cumulativeSourceFlows(end);
            
        end % get.AngularSizes
        
        function value = get.NodeSizes( obj )
            
            % Scale the net amounts received by each sink.
            value = obj.NodeScaleFactor * ...
                obj.NetReceived / sum( obj.NetReceived );
            
        end % get.NodeSizes
        
        function value = get.NodePositions( obj )
            
            % The angular node positions are the midpoints of the angular
            % arc positions.
            value = (obj.AngularPositions(1:end-1) + ...
                obj.AngularPositions(2:end)) / 2;
            
        end % get.NodePositions
        
    end % methods
    
    methods
        
        function varargout = title( obj, varargin )
            
            [varargout{1:nargout}] = title( obj.Axes, varargin{:} );
            
        end % title
        
    end % methods
    
    methods ( Access = protected )
        
        function setup( obj )
            %SETUP Initialize the chart graphics.
            
            % Create the axes.
            obj.Axes = axes( "Parent", obj.getLayout(), ...                
                "Visible", "off", ...
                "DataAspectRatio", [1, 1, 1] );
            obj.Axes.Toolbar = [];
            disableDefaultInteractivity( obj.Axes )
            
        end % setup
        
        function update( obj )
            %UPDATE Refresh the chart graphics.
            
            if obj.ComputationRequired
                
                % Create the chart graphics.
                % First, draw the circumferential arcs.
                hold( obj.Axes, "on" )
                for k = obj.NumSources:-1:1
                    theta(:, k) = ...
                        linspace( obj.AngularPositions(k) + obj.AngularGap, ...
                        obj.AngularPositions(k+1) - obj.AngularGap );
                end % for
                rho = obj.OuterRadius * ones( size( theta ) );
                [X, Y] = pol2cart( theta, rho );
                obj.Arcs = gobjects( obj.NumSources, 1 );
                for k = 1:obj.NumSources
                    obj.Arcs(k) = line( "Parent", obj.Axes, ...
                        "XData", X(:, k), ...
                        "YData", Y(:, k), ...
                        "LineWidth", 10, ...
                        "Color", obj.Colors(k, :) );
                end % for
                
                % Next, draw the receiving nodes in the interior of the
                % disk.
                [nodeX, nodeY] = ...
                    pol2cart( obj.NodePositions, obj.InnerRadius );
                obj.ReceivingNodes = gobjects( obj.NumSources, 1 );
                for k = 1:obj.NumSources
                    obj.ReceivingNodes(k) = line( "Parent", obj.Axes, ...
                        "XData", nodeX(k), ...
                        "YData", nodeY(k), ...
                        "Marker", "o", ...
                        "MarkerEdgeColor", obj.Colors(k, :), ...
                        "MarkerFaceColor", obj.Colors(k, :), ...
                        "MarkerSize", obj.NodeSizes(k) );
                end % for
                
                % Draw the patches and their labels. To create the color
                % transitions for each patch, we need to set the axes
                % colormap.
                colormap( obj.Axes, obj.PatchColormap )
                % Compute the angular differences, including the gap sizes.
                dtheta = diff( obj.AngularPositions ) - 2 * obj.AngularGap;
                % Compute the angular starting positions.
                thetaStart = ...
                    obj.AngularPositions(1:end-1) + obj.AngularGap;
                % Extract parameters required for the loop.
                pnf = obj.PositiveNetFlow;
                N = obj.NumTransitionPoints;
                numPosFlow = size( pnf, 1 );
                % Preallocate.
                obj.LinkPatches = gobjects( numPosFlow, 1 );
                obj.PatchLabels = gobjects( numPosFlow, 1 );
                for k = 1 : numPosFlow
                    % Compute the proportion of each circumferential arc to
                    % use as the base of the patch.
                    sourceIdx = pnf(k, 1);
                    sinkIdx = pnf(k, 2);
                    flowValue = obj.NetFlow{sourceIdx, sinkIdx};
                    arcProp = flowValue / obj.NetSent(sourceIdx);
                    % Starting and finishing angles for the patch base.
                    localThetaStart = thetaStart(sourceIdx);
                    thetaEnd = localThetaStart + ...
                        arcProp * dtheta(sourceIdx);
                    % Update the starting angle for the current source.
                    thetaStart(sourceIdx) = thetaEnd;
                    % Compute the patch coordinates.
                    thetaPatch = ...
                        [linspace( localThetaStart, thetaEnd, N ), ...
                        linspace( thetaEnd, ...
                        obj.NodePositions(sinkIdx), N ), ...
                        linspace( obj.NodePositions(sinkIdx), ...
                        localThetaStart, N )];
                    rhoPatch = [obj.OuterRadius * ones( 1, N ), ...
                        linspace( ...
                        obj.OuterRadius, obj.InnerRadius, N ), ...
                        linspace( obj.InnerRadius, obj.OuterRadius, N )];
                    [X, Y] = pol2cart( thetaPatch, rhoPatch );
                    % Compute the current patch color indices into the
                    % overall axes colormap.
                    colorIdx = [(N * (k-1) + 1) * ones( N, 1 ); ...
                        ((N * (k-1) + 1) : N * k).'; ...
                        (N * k : -1 : (N * (k-1) + 1)).'];
                    % Draw the patches.
                    obj.LinkPatches(k) = patch( "Parent", obj.Axes, ...
                        "XData", X, ...
                        "YData", Y, ...
                        "CData", colorIdx, ...
                        "FaceColor", "interp", ...
                        "EdgeColor", "interp", ...
                        "LineWidth", 1, ...
                        "FaceAlpha", 0.85 );
                    % Compute the coordinates for the patch labels.
                    [patchLabelX, patchLabelY] = pol2cart( ...
                        (localThetaStart + thetaEnd)/2, ...
                        obj.OuterRadius + obj.PatchLabelOffset );
                    % Construct the text for the patch label, using the
                    % color of the sink.
                    sinkColor = num2cell( obj.Colors(sinkIdx, :) );
                    patchLabelText = "\" + ...
                        sprintf( "color[rgb]{%f,%f,%f}%g", ...
                        sinkColor{:}, pnf(k, 3) );
                    % Create the patch labels.
                    obj.PatchLabels(k) = text( obj.Axes, ...
                        patchLabelX, ...
                        patchLabelY, ...
                        patchLabelText, ...
                        "FontUnits", "normalized", ...
                        "FontWeight", "bold", ...
                        "FontSize", obj.PatchLabelFontSize, ...
                        "VerticalAlignment", "middle", ...
                        "HorizontalAlignment", "center" );
                end % for
                
                % Create the outer labels.
                [outerLabelX, outerLabelY] = ...
                    pol2cart( obj.NodePositions, ...
                    obj.OuterRadius + obj.OuterLabelOffset );
                obj.OuterLabels = gobjects( obj.NumSources, 1 );
                for k = 1:obj.NumSources
                    % Form the outer label text from the user-provided text
                    % label and the net sent amounts.
                    s = obj.Labels{k} + " (" + ...
                        num2str( obj.NetSent(k) ) + ")";
                    c = num2cell( obj.Colors(k, :) );
                    formattedLabel = "\" + ...
                        sprintf( "color[rgb]{%f,%f,%f} %s", c{:}, s );
                    obj.OuterLabels(k) = text( obj.Axes, ...
                        outerLabelX(k), ...
                        outerLabelY(k), ...
                        formattedLabel, ...
                        "FontWeight", "bold", ...
                        "HorizontalAlignment", "center", ...
                        "VerticalAlignment", "middle", ...
                        "FontUnits", "normalized", ...
                        "FontSize", obj.OuterLabelFontSize );
                end % for
                
                % Draw the node labels.
                netReceivedText = num2str( obj.NetReceived );
                nodeLabelFontSize = 0.03 + 0.02 * ...
                    (obj.NodeSizes - min( obj.NodeSizes )) / ...
                    (max( obj.NodeSizes ) - min( obj.NodeSizes ));
                obj.NodeLabels = gobjects( obj.NumSources, 1 );
                for k = 1:obj.NumSources
                    obj.NodeLabels(k) = text( obj.Axes, ...
                        nodeX(k), ...
                        nodeY(k), ...
                        netReceivedText(k, :), ...
                        "FontWeight", "bold", ...
                        "Color", 0.1 * ones( 1, 3 ), ...
                        "HorizontalAlignment", "center", ...
                        "VerticalAlignment", "middle", ...
                        "FontUnits", "normalized", ...
                        "FontSize", nodeLabelFontSize(k) );
                end % for
                
                % Add the title.
                t = title( obj.Axes, "CircularNetFlow Chart", ...
                    "FontUnits", "normalized", ...
                    "FontSize", 0.05, ...
                    "Visible", "on" );
                t.Position(1) = t.Position(1) - obj.OuterRadius;                
                
                % Ensure all graphics objects are visible.
                p = vertcat( obj.OuterLabels.Position );
                p = [p; obj.Axes.Title.Position];
                set( obj.Axes, ...
                    "XLim", [min( p(:, 1) ), max( p(:, 1) )], ...
                    "YLim", [min( p(:, 2) ), max( p(:, 2) )] )
                hold( obj.Axes, "off" )
                
                % Mark the chart clean.
                obj.ComputationRequired = false;
                
            end % if
            
            % Refresh the chart's decorative properties.
            set( obj.LinkPatches, "FaceAlpha", obj.FaceAlpha )
            
        end % update
        
    end % methods ( Access = protected )
    
end % class definition