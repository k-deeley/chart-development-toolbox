classdef LineGradientChart < matlab.graphics.chartcontainer.ChartContainer
    %LINEGRADIENTCHART Chart for managing a variable-color curve plotted 
    %against a date/time vector.
    
    % Copyright 2018-2025 The MathWorks, Inc.
    
    properties ( Dependent )
        % Chart x-data.
        XData(:, 1) datetime {mustBeSorted}
        % Chart y-data.
        YData(:, 1) double {mustBeReal}
    end % properties ( Dependent )
    
    properties
        % Width of the line.
        LineWidth(1, 1) double {mustBePositive, mustBeFinite} = 0.5
        % Axes x-grid.
        XGrid(1, 1) matlab.lang.OnOffSwitchState = "on"
        % Axes y-grid.
        YGrid(1, 1) matlab.lang.OnOffSwitchState = "on"
    end % properties
    
    properties ( Access = private )
        % Internal storage for the XData property.
        XData_(2, :) datetime = NaT( 2, 1 )
        % Internal storage for the YData property.
        YData_(2, :) double {mustBeReal} = NaN( 2, 1 )
        % Logical scalar specifying whether a computation is required.
        ComputationRequired(1, 1) logical = false
    end % properties ( Access = private )
    
    properties ( Access = private, Transient, NonCopyable )
        % Chart axes.
        Axes(:, 1) matlab.graphics.axis.Axes {mustBeScalarOrEmpty}
        % Line with a color gradient, implemented internally as a surface.
        Surface(:, 1) matlab.graphics.primitive.Surface ...
            {mustBeScalarOrEmpty}
    end % properties ( Access = private, Transient, NonCopyable )
    
    properties ( Constant, Hidden )
        % Product dependencies.
        Dependencies(1, :) string = "MATLAB"
    end % properties ( Constant, Hidden )
    
    methods
        
        function value = get.XData( obj )
            
            value = obj.XData_(1, :).';
            
        end % get.XData
        
        function set.XData( obj, value )
            
            % Mark the chart for an update.
            obj.ComputationRequired = true;
            
            % Decide how to modify the chart data.
            nX = numel( value );
            nY = numel( obj.YData );
            
            if nX < nY % If the new x-data is too short ...
                % ... then chop the chart y-data.
                obj.YData_ = obj.YData_(:, 1:nX);
            else
                % Otherwise, if nX >= nY, then pad the y-data.
                obj.YData_(:, end+1:nX) = NaN;
            end % if
            
            % Set the internal x-data.
            obj.XData_ = [value(:), value(:)].';
            
        end % set.XData
        
        function value = get.YData( obj )
            
            value = obj.YData_(1, :).';
            
        end % get.YData
        
        function set.YData( obj, value )
            
            % Mark the chart for an update.
            obj.ComputationRequired = true;
            
            % Decide how to modify the chart data.
            nY = numel( value );
            nX = numel( obj.XData );
            
            if nY < nX % If the new y-data is too short ...
                % ... then chop the chart x-data.
                obj.XData_ = obj.XData_(:, 1:nY);
            else
                % Otherwise, if nY >= nX, then pad the x-data.
                obj.XData_(:, end+1:nY) = NaT;
            end % if
            
            % Set the internal y-data.
            obj.YData_ = [value(:), value(:)].';
            
        end % set.YData
        
    end % methods
    
    methods

        function obj = LineGradientChart( namedArgs )
            %LINEGRADIENTCHART Construct a LineGradientChart, given
            %optional name-value arguments.

            arguments ( Input )
                namedArgs.?LineGradientChart
            end % arguments ( Input )

            % Call the superclass constructor.
            f = figure( "Visible", "off" );
            figureCleanup = onCleanup( @() delete( f ) );
            obj@matlab.graphics.chartcontainer.ChartContainer( ...
                "Parent", f );
            obj.Parent = [];

            % Set any user-defined properties.
            set( obj, namedArgs )

        end % constructor
        
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
            
            % Ensure the properties are up-to-date.
            obj.XGrid = obj.Axes.XGrid;
            obj.YGrid = obj.Axes.YGrid;
            
        end % grid
        
        function varargout = colormap( obj, varargin )
            
            [varargout{1:nargout}] = colormap( obj.Axes, varargin{:} );
            
        end % colormap
        
        function varargout = colorbar( obj, varargin )
            
            [varargout{1:nargout}] = colorbar( obj.Axes, varargin{:} );
            
        end % colorbar
        
    end % methods
    
    methods ( Access = protected )
        
        function setup( obj )
            %SETUP Initialize the chart graphics.
            
            % Create the axes.
            obj.Axes = axes( "Parent", obj.getLayout() );
            
            % Create the chart graphics.
            obj.Surface = surface( obj.Axes, NaT( 2 ), NaN( 2 ), ...
                NaN( 2 ), NaN( 2 ), "EdgeColor", "flat" );           
            
        end % setup
        
        function update( obj )
            %UPDATE Refresh the chart graphics.
            
            if obj.ComputationRequired
                
                % Update the surface plot with the new data.
                z = zeros( size( obj.XData_ ) );
                set( obj.Surface, "XData", obj.XData_, ...
                    "YData", obj.YData_, ...
                    "ZData", z, ...
                    "CData", obj.YData_ );                
                % Mark the chart clean.
                obj.ComputationRequired = false;
                
            end % if
            
            % Refresh the chart's decorative properties.
            obj.Surface.LineWidth = obj.LineWidth;
            set( obj.Axes, "XGrid", obj.XGrid, "YGrid", obj.YGrid )
            
        end % update
        
    end % methods ( Access = private )
    
end % classdef

function mustBeSorted( d )
%MUSTBESORTED Validate that the input datetime vector is sorted.

assert( issorted( d ), ...
    "LineGradientChart:DecreasingData", ...
    "The LineGradient chart's x-data must be nondecreasing." )

end % mustBeSorted