classdef ScatterBoxplot < matlab.ui.componentcontainer.ComponentContainer
    %SCATTERBOXPLOT Chart managing a bivariate scatter plot and its
    %marginal boxplots.
    %
    % Copyright 2018-2021 The MathWorks, Inc.
    
    properties ( Dependent )
        % Chart x-data.
        XData(:, 1) double {mustBeReal, mustBeFinite}
        % Chart y-data.
        YData(:, 1) double {mustBeReal, mustBeFinite}
    end % properties ( Dependent )
    
    properties ( Dependent )
        % Size data for the scatter series.
        ScatterSizeData
        % Color data for the scatter series.
        ScatterCData
        % Marker style for the scatter series.
        ScatterMarker
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
        WhiskerLineStyle
        % Boxchart whisker line color.
        WhiskerLineColor
        % Boxchart marker color.
        BoxMarkerColor
        % Boxchart marker size.
        BoxMarkerSize
        % Boxchart marker.
        BoxMarkerStyle
        % Boxchart line width.
        BoxLineWidth
    end % properties ( Dependent )
    
    properties ( Access = private )
        % Internal storage for the XData property.
        XData_ = 0
        % Internal storage for the XData property.
        YData_ = 0
        % Logical scalar specifying whether a computation is required.
        ComputationRequired = false()
    end % properties ( Access = private )
    
    properties ( Access = private, Transient, NonCopyable )
        % Chart layout.
        LayoutGrid(1, 1) matlab.ui.container.GridLayout
        % Tiled layout for the chart's axes.
        TiledLayout(1, 1) matlab.graphics.layout.TiledChartLayout
        % Chart scatter series axes.
        ScatterAxes(1, 1) matlab.graphics.axis.Axes
        % Toggle button for the chart controls.
        ToggleButton(1, 1) matlab.ui.controls.ToolbarStateButton
        % Print button for the chart controls.
        PrintButton(1, 1) matlab.ui.controls.ToolbarPushButton
        % Chart X-Chartbox axes.
        XBoxPlotAxes(1, 1) matlab.graphics.axis.Axes
        % Chart Y-Chartbox axes.
        YBoxPlotAxes(1, 1) matlab.graphics.axis.Axes
        % Listener for the PostSet event on the XLim axes property.
        XLimChangedListener event.proplistener
        % Listener for the PostSet event on the YLim axes property.
        YLimChangedListener event.proplistener
        % Scatter series for the (x, y) data.
        ScatterSeries(1, 1) matlab.graphics.chart.primitive.Scatter
        % Boxchart chart object for the marginal x-data.
        XBoxPlot(1, 1) matlab.graphics.chart.primitive.BoxChart
        % Boxchart chart object for the marginal y-data.
        YBoxPlot(1, 1) matlab.graphics.chart.primitive.BoxChart
        % Dropdown menu for selecting the scatter plot marker.
        ScatterMarkerDropDown(1, 1) matlab.ui.control.DropDown
        % Check box for the filled scatter marker.
        FilledScatterMarkersCheckBox(1, 1) matlab.ui.control.CheckBox
        % Slider for selecting the marker size of the scatter series.
        ScatterSizeDataSlider(1, 1) matlab.ui.control.Slider
        % Check box for variable size scatter markers.
        ScatterSizeCheckBox(1, 1) matlab.ui.control.CheckBox
        % Pushbutton for selecting the color of the scatter series.
        ScatterCDataButton(1, 1) matlab.ui.control.Button
        % Check boxes for the axes' XGrid and YGrid visibility.
        GridCheckBoxes(1, 2) matlab.ui.control.CheckBox
        % Pushbutton for selecting the box color.
        BoxFaceColorButton(1, 1) matlab.ui.control.Button
        % Dropdown menu for selecting the whisker line style.
        WhiskerLineStyleDropDown(1, 1) matlab.ui.control.DropDown
        % Pushbutton for selecting the whisker line color.
        WhiskerLineColorButton(1, 1) matlab.ui.control.Button
        % Spinner for selecting the boxcharts' line width.
        WhiskerLineWidthSpinner(1, 1) matlab.ui.control.Spinner
        % Dropdown menu for selecting the boxcharts' marker.
        BoxMarkerStyleDropDown(1, 1) matlab.ui.control.DropDown
        % Slider for selecting the boxcharts' marker size.
        BoxMarkerSizeSlider(1, 1) matlab.ui.control.Slider
        % Pushbutton for selecting the boxcharts' marker color.
        BoxMarkerColorButton(1, 1) matlab.ui.control.Button
    end % properties ( Access= private, Transient, NonCopyable )
    
    properties ( Constant, Hidden )
        % Product dependencies.
        Dependencies = ["MATLAB", ...
            "Statistics and Machine Learning Toolbox"]
    end % properties ( Constant, Hidden )
    
    methods
        
        function value = get.XData( obj )
            
            value = obj.XData_;
            
        end % get.XData
        
        function set.XData( obj, value )
            
            % Mark the chart for an update.
            obj.ComputationRequired = true();
            
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
            obj.ComputationRequired = true();
            
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
            
            % Deal with the "none" option.
            assert( ~isequal( value, "none" ), ...
                "ScatterBoxplot:UnsupportedScatterColor", ...
                "The 'none' color option is not supported." )
            
            % Update the color selection button.
            value = validatecolor( value, "multiple" );
            if size( value, 1 ) == 1
                colorData = reshape( value, [1, 1, 3] );
                obj.ScatterCDataButton.Icon = ...
                    repmat( colorData, [15, 15] );
                obj.ScatterCDataButton.Text = "";
            else
                obj.ScatterCDataButton.Icon = "";
                obj.ScatterCDataButton.Text = "Variable color";
            end % if
            
            % Update the scatter series.
            obj.ScatterSeries.CData = value;
            
        end % set.ScatterCData
        
        function value = get.ScatterSizeData( obj )
            
            value = obj.ScatterSeries.SizeData;
            
        end % get.ScatterSizeData
        
        function set.ScatterSizeData( obj, value )
            
            % Update the position on the slider.
            if length( value ) == 1
                obj.ScatterSizeDataSlider.Enable = true();
                sliderVal = min( 600, value );
                set( obj.ScatterSizeDataSlider, "Value", sliderVal, ...
                    "Tooltip", string( sliderVal ) )
                obj.ScatterSizeCheckBox.Value = false();
            else
                obj.ScatterSizeDataSlider.Enable = false();
                obj.ScatterSizeCheckBox.Value = true();
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
                obj.ScatterSizeDataSlider.Enable = false();
                % Update the checkbox.
                obj.ScatterSizeCheckBox.Value = true;
            else
                % Set the property.
                obj.ScatterSizeDataSlider.Enable = true();
                % Update the checkbox.
                obj.ScatterSizeCheckBox.Value = false();
            end % if
            
        end % set.VariableSizeScatterMarkers
        
        function value = get.BoxFaceColor( obj )
            
            value = obj.XBoxPlot.BoxFaceColor;
            
        end % get.BoxFaceColor
        
        function set.BoxFaceColor( obj, value )
            
            % Deal with the "none" option.
            assert( ~isequal( value, "none" ), ...
                "ScatterBoxplot:UnsupportedBoxFaceColor", ...
                "The 'none' color option is not supported." )
            
            % Update the color selection button.
            value = validatecolor( value );
            colorData = reshape( value, [1, 1, 3] );
            obj.BoxFaceColorButton.Icon = repmat( colorData, [15, 15] );
            
            % Update the boxcharts.
            obj.XBoxPlot.BoxFaceColor = colorData;
            obj.YBoxPlot.BoxFaceColor = colorData;
            
        end % set.BoxFaceColor
        
        function value = get.BoxMarkerColor( obj )
            
            value = obj.XBoxPlot.MarkerColor;
            
        end % get.BoxMarkerColor
        
        function set.BoxMarkerColor( obj, value )
            
            % Deal with the "none" option.
            assert( ~isequal( value, "none" ), ...
                "ScatterBoxplot:UnsupportedMarkerColor", ...
                "The 'none' color option is not supported." )
            
            % Update the color selection button.
            value = validatecolor( value );
            colorData = reshape( value, [1, 1, 3] );
            obj.BoxMarkerColorButton.Icon = repmat( colorData, [15, 15] );
            
            % Update the boxcharts.
            set( [obj.XBoxPlot, obj.YBoxPlot], "MarkerColor", value )
            
        end % set.BoxMarkerColor
        
        function value = get.BoxMarkerStyle( obj )
            
            value = obj.XBoxPlot.MarkerStyle;
            
        end % get.BoxMarkerStyle
        
        function set.BoxMarkerStyle( obj, value )
            
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
            
            % Deal with the "none" option.
            assert( ~isequal( value, "none" ), ...
                "ScatterBoxplot:UnsupportedWhiskerLineColor", ...
                "The 'none' color option is not supported." )
            
            % Update the color selection button.
            value = validatecolor( value );
            colorData = reshape( value, [1, 1, 3] );
            obj.WhiskerLineColorButton.Icon = ...
                repmat( colorData, [15, 15] );
            
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
        
    end % methods
    
    methods ( Access = protected )
        
        function setup( obj )
            %SETUP Initialize the chart graphics.
            
            % Define the layout grid.
            obj.LayoutGrid = uigridlayout( obj, [1, 2], ...
                "ColumnWidth", ["1x", "fit"] );
            
            % Define a tiled layout for the chart's axes.
            p = uipanel( "Parent", obj.LayoutGrid, ...
                "BorderType", "none" );
            obj.TiledLayout = tiledlayout( p, 3, 3, ...
                "TileSpacing", "compact", ...
                "Padding", "compact" );
            
            % Create the three chart axes.
            obj.YBoxPlotAxes = nexttile( obj.TiledLayout, 1, [2, 1] );
            obj.ScatterAxes = nexttile( obj.TiledLayout, 2, [2, 2] );
            obj.XBoxPlotAxes = nexttile ( obj.TiledLayout, 8 ,[1, 2] );
            
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
            
            % Create the listeners for changes in the main axes' limits.
            obj.XLimChangedListener = listener( obj.ScatterAxes, ...
                "XLim", 'PostSet', @obj.onXLimChanged );
            obj.YLimChangedListener = listener( obj.ScatterAxes, ...
                "YLim", 'PostSet', @obj.onYLimChanged );
            
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
            obj.ToggleButton = axtoolbarbtn( tb, "state", ...
                "Value", "on", ...
                "Tooltip", "Hide chart controls", ...
                "Icon", "Cog.png", ...
                "ValueChangedFcn", @obj.onToggleButtonPressed );
            
            % Add a push button to save the chart.
            obj.PrintButton = axtoolbarbtn( tb, "push", ...
                "Tooltip", "Save", ...
                "Icon", "Print.png", ...
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
            obj.ScatterMarkerDropDown = uidropdown( "Parent", controlLayout, ...
                "Items", set( obj.ScatterSeries, "Marker" ), ...
                "Tooltip", "Select the marker for the scatter plot", ...
                "Value", obj.ScatterSeries.Marker, ...
                "ValueChangedFcn", @obj.onScatterMarkerSelected );
            
            % Check box for the scatter series filled marker state.
            obj.FilledScatterMarkersCheckBox = uicheckbox( ...
                "Parent", controlLayout, ...
                "Value", false(), ...
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
                "Value", false(), ...
                "Text", "Variable size markers", ...
                "Tooltip", "Enable/disable variable size markers", ...
                "ValueChangedFcn", ...
                @obj.onVariableSizeScatterMarkersSelected );
            obj.ScatterSizeCheckBox.Layout.Column = 2;
            
            % Scatter series marker color selector.
            uilabel( "Parent", controlLayout, "Text", "Marker color:" );
            colorData = reshape( obj.ScatterCData, [1, 1, 3] );
            obj.ScatterCDataButton = uibutton( "Parent", controlLayout, ...
                "Text", "", ...
                "Tooltip", ...
                "Select the marker color for the scatter plot", ...
                "Icon", repmat( colorData, [15, 15] ), ...
                "IconAlignment", "left", ...
                "ButtonPushedFcn", @obj.onScatterCDataButtonPushed );
            
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
            colorData = reshape( obj.BoxFaceColor, [1, 1, 3] );
            obj.BoxFaceColorButton = uibutton( ...
                "Parent", controlLayout, ...
                "Text", "", ...
                "Tooltip", "Select the box face color", ...
                "Icon", repmat( colorData, [15, 15] ), ...
                "IconAlignment", "left", ...
                "ButtonPushedFcn", @obj.onBoxFaceColorButtonPushed );
            
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
            colorData = reshape( obj.WhiskerLineColor, [1, 1, 3] );
            obj.WhiskerLineColorButton = uibutton( ...
                "Parent", controlLayout, ...
                "Text", "", ...
                "Tooltip", "Select the color of the box", ...
                "Icon", repmat( colorData, [15, 15] ), ...
                "IconAlignment", "left", ...
                "ButtonPushedFcn", @obj.onWhiskerLineColorButtonPushed );
            
            % Boxchart whisker line width selector.
            uilabel( "Parent", controlLayout, ...
                "Text", "Line width:" );
            obj.WhiskerLineWidthSpinner = uispinner( "Parent", controlLayout, ...
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
            colorData = reshape( [0, 0.447, 0.741] , [1, 1, 3] );
            obj.BoxMarkerColorButton = uibutton( "Parent", controlLayout, ...
                "Text", "", ...
                "Tooltip", "Select the color of the boxchart marker", ...
                "Icon", repmat( colorData, [15, 15] ), ...
                "IconAlignment", "left", ...
                "ButtonPushedFcn", @obj.onBoxMarkerColorButtonPushed );
            
        end % setup
        
        function update ( obj )
            % UPDATE Refresh the chart graphics.
            
            if obj.ComputationRequired
                
                % Update the scatter series with the new data.
                set(obj.ScatterSeries, "XData", obj.XData_, ...
                    "YData", obj.YData_);
                
                % Update the x-boxchart with the new data.
                xlength = length( obj.XData_ );
                set( obj.XBoxPlot, ...
                    "XData", categorical( ones( xlength, 1 ) ), ...
                    "YData", obj.XData_ )
                
                % Update the y-boxchart with the new data.
                ylength = length( obj.YData_ );
                set( obj.YBoxPlot, ...
                    "XData", categorical( ones( ylength, 1 ) ), ...
                    "YData", obj.YData_ )
                
                % Mark the chart clean.
                obj.ComputationRequired = false();
                
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
                    exportgraphics( obj.TiledLayout , exportName )
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
        
        function onScatterCDataButtonPushed( obj, ~, ~ )
            %ONSCATTERCDATABUTTONPUSHED Allow the user to select a new
            %marker color for the scatter series.
            
            % Prompt the user to select a color.
            c = uisetcolor();
            figure( ancestor( obj, "figure" ) ); % Restore focus
            if isequal( c, 0 )
                % Exit if the user cancels.
                return
            else
                % Update the marker's color.
                obj.ScatterCData = c;
            end % if
            
        end % onScatterCDataButtonPushed
        
        function onBoxFaceColorButtonPushed( obj, ~, ~ )
            %ONBOXFACECOLORBUTTONPUSHED Allow the user to select a new
            %color for the boxcharts' boxes.
            
            % Prompt the user to select a color.
            c = uisetcolor();
            figure( ancestor( obj, "figure" ) ); % Restore focus
            if isequal( c, 0 )
                % Exit if the user cancels.
                return
            else
                % Update the box colors.
                set( [obj.XBoxPlot, obj.YBoxPlot], "BoxFaceColor", c )
                % Ensure the button is updated.
                obj.BoxFaceColor = c;
            end % if
            
        end % onBoxFaceColorButtonPushed
        
        function onWhiskerLineColorButtonPushed( obj, ~, ~ )
            %ONWHISKERLINECOLORBUTTONPUSHED Allow the user to select a new
            %line color for boxcharts' whisker lines.
            
            % Prompt the user to select a color.
            c = uisetcolor();
            figure( ancestor( obj, "figure" ) ); % Restore focus
            if isequal( c, 0 )
                % Exit if the user cancels.
                return
            else
                % Update the boxes' color.
                set( [obj.XBoxPlot, obj.YBoxPlot], "WhiskerLineColor", c )
                % Ensure the button is updated.
                obj.WhiskerLineColor = c;
            end % if
            
        end % onWhiskerLineColorButtonPushed
        
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
        
        function onBoxMarkerColorButtonPushed( obj, ~, ~ )
            %ONBoxMarkerColorBUTTONPUSHED Allow the user to select a new color
            %for the boxcharts' markers.
            
            % Prompt the user to select a color.
            c = uisetcolor();
            figure( ancestor( obj, "figure" ) ); % Restore focus
            if isequal( c, 0 )
                % Exit if the user cancels.
                return
            else
                % Update the boxcharts' marker color.
                set( [obj.XBoxPlot, obj.YBoxPlot], "MarkerColor", c )
                % Ensure the button is updated.
                obj.BoxMarkerColor = c;
            end % if
            
        end % onBoxMarkerColorButtonPushed
        
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
    
end % class definition