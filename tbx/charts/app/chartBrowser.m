function varargout = chartBrowser()
%CHARTBROWSER Launcher for the ChartBrowser application.

% Check the number of output arguments.
nargoutchk( 0, 1 )

% Create the AppContainer object (the top-level graphics object).
appOptions.Title = "Chart Browser";
appOptions.EnableTheming = true;
app = matlab.ui.container.internal.AppContainer( appOptions );

% Add a toolstrip tab group to the app.
tabGroup = matlab.ui.internal.toolstrip.TabGroup();
tabGroup.Tag = "TabGroup";
app.addTabGroup( tabGroup )

% Create the charts tab.
chartsTab = matlab.ui.internal.toolstrip.Tab( "Charts" );
tabGroup.add( chartsTab )

% Add a section and a column.
section = matlab.ui.internal.toolstrip.Section( "Overview" );
section.Tag = "Overview";
chartsTab.add( section )
column = matlab.ui.internal.toolstrip.Column( "Width", 50 );
column.Tag = "GettingStartedColumn";
section.add( column )

% Add the button for the Getting Started guide.
button = matlab.ui.internal.toolstrip.Button( ...
    "Icon", "plotPredictedVsActual" );
button.Text = "Getting Started";
button.Description = "Open the Getting Started guide";
button.ButtonPushedFcn = @onGettingStartedButtonPushed;
column.add( button )

% Add a second column.
column = matlab.ui.internal.toolstrip.Column( "Width", 50 );
column.Tag = "WhatIsAChartColumn";
section.add( column )

% Add the button for the "What is a chart?" guide.
button = matlab.ui.internal.toolstrip.Button( ...
    "Icon", "showTips" );
button.Text = "What is a Chart?";
button.Description = "Open the motivating example";
button.ButtonPushedFcn = @onWhatIsAChartButtonPushed;
column.add( button )

% Add the button for the development guide.
button = matlab.ui.internal.toolstrip.Button( ...
    "Icon", "documentation" );
button.Text = "Development Guide";
button.Description = "Open the chart development guide";
button.ButtonPushedFcn = @onDevelopmentGuideButtonPushed;
column.add( button )

% Add the button for the technical article.
button = matlab.ui.internal.toolstrip.Button( ...
    "Icon", "supportWebsite" );
button.Text = "Technical Article";
button.Description = "Open the technical article " + ...
    """Creating Specialized Charts with MATLAB OOP""";
button.ButtonPushedFcn = @onTechnicalArticleButtonPushed;
column.add( button )

% Add a section and a column.
section = matlab.ui.internal.toolstrip.Section( "Chart Examples" );
section.Tag = "ChartExamples";
chartsTab.add( section )
column = matlab.ui.internal.toolstrip.Column();
column.Tag = "ExamplesColumn";
section.add( column )

% Create the gallery categories (graphical and other).
category = matlab.ui.internal.toolstrip.GalleryCategory( "Chart Examples" );

% Create gallery items for the graphical views.
tiles = load( "Tiles.mat" );
chartNames = fieldnames( tiles.ChartTiles );
for k = 1 : numel( chartNames )
    name = chartNames{k};
    item = matlab.ui.internal.toolstrip.GalleryItem( name );
    icon = tiles.ChartTiles.(name);
    icon = imresize( icon, [24, 24] );
    item.Icon = matlab.ui.internal.toolstrip.Icon( icon );
    item.Description = name + " Chart";
    category.add( item )
end % for

% Create a gallery popup and add the gallery categories to it.
popup = matlab.ui.internal.toolstrip.GalleryPopup( ...
    "ShowSelection", true );
popup.add( category )

% Create the main gallery and add it to the view column.
gallery = matlab.ui.internal.toolstrip.Gallery( popup, ...
    'MinColumnCount', 3, 'MaxColumnCount', 5 );
column.add( gallery )

% Make the app visible.
app.Visible = true;

% Return the App Container reference if this is requested.
if nargout == 1
    varargout{1} = app;
end % if

end % chartBrowser