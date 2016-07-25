% circfit_residuals
% D McCarthy - Jan 13
% Finds the residuals of coordinates fit to a circle
%
% Usage:
% [sum_residuals] = circfit_residuals(xc,yc,R,x,y)
% Where:
% xc, yc, R are the variables of the circle
% x, y are column vectors of the coordinates used to fit the circle

function [sum_residuals] = circfit_residuals(xc,yc,R,x,y)

differences = (repmat([xc, yc],size(x,1),1) - [x, y]);

eclud_dists = sqrt(sum(differences.^2,2));

residuals = abs(eclud_dists-R);

sum_residuals = sum(residuals)/size(x,1);
