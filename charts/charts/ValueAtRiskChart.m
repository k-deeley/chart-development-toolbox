classdef ValueAtRiskChart < Component
    %VALUEATRISKCHART Chart displaying the distribution of a return series
    %together with value at risk metrics and a distribution fit.

    % Copyright 2018-2025 The MathWorks, Inc.

   properties ( Dependent )
        % Underlying data for the chart, typically a series of returns.
        Data(:, 1) double {mustBeReal, mustBeNonempty, mustBeFinite}
    end % properties ( Dependent )

    properties ( Dependent, AbortSet )
        % Value at risk level, used for both the VaR and CVaR metrics.
        VaRLevel(1, 1) double {mustBeReal, ...
            mustBeInRange( VaRLevel, 0.90, 1.00, "exclude-upper" )}
        % Probability distribution name.
        DistributionName(1, 1) string ...
            {mustBeMember( DistributionName, ["Kernel", "Normal", ...
            "Logistic", "tLocationScale"] )}
    end % properties ( Dependent, AbortSet )

    properties
        % Axes x-grid.
        XGrid(1, 1) matlab.lang.OnOffSwitchState = "on"
        % Axes y-grid.
        YGrid(1, 1) matlab.lang.OnOffSwitchState = "on"
    end % properties

    properties ( Dependent )
        % Visibility of the PDF of the distribution fit.
        FittedPDFVisible(1, 1) matlab.lang.OnOffSwitchState
        % Visibility of the VaR line.
        VaRLineVisible(1, 1) matlab.lang.OnOffSwitchState
        % Visibility of the CVaR line.
        CVaRLineVisible(1, 1) matlab.lang.OnOffSwitchState
        % Visibility of the VaR label.
        VaRLabelVisible(1, 1) matlab.lang.OnOffSwitchState
        % Visibility of the CVaR label.
        CVaRLabelVisible(1, 1) matlab.lang.OnOffSwitchState
        % Width of distribution fit curve and risk lines.
        LineWidth(1, 1) double {mustBePositive, mustBeFinite} = 2
        % Histogram edge transparency.
        EdgeAlpha(1, 1) double {mustBeInRange( EdgeAlpha, 0, 1 )}
        % Histogram edge color.
        EdgeColor
        % Histogram bar face transparency.
        FaceAlpha(1, 1) double {mustBeInRange( FaceAlpha, 0, 1 )}
        % Histogram bar face color.
        FaceColor
        % Visibility of the chart controls.
        Controls(1, 1) matlab.lang.OnOffSwitchState
    end % properties ( Dependent )

    properties ( SetAccess = private )
        % VaR and CVaR risk metrics.
        RiskMetrics(1, 2) double {mustBeReal, mustBeFinite}
    end % properties ( SetAccess = private )

    properties ( Access = private )
        % Internal storage for the chart's data.
        Data_(:, 1) double {mustBeReal, mustBeNonempty, mustBeFinite} = 0
        % Internal storage for the VaR level.
        VaRLevel_(1, 1) double {mustBeReal, ...
            mustBeInRange( VaRLevel_, 0.90, 1.00, "exclude-upper" )} = 0.95
        % Internal storage for the distribution name.
        DistributionName_(1, 1) string ...
            {mustBeMember( DistributionName_, ["Kernel", "Normal", ...
            "Logistic", "tLocationScale"] )} = "Kernel"
        % Logical vector specifying whether computations are required.
        ComputationRequired(1, 2) logical = false( 1, 2 )
    end % properties ( Access = private )

    properties ( Access = private, Transient, NonCopyable )
        % Chart layout.
        LayoutGrid(:, 1) matlab.ui.container.GridLayout ...
            {mustBeScalarOrEmpty}
        % Chart axes.
        Axes(:, 1) matlab.graphics.axis.Axes {mustBeScalarOrEmpty}
        % Toggle button for the chart controls.
        ToggleButton(:, 1) matlab.ui.controls.ToolbarStateButton ...
            {mustBeScalarOrEmpty}
        % Chart histogram to display the data.
        Histogram(:, 1) matlab.graphics.chart.primitive.Histogram ...
            {mustBeScalarOrEmpty}
        % Line object for the distribution fit.
        FittedPDF(:, 1) matlab.graphics.primitive.Line ...
            {mustBeScalarOrEmpty}
        % Vertical constant line for the value at risk.
        VaRLine(:, 1) matlab.graphics.chart.decoration.ConstantLine ...
            {mustBeScalarOrEmpty}
        % Vertical constant line for the conditional value at risk.
        CVaRLine(:, 1) matlab.graphics.chart.decoration.ConstantLine ...
            {mustBeScalarOrEmpty}
        % Dropdown menu for the probability distribution.
        DistributionDropDown(:, 1) matlab.ui.control.DropDown ...
            {mustBeScalarOrEmpty}
        % Check box for the fitted PDF.
        FittedPDFCheckBox(:, 1) matlab.ui.control.CheckBox ...
            {mustBeScalarOrEmpty}
        % Check box for the VaR line.
        VaRLineCheckBox(:, 1) matlab.ui.control.CheckBox ...
            {mustBeScalarOrEmpty}
        % Check box for the CVaR line.
        CVaRLineCheckBox(:, 1) matlab.ui.control.CheckBox ...
            {mustBeScalarOrEmpty}
        % Check box for the VaR label visibility.
        VaRLabelCheckBox(:, 1) matlab.ui.control.CheckBox ...
            {mustBeScalarOrEmpty}
        % Check box for the CVaR label visibility.
        CVaRLabelCheckBox(:, 1) matlab.ui.control.CheckBox ...
            {mustBeScalarOrEmpty}
        % Edit field for the line width.
        LineWidthEditField(:, 1) matlab.ui.control.NumericEditField ...
            {mustBeScalarOrEmpty}
        % Spinner to control the histogram's EdgeAlpha property.
        EdgeAlphaSpinner(:, 1) matlab.ui.control.Spinner ...
            {mustBeScalarOrEmpty}
        % Color picker for selecting the histogram EdgeColor.
        EdgeColorPicker(:, 1) matlab.ui.control.ColorPicker ...
            {mustBeScalarOrEmpty}
        % Spinner to control the histogram's FaceAlpha property.
        FaceAlphaSpinner(:, 1) matlab.ui.control.Spinner ...
            {mustBeScalarOrEmpty}
        % Color picker for selecting the histogram FaceColor.
        FaceColorPicker(:, 1) matlab.ui.control.ColorPicker ...
            {mustBeScalarOrEmpty}
    end % properties ( Access = private, Transient, NonCopyable )

    properties ( Constant, Hidden )
        % Product dependencies.
        Dependencies(1, :) string = ["MATLAB", ...
            "Statistics and Machine Learning Toolbox"]
        % Description.
        ShortDescription(1, 1) string = "Plot the distribution" + ...
            " of a return series together with its value at risk" + ...
            " metrics and a distribution fit"
    end % properties ( Constant, Hidden )

    methods

        function value = get.Data( obj )

            value = obj.Data_;

        end % get.Data

        function set.Data( obj, value )

            % Use fitdist to validate that the proposed data is acceptable.
            % Exit without updating if anything is wrong with the data
            % (this is distribution-dependent).
            try
                fitdist( value, obj.DistributionName_ );
            catch e
                throw( e )
            end % try/catch

            obj.Data_ = value;
            obj.ComputationRequired(1) = true;

        end % set.Data

        function value = get.VaRLevel( obj )

            value = obj.VaRLevel_;

        end % get.VaRLevel

        function set.VaRLevel( obj, value )

            obj.VaRLevel_ = value;
            obj.ComputationRequired(2) = true;

        end % set.VaRLevel

        function value = get.DistributionName( obj )

            value = obj.DistributionName_;

        end % get.DistributionName

        function set.DistributionName( obj, value )

            % Update the stored property and the dropdown control.
            obj.DistributionName_ = value;
            obj.DistributionDropDown.Value = value;

            % Mark the chart for an update.
            obj.ComputationRequired(1) = true;

        end % set.DistributionName

        function value = get.FittedPDFVisible( obj )

            value = obj.FittedPDF.Visible;

        end % get.FittedPDFVisible

        function set.FittedPDFVisible( obj, value )

            obj.FittedPDF.Visible = value;
            obj.FittedPDFCheckBox.Value = value;

        end % set.FittedPDFVisible

        function value = get.VaRLineVisible( obj )

            value = obj.VaRLine.Visible;

        end % get.VaRLineVisible

        function set.VaRLineVisible( obj, value )

            obj.VaRLine.Visible = value;
            obj.VaRLineCheckBox.Value = value;

        end % set.VaRLineVisible

        function value = get.CVaRLineVisible( obj )

            value = obj.CVaRLine.Visible;

        end % get.CVaRLineVisible

        function set.CVaRLineVisible( obj, value )

            obj.CVaRLine.Visible = value;
            obj.CVaRLineCheckBox.Value = value;

        end % set.CVaRLineVisible

        function value = get.VaRLabelVisible( obj )

            value = obj.VaRLabelCheckBox.Value;

        end % get.VaRLabelVisible
        
        function set.VaRLabelVisible( obj, value )

            obj.VaRLabelCheckBox.Value = value;
            obj.onVaRLabelToggled()

        end % set.VaRLabelVisible

        function value = get.CVaRLabelVisible( obj )

            value = obj.CVaRLabelCheckBox.Value;

        end % get.CVaRLabelVisible

        function set.CVaRLabelVisible( obj, value )

            obj.CVaRLabelCheckBox.Value = value;
            obj.onCVaRLabelToggled()

        end % set.CVaRLabelVisible

        function value = get.LineWidth( obj )

            value = obj.LineWidthEditField.Value;

        end % get.LineWidth

        function set.LineWidth( obj, value )

            obj.LineWidthEditField.Value = value;
            obj.onLineWidthEdited()

        end % set.LineWidth

        function value = get.EdgeAlpha( obj )

            value = obj.Histogram.EdgeAlpha;

        end % get.EdgeAlpha

        function set.EdgeAlpha( obj, value )

            % Update the spinner control.
            obj.EdgeAlphaSpinner.Value = value;
            
            % Update the histogram.
            obj.Histogram.EdgeAlpha = value;

        end % set.EdgeAlpha

        function value = get.EdgeColor( obj )

            value = obj.Histogram.EdgeColor;

        end % get.EdgeColor

        function set.EdgeColor( obj, value )

            % Update the histogram.
            value = validatecolor( value );            
            obj.Histogram.EdgeColor = value;

            % Update the color picker.
            obj.EdgeColorPicker.Value = value;

        end % set.EdgeColor

        function value = get.FaceAlpha( obj )

            value = obj.Histogram.FaceAlpha;

        end % get.FaceAlpha

        function set.FaceAlpha( obj, value )

            % Update the spinner control.
            obj.FaceAlphaSpinner.Value = value;

            % Update the histogram.
            obj.Histogram.FaceAlpha = value;

        end % set.FaceAlpha

        function value = get.FaceColor( obj )

            value = obj.Histogram.FaceColor;

        end % get.FaceColor

        function set.FaceColor( obj, value )

            % Update the histogram.
            value = validatecolor( value );
            obj.Histogram.FaceColor = value;

            % Update the color picker.
            obj.FaceColorPicker.Value = value;

        end % set.FaceColor

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

        function obj = ValueAtRiskChart( namedArgs )
            %VALUEATRISKCHART Construct a ValueAtRiskChart object, given
            %optional name-value arguments.

            arguments ( Input )
                namedArgs.?ValueAtRiskChart
            end % arguments ( Input )

            % Set any user-defined properties.
            set( obj, namedArgs )

        end % constructor

        function varargout = xlabel( obj, varargin )

            [varargout{1:nargout}] = xlabel( obj.Axes, varargin{:} );

        end % xlabel

        function varargout = ylabel( obj, varargin )

            [varargout{1:nargout}] = ylabel( obj.Axes, varargin{:} );

        end % ylabel

        function varargout = title( obj, varargin )

            [varargout{1:nargout}] = title( obj.Axes, varargin{:} );

        end % title

        function grid( obj, varargin )

            % Invoke grid on the axes.
            grid( obj.Axes, varargin{:} )
            
            % Update the chart's grid properties.
            obj.XGrid = obj.Axes.XGrid;
            obj.YGrid = obj.Axes.YGrid;

        end % grid

        function varargout = legend( obj, varargin )

            [varargout{1:nargout}] = legend( obj.Axes, varargin{:} );

        end % legend

        function varargout = axis( obj, varargin )

            [varargout{1:nargout}] = axis( obj.Axes, varargin{:} );

        end % axis

        function exportgraphics( obj, varargin )

            exportgraphics( obj.Axes, varargin{:} )

        end % exportgraphics

    end % methods

    methods ( Access = protected )

        function setup( obj )
            %SETUP Initialize the chart graphics.

            % Define the layout grid.
            obj.LayoutGrid = uigridlayout( obj, [1, 2], ...
                "ColumnWidth", ["1x", "0x"] );

            % Create the chart's axes.
            obj.Axes = axes( "Parent", obj.LayoutGrid );

            % Add a state button to show/hide the chart's controls.
            tb = axtoolbar( obj.Axes, "default" );
            iconPath = fullfile( chartsRoot(), "charts", "images", ...
                "Cog.png" );
            obj.ToggleButton = axtoolbarbtn( tb, "state", ...
                "Value", "off", ...
                "Tooltip", "Show chart controls", ...
                "Icon", iconPath, ...
                "ValueChangedFcn", @obj.onToggleButtonPressed );

            % Create the histogram.
            hold( obj.Axes, "on" )
            obj.Histogram = histogram( obj.Axes, NaN, ...
                "FaceColor", obj.Axes.ColorOrder(1, :), ...
                "Normalization", "pdf" );

            % Overlay the density on the histogram.
            c = obj.Axes.ColorOrder;
            obj.FittedPDF = line( "Parent", obj.Axes, ...
                "XData", NaN, ...
                "YData", NaN, ...
                "LineWidth", 2, ...
                "Color", c(2, :) );

            % Overlay the VaR lines.
            obj.VaRLine = xline( obj.Axes, 0, "Color", c(3, :), ...
                "Alpha", 1, ...
                "LineWidth", 2, ...
                "LabelHorizontalAlignment", "left" );
            obj.CVaRLine = xline( obj.Axes, 0, "Color", c(4, :), ...
                "Alpha", 1, ...
                "LineWidth", 2, ...
                "LabelHorizontalAlignment", "left" );

            % Annotate the axes and add the legend.
            xlabel( obj.Axes, "Data" )
            ylabel( obj.Axes, "Probability density" )
            title( obj.Axes, "ValueAtRisk Chart" )
            legend( obj.Axes, ["Data", "Fit", "VaR", "CVaR"] )
            hold( obj.Axes, "off" )

            % Add the chart controls. Start with the control panel and its
            % main layout grid.
            p = uipanel( "Parent", obj.LayoutGrid, ...
                "Title", "Chart Controls", ...
                "FontWeight", "bold" );
            p.Layout.Column = 2;
            g = uigridlayout( p, [8, 2], ...
                "RowHeight", repelem( "fit", 8 ), ...
                "ColumnWidth", ["fit", "1x"] );
            
            % Add the distribution selection dropdown.
            uilabel( g, "Text", "Distribution fit: ", ...
                "HorizontalAlignment", "right" );
            obj.DistributionDropDown = uidropdown( g, ...
                "Items", ...
                ["Kernel", "Normal", "Logistic", "tLocationScale"], ...
                "Tooltip", ...
                "Select the probability distribution to fit to the data", ...
                "ValueChangedFcn", @obj.onDistributionSelected );
            
            % Add checkboxes to control visibility of the PDF and value at
            % risk lines.
            obj.FittedPDFCheckBox = uicheckbox( g, ...
                "Text", "Show fitted PDF", ...
                "Value", ...
                matlab.lang.OnOffSwitchState( obj.FittedPDFVisible ), ...
                "Tooltip", "Hide or show the fitted PDF", ...
                "ValueChangedFcn", @obj.toggleFittedPDFVisibility );
            obj.FittedPDFCheckBox.Layout.Column = [1, 2];
            obj.VaRLineCheckBox = uicheckbox( g, ...
                "Text", "Show VaR line", ...
                "Value", ...
                matlab.lang.OnOffSwitchState( obj.VaRLineVisible ), ...
                "Tooltip", "Hide or show the VaR line", ...
                "ValueChangedFcn", @obj.toggleVaRLineVisibility );
            obj.VaRLineCheckBox.Layout.Column = [1, 2];
            obj.CVaRLineCheckBox = uicheckbox( g, ...
                "Text", "Show CVaR line", ...
                "Value", ...
                matlab.lang.OnOffSwitchState( obj.CVaRLineVisible ), ...
                "Tooltip", "Hide or show the CVaR line", ...
                "ValueChangedFcn", @obj.toggleCVaRLineVisibility );
            obj.CVaRLineCheckBox.Layout.Column = [1, 2];

            % Add checkboxes to control visibility of the risk line labels.
            obj.VaRLabelCheckBox = uicheckbox( g, ...
                "Text", "Show VaR label", ...
                "Value", true, ...
                "Tooltip", "Hide or show the VaR label", ...
                "ValueChangedFcn", @obj.onVaRLabelToggled );
            obj.VaRLabelCheckBox.Layout.Column = [1, 2];
            obj.CVaRLabelCheckBox = uicheckbox( g, ...
                "Text", "Show CVaR label", ...
                "Value", true, ...
                "Value", true, ...
                "Tooltip", "Hide or show the CVaR label", ...
                "ValueChangedFcn", @obj.onCVaRLabelToggled );
            obj.CVaRLabelCheckBox.Layout.Column = [1, 2];

            % Add an edit field for the line width.
            uilabel( g, "Text", "Line width:", ...
                "HorizontalAlignment", "right" );
            obj.LineWidthEditField = uieditfield( g, "numeric", ...
                "Limits", [0, Inf], ...
                "LowerLimitInclusive", "off", ...
                "UpperLimitInclusive", "off", ...
                "Value", 2, ...
                "ValueChangedFcn", @obj.onLineWidthEdited );
                        
            % Place the histogram controls in a separate panel.
            p = uipanel( g, "Title", "Histogram Appearance", ...
                "FontWeight", "bold" );
            p.Layout.Column = [1, 2];
            g = uigridlayout( p, [4, 2], ...
                "RowHeight", repmat( "fit", 4, 1 ), ...
                "ColumnWidth", ["fit", "1x"] );
            
            % Add controls for the edge and face transparency and color.
            uilabel( g, "Text", "Edge color:", ...
                "HorizontalAlignment", "right" );
            obj.EdgeColorPicker = uicolorpicker( "Parent", g, ...
                "Tooltip", "Select the histogram edge color", ...
                "Value", obj.EdgeColor, ...
                "ValueChangedFcn", @obj.onEdgeColorPicked );            
            uilabel( g, "Text", "Edge alpha:", ...
                "HorizontalAlignment", "right" );
            obj.EdgeAlphaSpinner = uispinner( g, ...
                "Value", obj.EdgeAlpha, ...
                "ValueDisplayFormat", "%.1f", ...
                "Limits", [0, 1], ...
                "Step", 0.1, ...
                "ValueChangedFcn", @obj.onEdgeAlphaSelected );
            uilabel( g, "Text", "Face color:", ...
                "HorizontalAlignment", "right" );
            obj.FaceColorPicker = uicolorpicker( "Parent", g, ...
                "Value", obj.FaceColor, ...
                "Tooltip", "Select the histogram face color", ...
                "ValueChangedFcn", @obj.onFaceColorPicked );            
            uilabel( g, "Text", "Face alpha:", ...
                "HorizontalAlignment", "right" );
            obj.FaceAlphaSpinner = uispinner( g, ...
                "Value", obj.FaceAlpha, ...
                "ValueDisplayFormat", "%.1f", ...
                "Limits", [0, 1], ...
                "Step", 0.1, ...
                "ValueChangedFcn", @obj.onFaceAlphaSelected );

        end % setup

        function update( obj )
            %UPDATE Refresh the chart graphics.

            if obj.ComputationRequired(1)

                % Update the non-parametric distribution fit.
                mdl = fitdist( obj.Data, obj.DistributionName_ );

                % Evaluate it on the sample range.
                sampleVals = linspace( ...
                    min( obj.Data ), max( obj.Data ), 1000 );
                pdfVals = pdf( mdl, sampleVals );

                % Update the density plot.
                set( obj.FittedPDF, "XData", sampleVals, "YData", pdfVals )

                % Update the histogram with the new data.
                set( obj.Histogram, "Data", obj.Data, "BinMethod", "auto" )

                % Update the VaR lines.
                obj.updateVaRLines()

                % Mark the chart clean.
                obj.ComputationRequired = false( 1, 2 );

            end % if

            if obj.ComputationRequired(2)

                % Update the VaR lines only.
                obj.updateVaRLines()
                
                % Mark the chart clean.
                obj.ComputationRequired(2) = false;

            end % if

            % Refresh the chart's decorative properties.
            obj.FittedPDF.LineWidth = obj.LineWidth;
            obj.VaRLine.LineWidth = obj.LineWidth;
            obj.CVaRLine.LineWidth = obj.LineWidth;
            set( obj.Axes, "XGrid", obj.XGrid, "YGrid", obj.YGrid )

        end % update

        function updateVaRLines( obj )
            %UPDATEVARLINES Update the VaR lines if the VaR level has been
            %changed.

            % Compute the new VaR and CVaR.
            VaR = quantile( obj.Data, 1 - obj.VaRLevel );
            CVaR = mean( obj.Data(obj.Data < VaR) );
            obj.RiskMetrics = [VaR, CVaR];
            obj.VaRLine.Value = VaR;
            obj.CVaRLine.Value = CVaR;
            obj.onVaRLabelToggled()
            obj.onCVaRLabelToggled()

        end % updateVaRLines

    end % methods ( Access = protected )

    methods ( Access = private )

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

        function onDistributionSelected( obj, ~, ~ )
            %ONDISTRIBUTIONSELECTED Update the chart when the user selects
            %a probability distribution from the dropdown menu.

            obj.DistributionName = obj.DistributionDropDown.Value;

        end % onDistributionSelected

        function toggleFittedPDFVisibility( obj, s, ~ )
            %TOGGLEFITTEDPDFVISIBILITY Toggle the visibility of the fitted
            %PDF.

            obj.FittedPDF.Visible = s.Value;

        end % toggleFittedPDFVisibility

        function toggleVaRLineVisibility( obj, s, ~ )
            %TOGGLEVARLINEVISIBILITY Toggle the visibility of the VaR line.

            obj.VaRLine.Visible = s.Value;

        end % toggleVaRLineVisibility

        function toggleCVaRLineVisibility( obj, s, ~ )
            %TOGGLECVARLINEVISIBILITY Toggle the visibility of the CVaR
            %line.

            obj.CVaRLine.Visible = s.Value;

        end % toggleCVaRLineVisibility

        function onVaRLabelToggled( obj, ~, ~ )
            %ONVARLABELTOGGLED Toggle the visibility of the VaR label.

            checked = obj.VaRLabelCheckBox.Value;
            if checked
                obj.VaRLine.Label = "VaR (" + 100 * obj.VaRLevel + ...
                    ") = " + obj.RiskMetrics(1);
            else
                obj.VaRLine.Label = "";
            end % if

        end % onVaRLabelToggled

        function onCVaRLabelToggled( obj, ~, ~ )
            %ONCVARLABELTOGGLED Toggle the visibility of the CVaR label.

            checked = obj.CVaRLabelCheckBox.Value;
            if checked
                obj.CVaRLine.Label = "CVaR (" + 100 * obj.VaRLevel + ...
                    ") = " + obj.RiskMetrics(2);
            else
                obj.CVaRLine.Label = "";
            end % if

        end % onCVaRLabelToggled

        function onLineWidthEdited( obj, ~, ~ )
            %ONLINEWIDTHEDITED Update the line width of the distribution
            %fit and risk lines.

            lw = obj.LineWidthEditField.Value;
            set( [obj.FittedPDF, obj.VaRLine, obj.CVaRLine], ...
                "LineWidth", lw )

        end % onLineWidthEdited

        function onEdgeAlphaSelected( obj, s, ~ )
            %ONEDGEALPHASELECTED Update the histogram's EdgeAlpha when the
            %user modifies the spinner.

            obj.EdgeAlpha = s.Value;

        end % onEdgeAlphaSelected

        function onEdgeColorPicked( obj, ~, ~ )
            %ONEDGECOLORPICKED Update the histogram's EdgeColor when the
            %user selects a color.

            % Update the edge color.
            obj.EdgeColor = obj.EdgeColorPicker.Value;

        end % onEdgeColorPicked

        function onFaceAlphaSelected( obj, s, ~ )
            %ONEDGEALPHASELECTED Update the histogram's EdgeAlpha when the
            %user modifies the spinner.

            obj.FaceAlpha = s.Value;

        end % onFaceAlphaSelected

        function onFaceColorPicked( obj, ~, ~ )
            %ONFACECOLORPICKED Update the histogram's FaceColor when the
            %user selects a color.

            % Update the face color.
            obj.FaceColor = obj.FaceColorPicker.Value;

        end % onFaceColorPicked

    end % methods ( Access = private )

end % classdef