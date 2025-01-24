function exportChartImage( names )
%EXPORTCHARTIMAGE Export chart images with transparent backgrounds for use
%in the example scripts, and smaller icons for use with the chart browser.
%Call this function with no inputs to regenerate and export all images.
%Alternatively, provide a list of required chart names. Only the specified
%chart images will be exported.

% Copyright 2024-2025 The MathWorks, Inc.

arguments ( Input )
    names(1, :) string {mustBeChartName} = string.empty( 1, 0 )
end % arguments ( Input )

% No input or an empty string means we should update all images.
if isempty( names )
    names = chartNames();
end % if

% Export the required images.
for name = names
    feval( "export" + name )
end % for

end % exportChartImage

function mustBeChartName( str )
%MUSTBECHARTNAME Verify that the input string array, str, contains valid
%chart names.

mustBeMember( str, allChartNames() )

end % mustBeChartName

function p = exportPath()
%EXPORTPATH Return the export folder.

arguments ( Output )
    p(1, 1) string {mustBeFolder}
end % arguments ( Output )

p = fullfile( chartsRoot(), "app", "images" );

end % exportPath

function exportAircraftChart()
%EXPORTAIRCRAFTCHART Export the AircraftChart.

% Create the chart.
f = uifigure();
figureCleanup = onCleanup( @() delete( f ) );
AC = AircraftChart( "Parent", f );

% Remove the title and axes and change the view.
title( AC, "" );
axis( AC, "off" )
view( AC, 2 )

% Export.
exportImage( "AircraftChart", AC )

end % exportAircraftChart

function exportAnnulusChart()
%EXPORTANNULUSCHART Export the AnnulusChart.

% Reset the seed.
s = rng();
rngCleanup = onCleanup( @() rng( s ) );
rng( "default" )

% Create the chart.
f = uifigure();
figureCleanup = onCleanup( @() delete( f ) );
AC = AnnulusChart( "Parent", f, ...
    "Data", randperm( 10 ), ...
    "FaceColor", hsv( 10 ), ...
    "LegendVisible", "off", ...
    "LabelVisible", "off" );

% Remove the title and fix the view.
title( AC, "" );
view( AC, 2 )
pause( 0.5 )

% Export.
exportImage( "AnnulusChart", AC )

end % exportAnnulusChart

function exportCircularNetFlowChart()
%EXPORTCIRCULARNETFLOWCHART Export the CircularNetFlowChart.

% Create the chart.
f = uifigure();
figureCleanup = onCleanup( @() delete( f ) );
n = 6;
ld = magic( n );
ld(1:n+1:end) = 0;
ld = array2table( ld );
CNFC = CircularNetFlowChart( "Parent", f, ...
    "LinkData", ld, ...
    "ShowLabels", "off" );
drawnow()
title( CNFC, "" )

% Export.
exportImage( "CircularNetFlowChart", CNFC )

end % exportCircularNetFlowChart

function exportClockChart()
%EXPORTCLOCKCHART Export the ClockChart.

% Create the chart.
f = uifigure();
figureCleanup = onCleanup( @() delete( f ) );
CC = ClockChart( "Parent", f, ...
    "ShowNumbers", "off" );

% Export.
exportImage( "ClockChart", CC )

end % exportClockChart

function exportCylinderChart()
%EXPORTCYLINDERCHART Export the CylinderChart.

% Create the chart.
f = uifigure();
figureCleanup = onCleanup( @() delete( f ) );
CC = CylinderChart( "Parent", f, "Data", magic( 2 ) );
axis( CC, "off" )

% Export.
exportImage( "CylinderChart", CC, [40, 50] )

end % exportCylinderChart

function exportEdgeworthBowleyChart()
%EXPORTEDGEWORTHBOWLEYCHART Export the EdgeworthBowleyChart.

