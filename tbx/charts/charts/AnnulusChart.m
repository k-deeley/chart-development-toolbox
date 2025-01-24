classdef AnnulusChart < Component
    %ANNULUSCHART Annulus (ring) chart, similar to a 3D pie chart.

    % Copyright 2019-2025 The MathWorks, Inc.

    properties ( Dependent )
        % Chart data, comprising a positive vector.
        Data(:, 1) double {mustBeNonempty, mustBePositive}
        % Wedge face colors.
        FaceColor  
        % Wedge label text.
        LabelText(:, 1) string
        % Wedge label font size.
        LabelFontSize(1, 1) double {mustBePositive, mustBeFinite}
        % Specifies whether percentages are shown on the labels.
        LabelPercentages(1, 1) matlab.lang.OnOffSwitchState
        % Visibility of the wedge labels.
        LabelVisible(1, 1) matlab.lang.OnOffSwitchState
        % Legend text.
        LegendText(:, 1) string
        % Specifies whether percentages are shown in the legend.
        LegendPercentages(1, 1) matlab.lang.OnOffSwitchState        
        % Legend color.
        LegendColor
        % Legend location.
        LegendLocation(1, 1) string {mustBeLegendLocation}
        % Number of columns in the legend.
        LegendNumColumns(1, 1) double {mustBeInteger, mustBePositive}
        % Legend orientation.
        LegendOrientation(1, 1) string ...
            {mustBeMember( LegendOrientation, ...
            ["vertical", "horizontal"] )}
        % Legend title.
        LegendTitle(1, 1) string
        % Visibility of the chart legend.
        LegendVisible(1, 1) matlab.lang.OnOffSwitchState
        % Font size used in the legend.
        LegendFontSize(1, 1) double {mustBePositive, mustBeFinite}
        % Box property of the legend.
        LegendBox(1, 1) matlab.lang.OnOffSwitchState
        % Chart controls.
        Controls(1, 1) matlab.lang.OnOffSwitchState
    end % properties ( Dependent )

    properties ( Dependent, SetAccess = private )
        % Chart data, in percentage form.
        DataPercentages(:, 1) double {mustBeNonempty, ...
            mustBeInRange( DataPercentages, 0, 100 )}
    end % properties ( Dependent, SetAccess = private )

    properties ( Access = private )
        % Internal storage for the Data property.
        Data_(:, 1) double {mustBeNonempty, mustBePositive} = 1
        % Internal storage for the FaceColor property.
        FaceColor_(:, 3) double {mustBeInRange( FaceColor_, 0, 1 )} = ...
            [0, 0, 0]
        % Internal storage for the Label property.
        LabelText_(:, 1) string = string.empty( 0, 1 )
        % Internal storage for the LabelFontSize property.
        LabelFontSize_(1, 1) double {mustBePositive, mustBeFinite} = 10
        % Internal storage for the LabelPercentages property.
        LabelPercentages_(1, 1) matlab.lang.OnOffSwitchState = "on"
        % Internal storage for the LabelVisible property.
        LabelVisible_(1, 1) matlab.lang.OnOffSwitchState = "on"        
        % Internal storage for the LegendText property.
        LegendText_(:, 1) string = string.empty( 0, 1 )
        % Internal storage for the LegendPercentages property.
        LegendPercentages_(1, 1) matlab.lang.OnOffSwitchState = "off"
        % Explosion logic for each wedge.
        WedgeExpanded(1, :) logical = false
        % Logical scalar specifying whether an update is required.
        ComputationRequired(1, 1) logical = true
    end % properties ( Access = private )

    properties ( Access = private, Transient, NonCopyable )
        % Chart layout.
        LayoutGrid(:, 1) matlab.ui.container.GridLayout ...
            {mustBeScalarOrEmpty}
        % Chart axes.
        Axes(:, 1) matlab.graphics.axis.Axes {mustBeScalarOrEmpty}
        % Axes legend.
        Legend(:, 1) matlab.graphics.illustration.Legend ...
            {mustBeScalarOrEmpty}
        % Toggle button for the chart controls.
        ToggleButton(:, 1) matlab.ui.controls.ToolbarStateButton ...
            {mustBeScalarOrEmpty}
        % Graphics objects (patches and surfaces) used for the wedges.
        WedgeGraphics(:, 6) matlab.graphics.Graphics = gobjects( 0, 6 )
        % Text objects used for the wedge labels.
        WedgeLabels(:, 1) matlab.graphics.primitive.Text        
        % Check box for the label visibility.
        VisibleLabelsCheckBox(:, 1) matlab.ui.control.CheckBox ...
            {mustBeScalarOrEmpty}
        % Check box for the label percentages.
        LabelPercentagesCheckBox(:, 1) matlab.ui.control.CheckBox ...
            {mustBeScalarOrEmpty}
        % Button to explode all wedges.
        ExplodeButton(:, 1) matlab.ui.control.Button {mustBeScalarOrEmpty}
        % Button to retract all wedges.
        RetractButton(:, 1) matlab.ui.control.Button {mustBeScalarOrEmpty}
        % Spinner for the label font size.
        LabelFontSizeSpinner(:, 1) matlab.ui.control.Spinner ...
            {mustBeScalarOrEmpty}
        % Check box for the legend visibility.
        LegendVisibleCheckBox(:, 1) matlab.ui.control.CheckBox ...
            {mustBeScalarOrEmpty}
        % Check box for the legend percentages.
        LegendPercentagesCheckBox(:, 1) matlab.ui.control.CheckBox ...
            {mustBeScalarOrEmpty}
        % Check box for the legend box.
        LegendBoxCheckBox(:, 1) matlab.ui.control.CheckBox ...
            {mustBeScalarOrEmpty}
        % Dropdown menu for the legend location.
        LegendLocationDropDown(:, 1) matlab.ui.control.DropDown ...
            {mustBeScalarOrEmpty}
        % Spinnder for the number of columns in the legend.
        LegendNumColumnsSpinner(:, 1) matlab.ui.control.Spinner ...
            {mustBeScalarOrEmpty}
        % Dropdown menu for the legend orientation.
        LegendOrientationDropDown(:, 1) matlab.ui.control.DropDown ...
            {mustBeScalarOrEmpty}
        % Edit field for the legend title.
        LegendTitleEditField(:, 1) matlab.ui.control.EditField ...
            {mustBeScalarOrEmpty}
    end % properties ( Access = private, Transient, NonCopyable )

    properties ( Constant, GetAccess = private )
        % Inner radius of the annulus.
        InnerRadius(1, 1) double {mustBeNonnegative, mustBeFinite} = 4
        % Outer radius of the annulus.
        OuterRadius(1, 1) double {mustBeNonnegative, mustBeFinite} = 9
        % Number of edges in each wedge.
        NumEdges(1, 1) double {mustBeInteger, mustBePositive} = 100
        % Explosion range (radial distance).
        ExplosionRange(1, 1) double {mustBeNonnegative, mustBeFinite} = 0.5
        % Explosion factor used for individual wedges.
        ExplosionFactor(1, 1) double {mustBeNonnegative, mustBeFinite} = 2
    end % properties ( Constant, GetAccess = private )

    properties ( Constant, Hidden )
        % Product dependencies.
        Dependencies(1, :) string = "MATLAB"
        % Description.
        ShortDescription(1, 1) string = "Visualize relative " + ...
            "proportions in a data vector using an annulus (ring)"
    end % properties ( Constant, Hidden )

    methods

        function value = get.Data( obj )

            value = obj.Data_;

        end % get.Data

        function set.Data( obj, value )

            % Mark the chart for an update.
            obj.ComputationRequired = true;

            % Store the internal value.
            obj.Data_ = value;

        end % set.Data

        function value = get.LabelText( obj )

            value = obj.LabelText_;

        end % get.Label

        function set.LabelText( obj, value )

            % Check that we have the right number of strings.
            assert( numel( value ) == numel( obj.Data_ ), ...
                "AnnulusChart:LabelTextLengthMismatch", ...
                "The number of labels must match the number " + ...
                "of data values." )

            % Mark the chart for an update.
            obj.ComputationRequired = true;

            % Update the internal, stored property.
            obj.LabelText_ = value;            

        end % set.LabelText

        function value = get.LabelVisible( obj )

            if isempty( obj.WedgeLabels )
                value = "on";
            else
                value = obj.WedgeLabels(1).Visible;
            end % if

            value = matlab.lang.OnOffSwitchState( value );

        end % get.VisibleLabels

        function set.LabelVisible( obj, value )

            % Update the flags.
            obj.ComputationRequired = true;
            obj.LabelVisible_ = value;

            % Update the controls.
            obj.VisibleLabelsCheckBox.Value = value;

        end % set.VisibleLabels

        function value = get.LabelFontSize( obj )

            value = obj.LabelFontSize_;

        end % get.LabelFontSize

        function set.LabelFontSize( obj, value )

            obj.ComputationRequired = true;
            obj.LabelFontSize_ = value;
            obj.LabelFontSizeSpinner.Value = value;

        end % set.LabelFontSize

        function value = get.LabelPercentages( obj )

            value = obj.LabelPercentages_;

        end % get.LabelPercentages

        function set.LabelPercentages( obj, value )

            % Mark the chart for an update.
            obj.ComputationRequired = true;

            % Update the internal stored value.
            obj.LabelPercentages_ = value;

            % Update the control.
            obj.LabelPercentagesCheckBox.Value = value;            

        end % set.LabelPercentages

        function value = get.FaceColor( obj )

            value = cell2mat( ...
                get( obj.WedgeGraphics(:, 1), "FaceColor" ) );

        end % get.FaceColor

        function set.FaceColor( obj, value )

            % Check that we have the right number of colors.
            value = validatecolor( value, "multiple" );
            assert( height( value ) == numel( obj.Data_ ), ...
                "AnnulusChart:FaceColorHeightMismatch", ...
                "The number of face colors must match the number " + ...
                "of data values." )

            % Mark the chart for an update.
            obj.ComputationRequired = true;

            % Store the internal value.
            obj.FaceColor_ = value;

        end % set.FaceColor

        function value = get.LegendText( obj )

            value = obj.LegendText_;

        end % get.LegendText

        function set.LegendText( obj, value )

            % Check that we have the right number of strings.
            assert( numel( value ) == numel( obj.Data_ ), ...
                "AnnulusChart:LegendTextLengthMismatch", ...
                "The number of legend entries must match the number " + ...
                "of data values." )

            % Mark the chart for an update.
            obj.ComputationRequired = true;

            % Store the internal value.
            obj.LegendText_ = value;
            
        end % set.LegendText

        function value = get.LegendColor( obj )

            value = obj.Legend.Color;

        end % get.LegendColor

        function set.LegendColor( obj, value )

            if ~isequal( value, "none" )
                value = validatecolor( value, "one" );
            end % if
            obj.Legend.Color = value;

        end % set.LegendColor

        function value = get.LegendLocation( obj )

            value = obj.Legend.Location;

        end % get.LegendLocation

        function set.LegendLocation( obj, value )

            % Update the legend.
            obj.Legend.Location = value;

            % Update the control.
            obj.LegendLocationDropDown.Value = value;

        end % set.LegendLocation

        function value = get.LegendNumColumns( obj )

            value = obj.Legend.NumColumns;

        end % get.LegendNumColumns

        function set.LegendNumColumns( obj, value )

            % Update the legend.
            obj.Legend.NumColumns = value;

            % Update the control.
            obj.LegendNumColumnsSpinner.Value = value;

        end % set.LegendNumColumns

        function value = get.LegendOrientation( obj )

            value = obj.Legend.Orientation;

        end % get.LegendOrientation

        function set.LegendOrientation( obj, value )

            % Update the legend.
            obj.Legend.Orientation = value;

            % Update the control.
            obj.LegendOrientationDropDown.Value = value;

        end % set.LegendOrientation

        function value = get.LegendTitle( obj )

            value = obj.Legend.Title.String;

        end % get.LegendTitle

        function set.LegendTitle( obj, value )

            obj.Legend.Title.String = value;
            obj.LegendTitleEditField.Value = value;

        end % set.LegendTitle

        function value = get.LegendPercentages( obj )

            value = obj.LegendPercentages_;

        end % get.LegendPercentages

        function set.LegendPercentages( obj, value )

            % Mark the chart for an update.
            obj.ComputationRequired = true;

            % Store the internal value.
            obj.LegendPercentages_ = value;

            % Update the control.
            obj.LegendPercentagesCheckBox.Value = value;            

        end % set.LegendPercentages

        function value = get.LegendVisible( obj )

            value = obj.Legend.Visible;

        end % get.LegendVisible

        function set.LegendVisible( obj, value )

            % Update the legend.
            obj.Legend.Visible = value;

            % Update the control.
            obj.LegendVisibleCheckBox.Value = value;

        end % set.LegendVisible

        function value = get.LegendFontSize( obj )

            value = obj.Legend.FontSize;

        end % get.LegendFontSize

        function set.LegendFontSize( obj, value )

            obj.Legend.FontSize = value;

        end % set.LegendFontSize

        function value = get.LegendBox( obj )

            value = obj.Legend.Box;

        end % get.LegendBox

        function set.LegendBox( obj, value )

            % Update the legend.
            obj.Legend.Box = value;

            % Update the control.
            obj.LegendBoxCheckBox.Value = value;

        end % set.LegendBox

        function value = get.Controls( obj )

            value = obj.ToggleButton.Value;

        end % get.Controls

        function set.Controls( obj, value )

            % Update the toggle button.
            obj.ToggleButton.Value = value;

            % Invoke the toggle button callback.
            obj.onToggleButtonPressed()

        end % set.Controls

        function value = get.DataPercentages( obj )

            value = 100 * obj.Data_ / sum( obj.Data_ );

        end % get.DataPercentages

    end % methods

    methods

        function obj = AnnulusChart( namedArgs )
            %ANNULUSCHART Construct an AnnulusChart, given optional
            %name-value arguments.

            arguments ( Input )
                namedArgs.?AnnulusChart
            end % arguments ( Input )

            % Set any user-defined properties.
            set( obj, namedArgs )

        end % constructor

        function varargout = title( obj, varargin )

            [varargout{1:nargout}] = title( obj.Axes, varargin{:} );

        end % title

        function varargout = view( obj, varargin )

            % Call the view function on the chart's axes.
            [varargout{1:nargout}] = view( obj.Axes, varargin{:} );

            % Update the wedge label positions.
            drawnow()
            obj.updateLabelPositions( 1:numel( obj.Data_ ) )

        end % view

        function exportgraphics( obj, varargin )

            exportgraphics( obj.Axes, varargin{:} )

        end % exportgraphics

        function resetView( obj )
            %RESETVIEW Restore the default chart view.

            % Reset the view.
            view( obj.Axes, [0, 50] )

            % Update the label positions.
            drawnow()
            obj.updateLabelPositions( 1:numel( obj.Data_ ) )

        end % resetView

        function explode( obj, wedgeIdx )
            %EXPLODE Explode wedges.

            arguments ( Input )
                obj(1, 1) AnnulusChart
                wedgeIdx(1, :) double {mustBeInteger, mustBePositive} = ...
                    1 : numel( obj.Data_ )
            end % arguments ( Input )

            % Validate the wedge indices.
            assert( all( wedgeIdx <= numel( obj.Data_ ) ), ...
                "AnnulusChart:IndexOutOfBounds", ...
                "The wedge indices must lie between 1 and the number" + ...
                " of data values." )

            % Retract any previously exploded wedges.
            expandedWedgesIdx = intersect( find( obj.WedgeExpanded ), ...
                wedgeIdx );
            obj.WedgeExpanded(expandedWedgesIdx) = false;
            obj.moveWedge( expandedWedgesIdx )

            % Mark the required wedges for explosion.
            obj.WedgeExpanded(wedgeIdx) = true;

            % Explode the wedges.
            obj.moveWedge( wedgeIdx )

        end % explode

        function retract( obj, wedgeIdx )
            %RETRACT Retract all wedges.

            arguments ( Input )
                obj(1, 1) AnnulusChart
                wedgeIdx(1, :) double {mustBeInteger, mustBePositive} = ...
                    1 : numel( obj.Data_ )
            end % arguments ( Input )

            % Expand any previously retracted wedges.
            retractedWedgesIdx = intersect( find( ~obj.WedgeExpanded ), ...
                wedgeIdx );
            obj.WedgeExpanded(retractedWedgesIdx) = true;
            obj.moveWedge( retractedWedgesIdx )

            % Mark all wedges for retraction.
            obj.WedgeExpanded(wedgeIdx) = false;

            % Retract the wedges.
            obj.moveWedge( wedgeIdx )

        end % retract

    end % methods

    methods ( Access = protected )

        function setup( obj )
            %SETUP Initialize the chart graphics.

            % Define the layout grid.
            obj.LayoutGrid = uigridlayout( obj, [1, 2], ...
                "ColumnWidth", ["1x", "0x"] );

            % Create the chart's axes, legend and title.
            obj.Axes = axes( "Parent", obj.LayoutGrid, ...
                "DataAspectRatio", [1, 1, 1], ...
                "Visible", "off", ...
                "View", [0, 50] );
            obj.Legend = legend( obj.Axes, "ButtonDownFcn", [] );
            title( obj.Axes, "Annulus Chart", "Visible", "on" )

            % Create a light object within the axes.
            light( obj.Axes )

            % Add a state button to show/hide the chart's controls.
            tb = axtoolbar( obj.Axes, "rotate" );
            iconPath = fullfile( chartsRoot(), "charts", "images", ...
                "Cog.png" );
            obj.ToggleButton = axtoolbarbtn( tb, "state", ...
                "Value", "off", ...
                "Tooltip", "Show chart controls", ...
                "Icon", iconPath, ...
                "ValueChangedFcn", @obj.onToggleButtonPressed );

            % Create a panel for the chart controls.
            mainControlPanel = uipanel( "Parent", obj.LayoutGrid, ...
                "Title", "Chart Controls", ...
                "FontWeight", "bold" );
            mainControlPanel.Layout.Column = 2;

            % Define the control layout.
            controlLayout = uigridlayout( mainControlPanel, [2, 1], ...
                "RowHeight", ["fit", "fit"] );

            % Add a panel for the wedge-related controls.
            wedgePanel = uipanel( "Parent", controlLayout, ...
                "Title", "Wedges", ...
                "FontWeight", "bold" );
            wedgeLayout = uigridlayout( wedgePanel, [4, 2], ...
                "RowHeight", repelem( "fit", 4 ) );
            obj.VisibleLabelsCheckBox = uicheckbox( ...
                "Parent", wedgeLayout, ...
                "Value", obj.LabelVisible, ...
                "Text", "Show labels", ...
                "Tooltip", "Show/hide the wedge labels", ...
                "ValueChangedFcn", ...
                @( s, ~ ) set( obj, "LabelVisible", s.Value ) );
            obj.VisibleLabelsCheckBox.Layout.Column = [1, 2];
            obj.LabelPercentagesCheckBox = uicheckbox( ...
                "Parent", wedgeLayout, ...
                "Value", obj.LabelPercentages_, ...
                "Text", "Show label percentages", ...
                "Tooltip", ...
                "Show/hide percentages in the wedge labels", ...
                "ValueChangedFcn", ...
                @( s, ~ ) set( obj, "LabelPercentages", s.Value ) );
            obj.LabelPercentagesCheckBox.Layout.Column = [1, 2];
            uilabel( "Parent", wedgeLayout, ...
                "Text", "Label font size:", ...
                "HorizontalAlignment", "right" );
            obj.LabelFontSizeSpinner = uispinner( ...
                "Parent", wedgeLayout, ...
                "Value", obj.LabelFontSize_, ...
                "Step", 1, ...
                "Limits", [0, Inf], ...
                "LowerLimitInclusive", "off", ...
                "UpperLimitInclusive", "off", ...
                "ValueChangedFcn", ...
                @( s, ~ ) set( obj, "LabelFontSize", s.Value ) );            
            obj.ExplodeButton = uibutton( "Parent", wedgeLayout, ...
                "Text", "Explode", ...
                "Tooltip", "Explode all wedges", ...
                "ButtonPushedFcn", @( ~, ~ ) obj.explode() );
            obj.RetractButton = uibutton( "Parent", wedgeLayout, ...
                "Text", "Retract", ...
                "Tooltip", "Retract all wedges", ...
                "ButtonPushedFcn", @( ~, ~ ) obj.retract() );

            % Add a panel for the legend-related controls.
            legendPanel = uipanel( "Parent", controlLayout, ...
                "Title", "Legend", ...
                "FontWeight", "bold" );
            legendLayout = uigridlayout( legendPanel, [7, 2], ...
                "RowHeight", repelem( "fit", 7 ), ...
                "ColumnWidth", ["fit", "fit"] );
            obj.LegendVisibleCheckBox = uicheckbox( ...
                "Parent", legendLayout, ...
                "Value", obj.LegendVisible, ...
                "Text", "Show legend", ...
                "Tooltip", "Hide/show the legend", ...
                "ValueChangedFcn", ...
                @( s, ~ ) set( obj, "LegendVisible", s.Value ) );
            obj.LegendVisibleCheckBox.Layout.Column = [1, 2];
            obj.LegendPercentagesCheckBox = uicheckbox( ...
                "Parent", legendLayout, ...
                "Value", obj.LegendPercentages_, ...
                "Text", "Show legend percentages", ...
                "Tooltip", ...
                "Show/hide percentages in the legend", ...
                "ValueChangedFcn", ...
                @( s, ~ ) set( obj, "LegendPercentages", s.Value ) );
            obj.LegendPercentagesCheckBox.Layout.Column = [1, 2];
            obj.LegendBoxCheckBox = uicheckbox( ...
                "Parent", legendLayout, ...
                "Value", obj.LegendBox, ...
                "Text", "Box", ...
                "Tooltip", "Show/hide the legend box", ...
                "ValueChangedFcn", ...
                @( s, ~ ) set( obj, "LegendBox", s.Value ) );
            obj.LegendBoxCheckBox.Layout.Column = [1, 2];
            uilabel( "Parent", legendLayout, ...
                "Text", "Legend location:", ...
                "HorizontalAlignment", "right" );
            obj.LegendLocationDropDown = uidropdown( ...
                "Parent", legendLayout, ...
                "Items", set( obj.Legend, "Location" ), ...
                "Tooltip", "Select the legend location", ...
                "Value", obj.LegendLocation, ...
                "ValueChangedFcn", ...
                @( s, ~ ) set( obj, "LegendLocation", s.Value ) );
            uilabel( "Parent", legendLayout, ...
                "Text", "Number of columns:", ...
                "HorizontalAlignment", "right" );
            obj.LegendNumColumnsSpinner = uispinner( ...
                "Parent", legendLayout, ...
                "Value", obj.LegendNumColumns, ...
                "Tooltip", ...
                "Specify the number of columns in the legend", ...
                "Limits", [1, Inf], ...
                "UpperLimitInclusive", false, ...
                "ValueDisplayFormat", "%d", ...
                "Step", 1, ...
                "RoundFractionalValues", "on", ...
                "ValueChangedFcn", ...
                @( s, ~ ) set( obj, "LegendNumColumns", s.Value ) );
            uilabel( "Parent", legendLayout, ...
                "Text", "Legend orientation:", ...
                "HorizontalAlignment", "right" );
            obj.LegendOrientationDropDown = uidropdown( ...
                "Parent", legendLayout, ...
                "Items", set( obj.Legend, "Orientation" ), ...
                "Tooltip", "Select the legend orientation", ...
                "Value", obj.LegendOrientation, ...
                "ValueChangedFcn", ...
                @( s, ~ ) set( obj, "LegendOrientation", s.Value ) );
            uilabel( "Parent", legendLayout, ...
                "Text", "Legend title:", ...
                "HorizontalAlignment", "right" );
            obj.LegendTitleEditField = uieditfield( ...
                "Parent", legendLayout, ...
                "Value", obj.LegendTitle, ...
                "Tooltip", "Specify the legend title", ...
                "ValueChangedFcn", ...
                @( s, ~ ) set( obj, "LegendTitle", s.Value ) );

        end % setup

        function update( obj )
            %UPDATE Refresh the chart graphics.

            if obj.ComputationRequired

                % Number of wedges required.
                numWedges = numel( obj.Data_ );

                % Determine the current number of wedges.
                currentNumWedges = height( obj.WedgeGraphics );

                % Update the colors.
                currentNumColors = height( obj.FaceColor_ );
                if currentNumColors < numWedges                    
                    obj.FaceColor_(end+1:numWedges, :) = hsv( ...
                        numWedges - currentNumColors );
                else
                    obj.FaceColor_ = obj.FaceColor_(1:numWedges, :);
                end % if                

                if numWedges < currentNumWedges
                    % Delete the appropriate wedges and labels.
                    numToDelete = currentNumWedges - numWedges;
                    % Wedge graphics.
                    delete( obj.WedgeGraphics(end-numToDelete+1:end, :) )
                    obj.WedgeGraphics(end-numToDelete+1:end, :) = [];
                    % Wedge labels.
                    delete( obj.WedgeLabels(end-numToDelete+1:end) )
                    obj.WedgeLabels(end-numToDelete+1:end) = [];
                    % Update the expansion record.
                    obj.WedgeExpanded = obj.WedgeExpanded(1:numWedges);
                    % Label and legend text.
                    obj.LabelText_ = obj.LabelText_(1:numWedges);
                    obj.LegendText_ = obj.LegendText_(1:numWedges);
                else
                    % Create new wedge graphics and labels.
                    numToCreate = numWedges - currentNumWedges;
                    % Allocate space in the graphics array.
                    obj.WedgeGraphics = [obj.WedgeGraphics;
                        gobjects( numToCreate, 6 ) ];
                    for k = currentNumWedges+1:numWedges
                        % Create new surface, patch and text objects.
                        obj.WedgeGraphics(k, 1) = ...
                            patch( "Parent", obj.Axes, ...
                            "XData", NaN, ...
                            "YData", NaN, ...
                            "ZData", NaN );
                        obj.WedgeGraphics(k, 2) = ...
                            patch( "Parent", obj.Axes, ...
                            "HandleVisibility", "off", ...
                            "XData", NaN, ...
                            "YData", NaN, ...
                            "ZData", NaN );
                        obj.WedgeGraphics(k, 3) = ...
                            surface( obj.Axes, NaN, NaN, NaN, ...
                            "HandleVisibility", "off" );
                        obj.WedgeGraphics(k, 4) = ...
                            surface( obj.Axes, NaN, NaN, NaN, ...
                            "HandleVisibility", "off" );
                        obj.WedgeGraphics(k, 5) = ...
                            patch( "Parent", obj.Axes, ...
                            "HandleVisibility", "off", ...
                            "XData", NaN, ...
                            "YData", NaN, ...
                            "ZData", NaN );
                        obj.WedgeGraphics(k, 6) = ...
                            patch( "Parent", obj.Axes, ...
                            "HandleVisibility", "off", ...
                            "XData", NaN, ...
                            "YData", NaN, ...
                            "ZData", NaN );
                        % Update the expansion record.
                        obj.WedgeExpanded(1, k) = false;
                        % Update the label and legend text.
                        if numel( obj.LabelText_ ) < k
                            obj.LabelText_(k, 1) = "Data " + k;
                        end % if
                        if numel( obj.LegendText ) < k
                            obj.LegendText_(k, 1) = "Data " + k;                        
                        end % if
                        obj.WedgeLabels(k, 1) = text( ...
                            "Parent", obj.Axes, ...
                            "Position", NaN( 1, 3 ), ...
                            "String", "", ...
                            "FontSize", 10, ...                            
                            "Margin", 1 );
                    end % for

                    % Set graphics properties for each newly-created wedge
                    % object.
                    for r = 1 : numWedges
                        for c = 1 : width( obj.WedgeGraphics )
                            set( obj.WedgeGraphics(r, c), ...
                                "EdgeColor", "none", ...                                
                                "LineWidth", 1.75, ...
                                "SpecularStrength", 0, ...
                                "AmbientStrength", 0.45, ...
                                "ButtonDownFcn", @obj.onWedgeClicked, ...
                                "Tag", num2str( r ) )
                        end % for
                    end % for
                end % if

                % Compute the angular span of each wedge.
                wedgeSpans = 2 * pi * obj.DataPercentages / 100;

                % Loop over each wedge to set its data.
                for k = 1 : numWedges
                    % Minimum wedge azimuthal angle.
                    minAz = sum( wedgeSpans(1:k-1) );
                    % Maximum wedge azimuthal angle.
                    maxAz = sum( wedgeSpans(1:k) );
                    % Angular subdivision.
                    fineAngle = linspace( minAz, maxAz, obj.NumEdges );
                    cosAngle = cos( fineAngle );
                    sinAngle = sin( fineAngle );
                    % Define the surface coordinates.
                    x = [1; 1] * cosAngle;
                    y = [1; 1] * sinAngle;
                    z = [-1; 1] * ones( 1, obj.NumEdges );
                    % Top edge.
                    set( obj.WedgeGraphics(k, 1), ...
                        "XData", ...
                        [obj.InnerRadius * cosAngle, ...
                        fliplr( obj.OuterRadius * cosAngle )], ...
                        "YData", ...
                        [obj.InnerRadius * sinAngle, ...
                        fliplr( obj.OuterRadius * sinAngle )], ...
                        "ZData", ones( 1, 2 * obj.NumEdges ) )
                    % Bottom edge.
                    set( obj.WedgeGraphics(k, 2), ...
                        "XData", ...
                        [obj.InnerRadius * cosAngle, ...
                        fliplr( obj.OuterRadius * cosAngle )], ...
                        "YData", ...
                        [obj.InnerRadius * sinAngle, ...
                        fliplr( obj.OuterRadius * sinAngle )], ...
                        "ZData", (-1) * ones( 1, 2 * obj.NumEdges ) )
                    % Curved surfaces.
                    set( obj.WedgeGraphics(k, 3), ...
                        "XData", x * obj.InnerRadius, ...
                        "YData", y * obj.InnerRadius, ...
                        "ZData", z )
                    set( obj.WedgeGraphics(k, 4), ...
                        "XData", x * obj.OuterRadius, ...
                        "YData", y * obj.OuterRadius, ...
                        "ZData", z )
                    % Side faces.
                    cosMinAz = cos( minAz );
                    sinMinAz = sin( minAz );
                    cosMaxAz = cos( maxAz );
                    sinMaxAz = sin( maxAz );
                    inOutOutIn = [obj.InnerRadius, obj.OuterRadius, ...
                        obj.OuterRadius, obj.InnerRadius];
                    set( obj.WedgeGraphics(k, 5), ...
                        "XData", cosMinAz * inOutOutIn, ...
                        "YData", sinMinAz * inOutOutIn, ...
                        "ZData", [-1, -1, 1, 1] )
                    set( obj.WedgeGraphics(k, 6), ...
                        "XData", cosMaxAz * inOutOutIn, ...
                        "YData", sinMaxAz * inOutOutIn, ...
                        "ZData", [-1, -1, 1, 1] )
                end % for

                % Update the colors. Loop over the wedges and wedge labels.
                for k = 1 : numel( obj.Data_ )
                    % Extract the current color.
                    currentColor = obj.FaceColor_(k, :);
                    % Use a darker shade for each text label compared to 
                    % its associated wedge.
                    obj.WedgeLabels(k).Color = 0.5 * currentColor;
                    % Each wedge comprises four patches and two surfaces.
                    set( obj.WedgeGraphics(k, :), ...
                        "FaceColor", currentColor )
                end % for

                % Update the labels.
                set( obj.WedgeLabels, ...
                    "Visible", obj.LabelVisible_, ...
                    "FontSize", obj.LabelFontSize_ )

                % Mark the chart clean.
                obj.ComputationRequired = false;

            end % if

            % Update the label text and position.
            obj.updateWedgeLabels()            
            obj.updateLabelPositions( 1:numel( obj.Data_ ) )

            % Update the legend.
            obj.updateLegend()            

        end % update

    end % methods ( Access = protected )

    methods ( Access = private )

        function updateWedgeLabels( obj )
            %UPDATEWEDGELABELS Update the text in the wedge labels.

            % If necessary, append the percentages to the labels.
            if obj.LabelPercentages_
                newLabels = obj.LabelText_ + " (" + ...
                    num2str( obj.DataPercentages, "%.1f" ) + "%)";
            else
                newLabels = obj.LabelText_;
            end % if

            % Update the labels.
            for k = 1:numel( newLabels )
                obj.WedgeLabels(k).String = newLabels(k);
            end % for

        end % updateWedgeLabels

        function updateLabelPositions( obj, wedgeIdx )
            %UPDATELABELPOSITIONS Update the wedge label positions for the
            %specified wedges.

            % Compute the angular span of each wedge.
            wedgeSpans = 2 * pi * obj.DataPercentages / 100;

            % Record the current view.
            [currentAzimuth, currentElevation] = view( obj.Axes );

            % Loop over the required wedges.
            for k = wedgeIdx

                % Compute the average angle within the angular extension.
                averageAngle = 0.5 * (sum( wedgeSpans(1:k-1) ) + ...
                    sum( wedgeSpans(1:k) ));

                % Compute phi: this angle is needed to deal with the issue
                % of 3d perspective when setting the label positions.
                phi = mod( averageAngle - currentAzimuth * pi / 180, ...
                    2 * pi );

                % Compute dr: this controls how much further out the label
                % needs to be positioned in order to solve the perspective
                % problem.
                dr = tand( 90 - currentElevation ) * abs( sin( phi ) );

                % If the individual wedge is exploded, take into account
                % the extra radial extension.
                if obj.WedgeExpanded(k)
                    dr = dr + obj.ExplosionFactor * obj.ExplosionRange;
                end % if

                % Determine the horizontal text alignment.
                if phi > 0.5 * pi && phi < 1.5 * pi
                    textAlignment = "right";
                elseif phi == 0.5 * pi || phi == 1.5 * pi
                    textAlignment = "center";
                else
                    textAlignment = "left";
                end % if

                % Determine the vertical alignment (the angle phi is needed
                % because the current view needs to be taken into account).
                if phi <= pi
                    obj.WedgeLabels(k).VerticalAlignment = "bottom";
                else
                    obj.WedgeLabels(k).VerticalAlignment = "top";
                end % if

                % Calculate the new (x, y) coordinates and update the label
                % position.
                x = (dr + obj.OuterRadius) * cos( averageAngle );
                y = (dr + obj.OuterRadius) * sin( averageAngle );
                set( obj.WedgeLabels(k), "Position", [x, y, 0], ...
                    "HorizontalAlignment", textAlignment )

            end % for

        end % updateLabelPositions

        function moveWedge( obj, wedgeIdx )
            %MOVEWEDGE Move the wedge specified by wedgeIdx.

            % Compute the angular span of each wedge.
            wedgeSpans = 2 * pi * obj.DataPercentages / 100;

            % Compute the sign from the record of which wedges are expanded
            % (the logical vector WedgeExpanded).
            % Sign 1 means that the wedge should be exploded, -1 means that
            % the wedge should be contracted.
            sgn = -1 + 2 * obj.WedgeExpanded(wedgeIdx);

            % Loop over the wedges to move.
            for w = 1 : numel( wedgeIdx )

                % Compute the average angle within the angular span.
                averageAngle = 0.5 * (...
                    sum( wedgeSpans(1:wedgeIdx(w)-1)) + ...
                    sum( wedgeSpans(1:wedgeIdx(w)) ));

                % Update the data of each wedge piece.
                radius = obj.ExplosionFactor * obj.ExplosionRange;
                for k = 1 : width( obj.WedgeGraphics )
                    set( obj.WedgeGraphics(wedgeIdx(w), k), ...
                        "XData", ...
                        obj.WedgeGraphics(wedgeIdx(w), k).XData + ...
                        sgn(w) * radius * cos( averageAngle ), ...
                        "YData", ...
                        obj.WedgeGraphics(wedgeIdx(w), k).YData + ...
                        sgn(w) * radius * sin( averageAngle ) )
                end % for
            end % for

            % Update the label positions because the wedges have moved.
            drawnow()
            obj.updateLabelPositions( wedgeIdx )

        end % moveWedge

        function onWedgeClicked( obj, s, ~ )
            %ONWEDGECLICKED Respond to user clicks on the annulus' wedges.

            % Recover the wedge index from the Tag property.
            wedgeIdx = str2double( s.Tag );

            % Update the record of which wedges are expanded.
            obj.WedgeExpanded(wedgeIdx) = ~obj.WedgeExpanded(wedgeIdx);

            % Move the wedge.
            obj.moveWedge( wedgeIdx )

        end % onWedgeClicked

        function updateLegend( obj )
            %UPDATELEGEND Update the chart's legend.

            % Update the legend text.
            if obj.LegendPercentages_
                newLegendText = obj.LegendText_ + " (" + ...
                    num2str( obj.DataPercentages, "%.1f" ) + "%)";
            else
                newLegendText = obj.LegendText_;
            end % if
            obj.Legend.String = newLegendText;

        end % updateLegend        

        function onToggleButtonPressed( obj, ~, ~ )
            %ONTOGGLEBUTTONPRESSED Hide/show the chart controls.

            toggleDown = obj.ToggleButton.Value;

            if toggleDown
                % Show the controls.
                obj.LayoutGrid.ColumnWidth{2} = "fit";
                obj.ToggleButton.Tooltip = "Hide chart controls";
            else
                % Hide the controls.
                obj.LayoutGrid.ColumnWidth{2} = "0x";
                obj.ToggleButton.Tooltip = "Show chart controls";
            end % if

        end % onToggleButtonPressed

    end % methods ( Access = private )

end % classdef