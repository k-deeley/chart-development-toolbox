classdef GraphicsHierarchyChart < Chart
    %GRAPHICSHIERARCHYCHART Visualize the graphics hierarchy descending
    %from a given graphics object.

    % Copyright 2024-2025 The MathWorks, Inc.

    properties ( Dependent )
        % Graphics object at the root of the visualization.
        RootObject(1, 1) {mustBeValidGraphics}
        % Logical flag indicating whether to show hidden objects.
        ShowHiddenHandles(1, 1) matlab.lang.OnOffSwitchState
    end % properties ( Dependent )

    properties ( Access = private, Transient, NonCopyable )
        % Chart axes.
        Axes(:, 1) matlab.graphics.axis.Axes {mustBeScalarOrEmpty}
        % Graph plot.
        GraphPlot(:, 1) matlab.graphics.chart.primitive.GraphPlot ...
            {mustBeScalarOrEmpty}
    end % properties ( Access = private, Transient, NonCopyable )

    properties ( Access = private )
        % Internal storage for the RootObject property.
        RootObject_(1, 1) {mustBeValidGraphics} = groot()
        % Internal storage for the ShowHiddenHandles property.
        ShowHiddenHandles_(1, 1) matlab.lang.OnOffSwitchState = "off"
        % Logical flag indicating whether a full update is required.
        ComputationRequired(1, 1) logical = false
    end % properties ( Access = private )

    methods

        function obj = GraphicsHierarchyChart( namedArgs )
            %GRAPHICSHIERARCHYCHART Construct a GraphicsHierarchyChart
            %object, given optional name-value arguments.

            arguments ( Input )
                namedArgs.?GraphicsHierarchyChart
            end % arguments ( Input )

            % Set any user-defined properties.
            set( obj, namedArgs )

        end % constructor

        function value = get.RootObject( obj )

            value = obj.RootObject_;

        end % get.RootObject

        function set.RootObject( obj, value )

            obj.ComputationRequired = true;
            obj.RootObject_ = value;

        end % set.RootObject

        function value = get.ShowHiddenHandles( obj )

            value = obj.ShowHiddenHandles_;

        end % get.ShowHiddenObjects

        function set.ShowHiddenHandles( obj, value )

            obj.ComputationRequired = true;
            obj.ShowHiddenHandles_ = value;

        end % set.ShowHiddenObjects

        function varargout = title( obj, varargin )

            [varargout{1:nargout}] = title( obj.Axes, varargin{:} );

        end % title

    end % methods

    methods ( Access = protected )

        function setup( obj )
            %SETUP Initialize the chart's graphics.

            % Create the axes.
            obj.Axes = axes( "Parent", obj.getLayout(), ...
                "Visible", "off" );
            obj.Axes.Title.Visible = "on";

        end % setup

        function update( obj )
            %UPDATE Refresh the chart's graphics.

            if obj.ComputationRequired

                % Construct the graph containing the descendants of the
                % stored root object.
                [G, nodeLabels] = kids2graph( obj.RootObject, ...
                    "ShowHiddenHandles", obj.ShowHiddenHandles );

                % Plot the graph.
                hold( obj.Axes, "on" )
                G.plot( "Parent", obj.Axes, ...
                    "MarkerSize", 8, ...
                    "NodeColor", obj.Axes.ColorOrder(2, :), ...
                    "LineWidth", 3, ...
                    "NodeLabel", nodeLabels )
                hold( obj.Axes, "off" )

                % Reset the flag.
                obj.ComputationRequired = false;

            end % if


        end % update

    end % methods ( Access = protected )

end % classdef