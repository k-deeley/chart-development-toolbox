function [outputArg1,outputArg2] = buildfile(inputArg1,inputArg2)
    %BUILDFILE Summary of this function goes here
    %   Detailed explanation goes here
    outputArg1 = inputArg1;
    outputArg2 = inputArg2;
end

function verifyExamples()
Verify that the HTML examples are present.
Check that each Live Script (.mlx) example file in the +example package has a corresponding .html example file.

% Reference the current project.
prj = currentProject();

% List the project files and full paths.
prjFiles = prj.Files;
fullPaths = vertcat( prjFiles.Path );

% Identify the files and the names of their containing folders.
fileIdx = isfile( fullPaths );
[~, folderNames] = fileparts( fileparts( fullPaths ) );

% Extract the files in the +example package.
exampleFiles = prjFiles(fileIdx & folderNames == "+example");

% Obtain their file extensions.
exampleFilePaths = vertcat( exampleFiles.Path );
[examplePackage, exampleFilenames, exampleFileExtensions] = fileparts( exampleFilePaths );
examplePackage = examplePackage(1);

% Perform the required checks.
% First, check that only .mlx and .html files are present in the +example
% package.
assert( all( ismember( exampleFileExtensions, [".mlx", ".html"] ) ), ...
    "Detected an unknown file extension in the +example package. Check that all files have extension .mlx or .html." )
disp( "All files in the +example package have extension .mlx or .html." )
% Next, check that the number of .html files does not exceed the number of
% .mlx files.
mlxIdx = exampleFileExtensions == ".mlx";
htmlIdx = exampleFileExtensions == ".html";
assert( sum( htmlIdx ) <= sum( mlxIdx ), "Detected too many HTML files in the +example package." )
disp( "The number of HTML example files does not exceed the number of Live Script examples." )
% Next, check that each .mlx file has a corresponding .html file.
exampleLiveScripts = exampleFilenames(mlxIdx);
for k = 1:length( exampleLiveScripts )
    requiredHTMLFile = fullfile( examplePackage, exampleLiveScripts(k) ) + ".html";
    if ~ismember( requiredHTMLFile, exampleFilePaths )
        warning( "Detected a missing .html file: %s.", requiredHTMLFile )
    else
        disp( "The required HTML example file " + requiredHTMLFile + " is present." )
    end % if
end % for

end % verifyExamples

Verify that project files are correctly labeled.
Ensure that all files within various project packages and subfolders have the required labels.
Copyright 2019-2022 The MathWorks, Inc.
function verifyLabels()

% Reference the current project.
prj = currentProject();

% List the project files and full paths.
prjFiles = prj.Files;
fullPaths = vertcat( prjFiles.Path );

% Identify the files and the names of their containing folders.
fileIdx = isfile( fullPaths );
[~, folderNames] = fileparts( fileparts( fullPaths ) );

% Verify that files in the +chart package have the label "Chart".
chartFiles = prjFiles(fileIdx & folderNames == "+chart");
verifyBatch( chartFiles, "Chart" )

% Verify that files in the +example package have the label "Example".
exampleFiles = prjFiles(fileIdx & folderNames == "+example");
verifyBatch( exampleFiles, "Example" )

% Verify that files in the data folder have the label "Data".
dataFiles = prjFiles(fileIdx & folderNames == "data" );
verifyBatch( dataFiles, "Data" )

% Verify that files in the doc folder have the label "Documentation".
docFiles = prjFiles(fileIdx & folderNames == "doc");
verifyBatch( docFiles, "Documentation" )

% Verify that files in the image folder have the label "Image".
imageFiles = prjFiles(fileIdx & folderNames == "images");
verifyBatch( imageFiles, "Image" )

% Verify that files in the utilities folder have the label "Utility".
utilityFiles = prjFiles(fileIdx & (ismember( folderNames, ["utilities", "+internal"] )));
verifyBatch( utilityFiles, "Utility" )

end % verifyLabels

function verifyBatch( files, labelName )

disp( "Verifying " + labelName + " labels... " )
for k = 1:length( files )
    lbls = files(k).Labels;
    if isscalar( lbls ) && lbls.CategoryName == "Classification" && lbls.Name == labelName
        disp( "File " + files(k).Path + " is labeled correctly." )
    else
        for lb = 1:length( lbls )
            removeLabel( files(k), lbls(lb) )
        end % for
        addLabel( files(k), "Classification", labelName );
        disp( "File " + files(k).Path + " was incorrectly labeled. Now labeled as " + labelName + "." )
    end % if
end % for
disp( "Verified " + labelName + " labels." )

end % verifyBatch

Convert live scripts to HTML.
If no input filenames are provided, then for the Chart Catalog's +example folder, run all of the live scripts and export them to HTML files in the same folder.
Copyright 2019-2022 The MathWorks, Inc.
function refreshHTML( filesToConvert )

arguments
    filesToConvert(:, 1) string = ""
end % arguments

% Find the default list of files to convert.
fileSpec = fullfile( catalogRoot(), "+example", "*.mlx" );
defaultFilesToConvert = deblank( string( ls( fileSpec ) ) );

% Check the input files.
if nargin == 0
    filesToConvert = defaultFilesToConvert;
else
    assert( all( ismember( filesToConvert, defaultFilesToConvert ) ), ...
       "chart:internal:refreshHTML:InvalidFiles", ...
      "All of the specified files must exist in the +example folder." )
end % if

% Run and save each file, then export to HTML.
for k = 1 : numel( filesToConvert )
    currentFile = fullfile( ...
        catalogRoot(), "+example", filesToConvert(k) );
    % Run and save the current file.
    matlab.internal.liveeditor.executeAndSave( char( currentFile ) );
    % Export it to HTML.
    targetFile = fullfile( catalogRoot(), "+example", ...
        filesToConvert{k}(1:end-4) + ".html" );
    matlab.internal.liveeditor.openAndConvert( ...
        char( currentFile ), char( targetFile ) );
    % Activate the hyperlinks.
    activateLinks( targetFile )
    % Display progress.
    disp( "Exported " + targetFile )
end % for

end % refreshHTML

function activateLinks( file )
%ACTIVATELINKS Convert the Live Script hyperlinks to JavaScript-enabled
%links within the specified HTML file.

% Read the file contents.
htmlFileContents = string( fileread( file ) );

% Replace the commands within the anchors.

% Extract the anchors.
anchors = extractBetween( htmlFileContents, "<a href = ""matlab:", ">", ...
    "Boundaries", "inclusive" );
% Extract the commands.
commands = extractBetween( anchors, """", """" );
% Format the JavaScript-enabled anchors.
replacementAnchors = "<a href = ""#"" onclick=""handleClick(" + ...
    "'" + commands + "'" + "); return false;"">";
% Replace the original anchors with the new anchors.
for k = 1:length( anchors )
    htmlFileContents = replace( htmlFileContents, ...
        anchors(k), replacementAnchors(k) );
end % for

% Insert the JavaScript block.
htmlFileContents = insertBefore( htmlFileContents, "</body>", ...
    "<script type = ""text/javascript"">" + ...
    "function setup(h) { window.uihtml = h; };" + ...
    "function handleClick(command) {" + newline() + ...
    "window.uihtml.Data = {" + newline() + ...
    "id: Math.random(), Link: command, }; }; </script>" );

% Replace the file contents.
fileID = fopen( file, "w" );
fprintf( fileID, "%s", htmlFileContents );
fclose( fileID );

end % activateLinks