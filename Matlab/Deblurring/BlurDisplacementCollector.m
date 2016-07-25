% These are the collected blur displacements:
% BluredTargets: X1, Y1, X2, Y2
BlurredTargets = BlurDisplacementsPairs;
FileName = 'sharp.JPG';

% Here are some control points:
% Control pattern: ID, X, Y
switch PathName
    case '\\staff-fs\cv-staff-home\cvdm7\Shaker table 5.11.12'
        % 05/11/12
        ControlPattern = [ 104,0.003,0.842 ; 106,0.003,0.517 ; 110,0,0.101 ; 101,0.780,0.839 ; 105,0.786,0.512 ; 107,0.791,0.1 ];
    case '\\staff-fs\cv-staff-home\cvdm7\Shaker table 19.11.12'
        % 19/11/12
        ControlPattern = [ 105,0,0.512 ; 107,0.001,0.1 ; 106,0.806,0.52 ; 110,0.809,0.106 ];
    case '\\staff-fs\cv-staff-home\cvdm7\Shaker table 04.12.12'
        % 4/12/12
        ControlPattern = [ 101,0,0.84 ; 105,0.005,0.512 ; 107,0.008,0.1 ; 104,0.810,0.846 ; 106,0.814,0.521 ; 110,0.816,0.107 ];
    case '\\staff-fs\cv-staff-home\cvdm7\Shaker table 29.12.12'
        % 29/12/12
        ControlPattern = [ 101,0.792,0.84 ; 105,0.789,0.512 ; 107,0.790,0.1 ; 104,0.019,0.756 ; 106,0.002,0.521 ; 110,0,0.107 ];
    case '\\hs8.lboro.ac.uk\cvdm7\Shaker table 24.4.13\A200\set2\'
        % Shaker table 24/4/13
        ControlPattern = [ 101,0.461,0.84 ; 105,0.464,0.513 ; 107,0.465,0.1 ; 104,1.302,0.845 ; 106,1.305,0.52 ; 110,1.307,0.106 ];
    case {'\\hs8.lboro.ac.uk\cvdm7\Shake table 26.4.13\A200', 'C:\Users\cvdm7\Personal Documents - Not Backed Up\Shake table 26.4.13\A200'}
        % Shake table 26.4.13
        ControlPattern = [ 101,0.602,0.84 ; 105,0.605,0.512 ; 107,0.605,0.1 ; 104,1.398,0.846 ; 106,1.402,0.52 ; 110,1.403,0.107 ];
end

% % Image 4
% ControlPoints = [101,1144.987223,346.433205 ; 104,3988.408757,365.501811 ; 105,1154.698977,1501.695078 ; 106,3985.776117,1500.363666 ; 107,1169.576981,2932.568975 ; 110,3958.961699,2923.542334 ; ];
% 
% % Image 7
% ControlPoints = [
% 101,	1144.687738,	346.400106;
% 104,	3988.279222,	365.378099;
% 105,	1154.460135,	1501.72631;
% 106,	3985.67745,     1500.28352;
% 107,	1169.406721,	2932.597805;
% 110,	3958.895456,	2923.4933;
% ];

% load the PhotoModeler 2D Point Table for control points
FileName2dpt =[ FileName(1:(size(FileName,2)-4)) 'JPG_2dpt.txt'];
% FileName2dpt = 'stillJPG_2dpt.txt';
if exist(fullfile(PathName,FileName2dpt),'file')==0
    FileName2dpt = uigetfile({'*.txt','PhotoModler 2D Point Table';...
        '*.*','All Files' },['Select 2D point table containing control points for ' FileName],fullfile(PathName,FileName2dpt));
    PMfid = fopen(fullfile(PathName,FileName2dpt));
else
    PMfid = fopen(fullfile(PathName,FileName2dpt));
end
PMdata = textscan(PMfid,'%f %f %f %f %*s %*s %*s %*s','HeaderLines',4,'Delimiter',',','CollectOutput',1);
fclose(PMfid);
PhotoNumber = 1;
[ControlPoints, ~ ] = ReadPMPointTable(PMdata,PhotoNumber);

% MatchedControlPoints = ControlPoint[x y] ControlPattern[x y]
MatchedControlPoints = [];
for p = 1:size(ControlPoints,1)
    if sum(ControlPattern(:,1)==ControlPoints(p,1)) == 1
        MatchedControlPoints(end+1,:) = [ ControlPoints(p,[2 3])  ControlPattern(ControlPattern(:,1)==ControlPoints(p,1),[2 3])];
    end
end

% Calculate the tform parameters:
TFORM = cp2tform(MatchedControlPoints(:,[1 2]),MatchedControlPoints(:,[3 4]),'projective');

BlurredTargets_fwd = zeros(size(BlurredTargets,1),4);
BlurredTargets_fwd(:,[1 2]) = tformfwd(TFORM,BlurredTargets(:,1),BlurredTargets(:,2));
BlurredTargets_fwd(:,[3 4]) = tformfwd(TFORM,BlurredTargets(:,3),BlurredTargets(:,4));

TargetDisplacements = BlurredTargets_fwd(:,[3 4]) - BlurredTargets_fwd(:,[1 2]);

disp('BlurDisplacementCollector: Blur displacements saved in TargetDisplacements array');
openvar('TargetDisplacements');
% TargetDisplacements_EcldDist = 