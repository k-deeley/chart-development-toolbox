classdef CatalogLauncher < handle
    %CATALOGLAUNCHER Application launcher for the chart catalog.
    %
    % Copyright 2018-2022 The MathWorks, Inc.

    properties ( SetAccess = private )
        % Main application figure window.
        Figure matlab.ui.Figure {mustBeScalarOrEmpty}
    end % properties ( SetAccess = private )

    properties ( Constant, GetAccess = private )
        % Default colors.
        DefaultColors = colororder()
        % Standard blue color used for plots.
        PlotBlue = CatalogLauncher.DefaultColors(1, :)
        % Yellow highlight color.
        HighlightYellow = [0.969, 1, 0]
    end % properties ( Constant, GetAccess = private )

    properties ( Access = private )
        % View menu.
        ViewMenu(1, 1) matlab.ui.container.Menu
        % Tab menu.
        TabMenu(1, 1) matlab.ui.container.Menu
        % Documentation menus.
        DocumentationMenus = gobjects( 0 )
        % Logical scalar flag for reusing a sole tab.
        ReuseTab = true()
        % Getting started label layout.
        LabelLayout(1, 1) matlab.ui.container.GridLayout
        % Tab group layout.
        TabGroupLayout(1, 1) matlab.ui.container.GridLayout
        % Documentation panel.
        DocumentationPanel(1, 1) matlab.ui.container.Panel
        % Tab group for the doc pages.
        TabGroup(1, 1) matlab.ui.container.TabGroup
        % Placeholder for a reusable tab.
        SoleTab = gobjects( 0 )
    end % properties ( Access = private )

    properties ( Dependent, Access = private )
        % Array of tabs to hold the HTML pages.
        TabList
        % Names of the open tabs.
        TabNames
    end % properties ( Dependent, Access = private )

    methods

        function obj = CatalogLauncher()
            %CATALOGLAUNCHER Build the chart catalog.

            % Create the main application figure.
            obj.Figure = uifigure( "Name", "Chart Catalog", ...
                "Units", "normalized", ...
                "Position", [0.125, 0.125, 0.75, 0.75] );

            % Create the view menu.
            obj.ViewMenu = uimenu( "Parent", obj.Figure, ...
                "Enable", "off", ...
                "Text", "View", ...
                "Tooltip", "Select documentation tabs to close" );

            % Create the options menu.
            optionsMenu = uimenu( "Parent", obj.Figure, ...
                "Text", "Options", ...
                "Tooltip", "Configure catalog options" );
            obj.TabMenu = uimenu( "Parent", optionsMenu, ...
                "Text", "Reuse tab", ...
                "Tooltip", "Reuse the same tab or use new tabs " + ...
                "for the chart documentation pages", ...
                "Checked", "on", ...
                "MenuSelectedFcn", @obj.onTabMenuSelected );

            % Define the horizontal layout.
            horizontalLayout = uigridlayout( obj.Figure, [1, 2], ...
                "ColumnWidth", ["1x", "1.33x"], ...
                "Padding", 0, ...
                "ColumnSpacing", 0 );

            % Create a panel for the chart grid.
            chartPanel = uipanel( "Parent", horizontalLayout, ...
                "Title", "Gallery", ...
                "FontSize", 16, ...
                "FontWeight", "bold", ...
                "BackgroundColor", [0, 0.66, 0.88], ...
                "ForegroundColor", "white" );

            % Create a panel for the documentation browser.
            obj.DocumentationPanel = uipanel( ...
                "Parent", horizontalLayout, ...
                "Title", "Documentation and Resources", ...
                "FontSize", 16, ...
                "FontWeight", "bold", ...
                "BackgroundColor", "white", ...
                "ForegroundColor", "black" );

            % Create a tab group for the HTML documents.
            obj.TabGroupLayout = uigridlayout( obj.DocumentationPanel, ...
                [1, 1], "Padding", 0 );
            obj.TabGroup = uitabgroup( "Parent", obj.TabGroupLayout );

            % Create the getting started label.
            obj.LabelLayout = uigridlayout( obj.DocumentationPanel, ...
                [1, 1], "Padding", 0 );
            uilabel( "Parent", obj.LabelLayout, ...
                "HorizontalAlignment", "center", ...
                "BackgroundColor", "white", ...
                "FontSize", 16, ...
                "FontWeight", "bold", ...
                "Text", "Select a chart to get started." );

            % Define a grid layout for the chart tiles.
            numCols = 4;
            chartTileGrid = uigridlayout( chartPanel, [1, numCols] );

            % Load the chart imagery.
            S = load( fullfile( chartsRoot(), "Tiles.mat" ) );
            chartNames = fieldnames( S.ChartTiles );

            % Prepare the list of charts available to the user.
            userAccessibleCharts = accessibleCharts();
            chartList = intersect( chartNames, userAccessibleCharts );
            numCharts = numel( chartList );

            % Create the individual clickable chart tiles within the grid
            % layout.
            for k = 1:numCharts
                % Obtain the name of the current chart.
                currentChartName = chartList(k);
                p = uipanel( "Parent", chartTileGrid );
                p.Layout.Row = ceil( k / numCols );
                c = mod( k, numCols );
                p.Layout.Column = c + numCols * (c == 0);                
                g = uigridlayout( p, [1, 1], "Padding", 2 );
                p = uipanel( "Parent", g, ...
                    "Title", currentChartName, ...
                    "FontSize", 14, ...
                    "FontWeight", "bold", ...
                    "ForegroundColor", "white", ...
                    "BackgroundColor", obj.PlotBlue );
                g = uigridlayout( p, [1, 1], "Padding", 0 );
                uiimage( "Parent", g, ...
                    "BackgroundColor", "w", ...
                    "ImageSource", S.ChartTiles.(currentChartName), ...
                    "ImageClickedFcn", @obj.onTileClicked, ...
                    "Interruptible", "off", ...
                    "BusyAction", "cancel", ...
                    "Tag", currentChartName, ...
                    "Tooltip", ...
                    "View the documentation for the " + ...
                    currentChartName + " chart" );
            end % for
            
        end % constructor

        function value = get.TabList( obj )

            value = obj.TabGroup.Children;

        end % get.TabList

        function value = get.TabNames( obj )

            if isempty( obj.TabList )
                value = string.empty( 0, 1 );
            else
                value = string( {obj.TabList.Title}.' );
            end % if

        end % get.TabNames

    end % methods

    methods ( Access = private )

        function onTileClicked( obj, s, ~ )
            %ONTILECLICKED Respond to the user clicking on a chart tile.

            % Determine the panel containing the image component.
            currentPanel = s.Parent.Parent;

            % Highlight the panel momentarily.
            currentPanel.BackgroundColor = obj.HighlightYellow;
            currentPanel.ForegroundColor = "black";
            pause( 0.1 )
            drawnow()
            currentPanel.BackgroundColor = obj.PlotBlue;
            currentPanel.ForegroundColor = "white";

            if isempty( obj.TabList )
                % Place the getting started label in the background.
                obj.DocumentationPanel.Children = ...
                    flip( obj.DocumentationPanel.Children );
                drawnow()
            end % if

            % Obtain the name of the selected chart.
            selectedChartName = s.Tag;

            % Depending on the selected option, we either reuse the same
            % tab for all chart documentation pages, or create a new tab
            % each time.
            if obj.ReuseTab
                if isempty( obj.SoleTab )
                    % Create a new tab.
                    obj.SoleTab = uitab( "Parent", obj.TabGroup, ...
                        "BackgroundColor", "white", ...
                        "Title", selectedChartName );
                    % Enable the view menu.
                    obj.ViewMenu.Enable = "on";
                else
                    % Clear the existing contents.
                    delete( obj.SoleTab.Children )
                end % if
                % Update the tab's title.
                obj.SoleTab.Title = selectedChartName;
                % Show the HTML version of the chart's documentation.
                exampleFile = fullfile( catalogRoot(), "+example", ...
                    selectedChartName + ".html" );
                tabOneByOne = uigridlayout( ...
                    obj.SoleTab, [1, 1], "Padding", 0, ...
                    "BackgroundColor", "w" );
                uihtml( "Parent", tabOneByOne, ...
                    "HTMLSource", exampleFile, ...
                    "DataChangedFcn", @obj.onHTMLDataChanged );
                % Update the documentation menus.
                delete( obj.DocumentationMenus )
                obj.DocumentationMenus = gobjects( 0 );
                obj.DocumentationMenus = ...
                    uimenu( "Parent", obj.ViewMenu, ...
                    "Text", selectedChartName, ...
                    "Checked", "on", ...
                    "Interruptible", "off", ...
                    "BusyAction", "cancel", ...
                    "Tag", selectedChartName, ...
                    "MenuSelectedFcn", @obj.onCloseDoc );
            else
                % Open a new tab containing the documentation for the
                % selected chart, or give the tab focus if the tab is
                % already open.
                [alreadyOpen, idx] = ...
                    ismember( selectedChartName, obj.TabNames );
                if alreadyOpen
                    % Change focus if necessary.
                    obj.TabGroup.SelectedTab = obj.TabList(idx);
                else
                    % Open a new tab and give it focus.
                    newTab = uitab( "Parent", obj.TabGroup, ...
                        "Title", selectedChartName );
                    obj.TabGroup.SelectedTab = newTab;
                    % Show the HTML version of the chart's documentation.
                    exampleFile = fullfile( catalogRoot(), "+example", ...
                        selectedChartName + ".html" );
                    tabOneByOne = uigridlayout( newTab, [1, 1], ...
                        "Padding", 0, ...
                        "BackgroundColor", "w" );
                    uihtml( "Parent", tabOneByOne, ...
                        "HTMLSource", exampleFile, ...
                        "DataChangedFcn", @obj.onHTMLDataChanged );
                    % Enable the view menu and add a new menu item.
                    obj.ViewMenu.Enable = "on";
                    obj.DocumentationMenus(end+1) = ...
                        uimenu( "Parent", obj.ViewMenu, ...
                        "Text", selectedChartName, ...
                        "Checked", "on", ...
                        "Interruptible", "off", ...
                        "BusyAction", "cancel", ...
                        "Tag", selectedChartName, ...
                        "MenuSelectedFcn", @obj.onCloseDoc );
                end % if

            end % if

        end % onTileClicked

        function onHTMLDataChanged( ~, ~, e )
            %ONHTMLDATACHANGED Respond to user interaction with hyperlinks
            %in the uihtml components.

            % Use the MATLAB web browser to handle the requested link from
            % the HTML version of the Live Script.
            web( e.Data.Link )

        end % onHTMLDataChanged

        function onCloseDoc( obj, s, ~ )
            %ONCLOSEDOC Close the corresponding documentation tab in
            %response to the user selecting a menu item.

            if obj.ReuseTab
                % Remove the sole tab.
                delete( obj.SoleTab )
                obj.SoleTab = gobjects( 0 );
                % Update the menu item.
                delete( obj.DocumentationMenus )
                obj.DocumentationMenus = gobjects( 0 );
                % Disable the view menu.
                obj.ViewMenu.Enable = "off";
                % Show the getting started label.
                obj.DocumentationPanel.Children = ...
                    flip( obj.DocumentationPanel.Children );
            else
                % Close the corresponding doc tab.
                idx = obj.TabNames == s.Tag;
                delete( obj.TabList(idx) )
                % Update the menu items.
                idx = obj.DocumentationMenus == s;
                delete( obj.DocumentationMenus(idx) )
                obj.DocumentationMenus(idx) = [];
                % Return to the initial state if necessary.
                if isempty( obj.DocumentationMenus )
                    % Disable the view menu.
                    obj.ViewMenu.Enable = "off";
                    % Show the getting started label.
                    obj.DocumentationPanel.Children = ...
                        flip( obj.DocumentationPanel.Children );
                end % if

            end % if

        end % onCloseDoc

        function onTabMenuSelected( obj, ~, ~ )
            %ONTABMENUSELECTED Toggle between separate tabs for the chart
            %doc pages or a single tab.

            % Current checked status.
            checked = obj.TabMenu.Checked;
            if checked == "off"
                % Reset the tab group.
                delete( obj.TabGroup.Children )
                obj.SoleTab = gobjects( 0 );
                % Show the getting started label.
                obj.DocumentationPanel.Children = ...
                    [obj.LabelLayout; obj.TabGroupLayout];
                % Update the view menu items.
                delete( obj.DocumentationMenus )
                obj.DocumentationMenus = gobjects( 0 );
                obj.ViewMenu.Enable = "off";
            end % if

            % Update the logical flag.
            obj.ReuseTab = ~obj.ReuseTab;

            % Update the menu item.
            obj.TabMenu.Checked = ...
                setdiff( ["on", "off"], obj.TabMenu.Checked );

        end % onTabMenuSelected

    end % methods ( Access = private )

end % class definition

function userAccessibleCharts = accessibleCharts()
%ACCESSIBLECHARTS Prepare a list of charts available to the user.
%Each chart has a set of MATLAB product dependencies. The chart catalog is
%populated with the subset of charts accessible via the user's installed
%products.

% Start with a list of all the charts.
chartNames = dir( fullfile( chartsRoot(), "*Chart.m" ) );
chartNames = string( {chartNames.name}.' );
% Remove the file extension.
chartNames = erase( chartNames, ".m" );
% Read off the chart dependencies.
nCharts = numel( chartNames );
chartDependencies = cell( nCharts, 1 );
for k = 1:nCharts
    chartDependencies{k, 1} = ...
        chart.(chartNames{k}).Dependencies;
end % for

% Decide which charts the user can see, based on their
% installation.
v = ver();
toolboxNames = string( {v.Name}.' );
userVisible = false( nCharts, 1 );
for k = 1:nCharts
    userVisible(k) = all( ...
        ismember( chartDependencies{k}, toolboxNames ) );
end % for
userAccessibleCharts = chartNames(userVisible);

end % accessibleCharts