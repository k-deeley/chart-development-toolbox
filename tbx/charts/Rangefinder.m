classdef Rangefinder < matlab.graphics.chartcontainer.ChartContainer
    %RANGEFINDER Rangefinder chart for bivariate scattered data.
    %The rangefinder chart displays a 2D scatter plot overlaid with a
    %marker at the crossover point of the marginal medians and lines
    %indicating the marginal adjacent values.
    %
    % Copyright 2018-2022 The MathWorks, Inc.
    
    properties ( Dependent )
        % Chart x-data.
        XData(:, 1) double {mustBeReal}
        % Chart y-data.
        YData(:, 1) double {mustBeReal}
    end % properties ( Dependent )
    
    properties
        % Marker for the discrete plot.
        Marker = "o"
        % Size data for the discrete plot.
        SizeData = 36
        % Color of the discrete plot.
        CData = [0, 0.4470, 0.7410]
        % Axes x-grid.
        XGrid = "on"
        % Axes y-grid.
        YGrid = "on"
    end % properties
    
    properties ( Access = private )
        % Internal storage for the XData property.
        XData_ = double.empty( 0, 1 )
        % Internal storage for the YData property.
        YData_ = double.empty( 0, 1 )
        % Logical scalar specifying whether a computation is required.
        ComputationRequired = false()
    end % properties ( Access = private )
    
    properties ( Access = private, Transient, NonCopyable )
        % Chart axes.
        Axes(1, 1) matlab.graphics.axis.Axes
        % Scatter series for the discrete bivariate data.
        ScatterSeries(1, 1) matlab.graphics.chart.primitive.Scatter
        % Line objects used for the median crossover.
        MedianCrossoverLines(4, 1) matlab.graphics.primitive.Line
        % Line objects used for the adjacent values.
        AdjacentLines(4, 1) matlab.graphics.chart.primitive.Line
    end % properties ( Access = private, Transient, NonCopyable )
    
    properties ( Constant, Hidden )
        % Product dependencies.
        Dependencies = ["MATLAB", ...
            "Statistics and Machine Learning Toolbox"]
    end % properties ( Constant, Hidden )
    
    methods
        
        function value = get.XData( obj )
            
            value = obj.XData_;
            
        end % get.XData
        
        function set.XData( obj, value )
            
            % Mark the chart for an update.
            obj.ComputationRequired = true();
            
            % Decide how to modify the chart data.
            nX = numel( value );
            nY = numel( obj.YData_ );
            
            if nX < nY % If the new x-data is too short ...
                % ... then chop the chart y-data.
                obj.YData_ = obj.YData_(1:nX);
            else
                % Otherwise, if nX >= nY, then pad the y-data.
                obj.YData_(end+1:nX, 1) = NaN;
            end % if
            
            % Set the internal x-data.
            obj.XData_ = value;
            
            % Reset the scatter series' color and size data if necessary.
            nC = size( obj.CData, 1 );
            if nC > 1 && nX ~= nC
                obj.CData = obj.Axes.ColorOrder(1, :);
            end % if
            nS = numel( obj.SizeData );
            if nS > 1 && nX ~= nS
                obj.SizeData = 36;
            end % if
            
        end % set.XData
        
        function value = get.YData( obj )
            
            value = obj.YData_;
            
        end % get.YData
        
        function set.YData( obj, value )
            
            % Mark the chart for an update.
            obj.ComputationRequired = true();
            
            % Decide how to modify the chart data.
            nY = numel( value );
            nX = numel( obj.XData_ );
            
            if nY < nX % If the new y-data is too short ...
                % ... then chop the chart x-data.
                obj.XData_ = obj.XData_(1:nY);
            else
                % Otherwise, if nY >= nX, then pad the x-data.
                obj.XData_(end+1:nY, 1) = NaN;
            end % if
            
            % Set the internal y-data.
            obj.YData_ = value;
            
            % Reset the color and size data if necessary.
            nC = size( obj.CData, 1 );
            if nC > 1 && nY ~= nC
                obj.CData = obj.Axes.ColorOrder(1, :);
            end % if
            nS = numel( obj.SizeData );
            if nS > 1 && nY ~= nS
                obj.SizeData = 36;
            end % if
            
        end % set.YData
        
    end % methods
    
    methods
        
        function varargout = xlabel( obj, varargin )
            
            [varargout{1:nargout}] = xlabel( obj.Axes, varargin{:} );
            
        end % xlabel
        
        function varargout = ylabel( obj, varargin )
            
            [varargout{1:nargout}] = ylabel( obj.Axes, varargin{:} );
            
        end % ylabel
        
        function varargout = title( obj, varargin )
            
            [varargout{1:nargout}] = title( obj.Axes, varargin{:} );
            
        end % title
        
    end % methods
    
    methods ( Access = protected )
        
        function setup( obj )
            %SETUP Initialize the chart graphics.
            
            % Create the chart's axes.
            obj.Axes = axes( "Parent", obj.getLayout() );
            
            % Initialize the scatter plot.
            obj.ScatterSeries = scatter( obj.Axes, NaN, NaN );
            
            % Next, create the median crossover. This comprises two
            % perpendicular line segments with markers at their crossover
            % point.
            crossoverColor = "k";
            crossoverMarkers = ["none", "none", "o", "x"];
            crossoverMarkerSizes = [6, 6, 20, 20];
            for k = 1:4
                obj.MedianCrossoverLines(k) = line( ...
                    "Parent", obj.Axes, ...
                    "XData", NaN, ...
                    "YData", NaN, ...
                    "Color", crossoverColor, ...
                    "Marker", crossoverMarkers(k), ...
                    "MarkerSize", crossoverMarkerSizes(k), ...
                    "LineWidth", 2 );
            end % for
            
            % Create the line segments for the adjacent values.
            segmentColor = obj.Axes.ColorOrder(4, :);
            hold( obj.Axes, "on" )
            for k = 1:4
                obj.AdjacentLines(k) = plot( obj.Axes, NaN, NaN, ...
                    "Color", segmentColor, ...
                    "LineWidth", 3 );
                % Define the labels for the custom datatips.
                if k <= 2
                    lbl = "(x):";
                else
                    lbl = "(y):";
                end % if
                obj.AdjacentLines(k).DataTipTemplate. ...
                    DataTipRows(1).Label = "Lower adjacent value " + lbl;
                obj.AdjacentLines(k).DataTipTemplate. ...
                    DataTipRows(2).Label = "Lower quartile " + lbl;
                obj.AdjacentLines(k).DataTipTemplate. ...
                    DataTipRows(3).Label = "Median " + lbl;
                obj.AdjacentLines(k).DataTipTemplate. ...
                    DataTipRows(4).Label = "Upper quartile " + lbl;
                obj.AdjacentLines(k).DataTipTemplate. ...
                    DataTipRows(5).Label = "Upper adjacent value " + lbl;
                obj.AdjacentLines(k).DataTipTemplate. ...
                    DataTipRows(6).Label = "Interquartile range " + lbl;
            end % for
            hold( obj.Axes, "off" )
            
        end % setup
        
        function update( obj )
            %UPDATE Refresh the chart graphics.
            
            if obj.ComputationRequired
                
                % Update the scatter plot.
                set( obj.ScatterSeries, "XData", obj.XData_, ...
                    "YData", obj.YData_ )
                
                % Compute the marginal quartiles.
                qx = quantile( obj.XData_, [0.25, 0.50, 0.75] );
                qy = quantile( obj.YData_, [0.25, 0.50, 0.75] );
                
                % Compute the interquartile ranges.
                iqrx = qx(3) - qx(1);
                iqry = qy(3) - qy(1);
                
                % Update the median crossover graphics.
                set( obj.MedianCrossoverLines(1), ...
                    "XData", qx([1, 3]), ...
                    "YData", qy([2, 2]) )
                set( obj.MedianCrossoverLines(2), ...
                    "XData", qx([2, 2]), ...
                    "YData", qy([1, 3]) )
                set( obj.MedianCrossoverLines(3), ...
                    "XData", qx(2), ...
                    "YData", qy(2) )
                set( obj.MedianCrossoverLines(4), ...
                    "XData", qx(2), ...
                    "YData", qy(2) )
                
                % Update the adjacent lines. To do this, we compute the
                % upper and lower limits.
                xLimits = [qx(1)-1.5*iqrx, qx(3)+1.5*iqrx];
                yLimits = [qy(1)-1.5*iqry, qy(3)+1.5*iqry];
                internalxIdx = obj.XData_ > xLimits(1) & ...
                    obj.XData_ < xLimits(2);
                internalyIdx = obj.YData_ > yLimits(1) & ...
                    obj.YData_ < yLimits(2);
                adjx = [min(obj.XData_(internalxIdx)), ...
                    max(obj.XData_(internalxIdx))];
                adjy = [min(obj.YData_(internalyIdx)), ...
                    max(obj.YData_(internalyIdx))];
                
                % Deal with the case when no adjacent values exist.
                if isempty( adjx )
                    adjx = NaN( 1, 2 );
                end % if
                if isempty( adjy )
                    adjy = NaN( 1, 2 );
                end % if
                
                % Update the adjacent lines.
                set( obj.AdjacentLines(1), ...
                    "XData", [adjx(1), adjx(1)], ...
                    "YData", qy([1, 3]) )
                set( obj.AdjacentLines(2), ...
                    "XData", [adjx(2), adjx(2)], ...
                    "YData", qy([1, 3]) )
                set( obj.AdjacentLines(3), ...
                    "XData", qx([1, 3]), ...
                    "YData", [adjy(1), adjy(1)] )
                set( obj.AdjacentLines(4), ...
                    "XData", qx([1, 3]), ...
                    "YData", [adjy(2), adjy(2)] )
                
                % Update the values in the custom datatips.
                for k = 1:4
                    if k <= 2
                        newTipVals = [adjx(1), qx, adjx(2), iqrx];
                    else
                        newTipVals = [adjy(1), qy, adjy(2), iqry];
                    end % if
                    for kk = 1:length( newTipVals )
                        obj.AdjacentLines(k).DataTipTemplate. ...
                            DataTipRows(kk).Value = ...
                            newTipVals(kk) * [1, 1];
                    end % for
                end % for
                
                % Mark the chart clean.
                obj.ComputationRequired = false();
                
            end % if
            
            % Refresh the chart's decorative properties.
            set( obj.ScatterSeries, "Marker", obj.Marker, ...
                "SizeData", obj.SizeData, ...
                "CData", obj.CData )
            set( obj.Axes, "XGrid", obj.XGrid, "YGrid", obj.YGrid )
            
        end % update
        
    end % methods ( Access = protected )
    
end % class definition