classdef CylinderChart < matlab.graphics.chartcontainer.ChartContainer
    %CYLINDER Chart representing a stacked cylinder graph.
    %
    % Copyright 2018-2022 The MathWorks, Inc.
    
    properties ( Dependent )
        % Chart data.
        Data(:, :) double {mustBeReal, mustBeFinite, mustBeNonnegative}
    end % properties ( Dependent )
    
    properties
        % Axes view (azimuth, elevation).
        View = [-16, 12]
    end % properties
    
    properties ( Dependent )
        % Three-column numeric matrix of cylinder face colors.
        FaceColors(:, 3) double ...
            {mustBeReal, mustBeInRange( FaceColors, 0, 1 )}
    end % properties ( Dependent )
    
    properties ( Dependent, SetAccess = private )
        % Number of cylindrical stacks.
        NumStacks
        % Number of layers within each cylindrical stack.
        NumLayers
    end % properties ( Dependent, SetAccess = private )
    
    properties ( Access = private )
        % Internal storage for the Data property.
        Data_ = double.empty( 0, 0 )
        % Internal storage for the FaceColors property.
        FaceColors_ = cool()
        % Logical scalar specifying whether a computation is required.
        ComputationRequired = false
    end % properties ( Access = private )
    
    properties ( Access = private, Transient, NonCopyable )
        % Chart axes.
        Axes(1, 1) matlab.graphics.axis.Axes
        % Surface graphics objects used for the cylinders.
        CylinderSurfaces
    end % properties ( Access = private, Transient, NonCopyable )
    
    properties ( Constant, Hidden )
        % Product dependencies.
        Dependencies = "MATLAB"
    end % properties ( Constant, Hidden )
    
    methods
        
        function value = get.Data( obj )
            
            value = obj.Data_;
            
        end % get.Data
        
        function set.Data( obj, value )
            
            % Mark the chart for an update.
            obj.ComputationRequired = true;
            
            % Update the internal stored property.
            obj.Data_ = value;
            
        end % set.Data
        
        function value = get.FaceColors( obj )
            
            value = obj.FaceColors_;
            
        end % get.FaceColors
        
        function set.FaceColors( obj, value )
            
            % Check the user-supplied list of colors.
            assert( isequal( size( value ), [obj.NumLayers, 3] ), ...
                "Cylinder:InvalidFaceColors", ...
                "The FaceColors property must be a matrix with the number of rows equal to the number of data columns." )
            
            % Update the face colors of each layer in each stack.
            drawnow()
            for k = 1:obj.NumLayers
                set( obj.CylinderSurfaces(:, k), "FaceColor", value(k, :) )
            end % for
            
            % Update the internal stored property.
            obj.FaceColors_ = value;
            
        end % set.FaceColors
        
        function value = get.NumStacks( obj )
            
            value = height( obj.Data_ );
            
        end % get.NumStacks
        
        function value = get.NumLayers( obj )
            
            value = width( obj.Data_ );
            
        end % get.NumLayers
        
    end % methods
    
    methods
        
        function varargout = xlabel( obj, varargin )
            
            [varargout{1:nargout}] = xlabel( obj.Axes, varargin{:} );
            
        end % xlabel
        
        function varargout = zlabel( obj, varargin )
            
            [varargout{1:nargout}] = zlabel( obj.Axes, varargin{:} );
            
        end % zlabel
        
        function varargout = title( obj, varargin )
            
            [varargout{1:nargout}] = title( obj.Axes, varargin{:} );
            
        end % title
        
        function varargout = legend( obj, varargin )
            
            if ~isempty( obj.CylinderSurfaces )
                [varargout{1:nargout}] = legend( ...
                    obj.CylinderSurfaces(1, :), varargin{:} );
            end % if
            
        end % legend
        
        function varargout = xticklabels( obj, varargin )
            
            [varargout{1:nargout}] = xticklabels( obj.Axes, varargin{:} );
            
        end % xticklabels
        
        function varargout = xtickangle( obj, varargin )
            
            [varargout{1:nargout}] = xtickangle( obj.Axes, varargin{:} );
            
        end % xtickangle
        
    end % methods
    
    methods ( Access = protected )
        
        function setup( obj )
            %SETUP Initialize the chart graphics.
            
            % Create the axes.
            obj.Axes = axes( "Parent", obj.getLayout(), ...                
                "XGrid", "on", ...
                "YGrid", "on", ...
                "ZGrid", "on", ...
                "YLim", [-2, 4], ...
                "YTick", [], ...
                "Color", [0.7, 0.7, 0.7] );
            
            % Set the required axes properties.
            obj.Axes.DataAspectRatio(1:2) = [1, 1];
            obj.Axes.ZAxis.TickDirection = "in";
            obj.Axes.ZAxis.TickLength(2) = ...
                3 * obj.Axes.ZAxis.TickLength(2);
            
        end % setup
        
        function update( obj )
            %UPDATE Refresh the chart graphics.
            
            if obj.ComputationRequired
                
                % First, record the previous number of layers (this is used to
                % preserve the existing face colors if possible).
                prevNumLayers = width( obj.CylinderSurfaces );
                % Similarly, record the previous number of stacks (this is used
                % to preserve the existing tick labels if possible).
                prevNumStacks = height( obj.CylinderSurfaces );
                
                % Update the number of surface objects in accordance with the
                % data. Start by deleting the existing cylinders if they exist.
                if ~isempty( obj.CylinderSurfaces )
                    delete( obj.CylinderSurfaces )
                end % if
                
                % Preallocate storage for the new cylinders.
                obj.CylinderSurfaces = gobjects( obj.NumStacks, obj.NumLayers);
                
                % Determine the face colors: use the previous colors if
                % possible; otherwise, revert to a default set of colors.
                if obj.NumLayers <= prevNumLayers
                    obj.FaceColors_ = obj.FaceColors_(1 : obj.NumLayers, :);
                else
                    obj.FaceColors_ = cool( obj.NumLayers );
                end % if
                
                % Create the new cylinders.
                for k1 = 1 : obj.NumStacks
                    for k2 = 1 : obj.NumLayers
                        obj.CylinderSurfaces(k1, k2) = ...
                            surface( obj.Axes, [], [], [], ...
                            "FaceColor", obj.FaceColors_(k2, :), ...
                            "EdgeAlpha", 0 );
                    end % for k2
                end % for k1
                
                % Compute the cylindrical coordinates.
                % Define the number of points used for the cylinder
                % circumferences and the radius of the cylinders.
                n = 1000;
                r = 2 * [1; 1];
                % Cylinder heights above the (x, y) plane.
                heights = [zeros( obj.NumStacks, 1 ), cumsum( obj.Data_, 2 )];
                % Angles from 0 to 2*pi.
                theta = 2 * ( 0 : n ) / n;
                % Compute sin(theta), ensuring the final value is exactly zero.
                sintheta = sinpi( theta );
                rsintheta = r * sintheta;
                rcostheta = r * cospi( theta );
                % Compute the coordinates of the cylinders, and update the
                % surface objects and rings.
                y = 1 + rsintheta;
                for k1 = 1:obj.NumStacks
                    x = 5*k1 + rcostheta;
                    for k2 = 1:obj.NumLayers
                        z = heights(k1, k2:(k2+1)).' * ones( 1, n + 1 );
                        set( obj.CylinderSurfaces(k1, k2), ...
                            "XData", x, "YData", y, "ZData", z )
                    end % for k2
                end % for k1
                
                % Update the axes properties.
                set( obj.Axes, "XLim", [1, 5 * obj.NumStacks + 4], ...
                    "XTick", 5 * (1 : obj.NumStacks) )
                % Reuse the previous tick labels, if possible.
                if obj.NumStacks <= prevNumStacks
                    obj.Axes.XTickLabel = obj.Axes.XTickLabel(1:obj.NumStacks);
                else
                    obj.Axes.XTickLabel = 1:obj.NumStacks;
                end % if
                
                % Mark the chart clean.
                obj.ComputationRequired = false;
                
            end % if
            
            % Refresh the chart's decorative properties.
            obj.Axes.View = obj.View;
            
        end % update
        
    end % methods ( Access = protected )
    
end % class definition