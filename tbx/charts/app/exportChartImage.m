function exportChartImage( chartNames )
%EXPORTCHARTIMAGE Export chart images with transparent backgrounds for use
%in the example scripts, and smaller icons for use with the chart browser.
%Call this function with no inputs to regenerate and export all images.
%Alternatively, provide a list of required chart names. Only the specified
%chart images will be exported.

% Copyright 2024-2025 The MathWorks, Inc.

arguments ( Input )
    chartNames(1, :) string {mustBeChartName} = string.empty( 1, 0 )
end % arguments ( Input )

% No input or an empty string means we should update all images.
if isempty( chartNames )
    chartNames = allChartNames();
end % if

% Export the required images.
for name = chartNames
    feval( "export" + name )
end % for

end % exportChartImage

function mustBeChartName( str )
%MUSTBECHARTNAME Verify that the input string array, str, contains valid
%chart names.

mustBeMember( str, allChartNames() )

end % mustBeChartName

function names = allChartNames()
%ALLCHARTNAMES Return a string array of all available chart names.

arguments ( Output )
    names(1, :) string
end % arguments ( Output )

names = string( ls( fullfile( chartsRoot(), "charts", "*.m" ) ) );
names = extractBefore( names, ".m" );

end % allChartNames

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
exportImages( "AircraftChart", AC )

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
t = title( AC, "" );
view( AC, 2 )
pause( 0.5 )

% Export.
exportImages( "AnnulusChart", t.Parent )

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
exportImages( "CircularNetFlowChart", CNFC )

end % exportCircularNetFlowChart

function exportClockChart()
%EXPORTCLOCKCHART Export the ClockChart.

% Create the chart.
f = uifigure();
figureCleanup = onCleanup( @() delete( f ) );
CC = ClockChart( "Parent", f );

% Export.
exportImages( "ClockChart", CC )

end % exportClockChart

function exportCylinderChart()
%EXPORTCYLINDERCHART Export the CylinderChart.

% Create the chart.
f = uifigure();
figureCleanup = onCleanup( @() delete( f ) );
CC = CylinderChart( "Parent", f, "Data", magic( 2 ) );
axis( CC, "off" )

% Export.
exportImages( "CylinderChart", CC )

end % exportCylinderChart

function exportEdgeworthBowleyChart()
%EXPORTEDGEWORTHBOWLEYCHART Export the EdgeworthBowleyChart.

% Create the chart.
f = uifigure();
figureCleanup = onCleanup( @() delete( f ) );
dataPath = fullfile( chartsDocRoot(), "data", "IndifferenceCurves.mat" );
data = load( dataPath );
data.A = data.A(:, 1:2:end);
data.B = data.B(:, 1:2:end);
EBC = EdgeworthBowleyChart( "Parent", f, ...
    "AData", data.A, ...
    "BData", data.B, ...
    "LineWidth", 7, ...
    "MarkerSize", 16 );
axis( EBC, "off" )
title( EBC, "" )

% Export.
exportImages( "EdgeworthBowleyChart", EBC )

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
exportImages( "GraphicsHierarchyChart", GHC )

end % exportGraphicsHierarchyChart

function exportImpliedVolatilityChart()
%EXPORTIMPLIEDVOLATILITYCHART Export the ImpliedVolatilityChart.

% Create the chart.
f = uifigure();
figureCleanup = onCleanup( @() delete( f ) );
data = load( fullfile( chartsDocRoot(), "data", "Option.mat" ) );
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
exportImages( "ImpliedVolatilityChart", ax )

end % exportImpliedVolatilityChart

function exportImages( name, ax )
%EXPORTIMAGES Export PNG images of the given chart.

arguments ( Input )
    name(1, 1) string    
    ax(1, 1) matlab.graphics.Graphics
end % arguments ( Input )

% Export the axes using both black and white backgrounds.
colors = ["Black", "White"];
pngPath = fullfile( exportPath(), name + colors + ".png" );
for k = 1 : numel( colors )
    exportgraphics( ax, pngPath(k), ...
        "Resolution", 300, ...
        "BackgroundColor", colors(k) )
end % for

end % exportImages