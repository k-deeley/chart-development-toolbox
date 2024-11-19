classdef ClockChart < matlab.graphics.chartcontainer.ChartContainer
    %CLOCKCHART Illustrates the use of timer objects within charts.

    % Copyright 2024-2025 The MathWorks, Inc.

    properties ( Access = private, Transient, NonCopyable )
        % Chart axes.
        Axes(:, 1) matlab.graphics.axis.Axes {mustBeScalarOrEmpty}
        % Line for the clock face edge.
        ClockFaceEdge(:, 1) matlab.graphics.primitive.Line ...
            {mustBeScalarOrEmpty}
        % Text objects for the numbers.
        ClockNumbers(:, 1) matlab.graphics.primitive.Text
        % Line objects for the minute markers.
        MinuteMarkers(:, 1) matlab.graphics.primitive.Line
        % Line objects for the five-minute markers.
        FiveMinuteMarkers(:, 1) matlab.graphics.primitive.Line
        % Patch object for the hour hand.
        HourHand(:, 1) matlab.graphics.primitive.Patch ...
            {mustBeScalarOrEmpty}
        % Patch object for the minute hand.
        MinuteHand(:, 1) matlab.graphics.primitive.Patch ...
            {mustBeScalarOrEmpty}
        % Patch object for the second hand.
        SecondHand(:, 1) matlab.graphics.primitive.Patch ...
            {mustBeScalarOrEmpty}
    end % properties ( Access = private, Transient, NonCopyable )

    properties ( Access = private )
        % Timer object, used for the clock.
        Timer(:, 1) timer {mustBeScalarOrEmpty}
        % Destruction listener, used to tidy up the timer.
        DestructionListener(:, 1) event.listener {mustBeScalarOrEmpty}
    end % properties ( Access = private )

    properties ( Constant, Hidden )
        % Product dependencies.
        Dependencies(1, :) string = "MATLAB"
    end % properties ( Constant, Hidden )

    methods

        function obj = ClockChart( namedArgs )
            %CLOCKCHART Construct a ClockChart object, given optional
            %name-value arguments.

            arguments ( Input )
                namedArgs.?ClockChart
            end % arguments ( Input )

            % Call the superclass constructor.
            f = figure( "Visible", "off" );
            figureCleanup = onCleanup( @() delete( f ) );
            obj@matlab.graphics.chartcontainer.ChartContainer( ...
                "Parent", f )
            obj.Parent = [];

            % Create the timer.
            obj.Timer = timer( "Period", 1, ...
                "ExecutionMode", "fixedRate", ...
                "TimerFcn", @obj.onTick );

            % Start the timer.
            start( obj.Timer )

            % Create a listener to delete the timer when the chart is
            % deleted.
            obj.DestructionListener = listener( obj, ...
                "ObjectBeingDestroyed", @obj.onChartDeleted );

            % Set any user-specified properties.
            set( obj, namedArgs )

        end % constructor

    end % methods

    methods ( Access = protected )

        function setup( obj )
            %SETUP Initialize the chart graphics.

            % Create the axes.
            obj.Axes = axes( "Parent", obj.getLayout(), ...
                "Visible", "off", ...
                "Toolbar", [], ...
                "Interactions", [], ...
                "XLim", [-10, 10], ...
                "YLim", [-10, 10], ...
                "DataAspectRatio", [1, 1, 1] );

            % Draw the clock face edge.
            t = linspace( 0, 2 * pi, 500 );
            obj.ClockFaceEdge = line( "Parent", obj.Axes, ...
                "XData", 9 * cos( t ), ...
                "YData", 9 * sin( t ), ...
                "LineWidth", 8 );

            % Add the clock numbers.
            clockNumberAngles = (60 : -30 : -270).'; % 1-12 o'clock
            obj.ClockNumbers = text( obj.Axes, ...
                7 * cosd( clockNumberAngles ), ...
                7 * sind( clockNumberAngles ), ...
                string( (1:12).' ), ...
                "HorizontalAlignment", "center", ...
                "VerticalAlignment", "middle", ...
                "FontName", "monospaced", ...
                "FontSize", 28 );

            % Compute the minute and five-minute tick mark coordinates.
            minuteAngles = (90 : -6 : -264);
            fiveMinuteAngles = minuteAngles(1:5:end);
            tickRadii = [8.1; 8.5];
            minutex = tickRadii * cosd( minuteAngles );
            minutey = tickRadii * sind( minuteAngles );
            fiveMinutex = tickRadii * cosd( fiveMinuteAngles );
            fiveMinutey = tickRadii * sind( fiveMinuteAngles );

            % Add the minute markers.
            for k = 1 : width( minutex )
                obj.MinuteMarkers(k) = line( "Parent", obj.Axes, ...
                    "XData", minutex(:, k), ...
                    "YData", minutey(:, k), ...
                    "LineWidth", 3 );
            end % for

            % Add the five-minute markers.
            for k = 1 : width( fiveMinutex )
                obj.FiveMinuteMarkers(k) = line( "Parent", obj.Axes, ...
                    "XData", fiveMinutex(:, k), ...
                    "YData", fiveMinutey(:, k), ...
                    "LineWidth", 8 );
            end % for

            % Create patches for the hour, minute, and second hands.
            obj.HourHand = patch( "Parent", obj.Axes, ...
                "XData", NaN, ...
                "YData", NaN, ...
                "EdgeAlpha", 0 );
            obj.MinuteHand = patch( "Parent", obj.Axes, ...
                "XData", NaN, ...
                "YData", NaN, ...
                "EdgeAlpha", 0 );
            obj.SecondHand = patch( "Parent", obj.Axes, ...
                "XData", NaN, ...
                "YData", NaN, ...
                "EdgeAlpha", 0, ...
                "FaceColor", "r" );

        end % setup

        function update( obj )
            %UPDATE Refresh the chart graphics.

            set( [obj.HourHand, obj.MinuteHand], ...
                "FaceColor", obj.ClockFaceEdge.Color )

        end % update

    end % methods ( Access = protected )

    methods ( Access = private )

        function onChartDeleted( obj, ~, ~ )
            %ONCHARTDELETED Respond to the destruction of the chart by
            %tidying up the timer object.

            if obj.Timer.Running == "on"
                stop( obj.Timer )
            end % if

            delete( obj.Timer )

        end % onChartDeleted

        function onTick( obj, ~, ~ )
            %ONTICK Timer callback.

            % Record the current time.
            t = datetime( "now" );

            % Compute the hand coordinates.
            [hourHand, minuteHand, secondHand] = handxy( t );

            % Update the hands.
            set( obj.HourHand, "XData", hourHand(:, 1), ...
                "YData", hourHand(:, 2) )
            set( obj.MinuteHand, "XData", minuteHand(:, 1), ...
                "YData", minuteHand(:, 2) )
            set( obj.SecondHand, "XData", secondHand(:, 1), ...
                "YData", secondHand(:, 2) )

        end % onTick

    end % methods ( Access = private )

end % classdef

function [hourHand, minuteHand, secondHand] = handxy( t )
%HANDXY Compute (x, y) coordinates of the hour, minute, and second hands of
%the clock given the current time (t).

arguments ( Input )
    t(1, 1) datetime
end % arguments ( Input )

arguments ( Output )
    hourHand(:, 2) double {mustBeReal, mustBeFinite}
    minuteHand(:, 2) double {mustBeReal, mustBeFinite}
    secondHand(:, 2) double {mustBeReal, mustBeFinite}
end % arguments ( Output )

% Initialize the clock hand dimensions (front/back length, front/back
% width).
persistent handDimensions distanceToOrigin inverseTangent

if isempty( handDimensions )
    handDimensions = [5, 5/3, 0.1, 0.3;
        7, 7/3, 0.1, 0.3;
        7, 7/3, 0.05, 0.15];
end % if

if isempty( distanceToOrigin )
    distanceToOrigin = [hypot( handDimensions(:, 1), ...
        handDimensions(:, 3) ), hypot( handDimensions(:, 2), ...
        handDimensions(:, 4) )];
end % if

if isempty( inverseTangent )
    inverseTangent = atan( [handDimensions(:, 3) ./ ...
        handDimensions(:, 1), handDimensions(:, 4) ./ ...
        handDimensions(:, 2)] );
end % if

% Define the conversion factor from degrees to radians (pi/180), in the 
% clockwise direction (-1).
f = (-1) * pi/180;

% Write down the hand angles based on the current time.
hourHandAngle = f * (-90 + 30 * t.Hour + (30 * t.Minute) / 60 );
minuteHandAngle = f * (-90 + 6 * t.Minute + (6 * t.Second) / 60);
secondHandAngle = f * (-90 + 6 * t.Second);

% Compute the (x, y) hand coordinates given the hand angle and dimensions.
hourHand = xy( hourHandAngle, distanceToOrigin(1, :), ...
    handDimensions(1, :), inverseTangent(1, :) );
minuteHand = xy( minuteHandAngle, distanceToOrigin(2, :), ...
    handDimensions(2, :), inverseTangent(2, :) );
secondHand = xy( secondHandAngle, distanceToOrigin(3, :), ...
    handDimensions(3, :), inverseTangent(3, :) );

    function coords = xy( theta, d, dims, invTan )
        %XY Hand coordinate calculator, given the hand angle (theta),
        %distances to the origin (d), the hand dimensions (dims), and the
        %inverse tangents of the hand dimensions (invTan).

        coords = [[d(1) * cos( theta + invTan(1) ); ...
              (dims(1) + 5 * dims(3)) * cos( theta ); ...
              d(1) * cos( theta - invTan(1) ); ...
              d(2) * cos( theta + invTan(2) + pi );...
              d(2) * cos( theta - invTan(2) + pi )], ...
              [d(1) * sin( theta + invTan(1) ); ...
              (dims(1) + 5 * dims(3)) * sin( theta ); ...
              d(1) * sin( theta - invTan(1) ); ...
              d(2) * sin( theta + invTan(2) + pi ); ...
              d(2) * sin( theta - invTan(2) + pi )]];

    end % xy

end % handxy