function [Rot] = FormR(Cam, varargin)

if nargin < 2
    Rmat_type = 'opk';
elseif nargin < 3
    Rmat_order = 'ZYX';
else
    Rmat_type = varargin{1};
    Rmat_order = varargin{2};
end

sO = sin(Cam.omega);
cO = cos(Cam.omega);
sP = sin(Cam.phi);
cP = cos(Cam.phi);
sK = sin(Cam.kappa);
cK = cos(Cam.kappa);

switch Rmat_type
    case 'opk'
        
        Rot(1,1) = cP * cK;
        Rot(1,2) = cO * sK + sO * sP * cK;
        Rot(1,3) = sO * sK - cO * sP * cK;
        
        Rot(2,1) = -cP * sK;
        Rot(2,2) = cO * cK - sO * sP * sK;
        Rot(2,3) = sO * cK + cO * sP * sK;
        
        Rot(3,1) = sP;
        Rot(3,2) = -sO * cP;
        Rot(3,3) = cO * cP;
        
        % Rot = Rot';
        
    case 'pok'
        
        Rot(1,1) = cP * cK + sP * sO * sK;
        Rot(1,2) = cO * sK;
        Rot(1,3) = -sP * cK + cP * sO * sK;
        
        Rot(2,1) = -cP * sK + sP * sO * cK;
        Rot(2,2) = cO * cK;
        Rot(2,3) = sP * sK + cP * sO * cK;
        
        Rot(3,1) = sP * cO;
        Rot(3,2) = -sO;
        Rot(3,3) = cP * cO;
        
        Rot = Rot';
        
    case {'opk2','pok2','kpo','pko'}
        RotO = [ 1  0   0   ; ...
                 0  cO  -sO ; ...
                 0  sO  cO  ];
        RotP = [  cP  0  sP ; ...
                  0   1  0  ; ...
                 -sP  0  cP ];
        RotK = [ cK  -sK  0 ; ...
                 sK  cK   0 ; ...
                 0   0    1 ];
        
        switch Rmat_type
            case 'opk2'
                Rot = RotO * RotP * RotK;
            case 'pok2'
                Rot = RotP * RotO * RotK;
            case 'kpo'
                Rot = RotK * RotP * RotO;
            case 'pko'
            	Rot = RotP * RotK * RotO;
        end
        
        Rot = Rot';
        
    case 'cosines'
        Rot = angle2dcm(Cam.omega,Cam.phi,Cam.kappa,Rmat_order);
        
        Rot = Rot';
end