classdef WindRoseChart < Chart
    %WINDROSECHART Chart for displaying speed and direction data on an
    %angular (polar) histogram.

    % Copyright 2018-2025 The MathWorks, Inc.

    properties ( Dependent )
        % Wind data table, containing direction and speed values.
        WindData(:, 2) table {mustBeWindData}
        % Bin edges for the speed data.
        SpeedBinEdges(1, :) double {mustBeNonnegative}
    end % properties ( Dependent )

    properties ( SetAccess = private )
        % Speed and direction observation counts in each bin.
        ObservationCounts(:, :) double {mustBeInteger, mustBeNonnegative}
        % Percentage observation counts in each bin.
        PercentageObservationCounts(:, :) double ...
            {mustBeInRange( PercentageObservationCounts, 0, 100 )}
        % Cumulative percentages in each bin (by wind direction).
        CumulativePercentageObservationCounts(:, :) double ...
            {mustBeNonnegative, mustBeFinite}
    end % properties ( Dependent, SetAccess = private )

    properties
        % Radial offset for the direction labels.
        DirectionLabelOffset(1, 1) double {mustBeReal, mustBeFinite} = 0.05
        % Direction label font size.
        DirectionLabelFontSize(1, 1) double ...
            {mustBeNonnegative, mustBeFinite} = 10
        % Direction label font weight.
        DirectionLabelFontWeight(1, 1) string {mustBeFontWeight} = "normal"
        % Direction label font angle.
        DirectionLabelFontAngle(1, 1) string {mustBeFontAngle} = "normal"
        % Direction label visibility.
        DirectionLabelVisible(1, 1) matlab.lang.OnOffSwitchState = "on"
        % Patch face transparency.
        FaceAlpha(1, 1) double {mustBeInRange( FaceAlpha, 0, 1 )} = 1
        % Patch line width.
        LineWidth(1, 1) double {mustBePositive, mustBeFinite} = 0.5
        % Patch line style.
        LineStyle(1, 1) string {mustBeLineStyle} = "-"
        % Patch edge color.
        EdgeColor {mustBeColor( EdgeColor, ...
            ["flat", "none", "interp"] )} = "k"
        % Patch edge alpha.
        EdgeAlpha(1, 1) double {mustBeInRange( EdgeAlpha, 0, 1 )} = 1
        % Backdrop color.
        BackdropColor {validatecolor} = [0.8725, 0.8725, 0.8725]
        % Backdrop line width.
        BackdropLineWidth(1, 1) double {mustBePositive, mustBeFinite} = 0.5
        % Backdrop line style.
        BackdropLineStyle(1, 1) string {mustBeLineStyle} = "-"
        % Radial label font size.
        RadialLabelFontSize(1, 1) double {mustBePositive, mustBeFinite} = 8
        % Radial label font weight.
        RadialLabelFontWeight(1, 1) string {mustBeFontWeight} = "normal"
        % Radial label font angle.
        RadialLabelFontAngle(1, 1) string {mustBeFontAngle} = "normal"
        % Radial label visibility.
        RadialLabelVisible(1, 1) matlab.lang.OnOffSwitchState = "on"
        % Legend location.
        LegendLocation(1, 1) string {mustBeLegendLocation} = ...
            "northeastoutside"
        % Legend orientation.
        LegendOrientation(1, 1) string {mustBeMember( ...
            LegendOrientation, ["vertical", "horizontal"] )}= "vertical"
        % Legend number of columns.
        LegendNumColumns(1, 1) double {mustBeInteger, mustBePositive} = 1
        % Legend box.
        LegendBox(1, 1) matlab.lang.OnOffSwitchState = "off"
        % Legend color.
        LegendColor {mustBeColor( LegendColor, "none" )} = "none"
        % Legend visibility.
        LegendVisible(1, 1) matlab.lang.OnOffSwitchState = "on"
        % Legend edge color.
        LegendEdgeColor {mustBeColor( ...
            LegendEdgeColor, "none" )} = [0.15, 0.15, 0.15]
        % Legend font angle.
        LegendFontAngle(1, 1) string {mustBeFontAngle} = "normal"
        % Legend font size.
        LegendFontSize(1, 1) double {mustBePositive, mustBeFinite} = 9
        % Legend font weight.
        LegendFontWeight(1, 1) string {mustBeFontWeight} = "normal"
        % Legend line width.
        LegendLineWidth(1, 1) double {mustBePositive, mustBeFinite} = 0.5
        % Legend text color.
        LegendTextColor {mustBeColor( LegendTextColor, "none" )} = "k"
        % Legend title string.
        LegendTitle(1, 1) string = "Windspeed (m/s)"
    end % properties

    properties ( Dependent )
        % Angular direction in which to display the radial labels.
        RadialLabelDirection(1, 1) string {mustBeDirection}
        % Patch face colors.
        FaceColors(:, 3) double {mustBeInRange( FaceColors, 0, 1 )}
    end % properties ( Dependent )

    properties ( Access = private )
        % Internal storage for the WindData property.
        WindData_(:, 2) table {mustBeWindData} = defaultWindData()
        % Internal storage for the SpeedBinEdges property.
        SpeedBinEdges_(1, :) double {mustBeNonnegative} = [0:5:30, Inf]
        % Internal angle for the radial text labels (clockwise from North).
        RadialLabelAngle(1, 1) double ...
            {mustBeInRange( RadialLabelAngle, 0, 360 )} = 135
        % Minimum backdrop circle radius.
        MinRadius(1, 1) double {mustBePositive, mustBeFinite} = 1
        % Maximum backdrop circle radius.
        MaxRadius(1, 1) double {mustBePositive, mustBeFinite} = 1
        % Outer border value for the axis limits.
        OuterBorder(1, 1) double {mustBePositive, mustBeFinite} = 1
        % Radii of the backdrop circles.
        CircleRadii(1, :) double {mustBePositive, mustBeFinite} = 1
        % Logical scalar specifying whether a computation is required.
        ComputationRequired(1, 1) logical = false
    end % properties ( Access = private )

    properties ( Access = private, Transient, NonCopyable )
        % Chart axes.
        Axes(:, 1) matlab.graphics.axis.Axes {mustBeScalarOrEmpty}
        % Axes legend.
        Legend(:, 1) matlab.graphics.illustration.Legend ...
            {mustBeScalarOrEmpty}
        % Concentric circles used in the chart backdrop.
        BackdropCircles(:, 1) matlab.graphics.primitive.Line
        % Angular rays used in the chart backdrop.
        BackdropRays(:, 1) matlab.graphics.primitive.Line
        % Text labels indicating the radial percentanges.
        RadialLabels(:, 1) matlab.graphics.primitive.Text
        % Text labels indicating the wind directions.
        DirectionLabels(:, 1) matlab.graphics.primitive.Text
        % Patch objects for the angular histogram.
        Patches(:, :) matlab.graphics.primitive.Patch
        % Text objects to display the bin data.
        TextBoxes(:, :) matlab.graphics.primitive.Text
    end % properties ( Access = private, Transient, NonCopyable )

    properties ( Constant, GetAccess = private )
        % Angles for the backdrop rays.
        RayAngles(1, :) double ...
            {mustBeNonnegative, mustBeFinite} = 0:22.5:337.5
        % Lower and upper edges for the direction bins.
        DirectionEdges(:, 2) double ...
            {mustBeReal, mustBeFinite} = [355, 5:10:345; 5:10:355].'
        % Direction bin centers.
        DirectionBinCenters(:, 1) double ...
            {mustBeReal, mustBeFinite} = 0:10:350
        % Direction label text, counterclockwise from East (E).
        DirectionLabelText(:, 1) string = directionLabelText()
        % Number of concentric circles in the chart's backdrop.
        NumCircles(1, 1) double {mustBeInteger, mustBePositive} = 10
        % Wind direction / angle lookup.
        DirectionLookup = dictionary( WindRoseChart.RayAngles, ...
            ["N", "NNE", "NE", "ENE", ...
            "E", "ESE", "SE", "SSE", ...
            "S", "SSW", "SW", "WSW", ...
            "W", "WNW", "NW", "NNW"] )
    end % properties ( Constant, GetAccess = private )

    properties ( Constant, Hidden )
        % Product dependencies.
        Dependencies(1, :) string = "MATLAB"
    end % properties ( Constant, Hidden )

    methods

        function value = get.WindData( obj )

            value = obj.WindData_;

        end % get.WindData

        function set.WindData( obj, value )

            % Mark the chart for an update.
            obj.ComputationRequired = true;

            % Update the internal stored value.
            obj.WindData_ = value;

            % Update the observation counts and derived quantities.
            obj.updateCounts()

        end % set.WindData

        function value = get.SpeedBinEdges( obj )

            value = obj.SpeedBinEdges_;

        end % get.SpeedBinEdges

        function set.SpeedBinEdges( obj, value )

            % Check the new value.
            assert( issorted( value, "strictascend" ) && ...
                numel( value ) >= 2 && value(1) == 0 && ...
                value(end) == Inf, "WindRose:InvalidSpeedBinEdges", ...
                "The speed bin edge vector must be of the form " + ...
                "[0, v(1), v(2), ..., v(n), Inf] where v(i) < v(i+1)" + ...
                " for i = 1, 2, ..., n-1." )

            % Mark the chart for an update.
            obj.ComputationRequired = true;

            % Update the internal stored value.
            obj.SpeedBinEdges_ = value;

            % Update the observation counts and derived quantities.
            obj.updateCounts()

        end % set.SpeedBinEdges

        function value = get.RadialLabelDirection( obj )

            value = string( obj.DirectionLookup(obj.RadialLabelAngle) );

        end % get.RadialLabelDirection

        function set.RadialLabelDirection( obj, value )

            % Perform a reverse lookup to determine the required angle
            % (clockwise from North).
            angles = num2cell( obj.RayAngles );
            directions = values( obj.DirectionLookup, angles );
            obj.RadialLabelAngle = angles{directions == value};

            % Update the labels.
            obj.updateRadialLabels()

        end % set.RadialLabelDirection

        function set.DirectionLabelOffset( obj, value )

            % Update the stored property.
            obj.DirectionLabelOffset = value;

            % Update the direction labels.
            obj.updateDirectionLabels()

        end % set.DirectionLabelOffset

        function value = get.FaceColors( obj )

            value = vertcat( obj.Patches(1, :).FaceColor );

        end % get.FaceColors

        function set.FaceColors( obj, value )

            % Check that the number of colors is correct.
            numColors = height( value );
            assert( numColors == width( obj.Patches ), ...
                "WindRose:WrongNumberOfFaceColors", ...
                "The number of colors must match the number of " + ...
                "speed bins." )

            % Update the patches.
            for k = 1:numColors
                set( obj.Patches(:, k), "FaceColor", value(k, :) )
            end % for

        end % set.FaceColors

    end % methods

    methods

        function obj = WindRoseChart( namedArgs )
            %WINDROSECHART Construct a WindRoseChart object, given optional
            %name-value arguments.

            arguments ( Input )
                namedArgs.?WindRoseChart
            end % arguments ( Input )

            % Set any user-defined properties.
            set( obj, namedArgs )

        end % constructor

        function varargout = title( obj, varargin )

            [varargout{1:nargout}] = title( obj.Axes, varargin{:} );

        end % title

    end % methods

    methods ( Access = protected )

        function setup( obj )
            %SETUP Initialize the chart graphics.

            % Create the chart's axes.
            obj.Axes = axes( "Parent", obj.getLayout(), ...
                "DataAspectRatio", [1, 1, 1], ...
                "Interactions", [], ...
                "Visible", "off" );

            % Ensure the title is visible.
            obj.Axes.Title.Visible = "on";

            % Create the chart backdrop. This comprises the concentric
            % circles, the angular rays, the radial labels and the
            % direction labels.

            % Concentric circles.
            for k = 1:obj.NumCircles
                obj.BackdropCircles(k) = line( "Parent", obj.Axes, ...
                    "XData", NaN, ...
                    "YData", NaN, ...
                    "Color", obj.BackdropColor, ...
                    "HandleVisibility", "off" );
            end % for

            % Angular rays.
            nRays = numel( obj.RayAngles );
            for k = 1:nRays
                obj.BackdropRays(k) = line( "Parent", obj.Axes, ...
                    "XData", NaN, ...
                    "YData", NaN, ...
                    "Color", obj.BackdropColor, ...
                    "HandleVisibility", "off" );
            end % for

            % Create the text boxes containing the radial percentage
            % labels.
            textX = NaN( obj.NumCircles, 1 );
            textY = textX;
            radialText = repmat( "", obj.NumCircles, 1 );
            obj.RadialLabels = text( textX, textY, radialText, ...
                "Parent", obj.Axes, ...
                "HandleVisibility", "off", ...
                "HorizontalAlignment", "center", ...
                "VerticalAlignment", "middle" );

            % Create the text boxes containing the direction labels.
            textX = NaN( size( obj.DirectionLabelText ) );
            textY = textX;
            obj.DirectionLabels = ...
                text( textX, textY, obj.DirectionLabelText, ...
                "Parent", obj.Axes, ...
                "HandleVisibility", "off", ...
                "HorizontalAlignment", "center", ...
                "VerticalAlignment", "middle" );

            % Create the histogram patches comprising the wind rose. Loop
            % over the number of direction bins and the number of speed
            % bins. For each of direction-speed bin, create a patch object.
            % Similarly, create the text boxes for the direction-speed
            % data.
            numDirectionBins = numel( obj.DirectionBinCenters );
            numSpeedBins = numel( obj.SpeedBinEdges_ ) - 1;
            patchColors = parula( numSpeedBins );
            obj.Patches = repmat( patch( "Parent", [] ), ...
                numDirectionBins, numSpeedBins );
            obj.TextBoxes = repmat( text( "Parent", [] ), ...
                numDirectionBins, numSpeedBins );
            for k1 = 1:numDirectionBins
                for k2 = 1:numSpeedBins
                    obj.Patches(k1, k2) = patch( "Parent", obj.Axes, ...
                        "FaceColor", patchColors(k2, :), ...
                        "XData", NaN, ...
                        "YData", NaN, ...
                        "ButtonDownFcn", @obj.onPatchClicked );
                    obj.TextBoxes(k1, k2) = text( "Parent", obj.Axes, ...
                        "PickableParts", "none", ...
                        "HorizontalAlignment", "left", ...
                        "VerticalAlignment", "middle", ...
                        "BackgroundColor", "w", ...
                        "EdgeColor", "k", ...
                        "LineWidth", 1.5, ...
                        "Visible", "off" );
                end % for k2
            end % for k1

            % Initialize the legend.
            obj.Legend = legend( obj.Axes, obj.Patches(1, :) );

        end % setup

        function update( obj )
            %UPDATE Refresh the chart graphics.

            if obj.ComputationRequired

                % Hide any visible text boxes, if necessary.
                set( obj.TextBoxes, "Visible", "off" )

                % Update the axes limits.
                axis( obj.Axes, obj.OuterBorder * [-1, 1, -1, 1] )

                % Move the title.
                obj.Axes.Title.Position = obj.OuterBorder * [-1, 1, 0];

                % Backdrop concentric circles.
                t = linspace( 0, 2*pi ).';
                circleX = cos( t ) * obj.CircleRadii;
                circleY = sin( t ) * obj.CircleRadii;

                % Update the circles' x and y-data.
                for k = 1:obj.NumCircles
                    set( obj.BackdropCircles(k), ...
                        "XData", circleX(:, k), "YData", circleY(:, k) )
                end % for

                % Backdrop angular rays. These begin at the inner circle
                % and terminate at the outer circle.
                rayLims = [obj.MinRadius; obj.MinRadius + obj.MaxRadius];
                rayX = rayLims * cosd( obj.RayAngles );
                rayY = rayLims * sind( obj.RayAngles );
                for k = 1:numel( obj.RayAngles )
                    set( obj.BackdropRays(k), "XData", rayX(:, k), ...
                        "YData", rayY(:, k) )
                end % for

                % Radial text labels.
                obj.updateRadialLabels()

                % Direction labels.
                obj.updateDirectionLabels()

                % Histogram patches and text boxes. First, determine
                % whether new objects need to be created or old objects
                % need to be deleted.
                previousNumSpeedBins = width( obj.Patches );
                currentNumSpeedBins = numel( obj.SpeedBinEdges_ ) - 1;
                numDirectionBins = numel( obj.DirectionBinCenters );
                if currentNumSpeedBins < previousNumSpeedBins
                    % Delete the graphics objects.
                    delete( obj.Patches(:, currentNumSpeedBins+1:end) )
                    delete( obj.TextBoxes(:, currentNumSpeedBins+1:end) )
                    % Update the stored properties.
                    obj.Patches(:, currentNumSpeedBins+1:end) = [];
                    obj.TextBoxes(:, currentNumSpeedBins+1:end) = [];
                elseif currentNumSpeedBins >= previousNumSpeedBins
                    % Create new patches and text boxes.
                    obj.Patches(1:numDirectionBins, ...
                        previousNumSpeedBins+1:currentNumSpeedBins) = ...
                        patch( "Parent", [] );
                    obj.TextBoxes(1:numDirectionBins, ...
                        previousNumSpeedBins+1:currentNumSpeedBins) = ...
                        text( "Parent", [] );
                    for k1 = 1 : height( obj.Patches )
                        for k2 = previousNumSpeedBins+1:currentNumSpeedBins
                            obj.Patches(k1, k2) = patch( ...
                                "Parent", obj.Axes, ...
                                "XData", NaN, ...
                                "YData", NaN, ...
                                "ButtonDownFcn", @obj.onPatchClicked );
                            obj.TextBoxes(k1, k2) = text( ...
                                "Parent", obj.Axes, ...
                                "PickableParts", "none", ...
                                "HorizontalAlignment", "left", ...
                                "VerticalAlignment", "middle", ...
                                "BackgroundColor", "w", ...
                                "EdgeColor", "k", ...
                                "LineWidth", 1.5, ...
                                "Visible", "off" );
                        end % for k2
                    end % for k1
                end % if

                % Update the patch x and y-data, as well as the face
                % colors. Use the same loop to update the text boxes.
                angularSemiBinWidth = obj.DirectionEdges(1, 2);
                thetaBase = ...
                    linspace( -angularSemiBinWidth, angularSemiBinWidth );
                cpoc = obj.CumulativePercentageObservationCounts;
                [numDirectionBins, numSpeedBins] = size( cpoc );
                patchColors = parula( numSpeedBins );
                for k1 = 1:numDirectionBins
                    for k2 = 1:numSpeedBins
                        % Inner radius.
                        if k2 > 1
                            r(1) = cpoc(k1, k2-1);
                        else
                            r(1) = 0;
                        end % if
                        % Outer radius.
                        r(2) = cpoc(k1, k2);
                        r = r + obj.MinRadius;
                        % Patch x and y coordinates.
                        theta = obj.DirectionBinCenters(k1) + thetaBase;
                        patchX = [r(1) * sind( fliplr( theta ) ), ...
                            r(2) * sind( theta )];
                        patchY = [r(1) * cosd( fliplr( theta ) ), ...
                            r(2) * cosd( theta )];
                        set( obj.Patches(k1, k2), "XData", patchX, ...
                            "YData", patchY, ...
                            "FaceColor", patchColors(k2, :) )
                        % Text boxes.
                        set( obj.TextBoxes(k1, k2), "Position", ...
                            [mean( patchX ), mean( patchY ), 0], ...
                            "String", "{\bf{Direction Range:}} [" + ...
                            obj.DirectionEdges(k1, 1) + char( 176 ) + ...
                            ", " + obj.DirectionEdges(k1, 2) + ...
                            char( 176 ) + ")" + newline() + ...
                            "{\bf{Observation Count:}} " + sprintf( ...
                            "%d (%.2f%%)", ...
                            obj.ObservationCounts(k1, k2), ...
                            obj.PercentageObservationCounts(k1, k2) ) )
                    end % for k2
                end % for k1

                % Ensure that all the text boxes are above all the patches
                % in the axes' visual stacking order.
                obj.Axes.Children = [obj.TextBoxes(:); obj.Patches(:)];

                % Update the legend, using only the first row of patches.
                obj.Legend = legend( obj.Axes, obj.Patches(1, :) );

                % Form legend text entries of the form "a <= v < b" for the
                % appropriate speed threshold values a and b.
                legendText = strings( numSpeedBins, 1 );
                for k = 1:numSpeedBins
                    legendText(k) = sprintf( "[%g, %g)", ...
                        obj.SpeedBinEdges(k), ...
                        obj.SpeedBinEdges(k+1) );
                end % for
                obj.Legend.String = legendText;

                % Mark the chart clean.
                obj.ComputationRequired = false;

            end % if

            % Refresh the chart's decorative properties.
            set( obj.Patches, ...
                "FaceAlpha", obj.FaceAlpha, ...
                "LineWidth", obj.LineWidth, ...
                "LineStyle", obj.LineStyle, ...
                "EdgeColor", obj.EdgeColor, ...
                "EdgeAlpha", obj.EdgeAlpha )
            set( [obj.BackdropCircles; obj.BackdropRays], ...
                "Color", obj.BackdropColor, ...
                "LineWidth", obj.BackdropLineWidth, ...
                "LineStyle", obj.BackdropLineStyle )
            set( obj.DirectionLabels, ...
                "FontSize", obj.DirectionLabelFontSize, ...
                "FontWeight", obj.DirectionLabelFontWeight, ...
                "FontAngle", obj.DirectionLabelFontAngle, ...
                "Visible", obj.DirectionLabelVisible )
            set( obj.RadialLabels, ...
                "FontSize", obj.RadialLabelFontSize, ...
                "FontWeight", obj.RadialLabelFontWeight, ...
                "FontAngle", obj.RadialLabelFontAngle, ...
                "Visible", obj.RadialLabelVisible )
            set( obj.Legend, ...
                "Location", obj.LegendLocation, ...
                "Orientation", obj.LegendOrientation, ...
                "NumColumns", obj.LegendNumColumns, ...
                "Color", obj.LegendColor, ...
                "Box", obj.LegendBox, ...
                "Visible", obj.LegendVisible, ...
                "EdgeColor", obj.LegendEdgeColor, ...
                "FontAngle", obj.LegendFontAngle, ...
                "FontSize", obj.LegendFontSize, ...
                "FontWeight", obj.LegendFontWeight, ...
                "LineWidth", obj.LegendLineWidth, ...
                "TextColor", obj.LegendTextColor )
            obj.Legend.Title.String = obj.LegendTitle;

        end % update

    end % methods ( Access = protected )

    methods ( Access = private )

        function updateCounts( obj )
            %UPDATECOUNTS Update the observation counts and derived
            %quantities.

            % Update the observation counts matrix. This has size pxq,
            % where p is the number of direction bins and q is the number
            % of speed bins. Each row corresponds to an angular direction
            % bin and each column corresponds to a windspeed bin. The
            % matrix elements are the number of data points in each
            % combined direction/speed bin.
            numDirectionBins = numel( obj.DirectionBinCenters );
            numSpeedBins = numel( obj.SpeedBinEdges ) - 1;
            obj.ObservationCounts = ...
                zeros( numDirectionBins, numSpeedBins );
            windDirection = obj.WindData_.Direction;

            % Loop over the direction bins. This computation is similar to
            % that performed by HISTCOUNTS2.
            for k = 1:numDirectionBins
                if k == 1
                    % The first direction bin is between 355 and 5 degrees,
                    % so requires different logic to the other direction
                    % bins (OR rather than AND).
                    directionIdx = ...
                        windDirection >= obj.DirectionEdges(k, 1) | ...
                        windDirection <  obj.DirectionEdges(k, 2);
                else
                    % Otherwise, the directions come from a continuous
                    % interval.
                    directionIdx = ...
                        windDirection >= obj.DirectionEdges(k, 1) & ...
                        windDirection <  obj.DirectionEdges(k, 2);
                end % if
                % Extract the speeds in the current wind direction
                % interval, count them according to the speed bins.
                obj.ObservationCounts(k, :) = ...
                    histcounts( obj.WindData_.Speed(directionIdx), ...
                    obj.SpeedBinEdges );
            end % for

            % Compute the percentage observation counts.
            numObs = height( obj.WindData_ );
            obj.PercentageObservationCounts = 100 * ...
                obj.ObservationCounts / numObs;

            % Compute the cumulative percentage observation counts by wind
            % direction.
            obj.CumulativePercentageObservationCounts = cumsum( ...
                obj.PercentageObservationCounts, 2 );

            % Update the radii and outer border.
            obj.MaxRadius = ceil( max( ...
                obj.CumulativePercentageObservationCounts(:) ) );
            obj.MinRadius = obj.MaxRadius / 50;
            obj.OuterBorder = obj.MinRadius + obj.MaxRadius + 1;
            obj.CircleRadii = obj.MinRadius + (1:obj.NumCircles) * ...
                obj.MaxRadius / obj.NumCircles;

        end % updateCounts

        function updateRadialLabels( obj )
            %UPDATERADIALLABELS Update the radial labels (position and
            %text). Note that the angle is converted from clockwise from
            %North to anticlockwise from East.

            radTextX = sind( obj.RadialLabelAngle ) * obj.CircleRadii;
            radTextY = cosd( obj.RadialLabelAngle ) * obj.CircleRadii;
            radText = num2str( obj.CircleRadii(:), "%.1f%%" );
            for k = 1:numel( obj.RadialLabels )
                set( obj.RadialLabels(k), ...
                    "Position", [radTextX(k), radTextY(k), 0], ...
                    "String", radText(k, :) )
            end % for

        end % updateRadialLabels

        function updateDirectionLabels( obj )
            %UPDATEDIRECTIONLABELS Update the direction labels.

            % Define the radius at which to place the direction labels.
            textRadius = obj.OuterBorder + obj.DirectionLabelOffset;

            % Cartesian coordinates of the text labels.
            textX = textRadius * cosd( obj.RayAngles );
            textY = textRadius * sind( obj.RayAngles );
            for k = 1 : numel( obj.DirectionLabels )
                set( obj.DirectionLabels(k), ...
                    "Position", [textX(k), textY(k), 0] );
            end % for

        end % updateDirectionLabels

        function onPatchClicked( obj, s, ~ )
            %ONPATCHCLICKED Hide/show the bin data text box.

            % Identify the clicked patch.
            clickedPatch = obj.Patches == s;

            % Quickly flash the selected patch to provide visual feedback.
            currentFaceColor = obj.Patches(clickedPatch).FaceColor;
            obj.Patches(clickedPatch).FaceColor = ...
                [1, 1, 1] - currentFaceColor;
            pause( 0.1 )
            obj.Patches(clickedPatch).FaceColor = currentFaceColor;

            % Toggle the visibility of the corresponding text box.
            obj.TextBoxes(clickedPatch).Visible = ...
                ~obj.TextBoxes(clickedPatch).Visible;

        end % onPatchClicked

    end % methods ( Access = private )

