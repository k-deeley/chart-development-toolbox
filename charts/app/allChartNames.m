function names = allChartNames()
%ALLCHARTNAMES Return a string array of all available chart names.

arguments ( Output )
    names(1, :) string
end % arguments ( Output )

names = string( ls( fullfile( chartsRoot(), "charts", "*.m" ) ) );
names = extractBefore( names, ".m" );

end % allChartNames