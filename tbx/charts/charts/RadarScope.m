classdef RadarScope < Component
    %RADARSCOPE Component managing a radar scope and a set of blips
    %representing objects detected on the scope.

    % Copyright 2021-2025 The MathWorks, Inc.

    properties
        % Backdrop color.
        BackdropColor {validatecolor} = [0.6, 1, 0]
        % Blip color.
        BlipColor {validatecolor} = [1, 1, 1]
        % Grid line width.
        GridLineWidth(1, 1) double {mustBePositive, mustBeFinite} = 1.5
        % Grid line transparency.
        GridAlpha(1, 1) double {mustBeInRange( GridAlpha, 0, 1 )} = 0.25
        % Specify whether the lamp is shown.
        ShowProximityLamp(1, 1) matlab.lang.OnOffSwitchState = "on"
    end % properties

    properties ( SetAccess = private )
        % Blips on the scope.
        Blips(:, 1) Blip
    end % properties ( SetAccess = private )

    properties ( Access = private )
        % Grid layout.
        GridLayout(:, 1) matlab.ui.container.GridLayout ...
            {mustBeScalarOrEmpty}
        % Chart's polar axes.
        Axes(:, 1) matlab.graphics.axis.PolarAxes {mustBeScalarOrEmpty}
        % Text label.
        Label(:, 1) matlab.ui.control.Label {mustBeScalarOrEmpty}
        % Proximity status lamp.
        Lamp(:, 1) matlab.ui.control.Lamp {mustBeScalarOrEmpty}
        % Blip position listener.
        BlipPositionListeners(:, 1) event.proplistener
    end % properties ( Access = private )

    properties ( Constant, Hidden )
        % Product dependencies.
        Dependencies(1, :) string = "MATLAB"
        % Description.
        ShortDescription(1, 1) string = "Plot a set of blips on a " + ...
            "radar scope and issue proximity alerts"
    end % properties ( Constant, Hidden )

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

        function varargout = thetaticks( obj, varargin )

            [varargout{1:nargout}] = thetaticks( obj.Axes, varargin{:} );

        end % thetaticks

        function varargout = thetaticklabels( obj, varargin )

            [varargout{1:nargout}] = thetaticklabels( ...
                obj.Axes, varargin{:} );

        end % thetaticklabels

        function varargout = rticks( obj, varargin )

            [varargout{1:nargout}] = rticks( obj.Axes, varargin{:} );

        end % rticks

        function varargout = rticklabels( obj, varargin )

            [varargout{1:nargout}] = rticklabels( obj.Axes, varargin{:} );

        end % rticklabels

        function varargout = rlabel( obj, labelText, namedArgs )

            arguments ( Input )
                obj(1, 1) RadarScope
                labelText(1, 1) string
                namedArgs.?matlab.graphics.primitive.Text
            end % arguments ( Input )

            % Check the number of outputs.
            nargoutchk( 0, 1 )

            % Set the label text and any name-value pairs.
            label = obj.Axes.ThetaAxis.Label;
            label.String = labelText;
            set( label, namedArgs )

            % Return the label if requested.
            if nargout == 1
                varargout{1} = label;
            end % if

        end % rlabel

        function varargout = thetalabel( obj, labelText, namedArgs )

            arguments ( Input )
                obj(1, 1) RadarScope
                labelText(1, 1) string
                namedArgs.?matlab.graphics.primitive.Text
            end % arguments ( Input )

            % Check the number of outputs.
            nargoutchk( 0, 1 )

            % Set the label text and any name-value pairs.
            label = obj.Axes.RAxis.Label;
            label.String = labelText;
            set( label, namedArgs )

            % Return the label if requested.
            if nargout == 1
                varargout{1} = label;
            end % if

        end % thetalabel

    end % methods

    methods ( Access = protected )

        function setup( obj )
            %SETUP Initialize the component's graphics.

            % Create a grid for the chart components.
            obj.GridLayout = uigridlayout( "Parent", obj, ...
                "ColumnWidth", "1x", ...
                "RowHeight", ["1x", "fit", "fit"], ...
                "BackgroundColor", "k" );

            % Create the polar axes.
            obj.Axes = polaraxes( "Parent", obj.GridLayout, ...
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
            obj.Label = uilabel( "Parent", obj.GridLayout, ...
                "Text", "Proximity Status", ...
                "FontWeight", "bold", ...
                "HorizontalAlignment", "center" );
            obj.Lamp = uilamp( "Parent", obj.GridLayout, ...
                "Color", "g" );

        end % setup

        function update( obj )
            %UPDATE Refresh the component's graphics.

            % Update the scope colors.
            set( obj.Axes, "RColor", obj.BackdropColor, ...
                "ThetaColor", obj.BackdropColor, ...
                "LineWidth", obj.GridLineWidth, ...
                "GridAlpha", obj.GridAlpha )
            obj.Axes.Title.Color = obj.BackdropColor;
            obj.Label.FontColor = obj.BackdropColor;

            if obj.ShowProximityLamp
                obj.GridLayout.RowHeight = ["1x", "fit", "fit"];
            else
                obj.GridLayout.RowHeight = ["1x", "0x", "0x"];
            end % if

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
            set( obj.Blips(distantBlipIdx), "Color", obj.BlipColor )
            if any( linIdx )
                obj.notify( "NearbyBlipsDetected" )
                obj.Lamp.Color = "r";
            else
                obj.Lamp.Color = obj.BackdropColor;
            end % if

        end % onBlipPositionChanged

    end % methods ( Access = private )

end % classdef