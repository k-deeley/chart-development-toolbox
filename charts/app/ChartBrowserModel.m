classdef ChartBrowserModel < handle
    %CHARTBROWSERMODEL Application data model for the Chart Browser app.

    properties ( Constant )
        % File group names.
        GroupNames = ["Documentation", "Examples", "Source Code"]
        % File group tags.
        GroupTags = ["01_Documentation", "02_Examples", "03_SourceCode"]
        % Group folder names.
        GroupFolders = ["doc", "examples", "charts"]
    end % properties ( Constant )

    properties ( SetAccess = private )
        % List of open documentation files.
        OpenDocumentationFiles(1, :) string = string.empty( 1, 0 )
        % List of open chart example files.
        OpenExampleFiles(1, :) string = string.empty( 1, 0 )
        % List of open chart source code files.
        OpenSourceCodeFiles(1, :) string = string.empty( 1, 0 )
        % List of all documentation files.
        DocumentationNames(1, :) string = string.empty( 1, 0 )
        % List of all examples accessible to the user.
        AccessibleExampleNames(1, :) string = string.empty( 1, 0 )
        % List of all charts.
        AllChartNames(1, :) string = string.empty( 1, 0 )
        % List of all charts accessible to the user.
        AccessibleChartNames(1, :) string = string.empty( 1, 0 )
        % Icon dictionary.
        IconDictionary(1, 1) dictionary = ...
            configureDictionary( "string", "cell" )
    end % properties ( SetAccess = private )

    events ( NotifyAccess = private )
        % A file has been opened.
        FileOpened
        % A file has been closed.
        FileClosed
    end % events ( NotifyAccess = private )

    methods

        function obj = ChartBrowserModel()
            %CHARTBROWSERMODEL Construct a ChartBrowserModel object.

            % Record the chart names.
            [obj.AllChartNames, obj.AccessibleChartNames] = chartNames();

            % Store the example names.
            obj.AccessibleExampleNames = obj.AccessibleChartNames + ...
                "Examples";

            % Obtain a list of documentation files.
            docFiles = ls( fullfile( chartsRoot(), "doc", "*.m" ) );
            docFiles = extractBefore( string( docFiles ), ".m" );
            obj.DocumentationNames = docFiles.';

            % List the icon files corresponding to the accessible charts.
            iconFiles = fullfile( chartsRoot(), "app", "images", ...
                obj.AccessibleChartNames + "40.png" );

            % Create a datastore for importing the icons, preserving the
            % transparent backgrounds.
            iconDatastore = fileDatastore( iconFiles, ...
                "ReadFcn", @importImageIcon );

            % Set up the icon dictionary. The keys are the chart names,
            % and each value is a 1-by-2 cell array containing the icon (in
            % cell 1) and the short description of the chart (in cell 2).
            iconDictionary = obj.IconDictionary;

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

        function openFile( obj, filename )
            %OPENFILE Open a file.

            arguments ( Input )
                obj(1, 1) ChartBrowserModel
                filename(1, 1) string
            end % arguments ( Input )

            % Validate the filename.
            status = obj.validateName( filename );

            % Update the list of open files.
            if status(1)
                if ~ismember( filename, obj.OpenDocumentationFiles )
                    obj.OpenDocumentationFiles(1, end+1) = filename;
                end % if
                eventData = ChartBrowserEventData( filename, ...
                    "doc", "01_Documentation" );
            elseif status(2)
                if ~ismember( filename, obj.OpenExampleFiles )
                    obj.OpenExampleFiles(1, end+1) = filename;
                end % if
                eventData = ChartBrowserEventData( filename, ...
                    "examples", "02_Examples" );
            elseif status(3)
                if ~ismember( filename, obj.OpenSourceCodeFiles )
                    obj.OpenSourceCodeFiles(1, end+1) = filename;
                end % if
                eventData = ChartBrowserEventData( filename, ...
                    "charts", "03_SourceCode" );
            end % if

            % Notify the event.
            obj.notify( "FileOpened", eventData )

        end % openFile

        function closeFile( obj, filename, notifyEvent )
            %CLOSEFILE Close a file.

            arguments ( Input )
                obj(1, 1) ChartBrowserModel
                filename(1, 1) string
                notifyEvent(1, 1) logical = true
            end % arguments ( Input )

            % Validate the chart name.
            status = obj.validateName( filename );
            isAlreadyOpen = [
                ismember( filename, obj.OpenDocumentationFiles );
                ismember( filename, obj.OpenExampleFiles );
                ismember( filename, obj.OpenSourceCodeFiles )];

            % Update the list of open files.
            if status(1) && isAlreadyOpen(1)
                obj.OpenDocumentationFiles = setdiff( ...
                    obj.OpenDocumentationFiles, filename, "stable" );
                eventData = ChartBrowserEventData( filename, ...
                    "doc", "01_Documentation" );
            elseif status(2) && isAlreadyOpen(2)
                obj.OpenExampleFiles = setdiff( ...
                    obj.OpenExampleFiles, filename, "stable" );
                eventData = ChartBrowserEventData( filename, ...
                    "examples", "02_Examples" );
            elseif status(3) && isAlreadyOpen(3)
                obj.OpenSourceCodeFiles = setdiff( ...
                    obj.OpenSourceCodeFiles, filename, "stable" );
                eventData = ChartBrowserEventData( filename, ...
                    "charts", "03_SourceCode" );
            end % if

            % Notify the event.
            if any( isAlreadyOpen ) && notifyEvent
                obj.notify( "FileClosed", eventData )
            end % if

        end % closeFile

        function group = findGroupFromFile( obj, file )
            %FINDGROUPFROMFILE Identify the group corresponding to the
            %given file.

            arguments ( Input )
                obj(1, 1) ChartBrowserModel
                file(1, 1) string
            end % arguments ( Input )

            status = obj.validateName( file );
            group = obj.GroupNames(status);

        end % findGroupFromFile

        function path = fullpath( obj, file )
            %FULLPATH Return the full path to the given file.

            arguments ( Input )
                obj(1, 1) ChartBrowserModel
                file(1, 1) string
            end % arguments

           status = obj.validateName( file );
           folder = obj.GroupFolders(status);
           path = fullfile( chartsRoot(), folder, file + ".m" );

        end % fullpath

        function name = formatName( obj, file )
            %FORMATNAME Return the formatted display name for a given file.

            arguments ( Input )
                obj(1, 1) ChartBrowserModel
                file(1, 1) string
            end % arguments ( Input )

            % Validate the file.
            status = obj.validateName( file );

            % Deal with special cases.
            if status(1) % doc

                switch file
                    case "WhatIsAChart"
                        name = "What is a Chart?";
                    case "GettingStartedApp"
                        name = "Getting Started";
                    case "CreatingSpecializedCharts"
                        name = "Development Guide";
                    case "TechnicalArticle"
                        name = "Technical Article";
                end % switch/case

            elseif status(2) || status(3)
                
                % Insert a space before each capital letter.
                name = regexprep( file, "([A-Z])", " $1" );
                
                % Remove the leading space.
                name = strtrim( name );

            end % if

        end % formatName

    end % methods

    methods ( Access = private )

        function status = validateName( obj, filename )
            %VALIDATENAME Validate that the given file exists.

            arguments ( Input )
                obj(1, 1) ChartBrowserModel
                filename(1, 1) string
            end % arguments ( Input )

            isdoc = ismember( filename, obj.DocumentationNames );
            isexample = ismember( filename, obj.AccessibleExampleNames );
            ischart = ismember( filename, obj.AccessibleChartNames );
            tf = isdoc || isexample || ischart;
            assert( tf, "ChartBrowserModel:InvalidFilename", ...
                "Unrecognized filename " + filename + "." )
            status = [isdoc; isexample; ischart];

        end % validateName

    end % methods ( Access = private )

end % classdef