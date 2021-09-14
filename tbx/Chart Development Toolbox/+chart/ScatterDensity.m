classdef ScatterDensity < matlab.graphics.chartcontainer.ChartContainer
    %SCATTERDENSITY Chart managing 2D scattered data (x and y), using a
    %color scheme applied to the data points indicating the relative
    %data density.
    %
    % Copyright 2019-2021 The MathWorks, Inc.
    
    properties ( Dependent )
        % Chart x-data.
        XData(:, 1) double {mustBeReal}
        % Chart y-data.
        YData(:, 1) double {mustBeReal}
        % Radius of the density circle.
        Radius(1, 1) double {mustBeNonnegative, mustBeFinite}
        % Density calculation method.
        DensityMethod(1, 1) string ...
            {mustBeMember( DensityMethod, ["boundary", "noboundary"] ) }
    end % properties ( Dependent )
    
    properties
        % Marker for the scatter series.
        Marker = "."
        % Size data for the scatter series.
        SizeData = 36
        % Axes x-grid.
        XGrid = "on"
        % Axes y-grid.
        YGrid = "on"        
    end % properties
    
    properties ( Dependent )
        % Axes color limits.
        CLim
    end % properties ( Dependent )
    
    properties ( Access = private )
        % Internal storage for the XData property.
        XData_ = double.empty( 0, 1 )
        % Internal storage for the YData property.
        YData_ = double.empty( 0, 1 )
        % Internal storage for the Radius property.
        Radius_ = 0.25
        % Internal storage for the DensityMethod property.
        DensityMethod_ = "noboundary"
        % Logical scalar specifying whether a computation is required.
        ComputationRequired = false()
    end % properties ( Access = private )
    
    properties ( Access = private, Transient, NonCopyable )
        % Chart axes.
        Axes(1, 1) matlab.graphics.axis.Axes
        % Scatter series for the (x, y) data.
        ScatterSeries(1, 1) matlab.graphics.chart.primitive.Scatter
        % Rectangle object drawn to show the domain boundary.
        BoundingBox(1, 1) matlab.graphics.primitive.Rectangle
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
            
            % Reset the scatter series' size data if necessary.
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
            obj.YData_ = value(:);
            
            % Reset the scatter series' size data if necessary.
            nS = numel( obj.SizeData );
            if nS > 1 && nY ~= nS
                obj.SizeData = 36;
            end % if
            
        end % set.YData
        
        function value = get.Radius( obj )
            
            value = obj.Radius_;
            
        end % get.Radius
        
        function set.Radius( obj, value )
            
            % Mark the chart for an update.
            obj.ComputationRequired = true();
            
            % Set the internal value.
            obj.Radius_ = value;
            
        end % set.Radius
        
        function value = get.DensityMethod( obj )
            
            value = obj.DensityMethod_;
            
        end % get.DensityMethod
        
        function set.DensityMethod( obj, value )
            
            % Mark the chart for an update.
            obj.ComputationRequired = true();
            
            % Set the internal value.
            obj.DensityMethod_ = value;
            
        end % set.DensityMethod
        
        function value = get.CLim( obj )
            
            value = obj.Axes.CLim;
            
        end % get.CLim
        
        function set.CLim( obj, value )
            
            obj.Axes.CLim = value;
            
        end % set.CLim
        
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
        
        function grid( obj, varargin )
            
            % Invoke grid on the axes.
            grid( obj.Axes, varargin{:} )
            
            % Update the chart's decorative properties.
            obj.XGrid = obj.Axes.XGrid;
            obj.YGrid = obj.Axes.YGrid;
            
        end % grid
        
        function varargout = legend( obj, varargin )
            
            [varargout{1:nargout}] = legend( obj.Axes, varargin{:} );
            
        end % legend
        
        function varargout = colorbar( obj, varargin )
            
            [varargout{1:nargout}] = colorbar( obj.Axes, varargin{:} );
            
        end % colorbar
        
        function varargout = colormap( obj, varargin )
            
            [varargout{1:nargout}] = colormap( obj.Axes, varargin{:} );
            
        end % colormap
        
    end % methods
    
    methods ( Access = protected )
        
        function setup( obj )
            %SETUP Initialize the chart graphics.
            
            % Create the chart's axes.
            obj.Axes = axes( "Parent", obj.getLayout(), ...
                "Colormap", parula() );
            % Add the colorbar.
            colorbar( obj )
            
            % Create the scatter plot.
            hold( obj.Axes, "on" )
            obj.ScatterSeries = scatter( obj.Axes, NaN, NaN, "." );
            
            % Create the bounding box.
            obj.BoundingBox = rectangle( obj.Axes, ...
                "Visible", "off", ...
                "Position", zeros( 1, 4 ), ...
                "LineWidth", 3 );
            hold( obj.Axes, "off" )
            
        end % setup
        
        function update( obj )
            %UPDATE Refresh the chart graphics.
            
            if obj.ComputationRequired
                
                % Evaluate the new color data for the scatter series.
                
                % First, extract the chart data.
                x = obj.XData_;
                y = obj.YData_;
                
                % Deal with the case where all the x-data or all the y-data
                % is missing.
                if all( isnan( x ) ) || all( isnan( y ) )
                    newCData = NaN;
                else
                    % Otherwise we can evaluate point densities.
                    [xmin, xmax] = bounds( x );
                    [ymin, ymax] = bounds( y );
                    % Compute the pairwise distances between the scattered
                    % data points.
                    pointDistances = pdist2( [x, y], [x, y] );
                    % Estimate the maximum possible radius based on the
                    % diagonal of the data span.
                    maxRad = sqrt( (xmax-xmin)^2 + (ymax-ymin)^2 );
                    % Update the internal radius value.
                    obj.Radius_ = min( obj.Radius_, maxRad );
                    
                    % Compute the density at each data point, excluding the
                    % point itself.
                    pointCounts = ...
                        sum( pointDistances <= obj.Radius_, 2 ) - 1;
                    
                    % Depending on the selected density method, compute the
                    % intersection area.
                    switch obj.DensityMethod_
                        case "boundary"
                            % Compute the intersection area for each data
                            % point.
                            normArea = NaN( size( x ) );
                            for k = 1:numel( x )
                                normArea(k) = intersectionArea( ...
                                    x(k), y(k), obj.Radius_, ....
                                    xmin, xmax, ymin, ymax );
                            end % for
                            % Update the bounding box.
                            set( obj.BoundingBox, "Visible", "on", ...
                                "Position", ...
                                [xmin, ymin, xmax-xmin, ymax-ymin] )
                        case "noboundary"
                            % This is the simpler case when the point
                            % counts are normalized by the circular area.
                            normArea = 2 * pi * obj.Radius_^2;
                            obj.BoundingBox.Visible = "off";
                    end % switch/case
                    
                    % Normalize the point counts by the area.
                    newCData = pointCounts ./ normArea;
                    
                end % if
                
                % Update the scatter series with the new chart data and
                % color data.
                set( obj.ScatterSeries, "XData", obj.XData_, ...
                    "YData", obj.YData_, "CData", newCData )
                obj.Axes.CLimMode = "auto";
                
                % Mark the chart clean.
                obj.ComputationRequired = false();
                
            end % if
            
            % Refresh the chart's decorative properties.
            set( obj.ScatterSeries, "Marker", obj.Marker, ...
                "SizeData", obj.SizeData )
            set( obj.Axes, "XGrid", obj.XGrid, "YGrid", obj.YGrid, ...
                "CLim", obj.CLim )
            
        end % update
        
    end % methods ( Access = protected )
    
