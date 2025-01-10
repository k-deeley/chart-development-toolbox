function plan = buildfile()
%BUILDFILE Chart Development Toolbox build file.

% Copyright 2024-2025 The MathWorks, Inc.

% Define the build plan.
plan = buildplan( localfunctions() );

% Add a test task to run the unit tests for the project. Generate and save
% a coverage report. This build task is optional.
projectRoot = plan.RootFolder;
%testFolder = fullfile( projectRoot, "charts", "tests" );
%codeFolder = fullfile( projectRoot, "tbx", "charts"  );
% plan("test") = matlab.buildtool.tasks.TestTask( testFolder, ...
%     "Strict", true, ...
%     "Description", "Assert that all tests across the project pass.", ...
%     "SourceFiles", codeFolder, ...
%     "CodeCoverageResults", "reports/Coverage.html", ...
%     "OutputDetail", "none" );

% Set the package toolbox task to run by default.
plan.DefaultTasks = "package";

% Define the task dependencies and inputs.
%plan("test").Dependencies = "check";
%plan("doc").Dependencies = "test";
plan("doc").Inputs = [
    fullfile( chartsRoot(), "charts" );
    fullfile( chartsDocRoot(), "examples" );    
    fullfile( chartsDocRoot(), "GettingStarted.mlx" );
    fullfile( chartsDocRoot(), "CreatingSpecializedCharts.mlx" )];
plan("package").Dependencies = "doc";

end % buildfile

function checkTask( context )
% Check the source code and project for any issues.

% Set the project root as the folder in which to check for any static code
% issues.
projectRoot = context.Plan.RootFolder;
codeIssuesTask = matlab.buildtool.tasks.CodeIssuesTask( projectRoot, ...
     "IncludeSubfolders", true, ...
     "Configuration", "factory", ...
     "Description", ...
     "Assert that there are no code issues in the project.", ...
     "WarningThreshold", 0 );
codeIssuesTask.analyze( context )

% Update the project dependencies.
prj = currentProject();
prj.updateDependencies()

% Run the checks.
checkResults = table( prj.runChecks() );

% Log any failed checks.
passed = checkResults.Passed;
notPassed = ~passed;
if any( notPassed )
    disp( checkResults(notPassed, :) )
else
    fprintf( "** All project checks passed.\n\n" )    
end % if

% Check that all checks have passed.
assert( all( passed ), "buildfile:ProjectIssue", ...
    "At least one project check has failed. " + ...
    "Resolve the failures shown above to continue." )

end % checkTask

function docTask( context )
% Build the documentation and examples.

% Publish the chart classes as HTML documents.
chartsFolder = context.Task.Inputs(1).Path;
chartNames = deblank( string( ls( fullfile( chartsFolder, "*.m" ) ) ) );
chartFullPaths = fullfile( chartsFolder, chartNames );
chartNames = erase( chartNames, ".m" );
htmlOutputFolder = fullfile( chartsRoot(), "app", "html", "charts" );
for chartIdx = 1 : numel( chartNames )
    % Export the chart classdef file to an HTML document.
    publish( chartFullPaths(chartIdx), ...
        "format", "html", ...
        "outputDir", htmlOutputFolder, ...
        "evalCode", false );
    % Erase the footer.
    publishedFile = fullfile( htmlOutputFolder, ...
        chartNames(chartIdx) + ".html" );
    rawHTML = splitlines( fileread( publishedFile ) );
    footerStartIdx = find( startsWith( rawHTML, "<p class=""footer"">" ) );
    footerEndIdx = find( startsWith( rawHTML, "</p>" ) );
    footerEndIdx = footerEndIdx( find( footerEndIdx > footerStartIdx, ...
        1, "first" ) );
    rawHTML(footerStartIdx:footerEndIdx) = [];
    writelines( rawHTML, publishedFile )
end % for

% Publish the Live Script examples as HTML documents.
examplesFolder = context.Task.Inputs(2).Path;
exampleNames = deblank( string( ls( ...
    fullfile( examplesFolder, "*Examples.mlx" ) ) ) );
exampleFullPaths = fullfile( examplesFolder, exampleNames );
exampleNames = erase( exampleNames, ".mlx" );
htmlOutputFolder = fullfile( chartsRoot(), "app", "html", "examples" );
for exampleIdx = 1 : numel( exampleNames )    
    exportName = fullfile( htmlOutputFolder, ...
        exampleNames(exampleIdx) + ".html" );
    export( exampleFullPaths(exampleIdx), exportName, ...
        "Format", "html", ...
        "Run", false );
end % for

% Publish the getting started guide.
gettingStartedGuide = context.Task.Inputs(3).Path;
htmlOutputFolder = fullfile( chartsRoot(), "app", "html", "doc" );
exportName = fullfile( htmlOutputFolder, "GettingStarted.html" );
export( gettingStartedGuide, exportName, ...
    "Format", "html", ...
    "Run", false );

% Publish the chart development guide.
creatingCharts = context.Task.Inputs(4).Path;
exportName = fullfile( htmlOutputFolder, ...
    "CreatingSpecializedCharts.html" );
export( creatingCharts, exportName, ...
    "Format", "html", ...
    "Run", false );

