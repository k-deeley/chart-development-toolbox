%[text] # Scatter plot with a best-fit line.
%[text] ## Create sample (x, y) data.
rng( "default" )
x = linspace( 0, 1, 1000 ).';
y = 2 * x + 1 + 0.25 * randn( size( x ) );
%%
%[text] ## Create a scatter plot of the data.
figure
s = scatter( x, y, "filled" );
%%
%[text] ## Add the best-fit line.
mdl = fitlm( x, y );
hold on
plot( x, mdl.Fitted, "LineWidth", 2 )
%%
%[text] ## Suppose that our x-data changes.
s.XData = s.XData + 2;

% This changes updates the scatter plot, but not the best-fit line 
% associated with the (x, y)-data.
%
% This demonstrates the first issue - the scatter plot and the best-fit
% line are not synchronized.
%%
%[text] ## Suppose that our x-data now has a different size.
xnew = x(1:500);
s.XData = xnew;

% This change causes the scatter plot to issue a warning, since its XData
% and YData properties now have different lengths. The scatter plot is no
% longer rendered.
%%
%[text] ## Now update the y-data.
%[text] This will render the scatter object as long as the new y-data has the same length as the new x-data.
s.YData = - 2 * xnew + 0.5 + randn( size( xnew ) );

% This demonstrates the second issue - changing x/y-data individually may 
% cause the scatter plot to disappear.

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"onright"}
%---
