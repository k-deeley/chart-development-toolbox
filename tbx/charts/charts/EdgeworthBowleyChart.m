classdef EdgeworthBowleyChart < Chart
    %EDGEWORTHBOWLEYCHART Creates an Edgeworth-Bowley chart based on the
    %utility curves of two individuals and the Pareto-efficient contract
    %curve.

    % Copyright 2018-2025 The MathWorks, Inc.

    properties
        % Line width.
        LineWidth(1, 1) double {mustBePositive, mustBeFinite} = 1.5
        % Marker size.
        MarkerSize(1, 1) double {mustBePositive, mustBeFinite} = 8
    end % properties

    properties ( Dependent )
        % Chart A-data: this is a matrix defining the utility curves for
        % the individual A.
        AData(:, :) double {mustBeReal}
        % Chart B-data: this is a matrix defining the utility curves for
        % the individual B.
        BData(:, :) double {mustBeReal}
        % Quantity of good 1.
        Quantity1(1, 1) double {mustBeReal}
        % Quantity of good 2.
        Quantity2(1, 1) double {mustBeReal}
    end % properties ( Dependent )

    properties ( Access = private )
        % Internal storage for the AData property.
        AData_(:, :) double {mustBeReal} = double.empty( 0, 1 )
        % Internal storage for the BData property.
        BData_(:, :) double {mustBeReal} = double.empty( 0, 1 )
        % Internal storage for the Quantity1 property.
        Quantity1_(1, 1) double {mustBeReal} = 1
        % Internal storage for the Quantity2 property.
        Quantity2_(1, 1) double {mustBeReal} = 1
        % Fitted curve data for A.
        ACurveFit(:, :) double {mustBeReal} = double.empty( 0, 0 )
        % Fitted curve data for B.
        BCurveFit(:, :) double {mustBeReal} = double.empty( 0, 0 )
        % Pareto set.
        ParetoSet(:, :) double {mustBeReal} = zeros( 2 )
        % A coefficients.
        ACoefficients(:, :) double {mustBeReal} = double.empty( 0, 0 )
        % B coefficients.
        BCoefficients(:, :) double {mustBeReal} = double.empty( 0, 0 )
        % Logical scalar specifying whether a computation is required.
        ComputationRequired(1, 1) logical = false
    end % properties ( Access = private )

    properties ( Access = private, Transient, NonCopyable )
        % Chart axes.
        Axes(:, 1) matlab.graphics.axis.Axes {mustBeScalarOrEmpty}
        % Pareto-efficient curve.
        ContractLine(:, 1) matlab.graphics.primitive.Line ...
            {mustBeScalarOrEmpty}
        % Utility line for A.
        AUtilityLines(:, 1) matlab.graphics.primitive.Line
        % Utility line for B.
        BUtilityLines(:, 1) matlab.graphics.primitive.Line
        % Scattered data points.
        ScatterPoints(:, 1) matlab.graphics.primitive.Line ...
            {mustBeScalarOrEmpty}
    end % properties ( Access = private, Transient, NonCopyable )

    properties ( Constant, Hidden )
        % Product dependencies.
        Dependencies(1, :) string = ["MATLAB", ...
            "Statistics and Machine Learning Toolbox"]
        % Description.
        ShortDescription(1, 1) string = "Plot the utility curves of" + ...
            " two individuals and the Pareto-efficient contract curve"
    end % properties ( Constant, Hidden )

    methods

        function value = get.AData( obj )

            value =  obj.AData_;

        end % get.AData

        function set.AData( obj, value )

            % Mark the chart for an update.
            obj.ComputationRequired = true;

            % Update the internal chart data properties.
            obj.Quantity1_ = value(end, 1);
            obj.ParetoSet(end, 1) = obj.Quantity1_;
            if isempty( obj.BData_ )
                obj.Quantity2_ = max( value(:, 2:end), [], "all" );
                obj.ParetoSet(end, 2) = obj.Quantity2_;
            else
                maxA = max( value(:, 2:end), [], "all" );
                maxB = max( obj.BData_(:, 2:end), [], "all" );
                obj.Quantity2_ = max( maxA, maxB );
                obj.ParetoSet(end, 2) = obj.Quantity2_;
                % If A is resized ...
                obj.BData_ = obj.BData_(1:height( value ), :);
                % If B is resized ...
                obj.BCurveFit = NaN( size( obj.BData_ ) - [0, 1] );
                obj.ACurveFit = NaN( size( value ) - [0, 1] );
            end % if

            % Update the stored property.
            obj.AData_ = value;
            % Update the last point of ParetoSet.
            obj.ParetoSet(end, 1) = obj.Quantity1_;
            obj.ParetoSet(end, 2) = obj.Quantity2_;

            % Update the fitted curve.
            if ~isempty( obj.ACurveFit )
                obj.ACurveFit = obj.ACurveFit(1:height( value ), :);
            end % if

        end % set.AData

        function value = get.BData( obj )

            value =  obj.BData_;

        end % get.BData

        function set.BData( obj, value )

            % Mark the chart for an update.
            obj.ComputationRequired = true;

            % Update the internal chart data properties.
            obj.Quantity1_ = value(end, 1);
            obj.ParetoSet(end, 1) = obj.Quantity1_;
            if isempty( obj.AData_ )
                obj.Quantity2_ = max( value(:, 2:end), [], "all" );
                obj.ParetoSet(end, 2) = obj.Quantity2_;
            else
                maxB = max( value(:, 2:end), [], "all" );
                maxA = max( obj.AData(:, 2:end), [], "all" );
                obj.Quantity2_ = max( maxA, maxB );
                obj.ParetoSet(end, 2) = obj.Quantity2_;
                obj.AData_ = obj.AData_(1:height( value ), :);
                obj.ACurveFit = NaN( size( obj.AData_ ) - [0 1] );
                obj.BCurveFit = NaN( size( value ) - [0 1] );
            end

            % Update the stored property.
            obj.BData_ = value;

        end % set.BData

        function value = get.Quantity1( obj )

            value = obj.Quantity1_;

        end % get.Quantity1

        function set.Quantity1( obj, value )

            % Truncate AData and BData.
            truncateAndAssignQ1( obj, value )

        end % set.Quantity1

        function value = get.Quantity2( obj )

            value = obj.Quantity2_;

        end % get.Quantity2

        function set.Quantity2( obj, Q )

            truncateAndAssignQ2( obj, Q )

        end % set.Quantity2

    end % methods

    methods

        function obj = EdgeworthBowleyChart( namedArgs )
            %EDGEWORTHBOWLEYCHART Construct an EdgeworthBowleyChart, given
            %optional name-value arguments.

            arguments ( Input )
                namedArgs.?EdgeworthBowleyChart
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

        function varargout = title( obj, varargin )

            [varargout{1:nargout}] = title( obj.Axes, varargin{:} );

        end % title

        function grid( obj, varargin )

            grid( obj.Axes, varargin{:} )

        end % grid

        function varargout = axis( obj, varargin )
            
            [varargout{1:nargout}] = axis( obj.Axes, varargin{:} );

        end % axis

    end % methods

    methods ( Access = protected )

        function setup( obj )
            %SETUP Initialize the chart graphics.

            % The chart's axes.
            obj.Axes = axes( "Parent", obj.getLayout() );

            % The contract line.
            obj.ContractLine = line( "Parent", obj.Axes, ...
                "XData", NaN, ...
                "YData", NaN, ...
                "Color", [0 0.5 0], ...
                "LineStyle", "-", ...
                "Linewidth", 2, ...
                "LineJoin", "round" );

            % Utility lines for A.
            obj.AUtilityLines = line( "Parent", obj.Axes, ...
                "XData", NaN, ...
                "YData", NaN, ...
                "LineWidth", 1.5, ...
                "Color", [0.5 0.5 0.5] );

            % Utility lines for B.
            obj.BUtilityLines = line( "Parent", obj.Axes, ...
                "XData", NaN, ...
                "YData", NaN, ...
                "LineWidth", 1.5, ...
                "Color", [0.5 0.5 0.5] );

            % Scattered points.
            obj.ScatterPoints = line( "Parent", obj.Axes, ...
                "XData", NaN, ...
                "YData", NaN, ...
                "Color", [0.5 0.5 0.8], ...
                "Marker", ".", ...
                "MarkerSize", 8, ...
                "LineStyle", "none" );

            % Annotations.
            xlabel( obj.Axes, "Quantity 1" );
            ylabel( obj.Axes, "Quantity 2" );
            title( obj.Axes, "Edgeworth-Bowley Chart" )
            grid( obj.Axes, "on" )

        end % setup

        function update( obj )
            %UPDATE Refresh the chart graphics.

            % Update the chart graphics.
            plotScatter( obj ) % Plot the AData and BData
            fitCurves( obj ) % Obtain the fitted curves
            plotFittedCurves( obj ) % Plot the fitted lines
            axis( obj.Axes, [0, obj.Quantity1_, ...
                0, obj.Quantity2_] )
            paretoSet( obj ) % Evaluate the Pareto set
            plotPareto( obj ) % Plot the Pareto Set
            set( obj.AUtilityLines, "LineWidth", obj.LineWidth )
            set( obj.BUtilityLines, "LineWidth", obj.LineWidth )
            set( obj.ContractLine, "LineWidth", obj.LineWidth )
            obj.ScatterPoints.MarkerSize = obj.MarkerSize;

        end % update

    end % methods ( Access = protected )

    methods ( Access = private )

        function fitCurves( obj )
            %FITCURVES Obtain the curves fitted from AData and BData and
            %store the values in the ACurveFit and BCurveFit properties.

            % Handle possible warning messages.
            w = warning();
            oc = onCleanup( @() warning( w ) );
            warning( "off" )

            ncols = width( obj.AData );

            % Fit AData
            if ~isempty( obj.AData_ )
                x = obj.AData_(:, 1);
                obj.ACoefficients = zeros( width( obj.AData_ )-1, 3 );
                idx = false( height( obj.AData_ ), ncols-1 );
                for k = 2:ncols
                    y = obj.AData_(:, k);
                    if any(~isnan(y)) % If y contains any number
                        hyprb = @(b, x) b(1) + b(2)./(x - b(3));  % Generalised Hyperbola
                        B0 = [0; obj.Quantity1_; 0];
                        mdl = fitnlm( x, y, hyprb, B0 );
                        obj.ACoefficients(k-1, :) = mdl.Coefficients.Estimate';% Store the coefficients
                        obj.ACurveFit(:, k-1) = hyprb( mdl.Coefficients.Estimate, x );
                        idx(:, k-1) = obj.ACurveFit(:, k-1) < mdl.Coefficients.Estimate(1);
                    else % If all y is NaN
                        obj.ACoefficients(k-1, :) = NaN( 1, 3 );
                        obj.ACurveFit(:, k-1) = NaN;
                        idx(:, k-1) = obj.ACurveFit(:,k-1) < mdl.Coefficients.Estimate(1);
                    end % if
                end % for
                obj.ACurveFit(idx(:, 2:end)) = NaN;
                idx = obj.ACurveFit > obj.Quantity2_;
                obj.ACurveFit(idx)= NaN;
            end % if

            % Fit BData
            if ~isempty( obj.BData_ )
                x = obj.BData_(:, 1);
                obj.BCoefficients = zeros( width( obj.AData_ )-1, 3 );
                idx = false( height( obj.BData_ ), ncols-1 );
                for k = 2:ncols
                    y = obj.BData_(:, k);
                    if any(~isnan(y))
                        hyprb = @(b, x) b(1) + b(2)./(x - b(3));
                        B0 = [0; obj.Quantity1_; 0];
                        mdl = fitnlm( x, y, hyprb, B0 );
                        obj.BCoefficients(k-1, :) = ...
                            mdl.Coefficients.Estimate';
                        obj.BCurveFit(:, k-1) = ...
                            hyprb( mdl.Coefficients.Estimate, x );
                        idx(:, k-1) = obj.BCurveFit(:, k-1) ...
                            < mdl.Coefficients.Estimate(1);
                    else
                        obj.BCoefficients(k-1, :) = NaN( 1, 3 );
                        obj.BCurveFit(:, k-1) = NaN;
                        idx(:, k-1) = obj.BCurveFit(:, k-1) ...
                            < mdl.Coefficients.Estimate(1);
                    end % if
                end % for
                obj.BCurveFit(idx(:, 2:end)) = NaN;
                idx = abs(obj.BCurveFit) > obj.Quantity2_ | ...
                    obj.BCurveFit < 0;
                obj.BCurveFit(idx) = NaN;
            end % if

            % Check the hyperbolas are consistent (they do not intersect).

            % AData.
            if ~isempty( obj.ACoefficients )
                k = 0;
                for i = 2 : height( obj.ACoefficients )
                    if ~isnan( obj.ACoefficients(i-1-k, 3) )
                        a3 = obj.ACoefficients(i-1-k, 3);
                    end % Check the previous third element is not a NaN
                    if ~isnan( obj.ACoefficients(i-1-k, 1) )
                        a1 = obj.ACoefficients(i-1-k, 1);
                    end % Check the previous first element is not a NaN
                    if (obj.ACoefficients(i-k,3)+1) < a3 || ...
                            (obj.ACoefficients(i-k,1)+1) < a1
                        obj.ACoefficients = ...
                            obj.ACoefficients([1:i-1-k i+1-k:end ],:);
                        k = k+1;
                        obj.ACurveFit(:, i) = NaN;
                        obj.AData_(:, i) = NaN;
                    end % if
                end % for
            end % if

            % BData.
            if ~isempty( obj.BCoefficients )
                k = 0;
                for i = 2 : height( obj.BCoefficients )
                    if ~isnan( obj.BCoefficients(i-1-k, 3) )
                        b3 = obj.BCoefficients(i-1-k, 3);
                    end % Check the previous third element is not a NaN
                    if ~isnan( obj.BCoefficients(i-1-k, 1) )
                        b1 = obj.BCoefficients(i-1-k, 1);
                    end % Check the previous first element is not a NaN
                    if (obj.BCoefficients(i-k, 3)+1) < b3 || ...
                            (obj.BCoefficients(i-k, 1)+1) < b1
                        obj.BCoefficients = ...
                            obj.BCoefficients([1:i-1-k i+1-k:end ], :);
                        k = k+1;
                        obj.BCurveFit(:, i) = NaN;
                        obj.BData_(:, i) = NaN;
                    end % if
                end % for
            end % if

        end % fitCurves

        function plotFittedCurves( obj )
            %PLOTFITTEDCURVES Plot the fitted curves.

            if ~isempty( obj.ACurveFit ) % Check there is obj.AData_
                nCurvesA = width( obj.ACurveFit );
                x = obj.AData_(:, 1);
                for k = 1:nCurvesA
                    y = obj.ACurveFit(:, k);
                    if height( obj.AUtilityLines ) < k
                        obj.AUtilityLines(k, 1) = ...
                            line( "Parent", obj.Axes, ...
                            "XData", x, ...
                            "YData", y, ...
                            "LineStyle", "-", ...
                            "LineWidth", 1.5, ...
                            "Color", [0.5 0.5 0.6] );
                    else
                        set( obj.AUtilityLines(k,1),...
                            "XData", x,...
                            "YData", y, ...
                            "LineStyle", "-", ...
                            "Color", [0.5 0.5 0.6] )
                    end % if
                end % for
            end % if

            if ~isempty( obj.BCurveFit ) % Check there is obj.BData_
                % Invert the curves
                BCF = obj.BCurveFit;
                BCF = flipud( BCF );
                BCF = obj.Quantity2_ - BCF;
                nCurvesB = width( BCF );
                x = obj.BData_(:, 1);
                for k = 1:nCurvesB
                    y = BCF(:, k);
                    if height( obj.BUtilityLines ) < k
                        obj.BUtilityLines(k, 1) = line( ...
                            "Parent", obj.Axes, ...
                            "XData", x, ...
                            "YData", y, ...
                            "LineStyle", "-",...
                            "LineWidth", 1.5, ...
                            "Color", [0.5 0.5 0.6] );
                    else
                        set( obj.BUtilityLines(k,1), "XData", x,...
                            "YData", y, ...
                            "LineStyle", "-",...
                            "Color", [0.5 0.5 0.6] )
                    end % if
                end % for
            end % if

        end % plotFittedCurves

        function paretoSet( obj )
            %PARETOSET Obtain the Pareto set from the curves stored in the
            %ACurvedFit and BCurveFit properties and store it in the
            %ParetoSet property.

            % Initialize the property.
            obj.ParetoSet = [obj.Quantity1, obj.Quantity2; 0, 0];

            % Compute the Pareto set.
            if ~isempty( obj.ACurveFit ) && ~isempty( obj.BCurveFit )
                Mx = obj.Quantity1;
                My = obj.Quantity2;
                for k = 1 : height( obj.ACoefficients ) - 1
                    a1 = obj.ACoefficients(k, 1);
                    a2 = obj.ACoefficients(k, 2);
                    a3 = obj.ACoefficients(k, 3);
                    distance = obj.Quantity1_ * obj.Quantity2_;
                    for l = 1:height( obj.BCoefficients )-1
                        b1 = obj.BCoefficients(l, 1);
                        b2 = obj.BCoefficients(l, 2);
                        b3 = obj.BCoefficients(l, 3);
                        % Check the two curves intersect.
                        % Ya  = a1 + a2/(x-a3);
                        % Yb = My - [b1 + b2/(Mx-x-b3);
                        YaMax = a1 + a2/(0.1);
                        YaMin = a1 + a2/(Mx - a3);
                        YbMax = My - (b1 + b2/(Mx-0.1));
                        YbMin = My - (b1 + b2/(0.1));
                        if YaMax > YbMax && YaMin > YbMin
                            xroots = [(b2 - a2 + Mx*a1 - My*a3 + Mx*b1 + My*b3 + a1*a3 - a1*b3 + a3*b1 - b1*b3 + (Mx^2*My^2 - 2*Mx^2*My*a1 - 2*Mx^2*My*b1 + Mx^2*a1^2 + 2*Mx^2*a1*b1 + Mx^2*b1^2 - 2*Mx*My^2*a3 - 2*Mx*My^2*b3 + 4*Mx*My*a1*a3 + 4*Mx*My*a1*b3 - 2*Mx*My*a2 + 4*Mx*My*a3*b1 + 4*Mx*My*b1*b3 - 2*Mx*My*b2 - 2*Mx*a1^2*a3 - 2*Mx*a1^2*b3 + 2*Mx*a1*a2 - 4*Mx*a1*a3*b1 - 4*Mx*a1*b1*b3 + 2*Mx*a1*b2 + 2*Mx*a2*b1 - 2*Mx*a3*b1^2 - 2*Mx*b1^2*b3 + 2*Mx*b1*b2 + My^2*a3^2 + 2*My^2*a3*b3 + My^2*b3^2 - 2*My*a1*a3^2 - 4*My*a1*a3*b3 - 2*My*a1*b3^2 + 2*My*a2*a3 + 2*My*a2*b3 - 2*My*a3^2*b1 - 4*My*a3*b1*b3 + 2*My*a3*b2 - 2*My*b1*b3^2 + 2*My*b2*b3 + a1^2*a3^2 + 2*a1^2*a3*b3 + a1^2*b3^2 - 2*a1*a2*a3 - 2*a1*a2*b3 + 2*a1*a3^2*b1 + 4*a1*a3*b1*b3 - 2*a1*a3*b2 + 2*a1*b1*b3^2 - 2*a1*b2*b3 + a2^2 - 2*a2*a3*b1 - 2*a2*b1*b3 - 2*a2*b2 + a3^2*b1^2 + 2*a3*b1^2*b3 - 2*a3*b1*b2 + b1^2*b3^2 - 2*b1*b2*b3 + b2^2)^(1/2) - Mx*My)/(2*(a1 - My + b1))
                                -(a2 - b2 - Mx*a1 + My*a3 - Mx*b1 - My*b3 - a1*a3 + a1*b3 - a3*b1 + b1*b3 + (Mx^2*My^2 - 2*Mx^2*My*a1 - 2*Mx^2*My*b1 + Mx^2*a1^2 + 2*Mx^2*a1*b1 + Mx^2*b1^2 - 2*Mx*My^2*a3 - 2*Mx*My^2*b3 + 4*Mx*My*a1*a3 + 4*Mx*My*a1*b3 - 2*Mx*My*a2 + 4*Mx*My*a3*b1 + 4*Mx*My*b1*b3 - 2*Mx*My*b2 - 2*Mx*a1^2*a3 - 2*Mx*a1^2*b3 + 2*Mx*a1*a2 - 4*Mx*a1*a3*b1 - 4*Mx*a1*b1*b3 + 2*Mx*a1*b2 + 2*Mx*a2*b1 - 2*Mx*a3*b1^2 - 2*Mx*b1^2*b3 + 2*Mx*b1*b2 + My^2*a3^2 + 2*My^2*a3*b3 + My^2*b3^2 - 2*My*a1*a3^2 - 4*My*a1*a3*b3 - 2*My*a1*b3^2 + 2*My*a2*a3 + 2*My*a2*b3 - 2*My*a3^2*b1 - 4*My*a3*b1*b3 + 2*My*a3*b2 - 2*My*b1*b3^2 + 2*My*b2*b3 + a1^2*a3^2 + 2*a1^2*a3*b3 + a1^2*b3^2 - 2*a1*a2*a3 - 2*a1*a2*b3 + 2*a1*a3^2*b1 + 4*a1*a3*b1*b3 - 2*a1*a3*b2 + 2*a1*b1*b3^2 - 2*a1*b2*b3 + a2^2 - 2*a2*a3*b1 - 2*a2*b1*b3 - 2*a2*b2 + a3^2*b1^2 + 2*a3*b1^2*b3 - 2*a3*b1*b2 + b1^2*b3^2 - 2*b1*b2*b3 + b2^2)^(1/2) + Mx*My)/(2*(a1 - My + b1))];
                            if xroots(1) > a3  && xroots(2) > a3 && isreal( xroots )
                                yroots = a1 + a2./(xroots - a3);
                                xpareto = xroots(1) + 0.5 * (xroots(2)-xroots(1));
                                ypareto = yroots(1) + 0.5 * (yroots(2)-yroots(1));
                                distanceAns = distance;
                                distance = sqrt( (xroots(2)-xroots(1))^2+(yroots(2)-yroots(1))^2 );
                                if distance < distanceAns
                                    ParetoPoint = [xpareto, ypareto];
                                end % if
                            end % if
                        end % if
                    end % for
                    if any( ParetoPoint ~= obj.ParetoSet(2, :) )
                        obj.ParetoSet = [obj.ParetoSet(1,:); ParetoPoint; obj.ParetoSet(2:end,:)];
                    end % if
                end % for

                % Smooth the line.
                queryPoints = 0:0.01:Mx;
                PS = pchip(obj.ParetoSet(:,1)', obj.ParetoSet(:,2)', queryPoints);
                obj.ParetoSet = [queryPoints', PS'];

            end % if

        end % paretoSet

        function plotScatter( obj )
            %PLOTSCATTER Visualize the values from AData_ and BData_ to the
            %corresponding chart graphics.

            % Reverse the BData matrix.
            BD = obj.BData_;
            BD(:, 2:end) = flipud( BD(:, 2:end) );
            BD(:, 2:end) = obj.Quantity2_ - BD(:, 2:end);
            ncolsA = width( obj.AData_ );
            ncolsB = width( obj.BData_ );
            if isempty( obj.AData_ )
                nrows = height( obj.BData_ );
            else
                nrows = height( obj.AData_ );
            end % if

            y = zeros( nrows*(ncolsA+ncolsB-2), 1 );
            x = zeros( nrows*(ncolsA+ncolsB-2), 1 );

            for k = 2:ncolsA
                x((k-2)*nrows+1:(k-1)*nrows) = obj.AData_(:, 1);
                y((k-2)*nrows+1:(k-1)*nrows) = obj.AData_(:, k);
            end % for

            for k = 2+ncolsB:2*ncolsB
                x((k-2)*nrows+1:(k-1)*nrows) = obj.BData_(:, 1);
                y((k-2)*nrows+1:(k-1)*nrows) = BD(:, k-ncolsB);
            end % for

            xlim( obj.Axes, [0, obj.Quantity1] )
            ylim( obj.Axes, [0, obj.Quantity2] )
            set( obj.ScatterPoints, "XData", x, "YData", y )

        end % plotScatter

        function plotPareto( obj )
            %PLOTPARETO Update the contract line using the values from the
            %Pareto set.

            if ~isempty( obj.AData_ ) && ~isempty( obj.BData_ ) && ...
                    ~isempty( obj.ParetoSet )
                x = obj.ParetoSet(:, 1);
                y = obj.ParetoSet(:, 2);
                set( obj.ContractLine, "XData", x, "YData", y )
            end % if

        end % plotPareto

        function truncateAndAssignQ1( obj, Q )

            % If Q differs from the current quantity by too large a margin,
            % recall the method with an adjusted value of Q.
            currentQ = obj.Quantity1_;
            if (Q-currentQ) > 1
                truncateAndAssignQ1( obj, Q-1 );
            elseif (Q-currentQ) < -1
                truncateAndAssignQ1( obj, Q+1 );
            end % if

            % Update the chart's internal data properties.
            currentQ = obj.Quantity1_;
            if Q > currentQ
                step = diff( obj.AData_(1:2, 1) );
                num_steps = (Q-currentQ)/step+1;
                obj.AData_ = [obj.AData_; (currentQ:step:Q)', ...
                    NaN( num_steps, width( obj.AData_ )-1)];
                obj.BData_ = [obj.BData_; (currentQ:step:Q)', ...
                    NaN( num_steps, width( obj.BData_ )-1)];
                obj.ACurveFit = obj.AData(:, 2:end);
                obj.BCurveFit = obj.BData(:, 2:end);
                obj.ParetoSet = [0 0; 0 0];
            elseif Q < currentQ
                obj.AData_ = obj.AData_(1:sum( Q>obj.AData_(:, 1) ), :);
                obj.BData_ = obj.BData_(1:sum( Q>obj.BData_(:, 1) ), :);
                obj.ACurveFit = obj.AData(:, 2:end);
                obj.BCurveFit = obj.BData(:, 2:end);
                obj.ParetoSet = [0 0; 0 0];
            end

            % Store the quantity and update the Pareto set.
            obj.Quantity1_ = Q;
            obj.ParetoSet(end, 1) = obj.Quantity1_;

        end % truncateAndAssignQ1

        function truncateAndAssignQ2( obj, Q )

            % If Q differs from the current quantity by too large a margin,
            % recall the method with an adjusted value of Q.
            currentQ = obj.Quantity2_;
            if (Q-currentQ) > 1
                truncateAndAssignQ2( obj, Q-1 );
            elseif (Q-currentQ) < -1
                truncateAndAssignQ2( obj, Q+1 );
            end % if

            % Update the chart's internal data properties.
            % If any Y data is bigger than the maximum quantity
            if Q < currentQ
                idx = obj.AData_(:, 2:end) > Q;
                obj.AData_([false( height( idx ), 1 ), idx]) = NaN;
                idx = obj.BData_(:, 2:end) > Q;
                obj.BData_([false( height( idx ), 1 ), idx]) = NaN;
                obj.ACurveFit = obj.AData(:, 2:end);
                obj.BCurveFit = obj.BData(:, 2:end);
                obj.ParetoSet = zeros( 2 );
            end % if

            % Store the quantity and update the Pareto set.
            obj.Quantity2_ = Q;
            obj.ParetoSet(end, 2) = obj.Quantity2_;

        end % truncateAndAssignQ2

    end % methods ( Access = private )

end % classdef