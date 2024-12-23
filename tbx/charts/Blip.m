classdef Blip < matlab.mixin.SetGetExactNames
    %BLIP Class managing a radar blip. Radar blips are intended for use
    %with a polar axes, or the RadarScope chart.

    % Copyright 2021-2025 The MathWorks, Inc.

    properties ( Dependent )
        % Blip parent.
        Parent
        % Blip color.
        Color {validatecolor}
        % Blip visibility.
        Visible(1, 1) matlab.lang.OnOffSwitchState
        % Text string associated with the point.
        String(1, 1) string
        % Marker size.
        MarkerSize(1, 1) double {mustBePositive, mustBeFinite}
    end % properties ( Dependent )

    properties ( Dependent, SetObservable )
        % Position of the blip's point in (theta, rho) polar coordinates.
        Position(1, 2) {mustBeReal, mustBeFinite}
    end % properties ( Dependent, SetObservable )    

    properties ( Access = private )
        % Line object for the point.
        Point(:, 1) matlab.graphics.chart.primitive.Line ...
            {mustBeScalarOrEmpty}
        % Text object for the label.
        Label(:, 1) matlab.graphics.primitive.Text ...
            {mustBeScalarOrEmpty}
    end % properties ( Access = private )

    methods

        function obj = Blip( namedArgs )
            %BLIP Construct a radar blip object.

            arguments ( Input )
                namedArgs.?Blip
            end % arguments ( Input )

            % Create the graphics objects: a polar plot requires a
            % polar axes as the parent. We create an unplugged polar axes
            % to act as a temporary parent, ensuring that it is cleaned up
            % after the constructor completes.
            pax = polaraxes( "Parent", [] );
            oc = onCleanup( @() delete( pax ) );
            amber = [1, 0.5, 0];
            obj.Point = polarplot( pax, NaN, NaN, ...
                "Color", amber, ...
                "Marker", ".", ...
                "MarkerSize", 14, ...
                "DeleteFcn", @obj.onGraphicsDeleted );
            obj.Label = text( "Parent", pax, ...
                "Position", [NaN, NaN, 0], ...
                "Margin", 1, ...
                "FontSize", 9, ...
                "FontWeight", "bold", ...
                "HorizontalAlignment", "left", ...
                "VerticalAlignment", "bottom", ...
                "Color", amber, ...
                "DeleteFcn", @obj.onGraphicsDeleted );
            pax.Children = flip( pax.Children );

            % Unplug the point and label from the temporary polar axes.
            set( pax.Children, "Parent", [] )

            % Set any user-defined properties.
            set( obj, namedArgs )

        end % constructor

        function delete( obj )
            %DELETE Destructor method: delete the graphics when the object
            %is deleted.

            delete( [obj.Point, obj.Label] )

        end % destructor

        function value = get.Parent( obj )

            value = obj.Point.Parent;

        end % get.Parent

        function set.Parent( obj, value )

            % Move the point and label to the new parent.
            set( [obj.Point, obj.Label], "Parent", value )

        end % set.Parent

        function value = get.Position( obj )

            value = [obj.Point.ThetaData, obj.Point.RData];

        end % get.Position

        function set.Position( obj, value )

            % Update both the point and the label.
            set( obj.Point, "ThetaData", value(1), "RData", value(2) )
            obj.Label.Position(1:2) = value;

        end % set.Position

        function value = get.Color( obj )

            value = obj.Point.Color;

        end % get.Color

        function set.Color( obj, value )

            % Update the point and label colors.
            set( [obj.Point, obj.Label], "Color", value )

        end % set.Color

        function value = get.Visible( obj )

            value = obj.Point.Visible;

        end % get.Visible

        function set.Visible( obj, value )

            set( [obj.Point, obj.Label], "Visible", value )

        end % set.Visible

        function value = get.String( obj )

            value = string( obj.Label.String );

        end % get.String

        function set.String( obj, value )

            obj.Label.String = value;

        end % set.String

        function value = get.MarkerSize( obj )

            value = obj.Point.MarkerSize;
            
        end % get.MarkerSize

        function set.MarkerSize( obj, value )

            obj.Point.MarkerSize = value;

        end % set.MarkerSize

    end % methods

    methods ( Access = private )

        function onGraphicsDeleted( obj, ~, ~ )
            %ONGRAPHICSDELETED Delete the object when the graphics are
            %deleted.

            delete( obj )

        end % onGraphicsDeleted

    end % methods ( Access = private )

end % classdef