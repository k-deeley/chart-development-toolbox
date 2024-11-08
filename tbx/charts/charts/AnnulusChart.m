classdef AnnulusChart < matlab.ui.componentcontainer.ComponentContainer
    %ANNULUSCHART Annulus (ring) chart, similar to a 3D pie chart.

    % Copyright 2019-2025 The MathWorks, Inc.
   
    properties ( AbortSet, Dependent )        
        % Specifies whether all the annulus' wedges are exploded.
        Exploded(1, 1) matlab.lang.OnOffSwitchState = "off"
        % Specifies whether percentages are shown on the labels.
        LabelPercentages(1, 1) matlab.lang.OnOffSwitchState = "on"
        % Specifies whether percentages are shown in the legend.
        LegendPercentages(1, 1) matlab.lang.OnOffSwitchState = "off"
    end % properties ( AbortSet, Dependent )
    
    properties ( Dependent )
        % Chart data, comprising a positive vector.
        Data(:, 1) double {mustBeNonempty, mustBePositive} = 1
        % Wedge label text.
        LabelText(:, 1) string = string.empty( 0, 1 )
        % Visibility of the wedge labels.
        VisibleLabels(1, 1) matlab.lang.OnOffSwitchState = "on"
        % Wedge label font size.
        LabelFontSize(1, 1) double {mustBePositive, mustBeFinite} = 9
        % Wedge face colors.
        FaceColor(:, 3) double {mustBeInRange( FaceColor, 0, 1 )}
        % Legend text.
        LegendText(:, 1) string = string.empty( 0, 1 )
        % Legend color.
        LegendColor
        % Legend location.
        LegendLocation(1, 1) string = ""
        % Number of columns in the legend.
        LegendNumColumns(1, 1) double {mustBeInteger, mustBePositive} = 1
        % Legend orientation.
        LegendOrientation(1, 1) string ...
            {mustBeMember( LegendOrientation, ...
            ["vertical", "horizontal"] )} = "vertical"
        % Legend title.
        LegendTitle(1, 1) string = ""
        % Visibility of the chart legend.
        LegendVisible(1, 1) matlab.lang.OnOffSwitchState = "on"
        % Font size used in the legend.
        LegendFontSize(1, 1) double {mustBePositive, mustBeFinite} = 9
        % Box property of the legend.
        LegendBox(1, 1) matlab.lang.OnOffSwitchState = "on"
        % Chart controls.
        Controls(1, 1) matlab.lang.OnOffSwitchState = "off"
    end % properties ( Dependent )
    
    properties ( Dependent, SetAccess = private )
        % Chart data, in percentage form.
        DataPercentages
    end % properties ( Dependent, SetAccess = private )
    
    properties ( Access = private )
        % Internal storage for the Data property.
        Data_(:, 1) double {mustBeNonempty, mustBePositive} = 1
        % Internal storage for the Exploded property.
        Exploded_(1, 1) matlab.lang.OnOffSwitchState = "off"
        % Internal storage for the Label property.
        LabelText_(:, 1) string = string.empty( 0, 1 )
        % Internal storage for the LabelPercentages property.
        LabelPercentages_(1, 1) matlab.lang.OnOffSwitchState = "on"
        % Internal storage for the LegendText property.
        LegendText_(:, 1) string = string.empty( 0, 1 )
        % Internal storage for the LegendPercentages property.
        LegendPercentages_(1, 1) matlab.lang.OnOffSwitchState = "off"
        % Explosion logic for each wedge.
        WedgeExpanded(1, :) logical = false( 1, 0 )
        % Logical scalar specifying whether an update is required.
        ComputationRequired(1, 1) logical = false
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
        % Check box for exploded wedges.
        ExplodedCheckBox(:, 1) matlab.ui.control.CheckBox ...
            {mustBeScalarOrEmpty}
        % Check box for the label visibility.
        VisibleLabelsCheckBox(:, 1) matlab.ui.control.CheckBox ...
            {mustBeScalarOrEmpty}
        % Check box for the label percentages.
        LabelPercentagesCheckBox(:, 1) matlab.ui.control.CheckBox ...
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
            assert( length( value ) == length( obj.Data_ ), ...
                "AnnulusChart:LabelTextLengthMismatch", ...
                "The number of labels must match the number " + ...
                "of data values." )
            % Update the internal, stored property.
            obj.LabelText_ = value;
            drawnow()
            % Update the legend and label text.
            obj.updateWedgeLabels()
            obj.updateLegend()
            
        end % set.LabelText
        
        function value = get.VisibleLabels( obj )
            
            if isempty( obj.WedgeLabels )
                value = "on";
            else
                value = obj.WedgeLabels(1).Visible;
            end % if
            value = matlab.lang.OnOffSwitchState( value );
            
        end % get.VisibleLabels
        
        function set.VisibleLabels( obj, value )
            
            % Update the wedge labels.
            set( obj.WedgeLabels, "Visible", value )
            % Update the contros.
            obj.VisibleLabelsCheckBox.Value = value;
            
        end % set.VisibleLabels
        
        function value = get.LabelFontSize( obj )
            
            value = obj.WedgeLabels(1).FontSize;
            
        end % get.LabelFontSize
        
        function set.LabelFontSize( obj, value )
            
            set( obj.WedgeLabels, "FontSize", value )
            
        end % set.LabelFontSize
        
        function value = get.LabelPercentages( obj )
            
            value = obj.LabelPercentages_;
            
        end % get.LabelPercentages
        
        function set.LabelPercentages( obj, value )
            
            % Update the internal stored value.
            obj.LabelPercentages_ = value;
            % Update the control.
            obj.LabelPercentagesCheckBox.Value = value;
            % Update the label text.
            obj.updateWedgeLabels()
            
        end % set.LabelPercentages
        
        function value = get.Exploded( obj )
            
            value = obj.Exploded_;
            
        end % get.Exploded
        
        function set.Exploded( obj, value )
            
            % Update the internal stored value.
            obj.Exploded_ = value;
            
            % Update the control.
            obj.ExplodedCheckBox.Value = value;
            
            % Update the record of the expanded wedges.
            if value
                % Retract any previously exploded wedges.
                expandedWedgesIdx = find( obj.WedgeExpanded );
                obj.WedgeExpanded(expandedWedgesIdx) = false;
                obj.moveWedge( expandedWedgesIdx )
                % Mark all wedges for explosion.
                obj.WedgeExpanded = true( 1, length( obj.Data_ ) );
            else
                % Expand any previously retracted wedges.
                retractedWedgesIdx = find( ~obj.WedgeExpanded );
                obj.WedgeExpanded(retractedWedgesIdx) = true;
                obj.moveWedge( retractedWedgesIdx )
                % Mark all wedges for retraction.
                obj.WedgeExpanded = false( 1, length( obj.Data_ ) );
            end % if
            
            % Explode/retract the wedges.
            obj.moveWedge( 1:length( obj.Data_ ) )
            
        end % set.Exploded
        
        function value = get.FaceColor( obj )
            
            value = cell2mat( ...
                get( obj.WedgeGraphics(:, 1), "FaceColor" ) );
            
        end % get.FaceColor
        
        function set.FaceColor( obj, value )
            
            obj.updateColors( value )
            
        end % set.FaceColor
        
        function value = get.LegendText( obj )
            
            value = obj.LegendText_;
            
        end % get.LegendText
        
        function set.LegendText( obj, value )
            
            % Check that we have the right number of strings.
            assert( length( value ) == length( obj.Data_ ), ...
                "AnnulusChart:LegendTextLengthMismatch", ...
                "The number of legend entries must match the number " + ...
                "of data values." )
            % Store the internal value.
            obj.LegendText_ = value;
            drawnow()
            % Update the legend.
            obj.updateLegend()
            
        end % set.LegendText
        
        function value = get.LegendColor( obj )
            
            value = obj.Legend.Color;
            
        end % get.LegendColor
        
        function set.LegendColor( obj, value )
            
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
            
        end % set.LegendTitle
        
        function value = get.LegendPercentages( obj )
            
            value = obj.LegendPercentages_;
            
        end % get.LegendPercentages
        
        function set.LegendPercentages( obj, value )
            
            % Store the internal value.
            obj.LegendPercentages_ = value;
            % Update the control.
            obj.LegendPercentagesCheckBox.Value = value;
            % Update the legend.
            obj.updateLegend()
            
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

            % Call the superclass constructor.
            obj@matlab.ui.componentcontainer.ComponentContainer( ...
                "Parent", [], ...
                "Units", "normalized", ...
                "Position", [0, 0, 1, 1] )

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
            obj.updateLabelPositions( 1:length( obj.Data_ ) )
            
        end % view
        
        function resetView( obj )
            %RESETVIEW Restore the default chart view.
            
            % Reset the view.
            view( obj.Axes, [0, 50] )
            % Update the label positions.
            obj.updateLabelPositions( 1:length( obj.Data_ ) )
            
        end % resetView
        
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

            % Define the layout and subpanels for the controls.
            controlLayout = uigridlayout( mainControlPanel, [2, 1], ...
                "RowHeight", ["fit", "fit"] );
            wedgePanel = uipanel( "Parent", controlLayout, ...
                "Title", "Wedges", ...
                "FontWeight", "bold" );
            wedgeLayout = uigridlayout( wedgePanel, [3, 1], ...
                "RowHeight", repmat( "fit", 1, 3 ) );
            obj.ExplodedCheckBox = uicheckbox( ...
                "Parent", wedgeLayout, ...
                "Value", obj.Exploded_, ...
                "Text", "Explode all wedges", ...
                "Tooltip", ...
                "Explode/retract all the wedges in the annulus", ...
                "ValueChangedFcn", ...
                @( s, ~ ) set( obj, "Exploded", s.Value ) );
            obj.VisibleLabelsCheckBox = uicheckbox( ...
                "Parent", wedgeLayout, ...
                "Value", obj.VisibleLabels, ...
                "Text", "Show labels", ...
                "Tooltip", "Show/hide the wedge labels", ...
                "ValueChangedFcn", ...
                @( s, ~ ) set( obj, "VisibleLabels", s.Value ) );
            obj.LabelPercentagesCheckBox = uicheckbox( ...
                "Parent", wedgeLayout, ...
                "Value", obj.LabelPercentages_, ...
                "Text", "Label percentages", ...
                "Tooltip", ...
                "Show/hide percentages in the wedge labels", ...
                "ValueChangedFcn", ...
                @( s, ~ ) set( obj, "LabelPercentages", s.Value ) );
            legendPanel = uipanel( "Parent", controlLayout, ...
                "Title", "Legend", ...
                "FontWeight", "bold" );
            legendLayout = uigridlayout( legendPanel, [6, 2], ...
                "RowHeight", repmat( "fit", 1, 6 ), ...
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
                "Text", "Legend percentages", ...
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
            
        end % setup
        
        function update( obj )
            %UPDATE Refresh the chart graphics.
            
            if obj.ComputationRequired
                
                % Number of wedges required.
                numWedges = numel( obj.Data_ );
                
                % Set the initial colormap.
                colors = hsv( numWedges );
                
                % Determine the current number of wedges.
                currentNumWedges = size( obj.WedgeGraphics, 1 );
                
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
                        % Update the expansion record, label text and wedge
                        % label text objects.
                        obj.WedgeExpanded(1, k) = false;
                        obj.LabelText_(k, 1) = "Data " + k;
                        obj.LegendText_(k, 1) = "Data " + k;
                        obj.WedgeLabels(k, 1) = text( ...
                            "Parent", obj.Axes, ...
                            "Position", NaN( 1, 3 ), ...
                            "String", "", ...
                            "FontSize", 10, ...
                            "Color", 0.5 * colors(k, :), ...
                            "Margin", 1 );
                    end % for
                    
                    % Set graphics properties for each newly-created wedge
                    % object.
                    for r = 1:numWedges
                        for c = 1:size( obj.WedgeGraphics, 2 )
                            set( obj.WedgeGraphics(r, c), ...
                                "EdgeColor", "none", ...
                                "FaceColor", colors(r, :), ...
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
                for k = 1:numWedges
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
                
                % Update the label text and position.
                obj.updateWedgeLabels()
                obj.updateLabelPositions( 1:numel( obj.Data_ ) )
                
                % Update the legend.
                obj.updateLegend()
                
                if numWedges ~= currentNumWedges
                    % Update the colors.
                    obj.updateColors( colors )
                    % Retract any expanded wedges.
                    expandedWedgesIdx = find( obj.WedgeExpanded );
                    obj.WedgeExpanded( expandedWedgesIdx ) = false;
                    obj.moveWedge( expandedWedgesIdx )
                    % Explode if necessary.
                    if obj.Exploded_
                        obj.WedgeExpanded = true( 1, numWedges );
                        obj.moveWedge( 1:numel( obj.Data_ ) )
                    end % if
                end % if
                
                % Mark the chart clean.
                obj.ComputationRequired = false;
                
            end % if
            
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
        
        function updateLabelPositions( obj , wedgeIdx )
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
                
                % If the annulus is exploded, take into account the extra
                % radial extension.
                if obj.Exploded_ == "on"
                    dr = dr + obj.ExplosionRange;
                end % if
                
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
            for w = 1:length( wedgeIdx )
                
                % Compute the average angle within the angular span.
                averageAngle = 0.5 * (...
                    sum( wedgeSpans(1:wedgeIdx(w)-1)) + ...
                    sum( wedgeSpans(1:wedgeIdx(w)) ));
                
                % Update the data of each wedge piece.
                radius = obj.ExplosionFactor * obj.ExplosionRange;
                for k = 1:size( obj.WedgeGraphics, 2 )
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
        
        function updateColors( obj, colors )
            %UPDATECOLORS Update the colors of the wedge graphics and
            %legend items.
            
            % Loop over the number of wedges/labels/legend items.
            for k = 1:length( obj.Data_ )
                % Use a darker shade for each text label compared to its
                % associated wedge.
                obj.WedgeLabels(k).Color = 0.5 * colors(k, :);
                % Each wedge comprises four patches and two surfaces.
                set( obj.WedgeGraphics(k, :), "FaceColor", colors(k, :) )
            end % for
            
        end % updateColors
        
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
    
end % class definition