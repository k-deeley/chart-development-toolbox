classdef SnailTrailChart < matlab.ui.componentcontainer.ComponentContainer
    %SNAILTRAIL Chart for displaying excess return against tracking error
    %for a given asset return series relative to a given benchmark return
    %series.
    %
    % Copyright 2018-2022 The MathWorks, Inc.
    
    properties ( Dependent )
        % Chart data, comprising a timetable with two return series.
        Returns(:, 2) timetable {mustBeAssetAndBenchmarkReturns}
        % Number of points in the trail, including the head.
        TrailLength(1, 1) double {mustBeInteger, mustBePositive} = 5
        % Index of the snail's current position.
        CurrentIndex(1, 1) double {mustBeInteger, mustBePositive} = 1
        % Current date.
        CurrentDate(1, 1) datetime
        % Number of observations used for the window size in the rolling
        % excess return and tracking error computation.
        Period(1, 1) double {mustBeInteger, mustBePositive} = 5
    end % properties ( Dependent )
    
    properties ( Dependent )
        % Visibility of the chart controls.
        Controls(1, 1) matlab.lang.OnOffSwitchState
    end % properties ( Dependent )
    
    properties ( Dependent, SetAccess = private )
        % Performance statistics. This is a table comprising a datetime
        % vector of end dates for the rolling periods, and three double
        % vectors containing the excess return, tracking error and
        % information ratio for each period.
        PerformanceStatistics
    end % properties ( Dependent, SetAccess = private )
    
    properties ( Access = private )
        % Backing property for the chart data.
        Returns_ = defaultReturnsData()
        % Backing property for the trail length.
        TrailLength_ = 5
        % Backing property for the current index.
        CurrentIndex_ = 1
        % Backing property for the period.
        Period_ = 5
        % Logical scalar specifying whether a computation is required.
        ComputationRequired = false
    end % properties ( Access = private )
    
    properties ( Access = private, Transient, NonCopyable )
        % Chart layout.
        LayoutGrid(1, 1) matlab.ui.container.GridLayout
        % Chart axes.
        Axes(1, 1) matlab.graphics.axis.Axes
        % Toggle button for the chart controls.
        ToggleButton(1, 1) matlab.ui.controls.ToolbarStateButton
        % 2D scatter series for the excess return vs. tracking error.
        ScatterSeries(1, 1) matlab.graphics.chart.primitive.Scatter
        % Line object for the snail head.
        Head(1, 1) matlab.graphics.primitive.Line
        % Line object for the trail.
        Trail(1, 1) matlab.graphics.primitive.Line
        % Line objects for the axes crosshair.
        CrossHair(2, 1) matlab.graphics.primitive.Line
        % Text box for the performance statistics.
        TextBox(1, 1) matlab.graphics.primitive.Text
        % Colorbar check box.
        ColorbarCheckBox(1, 1) matlab.ui.control.CheckBox
        % Spinner for the number of steps.
        NumStepsSpinner(1, 1) matlab.ui.control.Spinner
        % Button to move the head of the trail.
        StepButton(1, 1) matlab.ui.control.Button
        % Button to reset the head of the trail.
        RewindButton(1, 1) matlab.ui.control.Button
        % Button to animate the snail trail.
        AnimateButton(1, 1) matlab.ui.control.Button
    end % properties ( Access = private, Transient, NonCopyable )
    
    properties ( Constant, Hidden )
        % Product dependencies.
        Dependencies = "MATLAB"
    end % properties ( Constant, Hidden )
    
    methods
        
        function value = get.Returns( obj )
            
            value = obj.Returns_;
            
        end % get.Returns
        
        function set.Returns( obj, value )
            
            % Mark the chart for an update.
            obj.ComputationRequired = true;
            
            % Store the internal data.
            obj.Returns_ = value;
            
            % Rewind the snail trail.
            rewind( obj )
            
        end % set.Returns
        
        function value = get.TrailLength( obj )
            
            value = obj.TrailLength_;
            
        end % get.TrailLength
        
        function set.TrailLength( obj, value )
            
            % Check the proposed trail length.
            h = height( obj.PerformanceStatistics );
            assert( value <= h, "SnailTrail:InvalidTrailLength", ...
                "The trail length cannot exceed the height of the " + ...
                "PerformanceStatistics table, %d.", h )
            
            % Mark the chart for an update.
            obj.ComputationRequired = true;
            
            % Set the internal property.
            obj.TrailLength_ = value;
            
        end % set.TrailLength
        
        function value = get.CurrentIndex( obj )
            
            value = obj.CurrentIndex_;
            
        end % get.CurrentIndex
        
        function set.CurrentIndex( obj, value )
            
            % Check the proposed index.
            h = height( obj.PerformanceStatistics );
            assert( value <= h, "SnailTrail:InvalidCurrentIndex", ...
                "The current index cannot exceed the height of the " + ...
                "PerformanceStatistics table, %d.", h )
            
            % Mark the chart for an update.
            obj.ComputationRequired = true;
            
            % Set the internal property.
            obj.CurrentIndex_ = value;
            
        end % set.CurrentIndex
        
        function value = get.CurrentDate( obj )
            
            value = obj.PerformanceStatistics. ...
                PeriodEndDate(obj.CurrentIndex_);
            
        end % get.CurrentDate
        
        function set.CurrentDate( obj, value )
            
            % Validate the new date.
            [dateInRange, idx] = ismember( value, ...
                obj.PerformanceStatistics.PeriodEndDate );
            assert( dateInRange, "SnailTrail:InvalidCurrentDate", ...
                "The current date must be chosen from the " + ...
                "available period end dates." )
            
            % Mark the chart for an update.
            obj.ComputationRequired = true;
            
            % Update the current index.
            obj.CurrentIndex = idx;
            
        end % set.CurrentDate
        
        function value = get.Period( obj )
            
            value = obj.Period_;
            
        end % get.Period
        
        function set.Period( obj, value )
            
            % Check the proposed period.
            h = height( obj.PerformanceStatistics );
            assert( value <= h/2, "SnailTrail:InvalidPeriod", ...
                "The current index cannot exceed half the height " + ...
                "of the PerformanceStatistics table, %d.", h )
            
            % Mark the chart for an update.
            obj.ComputationRequired = true;
            
            % Set the internal property.
            obj.Period_ = value;
            
        end % set.Period
        
        function value = get.Controls( obj )
            
            value = obj.ToggleButton.Value;
            
        end % get.Controls
        
        function set.Controls( obj, value )
            
            % Update the toggle button.
            obj.ToggleButton.Value = value;
            % Invoke the toggle button callback.
            obj.onToggleButtonPressed()
            
        end % set.Controls
        
        function value = get.PerformanceStatistics( obj )
            
            % Period end dates.
            PeriodEndDate = obj.Returns_.Properties.RowTimes;
            PeriodEndDate = PeriodEndDate(obj.Period_:end);
            % Window size.
            n = obj.Period_;
            % Asset and benchmark.
            benchmark = obj.Returns_{:, 1};
            asset = obj.Returns_{:, 2};
            % Rolling mean difference.
            ExcessReturn = double.empty( 0, 1 );
            for k = height( obj.Returns_ ) : -1 : n
                ExcessReturn(k-n+1, 1) = ...
                    mean( asset(k-n+1:k) - benchmark(k-n+1:k) );
            end % for
            % Rolling std difference.
            TrackingError = double.empty( 0, 1 );
            for k = height( obj.Returns_ ) : -1 : n
                TrackingError(k-n+1, 1) = ...
                    std( asset(k-n+1:k) - benchmark(k-n+1:k) );
            end % for
            % Information ratio.
            InformationRatio = ExcessReturn ./ TrackingError;
            % Place the results in a timetable.
            value = timetable( PeriodEndDate, ExcessReturn, ...
                TrackingError, InformationRatio );
            
        end % get.PerformanceStatistics
        
        function step( obj, numSteps )
            %STEP Increment/decrement the trail by the given number of
            %steps.
            
            % Validate the number of steps.
            if nargin < 2
                numSteps = 1;
            else
                validateattributes( numSteps, "double", ...
                    ["scalar", "real", "finite", "integer"], ...
                    "step", "the number of steps" )
            end % if
            % Saturate if the number of steps is too large or too small.
            if numSteps >= 0
                obj.CurrentIndex = min( obj.CurrentIndex_ + numSteps, ...
                    height( obj.PerformanceStatistics ) );
            else
                obj.CurrentIndex = max( 1, obj.CurrentIndex_ + numSteps );
            end % if
            
        end % step
        
        function rewind( obj )
            %REWIND Rewind the snail trail.
            
            obj.CurrentIndex = 1;
            
        end % rewind
        
        function animate( obj )
            %ANIMATE Animate the snail trail.
            
            for k = 1:height( obj.PerformanceStatistics )
                obj.CurrentIndex = k;
                drawnow()
            end % for
            
        end % animate
        
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
        
        function varargout = colorbar( obj, varargin )
            
            % Call the colorbar function on the chart's axes.
            [varargout{1:nargout}] = colorbar( obj.Axes, varargin{:} );
            % Ensure the colorbar check box is up-to-date.
            hasbar = ~isempty( obj.Axes.Colorbar );
            obj.ColorbarCheckBox.Value = hasbar;
            % Update the label if necessary.
            if hasbar
                obj.Axes.Colorbar.Label.String = "Information ratio";
            end % if
            
        end % colorbar
        
        function varargout = colormap( obj, varargin )
            
            % Call the colormap function on the chart's axes.
            [varargout{1:nargout}] = colormap( obj.Axes, varargin{:} );
            
        end % colormap        
        
    end % methods
    
    methods ( Access = protected )
        
        function setup( obj )
            %SETUP Initialize the chart graphics.
            
            % Define the layout grid.
            obj.LayoutGrid = uigridlayout( obj, [1, 2], ...
                "ColumnWidth", ["1x", "fit"] );
            
            % Create the chart's axes.            
            obj.Axes = axes( "Parent", obj.LayoutGrid, ...
                "XGrid", "on", ...
                "YGrid", "on", ...
                "Color", [0.95, 0.95, 0.95] );
            
            % Add a state button to show/hide the chart's controls.
            tb = axtoolbar( obj.Axes, "default" );
            obj.ToggleButton = axtoolbarbtn( tb, "state", ...
                "Value", "on", ...
                "Tooltip", "Hide chart controls", ...
                "Icon", "Cog.png", ...
                "ValueChangedFcn", @obj.onToggleButtonPressed );
            
            % Add default annotations.
            xlabel( obj.Axes, "Tracking error" )
            ylabel( obj.Axes, "Excess return" )
            title( obj.Axes, "SnailTrail Chart" )
            
            % Add the scatter plot.
            hold( obj.Axes, "on" )
            obj.ScatterSeries = scatter( obj.Axes, [], [], 12, [], ...
                "o", "filled" );
            hold( obj.Axes, "off" )
            
            % Create the trail.
            obj.Trail = line( "Parent", obj.Axes, ...
                "XData", [], ...
                "YData", [], ...
                "Color", [0.8, 0, 0], ...
                "Marker", ".", ...
                "MarkerSize", 12, ...
                "LineWidth", 1.5 );
            
            % Create the head.
            obj.Head = line( "Parent", obj.Axes, ...
                "XData", [], ...
                "YData", [], ...
                "Marker", "s", ...
                "MarkerEdgeColor", "k", ...
                "MarkerFaceColor", "m" );
            
            % Draw the crosshair to create the appearance of four
            % quadrants.
            obj.CrossHair(1) = line( "Parent", obj.Axes, ...
                "XData", [NaN, NaN], ...
                "YData", [0, 0], ...
                "Color", "k", ...
                "LineWidth", 2.5 );
            obj.CrossHair(2) = line( "Parent", obj.Axes, ...
                "XData", [0, 0], ...
                "YData", [NaN, NaN], ...
                "Color", "k", ...
                "LineWidth", 2.5 );
            
            % Add the colorbar.
            c = colorbar( obj );
            c.Label.String = "Information ratio";
            
            % Create the text box.
            obj.TextBox = text( NaN, NaN, "", ...
                "Parent", obj.Axes );
            
            % Add the chart control panel and layout.
            p = uipanel( "Parent", obj.LayoutGrid, ...
                "Title", "Chart Controls", ...
                "FontWeight", "bold" );
            p.Layout.Column = 2;
            controlLayout = uigridlayout( p, [5, 2], ...
                "RowHeight", repmat( "fit", 5, 1 ) );
            
            % Colorbar check box.
            obj.ColorbarCheckBox = uicheckbox( ...
                "Parent", controlLayout, ...
                "Interruptible", "off", ...
                "BusyAction", "cancel", ...
                "Text", "Colorbar", ...
                "Tooltip", "Show/hide the colorbar", ...
                "Value", true, ...
                "ValueChangedFcn", @obj.onColorbarSelected );
            obj.ColorbarCheckBox.Layout.Column = [1, 2];
            
            % Spinner for the number of steps.
            uilabel( "Parent", controlLayout, ...
                "Text", "Number of steps:" );
            obj.NumStepsSpinner = uispinner( "Parent", controlLayout, ...
                "Value", 1, ...
                "Step", 1, ...
                "RoundFractionalValues", "on", ...
                "Tooltip", "Select the number of steps", ...
                "ValueDisplayFormat", "%d" );
            
            % Button for taking steps.
            obj.StepButton = uibutton( controlLayout, "push", ...
                "Interruptible", "off", ...
                "BusyAction", "cancel", ...
                "Text", char( 10139 ) + " Step ", ...
                "Tooltip", "Take the specified number of steps in the trail", ...
                "ButtonPushedFcn", @obj.onStepButtonPushed );
            obj.StepButton.Layout.Column = [1, 2];
            
            % Rewind button.
            obj.RewindButton = uibutton( controlLayout, "push", ...
                "Interruptible", "off", ...
                "BusyAction", "cancel", ...
                "Text", char( 9194 ) + " Rewind", ...
                "Tooltip", "Rewind the trail back to the starting point", ...
                "ButtonPushedFcn", @obj.onRewindButtonPushed );
            obj.RewindButton.Layout.Column = [1, 2];
            
            % Animate button.
            obj.AnimateButton = uibutton( controlLayout, "push", ...
                "Interruptible", "off", ...
                "BusyAction", "cancel", ...
                "Text", char( 9654 ) + " Animate", ...
                "Tooltip", "Animate the entire snail trail", ...
                "ButtonPushedFcn", @obj.onAnimateButtonPushed );
            obj.AnimateButton.Layout.Column = [1, 2];
            
        end % setup
        
        function update( obj )
            %UPDATE Refresh the chart graphics.
            
            if obj.ComputationRequired
                
                % Reset the cross hairs.
                obj.CrossHair(1).XData = NaN( 1, 2 );
                obj.CrossHair(2).YData = NaN( 1, 2 );
                
                % Scatter series.
                set( obj.ScatterSeries, ...
                    "XData", obj.PerformanceStatistics.TrackingError, ...
                    "YData", obj.PerformanceStatistics.ExcessReturn, ...
                    "CData", obj.PerformanceStatistics.InformationRatio )
                
                % Trail.
                p = obj.CurrentIndex_;
                t = obj.TrailLength_;
                if p >= t
                    set( obj.Trail, ...
                        "XData", ...
                        obj.PerformanceStatistics.TrackingError(p-t+1:p), ...
                        "YData", ...
                        obj.PerformanceStatistics.ExcessReturn(p-t+1:p) )
                else
                    set( obj.Trail, "XData", ...
                        obj.PerformanceStatistics.TrackingError(1:p), ...
                        "YData", ...
                        obj.PerformanceStatistics.ExcessReturn(1:p) )
                end % if
                
                % Head.
                set( obj.Head, "XData", ...
                    obj.PerformanceStatistics.TrackingError(p), ...
                    "YData", ...
                    obj.PerformanceStatistics.ExcessReturn(p) )
                
                % Update the text box.
                x = obj.Axes.XLim(1) + 0.005;
                y = obj.Axes.YLim(2) - 0.10 * diff( obj.Axes.YLim );
                d = obj.CurrentDate;
                idx = obj.CurrentIndex_;
                er = obj.PerformanceStatistics.ExcessReturn(idx);
                te = obj.PerformanceStatistics.TrackingError(idx);
                ir = obj.PerformanceStatistics.InformationRatio(idx);
                set( obj.TextBox, "Position", [x, y, 0], ...
                    "String", ["Date: " + string( d ); ...
                    "Excess return: " + num2str( er ); ...
                    "Tracking error: " + num2str( te ); ...
                    "Information ratio: " + num2str( ir )] )
                
                % Update the cross hairs.
                obj.CrossHair(1).XData = obj.Axes.XLim;
                obj.CrossHair(2).YData = obj.Axes.YLim;
                
                % Mark the chart clean.
                obj.ComputationRequired = false;
                
            end % if
            
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
        
        function onColorbarSelected( obj, ~, ~ )
            %ONCOLORBARSELECTED Show/hide the colorbar.
            
            checked = obj.ColorbarCheckBox.Value;
            if checked
                colorbar( obj )
            else
                colorbar( obj, "off" )
            end % if
            
        end % onColorbarSelected
        
        function onStepButtonPushed( obj, ~, ~ )
            %ONSTEPBUTTONPUSHED Call the step() method.
            
            step( obj, obj.NumStepsSpinner.Value )
            
        end % onStepButtonPushed
        
        function onRewindButtonPushed( obj, ~, ~ )
            %ONREWINDBUTTONPUSHED Call the rewind() method.
            
            rewind( obj )
            
        end % onRewindButtonPushed
        
        function onAnimateButtonPushed( obj, ~, ~ )
            %ONANIMATEBUTTONPUSHED Call the animate() method.
            
            obj.AnimateButton.Enable = "off";
            animate( obj )
            obj.AnimateButton.Enable = "on";            
            
        end % onAnimateButtonPushed
        
    end % methods ( Access = private )
    
end % class definition

function rets = defaultReturnsData()
%DEFAULTRETURNSDATA Create an empty timetable of returns data.

Date = datetime.empty( 0, 1 );
Asset = double.empty( 0, 1 );
Benchmark = double.empty( 0, 1 );
rets = timetable( Date, Asset, Benchmark );

end % defaultReturnsData

function mustBeAssetAndBenchmarkReturns( tt )
%MUSTBEASSETANDBENCHMARKRETURNS Validate the given input data.

if ~isempty( tt )
    % Check that we have enough data.
    assert( height( tt ) >= 10, "SnailTrail:ShortData", ...
        "At least 10 observations are required." )
    
    % Check the dates and the individual variables.
    d = tt.Properties.RowTimes;
    assert( isa( d, "datetime" ) && issorted( d ), ...
        "SnailTrail:InvalidDates", ...
        "Timetable row times must be increasing datetime values." )
    names = ["asset", "benchmark"];
    for k = [1, 2]
        validateattributes( tt{:, k}, "double", ["real", "finite"], ...
            "SnailTrail", "the " + names(k) + " series" )
    end % for
    
end % if

end % mustBeAssetAndBenchmarkReturns