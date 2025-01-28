classdef ( SharedTestFixtures = {FigureFixture} ) ...
        tScatterFit < matlab.uitest.TestCase & matlab.mock.TestCase
    %TSCATTERFIT Test harness for the ScatterFit chart.
    
    properties ( Access = private )
        % The chart under test.
        Chart(:, 1) chart.ScatterFit {mustBeScalarOrEmpty}
        % Sample chart data for testing.
        Data(1, 1) struct = load( "ChartData.mat" )
    end % properties ( Access = private )
    
    methods ( TestClassSetup )
        
        function chartSetup( obj )
            
            % Initialize the chart.
            fx = obj.getSharedTestFixtures( "FigureFixture" );
            obj.Chart = chart.ScatterFit( "Parent", fx.Figure, ...
                "Units", "normalized", ...
                "Position", [0, 0, 1, 1] );
            % Define the teardown action.
            obj.addTeardown( @() delete( obj.Chart ) )
            
        end % chartSetup
        
    end % methods ( TestClassSetup )
    
    methods ( Test )
        
        function testClassAndSizeAndParent( obj )
            
            % Check that we have a 1-by-1 ScatterFit chart with the
            % correct parent.
            obj.verifyClass( obj.Chart, "chart.ScatterFit" )
            obj.verifySize( obj.Chart, [1, 1] )
            fx = obj.getSharedTestFixtures( "FigureFixture" );
            obj.verifySameHandle( obj.Chart.Parent, fx.Figure )
            
        end % testClassAndSizeAndParent
        
        function testSettingChartDataUpdatesChartGraphics( obj )
            
            % Set data in the chart (empty to non-empty).
            set( obj.Chart, "XData", obj.Data.x, "YData", obj.Data.y )
            drawnow()
            
            % Verify that the chart graphics have been updated.
            obj.verifyThat( obj.Chart.XData, ...
                IsEqualVector( obj.Data.x, "RelTol", 1e-6 ) )
            obj.verifyThat( obj.Chart.YData, ...
                IsEqualVector( obj.Data.y, "RelTol", 1e-6 ) )
            obj.verifyNotEmpty( obj.Chart.BestFitLine.XData )
            obj.verifyNotEmpty( obj.Chart.BestFitLine.YData )
            
            % Revert the chart data to empty vectors.
            emptyVec = double.empty( 0, 1 );
            set( obj.Chart, "XData", emptyVec, "YData", emptyVec )
            drawnow()
            
            % Verify that the chart graphics have been updated.
            obj.verifyThat( obj.Chart.XData, IsEqualVector( emptyVec ) )
            obj.verifyThat( obj.Chart.YData, IsEqualVector( emptyVec ) )
            obj.verifyThat( obj.Chart.BestFitLine.XData, ...
                IsEqualVector( emptyVec ) )
            obj.verifyThat( obj.Chart.BestFitLine.YData, ...
                IsEqualVector( emptyVec ) )
            
            % Set scalar values.
            x0 = 0; y0 = 0;
            set( obj.Chart, "XData", x0, "YData", y0 )
            drawnow()
            
            % Verify that the chart graphics have been updated.
            obj.verifyEqual( obj.Chart.XData, x0 )
            obj.verifyEqual( obj.Chart.YData, y0 )
            obj.verifyNotEmpty( obj.Chart.BestFitLine.XData )
            obj.verifyNotEmpty( obj.Chart.BestFitLine.YData )
            
        end % testSettingChartDataUpdatesChartGraphics
        
        function testTruncatingAndPaddingChartDataUpdatesChartGraphics( obj )
            
            % Modify the chart data (long to short, x first).
            obj.Chart.XData = obj.Data.xnew;
            obj.Chart.YData = obj.Data.ynew;
            drawnow()
            
            % Verify that the chart graphics have been updated.
            obj.verifyThat( obj.Chart.XData, ...
                IsEqualVector( obj.Data.xnew, "RelTol", 1e-6 ) )
            obj.verifyThat( obj.Chart.YData, ...
                IsEqualVector( obj.Data.ynew, "RelTol", 1e-6 ) )
            obj.verifyNotEmpty( obj.Chart.BestFitLine.XData )
            obj.verifyNotEmpty( obj.Chart.BestFitLine.YData )
            
            % Modify the chart data (short to long, x first).
            obj.Chart.XData = obj.Data.x;
            obj.Chart.YData = obj.Data.y - 100;
            drawnow()
            
            % Verify that the chart graphics have been updated.
            obj.verifyThat( obj.Chart.XData, ...
                IsEqualVector( obj.Data.x, "RelTol", 1e-6 ) )
            obj.verifyThat( obj.Chart.YData, ...
                IsEqualVector( obj.Data.y - 100, "RelTol", 1e-6 ) )
            obj.verifyNotEmpty( obj.Chart.BestFitLine.XData )
            obj.verifyNotEmpty( obj.Chart.BestFitLine.YData )
            
            % Modify the chart data (long to short, y first).
            obj.Chart.YData = -obj.Data.ynew;
            obj.Chart.XData = -obj.Data.xnew;
            drawnow()
            
            % Verify that the chart graphics have been updated.
            obj.verifyThat( obj.Chart.XData, ...
                IsEqualVector( -obj.Data.xnew, "RelTol", 1e-6 ) )
            obj.verifyThat( obj.Chart.YData, ...
                IsEqualVector( -obj.Data.ynew, "RelTol", 1e-6 ) )
            obj.verifyNotEmpty( obj.Chart.BestFitLine.XData )
            obj.verifyNotEmpty( obj.Chart.BestFitLine.YData )
            
            % Modify the chart data (short to long, y first).
            obj.Chart.YData = obj.Data.y;
            obj.Chart.XData = obj.Data.x;
            drawnow()
            
            % Verify that the chart graphics have been updated.
            obj.verifyThat( obj.Chart.XData, ...
                IsEqualVector( obj.Data.x, "RelTol", 1e-6 ) )
            obj.verifyThat( obj.Chart.YData, ...
                IsEqualVector( obj.Data.y, "RelTol", 1e-6 ) )
            obj.verifyNotEmpty( obj.Chart.BestFitLine.XData )
            obj.verifyNotEmpty( obj.Chart.BestFitLine.YData )
            
        end % testTruncatingAndPaddingChartDataUpdatesChartGraphics
        
        function testSettingSizeAndColorUpdatesGraphics( obj )
            
            % Modify the size data of the chart: use a constant value.
            newSize = 64;
            set( obj.Chart, "XData", obj.Data.x, ...
                "YData", obj.Data.y, "SizeData", newSize )
            drawnow()
            obj.verifyEqual( obj.Chart.ScatterSeries.SizeData, newSize, ...
                "RelTol", 1e-6 )
            
            % Modify the size data of the chart: use variable sizes.
            newSizes = 1:length( obj.Chart.XData );
            obj.Chart.SizeData = newSizes;
            drawnow()
            obj.verifyThat( obj.Chart.ScatterSeries.SizeData, ...
                IsEqualVector( newSizes, "RelTol", 1e-6 ) )
            
            % Modify the chart's data.
            set( obj.Chart, "XData", obj.Data.xnew, ...
                "YData", obj.Data.ynew )
            drawnow()
            % Verify that the size data has been reset.
            obj.verifyEqual( obj.Chart.SizeData, 36, "RelTol", 1e-6 )
            
            % Modify the color: use a constant value.
            newColor = [1, 0, 0];
            obj.Chart.CData = newColor;
            drawnow()
            obj.verifyEqual( obj.Chart.CData, newColor, "RelTol", 1e-6 )
            
            % Modify the color data of the chart: use variable colors.
            newColors = hsv( length( obj.Chart.XData ) );
            obj.Chart.CData = newColors;
            drawnow()
            obj.verifyEqual( obj.Chart.CData, newColors, "RelTol", 1e-6 )
            
            % Modify the chart's data.
            set( obj.Chart, "YData", obj.Data.y, "XData", obj.Data.x )
            drawnow()
            % Verify that the color has been reset.
            c = colororder();
            obj.verifyEqual( obj.Chart.CData, c(1, :), "RelTol", 1e-6 )
            
            % Test other combinations of XData, YData, CData and SizeData.
            currentLength = length( obj.Chart.XData );
            set( obj.Chart, "CData", hsv( currentLength ), ...
                "SizeData", 1:currentLength, "XData", obj.Data.xnew )
            drawnow()
            obj.verifyEqual( obj.Chart.CData, c(1, :), "RelTol", 1e-6 )
            obj.verifyEqual( obj.Chart.SizeData, 36, "RelTol", 1e-6 )
            currentLength = length( obj.Chart.XData );
            set( obj.Chart, "CData", hsv( currentLength ), ...
                "SizeData", 1:currentLength, "YData", obj.Data.y )
            drawnow()
            obj.verifyEqual( obj.Chart.CData, c(1, :), "RelTol", 1e-6 )
            obj.verifyEqual( obj.Chart.SizeData, 36, "RelTol", 1e-6 )
            
        end % testSettingSizeAndColorUpdatesGraphics
        
        function testGettingAndSettingLineVisibility( obj )
            
            % Uncheck the box.
            obj.choose( obj.Chart.BestFitLineCheckBox, false )
            
            % Verify that the line is not visible.
            obj.verifyFalse( obj.Chart.LineVisible )
            
            % Check the box.
            obj.choose( obj.Chart.BestFitLineCheckBox, true )
            
            % Verify that the line is visible.
            obj.verifyTrue( obj.Chart.LineVisible )
            
            % Modify the chart programmatically.
            obj.Chart.LineVisible = "off";
            obj.verifyFalse( obj.Chart.BestFitLineCheckBox.Value )
            obj.Chart.LineVisible = "on";
            obj.verifyTrue( obj.Chart.BestFitLineCheckBox.Value )
            
        end % testGettingAndSettingLineVisibility
        
        function testGettingAndSettingLineWidth( obj )
            
            % Spin up.
            obj.press( obj.Chart.LineWidthSpinner, "up" )
            obj.verifyEqual( ...
                obj.Chart.LineWidth, obj.Chart.LineWidthSpinner.Value, ...
                "RelTol", 1e-6 )
            
            % Spin down.
            obj.press( obj.Chart.LineWidthSpinner, "down" )
            obj.verifyEqual( ...
                obj.Chart.LineWidth, obj.Chart.LineWidthSpinner.Value, ...
                "RelTol", 1e-6 )
            
            % Enter a specific value.
            lw = 3.5;
            obj.type( obj.Chart.LineWidthSpinner, lw )
            obj.verifyEqual( obj.Chart.LineWidth, lw )
            
            % Modify the chart programmatically.
            lw = 5;
            obj.Chart.LineWidth = lw;
            obj.verifyEqual( obj.Chart.LineWidthSpinner.Value, lw, ...
                "RelTol", 1e-6 )
            
        end % testGettingAndSettingLineWidth
        
        function testGettingAndSettingLineStyle( obj )
            
            % Select an item from the dropdown menu.
            obj.choose( obj.Chart.LineStyleDropDown, ":" )
            obj.verifyThat( obj.Chart.LineStyle, ...
                IsEquivalentText( obj.Chart.LineStyleDropDown.Value ) )
            
            % Modify the chart programmatically.
            ls = "-";
            obj.Chart.LineStyle = ls;
            obj.verifyThat( obj.Chart.LineStyleDropDown.Value, ...
                IsEquivalentText( ls ) )
            
        end % testGettingAndSettingLineStyle
        
        function testGettingAndSettingLineColor( obj )
            
            % Test the interactive button via mocking.
            [mockColorPicker, behavior] = obj.createMock( ?ColorPicker );
            
            % Define the behavior when the uisetcolor() method is invoked.
            blue = [0, 0, 1];
            obj.assignOutputsWhen( ...
                withAnyInputs( behavior.uisetcolor() ), blue )
            
            % Inject the mock color picker.
            obj.Chart.ColorPicker = mockColorPicker;
            obj.addTeardown( ...
                @() set( obj.Chart, "ColorPicker", DefaultColorPicker() ) )
            
            % Press the button to trigger the color selection.
            obj.press( obj.Chart.LineColorButton )
            pause( 1 )
            
            % Verify that the color has been set in the line and button
            % icon.
            obj.verifyEqual( obj.Chart.LineColor, blue, "RelTol", 1e-6 )
            obj.verifyThat( obj.Chart.LineColorButton.Icon(1, 1, :), ...
                IsEqualVector( blue, "RelTol", 1e-6 ) )
            
            % Modify the chart programmatically.
            red = [1, 0, 0];
            obj.Chart.LineColor = red;
            obj.verifyEqual( obj.Chart.LineColor, red, "RelTol", 1e-6 )
            obj.verifyThat( obj.Chart.LineColorButton.Icon(1, 1, :), ...
                IsEqualVector( red, "RelTol", 1e-6 ) )
            
        end % testGettingAndSettingLineColor
        
        function testGettingAndSettingMarker( obj )
            
            % Select an item from the dropdown menu.
            obj.choose( obj.Chart.MarkerDropDown, "o" )
            obj.verifyThat( obj.Chart.Marker, ...
                IsEquivalentText( obj.Chart.MarkerDropDown.Value ) )
            
            % Modify the chart programmatically.
            m = "square";
            obj.Chart.Marker = m;
            obj.verifyThat( obj.Chart.MarkerDropDown.Value, ...
                IsEquivalentText( m ) )
            
        end % testGettingAndSettingMarker
        
        function testSettingGridOptionsUpdatesGraphics( obj )
            
            % Select the x/y grid options, and modify the chart
            % programmatically.
            d = ["X", "Y"];
            for k = 1:length( d )
                % Selection.
                dGrid = d(k) + "Grid";
                obj.choose( obj.Chart.GridCheckBoxes(k), true )
                obj.verifyTrue( obj.Chart.(dGrid) )
                obj.choose( obj.Chart.GridCheckBoxes(k), false )
                obj.verifyFalse( obj.Chart.(dGrid) )
                % Chart modification.
                obj.Chart.(dGrid) = "on";
                obj.verifyTrue( obj.Chart.GridCheckBoxes(k).Value )
                obj.Chart.(dGrid) = "off";
                obj.verifyFalse( obj.Chart.GridCheckBoxes(k).Value )
            end % for
            
        end % testSettingGridOptionsUpdatesGraphics
        
        function testCallingAnnotationsUpdatesGraphics( obj )
            
            % Define some sample text to use.
            sampleText = "Chart under test";
            sampleLegendText = ["Scattered data", "Best-fit line"];
            
            % xlabel.
            xlabel( obj.Chart, sampleText )
            obj.verifyThat( obj.Chart.Axes.XLabel.String, ...
                IsEquivalentText( sampleText ) )
            
            % ylabel.
            ylabel( obj.Chart, sampleText )
            obj.verifyThat( obj.Chart.Axes.YLabel.String, ...
                IsEquivalentText( sampleText ) )
            
            % title.
            title( obj.Chart, sampleText )
            obj.verifyThat( obj.Chart.Axes.Title.String, ...
                IsEquivalentText( sampleText ) )
            
            % legend.
            legend( obj.Chart, sampleLegendText )
            obj.verifyThat( obj.Chart.Axes.Legend.String, ...
                IsEquivalentText( sampleLegendText ) )
            
            % grid.
            grid( obj.Chart, "on" )
            obj.verifyTrue( obj.Chart.XGrid )
            obj.verifyTrue( obj.Chart.YGrid )
            grid( obj.Chart, "off" )
            obj.verifyFalse( obj.Chart.XGrid )
            obj.verifyFalse( obj.Chart.YGrid )
            
        end % testCallingAnnotationsUpdatesGraphics
        
        function testTogglingControlsUpdatesLayout( obj )
            
            % Modify the chart programmatically.
            obj.Chart.Controls = "off";
            drawnow()
            obj.verifyThat( obj.Chart.LayoutGrid.ColumnWidth, ...
                IsEquivalentText( ["1x", "0x"] ) )
            obj.verifyFalse( obj.Chart.Controls )
            obj.Chart.Controls = "on";
            drawnow()
            obj.verifyThat( obj.Chart.LayoutGrid.ColumnWidth, ...
                IsEquivalentText( ["1x", "fit"] ) )
            obj.verifyTrue( obj.Chart.Controls )
            
        end % testTogglingControlsUpdatesLayout
        
    end % methods ( Test )
    
end % class definition