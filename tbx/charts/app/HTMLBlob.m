classdef HTMLBlob < matlab.ui.componentcontainer.ComponentContainer
    %HTMLBLOB Parametrizable view of an HTML document.

    properties
        % HTML source file.
        HTMLSource(:, 1) string {mustBeFile, mustBeScalarOrEmpty} = ...
            string.empty( 0, 1 )
        % HTML event received callback.
        HTMLEventReceivedFcn(:, 1) function_handle {mustBeScalarOrEmpty}
    end % properties

    properties ( GetAccess = ?matlab.unittest.TestCase, ...
            SetAccess = private )
        % Grid layout.
        Grid(:, 1) matlab.ui.container.GridLayout {mustBeScalarOrEmpty}
        % HTML container.
        HTMLContainer(:, 1) matlab.ui.control.HTML {mustBeScalarOrEmpty}
    end % properties ( GetAccess = ?matlab.unittest.TestCase, ...
    % SetAccess = private )

    methods

        function obj = HTMLBlob( namedArgs )
            %HTMLBLOB Construct an HTMLBLOB object, given optional
            %name-value arguments.

            arguments ( Input )
                namedArgs.?HTMLBlob
            end % arguments ( Input )

            % Call the superclass constructor.
            obj@matlab.ui.componentcontainer.ComponentContainer( ...
                "Parent", [], ...
                "Units", "normalized", ...
                "Position", [0, 0, 1, 1] )

            % Set any user-defined propertie.s
            set( obj, namedArgs )

        end % constructor

        function sendEventToHTMLSource( obj, varargin )
            %SENDEVENTTOHTMLSOURCE Send an event to the underlying HTML.

            obj.HTMLContainer.sendEventToHTMLSource( varargin{:} )

        end % sendEventToHTMLSource

    end % methods

    methods ( Access = protected )

        function setup( obj )
            %SETUP Initialize the blob.

            % Create the HTML container within a grid.
            obj.Grid = uigridlayout( obj, [1, 1], "Padding", 0 );
            obj.HTMLContainer = uihtml( obj.Grid );

        end % setup

        function update( obj )
            %UPDATE Update the blob.

            set( obj.HTMLContainer, "HTMLSource", obj.HTMLSource, ...
                "HTMLEventReceivedFcn", obj.HTMLEventReceivedFcn )

        end % update

    end % methods ( Access = protected )

end % classdef