classdef InductionMotorChart < Chart
    %INDUCTIONMOTORCHART Chart representing the operating performance of an
    %induction motor. Thanks to Chris Armstrong for the idea behind this
    %example.
    %
    % See also InductionMotorParameters.

    % Copyright 2021-2025 The MathWorks, Inc.

    properties
        % Operating point of the motor.
        OperatingPoint(1, 2) double {mustBeReal, mustBeFinite} = [0, 0]
        % Width of the rated and reduced curves.
        LineWidth(1, 1) double {mustBePositive, mustBeFinite} = 2
        % Operating point marker size.
        MarkerSize(1, 1) double {mustBePositive, mustBeFinite} = 20
        % Visibility of the legend.
        LegendVisible(1, 1) matlab.lang.OnOffSwitchState = "on"
    end % properties

    properties ( Dependent )
        % A set of induction motor parameters.
        MotorParameters(1, 1) InductionMotorParameters
    end % properties

    properties ( Access = private, Transient, NonCopyable )
        % The chart's axes.
        Axes(:, 1) matlab.graphics.axis.Axes {mustBeScalarOrEmpty}
        % A plot object for the operating point.
        OperatingPointPlot(:, 1) matlab.graphics.chart.primitive.Line ...
            {mustBeScalarOrEmpty}
        % A patch object for the normal operating region.
        NormalRegionPatch(:, 1) matlab.graphics.primitive.Patch ...
            {mustBeScalarOrEmpty}
        % A patch object for the buffer region.
        BufferRegionPatch(:, 1) matlab.graphics.primitive.Patch ...
            {mustBeScalarOrEmpty}
        % A patch object for the overload region.
        OverloadRegionPatch(:, 1) matlab.graphics.primitive.Patch ...
            {mustBeScalarOrEmpty}
        % A line object for the rated curves.
        RatedCurves(:, 1) matlab.graphics.primitive.Line ...
            {mustBeScalarOrEmpty}
        % A line object for the reduced curves.
        ReducedCurves(:, 1) matlab.graphics.primitive.Line ...
            {mustBeScalarOrEmpty}
    end % properties ( Access = private, Transient, NonCopyable )

    properties ( Access = private )
        % Internal storage for the MotorParameters property.
        MotorParameters_(1, 1) InductionMotorParameters = ...
            InductionMotorParameters
        % Logical flag indicating whether a full chart update is required.
        FullUpdateRequired(1, 1) logical = false
    end % properties ( Access = private )

    events ( NotifyAccess = private, HasCallbackProperty )
        % The operating point has moved out of the normal running region.
        AbnormalPerformanceDetected
    end % events ( NotifyAccess = private, HasCallbackProperty )

    methods

        function obj = InductionMotorChart( namedArgs )
            %INDUCTIONMOTORCHART Construct an InductionMotorChart object,
            %given optional name-value arguments.

            arguments ( Input )
                namedArgs.?InductionMotorChart
            end % arguments ( Input )            

            % Set any user-defined properties.
            set( obj, namedArgs )

        end % constructor

        function value = get.MotorParameters( obj )

            value = obj.MotorParameters_;

        end % get.MotorParameters

        function set.MotorParameters( obj, value )

            obj.FullUpdateRequired = true;
            obj.MotorParameters_ = value;

        end % set.MotorParameters

        function varargout = xlabel( obj, varargin )

            [varargout{1:nargout}] = xlabel( obj.Axes, varargin{:} );

        end % xlabel

        function varargout = ylabel( obj, varargin )

            [varargout{1:nargout}] = ylabel( obj.Axes, varargin{:} );

        end % ylabel

        function varargout = title( obj, varargin )

            [varargout{1:nargout}] = title( obj.Axes, varargin{:} );

        end % title

        function varargout = subtitle( obj, varargin )

            [varargout{1:nargout}] = subtitle( obj.Axes, varargin{:} );

        end % subtitle

        function grid( obj, varargin )

            grid( obj.Axes, varargin{:} )

        end % grid

    end % methods

    methods ( Access = protected )

        function setup( obj )
            %SETUP Initialize the chart's graphics and controls.

            % Create the chart's axes.
            obj.Axes = axes( "Parent", obj.getLayout(), ...
                "Box", "on", ...
                "Interactions", dataTipInteraction, ...
                "Toolbar", [], ...
                "DataAspectRatio", [10, 1, 1], ...
                "XAxisLocation", "origin", ...
                "YAxisLocation", "origin" );

            % Customize the axes' appearance.
            set( [obj.Axes.XAxis, obj.Axes.YAxis], "Exponent", 0 )
            xlabel( obj.Axes, "Motor speed (RPM)" )
            ylabel( obj.Axes, "Motor torque (Nm)" )
            title( obj.Axes, "Induction Motor Performance" )
            grid( obj.Axes, "on" )

            % Create the patch and line objects for the backdrop.

            % Normal region.
            obj.NormalRegionPatch = patch( "Parent", obj.Axes, ...
                "XData", NaN, ...
                "YData", NaN, ...
                "FaceColor", obj.Axes.ColorOrder(1, :), ...
                "FaceAlpha", 0.6, ...
                "EdgeColor", "none", ...
                "PickableParts", "none", ...
                "DisplayName", "Normal running" );

            % Buffer region.
            obj.BufferRegionPatch = patch( "Parent", obj.Axes, ...
                "XData", NaN, ...
                "YData", NaN, ...
                "FaceColor", obj.Axes.ColorOrder(3, :), ...
                "FaceAlpha", 0.6, ...
                "EdgeColor", "none", ...
                "PickableParts", "none", ...
                "DisplayName", "Buffer region" );

            % Overload region.
            obj.OverloadRegionPatch = patch( "Parent", obj.Axes, ...
                "XData", NaN, ...
                "YData", NaN, ...
                "FaceColor", obj.Axes.ColorOrder(2, :), ...
                "FaceAlpha", 0.6, ...
                "EdgeColor", "none", ...
                "PickableParts", "none", ...
                "DisplayName", "Overload region" );

            % Rated curves.
            obj.RatedCurves = line( "Parent", obj.Axes, ...
                "XData", NaN, ...
                "YData", NaN, ...
                "Color", obj.Axes.ColorOrder(4, :), ...
                "LineStyle", ":", ...
                "LineWidth", 2, ...
                "PickableParts", "none", ...
                "DisplayName", "Rated" );

            % Reduced curves.
            obj.ReducedCurves = line( "Parent", obj.Axes, ...
                "XData", NaN, ...
                "YData", NaN, ...
                "Color", obj.Axes.ColorOrder(5, :), ...
                "LineStyle", ":", ...
                "LineWidth", 2, ...
                "PickableParts", "none", ...
                "DisplayName", "Reduced" );

            % Plot the operating point.
            hold( obj.Axes, "on" )
            obj.OperatingPointPlot = plot( obj.Axes, NaN, NaN, ...
                "Color", obj.Axes.ColorOrder(6, :), ...
                "Marker", ".", ...
                "LineStyle", "none", ...
                "MarkerSize", 20, ...
                "DisplayName", "Operating point" );
            hold( obj.Axes, "off" )

            % Enable a custom datatip.
            obj.OperatingPointPlot.DataTipTemplate...
                .DataTipRows(1).Label = "Motor speed (RPM):";
            obj.OperatingPointPlot.DataTipTemplate...
                .DataTipRows(2).Label = "Motor torque (Nm):";

            % Add the legend.
            legend( obj.Axes, "Location", "northeastoutside" )

        end % setup

        function update( obj )
            %UPDATE Refresh the chart's graphics in response to any
            %changes.

            % Update the operating point.
            speed = obj.OperatingPoint(1);
            torque = obj.OperatingPoint(2);
            set( obj.OperatingPointPlot, "XData", speed, "YData", torque )

            % Notify the "AbnormalPerformanceDetected" event if the motor 
            % performance has gone outside the normal operating region.
            region = obj.MotorParameters.NormalRegion;            
            if ~inNormalRegion( speed, torque, region(:, 1), region(:, 2) )
                obj.notify( "AbnormalPerformanceDetected" )
            end % if

            % Update the backdrop if needed.
            if obj.FullUpdateRequired

                % Update the axes and backdrop graphics.
                set( obj.Axes, ...
                    "XLim", obj.MotorParameters.Bounds(1:2), ...
                    "YLim", obj.MotorParameters.Bounds(3:4) )
                set( obj.NormalRegionPatch, ...
                    "XData", obj.MotorParameters.NormalRegion(:, 1), ...
                    "YData", obj.MotorParameters.NormalRegion(:, 2) )
                set( obj.BufferRegionPatch, ...
                    "XData", obj.MotorParameters.BufferRegion(:, 1:2), ...
                    "YData", obj.MotorParameters.BufferRegion(:, 3:4) )
                set( obj.OverloadRegionPatch, "XData", ...
                    obj.MotorParameters.OverloadRegion(:, 1:2), ...
                    "YData", obj.MotorParameters.OverloadRegion(:, 3:4) )
                set( obj.RatedCurves, ...
                    "XData", obj.MotorParameters.RatedCurves(:, 1), ...
                    "YData", obj.MotorParameters.RatedCurves(:, 2) )
                set( obj.ReducedCurves, ...
                    "XData", obj.MotorParameters.ReducedCurves(:, 1), ...
                    "YData", obj.MotorParameters.ReducedCurves(:, 2) )

                % Reset the flag.
                obj.FullUpdateRequired = false;

            end % if

            % Update the decorative properties.
            obj.Axes.Legend.Visible = obj.LegendVisible;
            set( [obj.ReducedCurves, obj.RatedCurves], ...
                "LineWidth", obj.LineWidth )
            obj.OperatingPointPlot.MarkerSize = obj.MarkerSize;

        end % update

    end % methods ( Access = protected )

end % classdef

function tf = inNormalRegion( x, y, xr, yr )
%INNORMALREGION Determine whether the point (x, y) lies in the rectangle
%with vertices (xr, yr).

[mnx, mxx] = bounds( xr );
[mny, mxy] = bounds( yr );
tf = x >= mnx && x <= mxx && y >= mny && y <= mxy;

end % inNormalRegion