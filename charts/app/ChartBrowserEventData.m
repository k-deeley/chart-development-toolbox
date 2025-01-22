classdef ChartBrowserEventData < event.EventData
    %CHARTBROWSEREVENTDATA Custom event data for the Chart Browser model.

    properties ( SetAccess = immutable )
        % Name of the file that has just been opened.
        File(:, 1) string {mustBeScalarOrEmpty}
        % File group.
        Folder(:, 1) string {mustBeGroupFolder, mustBeScalarOrEmpty}
        % Group tag.
        Tag(:, 1) string {mustBeGroupTag, mustBeScalarOrEmpty}
    end % properties ( SetAccess = immutable )

    methods

        function obj = ChartBrowserEventData( file, folder, tag )
            %CHARTBROWSEREVENTDATA Construct the event payload, given the
            %filename, group, and tag.

            narginchk( 3, 3 )

            obj.File = file;
            obj.Folder = folder;
            obj.Tag = tag;

        end % constructor

    end % methods

end % classdef

function mustBeGroupFolder( folder )
%MUSTBEGROUPFOLDER Validate the the given folder is a member of the list of
%group folders.

mustBeMember( folder, ChartBrowserModel.GroupFolders )

end % mustBeGroupFolder

function mustBeGroupTag( tag )
%MUSTBEGROUPTAG Validate the the given tag is a member of the list of
%group tags.

mustBeMember( tag, ChartBrowserModel.GroupTags )

end % mustBeGroupTag