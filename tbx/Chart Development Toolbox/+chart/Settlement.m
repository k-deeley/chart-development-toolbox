classdef Settlement < matlab.ui.componentcontainer.ComponentContainer
    %SETTLEMENT Chart displaying option prices against strike prices.
    %A settlement chart plots option prices on the y-axis against strike
    %prices on the x-axis. The option prices comprise put prices below
    %the at-the-money (ATM) price, and call prices above the at-the-money
    %price.
    %
    % See also BLSPRICE
    %
    % Copyright 2019-2022 The MathWorks, Inc.
    
    properties ( Dependent )
        % The strike (i.e., exercise) price of the option.
        Strike(:, 1) double {mustBeFinite, mustBeNonnegative} = (85:115).'
        % The price of the underlying asset, in currency units.
        Price(1, 1) double {mustBeFinite, mustBeNonnegative} = 100
        % Annualized continuously compounded risk-free rate of return
        % over the life of the option.
        Rate(1, 1) double {mustBeFinite, ...
            mustBeInRange( Rate, 0, 1 )} = 0.05
        % The time to expiray of the option, expressed in years.
        Time(1, 1) double {mustBeFinite, mustBeNonnegative} = 0.25
        % Annualized asset price volatility.
        Volatility(1, 1) double {mustBeFinite, ...
            mustBeInRange( Volatility, 0, 1 )} = 0.5
        % Annualized continuously compounded yield of the underlying asset
        % over the life of the option.
        Yield(1, 1) double {mustBeFinite, mustBeInRange( Yield, 0, 1 )} = 0
    end % properties
    
    properties ( Dependent, SetAccess = private )
        % Call and put prices computed using the Black-Scholes model.
        OptionPrices
        % At-the-money price (call-put parity price).
        AtTheMoneyPrice
    end % properties ( Dependent, SetAccess = private )
    
    properties
        % Call curve color.
        CallColor = [0, 0.4470, 0.7410]
        % Call curve line style.
        CallLineStyle = "-"
        % Call curve line width.
        CallLineWidth = 1.5
        % Call curve marker.
        CallMarker = "."
        % Call curve marker size.
        CallMarkerSize = 12
        % Put curve color.
        PutColor = [0.85, 0.325, 0.098]
        % Put curve line style.
        PutLineStyle = "-"
        % Put curve line width.
        PutLineWidth = 1.5
        % Put curve marker.
        PutMarker = "."
        % Put curve marker size.
        PutMarkerSize = 12
        % Call-put parity line color.
        AtTheMoneyColor = "k"
        % Call-put parity line line style.
        AtTheMoneyLineStyle = "-"
        % Call-put parity line line width.
        AtTheMoneyLineWidth = 2
    end % properties
    
    properties ( Dependent )
        % Visibility of the chart controls.
        Controls(1, 1) matlab.lang.OnOffSwitchState
    end % properties ( Dependent )
    
    properties ( Access = private )
        % Internal storage for the Price property.
        Price_ = 100
        % Internal storage for the Rate property.
        Rate_ = 0.1
        % Internal storage for the Time property.
        Time_ = 0.1
        % Internal storage for the Volatility property.
        Volatility_ = 0.1
        % Internal storage for the Yield property.
        Yield_ = 0.1
        % Internal storage for the Strike property.
        Strike_ = (85:115).'
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
        % Call curve.
        CallLine(1, 1) matlab.graphics.primitive.Line
        % Put curve.
        PutLine(1, 1) matlab.graphics.primitive.Line
        % At the money line.
        AtTheMoneyLine(1, 1) matlab.graphics.chart.decoration.ConstantLine
        % Strike price edit fields.
        StrikeEditFields(3, 1) matlab.ui.control.NumericEditField
        % Underlying asset price spinner.
        PriceSpinner(1, 1) matlab.ui.control.Spinner
        % Interest rate spinner.
        RateSpinner(1, 1) matlab.ui.control.Spinner
        % Expiry time spinner.
        TimeSpinner(1, 1) matlab.ui.control.Spinner
        % Volatility spinner.
        VolatilitySpinner(1, 1) matlab.ui.control.Spinner
        % Yield spinner.
        YieldSpinner(1, 1) matlab.ui.control.Spinner
        % Update button.
        UpdateButton(1, 1) matlab.ui.control.Button
        % Default button.
        DefaultButton(1, 1) matlab.ui.control.Button
    end % properties ( Access = private, Transient, NonCopyable )
    
    properties ( Constant, Hidden )
        % Product dependencies.
        Dependencies = ["MATLAB", ...
            "Statistics and Machine Learning Toolbox", ...
            "Financial Toolbox" ]
    end % properties ( Constant, Hidden )
    
    methods
        
        function value = get.Price( obj )
            
            value = obj.Price_;
            
        end % get.Price
        
        function set.Price( obj, value )
            
            % Mark the chart for an update.
            obj.ComputationRequired = true();
            
            % Update the control.
            obj.PriceSpinner.Value = value;
            
            % Update the internal stored property.
            obj.Price_ = value;
            
        end % set.Price
        
        function value = get.Rate( obj )
            
            value = obj.Rate_;
            
        end % get.Rate
        
        function set.Rate( obj, value )
            
            % Mark the chart for an update.
            obj.ComputationRequired = true();
            
            % Update the control.
            obj.RateSpinner.Value = value;
            
            % Update the internal stored property.
            obj.Rate_ = value;
            
        end % set.Rate
        
        function value = get.Time( obj )
            
            value = obj.Time_;
            
        end % get.Time
        
        function set.Time( obj, value )
            
            % Mark the chart for an update.
            obj.ComputationRequired = true();
            
            % Update the control.
            obj.TimeSpinner.Value = value;
            
            % Update the internal stored property.
            obj.Time_ = value;
            
        end % set.Time
        
        function value = get.Volatility( obj )
            
            value = obj.Volatility_;
            
        end % get.Volatility
        
        function set.Volatility( obj, value )
            
            % Mark the chart for an update.
            obj.ComputationRequired = true();
            
            % Update the control.
            obj.VolatilitySpinner.Value = value;
            
            % Update the internal stored property.
            obj.Volatility_ = value;
            
        end % set.Volatility
        
        function value = get.Yield( obj )
            
            value = obj.Yield_;
            
        end % get.Yield
        
        function set.Yield( obj, value )
            
            % Mark the chart for an update.
            obj.ComputationRequired = true();
            
            % Update the control.
            obj.YieldSpinner.Value = value;
            
            % Update the internal stored property.
            obj.Yield_ = value;
            
        end % set.Yield
        
        function value = get.Strike( obj )
            
            value = obj.Strike_;
            
        end % get.Strike
        
        function set.Strike( obj, value )
            
            % Check that the strike prices are sorted and contain at least
            % three values.
            assert( length( value ) >= 3 && issorted( value ), ...
                "Settlement:InvalidStrike", ...
                "The strike price vector should contain at least " + ...
                "three values, and should be sorted in increasing order." )
            
            % Mark the chart for an update.
            obj.ComputationRequired = true();
            
            % Update the control.
            obj.StrikeEditFields(1).Value = value(1);
            obj.StrikeEditFields(2).Value = mean( diff( value ) );
            obj.StrikeEditFields(3).Value = value(end);
            
            % Update the internal stored property.
            obj.Strike_ = value;
            
        end % set.Strike
        
        function value = get.OptionPrices( obj )
            
            [value(:, 1), value(:, 2)] = ...
                blsprice( obj.Price_, obj.Strike_, obj.Rate_, ...
                obj.Time_, obj.Volatility_, obj.Yield_ );
            
        end % get.OptionPrices
        
        function value = get.AtTheMoneyPrice( obj )
            
            % This is derived by solving C - P = 0 for K, and from the
            % call-put parity formula:
            % C - P = S - K * exp( - ( r - q ) * T )
            % This gives the expression K = S * exp( (r - q) * T ) for the
            % at-the-money price.
            value = obj.Price_ * ...
                exp( ( obj.Rate_ - obj.Yield_ ) * obj.Time_ );
            
        end % get.AtTheMoneyPrice
        
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
            
        end % grid
        
        function varargout = legend( obj, varargin )
            
            [varargout{1:nargout}] = legend( obj.Axes, varargin{:} );
            
        end % legend
        
        function reset( obj )
            %RESET Set the default chart data.
            
            obj.Strike     = (85:0.1:115).';
            obj.Price      = 100;
            obj.Rate       = 0.05;
            obj.Time       = 0.25;
            obj.Volatility = 0.5;
            obj.Yield      = 0;
            
        end % reset
        
    end % methods
    
    methods ( Access = protected )
        
        function setup( obj )
            %SETUP Initialize the chart graphics.
            
            % Define the chart layout.
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
            
            % Create the various option plots.
            hold( obj.Axes, "on" )
            obj.CallLine = line( "Parent", obj.Axes, ...
                "XData", NaN, ...
                "YData", NaN, ...
                "DisplayName", "Call prices" );
            obj.PutLine = line( "Parent", obj.Axes, ...
                "XData", NaN, ...
                "YData", NaN, ...
                "DisplayName", "Put prices" );
            obj.AtTheMoneyLine = xline( obj.Axes, 0, ...
                "Alpha", 1, ...
                "LabelOrientation", "horizontal", ...
                "LabelHorizontalAlignment", "left", ...
                "HandleVisibility", "off" );
            hold( obj.Axes, "off" )
            
            % Add some initial annotations.
            xlabel( obj.Axes, "Strike price" )
            ylabel( obj.Axes, "Option price" )
            title( obj.Axes, "Settlement Chart" )
            grid( obj.Axes, "on" )
            legend( obj.Axes )
            
            % Add the chart controls.
            p = uipanel( "Parent", obj.LayoutGrid, ...
                "Title", "Chart Controls", ...
                "FontWeight", "bold" );
            p.Layout.Column = 2;
            verticalLayout = uigridlayout( p, [2, 1], ...
                "RowHeight", ["fit", "1x"] );
            % First, the strike price specification.
            strikeLayout = uigridlayout( verticalLayout, [3, 3], ...
                "Padding", 2, ...
                "RowSpacing", 2, ...
                "ColumnWidth", repmat( "fit", 1, 3 ), ...
                "RowHeight", repmat( "fit", 1, 3 ) );
            uilabel( strikeLayout, "Text", "Strike (K):", ...
                "HorizontalAlignment", "right" );
            uilabel( strikeLayout, "Text", "Min:", ...
                "HorizontalAlignment", "right" );
            obj.StrikeEditFields(1) = uieditfield( ...
                strikeLayout, "numeric", ...
                "Value", obj.Strike(1), ...
                "Tooltip", "Specify the minimum strike price", ...
                "Limits", [0, Inf], ...
                "UpperLimitInclusive", false() );
            lb = uilabel( strikeLayout, "Text", "Step:", ...
                "HorizontalAlignment", "right" );
            lb.Layout.Column = 2;
            obj.StrikeEditFields(2) = uieditfield( ...
                strikeLayout, "numeric", ...
                "Value", diff( obj.Strike(1:2) ), ...
                "Tooltip", ...
                "Specify the step size in the strike price vector", ...
                "Limits", [0, Inf], ...
                "LowerLimitInclusive", false(), ...
                "UpperLimitInclusive", false() );
            lb = uilabel( strikeLayout, "Text", "Max:", ...
                "HorizontalAlignment", "right" );
            lb.Layout.Column = 2;
            obj.StrikeEditFields(3) = uieditfield( ...
                strikeLayout, "numeric", ...
                "Value", obj.Strike(end), ...
                "Tooltip", "Specify the maximum strike price", ...
                "Limits", [0, Inf], ...
                "UpperLimitInclusive", false() );
            % Next, the underlying asset price.
            controlLayout = uigridlayout( verticalLayout, [8, 2], ...
                "RowHeight", repmat( "fit", 1, 8 ), ...
                "ColumnWidth", ["fit", "1x"] );
            uilabel( controlLayout, "Text", "Price (S):", ...
                "HorizontalAlignment", "right" );
            obj.PriceSpinner = uispinner( controlLayout, ...
                "Value", obj.Price, ...
                "Tooltip", "Specify the underlying asset price", ...
                "Limits", [0, Inf], ...
                "UpperLimitInclusive", false(), ...
                "Step", 1 );
            % Risk-free interest rate.
            uilabel( controlLayout, "Text", "Rate (r):", ...
                "HorizontalAlignment", "right" );
            obj.RateSpinner = uispinner( controlLayout, ...
                "Value", obj.Rate, ...
                "Tooltip", "Specify the risk-free interest rate", ...
                "Limits", [0, 1], ...
                "Step", 0.01, ...
                "ValueDisplayFormat", "%.2f" );
            % Expiry time.
            uilabel( controlLayout, "Text", "Time (T):", ...
                "HorizontalAlignment", "right" );
            obj.TimeSpinner = uispinner( controlLayout, ...
                "Value", obj.Time, ...
                "Tooltip", "Specify the expiry time", ...
                "Limits", [0, Inf], ...
                "UpperLimitInclusive", false(), ...
                "Step", 0.25, ...
                "ValueDisplayFormat", "%.2f" );
            % Volatility.
            uilabel( controlLayout, ...
                "Text", "Volatility (" + char( 963 ) + "):", ...
                "HorizontalAlignment", "right" );
            obj.VolatilitySpinner = uispinner( controlLayout, ...
                "Value", obj.Volatility, ...
                "Tooltip", "Specify the volatility", ...
                "Limits", [0, 1], ...
                "Step", 0.01, ...
                "ValueDisplayFormat", "%.2f" );
            % Yield.
            uilabel( controlLayout, "Text", "Yield (q):", ...
                "HorizontalAlignment", "right" );
            obj.YieldSpinner = uispinner( controlLayout, ...
                "Value", obj.Yield, ...
                "Tooltip", "Specify the yield", ...
                "Limits", [0, 1], ...
                "Step", 0.01, ...
                "ValueDisplayFormat", "%.2f" );
            % Button to update the chart data.
            obj.UpdateButton = uibutton( controlLayout, ...
                "Text", char( 9654 ) + " Update ", ...
                "Tooltip", ...
                "Set the settlement chart data " + ...
                "using the specified values", ...
                "ButtonPushedFcn", @obj.onUpdateButtonPushed );
            obj.UpdateButton.Layout.Column = [1, 2];
            % Button to revert to the default values.
            obj.DefaultButton = uibutton( controlLayout, ...
                "Text", char( 8635 ) + " Set default values", ...
                "Tooltip", ...
                "Set the default settlement chart data values", ...
                "ButtonPushedFcn", @obj.onDefaultButtonPushed );
            obj.DefaultButton.Layout.Column = [1, 2];
            
        end % setup
        
        function update( obj )
            %UPDATE Refresh the chart graphics.
            
            if obj.ComputationRequired
                % Update the call price curve.
                callIdx = obj.Strike >= obj.AtTheMoneyPrice;
                set( obj.CallLine, "XData", obj.Strike(callIdx), ...
                    "YData", obj.OptionPrices(callIdx, 1) )
                % Update the put price curve.
                putIdx = obj.Strike <= obj.AtTheMoneyPrice;
                set( obj.PutLine, "XData", obj.Strike(putIdx), ...
                    "YData", obj.OptionPrices(putIdx, 2) )
                % Update the at-the-money line.
                set( obj.AtTheMoneyLine, "Value", obj.AtTheMoneyPrice, ...
                    "Label", "At the money price: " + ...
                    num2str( obj.AtTheMoneyPrice, "%.2f" ) )
                % Mark the chart clean.
                obj.ComputationRequired = false();
            end % if
            
            % Update the chart's decorative properties.
            set( obj.CallLine, "LineStyle", obj.CallLineStyle, ...
                "LineWidth", obj.CallLineWidth, ...
                "Color", obj.CallColor, ...
                "Marker", obj.CallMarker, ...
                "MarkerSize", obj.CallMarkerSize )
            set( obj.PutLine, "LineStyle", obj.PutLineStyle, ...
                "LineWidth", obj.PutLineWidth, ...
                "Color", obj.PutColor, ...
                "Marker", obj.PutMarker, ...
                "MarkerSize", obj.PutMarkerSize )
            set( obj.AtTheMoneyLine, ...
                "LineStyle", obj.AtTheMoneyLineStyle, ...
                "Color", obj.AtTheMoneyColor, ...
                "LineWidth", obj.AtTheMoneyLineWidth )
            
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
        
        function onUpdateButtonPushed( obj, ~, ~ )
            %ONUPDATEBUTTONPUSHED Take the user-entered data from the
            %control interface and update the chart.
            
            % Issue an alert if the strike price parameters are invalid.
            kMin = obj.StrikeEditFields(1).Value;
            kStep = obj.StrikeEditFields(2).Value;
            kMax = obj.StrikeEditFields(3).Value;
            try
                obj.Strike = kMin:kStep:kMax;
            catch
                f = ancestor( obj, "figure" );
                uialert( f, ...
                    "Please check the strike price parameters (minimum, step size and maximum).", ...
                    "Invalid strike price parameters" )
                return
            end % try/catch
            
            % Update the chart with the remaining parameter values taken
            % from the user-facing controls.
            set( obj, "Price", obj.PriceSpinner.Value, ...
                "Rate", obj.RateSpinner.Value, ...
                "Time", obj.TimeSpinner.Value, ...
                "Volatility", obj.VolatilitySpinner.Value, ...
                "Yield", obj.YieldSpinner.Value )
            
        end % onUpdateButtonPushed
        
        function onDefaultButtonPushed( obj, ~, ~ )
            %ONDEFAULTBUTTONPUSHED Revert to the default chart data values.
            
            reset( obj )
            
        end % onDefaultButtonPushed
        
    end % methods ( Access = private )
    
end % class definition