% Create the chart.
f = uifigure();
figureCleanup = onCleanup( @() delete( f ) );
dataPath = fullfile( chartsRoot(), "data", "IndifferenceCurves.mat" );
data = load( dataPath );
data.A = data.A(:, 1:2:end);
data.B = data.B(:, 1:2:end);
EBC = EdgeworthBowleyChart( "Parent", f, ...
    "AData", data.A, ...
    "BData", data.B, ...
    "LineWidth", 10, ...
    "LineColor", "y", ...
    "MarkerSize", 16 );
axis( EBC, "off" )
title( EBC, "" )

% Export.
exportImage( "EdgeworthBowleyChart", EBC, [40, 50] )

end % exportEdgeworthBowleyChart

function exportGraphicsHierarchyChart()
%EXPORTGRAPHICSHIERARCHYCHART Export the GraphicsHierarchyChart.

% Create chart data.
f1 = uifigure(); 
figureCleanup = onCleanup( @() delete( f1 ) );
ax = axes( "Parent", f1 ); 
scatter( ax, 1 : 100, [1 : 100; 101 : 200] )
colorbar( ax )

% Create the chart.
f2 = uifigure();
figureCleanup(2) = onCleanup( @() delete( f2 ) );
GHC = GraphicsHierarchyChart( "Parent", f2, ...
    "RootObject", f1, ...
    "LineWidth", 16, ...
    "MarkerSize", 36, ...
    "EdgeAlpha", 1, ...
    "ShowNodeLabels", "off" );

% Export.
exportImage( "GraphicsHierarchyChart", GHC, [40, 50] )

end % exportGraphicsHierarchyChart

function exportImpliedVolatilityChart()
%EXPORTIMPLIEDVOLATILITYCHART Export the ImpliedVolatilityChart.

% Create the chart.
f = uifigure();
figureCleanup = onCleanup( @() delete( f ) );
data = load( fullfile( chartsRoot(), "data", "Option.mat" ) );
D1 = data.D(data.D.Group == "G1", 1:4);
IVC = ImpliedVolatilityChart( "Parent", f, ...
    "OptionData", D1, ...
    "Marker", "none" );
view( IVC, [475, 26] )
axis( IVC, "off" )
t = title( IVC, "" );
pause( 0.5 )

% Export.
ax = t.Parent;
ax.Color = "none";
exportImage( "ImpliedVolatilityChart", ax, [40, 50] )

end % exportImpliedVolatilityChart

function exportInductionMotorChart()
%EXPORTINDUCTIONMOTORCHART Export the InductionMotorChart.

% Create the chart.
f = uifigure();
figureCleanup = onCleanup( @() delete( f ) );
dataFolder = fullfile( chartsRoot(), "data", "MotorParameters" );
IMP = InductionMotorParameters( dataFolder );
IMC = InductionMotorChart( "Parent", f, ...
    "MotorParameters", IMP, ...
    "LegendVisible", "off", ...
    "LineWidth", 2, ...
    "MarkerSize", 50, ...
    "OperatingPoint", [2000, 200], ...
    "FaceAlpha", 1 );
axis( IMC, "off" )
title( IMC, "" )

% Export.
exportImage( "InductionMotorChart", IMC, [40, 50] )

end % exportInductionMotorChart

function exportLineGradientChart()
%EXPORTLINEGRADIENTCHAT Export the LineGradientChart.

% Set the seed.
s = rng();
seedCleanup = onCleanup( @() rng( s ) );
rng( "default" )

% Create the chart.
f = uifigure();
figureCleanup = onCleanup( @() delete( f ) );
dates = datetime( 1990, 1, 1 ) : datetime( 2020, 1, 1 );
steps = [0, randn( size( dates(1:end-1) ) )];
walk = cumsum( steps );
LGC = LineGradientChart( "Parent", f, ...
    "XData", dates, ...
    "YData", walk, ...
    "LineWidth", 7 );
colormap( LGC, "cool" )
axis( LGC, "off" )
pause( 0.5 )

