% show_displacements - D McCarthy May 2014
% Opens a GAP format displacement vectors file as the result of the
% ComputeIntersection program and plots the motion vectors.
%
% Usage: [h] = show_displacements(filename, ctrlfile, [colour_style], [scale])
% Inputs:
% filename      : name of GAP format data file
% ctrlfile      : CSV file listing control target coordinates
% colour_style  : {'any', 'bi'}
% scale         : Scale vectors (after auto scaling). 0 = no auto scaling.
%                 Default = 0.5
% Outputs:
% h             : figure handle

function [varargout] = show_displacements(filename,varargin)
if nargin==1
    ctrlfile = '\\hs8.lboro.ac.uk\cvdm7\MATLAB\DeblurTo3D\ControlPointsCoords.csv'
else
    ctrlfile = varargin{1};
end
if nargin<3
    colour_style = 'any';
else
    colour_style = varargin{2};
end
if nargin<4
    scale = 0.5;
else
    scale = varargin{3};
end

fid = fopen(filename);
read_text = textscan(fid,'%*s %f %f %f%*[^\n]', ...
    'CommentStyle','#');
fclose(fid);

ctrl = csvread(ctrlfile);

in = cell2mat(read_text);

%in = csvread('tarPaired.csv');
x = in(1:2:end,1);
y = in(1:2:end,2);
z = in(1:2:end,3);

u = in(1:2:end,1) - in(2:2:end,1);
v = in(1:2:end,2) - in(2:2:end,2);
w = in(1:2:end,3) - in(2:2:end,3);

%w = zeros(50,1);

% plot3(x,y,z,'+b')
handle = figure;
plot3(ctrl(:,2),ctrl(:,3),ctrl(:,4),'^r')
hold on
switch colour_style
    case 'any'
quiver3(x,y,z,u,v,w,scale)
quiver3(x,y,z,-u,-v,-w,scale)
    case 'bi'
quiver3(x(1:2:end),y(1:2:end),z(1:2:end),u(1:2:end),v(1:2:end),w(1:2:end),scale,'r')
quiver3(x(2:2:end),y(2:2:end),z(2:2:end),u(2:2:end),v(2:2:end),w(2:2:end),scale,'b')
quiver3(x(1:2:end),y(1:2:end),z(1:2:end),-u(1:2:end),-v(1:2:end),-w(1:2:end),scale,'r')
quiver3(x(2:2:end),y(2:2:end),z(2:2:end),-u(2:2:end),-v(2:2:end),-w(2:2:end),scale,'b')
end
axis equal
xlabel 'x'
ylabel 'y'
zlabel 'z'

varargout{1} = handle;

% figure(2)
% plot3(in(:,1),in(:,2),in(:,3),'b+')
% axis equal