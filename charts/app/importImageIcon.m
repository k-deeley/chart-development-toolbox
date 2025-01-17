function icon = importImageIcon( file )
%IMPORTIMAGEICON Create a javax.swing.ImageIcon from the given
%file.

arguments ( Input )
    file(1, 1) string {mustBeFile}
end % arguments ( Input )

% Create a Java string from the filename.
file = java.lang.String( file );

% Create a javax.swing.ImageIcon from the image file.
icon = javax.swing.ImageIcon( file );

end % importImageIcon