% Export.
exportImage( "LineGradientChart", LGC, [40, 50] )

end % exportLineGradientChart

function exportLineSelectorChart()
%EXPORTLINESELECTORCHART Export the LineSelectorChart.

% Set the seed.
s = rng();
seedCleanup = onCleanup( @() rng( s ) );
rng( "default" )

% Create the chart.
f = uifigure();
figureCleanup = onCleanup( @() delete( f ) );
x = 1 : 100;
y = cumsum( randn( numel( x ), 2 ) );
LSC = LineSelectorChart( "Parent", f, ...
    "XData", x, ...
    "YData", y, ...
    "SelectedColor", [1, 0.5, 0], ...
    "TraceColor", [0.5, 0.5, 0.5], ...
    "TraceLineWidth", 5, ...
    "SelectedLineWidth", 7 );
pause( 0.5 )
LSC.select( 2 )
axis( LSC, "off" )

% Export.
exportImage( "LineSelectorChart", LSC, [40, 50] )

end % exportLineSelectorChart

function exportPolarChart()
%EXPORTPOLARCHART Export the PolarChart.

% Create the figure.
f = uifigure();
figureCleanup = onCleanup( @() delete( f ) );
months = 1 : 12;
meanMonthlyTemps = [4, 5, 6, 9, 12, 16, 17, 18, 15, 11, 7, 4;
    3, 4, 6, 8, 11, 13, 15, 15, 13, 10, 6, 4].';
PC = PolarChart( "Parent", f, ...
    "AngularData", months, ...
    "RadialData", meanMonthlyTemps, ...
    "LineWidth", 8 );
axis( PC, "off" )

% Export.
exportImage( "PolarChart", PC )

end % exportPolarChart

function exportRadarScope()
%EXPORTRADARSCOPE Export the RadarScope.

% Create the chart.
f = figure();
figureCleanup = onCleanup( @() delete( f ) );
RS = RadarScope( "Parent", f, ...
    "GridLineWidth", 5, ...
    "GridAlpha", 1, ...
    "ShowProximityLamp", "off" );
t = title( RS, "" );
rticks( RS, 0:20:100 )
rlabel( RS, "" )
thetalabel( RS, "" )
rticklabels( RS, [] )
thetaticklabels( RS, [] )
for k = 1 : 6
    B = Blip( "MarkerSize", 120, ...
        "Position", [deg2rad( 60 * k ), 50] );
    RS.addBlip( B )
end % for
pause( 0.5 )

% Export.
exportImage( "RadarScope", t.Parent )

end % exportRadarScope

function exportRangefinderChart()
%EXPORTRANGEFINDERCHART Export the RangefinderChart.

% Set the seed.
s = rng();
seedCleanup = onCleanup( @() rng( s ) );
rng( "default" )

% Create the chart.
f = uifigure();
figureCleanup = onCleanup( @() delete( f ) );
numPoints = 50;
x = 2 * randn( numPoints, 1 );
y = 2 * x + 1 + 2 * randn( numPoints, 1 );
RFC = RangefinderChart( "Parent", f, ...
    "XData", x, ...
    "YData", y, ...
    "Marker", ".", ...
    "SizeData", 1500, ...
    "LineWidth", 10 );
axis( RFC, "off" )

% Export.
exportImage( "RangefinderChart", RFC, [40, 50] )

end % exportRangefinderChart

function exportSankeyChart()
%EXPORTSANKEYCHART Export the SankeyChart.

% Create the chart.
f = uifigure();
figureCleanup = onCleanup( @() delete( f ) );
data = load( fullfile( chartsRoot(), "data", "Graph.mat" ) );
SC = SankeyChart( "Parent", f, ...
    "GraphData", digraph( data.linkData ), ...
    "LinkColor", "gradient", ...
    "LinkType", "vtanh", ...
    "NodeWidth", 0.2, ...
    "NodePadRatio", 0.25, ...
    "NodeLabelsVisible", "off" );
