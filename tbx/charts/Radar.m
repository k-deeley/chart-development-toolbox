classdef Radar < matlab.graphics.chartcontainer.ChartContainer
    %RADAR Chart displaying a line graph of dependent numeric variables
    %plotted against independent circular data.
    %
    % Copyright 2018-2022 The MathWorks, Inc.
    
    properties ( Dependent )
        % Chart angular data.
        AngularData(:, 1) double {mustBeReal, mustBeNonDecreasing}
        % Chart radial data.
        RadialData(:, 2) double {mustBeReal}
    end % properties ( Dependent )
    
    properties
        % Width of the lines.
        LineWidth = 1.5
        % Marker size.
        MarkerSize = 6
    end % properties
    
    properties ( Access = private )
        % Internal storage for the AngularData property.
        AngularData_ = NaN( 1, 1 )
        % Internal storage for the RadialData property.
        RadialData_ = NaN( 1, 2 )
        % Logical scalar specifying whether a computation is required.
        ComputationRequired = false()
    end % properties ( Access = private )
    
    properties ( Access = private )
        % Chart axes.
        Axes(1, 1) matlab.graphics.axis.PolarAxes
        % Circular line plots.
        PolarLines(2, 1) matlab.graphics.chart.primitive.Line
    end % properties ( Access = private )
    
    properties ( Constant, Hidden )
        % Product dependencies.
        Dependencies = "MATLAB"
    end % properties ( Constant, Hidden )
    
    methods
        
        function value = get.AngularData( obj )
            
            value = obj.AngularData_;
            
        end % get.AngularData
        
        function set.AngularData( obj, value )
            
            % Mark the chart for an update.
            obj.ComputationRequired = true();
            
            % Set the internal data property.
            obj.AngularData_ = value;
            % Update the radial data.
            nTheta = numel( value );
            nRadial = size( obj.RadialData_, 1 );
            if nTheta < nRadial
                obj.RadialData_ = obj.RadialData_(1:nTheta, :);
            else
                obj.RadialData_(end+1:nTheta, :) = NaN;
            end % if
            
        end % set.AngularData
        
        function value = get.RadialData( obj )
            
            value = obj.RadialData_;
            
        end % get.RadialData
        
        function set.RadialData( obj, value )
            
            % Mark the chart for an update.
            obj.ComputationRequired = true();
            
            % Update the internal data property.
            obj.RadialData_ = value;
            % Update the angular data.
            nTheta = numel( obj.AngularData_ );
            nRadial = size( obj.RadialData_, 1 );
            if nRadial < nTheta
                obj.AngularData_ = obj.AngularData_(1:nRadial);
            else
                obj.AngularData_(end+1:nRadial, 1) = NaN();
            end % if
            
        end % set.RadialData
        
    end % methods
    
    methods
        
        function varargout = title( obj, varargin )
            
            [varargout{1:nargout}] = title( obj.Axes, varargin{:} );
            
        end % title
        
        function varargout = legend( obj, varargin )
            
            [varargout{1:nargout}] = legend( obj.Axes, varargin{:} );
            
        end % legend
        
        function varargout = rticks( obj, varargin )
            
            [varargout{1:nargout}] = rticks( obj.Axes, varargin{:} );
            
        end % rticks
        
        function varargout = rticklabels( obj, varargin )
            
            [varargout{1:nargout}] = rticklabels( obj.Axes, varargin{:} );
            
        end % rticklabels
        
        function varargout = rtickformat( obj, varargin )
            
            [varargout{1:nargout}] = rtickformat( obj.Axes, varargin{:} );
            
        end % rticklabels
        
        function varargout = rtickangle( obj, varargin )
            
            [varargout{1:nargout}] = rtickangle( obj.Axes, varargin{:} );
            
        end % rtickangle
        
        function varargout = thetaticks( obj, varargin )
            
            [varargout{1:nargout}] = thetaticks( obj.Axes, varargin{:} );
            
        end % thetaticks
        
        function varargout = thetaticklabels( obj, varargin )
            
            [varargout{1:nargout}] = ...
                thetaticklabels( obj.Axes, varargin{:} );
            
        end % thetaticklabels
        
        function varargout = thetatickformat( obj, varargin )
            
            [varargout{1:nargout}] = ...
                thetatickformat( obj.Axes, varargin{:} );
            
        end % thetatickformat
        
    end % methods
    
    methods ( Access = protected )
        
        function setup( obj )
            %SETUP Initialize the chart graphics.
            
            % Create the polar axes.
            obj.Axes = polaraxes( "Parent", obj.getLayout(), ...
                "ThetaZeroLocation", "top", ...
                "ThetaAxisUnits", "radians", ...
                "ThetaDir", "clockwise" );
            
            % Create the polar lines.
            hold( obj.Axes, "on" )
            obj.PolarLines = polarplot( obj.Axes, obj.AngularData_, ...
                obj.RadialData_, ...
                "Marker", ".", ...
                "MarkerSize", 10, ...
                "LineStyle", "-", ...
                "LineWidth", 1.5 );
            hold( obj.Axes, "off" )
            
        end % setup
        
        function update( obj )
            %UPDATE Refresh the chart graphics.
            
            if obj.ComputationRequired
                
                % Update the lines.
                x = obj.AngularData_;
                theta = x2theta( x );
                set( obj.PolarLines(1), "ThetaData", theta, ...
                    "RData", obj.RadialData_(:, 1) );
                set( obj.PolarLines(2), "ThetaData", theta, ...
                    "RData", obj.RadialData_(:, 2) );
                
                % Update the angular ticks and tick labels.
                nx = numel( x );
                thetaTicks = linspace( 0, theta(end), nx );
                thetaTickLabels = min( x ) + (max( x ) - min( x )) * ...
                    thetaTicks / theta(end);
                thetaticks( obj, thetaTicks )
                thetaticklabels( obj, thetaTickLabels )
                
                % Mark the chart clean.
                obj.ComputationRequired = false();
                
            end % if
            
            % Refresh the chart's decorative properties.
            set( obj.PolarLines, "LineWidth", obj.LineWidth, ...
                "MarkerSize", obj.MarkerSize )
            
        end % update
        
    end % methods ( Access = protected )
    
end % class definition

function theta = x2theta( x )
%X2THETA Convert an increasing x-data vector to the corresponding angular
%values in radians.

nx = numel( x );
theta = (2 * pi * (1 - 1 / nx))* (x - min( x )) / (max( x ) - min( x ));

end % x2theta

function mustBeNonDecreasing( v )
%MUSTBENONDECREASING Validate that the input vector is nondecreasing.

validateattributes( v, "double", "nondecreasing" )

end % mustBeNonDecreasing