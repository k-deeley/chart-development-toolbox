classdef ScatterBoxChart < Component
    %SCATTERBOXCHART Bivariate scatter plot with marginal boxplots.
    
    % Copyright 2018-2025 The MathWorks, Inc.
    
    properties ( Dependent )
        % Chart x-data.
        XData(:, 1) double {mustBeReal}
        % Chart y-data.
        YData(:, 1) double {mustBeReal}
    end % properties ( Dependent )
    
    properties ( Dependent )
        % Size data for the scatter series.
        ScatterSizeData(:, 1) double {mustBePositive, mustBeFinite}
        % Color data for the scatter series.
        ScatterCData(:, 3) double {mustBeInRange( ScatterCData, 0, 1 )}
        % Marker style for the scatter series.
        ScatterMarker(1, 1) string {mustBeMarker}
        % Filled marker state for the scatter series.
        FilledScatterMarkers(1, 1) matlab.lang.OnOffSwitchState
        % Variable size marker state for the scatter series.
        VariableSizeScatterMarkers(1, 1) matlab.lang.OnOffSwitchState
        % Axes x-grid.
        XGrid(1, 1) matlab.lang.OnOffSwitchState
        % Axes y-grid.
        YGrid(1, 1) matlab.lang.OnOffSwitchState
        % Visibility of the chart controls.
        Controls(1, 1) matlab.lang.OnOffSwitchState
    end % properties ( Dependent )
    
    properties ( Dependent )
        % Boxchart face color.
        BoxFaceColor
        % Boxchart whisker line style.
        WhiskerLineStyle(1, 1) string {mustBeLineStyle}
        % Boxchart whisker line color.
        WhiskerLineColor
        % Boxchart marker color.
        BoxMarkerColor
        % Boxchart marker size.
        BoxMarkerSize(1, 1) double {mustBePositive, mustBeFinite}
        % Boxchart marker.
        BoxMarker(1, 1) string {mustBeMarker}
        % Boxchart line width.
        BoxLineWidth(1, 1) double {mustBePositive, mustBeFinite}
    end % properties ( Dependent )
    
    properties ( Access = private )
        % Internal storage for the XData property.
        XData_(:, 1) double {mustBeReal} = 0
        % Internal storage for the XData property.
        YData_(:, 1) double {mustBeReal} = 0
        % Logical scalar specifying whether a computation is required.
        ComputationRequired(1, 1) logical = false
    end % properties ( Access = private )
    
    properties ( Access = private, Transient, NonCopyable )
        % Chart layout.
        LayoutGrid(:, 1) matlab.ui.container.GridLayout ...
            {mustBeScalarOrEmpty}
        % Tiled layout for the chart's axes.
        TiledLayout(:, 1) matlab.graphics.layout.TiledChartLayout ...
            {mustBeScalarOrEmpty}
        % Chart scatter series axes.
        ScatterAxes(:, 1) matlab.graphics.axis.Axes {mustBeScalarOrEmpty}
        % Toggle button for the chart controls.
        ToggleButton(:, 1) matlab.ui.controls.ToolbarStateButton ...
            {mustBeScalarOrEmpty}
        % Print button for the chart controls.
        PrintButton(:, 1) matlab.ui.controls.ToolbarPushButton ...
            {mustBeScalarOrEmpty}
        % Chart X-Chartbox axes.
        XBoxPlotAxes(:, 1) matlab.graphics.axis.Axes {mustBeScalarOrEmpty}
        % Chart Y-Chartbox axes.
        YBoxPlotAxes(:, 1) matlab.graphics.axis.Axes {mustBeScalarOrEmpty}        
        % Scatter series for the (x, y) data.
        ScatterSeries(:, 1) matlab.graphics.chart.primitive.Scatter ...
            {mustBeScalarOrEmpty}
        % Boxchart chart object for the marginal x-data.
        XBoxPlot(:, 1) matlab.graphics.chart.primitive.BoxChart ...
            {mustBeScalarOrEmpty}
        % Boxchart chart object for the marginal y-data.
        YBoxPlot(:, 1) matlab.graphics.chart.primitive.BoxChart ...
            {mustBeScalarOrEmpty}
        % Dropdown menu for selecting the scatter plot marker.
        ScatterMarkerDropDown(:, 1) matlab.ui.control.DropDown ...
            {mustBeScalarOrEmpty}
        % Check box for the filled scatter marker.
        FilledScatterMarkersCheckBox(:, 1) matlab.ui.control.CheckBox ...
            {mustBeScalarOrEmpty}
        % Slider for selecting the marker size of the scatter series.
        ScatterSizeDataSlider(:, 1) matlab.ui.control.Slider ...
            {mustBeScalarOrEmpty}
        % Check box for variable size scatter markers.
        ScatterSizeCheckBox(:, 1) matlab.ui.control.CheckBox ...
            {mustBeScalarOrEmpty}
        % Color picker for selecting the color of the scatter series.
        ScatterCDataColorPicker(:, 1) matlab.ui.control.ColorPicker ...
            {mustBeScalarOrEmpty}
        % Check boxes for the axes' XGrid and YGrid visibility.
        GridCheckBoxes(1, 2) matlab.ui.control.CheckBox
        % Color picker for selecting the box color.
        BoxFaceColorPicker(:, 1) matlab.ui.control.ColorPicker ...
            {mustBeScalarOrEmpty}
        % Dropdown menu for selecting the whisker line style.
        WhiskerLineStyleDropDown(:, 1) matlab.ui.control.DropDown ...
            {mustBeScalarOrEmpty}
        % Color picker for selecting the whisker line color.
        WhiskerLineColorPicker(:, 1) matlab.ui.control.ColorPicker ...
            {mustBeScalarOrEmpty}
        % Spinner for selecting the boxcharts' line width.
        WhiskerLineWidthSpinner(:, 1) matlab.ui.control.Spinner ...
            {mustBeScalarOrEmpty}
        % Dropdown menu for selecting the boxcharts' marker.
        BoxMarkerStyleDropDown(:, 1) matlab.ui.control.DropDown ...
            {mustBeScalarOrEmpty}
        % Slider for selecting the boxcharts' marker size.
        BoxMarkerSizeSlider(:, 1) matlab.ui.control.Slider ...
            {mustBeScalarOrEmpty}
        % Color picker for selecting the boxcharts' marker color.
        BoxMarkerColorPicker(:, 1) matlab.ui.control.ColorPicker ...
            {mustBeScalarOrEmpty}
    end % properties ( Access = private, Transient, NonCopyable )
    
    properties ( Constant, Hidden )
        % Product dependencies.
        Dependencies(1, :) string = ["MATLAB", ...
            "Statistics and Machine Learning Toolbox"]
        % Description.
        ShortDescription(1, 1) string = "Bivariate scatter plot with" + ...
            " marginal boxplots"
    end % properties ( Constant, Hidden )
    
    methods
        
        function value = get.XData( obj )
            
            value = obj.XData_;
            
        end % get.XData
        
        function set.XData( obj, value )
            
            % Mark the chart for an update.
            obj.ComputationRequired = true;
            
            % Decide how to modify the chart data.
            nX = numel( value );
            nY = numel( obj.YData );
            
            if nX < nY % if the new XData is shorter
                % truncate YData_
                obj.YData_ = obj.YData_(1:nX);
            else % if the new YData is shorter
                % pad YData_
                obj.YData_(end+1:nX, 1) = NaN;
            end %if
            
            % Update the internal x-data.
            obj.XData_ = value;
            
            % Reset the scatter series' color and size data if necessary.
            nC = size( obj.ScatterCData, 1 );
            if nC > 1 && nX ~= nC
                obj.ScatterCData = [0, 0.447, 0.741];
            end % if
            
            nS = numel( obj.ScatterSizeData );
            if nS > 1 && nX ~= nS
                obj.ScatterSizeData = 36;
            end % if
            
        end % set.XData
        
        function value = get.YData( obj )
            
            value = obj.YData_;
            
        end % get.YData
        
        function set.YData( obj, value )
            
            % Mark the chart for an update.
            obj.ComputationRequired = true;
            
            % Decide how to modify the chart data
            nX = numel( obj.XData );
            nY = numel( value );
            
            if nY < nX % if the new YData is shorter
                % truncate XData_
                obj.XData_ = obj.XData_(1:nY);
            else % if the new XData is shorter
                % pad XData_
                obj.XData_(end+1:nY, 1) = NaN;
            end % if
            
            % Update the internal y-data.
            obj.YData_ = value;
            
            % Reset the scatter series' color and size data if necessary.
            nC = size( obj.ScatterCData, 1 );
            if nC > 1 && nY ~= nC
                obj.ScatterCData = [0, 0.447, 0.741];
            end % if
            
            nS = numel( obj.ScatterSizeData );
            if nS > 1 && nY ~= nS
                obj.ScatterSizeData = 36;
            end % if
            
        end % set.YData
        
        function value = get.ScatterMarker( obj )
            
            value = obj.ScatterSeries.Marker;
            
        end % get.ScatterMarker
        
        function set.ScatterMarker( obj, value )
            
            % Update the property.
            obj.ScatterSeries.Marker = value;
            
            % Update the dropdown menu.
            obj.ScatterMarkerDropDown.Value = value;
            
            % Decide whether to fill the marker.
            if obj.FilledScatterMarkersCheckBox.Value
                obj.ScatterSeries.MarkerFaceColor = ...
                    obj.ScatterSeries.MarkerEdgeColor;
            else
                obj.ScatterSeries.MarkerFaceColor = "none";
            end % if
            
        end % set.ScatterMarker
        
        function value = get.FilledScatterMarkers( obj )
            
            value = obj.FilledScatterMarkersCheckBox.Value;
            
        end % get.FilledScatterMarkers
        
        function set.FilledScatterMarkers( obj, value )
            
            % Update the check box status.
            obj.FilledScatterMarkersCheckBox.Value = value;
            
            % Decide whether to fill the marker.
            if obj.FilledScatterMarkersCheckBox.Value
                obj.ScatterSeries.MarkerFaceColor = ...
                    obj.ScatterSeries.MarkerEdgeColor;
            else
                obj.ScatterSeries.MarkerFaceColor = "none";
            end % if
            
        end % set.FilledScatterMarkers
        
        function value = get.ScatterCData( obj )
            
            value = obj.ScatterSeries.CData;
            
        end % get.ScatterCData
        
        function set.ScatterCData( obj, value )
            
            % Update the color selection button.
            value = validatecolor( value, "multiple" );
            if height( value ) == 1                
                obj.ScatterCDataColorPicker.Enable = "on";
                obj.ScatterCDataColorPicker.Value = value;                
            else
                obj.ScatterCDataColorPicker.Enable = "off";                
            end % if
            
            % Update the scatter series.
            obj.ScatterSeries.CData = value;
            
        end % set.ScatterCData
        
        function value = get.ScatterSizeData( obj )
            
            value = obj.ScatterSeries.SizeData;
            
        end % get.ScatterSizeData
        
        function set.ScatterSizeData( obj, value )
            
            % Update the position on the slider.
            if isscalar( value )
                obj.ScatterSizeDataSlider.Enable = true;
                sliderVal = min( 600, value );
                set( obj.ScatterSizeDataSlider, "Value", sliderVal, ...
                    "Tooltip", string( sliderVal ) )
                obj.ScatterSizeCheckBox.Value = false;
            else
                obj.ScatterSizeDataSlider.Enable = false;
                obj.ScatterSizeCheckBox.Value = true;
            end % if
            
            % Update the scatter series.
            obj.ScatterSeries.SizeData = value;
            
        end % set.ScatterSizeData
        
        function value = get.VariableSizeScatterMarkers( obj )
            
            value = obj.ScatterSizeCheckBox.Value;
            
        end % get.VariableSizeScatterMarkers
        
        function set.VariableSizeScatterMarkers( obj, value )
            
            if value
                % Set the property.
                obj.ScatterSizeDataSlider.Enable = false;
                % Update the checkbox.
                obj.ScatterSizeCheckBox.Value = true;
            else
                % Set the property.
                obj.ScatterSizeDataSlider.Enable = true;
                % Update the checkbox.
                obj.ScatterSizeCheckBox.Value = false;
            end % if
            
        end % set.VariableSizeScatterMarkers
        
        function value = get.BoxFaceColor( obj )
            
            value = obj.XBoxPlot.BoxFaceColor;
            
        end % get.BoxFaceColor
        
        function set.BoxFaceColor( obj, value )
            
            % Update the color selection button.
            value = validatecolor( value );            
            obj.BoxFaceColorPicker.Value = value;
            
            % Update the boxcharts.
            obj.XBoxPlot.BoxFaceColor = value;
            obj.YBoxPlot.BoxFaceColor = value;
            
        end % set.BoxFaceColor
        
        function value = get.BoxMarkerColor( obj )
            
            value = obj.XBoxPlot.MarkerColor;
            
        end % get.BoxMarkerColor
        
        function set.BoxMarkerColor( obj, value )
            
            % Update the color picker.
            value = validatecolor( value );
            obj.BoxMarkerColorPicker.Value = value;
            
            % Update the boxcharts.
            set( [obj.XBoxPlot, obj.YBoxPlot], "MarkerColor", value )
            
        end % set.BoxMarkerColor
        
        function value = get.BoxMarker( obj )
            
            value = obj.XBoxPlot.MarkerStyle;
            
        end % get.BoxMarkerStyle
        
        function set.BoxMarker( obj, value )
            
            % Update the dropdown menu.
            obj.BoxMarkerStyleDropDown.Value = value;
            
            % Update the boxcharts.
            set( [obj.XBoxPlot, obj.YBoxPlot], "MarkerStyle", value )
            
        end % set.BoxMarkerStyle
        
        function value = get.BoxMarkerSize( obj )
            
            value = obj.XBoxPlot.MarkerSize;
            
        end % get.BoxMarkerSize
        
        function set.BoxMarkerSize( obj, value )
            
            % Update the slider.
            obj.BoxMarkerSizeSlider.Value = min( 30, value );
            
            % Update the boxcharts.
            set( [obj.XBoxPlot, obj.YBoxPlot], "MarkerSize", value )
            
        end % set.BoxMarkerSize
        
        function value = get.WhiskerLineColor( obj )
            
            value = obj.XBoxPlot.WhiskerLineColor;
            
        end % get.WhiskerLineColor
        
        function set.WhiskerLineColor( obj, value )
            
            % Update the color selection button.
            value = validatecolor( value );            
            obj.WhiskerLineColorPicker.Value = value;
            
            % Update the boxcharts.
            set( [obj.XBoxPlot, obj.YBoxPlot], "WhiskerLineColor", value )
            
        end % set.WhiskerLineColor
        
        function value = get.BoxLineWidth( obj )
            
            value = obj.XBoxPlot.LineWidth;
            
        end % get.BoxLineWidth
        
        function set.BoxLineWidth( obj, value )
            
            % Update the spinner.
            obj.WhiskerLineWidthSpinner.Value = value;
            
            % Update the boxcharts.
            set( [obj.XBoxPlot, obj.YBoxPlot], "LineWidth", value )
            
        end % set.BoxLineWidth
        
        function value = get.WhiskerLineStyle( obj )
            
            value = obj.XBoxPlot.WhiskerLineStyle;
            
        end % get.WhiskerLineStyle
        
        function set.WhiskerLineStyle( obj, value )
            
            % Update the dropdown menu.
            obj.WhiskerLineStyleDropDown.Value = value;
            
            % Update the boxcharts.
            set( [obj.XBoxPlot, obj.YBoxPlot], "WhiskerLineStyle", value )
            
        end % set.WhiskerLineStyle
        
        function value = get.XGrid( obj )
            
            value = obj.ScatterAxes.XGrid;
            
        end % set.XGrid
        
        function set.XGrid( obj, value )
            
            % Update the axes.
            obj.ScatterAxes.XGrid = value;
            
            % Update the checkbox.
            obj.GridCheckBoxes(1).Value = value;
            
        end % set.XGrid
        
        function value = get.YGrid( obj )
            
            value = obj.ScatterAxes.YGrid;
            
        end % get.YGrid
        
        function set.YGrid( obj, value )
            
            % Update the axes.
            obj.ScatterAxes.YGrid = value;
            
            % Update the checkbox.
            obj.GridCheckBoxes(2).Value = value;
            
        end % set.YGrid
        
        function value = get.Controls( obj )
            
            value = obj.ToggleButton.Value;
            
        end % get.Controls
        
        function set.Controls( obj, value )
            
            % Update the toggle button.
            obj.ToggleButton.Value = value;
            
            % Invoke the toggle button callback.
            obj.onToggleButtonPressed()
            
        end % set.Controls
        
    end % methods
    
    methods

        function obj = ScatterBoxChart( namedArgs )
            %SCATTERBOXCHART Construct a ScatterBoxChart, given optional 
            %name-value arguments.

            arguments ( Input )
                namedArgs.?ScatterBoxChart
            end % arguments ( Input )            

            % Set any user-defined properties.
            set( obj, namedArgs )

        end % constructor
        
        function varargout = xlabel( obj, varargin )
            
            [varargout{1:nargout}] = ...
                xlabel( obj.ScatterAxes, varargin{:} );
            
        end % xlabel
        
        function varargout = ylabel( obj, varargin )
            
            [varargout{1:nargout}] = ...
                ylabel( obj.ScatterAxes, varargin{:} );
            
        end % ylabel
        
        function varargout = title( obj, varargin )
            
            [varargout{1:nargout}] = title( obj.ScatterAxes, varargin{:} );
            
        end % title
        
        function varargout = legend( obj, varargin )
            
            [varargout{1:nargout}] = ...
                legend( obj.ScatterAxes, varargin{:} );
            
        end % legend
        
        function grid( obj, varargin )
            
            % Invoke grid on the axes.
            grid( obj.ScatterAxes, varargin{:} );
            
            % Ensure the controls are up-to-date. This can be done by
            % setting the XGrid/YGrid chart properties, which in turn will
            % refresh the controls.
            obj.XGrid = obj.ScatterAxes.XGrid;
            obj.YGrid = obj.ScatterAxes.YGrid;
            
        end % grid

        function varargout = axis( obj, varargin )

            [varargout{1:nargout}] = axis( obj.ScatterAxes, varargin{:} );

        end % axis

        function exportgraphics( obj, varargin )

            exportgraphics( obj.TiledLayout, varargin{:} )

        end % exportgraphics
        
    end % methods
    
    methods ( Access = protected )
        
        function setup( obj )
            %SETUP Initialize the chart graphics.
            
            % Define the layout grid.
            obj.LayoutGrid = uigridlayout( obj, [1, 2], ...
                "ColumnWidth", ["1x", "0x"] );
            
            % Define a tiled layout for the chart's axes.
            p = uipanel( "Parent", obj.LayoutGrid, ...
                "BorderType", "none" );
            n = 7;
            obj.TiledLayout = tiledlayout( p, n, n, ...
                "TileSpacing", "compact", ...
                "Padding", "compact" );
            
            % Create the three chart axes.
            obj.YBoxPlotAxes = nexttile( obj.TiledLayout, 1, [n-1, 1] );
            obj.ScatterAxes = nexttile( obj.TiledLayout, 2, [n-1, n-1] );
            obj.XBoxPlotAxes = nexttile( obj.TiledLayout, ...
                n^2-n+2, [1, n-1] );
            
            % Customize the chart axes.
            set( obj.XBoxPlotAxes, ...
                "Color", "none" , ...
                "XTick", [], ...
                "XColor", "none", ...
                "YTick", [], ...
                "YColor", "none", ...
                "Interactions", dataTipInteraction() );
            set( obj.YBoxPlotAxes, ...
                "Color", "none", ...
                "XTick", [], ...
                "XColor", "none", ...
                "YTick", [], ...
                "YColor", "none", ...
                "Interactions", dataTipInteraction() );
            
            % Respond to changes in the main axes' limits.
            obj.ScatterAxes.XAxis.LimitsChangedFcn = @obj.onXLimChanged;
            obj.ScatterAxes.YAxis.LimitsChangedFcn = @obj.onYLimChanged;
            
            % Disable the toolbar visibility on the boxchart axes.
            set( obj.XBoxPlotAxes.Toolbar, "Visible", "off" )
            set( obj.YBoxPlotAxes.Toolbar, "Visible", "off" )
            
            % Create the scatter series.
            hold( obj.ScatterAxes, "on" )
            obj.ScatterSeries = scatter( obj.ScatterAxes, ...
                NaN, NaN, ".", ...
                "CData", obj.ScatterAxes.ColorOrder(1, :), ...
                "DisplayName", "Data" );
            hold( obj.ScatterAxes, "off" )
            
            % Annotate the axes.
            xlabel( obj.ScatterAxes, "x" )
            ylabel( obj.ScatterAxes, "y" )
            title( obj.ScatterAxes, "Scatter Boxplot" )
            legend( obj.ScatterAxes )
            
            % Create the x-boxchart.
            hold( obj.XBoxPlotAxes, "on" )
            obj.XBoxPlot = boxchart( obj.XBoxPlotAxes, 0, 0, ... 
                "Orientation", "horizontal" );
            hold( obj.XBoxPlotAxes, "off" )
            
            % Create the y-boxchart.
            hold( obj.YBoxPlotAxes, "on" )
            obj.YBoxPlot = boxchart( obj.YBoxPlotAxes, 0, 0, ...                
                "Orientation", "vertical" );
            hold( obj.YBoxPlotAxes, "off" )
            
            % Add a state button to show/hide the chart's controls.
            tb = axtoolbar( obj.ScatterAxes, ...
                ["datacursor", "zoomin", "zoomout", "restoreview"] );
            iconPath = fullfile( chartsRoot(), "charts", "images", ...
                "Cog.png" );
            obj.ToggleButton = axtoolbarbtn( tb, "state", ...
                "Value", "off", ...
                "Tooltip", "Show chart controls", ...
                "Icon", iconPath, ...
                "ValueChangedFcn", @obj.onToggleButtonPressed );
            
            % Add a push button to save the chart.
            iconPath = fullfile( chartsRoot(), "charts", "images", ...
                "Print.png" );
            obj.PrintButton = axtoolbarbtn( tb, "push", ...
                "Tooltip", "Save", ...
                "Icon", iconPath, ...
                "ButtonPushedFcn", @obj.onExport );
            
            % Create the main control panel.
            p = uipanel( "Parent", obj.LayoutGrid, ...
                "Title", "Chart Controls", ...
                "FontWeight", "bold" );
            vLayout = uigridlayout( p, [2, 1], ...
                "RowHeight", ["fit", "fit"] );
            
            % Add the chart controls for the scatter plot.
            p = uipanel( "Parent", vLayout, ...
                "Title", "Joint Density Scatter Plot", ...
                "FontWeight", "bold" );
            controlLayout = uigridlayout( p, [6, 2], ...
                "RowHeight", repmat( "fit", 1, 6 ), ...
                "ColumnWidth", ["fit", "fit"] );
            
            % Scatter series marker type selector.
            uilabel( "Parent", controlLayout, "Text", "Marker:" );
            obj.ScatterMarkerDropDown = uidropdown( ...
                "Parent", controlLayout, ...
                "Items", set( obj.ScatterSeries, "Marker" ), ...
                "Tooltip", "Select the marker for the scatter plot", ...
                "Value", obj.ScatterSeries.Marker, ...
                "ValueChangedFcn", @obj.onScatterMarkerSelected );
            
            % Check box for the scatter series filled marker state.
            obj.FilledScatterMarkersCheckBox = uicheckbox( ...
                "Parent", controlLayout, ...
                "Value", false, ...
                "Text", "Filled markers", ...
                "Tooltip", "Enable/disable filled markers", ...
                "ValueChangedFcn", @obj.onFilledScatterMarkersSelected );
            obj.FilledScatterMarkersCheckBox.Layout.Column = 2;
            
            % Scatter series marker size selector.
            uilabel( "Parent", controlLayout, ...
                "Text", "Marker size:" );
            obj.ScatterSizeDataSlider = uislider( ...
                "Parent", controlLayout, ...
                "Value", 36, ...
                "Tooltip", "36", ...
                "Limits", [1, 600], ...
                "MajorTicks", [1, 200, 400, 600], ...
                "MajorTickLabels", ["1", "200", "400", "600"], ...
                "ValueChangedFcn", @obj.onMarkerSizeSelected );
            
            % Check boxes for the multi sizes.
            obj.ScatterSizeCheckBox = uicheckbox( ...
                "Parent", controlLayout, ...
                "Value", false, ...
                "Text", "Variable size markers", ...
                "Tooltip", "Enable/disable variable size markers", ...
                "ValueChangedFcn", ...
                @obj.onVariableSizeScatterMarkersSelected );
            obj.ScatterSizeCheckBox.Layout.Column = 2;
            
            % Scatter series marker color selector.
            uilabel( "Parent", controlLayout, "Text", "Marker color:" );            
            obj.ScatterCDataColorPicker = uicolorpicker( ...
                "Parent", controlLayout, ...
                "Tooltip", ...
                "Select the marker color for the scatter plot", ...
                "Value", obj.ScatterCData, ...
                "ValueChangedFcn", @obj.onScatterCDataColorPicked );
            
            % Check boxes for the gridlines.
            obj.GridCheckBoxes(1) = uicheckbox( ...
                "Parent", controlLayout, ...
                "Value", matlab.lang.OnOffSwitchState( obj.XGrid ), ...
                "Tag", "X", ...
                "Text", "Show x-gridlines", ...
                "Tooltip", "Toggle the vertical axes gridlines", ...
                "ValueChangedFcn", @obj.onGridSelected );
            obj.GridCheckBoxes(2) = uicheckbox( ...
                "Parent", controlLayout, ...
                "Value", matlab.lang.OnOffSwitchState( obj.YGrid ), ...
                "Tag", "Y", ...
                "Text", "Show y-gridlines", ...
                "Tooltip", "Toggle the horizontal axes gridlines", ...
                "ValueChangedFcn", @obj.onGridSelected );
            
            % Add chart controls for the boxchart axes.
            p = uipanel( "Parent", vLayout, ...
                "Title", "Marginal Boxcharts", ...
                "FontWeight", "bold" );
            controlLayout = uigridlayout( p, [7, 2], ...
                "RowHeight", repmat( "fit", 1, 7 ), ...
                "ColumnWidth", ["fit", "fit"] );
            
            % Boxchart box color selector.
            uilabel( "Parent", controlLayout, ...
                "Text", "Box color:" );
            obj.BoxFaceColorPicker = uicolorpicker( ...
                "Parent", controlLayout, ...
                "Tooltip", "Select the box face color", ...
                "Value", obj.BoxFaceColor, ...
                "ValueChangedFcn", @obj.onBoxFaceColorPicked );
            
            % Boxchart whisker line style selector.
            uilabel( "Parent", controlLayout, ...
                "Text", "Whisker line style:" );
            obj.WhiskerLineStyleDropDown = uidropdown( ...
                "Parent", controlLayout, ...
                "Items", set( obj.XBoxPlot, "WhiskerLineStyle" ), ...
                "Tooltip", "Select the whisker line style", ...
                "Value", obj.XBoxPlot.WhiskerLineStyle, ...
                "ValueChangedFcn", @obj.onWhiskerLineStyleSelected );
            
            % Boxchart whisker line color selector.
            uilabel( "Parent", controlLayout, ...
                "Text", "Whisker line color:" );            
            obj.WhiskerLineColorPicker = uicolorpicker( ...
                "Parent", controlLayout, ...                
                "Tooltip", "Select the color of the box", ...
                "Value", obj.WhiskerLineColor, ...
                "ValueChangedFcn", @obj.onWhiskerLineColorPicked );
            
            % Boxchart whisker line width selector.
            uilabel( "Parent", controlLayout, ...
                "Text", "Line width:" );
            obj.WhiskerLineWidthSpinner = uispinner( ...
                "Parent", controlLayout, ...
                "Limits", [0, Inf], ...
                "LowerLimitInclusive", "off", ...
                "Step", 0.5, ...
                "Tooltip", "Select the boxchart linewidth", ...
                "Value", obj.XBoxPlot.LineWidth, ...
                "ValueDisplayFormat", "%.1f", ...
                "ValueChangedFcn", @obj.onWhiskerLineWidthSelected );
            
            % Boxchart marker style selector.
            uilabel( "Parent", controlLayout, "Text", "Marker style:" );
            obj.BoxMarkerStyleDropDown = uidropdown( ...
                "Parent", controlLayout, ...
                "Items", set( obj.XBoxPlot, "MarkerStyle" ), ...
                "Tooltip", "Select the scatter plot marker", ...
                "Value", obj.ScatterSeries.Marker, ...
                "ValueChangedFcn", @obj.onBoxMarkerSelected );
            
            % Boxchart marker size slider
            uilabel( "Parent", controlLayout, "Text", "Marker size:" );
            obj.BoxMarkerSizeSlider = uislider( ...
                "Parent", controlLayout, ...
                "Value", obj.XBoxPlot.MarkerSize, ...
                "Tooltip", string( obj.XBoxPlot.MarkerSize ), ...
                "Limits", [1, 30], ...
                "MajorTicks", [1, 10, 20, 30], ...
                "ValueChangedFcn", @obj.onBoxMarkerSizeSelected );
            
            % Boxchart marker color selector.
            uilabel( "Parent", controlLayout, ...
                "Text", "Marker color:" );
            obj.BoxMarkerColorPicker = uicolorpicker( ...
                "Parent", controlLayout, ...                
                "Tooltip", "Select the color of the boxchart marker", ...               
                "Value", [0, 0.447, 0.741], ...
                "ValueChangedFcn", @obj.onBoxMarkerColorPicked );
            
        end % setup
        
        function update ( obj )
            % UPDATE Refresh the chart graphics.
            
            if obj.ComputationRequired
                
                % Update the scatter series with the new data.
                set(obj.ScatterSeries, "XData", obj.XData_, ...
                    "YData", obj.YData_);
                
                % Update the x-boxchart with the new data.
                nx = numel( obj.XData_ );
                set( obj.XBoxPlot, ...
                    "XData", categorical( ones( nx, 1 ) ), ...
                    "YData", obj.XData_ )
                
                % Update the y-boxchart with the new data.
                ny = numel( obj.YData_ );
                set( obj.YBoxPlot, ...
                    "XData", categorical( ones( ny, 1 ) ), ...
                    "YData", obj.YData_ )
                
                % Mark the chart clean.
                obj.ComputationRequired = false;
                
            end % if
            
        end % update
        
    end % methods ( Access = protected )
    
    methods ( Access = private )
        
        function onToggleButtonPressed( obj, ~, ~ )
            % ONTOGGLEBUTTONPRESSED Hide/show the chart controls.
            
            % Check the current state.
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
        
        function onExport( obj, ~, ~ )
            %ONEXPORT Export the chart graphics.
            
            % Save the chart axes as an image file.
            filter = ["*.jpg"; "*.png"; "*.tif"; "*.pdf"; "*.eps"];
            [filename, filepath] = uiputfile( filter );
            f = ancestor( obj, "figure" );
            figure( f ) % Restore focus
            if ~isequal( filename, 0 )
                try
                    exportName = fullfile( filepath, filename );
                    exportgraphics( obj.TiledLayout, exportName )
                catch
                    uialert( f, "Unable to export graphics.", ...
                        "ScatterBoxplot: Export Error" )
                end % try/catch
            end % if
            
        end % onExport
        
        function onScatterMarkerSelected( obj, s, ~ )
            %ONSCATTERMARKERSELECTED Update the chart when the scatter plot
            %marker style is selected interactively.
            
            obj.ScatterSeries.Marker = s.Value;
            
        end % onScatterMarkerSelected
        
        function onFilledScatterMarkersSelected( obj, s, ~ )
            %ONFILLEDSCATTERMARKERSSELECTED Enable/disble filled markers.
            
            filled = s.Value;
            if filled
                obj.ScatterSeries.MarkerFaceColor = ...
                    obj.ScatterSeries.MarkerEdgeColor;
            else
                obj.ScatterSeries.MarkerFaceColor = "none";
            end % if
            
        end % onScatterFilledState
        
        function onMarkerSizeSelected( obj, s, ~ )
            %ONMARKERSIZESELECTED Update the marker size when the user
            %interacts with the slider.
            
            obj.ScatterSizeData = s.Value;
            
        end % onMarkerSizeSelected
        
        function onVariableSizeScatterMarkersSelected( obj, s, ~ )
            %ONVARIABLESIZESCATTERMARKERSSELECTED Enable/disable variable
            %size scatter plot markers.
            
            checked = s.Value;
            if checked
                obj.ScatterSizeDataSlider.Enable = "off";
            else
                obj.ScatterSizeDataSlider.Enable = "on";
                obj.ScatterSizeData = obj.ScatterSizeDataSlider.Value;
            end % if
            
        end % onVariableSizeScatterMarkersSelected
        
        function onScatterCDataColorPicked( obj, ~, ~ )
            %ONSCATTERCDATACOLORPICKED Allow the user to select a new 
            %marker color for the scatter series.
            
            % Update the marker's color.
            obj.ScatterCData = obj.ScatterCDataColorPicker.Value;
            
        end % onScatterCDataColorPicked
        
        function onBoxFaceColorPicked( obj, ~, ~ )
            %ONBOXFACECOLORPICKED Allow the user to select a new color for 
            %the boxcharts' boxes.

            % Update the box colors.
            set( [obj.XBoxPlot, obj.YBoxPlot], ...
                "BoxFaceColor", obj.BoxFaceColorPicker.Value )
            
        end % onBoxFaceColorPicked
        
        function onWhiskerLineColorPicked( obj, ~, ~ )
            %ONWHISKERLINECOLORPICKED Allow the user to select a new line 
            %color for boxcharts' whisker lines.

            % Update the boxes' color.
            set( [obj.XBoxPlot, obj.YBoxPlot], ...
                "WhiskerLineColor", obj.WhiskerLineColorPicker.Value )
            
        end % onWhiskerLineColorPicked
        
        function onWhiskerLineStyleSelected( obj, s, ~ )
            %ONWHISKERLINESTYLESELECTED Update the chart when the style of
            %the boxcharts' whisker line is selected interactively.
            
            set( [obj.XBoxPlot, obj.YBoxPlot], ...
                "WhiskerLineStyle", s.Value )
            
        end % onWhiskerLineStyleSelected
        
        function onWhiskerLineWidthSelected( obj, s, ~ )
            %ONWHISKERLINEWIDTHSELECTED Update the chart when the width of
            %the boxcharts' lines is selected interactively.
            
            set( [obj.XBoxPlot, obj.YBoxPlot], "LineWidth", s.Value )
            
        end % onWhiskerLineWidthSelected
        
        function onBoxMarkerSelected( obj, s, ~ )
            %ONBOXMARKERSELECTED Update the chart when the marker style of
            %the boxchart is selected interactively.
            
            set( [obj.XBoxPlot, obj.YBoxPlot], "MarkerStyle", s.Value )
            
        end % onBoxMarkerSelected
        
        function onBoxMarkerColorPicked( obj, ~, ~ )
            %ONBOXMARKERCOLORPICKED Allow the user to select a new color 
            %for the boxcharts' markers.

            % Update the boxcharts' marker color.
            set( [obj.XBoxPlot, obj.YBoxPlot], ...
                "MarkerColor", obj.BoxMarkerColorPicker.Value )

        end % onBoxMarkerColorPicked
        
        function onBoxMarkerSizeSelected( obj, s, ~ )
            %ONBOXMARKERSIZESELECTED Update the boxcharts' marker size
            %interactively.
            
            set( [obj.XBoxPlot, obj.YBoxPlot], "MarkerSize", s.Value )
            obj.BoxMarkerSizeSlider.Tooltip = string( s.Value );
            
        end % onBoxMarkerSizeSelected
        
        function onGridSelected( obj, s, ~ )
            %ONGRIDSELECTED Toggle the x/y grid lines.
            
            gridProp = s.Tag + "Grid";
            obj.ScatterAxes.(gridProp) = s.Value;
            
        end % onGridSelected
        
        function onXLimChanged( obj, ~, ~ )
            %ONXLIMCHANGED Synchronize the x-boxchart's axes with the main
            %axes.
            
            obj.XBoxPlotAxes.XLim = obj.ScatterAxes.XLim;
            
        end % onXLimChanged
        
        function onYLimChanged( obj, ~, ~ )
            %ONYLIMCHANGED Synchronize the y-boxchart's axes with the main
            %axes.
            
            obj.YBoxPlotAxes.YLim = obj.ScatterAxes.YLim;
            
        end % onYLimChanged
        
    end % methods ( Access = private )
    
end % classdef