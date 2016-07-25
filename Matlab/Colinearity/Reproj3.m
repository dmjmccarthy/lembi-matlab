function [ObjCds] = Reproj3(PobsMeas, Allphots, rots, ObjCds)
% function [ObjCds] = Reproj3(Im1, Im2, P1, P2, r1, r2, ObjCds)

images = length(Allphots);

% Im = PobsMeas
% P = Allphots
% r = rots

% A matrix
pa = zeros(images*2,3);
for Im_number = 1:images
    
    pa(Im_number*2-1, 1) = PobsMeas{Im_number}.x * rots{Im_number}(3,1) - Allphots{Im_number}.f * rots{Im_number}(1,1);
    pa(Im_number*2-1, 2) = PobsMeas{Im_number}.x * rots{Im_number}(3,2) - Allphots{Im_number}.f * rots{Im_number}(1,2);
    pa(Im_number*2-1, 3) = PobsMeas{Im_number}.x * rots{Im_number}(3,3) - Allphots{Im_number}.f * rots{Im_number}(1,3);
    
    pa(Im_number*2  , 1) = PobsMeas{Im_number}.y * rots{Im_number}(3,1) - Allphots{Im_number}.f * rots{Im_number}(2,1);
    pa(Im_number*2  , 2) = PobsMeas{Im_number}.y * rots{Im_number}(3,2) - Allphots{Im_number}.f * rots{Im_number}(2,2);
    pa(Im_number*2  , 3) = PobsMeas{Im_number}.y * rots{Im_number}(3,3) - Allphots{Im_number}.f * rots{Im_number}(2,3);
    
end

% Obs - computed terms
qa = zeros(images*2,1);
for Im_number = 1:images
    qa(Im_number*2-1) = PobsMeas{Im_number}.x * (Allphots{Im_number}.x * rots{Im_number}(3,1) + Allphots{Im_number}.y * rots{Im_number}(3,2) + Allphots{Im_number}.Z * rots{Im_number}(3,3)) - Allphots{Im_number}.f * (Allphots{Im_number}.x * rots{Im_number}(1,1) + Allphots{Im_number}.y * rots{Im_number}(1,2) + Allphots{Im_number}.Z * rots{Im_number}(1,3));
    qa(Im_number*2  ) = PobsMeas{Im_number}.y * (Allphots{Im_number}.x * rots{Im_number}(3,1) + Allphots{Im_number}.y * rots{Im_number}(3,2) + Allphots{Im_number}.Z * rots{Im_number}(3,3)) - Allphots{Im_number}.f * (Allphots{Im_number}.x * rots{Im_number}(2,1) + Allphots{Im_number}.y * rots{Im_number}(2,2) + Allphots{Im_number}.Z * rots{Im_number}(2,3));
end

pa;
qa;

sa = pa' * pa;      % Form AtA
qal = pa' * qa;    % Form Atq
u = sa\qal;        % Solve equations

ObjCds.x = u(1);
ObjCds.y = u(2);
ObjCds.z = u(3);

