function [ObjCds] = Reproj(Im1, Im2, P1, P2, r1, r2, ObjCds)

pa = zeros(4,3);

% A matrix
pa(1, 1) = Im1.x * r1(3,1) - P1.f * r1(1,1);
pa(1, 2) = Im1.x * r1(3,2) - P1.f * r1(1,2);
pa(1, 3) = Im1.x * r1(3,3) - P1.f * r1(1,3);
pa(2, 1) = Im1.y * r1(3,1) - P1.f * r1(2,1);
pa(2, 2) = Im1.y * r1(3,2) - P1.f * r1(2,2);
pa(2, 3) = Im1.y * r1(3,3) - P1.f * r1(2,3);

pa(3, 1) = Im2.x * r2(3,1) - P2.f * r2(1,1);
pa(3, 2) = Im2.x * r2(3,2) - P2.f * r2(1,2);
pa(3, 3) = Im2.x * r2(3,3) - P2.f * r2(1,3);
pa(4, 1) = Im2.y * r2(3,1) - P2.f * r2(2,1);
pa(4, 2) = Im2.y * r2(3,2) - P2.f * r2(2,2);
pa(4, 3) = Im2.y * r2(3,3) - P2.f * r2(2,3);

% Obs - computed terms
qa(1) = Im1.x * (P1.x * r1(3,1) + P1.y * r1(3,2) + P1.Z * r1(3,3)) - P1.f * (P1.x * r1(1,1) + P1.y * r1(1,2) + P1.Z * r1(1,3));
qa(2) = Im1.y * (P1.x * r1(3,1) + P1.y * r1(3,2) + P1.Z * r1(3,3)) - P1.f * (P1.x * r1(2,1) + P1.y * r1(2,2) + P1.Z * r1(2,3));

qa(3) = Im2.x * (P2.x * r2(3,1) + P2.y * r2(3,2) + P2.Z * r2(3,3)) - P2.f * (P2.x * r2(1,1) + P2.y * r2(1,2) + P2.Z * r2(1,3));
qa(4) = Im2.y * (P2.x * r2(3,1) + P2.y * r2(3,2) + P2.Z * r2(3,3)) - P2.f * (P2.x * r2(2,1) + P2.y * r2(2,2) + P2.Z * r2(2,3));

pa;
qa;

sa = pa' * pa;      % Form AtA
qal = pa' * qa';    % Form Atq
u = sa\qal;        % Solve equations

ObjCds.x = u(1);
ObjCds.y = u(2);
ObjCds.z = u(3);

