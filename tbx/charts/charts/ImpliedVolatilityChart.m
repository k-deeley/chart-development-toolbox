classdef ImpliedVolatilityChart < Component
    %IMPLIEDVOLATILITYCHART Chart managing 3D scattered data comprising
    %strike price, time to expiry and implied volatility, together with an
    %interpolated implied volatility surface.

    % Copyright 2018-2025 The MathWorks, Inc.

    properties ( Dependent )
        % Table of option data, comprising the time to expiry, strike
        % price, implied volatility and underlying asset price.
        OptionData(:, 4) table {mustBeOptionData}
    end % properties ( Dependent )

    properties
        % Marker for the scattered data.
        Marker(1, 1) string {mustBeMarker} = "."
        % Size of the markers.
        MarkerSize(1, 1) double {mustBePositive, mustBeFinite} = 6
        % Marker face color.
        MarkerFaceColor {validatecolor} = "k"
        % Marker edge color.
        MarkerEdgeColor {validatecolor} = "k"
    end % properties

    properties ( Dependent, AbortSet )
        % Volatility curve interpolation method.
        InterpolationMethod(1, 1) string ...
            {mustBeMember( InterpolationMethod, ...
            ["linear", "spline", "pchip", "makima", ...
            "Hagan2002", "Obloj2008"] )} = "pchip"
    end % properties ( Dependent, AbortSet )

    properties ( Dependent )
        % Visibility of the chart controls.
        Controls(1, 1) matlab.lang.OnOffSwitchState
    end % properties ( Dependent )

    properties ( Access = private )
        % Internal storage for the OptionData property.
        OptionData_(:, 4) table {mustBeOptionData} = defaultOptionData()
        % Internal storage for the InterpolationMethod property.
        InterpolationMethod_(1, 1) string ...
            {mustBeMember( InterpolationMethod_, ...
            ["linear", "spline", "pchip", "makima", ...
            "Hagan2002", "Obloj2008"] )} = "pchip"
        % Logical scalar specifying whether a computation is required.
        ComputationRequired(1, 1) logical = false
    end % properties ( Access = private )

    properties ( Dependent, Access = private )
        % Vector of unique expiry times.
        UniqueExpiryTimes(:, 1) double {mustBePositive, mustBeFinite}
        % Vector of finely subdivided strike prices.
        FineStrike(:, 1) double {mustBePositive, mustBeFinite}
        % Surface z-data (implied volatilities).
        VolatilityGrid(:, :) double {mustBePositive, mustBeFinite}
    end % properties ( Dependent, Access = private )

    properties ( Access = private, Transient, NonCopyable )
        % Chart layout.
        LayoutGrid(:, 1) matlab.ui.container.GridLayout ...
            {mustBeScalarOrEmpty}
        % Chart axes.
        Axes(:, 1) matlab.graphics.axis.Axes ...
            {mustBeScalarOrEmpty}
        % Toggle button for the chart controls.
        ToggleButton(:, 1) matlab.ui.controls.ToolbarStateButton ...
            {mustBeScalarOrEmpty}
        % Implied volatility surface.
        Surface(:, 1) matlab.graphics.primitive.Surface ...
            {mustBeScalarOrEmpty}
        % 3D scattered data, plotted using a line object.
        Line(:, 1) matlab.graphics.primitive.Line ...
            {mustBeScalarOrEmpty}
        % Implied volatility interpolation method dropdown menu.
        InterpolationMethodDropDown(:, 1) matlab.ui.control.DropDown ...
            {mustBeScalarOrEmpty}
        % Colorbar check box.
        ColorbarCheckBox(:, 1) matlab.ui.control.CheckBox ...
            {mustBeScalarOrEmpty}
    end % properties ( Access = private, Transient, NonCopyable )

    properties ( Constant, Hidden )
        % Product dependencies.
        Dependencies(1, :) string = ["MATLAB", ...
            "Statistics and Machine Learning Toolbox", ...
            "Optimization Toolbox", ...
            "Financial Toolbox", ...
            "Financial Instruments Toolbox"]
    end % properties ( Constant, Hidden )

    methods

        function value = get.OptionData( obj )

            value = obj.OptionData_;

        end % get.OptionData

        function set.OptionData( obj, value )

            % Mark the chart for an update.
            obj.ComputationRequired = true;

            % Set the internal data property.
            obj.OptionData_ = value;

        end % set.OptionData

        function value = get.InterpolationMethod( obj )

            value = obj.InterpolationMethod_;

        end % get.InterpolationMethod

        function set.InterpolationMethod( obj, value )

            % Mark the chart for an update.
            obj.ComputationRequired = true;

            % Update the dropdown menu if necessary.
            obj.InterpolationMethodDropDown.Value = value;

            % Assign the interpolation method.
            obj.InterpolationMethod_ = value;

        end % set.InterpolationMethod

        function value = get.Controls( obj )

            value = obj.ToggleButton.Value;

        end % get.Controls

        function set.Controls( obj, value )

            % Update the toggle button.
            obj.ToggleButton.Value = value;

            % Invoke the toggle button callback.
            obj.onToggleButtonPressed()

        end % set.Controls

        function value = get.UniqueExpiryTimes( obj )

            value = unique( obj.OptionData_.(1) );

        end % get.UniqueExpiryTimes

        function value = get.FineStrike( obj )

            % Take the maximal interior domain of the strike prices across
            % each unique expiry time.
            T = obj.UniqueExpiryTimes;
            for k = numel( T ) : -1 : 1
                currentTIdx = obj.OptionData_.(1) == T(k);
                K = obj.OptionData_.(2);
                [mn(k, 1), mx(k, 1)] = bounds( K(currentTIdx) );
            end % for
            mn = max( mn );
            mx = min( mx );
            value = linspace( mn, mx, 500 ).';

        end % get.FineStrike

        function sigma = get.VolatilityGrid( obj )

            % For each unique expiry time, we interpolate the corresponding
            % volatility smile over the fine strike prices.
            T = obj.UniqueExpiryTimes;
            K = obj.FineStrike;
            interpMethod = obj.InterpolationMethod;
            sigma = NaN( numel( K ), numel( T ) );

            switch interpMethod
                % Use INTERP1 to cover the basic cases.
                case {"linear", "spline", "pchip", "makima"}
                    for k = 1 : numel( T )
                        currentTIdx = obj.OptionData_.(1) == T(k);
                        currentK = obj.OptionData_{currentTIdx, 2};
                        currentVol = obj.OptionData_{currentTIdx, 3};
                        sigma(:, k) = interp1( currentK, currentVol, ...
                            K, interpMethod );
                    end % for
                    % Otherwise, we calibrate and evaluate the SABR model
                    % to obtain the implied volatilities.
                case {"Hagan2002", "Obloj2008"}
                    sigma = sabr( obj );
                otherwise
                    error( "ImpliedVolatility:InvalidInterpMethod", ...
                        "Unrecognized interpolation method %s.", ...
                        interpMethod )
            end % switch/case

            % Ensure that all computed volatilities are nonnegative.
            sigma = max( sigma, 0 );

        end % get.VolatilityGrid

    end % methods

    methods

        function obj = ImpliedVolatilityChart( namedArgs )
            %IMPLIEDVOLATILITYCHART Construct an ImpliedVolatilityChart, 
            %given optional name-value arguments.

            arguments ( Input )
                namedArgs.?ImpliedVolatilityChart 
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

        function varargout = zlabel( obj, varargin )

            [varargout{1:nargout}] = zlabel( obj.Axes, varargin{:} );

        end % zlabel

        function varargout = title( obj, varargin )

            [varargout{1:nargout}] = title( obj.Axes, varargin{:} );

        end % title

        function varargout = colorbar( obj, varargin )

            % Call the colorbar function on the chart's axes.
            [varargout{1:nargout}] = colorbar( obj.Axes, varargin{:} );

            % Ensure the colorbar check box is up-to-date.
            obj.ColorbarCheckBox.Value = ~isempty( obj.Axes.Colorbar );

        end % colorbar

        function varargout = colormap( obj, varargin )

            [varargout{1:nargout}] = colormap( obj.Axes, varargin{:} );

        end % colormap

    end % methods

    methods ( Access = protected )

        function setup( obj )
            %SETUP Initialize the chart graphics.

            % Define the layout grid.
            obj.LayoutGrid = uigridlayout( obj, [1, 2], ...
                "ColumnWidth", ["1x", "0x"] );

            % Create the chart's axes.
            obj.Axes = axes( "Parent", obj.LayoutGrid, ...
                "XGrid", "on", ...
                "YGrid", "on", ...
                "ZGrid", "on" );

            % Add a state button to show/hide the chart's controls.
            tb = axtoolbar( obj.Axes, "default" );
            iconPath = fullfile( chartsRoot(), ...
                "charts", "images", "Cog.png" );
            obj.ToggleButton = axtoolbarbtn( tb, "state", ...
                "Value", "on", ...
                "Tooltip", "Show chart controls", ...
                "Icon", iconPath, ...
                "ValueChangedFcn", @obj.onToggleButtonPressed );

            % Create the line and surface plot.
            obj.Line = line( "Parent", obj.Axes, ...
                "XData", NaN(), ...
                "YData", NaN(), ...
                "ZData", NaN(), ...
                "Marker", ".", ...
                "Color", "k", ...
                "LineStyle", "none" );
            obj.Surface = surface( obj.Axes, ...
                NaN(), NaN(), NaN(), NaN(), ...
                "FaceColor", "interp", ...
                "EdgeAlpha", 0 );
            % Configure the chart's axes.
            view( obj.Axes, 3 )

            % Add the chart controls.
            p = uipanel( "Parent", obj.LayoutGrid, ...
                "Title", "Chart Controls", ...
                "FontWeight", "bold" );
            controlLayout = uigridlayout( p, [3, 2], ...
                "ColumnWidth", ["fit", "fit"], ...
                "RowHeight", ["fit", "fit", "fit"] );
            
            % Interpolation methods dropdown menu.
            uilabel( "Parent", controlLayout, ...
                "Text", "Interpolation method:" );
            obj.InterpolationMethodDropDown = uidropdown( ...
                "Parent", controlLayout, ...
                "Items", ["linear", "spline", "pchip", ...
                "makima", "Hagan2002", "Obloj2008"], ...
                "Tooltip", ...
                "Select the implied volatility interpolation method", ...
                "Value", obj.InterpolationMethod_, ...
                "ValueChangedFcn", @obj.onInterpolationMethodSelected );
            
            % Colorbar check box.
            obj.ColorbarCheckBox = uicheckbox( ...
                "Parent", controlLayout, ...
                "Text", "Colorbar", ...
                "Tooltip", "Show/hide the colorbar", ...
                "Value", false, ...
                "ValueChangedFcn", @obj.onColorbarSelected );
            obj.ColorbarCheckBox.Layout.Column = [1, 2];

        end % setup

        function update( obj )
            %UPDATE Refresh the chart graphics.

            if obj.ComputationRequired

                % Update the discrete data markers.
                set( obj.Line, "XData", obj.OptionData_.(1), ...
                    "YData", obj.OptionData_.(2), ...
                    "ZData", obj.OptionData_.(3) )
            
                % Update the volatility surface.
                set( obj.Surface, "XData", obj.UniqueExpiryTimes, ...
                    "YData", obj.FineStrike, ...
                    "ZData", obj.VolatilityGrid, ...
                    "CData", obj.VolatilityGrid )

                % Mark the chart clean.
                obj.ComputationRequired = false;

            end % if

            % Refresh the chart's decorative properties.
            set( obj.Line, "Marker", obj.Marker, ...
                "MarkerSize", obj.MarkerSize, ...
                "MarkerFaceColor", obj.MarkerFaceColor, ...
                "MarkerEdgeColor", obj.MarkerEdgeColor )

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

        function onInterpolationMethodSelected( obj, ~, ~ )
            %ONINTERPOLATIONMETHODSELECTED Update the chart when the user
            %interactively selects an interpolation method.

            obj.InterpolationMethod = ...
                obj.InterpolationMethodDropDown.Value;

        end % onInterpolationMethodSelected

        function onColorbarSelected( obj, ~, ~ )
            %ONCOLORBARSELECTED Show/hide the colorbar.

            checked = obj.ColorbarCheckBox.Value;
            if checked
                colorbar( obj )
            else
                colorbar( obj, "off" )
            end % if

        end % onColorbarSelected

        function sigma = sabr( obj )
            %SABR Evaluate the implied volatility surface using the SABR
            %model.

            % Define the settlement date (an arbitrary date since we are
            % working with times to expiry). The exercise date will be the
            % settlement date plus the time to expiry.
            settle = datetime( 2000, 1, 1 );

            % For each unique time to expiry, we calibrate the SABR model
            % The calibrated SABR model is then used to interpolate the
            % implied volatilities across the range of finely subdivided
            % strike prices.
            T = obj.UniqueExpiryTimes;
            for k = numel( T ) : -1 : 1
                % Compute the exercise date.
                exercise = settle + years( T(k) );
                % Extract the (K, sigma) values for each expiry time.
                currentTIdx = obj.OptionData_.(1) == T(k);
                strike = obj.OptionData_{currentTIdx, 2};
                vol = obj.OptionData_{currentTIdx, 3};
                underlyingPrice = obj.OptionData_{currentTIdx, 4};
                % Calibrate the other parameters alpha, rho and nu using
                % nonlinear least squares.
                objFun = @( X ) vol - ...
                    blackvolbysabr( X(1), X(2), X(3), X(4), settle, ...
                    exercise, underlyingPrice, strike, ...
                    "Model", obj.InterpolationMethod );
                opts = optimoptions( "lsqnonlin", "Display", "off" );
                X = lsqnonlin( objFun, [0.5, 0.2, 0, 0.5], ...
                    [0, 0, -1, 0], [Inf, 1, 1, Inf], opts );
                % Interpolate the volatilities using the calibrated model.
                sigma(:, k) = blackvolbysabr( X(1), X(2), X(3), X(4), ...
                    settle, exercise, ...
                    mean( underlyingPrice ), obj.FineStrike );
            end % for

        end % sabr

    end % methods ( Access = protected )

end % classdef

function optData = defaultOptionData()
%DEFAULTOPTIONDATA Create an empty table of option data.

optData = table( 'Size', [0, 4], ...
    'VariableTypes', ["double", "double", "double", "double"], ...
    'VariableNames', ["T", "K", "Sigma", "S"] );

end % defaultOptionData

function mustBeOptionData( t )
%MUSTBEOPTIONDATA Validate that the input value t is a table containing
%option data in the required form.

if ~isempty( t )

    % Validate the required attributes of the table variables.
    expiryTime = t{:, 1};
    mustBeVector( expiryTime )
    mustBeNonnegative( expiryTime )
    mustBeFinite( expiryTime )

    strike = t{:, 2};
    mustBeVector( strike )
    mustBePositive( strike )
    mustBeFinite( strike )

    volatility = t{:, 3};
    mustBeVector( volatility )
    mustBeInRange( volatility, 0, 100, "exclude-lower" )

    assetPrice = t{:, 4};
    mustBeVector( assetPrice )
    mustBePositive( assetPrice )
    mustBeFinite( assetPrice )

end % if

end % mustBeOptionData