SC.YNodeData(13:end) = SC.YNodeData(13:end) - 50;

% Export.
exportImage( "SankeyChart", SC, [40, 50] )

end % exportSankeyChart

function exportScatterBoxChart()
%EXPORTSCATTERBOXCHART Export the ScatterBoxChart.

% Set the seed.
s = rng();
seedCleanup = onCleanup( @() rng( s ) );
rng( "default" )

% Create the chart.
f = uifigure();
figureCleanup = onCleanup( @() delete( f ) );
x = randn( 100, 1 );
y = 2 * x + 1 + 3 * randn( size( x ) );
SBC = ScatterBoxChart( "Parent", f, ...
    "XData", x, ...
    "YData", y, ...
    "ScatterSizeData", 1200, ...
    "BoxLineWidth", 8, ...
    "BoxFaceColor", "m" );
legend( SBC, "off" )
title( SBC, "" );
axis( SBC, "off" )
d = hypot( x, y );
n = numel( x );
d = round( 1 + ( n - 1 ) * rescale( d ) );
map = cool( n );
colorGradient = map(d, :);
SBC.ScatterCData = colorGradient;

% Export.
exportImage( "ScatterBoxChart", SBC, [40, 50] )

end % exportScatterBoxChart

function exportScatterDensityChart()
%EXPORTSCATTERDENSITYCHART Export the ScatterDensityChart.

% Set the seed.
s = rng();
seedCleanup = onCleanup( @() rng( s ) );
rng( "default" )

% Generate the data.
numSamples = 2000;
rng( "default" )
V = 0.2 * eye( 2 );
C1 = mvnrnd( [1, 1], V, numSamples);
C2 = mvnrnd( [-1, 1], V,  numSamples );
C3 = mvnrnd( [1, -1], V, numSamples );
C4 = mvnrnd( [-1, -1], V, numSamples );
x = [C1(:, 1); C2(:, 1); C3(:, 1); C4(:, 1)];
y = [C1(:, 2); C2(:, 2); C3(:, 2); C4(:, 2)];

% Create the chart.
f = uifigure();
figureCleanup = onCleanup( @() delete( f ) );
SDC = ScatterDensityChart( "Parent", f, ...
    "XData", x, ...
    "YData", y ); 
colorbar( SDC, "off" )
axis( SDC, "off" )

% Export.
exportImage( "ScatterDensityChart", SDC, [40, 50] )

end % exportScatterDensityChart

function exportScatterFitChart()
%EXPORTSCATTERFITCHART Export the ScatterFitChart.

% Set the seed.
s = rng();
seedCleanup = onCleanup( @() rng( s ) );
rng( "default" )

% Generate data.
x = randn( 1000, 1 );
y = 2 * x + 1 + 2 * randn( size( x ) );

% Create the chart.
f = uifigure();
figureCleanup = onCleanup( @() delete( f ) );
SFC = ScatterFitChart( "Parent", f, ...
    "XData", x, ...
    "YData", y, ...
    "LineWidth", 10, ...
    "SizeData", 300 );
legend( SFC, "off" )
axis( SFC, "off" )
title( SFC, "" )

% Export.
exportImage( "ScatterFitChart", SFC, [40, 50] )

end % exportScatterFitChart

function exportSettlementChart()
%EXPORTSETTLEMENTCHART Export the SettlementChart.

% Create the chart data.
Strike = (85:0.1:115).';
Price = 100;
Rate = 0.04;
Time = 0.25;
Volatility = 0.45;
Yield = 0.01;

% Create the chart.
f = uifigure();
figureCleanup = onCleanup( @() delete( f ) );
SC = SettlementChart( "Parent", f, ...
    "Strike", Strike, ...
    "Price", Price, ...
    "Rate", Rate, ...
    "Time", Time, ...
    "Volatility", Volatility, ...
    "Yield", Yield, ...
    "CallLineWidth", 10, ...
    "PutLineWidth", 10, ...
    "AtTheMoneyLineWidth", 10 );
