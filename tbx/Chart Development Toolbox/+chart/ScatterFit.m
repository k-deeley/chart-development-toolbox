classdef ScatterFit < matlab.ui.componentcontainer.ComponentContainer
    %SCATTERFIT Chart component managing 2D scattered data (x and y)
    %together with the corresponding best-fit line.
    %
    % Copyright 2018-2022 The MathWorks, Inc.
    
    properties ( Dependent )
        % Chart x-data.
        XData(:, 1) double {mustBeReal}
        % Chart y-data.
        YData(:, 1) double {mustBeReal}
    end % properties ( Dependent )
    
    properties
        % Size data for the scatter series.
        SizeData = 36
        % Color data for the scatter series.
        CData = [0, 0.4470, 0.7410]
    end % properties
    
    properties ( Dependent )
        % Visibility of the best-fit line.
        LineVisible(1, 1) matlab.lang.OnOffSwitchState
        % Width of the best-fit line.
        LineWidth
        % Style of the best-fit line.
        LineStyle
        % Scatter series marker.
        Marker
        % Color of the best-fit line.
        LineColor
        % Axes x-grid.
        XGrid(1, 1) matlab.lang.OnOffSwitchState
        % Axes y-grid.
        YGrid(1, 1) matlab.lang.OnOffSwitchState
        % Visibility of the chart controls.
        Controls(1, 1) matlab.lang.OnOffSwitchState
    end % properties ( Dependent )
    
    properties ( Access = private )
        % Internal storage for the XData property.
        XData_ = double.empty( 0, 1 )
        % Internal storage for the YData property.
        YData_ = double.empty( 0, 1 )
        % Logical scalar specifying whether a computation is required.
        ComputationRequired = false()
    end % properties ( Access = private )
    
    properties ( Access = private, Transient, NonCopyable )
        % Chart layout.
        LayoutGrid(1, 1) matlab.ui.container.GridLayout
        % Chart axes.
        Axes(1, 1) matlab.graphics.axis.Axes
        % Toggle button for the chart controls.
        ToggleButton(1, 1) matlab.ui.controls.ToolbarStateButton
        % Scatter series for the (x, y) data.
        ScatterSeries(1, 1) matlab.graphics.chart.primitive.Scatter
        % Line object for the best-fit line.
        BestFitLine(1, 1) matlab.graphics.primitive.Line
        % Label to display a summary of the best-fit line statistics.
        SummaryLabel(1, 1) matlab.ui.control.Label
        % Check box for the best-fit line visibility.
        BestFitLineCheckBox(1, 1) matlab.ui.control.CheckBox
        % Spinner for selecting the width of the best-fit line.
        LineWidthSpinner(1, 1) matlab.ui.control.Spinner
        % Dropdown menu for selecting the style of the best-fit line.
        LineStyleDropDown(1, 1) matlab.ui.control.DropDown
        % Dropdown menu for selecting the marker of the scatter plot.
        MarkerDropDown(1, 1) matlab.ui.control.DropDown
        % Pushbutton for selecting the color of the best-fit line.
        LineColorButton(1, 1) matlab.ui.control.Button
        % Check boxes for the axes' XGrid and YGrid visibility.
        GridCheckBoxes(1, 2) matlab.ui.control.CheckBox
    end % properties ( Access = private, Transient, NonCopyable )
    
    properties ( Constant, Hidden )
        % Product dependencies.
        Dependencies = ["MATLAB", ...
            "Statistics and Machine Learning Toolbox"]
    end % properties ( Constant, Hidden )
    
    properties ( Constant, GetAccess = private )
        % Warning ID which may arise when fitting the line.
        FitWarningID = "stats:LinearModel:RankDefDesignMat"
    end % properties ( Constant, GetAccess = private )
    
    methods
        
        function value = get.XData( obj )
            
            value = obj.XData_;
            
        end % get.XData
        
        function set.XData( obj, value )
            
            % Mark the chart for an update.
            obj.ComputationRequired = true();
            
            % Decide how to modify the chart data.
            nX = numel( value );
            nY = numel( obj.YData_ );
            
            if nX < nY % If the new x-data is too short ...
                % ... then chop the chart y-data.
                obj.YData_ = obj.YData_(1:nX);
            else
                % Otherwise, if nX >= nY, then pad the y-data.
                obj.YData_(end+1:nX, 1) = NaN;
            end % if
            
            % Set the internal x-data.
            obj.XData_ = value;
            
            % Reset the scatter series' color and size data if necessary.
            nC = size( obj.CData, 1 );
            if nC > 1 && nX ~= nC
                obj.CData = obj.Axes.ColorOrder(1, :);
            end % if
            nS = numel( obj.SizeData );
            if nS > 1 && nX ~= nS
                obj.SizeData = 36;
            end % if
            
        end % set.XData
        
        function value = get.YData( obj )
            
            value = obj.YData_;
            
        end % get.YData
        
        function set.YData( obj, value )
            
            % Mark the chart for an update.
            obj.ComputationRequired = true();
            
            % Decide how to modify the chart data.
            nY = numel( value );
            nX = numel( obj.XData_ );
            
            if nY < nX % If the new y-data is too short ...
                % ... then chop the chart x-data.
                obj.XData_ = obj.XData_(1:nY);
            else
                % Otherwise, if nY >= nX, then pad the x-data.
                obj.XData_(end+1:nY, 1) = NaN;
            end % if
            
            % Set the internal y-data.
            obj.YData_ = value;
            
            % Reset the color and size data if necessary.
            nC = size( obj.CData, 1 );
            if nC > 1 && nY ~= nC
                obj.CData = obj.Axes.ColorOrder(1, :);
            end % if
            nS = numel( obj.SizeData );
            if nS > 1 && nY ~= nS
                obj.SizeData = 36;
            end % if
            
        end % set.YData
        
        function value = get.LineVisible( obj )
            
            value = obj.BestFitLine.Visible;
            
        end % get.LineVisible
        
        function set.LineVisible( obj, value )
            
            % Update the property.
            obj.BestFitLine.Visible = value;
            % Update the check box.
            obj.BestFitLineCheckBox.Value = value;
            
        end % set.LineVisible
        
        function value = get.LineWidth( obj )
            
            value = obj.BestFitLine.LineWidth;
            
        end % get.LineWidth
        
        function set.LineWidth( obj, value )
            
            % Update the property.
            obj.BestFitLine.LineWidth = value;
            % Update the spinner.
            obj.LineWidthSpinner.Value = value;
            
        end % set.LineWidth
        
        function value = get.LineStyle( obj )
            
            value = obj.BestFitLine.LineStyle;
            
        end % get.LineStyle
        
        function set.LineStyle( obj, value )
            
            % Update the property.
            obj.BestFitLine.LineStyle = value;
            % Update the dropdown menu.
            obj.LineStyleDropDown.Value = value;
            
        end % set.LineStyle
        
        function value = get.Marker( obj )
            
            value = obj.ScatterSeries.Marker;
            
        end % get.Marker
        
        function set.Marker( obj, value )
            
            % Update the property.
            obj.ScatterSeries.Marker = value;
            % Update the dropdown menu.
            obj.MarkerDropDown.Value = validatestring( value, ...
                obj.MarkerDropDown.Items );
            
        end % set.Marker
        
        function value = get.LineColor( obj )
            
            value = obj.BestFitLine.Color;
            
        end % get.LineColor
        
        function set.LineColor( obj, value )
            
            % Deal with the "none" option.
            assert( ~isequal( value, "none" ), ...
                "ScatterFit:UnsupportedLineColor", ...
                "The 'none' color option is not supported." )
            
            % Update the line.
            obj.BestFitLine.Color = value;
            
            % Update the color selection button.
            lineColor = reshape( obj.LineColor, [1, 1, 3] );
            obj.LineColorButton.Icon = repmat( lineColor, [15, 15] );
            
        end % set.LineColor
        
        function value = get.XGrid( obj )
            
            value = obj.Axes.XGrid;
            
        end % set.XGrid
        
        function set.XGrid( obj, value )
            
            % Set the property.
            obj.Axes.XGrid = value;
            % Update the checkbox.
            obj.GridCheckBoxes(1).Value = value;
            
        end % set.XGrid
        
        function value = get.YGrid( obj )
            
            value = obj.Axes.YGrid;
            
        end % get.YGrid
        
        function set.YGrid( obj, value )
            
            % Set the property.
            obj.Axes.YGrid = value;
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
            % Ensure the controls are up-to-date. This can be done by
            % setting the XGrid/YGrid chart properties, which in turn will
            % refresh the controls.
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
            
            % Create the scatter series.
            hold( obj.Axes, "on" )
            obj.ScatterSeries = scatter( obj.Axes, NaN, NaN, ".", ...
                "CData", obj.CData, ...
                "DisplayName", "Data" );
            hold( obj.Axes, "off" )
            
            % Create the line object for the best-fit line.
            obj.BestFitLine = line( obj.Axes, NaN, NaN, ...
                "LineWidth", 1.5, ...
                "Color", obj.Axes.ColorOrder(2, :), ...
                "DisplayName", "Best-fit line" );
            
            % Annotate the axes and add the legend.
            xlabel( obj.Axes, "x" )
            ylabel( obj.Axes, "y" )
            title( obj.Axes, "ScatterFit Chart" )
            legend( obj.Axes )
            
            % Add the chart controls.
            p = uipanel( "Parent", obj.LayoutGrid, ...
                "Title", "Chart Controls", ...
                "FontWeight", "bold" );
            p.Layout.Column = 2;
            controlLayout = uigridlayout( p, [8, 2], ...
                "RowHeight", repmat( "fit", 1, 8 ) );
            % Summary label.
            obj.SummaryLabel = uilabel( "Parent", controlLayout, ...
                "Text", "" );
            obj.SummaryLabel.Layout.Column = [1, 2];
            % Best-fit line visibility toggle.
            obj.BestFitLineCheckBox = uicheckbox( ...
                "Parent", controlLayout, ...
                "Value", true(), ...
                "Text", "Show best-fit line", ...
                "Tooltip", ...
                "Hide or show the best-fit line", ...
                "ValueChangedFcn", @obj.toggleLineVisibility );
            obj.BestFitLineCheckBox.Layout.Column = [1, 2];
            % Best-fit line width selector.
            uilabel( "Parent", controlLayout, ...
                "Text", "Line width:" );
            obj.LineWidthSpinner = uispinner( "Parent", controlLayout, ...
                "Limits", [0, Inf], ...
                "LowerLimitInclusive", "off", ...
                "Step", 0.5, ...
                "Tooltip", "Select the width of the best-fit line", ...
                "Value", obj.BestFitLine.LineWidth, ...
                "ValueDisplayFormat", "%.1f", ...
                "ValueChangedFcn", @obj.onLineWidthSelected );
            % Best-fit line style selector.
            uilabel( "Parent", controlLayout, ...
                "Text", "Line style:" );
            obj.LineStyleDropDown = uidropdown( ...
                "Parent", controlLayout, ...
                "Items", set( obj.BestFitLine, "LineStyle" ), ...
                "Tooltip", "Select the style of the best-fit line", ...
                "Value", obj.BestFitLine.LineStyle, ...
                "ValueChangedFcn", @obj.onLineStyleSelected );
            % Best-fit line color selector.
            lineColor = reshape( obj.BestFitLine.Color, [1, 1, 3] );
            obj.LineColorButton = uibutton( "Parent", controlLayout, ...
                "Text", "Line color", ...
                "Tooltip", "Select the color of the best-fit line", ...
                "Icon", repmat( lineColor, [15, 15] ), ...
                "IconAlignment", "right", ...
                "ButtonPushedFcn", @obj.onLineColorButtonPushed );
            obj.LineColorButton.Layout.Column = [1, 2];
            % Scatter plot marker selector.
            uilabel( "Parent", controlLayout, ...
                "Text", "Scatter plot marker:" );
            obj.MarkerDropDown = uidropdown( ...
                "Parent", controlLayout, ...
                "Items", set( obj.ScatterSeries, "Marker" ), ...
                "Tooltip", "Select the marker for the scatter plot", ...
                "Value", obj.ScatterSeries.Marker, ...
                "ValueChangedFcn", @obj.onMarkerSelected );
            % Check boxes for the gridlines.
            obj.GridCheckBoxes(1) = uicheckbox( ...
                "Parent", controlLayout, ...
                "Value", matlab.lang.OnOffSwitchState( obj.XGrid ), ...
                "Tag", "X", ...
                "Text", "Show x-gridlines", ...
                "Tooltip", "Toggle the vertical axes gridlines", ...
                "ValueChangedFcn", @obj.onGridSelected );
            obj.GridCheckBoxes(1).Layout.Column = [1, 2];
            obj.GridCheckBoxes(2) = uicheckbox( ...
                "Parent", controlLayout, ...
                "Value", matlab.lang.OnOffSwitchState( obj.YGrid ), ...
                "Tag", "Y", ...
                "Text", "Show y-gridlines", ...
                "Tooltip", "Toggle the horizontal axes gridlines", ...
                "ValueChangedFcn", @obj.onGridSelected );
            obj.GridCheckBoxes(2).Layout.Column = [1, 2];
            
        end % setup
        
        function update( obj )
            %UPDATE Refresh the chart graphics.
            
            if obj.ComputationRequired
                
                % Update the scatter series with the new data.
                set( obj.ScatterSeries, "XData", obj.XData_, ...
                    "YData", obj.YData_ )
                % Compute the new best-fit line. Suppress any rank deficiency
                % warning from the regression, if necessary, then restore the
                % user's warning preference. Handle empty chart data as a
                % separate case as this causes an error when using the fitlm
                % function.
                if ~isempty( obj.XData_ )
                    % Handle the possible rank deficiency warning.
                    w = warning( "query", obj.FitWarningID );
                    oc = onCleanup( @() warning( w ) );
                    warning( "off", obj.FitWarningID )
                    mdl = fitlm( obj.XData_, obj.YData_ );                    
                    % Update the line graphics.
                    [~, posMin] = min( obj.XData_ );
                    [~, posMax] = max( obj.XData_ );
                    set( obj.BestFitLine, ...
                        "XData", obj.XData_([posMin, posMax]), ...
                        "YData", mdl.Fitted([posMin, posMax]) )
                    % Update the equation label.
                    obj.SummaryLabel.Text = modelSummary( mdl );
                else
                    % This is the empty data case. Update the line and the
                    % label.
                    set( obj.BestFitLine, "XData", obj.XData_, ...
                        "YData", obj.YData_ )
                    obj.SummaryLabel.Text = "";
                end % if
                
                % Mark the chart clean.
                obj.ComputationRequired = false();
                
            end % if
            
            % Refresh the chart's decorative properties.
            set( obj.ScatterSeries, "CData", obj.CData, ...
                "SizeData", obj.SizeData )
            
        end % update
        
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
        
        function toggleLineVisibility( obj, s, ~ )
            %TOGGLELINEVISIBILITY Toggle the visibility of the best-fit
            %line.
            
            obj.BestFitLine.Visible = s.Value;
            
        end % toggleLineVisibility
        
        function onLineWidthSelected( obj, s, ~ )
            %ONLINEWIDTHSELECTED Update the chart when the width of the
            %best-fit line is selected interactively.
            
            obj.BestFitLine.LineWidth = s.Value;
            
        end % onLineWidthSelected
        
        function onLineStyleSelected( obj, s, ~ )
            %ONLINESTYLESELECTED Update the chart when the style of the
            %best-fit line is selected interactively.
            
            obj.BestFitLine.LineStyle = s.Value;
            
        end % onLineStyleSelected
        
        function onLineColorButtonPushed( obj, ~, ~ )
            %ONLINECOLORBUTTONPUSHED Allow the user to select a new color
            %for the best-fit line.
            
            % Prompt the user to select a color.
            c = uisetcolor();
            figure( ancestor( obj, "figure" ) ) % Restore focus
            if isequal( c, 0 )
                % Exit if the user cancels.
                return
            else
                % Update the line's color.
                obj.LineColor = c;
            end % if
            
        end % onLineColorButtonPushed
        
        function onMarkerSelected( obj, s, ~ )
            %ONMARKERSELECTED Update the chart when the scatter plot marker
            %is selected interactively.
            
            obj.ScatterSeries.Marker = s.Value;
            
        end % onMarkerSelected
        
        function onGridSelected( obj, s, ~ )
            %ONGRIDSELECTED Toggle the x/y grid lines.
            
            gridProp = s.Tag + "Grid";
            obj.Axes.(gridProp) = s.Value;
            
        end % onGridSelected
        
    end % methods ( Access = private )
    