end % class definition

function A = intersectionArea( xc, yc, r, xmin, xmax, ymin, ymax )
%INTERSECTIONAREA Compute the area of the intersection of a circle of
%radius r centered around the point (xc, yc) within the rectangle (xmin,
%ymin), (xmax, ymin), (xmax, ymax), (xmin, ymax).

% If the circle is within the rectangle, return the area of the circle.
if (xc + r < xmax) && (xc - r > xmin) && ...
        (yc + r < ymax) && (yc - r > ymin)
    A = pi * r^2;
else
    % Compute the distances from the center of the circle to each of the
    % four vertices of the rectangle.
    c(1) = sqrt( (xc - xmin)^2 + (yc - ymin)^2 ); % Bottom left vertex
    c(2) = sqrt( (xc - xmin)^2 + (yc - ymax)^2 ); % Bottom right vertex
    c(3) = sqrt( (xc - xmax)^2 + (yc - ymax)^2 ); % Top right vertex
    c(4) = sqrt( (xc - xmax)^2 + (yc - ymin)^2 ); % Top left vertex
    
    if r >= max( c )
        % Return the area of the box.
        A = (xmax-xmin) * (ymax-ymin);
    else
        % Subtract the area of the circle lying outside the rectangle.
        A = pi * r^2;
        if xc + r > xmax
            d = xmax - xc;
            A = subtractExternalArea( r, d, A );
        end % if
        if xc - r < xmin
            d = xc - xmin;
            A = subtractExternalArea( r, d, A );
        end % if
        if yc + r > ymax
            d = ymax - yc;
            A = subtractExternalArea( r, d, A );
        end % if
        if yc - r < ymin
            d = yc - ymin;
            A = subtractExternalArea( r, d, A );
        end % if
        % If necessary, add back the intersection of the external areas.
        if r > c(1)
            dx = xc - xmin;
            dy = yc - ymin;
            A = addExternalIntersectionArea( dx, dy, r, A );
        end % if
        if r > c(2)
            dx = xc - xmin;
            dy = ymax - yc;
            A = addExternalIntersectionArea( dx, dy, r, A );
        end % if
        if r > c(3)
            dx = xmax - xc;
            dy = ymax - yc;
            A = addExternalIntersectionArea( dx, dy, r, A );
        end % if
        if r > c(4)
            dx = xmax - xc;
            dy = yc - ymin;
            A = addExternalIntersectionArea( dx, dy, r, A );
        end % if
        
    end % if
    
end % if

    function newArea = subtractExternalArea( r, d, oldArea )
        
        % Compute the area outside the rectangle and inside the circle in
        % either the x or y direction (a "half-moon").
        theta = acos( d/r );
        sectorArea = 0.5 * theta * r^2;
        triangleArea = 0.5 * r * sin( theta ) * d;
        externalArea = sectorArea - triangleArea;
        % Subtract this area from the input area.
        newArea = oldArea - externalArea;
        
    end % subtractExternalArea

    function newArea = addExternalIntersectionArea( dx, dy, r, oldArea )
        
        % Evaluate the area of the "quarter-moon".
        thetax = asin( dy/r );
        thetay = asin( dx/r );
        b1 = r * cos( thetax ) - dx;
        b2 = r * cos( thetay ) - dy;
        sectorAngle = pi/2 - thetax - thetay;
        sectorArea = 0.5 * sectorAngle * r^2;
        triangleArea1 = 0.5 * b1 * dy;
        triangleArea2 = 0.5 * b2 * dx;
        externalArea = sectorArea - triangleArea1 - triangleArea2;
        % Add this area to the input area.
        newArea = oldArea + externalArea;
        
    end % addExternalIntersectionArea

end % intersectionArea