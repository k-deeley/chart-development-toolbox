function chartMontage()
%CHARTMONTAGE Create chart montage for use in the README.md file.

% Create a datastore for all chart images.
chartImages = fullfile( chartsRoot(), "app", "images" );
ds = imageDatastore( chartImages );

% Remove smaller icons and the toolbox logo.
tf = endsWith( ds.Files, "40.png" ) | endsWith( ds.Files, "Logo.png" );
ds.Files(tf) = [];

% Create the tiled image.
im = readall( ds );
I = imtile( im, "GridSize", [NaN, 5], ...
    "BackgroundColor", "black", ...
    "BorderSize", [20, 20] );

% Reduce the resolution.
I = imresize( I, 0.2 );

% Export the tiled image.
imageFolder = fileparts( mfilename( "fullpath" ) );
exportName = fullfile( imageFolder, "chartMontage.png" );
backgroundIdx = double( all( I == intmin( class( I ) ), 3 ) );
imwrite( I, exportName, "Alpha", 1-backgroundIdx )

end % chartMontage