end % class definition

function s = modelSummary( mdl )
%MODELSUMMARY Given a linear regression model mdl representing a best-fit
%line, format the equation of the line and other model properties as a
%string.

% Compute the residual norm, excluding missing observations.
res = mdl.Residuals.Raw;
resNorm = norm( res(~ismissing( res )) );
% Extract the model coefficients.
coeffs = mdl.Coefficients.Estimate;
m = coeffs(2); % Gradient
c = coeffs(1); % Intercept
if c >= 0
    interceptSign = "+";
else
    interceptSign = "-";
end % if
gradientText = num2str( m, "%g" );
interceptText = num2str( abs( c ), "%g" );
s = "Best-fit line equation:" + newline() + newline() + ...
    "y = " + gradientText + "x" + ...
    interceptSign + interceptText + newline() + newline() + ...
    "Gradient: " + gradientText + newline() + ...
    "Intercept: " + interceptSign + interceptText + newline() + ...
    "Number of observations: " + ...
    num2str( mdl.NumObservations, "%g" ) + newline() + ...
    "MSE: " + num2str( mdl.MSE, "%g" ) + newline() + ...
    "RMSE: " + num2str( mdl.RMSE, "%g" ) + newline() + ...
    "R" + char( 178 ) + ": " + ...
    num2str( mdl.Rsquared.Ordinary, "%g" ) + newline() + ...
    "Residual norm: " + num2str( resNorm, "%g" );

end % modelSummary