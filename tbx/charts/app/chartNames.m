function [allChartNames, accessibleChartNames] = chartNames()
%CHARTNAMES Return string arrays of (a) all chart names, and (b) all chart
%names accessible to the end user based on their installed toolboxes.

arguments ( Output )
    allChartNames(1, :) string
    accessibleChartNames(1, :) string
end % arguments ( Output )

% Start with a list of all the charts.
allChartNames = dir( fullfile( chartsRoot(), "charts", "*.m" ) );
allChartNames = string( extractBefore( {allChartNames.name}, ".m" ) );

% Stop if only one output argument is required.
if nargout == 1
    return
end % if

% Read off the chart dependencies.
numCharts = numel( allChartNames );
chartDependencies = cell( numCharts, 1 );
for chartIdx = 1 : numCharts
    chartDependencies{chartIdx, 1} = eval( ...
        [allChartNames{chartIdx}, '.Dependencies'] );
end % for

% Decide which charts the user can see, based on their
% installation.
toolboxNames = string( {ver().Name}.' );
userVisibleIdx = false( numCharts, 1 );
for chartIdx = 1 : numCharts
    userVisibleIdx(chartIdx) = all( ...
        ismember( chartDependencies{chartIdx}, toolboxNames ) );
end % for

accessibleChartNames = allChartNames(userVisibleIdx);

end % chartNames