classdef RadarScope < Component
    %RADARSCOPE Component managing a radar scope and a collection of blips
    %representing objects detected on the scope.

    % Copyright 2021-2025 The MathWorks, Inc.

    properties
        % Backdrop color.
        BackdropColor {validatecolor} = [0.6, 1, 0]
    end % properties

    properties ( SetAccess = private )
        % Blips on the scope.
        Blips(:, 1) Blip
    end % properties ( SetAccess = private )

    properties ( Access = private )
        % Chart's polar axes.
        Axes(:, 1) matlab.graphics.axis.PolarAxes {mustBeScalarOrEmpty}
        % Text label.
        Label(:, 1) matlab.ui.control.Label {mustBeScalarOrEmpty}
        % Proximity status lamp.
        Lamp(:, 1) matlab.ui.control.Lamp {mustBeScalarOrEmpty}
        % Blip position listener.
        BlipPositionListeners(:, 1) event.proplistener
    end % properties ( Access = private )

    events ( NotifyAccess = private, HasCallbackProperty )
        % Blips have been detected in close proximity.
        NearbyBlipsDetected
    end % events ( NotifyAccess = private, HasCallbackProperty )

    methods

        function obj = RadarScope( namedArgs )
            %RADARSCOPE Construct a RadarScope object, given optional
            %name-value arguments.

            arguments ( Input )
                namedArgs.?RadarScope
            end % arguments ( Input )

            % Set any user-defined properties.
            set( obj, namedArgs )

        end % constructor

        function varargout = title( obj, varargin )
            %TITLE Customize the chart title.

            [varargout{1:nargout}] = title( obj.Axes, varargin{:} );

        end % title

        function varargout = subtitle( obj, varargin )
            %SUBTITLE Customize the chart subtitle.

            [varargout{1:nargout}] = subtitle( obj.Axes, varargin{:} );

        end % subtitle

        function grid( obj, varargin )
            %TITLE Customize the chart grid.

            grid( obj.Axes, varargin{:} )

        end % grid

        function addBlip( obj, blip )
            %ADDBLIP Add a blip to the scope.

            arguments ( Input )
                obj(1, 1) RadarScope
                blip(1, 1) Blip
            end % arguments ( Input )

            if ~ismember( blip, obj.Blips )
                % Parent the blip to the polar axes.
                blip.Parent = obj.Axes;
                % Store a reference to the blip in the scope.
                obj.Blips(end+1, 1) = blip;
                % Update the position listeners.
                weakObj = matlab.lang.WeakReference( obj );
                callback = @( varargin ) weakObj.Handle...
                    .onBlipPositionChanged( varargin{:} );
                obj.BlipPositionListeners(end+1, 1) = ...
                    listener( obj.Blips(end), ...
                    "Position", "PostSet", callback );
                % Update the proximity status.
                obj.onBlipPositionChanged()
            end % if

        end % addBlip

        function removeBlip( obj, blip, newBlipParent )
            %REMOVEBLIP Remove a blip from the scope.

            arguments ( Input )
                obj(1, 1) RadarScope
                blip(1, 1) Blip
                newBlipParent = []
            end % arguments ( Input )

            % Check whether the blip is on the scope.
            [blipOnScope, blipIdx] = ismember( blip, obj.Blips );

            % If it is, remove and unregister it.
            if blipOnScope
                % Unparent the blip from the scope.
                obj.Blips(blipIdx).Parent = newBlipParent;
                % Update the blip list.
                obj.Blips(blipIdx) = [];
                % Update the position listener.
                delete( obj.BlipPositionListeners(blipIdx) )
                obj.BlipPositionListeners(blipIdx) = [];
            end % if

        end % removeBlip

    end % methods

    methods ( Access = protected )

        function setup( obj )
            %SETUP Initialize the component's graphics.

            % Create a grid for the chart components.
            mainGrid = uigridlayout( "Parent", obj, ...
                "ColumnWidth", "1x", ...
                "RowHeight", ["1x", "fit", "fit"], ...
                "BackgroundColor", "k" );

            % Create the polar axes.
            obj.Axes = polaraxes( "Parent", mainGrid, ...
                "Color", "k", ...
                "Interactions", [], ...
                "Toolbar", [], ...
                "RTick", 0:10:100, ...
                "RLim", [0, 100], ...
                "ThetaZeroLocation", "top", ...
                "ThetaDir", "clockwise", ...
                "ThetaTick", 0:15:360, ...
                "LineWidth", 2, ...
                "GridAlpha", 0.25 );

            % Apply some default annotations.
            obj.Axes.RAxis.Label.String = "Range (miles)";
            obj.Axes.ThetaAxis.Label.String = "Bearing";
            thetatickformat( obj.Axes, "degrees" )
            title( obj.Axes, "Radar Scope" )

            % Add a static label, and the status lamp.
            obj.Label = uilabel( "Parent", mainGrid, ...
                "Text", "Proximity Status", ...
                "FontWeight", "bold", ...
                "HorizontalAlignment", "center" );
            obj.Lamp = uilamp( "Parent", mainGrid, "Color", "g" );

        end % setup

        function update( obj )
            %UPDATE Refresh the component's graphics.

            % Update the scope colors.
            set( obj.Axes, "RColor", obj.BackdropColor, ...
                "ThetaColor", obj.BackdropColor )
            obj.Axes.Title.Color = obj.BackdropColor;
            obj.Label.FontColor = obj.BackdropColor;

        end % update

    end % methods ( Access = protected )

    methods ( Access = private )

        function onBlipPositionChanged( obj, ~, ~ )
            %ONBLIPPOSITIONCHANGED Respond to changes in the position of
            %blips on the scope.

            % Compute the pairwise blip distances.
            blipPos = vertcat( obj.Blips.Position );
            blipDist = squareform( ...
                sqrt( pdist( blipPos, @polarDistance ) ) );

            % Identify the indices of the pairs of nearby blips.
            numBlips = numel( obj.Blips );
            linIdx = find( blipDist < 10 & blipDist > 0 );
            [row, col] = ind2sub( [numBlips, numBlips], linIdx );
            nearbyBlipIdx = union( row, col );
            distantBlipIdx = setdiff( 1:numBlips, nearbyBlipIdx );

            % Update the blips and the lamp.
            set( obj.Blips(nearbyBlipIdx), "Color", "r" )
            set( obj.Blips(distantBlipIdx), "Color", Blip.Amber )
            if any( linIdx )
                obj.notify( "NearbyBlipsDetected" )
                obj.Lamp.Color = "r";
            else
                obj.Lamp.Color = obj.BackdropColor;
            end % if

        end % onBlipPositionChanged

    end % methods ( Access = private )

end % classdef