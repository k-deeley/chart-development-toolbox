classdef RadarScope < Component
    %RADARSCOPE Chart managing a radar scope backdrop and a collection of
    %blips representing objects detected on the scope.

    % Public, user-facing properties.
    properties ( AbortSet )
        % Backdrop color.
        BackdropColor {mustBeColor} = [0.6, 1, 0]
    end % properties ( AbortSet )

    properties ( SetAccess = private )
        % Blips on the scope.
        Blips(1, :) Blip
    end % properties ( SetAccess = private )

    % Dynamic chart graphics and control objects.
    properties ( Access = private, Transient, NonCopyable )
        % Chart's polar axes.
        Axes(1, 1) matlab.graphics.axis.PolarAxes
        % Proximity status lamp.
        Lamp(1, 1) matlab.ui.control.Lamp
    end % properties ( Access = private, Transient, NonCopyable )

    % Annotation methods.
    methods

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

    end % methods

    % Blip-related methods.
    methods

        function add( obj, blip )
            %ADD Add a blip to the scope.

            arguments
                obj(1, 1) RadarScope
                blip(1, 1) Blip
            end % arguments

            if ismember( blip, obj.Blips )
                warning( "RadarScope:BlipAlreadyOnScope", ...
                    "The blip is already on the scope." )
            else
                % Parent the blip to the polar axes managed by the scope.
                blip.Parent = obj.Axes;
                % Append the blip to the blip array.
                obj.Blips(1, end+1) = blip;
            end % if

        end % add

        function remove( obj, blip )
            %REMOVE Remove a blip from the scope.

            arguments
                obj(1, 1) RadarScope
                blip(1, 1) Blip
            end % arguments

            % Validate.
            idx = obj.Blips == blip;
            if ~any( idx )
                warning( "RadarScope:BlipNotOnScope", ...
                    "The blip is not on the scope." )
            else
                % Remove the blip from the blip array.
                obj.Blips(idx) = [];
                % Unplug the blip.
                blip.Parent = matlab.graphics.axis.PolarAxes.empty( 0, 0 );
            end % if

        end % remove

        function updateProximityStatus( obj )
            %UPDATEPROXIMITYSTATUS Compute the distances between blips and
            %update the scope if blips are in danger.

            % Compute the pairwise blip distances.
            blipPos = vertcat( obj.Blips.Position );
            blipDist = squareform( ...
                sqrt( pdist( blipPos, @polarDistance ) ) );

            % Identify the indices of the pairs of nearby blips.
            numBlips = length( obj.Blips );
            linIdx = find( blipDist < 10 & blipDist > 0 );
            [row, col] = ind2sub( [numBlips, numBlips], linIdx );
            nearbyBlipIdx = union( row, col );
            distantBlipIdx = setdiff( 1:numBlips, nearbyBlipIdx );

            % Update the blips and the lamp.
            set( obj.Blips(nearbyBlipIdx), "Color", "r" )
            set( obj.Blips(distantBlipIdx), "Color", [1, 0.5, 0] )
            if any( linIdx )
                obj.Lamp.Color = "r";
            else
                obj.Lamp.Color = "g";
            end % if

        end % updateProximityStatus

    end % methods

    methods ( Access = protected )

        function setup( obj )
            %SETUP Initialize the chart's graphics and controls.

            % Make the chart span its parent (only for Component charts -
            % the default panel position on a uifigure is not full-window).
            set( obj, "Units", "normalized", "Position", [0, 0, 1, 1] )

            % Create a grid for the chart components.
            g = uigridlayout( "Parent", obj, ...
                "ColumnWidth", "1x", ... % One column
                "RowHeight", ["1x", "fit", "fit"], ... % Three rows
                "BackgroundColor", "black" );

            % Create the polar axes.
            obj.Axes = polaraxes( "Parent", g, ...
                "HandleVisibility", "off", ...
                "RColor", obj.BackdropColor, ...
                "RTick", 0:10:100, ...
                "RLim", [0, 100], ...
                "ThetaColor", obj.BackdropColor, ...
                "ThetaZeroLocation", "top", ...
                "ThetaDir", "clockwise", ...
                "ThetaTick", 0:15:360, ...
                "Color", "black", ...
                "LineWidth", 2, ...
                "GridAlpha", 0.25, ...
                "FontSize", 10 );

            % Apply some default annotations.
            obj.Axes.RAxis.Label.String = "Range (miles)";
            obj.Axes.ThetaAxis.Label.String = "Bearing";
            thetatickformat( obj.Axes, "degrees" )
            title( obj.Axes, "Radar Scope", "Color", obj.BackdropColor )

            % Add a static label, and the status lamp.
            uilabel( "Parent", g, ...
                "Text", "Proximity Status", ...
                "BackgroundColor", "black", ...
                "FontColor", obj.BackdropColor, ...
                "FontWeight", "bold", ...
                "HorizontalAlignment", "center" );
            obj.Lamp = uilamp( "Parent", g, "Color", "g" );

        end % setup

        function update( obj )
            %UPDATE Refresh the chart's graphics in response to any
            %changes.

            % Update the scope colors.
            set( obj.Axes, "RColor", obj.BackdropColor, ...
                "ThetaColor", obj.BackdropColor )
            obj.Axes.Title.Color = obj.BackdropColor;

        end % update

    end % methods ( Access = protected )

end % classdef