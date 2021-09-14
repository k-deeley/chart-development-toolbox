classdef Spider < matlab.graphics.chartcontainer.ChartContainer
    %SPIDER Manages the display of values from distinct measurements
    %plotted around a web. The number of nodes in the web is equal to the
    %number of distinct measurements.
    %
    % Copyright 2019-2021 The MathWorks, Inc.
    
    properties ( Dependent )
        %DATA Matrix of chart data: each row represents a distinct property
        %and corresponds to a node in the web. Each column contains the
        %measured property values and contains the data for each line.
        Data(:, :) double {mustBeInRange( Data, 0, 1 )}
        %TARGETDATA Target data vector, containing the same number of
        %elements as there are nodes in the web. Each element represents
        %the target value for that particular property.
        TargetData(:, 1) double {mustBeInRange( TargetData, 0, 1 )}
        % Node labels.
        LabelText(:, 1) string
    end % properties ( Dependent )
    
    properties
        % Line width of the data lines.
        LineWidth = 1.5
        % Visibility of the target line.
        TargetVisible = "off"
        % Target line color.
        TargetColor = "k"
        % Target line width.
        TargetLineWidth = 1.5
        % Target line style.
        TargetLineStyle = ":"
        % Node label font size.
        LabelFontSize = 10
        % Node label font angle.
        LabelFontAngle = "normal"
        % Node label font weight.
        LabelFontWeight = "normal"
    end % properties
    
    properties ( Dependent )
        % Line colors.
        LineColors(:, 3) double {mustBeInRange( LineColors, 0, 1 )}
    end % properties ( Dependent )
    
    properties ( Dependent, SetAccess = private )
        % Number of nodes.
        NumNodes
        % Number of lines.
        NumLines
    end % properties ( Dependent, SetAccess = private )
    
    properties ( Access = private )
        % Internal storage for the Data property.
        Data_ = 0
        % Internal storage for the TargetData property.
        TargetData_ = 0
        % Internal storage for the Labels property.
        LabelText_ = string.empty( 0, 1 )
        % Logical scalar specifying whether a computation is required.
        ComputationRequired = false()
    end % properties ( Access = private )
    
    properties ( Access = private, Transient, NonCopyable )
        % Chart axes.
        Axes(1, 1) matlab.graphics.axis.Axes
        % Array of graphical objects for the lines.
        Lines(:, 1) matlab.graphics.chart.primitive.Line
        % Target line.
        TargetLine(1, 1) matlab.graphics.primitive.Line
        % Concentric polygons forming the web.
        WebPolygons(10, 1) matlab.graphics.primitive.Line
        % Angular rays forming the web.
        WebRays(:, 1) matlab.graphics.primitive.Line
        % Text labels for the nodes.
        Labels(:, 1) matlab.graphics.primitive.Text
    end % properties ( Access = private, Transient, NonCopyable )
    
    properties ( Constant, GetAccess = private )
        % Web color.
        BackdropColor = 0.8725 * ones( 1, 3 )
    end % properties ( Constant, GetAccess = private )
    
    properties ( Constant, Hidden )
        % Product dependencies.
        Dependencies = "MATLAB"
    end % properties ( Constant, Hidden )
    
    methods
        
        function value = get.Data( obj )
            
            value = obj.Data_;
            
        end % get.Data
        
        function set.Data( obj, value )
            
            % Validate that the new number of nodes (the number of
            % rows in the data matrix) is in the required range.
            nD = size( value, 1 );
            assert( nD >= 3 && nD <= 20, ...
                "Spider:InvalidNumProperties", ...
                "The number of properties must be at least 3 " + ...
                "and at most 20." )
            
            % Mark the chart for an update.
            obj.ComputationRequired = true();
            
            % Decide how to modify the target data and node labels in
            % response to a change in the chart data.
            nT = length( obj.TargetData_ );
            if nD > nT
                % Pad.
                obj.TargetData_(end+1:nD, 1) = 0;
                obj.LabelText_(end+1:nD, 1) = "";
            elseif nD <= nT
                % Truncate.
                obj.TargetData_ = obj.TargetData_(1:nD, 1);
                obj.LabelText_ = obj.LabelText_(1:nD, 1);
            end % if
            
            % Update the internal stored value.
            obj.Data_ = value;
            
        end % set.Data
        
        function value = get.TargetData( obj )
            
            value = obj.TargetData_;
            
        end % get.TargetData
        
        function set.TargetData( obj , value )
            
            % Verify that the length of the new target data is correct.
            assert( length( value ) == obj.NumNodes, ...
                "Spider:InvalidTargetDataLength", ...
                "The length of the target data must equal " + ...
                "the number of nodes." )
            
            % Mark the chart for an update.
            obj.ComputationRequired = true();
            
            % Update the internal stored property.
            obj.TargetData_ = value;
            
        end % set.TargetData
        
        function value = get.LabelText( obj )
            
            value = obj.LabelText_;
            
        end % get.LabelText
        
        function set.LabelText( obj, value )
            
            % Verify that the length of the new label text is correct.
            assert( length( value ) == obj.NumNodes, ...
                "Spider:InvalidLabelTextLength", ...
                "The number of text labels must equal " + ...
                "the number of nodes." )
            
            % Mark the chart for an update.
            obj.ComputationRequired = true();
            
            % Update the internal stored property.
            obj.LabelText_ = value;
            
        end % set.LabelText
        
        function value = get.LineColors( obj )
            
            value = vertcat( obj.Lines.Color );
            
        end % get.LineColors
        
        function set.LineColors( obj, value )
            
            % Check that the number of colors is correct.
            nColors = size( value, 1 );
            assert( nColors == obj.NumLines, ...
                "Spider:ColorMatrixSizeMismatch", ...
                "The number of colors must match the number of lines." )
            
            % Set the new colors.
            for k = 1:nColors
                obj.Lines(k).Color = value(k, :);
            end % for
            
        end % set.LineColors
        
        function value = get.NumNodes( obj )
            
            value = size( obj.Data_, 1 );
            
        end % get.NumNodes
        
        function value = get.NumLines( obj )
            
            value = size( obj.Data_, 2 );
            
        end % get.NumLines
        
    end % methods
    
    methods
        
        function varargout = title( obj, varargin )
            
            [varargout{1:nargout}] = title( obj.Axes, varargin{:} );
            
        end % title
        
        function varargout = legend( obj, varargin )
            
            [varargout{1:nargout}] = legend( obj.Axes, varargin{:} );
            
        end % legend
        
    end % methods
    
    methods ( Access = protected )
        
        function setup( obj )
            %SETUP Initialize the chart graphics.
            
            % Create the chart's axes.
            obj.Axes = axes( "Parent", obj.getLayout(), ...
                "Visible", "off", ...
                "DataAspectRatio", [1, 1, 1], ...
                "XLim", [-1.25, 1.25], ...
                "YLim", [-1.25, 1.25] );
            % Make the title visible.
            obj.Axes.Title.Visible = "on";
            
            % Initialize the line objects for the concentric polygons
            % forming part of the web.
            for k = 1:length( obj.WebPolygons )
                obj.WebPolygons(k) = line( ...
                    "Parent", obj.Axes, ...
                    "XData", NaN, ...
                    "YData", NaN, ...
                    "Color", obj.BackdropColor, ...
                    "HandleVisibility", "off" );
            end % for
            
            % Initialize the line object for the target data.
            obj.TargetLine = line( ...
                "Parent", obj.Axes, ...
                "XData", NaN, ...
                "YData", NaN, ...
                "HandleVisibility", "off" );
            
        end % setup
        
        function update( obj )
            %UPDATE Refresh the chart graphics.
            
            if obj.ComputationRequired
                
                % First, update the fixed graphics objects.
                
                % Concentric polygons in the web.
                webRadii = 0.1 : 0.1 : 1;
                t = pi / 2 + linspace( 2 * pi, 0, obj.NumNodes + 1 ).';
                z = exp( 1i*t );
                webZ = z * webRadii;
                webX = real( webZ );
                webY = imag( webZ );
                % Update the concentric polygons used in the backdrop.
                for k = 1:length( obj.WebPolygons )
                    set( obj.WebPolygons(k), ...
                        "XData", webX(:, k), ...
                        "YData", webY(:, k) )
                end % for
                
                % Target line.
                targetZ = z .* obj.TargetData_([1:end, 1]); % Wrap around
                set( obj.TargetLine, "XData", real( targetZ ), ...
                    "YData", imag( targetZ ) )
                
                % Next, create or delete graphics objects as appropriate
                % before refreshing their properties.
                
                % Deal with a change in the number of nodes. This affects
                % the angular rays and the node labels.
                previousNumNodes = length( obj.WebRays );
                if obj.NumNodes <= previousNumNodes
                    % Remove the additional angular rays in the web.
                    for k = obj.NumNodes+1:previousNumNodes
                        % Tidy up the text boxes associated with the ray,
                        % if necessary.
                        setappdata( obj.WebRays(k), "Selected", true() )
                        onWebRayClicked( obj, obj.WebRays(k) )
                        delete( obj.WebRays(k) )
                    end % for
                    % Remove the references to the deleted web rays.
                    obj.WebRays(obj.NumNodes+1:end) = [];
                    % Remove the additional node labels.
                    delete( obj.Labels(obj.NumNodes+1:end) )
                    obj.Labels(obj.NumNodes+1:end) = [];
                elseif obj.NumNodes > previousNumNodes
                    % Add angular rays to the web, and node labels.
                    for k = previousNumNodes+1:obj.NumNodes
                        obj.WebRays(k) = line( ...
                            "Parent", obj.Axes, ...
                            "XData", NaN, ...
                            "YData", NaN, ...
                            "Color", obj.BackdropColor, ...
                            "HandleVisibility", "off", ...
                            "ButtonDownFcn", @obj.onWebRayClicked );
                        obj.Labels(k) = text( "Parent", obj.Axes, ...
                            "HandleVisibility", "off", ...                            
                            "Position", [NaN, NaN, 0], ...
                            "HorizontalAlignment", "center", ...
                            "VerticalAlignment", "middle" );
                    end % for
                end % if
                
                % Update the angular rays. These begin at the inner circle
                % and terminate at the outer border. Update the node
                % labels. These are placed outside the axes limits.
                rayZ = [0; 1] * z.';
                rayX = real( rayZ );
                rayY = imag( rayZ );
                textRadius = 1.225;
                textZ = textRadius * z;
                textX = real( textZ );
                textY = imag( textZ );
                for k = 1:obj.NumNodes
                    set( obj.WebRays(k), "XData", rayX(:, k), ...
                        "YData", rayY(:, k) )
                    set( obj.Labels(k), ...
                        "Position", [textX(k), textY(k), 0], ...
                        "String", obj.LabelText_(k) )
                end % for
                
                % Deal with a change in the number of lines.
                previousNumLines = length( obj.Lines );
                if obj.NumLines <= previousNumLines
                    % Remove the additional lines.
                    delete( obj.Lines(obj.NumLines+1:end) )
                    obj.Lines(obj.NumLines+1:end) = [];
                elseif obj.NumLines > previousNumLines
                    obj.Axes.ColorOrderIndex = previousNumLines+1;
                    % Create new lines.
                    hold( obj.Axes, "on" )
                    for k = previousNumLines+1:obj.NumLines
                        obj.Lines(k) = plot( obj.Axes, NaN, NaN, ".-", ...
                            "MarkerSize", 16 );
                    end % for
                    hold( obj.Axes, "off" )
                end % if
                
                % Update the lines.
                lineZ = z .* obj.Data_([1:end, 1], :); % Wrap around
                lineX = real( lineZ );
                lineY = imag( lineZ );
                for k = 1:obj.NumLines
                    set( obj.Lines(k), "XData", lineX(:, k), ...
                        "YData", lineY(:, k) )
                end % for
                
                % For the existing web rays, remove any text boxes from
                % prior user interactions.
                for k = 1:length( obj.WebRays )
                    setappdata( obj.WebRays(k), "Selected", true() )
                    onWebRayClicked( obj, obj.WebRays(k) )
                end % for
                
                % Ensure that the visual stacking order is correct.
                obj.Axes.Children = [flip( obj.Lines ); obj.TargetLine;
                    obj.WebRays; obj.WebPolygons];
                
            end % if
            
            % Refresh the chart's decorative properties.
            set( obj.Lines, "LineWidth", obj.LineWidth )
            set( obj.TargetLine, "Visible", obj.TargetVisible, ...
                "Color", obj.TargetColor, ...
                "LineWidth", obj.TargetLineWidth, ...
                "LineStyle", obj.TargetLineStyle )
            set( obj.Labels, "FontSize", obj.LabelFontSize, ...
                "FontAngle", obj.LabelFontAngle, ...
                "FontWeight", obj.LabelFontWeight )
            
        end % update
        
    end % methods ( Access = protected )
    
    methods ( Access = private )
        
        function onWebRayClicked( obj, s, ~ )
            %ONWEBRAYCLICKED Respond to user mouse clicks on the web rays.
            
            selected = getappdata( s, "Selected" );
            if selected
                % Restore the default web ray appearance.
                set( s, "LineWidth", 0.5, "Color", obj.BackdropColor )
                setappdata( s, "Selected", false() )
                % Delete the text boxes and remove their references.
                if isappdata( s, "WebRayTextBoxes" )
                    delete( getappdata( s, "WebRayTextBoxes" ) )
                    rmappdata( s, "WebRayTextBoxes" )
                end % if
            else
                % Highlight the selected web ray.
                set( s, "LineWidth", 1.5, ...
                    "Color", 0.75 * obj.BackdropColor )
                setappdata( s, "Selected", true() )
                % Display text boxes to show the observed values.
                selectedRayIdx = obj.WebRays == s;
                selectedData = obj.Data_(selectedRayIdx, :);
                for k = length( selectedData ):-1:1
                    tx(k) = text( obj.Axes, ...
                        obj.Lines(k).XData(selectedRayIdx), ...
                        obj.Lines(k).YData(selectedRayIdx), ...
                        num2str( selectedData(k) ), ...
                        "HandleVisibility", "off", ...
                        "Color", obj.Lines(k).Color, ...
                        "HorizontalAlignment", "left", ...
                        "VerticalAlignment", "bottom", ...
                        "BackgroundColor", [1, 1, 1, 0.75], ...
                        "FontWeight", "bold" );
                end % for
                % Store references to the text boxes in the selected ray.
                setappdata( s, "WebRayTextBoxes", tx )
            end % if
            
        end % onWebRayClicked
        
    end % methods ( Access = private )
    
end % classdef