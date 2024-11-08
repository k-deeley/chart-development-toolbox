classdef LineSelectorChart < matlab.graphics.chartcontainer.ChartContainer
    %LINESELECTOR Chart displaying a collection of line plots, possibly on
    %different scales.
    %
    % Copyright 2018-2022 The MathWorks, Inc.
    
    properties ( Dependent )
        % Chart x-data.
        XData(:, 1) double {mustBeReal}
        % Chart y-data.
        YData(:, :) double {mustBeReal}
        % Index of the selected line.
        SelectedLineIndex(1, 1) double {mustBeInteger, mustBeNonnegative}
    end % properties ( Dependent )
    
    properties
        % Axes x-grid.
        XGrid = "on"
        % Axes y-grid.
        YGrid = "on"
    end % properties
    
    properties ( Dependent )
        % Color of the selected line.
        SelectedColor
        % Color of the unselected line or lines.
        TraceColor
    end % properties ( Dependent )
    
    properties ( Access = private )
        % Internal storage for the XData property.
        XData_ = double.empty( 0, 1 )
        % Internal storage for the YData property.
        YData_ = double.empty( 0, 1 )
        % Internal storage for the SelectedLineIndex property.
        SelectedLineIndex_ = 0
        % Logical scalar specifying whether a computation is required.
        ComputationRequired = false
        % Internal storage for the SelectedColor property.
        SelectedColor_ = [0, 0.447, 0.741]
        % Internal storage for the TraceColor property.
        TraceColor_ = [0.85, 0.85, 0.85]
    end % properties ( Access = private )
    
    properties ( Dependent, Access = private )
        % Chart y-data, rescaled columnwise to lie in the range [0, 1].
        YDataScaled
        % Columnwise ranges.
        YDataRange
        % Columnwise minima.
        YDataMin
    end % properties ( Dependent, Access = private )
    
    properties ( Access = private, Transient, NonCopyable )
        % Chart axes.
        Axes(1, 1) matlab.graphics.axis.Axes
        % Reset button.
        ResetButton(1, 1) matlab.ui.controls.ToolbarPushButton
        % Line objects.
        Lines
    end % properties ( Access = private, Transient, NonCopyable )
    
    properties ( Constant, Hidden )
        % Product dependencies.
        Dependencies = "MATLAB"
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
            nY = size( obj.YData_, 1 );
            
            if nX < nY
                % Truncate the y-data if the new x-data is shorter.
                obj.YData_(nX+1:end, :) = [];
            else
                % Otherwise, pad the y-data with NaNs.
                obj.YData_(end+1:nX, :) = NaN();
            end % if
            
            % Set the internal x-data.
            obj.XData_ = value;
            
        end % set.XData
        
        function value = get.YData( obj )
            
            value = obj.YData_;
            
        end % get.YData
        
        function set.YData( obj, value )
            
            % Mark the chart for an update.
            obj.ComputationRequired = true;
            
            % Decide how to modify the chart data.
            nX = numel( obj.XData_ );
            nY = size( value, 1 );
            
            if nY < nX
                % Truncate the x-data if the new y-data is shorter.
                obj.XData_(nY+1:end) = [];
            else
                % Otherwise, pad the x-data with NaNs.
                obj.XData_(end+1:nY) = NaN();
            end % if
            
            % Set the internal y-data.
            if isvector( value )
                obj.YData_ = value(:);
            else
                obj.YData_ = value;
            end % if
            
        end % set.YData
        
        function value = get.YDataScaled( obj )
            
            value = (obj.YData_ - obj.YDataMin) ./ obj.YDataRange;
            
        end % get.YDataScaled
        
        function value = get.YDataRange( obj )
            
            value = max( obj.YData_, [], 1 ) - obj.YDataMin;
            
        end % get.YDataRange
        
        function value = get.YDataMin( obj )
            
            value = min( obj.YData_, [], 1 );
            
        end % get.YDataMin
        
        function value = get.SelectedColor( obj )
            
            value = obj.SelectedColor_;
            
        end % get.SelectedColor
        
        function set.SelectedColor( obj, value )
            
            % Set the property value.
            obj.SelectedColor_ = validatecolor( value );
            % Update the selected line if necessary.
            selectedLineIdx = obj.SelectedLineIndex_;
            if selectedLineIdx > 0
                obj.Lines(selectedLineIdx).Color = value;
                obj.Axes.YColor = value;
            end % if
            
        end % set.SelectedColor
        
        function value = get.TraceColor( obj )
            
            value = obj.TraceColor_;
            
        end % get.TraceColor
        
        function set.TraceColor( obj, value )
            
            % Set the property value.
            obj.TraceColor_ = validatecolor( value );
            % Update the unselected line(s) if necessary.
            unselectedLineIdx = setdiff( 1:numel( obj.Lines ), ...
                obj.SelectedLineIndex_ );
            set( obj.Lines(unselectedLineIdx), "Color", value )
            
        end % set.TraceColor
        
        function value = get.SelectedLineIndex( obj )
            
            value = obj.SelectedLineIndex_;
            
        end % get.SelectedLineIndex
        
        function set.SelectedLineIndex( obj, value )
            
            % Reset the chart if the user specifies a zero value.
            if value == 0
                obj.SelectedLineIndex_ = 0;
                deselect( obj )
            else
                % Otherwise, select the specified line.
                numLines = numel( obj.Lines );
                assert( value <= numLines, ...
                    "LineSelector:InvalidLineIndex", ...
                    "The SelectedLineIndex property must be a nonnegative scalar integer not exceeding the number of lines, %d.", ...
                    numLines )
                % Set the internal value.
                obj.SelectedLineIndex_ = value;
                % Trigger the line selected callback.
                onLineClicked( obj, obj.Lines(value) );
            end % if
            
        end % set.SelectedLineIndex
        
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
            % Update the chart's decorative properties.
            obj.XGrid = obj.Axes.XGrid;
            obj.YGrid = obj.Axes.YGrid;
            
        end % grid
        
        function varargout = legend( obj, varargin )
            
            % Invoke legend on the axes.
            [varargout{1:nargout}] = legend( obj.Axes, varargin{:} );
            % Reconnect the ItemHitFcn, if necessary.
            if ~isempty( obj.Axes.Legend )
                obj.Axes.Legend.ItemHitFcn = @obj.onLegendClicked;
            end % if
            
        end % legend
        
        function varargout = xlim( obj, varargin )
            
            [varargout{1:nargout}] = xlim( obj.Axes, varargin{:} );
            
        end % xlim
        
        function varargout = ylim( obj, varargin )
            
            [varargout{1:nargout}] = ylim( obj.Axes, varargin{:} );
            
        end % ylim
        
    end % methods
    
    methods ( Access = protected )
        
        function setup( obj )
            %SETUP Initialize the chart graphics.
            
            % Create the chart's axes.
            obj.Axes = axes( "Parent", obj.getLayout() );
            
            % Add a push button to reset the chart.
            tb = axtoolbar( obj.Axes, "default" );
            obj.ResetButton = axtoolbarbtn( tb, "push", ...
                "Icon", "Reset.png", ...
                "Tooltip", "Reset the chart", ...
                "ButtonPushedFcn", @obj.onResetButtonPushed );
            
        end % setup
        
        function update( obj )
            %UPDATE Refresh the chart graphics.
            
            if obj.ComputationRequired
                
                % Count the number of lines required.
                nNew = size( obj.YData_, 2 );
                
                % Count the number of existing lines.
                nOld = numel( obj.Lines );
                
                if nNew > nOld
                    % Create new lines.
                    nToCreate = nNew - nOld;
                    obj.Lines = [obj.Lines; gobjects( nToCreate, 1 )];
                    for k = 1:nToCreate
                        obj.Lines(nOld+k) = line( ...
                            obj.Axes, NaN, NaN, ...
                            "Color", obj.TraceColor, ...
                            "DisplayName", "" );
                    end % for
                elseif nNew < nOld
                    % Remove the unnecessary lines.
                    delete( obj.Lines(nNew+1:nOld) );
                    obj.Lines(nNew+1:nOld) = [];
                end % if
                
                % Update the data for all lines.
                for k = 1:nNew
                    set( obj.Lines(k), "XData", obj.XData_, ...
                        "YData", obj.YDataScaled(:, k) )
                end % for
                
                % Enable interactivity and gray out all lines.
                deselect( obj )
                
                % Mark the chart clean.
                obj.ComputationRequired = false;
                
            end % if
            
            % Refresh the chart's decorative properties.
            set( obj.Axes, "XGrid", obj.XGrid, ...
                "YGrid", obj.YGrid )
            
        end % update
        
    end % methods ( Access = protected )
    
    methods ( Access = private )
        
        function onResetButtonPushed( obj, ~, ~ )
            %ONRESETBUTTONPUSHED Reset the chart when the user pushes the
            %reset button on the axes' toolbar.
            
            deselect( obj )
            
        end % onResetButtonPushed
        
        function onLineClicked( obj, s, ~ )
            
            % Determine the index of the selected line.
            selectedIdx = find( obj.Lines == s );
            % Record this value in the object.
            obj.SelectedLineIndex_ = selectedIdx;
            % Gray out all lines.
            set( obj.Lines, "LineWidth", 0.5, ...
                "Color", obj.TraceColor )
            % Highlight the selected line.
            set( obj.Lines(selectedIdx), "LineWidth", 3, ...
                "Color", obj.SelectedColor, ...
                "YData", obj.YData_(:, selectedIdx) )
            set( obj.Axes, "YColor", obj.SelectedColor )
            % Adjust the y-data for all other lines.
            notSelectedIdx = setdiff( 1:numel( obj.Lines ), selectedIdx );
            for k = notSelectedIdx
                adjustedYData = obj.YDataScaled(:, k) * ...
                    obj.YDataRange(selectedIdx) + ...
                    obj.YDataMin(selectedIdx);
                set( obj.Lines(k), "YData", adjustedYData )
            end % for
            
        end % onLineClicked
        
        function onLegendClicked( obj, ~, e )
            
            onLineClicked( obj, e.Peer )
            
        end % onLegendClicked
        
        function deselect( obj )
            
            % Enable interactivity and gray out all lines.
            set( obj.Lines, "ButtonDownFcn", @obj.onLineClicked, ...
                "LineWidth", 0.5, ...
                "Color", obj.TraceColor )
            % Restore the original y-axis color.
            obj.Axes.YColor = "k";
            % Record no selection.
            obj.SelectedLineIndex_ = 0;
            
        end % deselect
        
    end % methods ( Access = private )
    
end % class definition