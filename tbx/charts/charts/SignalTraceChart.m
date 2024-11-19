classdef SignalTraceChart < matlab.graphics.chartcontainer.ChartContainer
    %SIGNALTRACECHART Chart for managing a collection of non-overlapping
    %signal traces plotted against a numeric time vector.

    % Copyright 2018-2025 The MathWorks, Inc.

    properties ( Dependent )
        % Chart time data.
        Time(:, 1) double {mustBeReal, mustBeFinite, mustBeIncreasing}
        % Chart signal data.
        SignalData(:, :) double {mustBeReal}
    end % properties ( Dependent )

    properties
        % Width of the signal traces.
        LineWidth(1, 1) double {mustBePositive, mustBeFinite} = 1.5
        % Font size used for the x-axis.
        XAxisFontSize(1, 1) double {mustBePositive, mustBeFinite} = 10
    end % properties

    properties ( Access = private, Transient, NonCopyable )
        % Chart axes.
        Axes(:, 1) matlab.graphics.axis.Axes {mustBeScalarOrEmpty}
        % Signal trace line objects.
        SignalLines(:, 1) matlab.graphics.primitive.Line
    end % properties ( Access = private, Transient, NonCopyable )

    properties ( Access = private )
        % Internal storage for the Time property.
        Time_(:, 1) double {mustBeReal, mustBeFinite, ...
            mustBeIncreasing} = double.empty( 0, 1 )
        % Internal storage for the SignalData property.
        SignalData_(:, :) double {mustBeReal} = double.empty( 0, 1 )
        % Logical scalar specifying whether a computation is required.
        ComputationRequired(1, 1) logical = false
    end % properties ( Access = private )

    properties ( Dependent, Access = private )
        % Translated signal data, adapted for display on the chart.
        OffsetSignalData(:, :) double {mustBeReal, mustBeFinite}
    end % properties ( Dependent, Access = private )

    properties ( Constant, Hidden )
        % Product dependencies.
        Dependencies(1, :) string = "MATLAB"
    end % properties ( Constant, Hidden )

    methods

        function value = get.Time( obj )

            value = obj.Time_;

        end % get.Time

        function set.Time( obj, value )

            % Mark the chart for an update.
            obj.ComputationRequired = true;

            % Current data lengths.
            nT = numel( value );
            nS = size( obj.SignalData_, 1 );

            % Decide how to proceed based on the data lengths.
            if nT > nS
                % Pad the existing signal data.
                obj.SignalData_(end+1:nT, :) = NaN;
            else
                % Truncate the existing signal data.
                obj.SignalData_ = obj.SignalData_(1:nT, :);
            end % if

            % Set the internal time.
            obj.Time_ = value(:);

        end % set.Time

        function value = get.SignalData( obj )

            value = obj.SignalData_;

        end % get.SignalData

        function set.SignalData( obj, value )

            % Mark the chart for an update.
            obj.ComputationRequired = true;

            % Current data lengths.
            nT = numel( obj.Time_ );
            nS = size( value, 1 );

            % Decide how to proceed based on the data lengths.
            if nS > nT
                % Pad the existing time data.
                obj.Time_(end+1:nS, :) = NaN;
            else
                % Truncate the existing time data.
                obj.Time_ = obj.Time_(1:nS, :);
            end % if

            % Set the internal signal data.
            obj.SignalData_ = value;

        end % set.SignalData

        function value = get.OffsetSignalData( obj )

            % Rescale the data, and then for each signal, offset it from
            % the previous one, leaving a small gap. Constant signals are
            % not rescaled.

            % Identify the constant signals.
            constSigIdx = all( diff( obj.SignalData_ ) == 0 )  | ...
                all( isnan( obj.SignalData_ ) );
            % Apply the z-score transformation to the non-constant signals.
            value = obj.SignalData_;
            nonConstantSignals = obj.SignalData_(:, ~constSigIdx);
            value(:, ~constSigIdx) = ...
                (nonConstantSignals - ...
                mean( nonConstantSignals, "omitnan" )) ./ ...
                std( nonConstantSignals, "omitnan" );

            % Cumulatively offset each signal from the previous one,
            % leaving a gap of size 0.5 between each pair of consecutive
            % signals.
            for k = 2:size( value, 2 )
                value(:, k) = value(:, k) + max( value(:, k-1) ) + ...
                    abs( min( value(:, k) ) ) + 0.5;
            end % for

        end % get.OffsetSignalData

    end % methods

    methods

        function obj = SignalTraceChart( namedArgs )
            %SIGNALTRACECHART Construct a SignalTraceChart object, given
            %optional name-value arguments.

            arguments ( Input )
                namedArgs.?SignalTraceChart
            end % arguments ( Inputs )

            % Call the superclass constructor.
            f = figure( "Visible", "off" );
            figureCleanup = onCleanup( @() delete( f ) );
            obj@matlab.graphics.chartcontainer.ChartContainer( ...
                "Parent", f )
            obj.Parent = [];

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

    end % methods

    methods ( Access = protected )

        function setup( obj )
            %SETUP Initialize the chart graphics.

            % Create the chart graphics.
            obj.Axes = axes( "Parent", obj.getLayout(), ...
                "Color", [0.0, 0.5, 0.5], ...
                "XGrid", "on", ...
                "YGrid", "on", ...
                "YTickLabel", [], ...
                "GridColor", "w" );

        end % setup

        function update( obj )

            if obj.ComputationRequired

                % Update the signal trace lines with the new data.
                nTraces = size( obj.SignalData_, 2 );
                nLines = numel( obj.SignalLines );
                % If we have more traces, then we need to create new line
                % objects.
                if nTraces >= nLines
                    nToAdd = nTraces - nLines;
                    for k = 1 : nToAdd
                        obj.SignalLines(end+1, 1) = line( ...
                            "Parent", obj.Axes, ...
                            "XData", [], ...
                            "YData", [], ...
                            "Color", "y", ...
                            "LineWidth", 1.5 );
                    end % for
                    % Otherwise, we need to delete the unneeded line
                    % objects and remove their references from the chart.
                else
                    nToRemove = nLines - nTraces;
                    delete( obj.SignalLines(end-nToRemove+1:end) );
                    obj.SignalLines = obj.SignalLines(1:end-nToRemove);
                end % if

                % Refresh the line x and y data.
                for k = 1:nTraces
                    set( obj.SignalLines(k), "XData", obj.Time_, ...
                        "YData", obj.OffsetSignalData(:, k) );
                end % for

                % Adjust the axes' y-limits.
                if ~all( isnan( obj.OffsetSignalData(:) ) )
                    [mn, mx] = bounds( obj.OffsetSignalData(:) );
                    obj.Axes.YLim = [mn - 0.5, mx + 0.5];
                end % if

                % Adjust the axes' x-limits.
                if ~all( isnan( obj.Time_ ) )
                    [mn, mx] = bounds( obj.Time_ );
                    obj.Axes.XLim = [mn, mx];
                end % if

                % Mark the chart clean.
                obj.ComputationRequired = false;

            end % if

            % Refresh the chart's decorative properties.
            set( obj.SignalLines, "LineWidth", obj.LineWidth )
            obj.Axes.XAxis.FontSize = obj.XAxisFontSize;

        end % update

    end % methods ( Access = protected )

end % classdef