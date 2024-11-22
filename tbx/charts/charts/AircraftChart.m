classdef AircraftChart < Chart
    %AIRCRAFTCHART Custom chart for displaying a 3D rendering of an
    %aircraft. The chart also provides roll, pitch and yaw methods for
    %modifying the attitude of the aircraft.

    % Copyright 2024-2025 The MathWorks, Inc.

    properties
        % Aircraft triangulation coordinate data.
        Triangulation(:, 3) triangulation = stlread( "avion31.stl" )
    end % properties

    properties ( Access = private, Transient, NonCopyable )
        % Chart axes.
        Axes(:, 1) matlab.graphics.axis.Axes {mustBeScalarOrEmpty}
        % Transform object.
        Transform(:, 1) matlab.graphics.primitive.Transform ...
            {mustBeScalarOrEmpty}
        % Patch object for the aircraft.
        Patch(:, 1) matlab.graphics.primitive.Patch {mustBeScalarOrEmpty}
    end % properties ( Access = private, Transient, NonCopyable )

    methods

        function obj = AircraftChart( namedArgs )

            arguments ( Input )
                namedArgs.?AircraftChart
            end % arguments            
            
            % Set any user-defined properties.
            set( obj, namedArgs )

        end % constructor

        function roll( obj, theta )
            %ROLL Roll the aircraft by theta degrees.

            obj.rotate( "roll", theta )

        end % roll

        function pitch( obj, theta )
            %PITCH Pitch the aircraft by theta degrees.

            obj.rotate( "pitch", theta )

        end % pitch

        function yaw( obj, theta )
            %YAW Yaw the aircraft by theta degrees.

            obj.rotate( "yaw", theta )

        end % yaw

        function reset( obj )
            %RESET Restore the original aircraft pose.

            obj.Transform.Matrix = eye( 4 );

        end % reset

    end % methods

    methods ( Access = protected )

        function setup( obj )
            %SETUP Initialize the chart graphics.

            % Obtain the chart's tiled layout.
            tl = obj.getLayout();

            % Define the color scheme used for the aircraft.
            blue = [0, 0.447, 0.741];
            gray = 0.95 * ones(1, 3);
            onesMatrix = ones(250, 3);
            paintJob = [gray .* onesMatrix; blue .* onesMatrix];

            % Create and customize the axes.
            x = [-2000, 2000];
            y = [-2500, 4500];
            z = [-2500, 2500];
            obj.Axes = axes( "Parent", tl, ...
                "Colormap", paintJob, ...
                "View", [225, 25], ...
                "DataAspectRatio", [1, 1, 1], ...
                "XLim", x, ...
                "YLim", y, ...
                "ZLim", z, ...
                "XTickLabel", [], ...
                "YTickLabel", [], ...
                "ZTickLabel", [], ...
                "NextPlot", "add");

            % Add the transform and patch.
            obj.Transform = hgtransform( "Parent", obj.Axes );
            obj.Patch = trisurf( obj.Triangulation, ...
                "Parent", obj.Transform, ...
                "FaceAlpha", 0.9, ...
                "FaceColor", "interp", ...
                "EdgeAlpha", 0, ...
                "FaceLighting", "gouraud" );

            % Add a title, lighting from above, and give the patch a shiny
            % appearance by adjusting lighting properties.
            title( obj.Axes, "Aircraft Attitude" )
            light( obj.Axes, "Position", [0, 0, 1] )
            material( obj.Axes, "shiny" )

        end % setup

        function update( obj )
            %UPDATE Refresh the chart graphics.

            faces = obj.Triangulation(:, :);
            pts = obj.Triangulation.Points;
            set( obj.Patch, "Faces", faces, ...
                "Vertices", pts, ...
                "FaceVertexCData", pts(:, 3) )

        end % update

    end % methods ( Access = protected )

    methods ( Access = private )

        function rotate( obj, type, theta )
            %ROTATE Rotate the aircraft with respect to one of three
            %orientations (roll, pitch, yaw) by an angle theta.

            arguments
                % Chart object.
                obj(1, 1) AircraftChart
                % Possible angles of rotation: roll, pitch and yaw.
                type(1, 1) string ...
                    {mustBeMember( type, ["roll", "pitch", "yaw"] )}
                % Angular value to rotate by.
                theta(1, 1) double {mustBeReal, mustBeFinite} = 0
            end % arguments

            switch type
                case "roll"
                    rotAxis = "y";
                case "pitch"
                    rotAxis = "x";
                case "yaw"
                    rotAxis = "z";
            end % switch/case

            % Convert the angle to radians and then update the
            % transformation matrix.
            theta = deg2rad( theta );
            obj.Transform.Matrix = obj.Transform.Matrix * ...
                makehgtform( rotAxis + "rotate", theta );

        end % rotate

    end % methods ( Access = private )

end % classdef