axis( SC, "off" )
title( SC, "" )
legend( SC, "off" )
pause( 0.5 )

% Export.
exportImage( "SettlementChart", SC, [40, 50] )

end % exportSettlementChart

function exportSignalTraceChart()
%EXPORTSIGNALTRACECHART Export the SignalTraceChart.

% Create the chart data.
t = linspace( 0, 6 * pi, 5000 ).';
y1 = [zeros( 1000, 1 ); ones( 500, 1 );
    zeros( 500, 1 ); (-1) * ones( 500, 1 );
    ones( 1000, 1 ); zeros( 1000, 1 );
    ones( 500, 1 )];
y2 = sin( t );
y3 = 2 * sin( 2 * t ) .* cos( 3 * t );
signals = [y1, y2, y3];

% Create the chart.
f = uifigure();
figureCleanup = onCleanup( @() delete( f ) );
STC = SignalTraceChart( "Parent", f, ...
    "Time", t, ...
    "SignalData", signals, ...
    "LineWidth", 8 );
xticks( STC, [] )

% Export.
exportImage( "SignalTraceChart", STC, [40, 50] )

end % exportSignalTraceChart

function exportSnailTrailChart()
%EXPORTSNAILTRAILCHART Export the SnailTrailChart.

% Load the chart data.
data = load( fullfile( chartsRoot(), "data", "Returns.mat" ), "rets" );

% Create the chart.
f = uifigure();
figureCleanup = onCleanup( @() delete( f ) );
STC = SnailTrailChart( "Parent", f, ...
    "Returns", data.rets, ...
    "ShowCurrentPointDetails", "off", ...
    "CrossHairLineWidth", 10, ...
    "TrailLineWidth", 10, ...
    "MarkerSize", 12 );
xlabel( STC, "" )
ylabel( STC, "" )
title( STC, "" )
colorbar( STC, "off" )
axis( STC, "off" )
STC.step( 34 )

% Export.
exportImage( "SnailTrailChart", STC, [40, 50] )

end % exportSnailTrailChart

function exportSpiderChart()
%EXPORTSPIDERCHART Export the SpiderChart.

% Set the seed.
s = rng();
seedCleanup = onCleanup( @() rng( s ) );
rng( "default" )

% Define the chart data.
data = rand( 5, 2 );

% Create the chart.
f = uifigure();
figureCleanup = onCleanup( @() delete( f ) );
SC = SpiderChart( "Parent", f, ...
    "Data", data, ...
    "WebLineWidth", 3.5, ...
    "LineWidth", 10 );

% Export.
exportImage( "SpiderChart", SC )

end % exportSpiderChart

function exportTernaryChart()
%EXPORTTERNARYCHART Export the TernaryChart.

% Load the chart data.
data = load( fullfile( chartsRoot(), "data", "Chemicals.mat" ) );

% Create the chart.
f = uifigure();
figureCleanup = onCleanup( @() delete( f ) );
TC = TernaryChart( "Parent", f, ...
    "Data", data.T, ...
    "EdgeColor", "none", ...
    "FaceColor", "interp", ...
    "ShowTicks", false );
xlabel( TC, "" )
ylabel( TC, "left", "" )
ylabel( TC, "right", "" )
zlabel( TC, "" )
colormap( TC, spring() )

% Export.
exportImage( "TernaryChart", TC )

end % exportTernaryChart

function exportValueAtRiskChart()
%EXPORTVALUEATRISKCHART Export the ValueAtRiskChart.

% Set the seed.
s = rng();
seedCleanup = onCleanup( @() rng( s ) );
rng( "default" )

% Create data for the chart.
d = 0.02 * trnd(10, 2000, 1 );