end % docTask

function packageTask( context )
% Package the Chart Development Toolbox.

% Toolbox short name.
toolboxShortName = "charts";

% Project root directory.
projectRoot = context.Plan.RootFolder;

% Import and tweak the toolbox metadata.
toolboxJSON = fullfile( projectRoot, toolboxShortName + ".json" );
meta = jsondecode( fileread( toolboxJSON ) );
meta.ToolboxMatlabPath = fullfile( projectRoot, meta.ToolboxMatlabPath );
meta.ToolboxFolder = fullfile( projectRoot, meta.ToolboxFolder );
meta.ToolboxImageFile = fullfile( projectRoot, meta.ToolboxImageFile );
versionString = feval( @(s) s(1).Version, ...
    ver( toolboxShortName ) ); %#ok<FVAL>
meta.ToolboxVersion = versionString;
mltbx = fullfile( projectRoot, ...
    meta.ToolboxName + " " + versionString + ".mltbx" );
meta.OutputFile = mltbx; 

% Define the toolbox packaging options.
toolboxFolder = meta.ToolboxFolder;
toolboxID = meta.Identifier;
meta = rmfield( meta, ["Identifier", "ToolboxFolder"] );
opts = matlab.addons.toolbox.ToolboxOptions( ...
    toolboxFolder, toolboxID, meta );

% Package the toolbox.
matlab.addons.toolbox.packageToolbox( opts )
fprintf( 1, "[+] %s\n", opts.OutputFile )

% Add the license.
licenseText = fileread( fullfile( projectRoot, "LICENSE.txt" ) );
mlAddonSetLicense( char( opts.OutputFile ), ...
    struct( "type", 'BSD', "text", licenseText ) );

end % packageTask

% Ensure the Apps Packaging Project is up-to-date. This should only
%    include the entry-point function (the app launcher), so create/update
%    the Apps Packaging Project whilst the rest of the toolbox code is off
%    the path (e.g., close the project first).

% Convert live scripts to HTML.
% If no input filenames are provided, then for the Chart Catalog's +example folder, run all of the live scripts and export them to HTML files in the same folder.
% Copyright 2019-2022 The MathWorks, Inc.
% function refreshHTML( filesToConvert )
% 
% arguments
%     filesToConvert(:, 1) string = ""
% end % arguments
% 
% % Find the default list of files to convert.
% fileSpec = fullfile( catalogRoot(), "+example", "*.mlx" );
% defaultFilesToConvert = deblank( string( ls( fileSpec ) ) );
% 
% % Check the input files.
% if nargin == 0
%     filesToConvert = defaultFilesToConvert;
% else
%     assert( all( ismember( filesToConvert, defaultFilesToConvert ) ), ...
%        "chart:internal:refreshHTML:InvalidFiles", ...
%       "All of the specified files must exist in the +example folder." )
% end % if
% 
% % Run and save each file, then export to HTML.
% for k = 1 : numel( filesToConvert )
%     currentFile = fullfile( ...
%         catalogRoot(), "+example", filesToConvert(k) );
%     % Run and save the current file.
%     matlab.internal.liveeditor.executeAndSave( char( currentFile ) );
%     % Export it to HTML.
%     targetFile = fullfile( catalogRoot(), "+example", ...
%         filesToConvert{k}(1:end-4) + ".html" );
%     matlab.internal.liveeditor.openAndConvert( ...
%         char( currentFile ), char( targetFile ) );
%     % Activate the hyperlinks.
%     activateLinks( targetFile )
%     % Display progress.
%     disp( "Exported " + targetFile )
% end % for
% 
% end % refreshHTML
% 
% function activateLinks( file )
% %ACTIVATELINKS Convert the Live Script hyperlinks to JavaScript-enabled
% %links within the specified HTML file.
% 
% % Read the file contents.
% htmlFileContents = string( fileread( file ) );
% 
% % Replace the commands within the anchors.
% 
% % Extract the anchors.
% anchors = extractBetween( htmlFileContents, "<a href = ""matlab:", ">", ...
%     "Boundaries", "inclusive" );
% % Extract the commands.
% commands = extractBetween( anchors, """", """" );
% % Format the JavaScript-enabled anchors.
% replacementAnchors = "<a href = ""#"" onclick=""handleClick(" + ...
%     "'" + commands + "'" + "); return false;"">";
% % Replace the original anchors with the new anchors.
% for k = 1:length( anchors )
%     htmlFileContents = replace( htmlFileContents, ...
%         anchors(k), replacementAnchors(k) );
% end % for
% 
% % Insert the JavaScript block.
% htmlFileContents = insertBefore( htmlFileContents, "</body>", ...
%     "<script type = ""text/javascript"">" + ...
%     "function setup(h) { window.uihtml = h; };" + ...
%     "function handleClick(command) {" + newline() + ...
%     "window.uihtml.Data = {" + newline() + ...
%     "id: Math.random(), Link: command, }; }; </script>" );
% 
% % Replace the file contents.
% fileID = fopen( file, "w" );
% fprintf( fileID, "%s", htmlFileContents );
% fclose( fileID );
% 
% end % activateLinks