end % classdef

function windData = defaultWindData()
%DEFAULTWINDDATA Create a default empty wind data table.

Direction = double.empty( 0, 1 );
Speed = double.empty( 0, 1 );
windData = table( Direction, Speed );

end % defaultWindData

function mustBeWindData( t )
%MUSTBEWINDDATA Verify that the 2-column table t contains valid windspeed
%and direction data.

% Check the table has the required variable names.
varNames = t.Properties.VariableNames;
assert( isequal( sort( varNames ), ["Direction", "Speed"] ), ...
    "WindRose:InvalidWindData", ...
    "The wind data must be specified as a table with two columns " + ...
    "named Direction and Speed." )

% Check the windspeed and wind direction values.
validateattributes( t.Speed, "double", ...
    ["column", "real", "finite", "nonnegative"], ...
    "WindRose/mustBeWindData", "the windspeed data" )
validateattributes( t.Direction, "double", ...
    {"column", "real", "finite", "nonnegative", "<=", 360}, ...
    "WindRose/mustBeWindData", "the wind direction data" )

end % mustBeWindData

function labText = directionLabelText()
%DIRECTIONLABELTEXT Direction label text, counterclockwise from East.

angles = [90:-22.5:0, 337.5:-22.5:112.5];
labText = WindRoseChart.DirectionLookup(angles);

end % directionLabelText

function mustBeDirection( d )
%MUSTBEDIRECTION Validate that the given direction is a member of the
%available directions.

mustBeMember( d, values( WindRoseChart.DirectionLookup ) )

end % mustBeDirection

function mustBeLegendLocation( location )
%MUSTBELEGENDLOCATION Validate that the given location is a member of the
%available legend locations.

leg = matlab.graphics.illustration.Legend();
legendCleanup = onCleanup( @() delete( leg ) );
validLocations = set( leg, "Location" );
mustBeMember( location, validLocations )

end % mustBeLegendLocation

function mustBeColor( c, opts )
%MUSTBECOLOR Validate the given input, c, is a valid color or a member of
%the finite set of string options opts.

c = convertCharsToStrings( c );
if ~isstring( c ) || ~ismember( c, opts )
    validatecolor( c );
end % if

end % mustBeColor