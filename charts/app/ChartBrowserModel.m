classdef ChartBrowserModel < handle
    %CHARTBROWSERMODEL Application data model for the Chart Browser app.

    properties ( SetAccess = private )
        % List of all charts.
        AllChartNames(1, :) string
        % List of all charts accessible to the user.
        AccessibleChartNames(1, :) string
        % List of all documentation files.
        DocumentationFiles(1, :) string
        % Icon dictionary.
        IconDictionary(1, 1) dictionary
        % Currently selected chart.
        SelectedChart(1, 1) string
        % Currently selected example.
        SelectedExample(1, 1) string
        % Currently selected documentation file.
        SelectedDocumentationFile(1, 1) string
    end % properties ( SetAccess = private )

    events ( NotifyAccess = private )
        % A new chart has been selected.
        ChartSelected
        % A new example has been selected.
        ExampleSelected
        % A new documentation file has been selected.
        DocumentationFileSelected
    end % events ( NotifyAccess = private )

    methods

        function obj = ChartBrowserModel()
            %CHARTBROWSERMODEL Construct a ChartBrowserModel object.

            % Record the chart names.
            [obj.AllChartNames, obj.AccessibleChartNames] = chartNames();

            % Obtain a list of documentation files.
            docFiles = ls( fullfile( chartsRoot(), "doc", "*.m" ) );
            docFiles = extractBefore( string( docFiles ), ".m" );
            obj.DocumentationFiles = docFiles.';

            % List the icon files corresponding to the accessible charts.
            iconFiles = fullfile( chartsRoot(), "app", "images", ...
                obj.AccessibleChartNames + "40.png" );

            % Create a datastore for importing the icons, preserving the
            % transparent backgrounds.
            iconDatastore = fileDatastore( iconFiles, ...
                "ReadFcn", @importImageIcon );

            % Initialize the icon dictionary. The keys are the chart names,
            % and each value is a 1-by-2 cell array containing the icon and
            % the short description of the chart.
            iconDictionary = configureDictionary( "string", "cell" );

            % Store the icons and descriptions.
            while hasdata( iconDatastore )
                [icon, info] = read( iconDatastore );
                [~, name] = fileparts( info.Filename );
                name = erase( name, "40" );
                description = eval( name + ".ShortDescription" );
                iconDictionary{name} = {icon, description};
            end % while

            obj.IconDictionary = iconDictionary;

        end % constructor

        function select( obj, chartName )
            %SELECT Select both the chart and example.

            arguments ( Input )
                obj(1, 1) ChartBrowserModel
                chartName(1, 1) string
            end % arguments ( Input )

            % Select the new chart and example.
            obj.selectChart( chartName )
            obj.selectExample( chartName )
            
        end % select

        function selectChart( obj, chartName )
            %SELECTCHART Select a new chart.

            arguments ( Input )
                obj(1, 1) ChartBrowserModel 
                chartName(1, 1) string
            end % arguments ( Input )

            % Validate the chart name.
            obj.validateChartName( chartName )

            % Update the selected chart.
            obj.SelectedChart = chartName;

            % Notify the event.
            obj.notify( "ChartSelected" )

        end % selectChart

        function selectExample( obj, chartName )
            %SELECTEXAMPLE Select a new example.

            arguments ( Input )
                obj(1, 1) ChartBrowserModel
                chartName(1, 1) string
            end % arguments ( Input )

            % Validate the chart name.
            obj.validateChartName( chartName )

            % Update the selected example.
            obj.SelectedExample = chartName;

            % Notify the event.
            obj.notify( "ExampleSelected" )

        end % selectExample

        function selectDocFile( obj, docFile )
            %SELECTDOCFILE Select a new documentation file.

            arguments ( Input )
                obj(1, 1) ChartBrowserModel
                docFile(1, 1) string
            end % arguments ( Input )

            % Validate.
            assert( ismember( docFile, obj.DocumentationFiles ) || ...
                docFile == "", "ChartBrowserModel:InvalidDocFile", ...
                "Unrecognized documentation file name " + docFile + "." )

            % Update the selected documentation file.
            obj.SelectedDocumentationFile = docFile;

            % Notify the event.
            obj.notify( "DocumentationFileSelected" )

        end % selectDocFile

    end % methods

    methods ( Access = private )

        function validateChartName( obj, chartName )
            %VALIDATECHARTNAME Validate that the given chart name is an
            %accessible chart.

            arguments ( Input )
                obj(1, 1) ChartBrowserModel
                chartName(1, 1) string
            end % arguments ( Input )

            % Validate the chart name.
            assert( ismember( chartName, obj.AccessibleChartNames ) || ...
                chartName == "", "ChartBrowserModel:InvalidChartName", ...
                "Unrecognized chart name " + chartName + "." )

        end % validateChartName

    end % methods ( Access = private )

end % classdef