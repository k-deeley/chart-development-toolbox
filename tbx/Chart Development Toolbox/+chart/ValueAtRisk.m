classdef ValueAtRisk < matlab.ui.componentcontainer.ComponentContainer
    %VALUEATRISK Chart displaying the distribution of a return series
    %together with value at risk metrics and a distribution fit.
    %
    % Copyright 2018-2021 The MathWorks, Inc.
    
    properties ( Dependent )
        % Underlying data for the chart, typically a series of returns.
        Data(:, 1) double {mustBeReal, mustBeNonempty, mustBeFinite} = 0
    end % properties ( Dependent )
    
    properties ( Dependent, AbortSet )
        % Value at risk level, used for both the VaR and CVaR metrics.
        VaRLevel(1, 1) double {mustBeReal, ...
            mustBeInRange( VaRLevel, 0.90, 1.00, "exclude-upper" )} = 0.95
        % Probability distribution name.
        DistributionName(1, 1) string ...
            {mustBeMember( DistributionName, ["Kernel", "Normal", ...
            "Logistic", "tLocationScale"] )} = "Kernel"
    end % properties ( Dependent, AbortSet )
    
    properties
        % Axes x-grid.
        XGrid = "on"
        % Axes y-grid.
        YGrid = "on"
    end % properties
    
    properties ( Dependent )
        % Visibility of the PDF of the distribution fit.
        FittedPDFVisible(1, 1) matlab.lang.OnOffSwitchState
        % Visibility of the VaR line.
        VaRLineVisible(1, 1) matlab.lang.OnOffSwitchState
        % Visibility of the CVaR line.
        CVaRLineVisible(1, 1) matlab.lang.OnOffSwitchState
        % Histogram edge transparency.
        EdgeAlpha
        % Histogram edge color.
        EdgeColor
        % Histogram bar face transparency.
        FaceAlpha
        % Histogram bar face color.
        FaceColor
        % Visibility of the chart controls.
        Controls(1, 1) matlab.lang.OnOffSwitchState
    end % properties ( Dependent )
    
    properties ( Access = private )
        % Internal storage for the chart's data.
        Data_ = 0
        % Internal storage for the VaR level.
        VaRLevel_ = 0.95
        % Internal storage for the distribution name.
        DistributionName_ = "Kernel"
        % Logical vector specifying whether computations are required.
        ComputationRequired = false( 1, 2 )
    end % properties ( Access = private )
    
    properties ( Access = private, Transient, NonCopyable )
        % Chart layout.
        LayoutGrid(1, 1) matlab.ui.container.GridLayout
        % Chart axes.
        Axes(1, 1) matlab.graphics.axis.Axes
        % Toggle button for the chart controls.
        ToggleButton(1, 1) matlab.ui.controls.ToolbarStateButton
        % Chart histogram to display the data.
        Histogram(1, 1) matlab.graphics.chart.primitive.Histogram
        % Line object for the distribution fit.
        FittedPDF(1, 1) matlab.graphics.primitive.Line
        % Vertical constant line for the value at risk.
        VaRLine(1, 1) matlab.graphics.chart.decoration.ConstantLine
        % Vertical constant line for the conditional value at risk.
        CVaRLine(1, 1) matlab.graphics.chart.decoration.ConstantLine
        % Dropdown menu for the probability distribution.
        DistributionDropDown(1, 1) matlab.ui.control.DropDown
        % Check box for the fitted PDF.
        FittedPDFCheckBox(1, 1) matlab.ui.control.CheckBox
        % Check box for the VaR line.
        VaRLineCheckBox(1, 1) matlab.ui.control.CheckBox
        % Check box for the CVaR line.
        CVaRLineCheckBox(1, 1) matlab.ui.control.CheckBox
        % Spinner to control the histogram's EdgeAlpha property.
        EdgeAlphaSpinner(1, 1) matlab.ui.control.Spinner
        % Pushbutton for selecting the histogram EdgeColor.
        EdgeColorButton(1, 1) matlab.ui.control.Button
        % Spinner to control the histogram's FaceAlpha property.
        FaceAlphaSpinner(1, 1) matlab.ui.control.Spinner
        % Pushbutton for selecting the histogram FaceColor.
        FaceColorButton(1, 1) matlab.ui.control.Button
    end % properties ( Access = private, Transient, NonCopyable )
    
    properties ( Constant, Hidden )
        % Product dependencies.
        Dependencies = ["MATLAB", ...
            "Statistics and Machine Learning Toolbox"]
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
            obj.ComputationRequired(1) = true();
            
        end % set.Data
        
        function value = get.VaRLevel( obj )
            
            value = obj.VaRLevel_;
            
        end % get.VaRLevel
        
        function set.VaRLevel( obj, value )
            
            obj.VaRLevel_ = value;
            obj.ComputationRequired(2) = true();
            
        end % set.VaRLevel
        
        function value = get.DistributionName( obj )
            
            value = obj.DistributionName_;
            
        end % get.DistributionName
        
        function set.DistributionName( obj, value )
            
            % Update the stored property and the dropdown control.
            obj.DistributionName_ = value;
            obj.DistributionDropDown.Value = value;
            % Mark the chart for an update.
            obj.ComputationRequired(1) = true();
            
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
            
            % Deal with the "none" and "auto" options.
            assert( ~(isequal( value, "none" ) || ...
                isequal( value, "auto" )), ...
                "ValueAtRisk:UnsupportedEdgeColor", ...
                "The 'none' and 'auto' color options are not supported." )
            
            % Update the histogram.
            obj.Histogram.EdgeColor = value;
            
            % Update the color selection button.
            edgeColor = reshape( obj.EdgeColor, [1, 1, 3] );
            obj.EdgeColorButton.Icon = repmat( edgeColor, [15, 15] );
            
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
            
            % Deal with the "none" and "auto" options.
            assert( ~(isequal( value, "none" ) || ...
                isequal( value, "auto" )), ...
                "ValueAtRisk:UnsupportedFaceColor", ...
                "The 'none' and 'auto' color options are not supported." )
            
            % Update the histogram.
            obj.Histogram.FaceColor = value;
            
            % Update the color selection button.
            faceColor = reshape( obj.FaceColor, [1, 1, 3] );
            obj.FaceColorButton.Icon = repmat( faceColor, [15, 15] );
            
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
        
    end % methods
    
    methods ( Access = protected )
        
        function setup( obj )
            %SETUP Initialize the chart graphics.
            
            % Define the layout grid.
            obj.LayoutGrid = uigridlayout( obj, [1, 2], ...
                "ColumnWidth", ["1x", "fit"] );
            
            % Create the chart's axes.            
            obj.Axes = axes( "Parent", obj.LayoutGrid );
            
            % Add a state button to show/hide the chart's controls.
            tb = axtoolbar( obj.Axes, "default" );
            obj.ToggleButton = axtoolbarbtn( tb, "state", ...
                "Value", "on", ...
                "Tooltip", "Hide chart controls", ...
                "Icon", "Cog.png", ...
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
                "LineWidth", 2.5, ...
                "Color", c(2, :) );
            
            % Overlay the VaR lines.
            obj.VaRLine = xline( obj.Axes, 0, "m", "LineWidth", 2, ...
                "LabelHorizontalAlignment", "left" );
            obj.CVaRLine = xline( obj.Axes, 0, "r", "LineWidth", 2, ...
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
            g = uigridlayout( p, [5, 2], ...
                "RowHeight", repmat( "fit", 5, 1 ), ...
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
            % Place the histogram controls in a separate panel.
            p = uipanel( g, "Title", "Histogram Appearance", ...
                "FontWeight", "bold" );
            p.Layout.Column = [1, 2];
            g = uigridlayout( p, [4, 2], ...
                "RowHeight", repmat( "fit", 4, 1 ), ...
                "ColumnWidth", ["fit", "1x"] );
            % Add controls for the edge and face transparency and color.
            edgeColor = reshape( obj.EdgeColor, [1, 1, 3] );
            obj.EdgeColorButton = uibutton( "Parent", g, ...
                "Text", "Edge color", ...
                "Tooltip", "Select the histogram edge color", ...
                "Icon", repmat( edgeColor, [15, 15] ), ...
                "IconAlignment", "right", ...
                "ButtonPushedFcn", @obj.onEdgeColorSelected );
            obj.EdgeColorButton.Layout.Column = [1, 2];
            uilabel( g, "Text", "Edge alpha:", ...
                "HorizontalAlignment", "right" );
            obj.EdgeAlphaSpinner = uispinner( g, ...
                "Value", obj.EdgeAlpha, ...
                "ValueDisplayFormat", "%.1f", ...
                "Limits", [0, 1], ...
                "Step", 0.1, ...
                "ValueChangedFcn", @obj.onEdgeAlphaSelected );
            faceColor = reshape( obj.FaceColor, [1, 1, 3] );
            obj.FaceColorButton = uibutton( "Parent", g, ...
                "Text", "Face color", ...
                "Tooltip", "Select the histogram face color", ...
                "Icon", repmat( faceColor, [15, 15] ), ...
                "IconAlignment", "right", ...
                "ButtonPushedFcn", @obj.onFaceColorSelected );
            obj.FaceColorButton.Layout.Column = [1, 2];
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
                obj.ComputationRequired(2) = false();
                
            end % if
            
            % Refresh the chart's decorative properties.
            set( obj.Axes, "XGrid", obj.XGrid, "YGrid", obj.YGrid )
            
        end % update
        
        function updateVaRLines( obj )
            %UPDATEVARLINES Update the VaR lines if the VaR level has been
            %changed.
            
            % Compute the new VaR and CVaR.
            VaR = quantile( obj.Data, 1 - obj.VaRLevel );
            CVaR = mean( obj.Data(obj.Data < VaR) );
            percentVaRLevel = 100 * obj.VaRLevel;
            set( obj.VaRLine, "Value", VaR, ...
                "Label", "VaR (" + percentVaRLevel + ") = " + VaR )
            set( obj.CVaRLine, "Value", CVaR, ...
                "Label", "CVaR (" + percentVaRLevel + ") = " + CVaR )
            
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
        
        function onEdgeAlphaSelected( obj, s, ~ )
            %ONEDGEALPHASELECTED Update the histogram's EdgeAlpha when the
            %user modifies the spinner.
            
            obj.EdgeAlpha = s.Value;
            
        end % onEdgeAlphaSelected
        
        function onEdgeColorSelected( obj, ~, ~ )
            %ONEDGECOLORSELECTED Update the histogram's EdgeColor when the
            %user selects a color.
            
            % Prompt the user to select a color.
            c = uisetcolor();
            figure( ancestor( obj, "figure" ) ) % Restore focus
            if isequal( c, 0 )
                % Exit if the user cancels.
                return
            else
                % Update the edge color.
                obj.EdgeColor = c;
            end % if
            
        end % onEdgeColorSelected
        
        function onFaceAlphaSelected( obj, s, ~ )
            %ONEDGEALPHASELECTED Update the histogram's EdgeAlpha when the
            %user modifies the spinner.
            
            obj.FaceAlpha = s.Value;
            
        end % onFaceAlphaSelected
        
        function onFaceColorSelected( obj, ~, ~ )
            %ONFACECOLORSELECTED Update the histogram's FaceColor when the
            %user selects a color.
            
            % Prompt the user to select a color.
            c = uisetcolor();
            figure( ancestor( obj, "figure" ) ) % Restore focus
            if isequal( c, 0 )
                % Exit if the user cancels.
                return
            else
                % Update the face color.
                obj.FaceColor = c;
            end % if
            
        end % onFaceColorSelected
        
    end % methods ( Access = private )
    
end % class definition