% Create the chart.
f = uifigure();
figureCleanup = onCleanup( @() delete( f ) );
VARC = ValueAtRiskChart( "Parent", f, ...
    "Data", d, ...
    "FaceAlpha", 1, ...
    "LineWidth", 10, ...
    "VaRLabelVisible", "off", ...
    "CVaRLabelVisible", "off" );
VARC.EdgeColor = VARC.FaceColor;
xlabel( VARC, "" )
ylabel( VARC, "" )
title( VARC, "" )
legend( VARC, "off" )
axis( VARC, "off" )

% Export.
exportImage( "ValueAtRiskChart", VARC, [40, 50] )

end % exportValueAtRiskChart

function exportWindRoseChart()
%EXPORTWINDROSECHART Export the WindRoseChart.

% Load the chart data.
data = load( fullfile( chartsRoot(), "data", "Wind.mat" ) );

% Create the chart.
f = uifigure();
figureCleanup = onCleanup( @() delete( f ) );
WRC = WindRoseChart( "Parent", f, ...
    "WindData", data.W, ...
    "LegendVisible", "off", ...
    "RadialLabelVisible", "off", ...
    "BackdropLineWidth", 3.5, ...
    "EdgeColor", "none", ...
    "DirectionLabelVisible", "off" );

% Export.
exportImage( "WindRoseChart", WRC )

end % exportWindRoseChart

function exportImage( name, gobj, resolution )
%EXPORTIMAGE Export large and small PNG images of the given chart using a 
%transparent background.

arguments ( Input )
    name(1, 1) string    
    gobj(1, 1) matlab.graphics.Graphics
    resolution(1, 2) double {mustBePositive, mustBeInteger} = [40, 40]
end % arguments ( Input )

% Export the axes using both black and white backgrounds.
colors = ["Black", "White"];
pngPath = fullfile( exportPath(), name + colors + ".png" );
for k = 1 : numel( colors )
    exportgraphics( gobj, pngPath(k), ...
        "Resolution", 300, ...
        "BackgroundColor", colors(k) )
end % for

% Merge the two images to create an image with a transparent background.
black = imread( pngPath(1) );
white = imread( pngPath(2) );
white = imresize( white, size( black, 1:2 ), "bicubic" );
black = double( black ) / 255;
white = double( white ) / 255;
alpha = mean( 1 - white + black, 3 );
alpha = max( 0, min( alpha, 1 ) );
nonZeroAlpha = alpha >= eps;
pngrgb = zeros( size( black ) );

for k = 1 : 3
    currentSlice = black(:, :, k);
    zeroSlice = pngrgb(:, :, k);
    zeroSlice(nonZeroAlpha) = currentSlice(nonZeroAlpha) ./ ...
        alpha(nonZeroAlpha);
    pngrgb(:, :, k) = zeroSlice;
end % for

pngrgb = max( 0, min( pngrgb, 1 ) );
pngrgb = uint8( 255 * pngrgb );

% Export the image with transparent background and remove the black and
% white background images.
exportName = fullfile( exportPath(), name + ".png" );
imwrite( pngrgb, exportName, "Alpha", alpha )
delete( pngPath(1) )
delete( pngPath(2) )

% Export an icon-size version of the image.
pngrgb40 = imresize( pngrgb, resolution, "bicubic" );
alpha40 = imresize( alpha, resolution, "bicubic" );
export40Name = fullfile( exportPath(), name + "40.png" );
imwrite( pngrgb40, export40Name, "Alpha", alpha40 )

% Create the toolbox logo.
if name == "ScatterFitChart"
    pngrgb24 = imresize( pngrgb, [24, 24], "bicubic" );
    alpha24 = imresize( alpha, [24, 24], "bicubic" );
    export24Name = fullfile( exportPath(), "toolboxLogo.png" );
    imwrite( pngrgb24, export24Name, "Alpha", alpha24 )
end % if

end % exportImages