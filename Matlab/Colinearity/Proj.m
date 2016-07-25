function [Lft, Rgt] = Proj(P1, P2, r1, r2, ObjCds)

    dx1 = ObjCds.x - P1.x;
    dy1 = ObjCds.y - P1.y;
    dz1 = ObjCds.z - P1.Z;
    dx2 = ObjCds.x - P2.x;
    dy2 = ObjCds.y - P2.y;
    dz2 = ObjCds.z - P2.Z;
    
    Lft.x = ((r1(1,1) * dx1 + r1(1,2) * dy1 + r1(1,3) * dz1) / (r1(3,1) * dx1 + r1(3,2) * dy1 + r1(3,3) * dz1)) * P1.f;
    Lft.y = ((r1(2,1) * dx1 + r1(2,2) * dy1 + r1(2,3) * dz1) / (r1(3,1) * dx1 + r1(3,2) * dy1 + r1(3,3) * dz1)) * P1.f;
    Rgt.x = ((r2(1,1) * dx2 + r2(1,2) * dy2 + r2(1,3) * dz2) / (r2(3,1) * dx2 + r2(3,2) * dy2 + r2(3,3) * dz2)) * P2.f;
    Rgt.y = ((r2(2,1) * dx2 + r2(2,2) * dy2 + r2(2,3) * dz2) / (r2(3,1) * dx2 + r2(3,2) * dy2 + r2(3,3) * dz2)) * P2.f;
    
%     Lft.x = ((r1(1,1) * dx1 + r1(2,1) * dy1 + r1(3,1) * dz1) / (r1(1,3) * dx1 + r1(2,3) * dy1 + r1(3,3) * dz1)) * P1.f;
%     Lft.y = ((r1(1,2) * dx1 + r1(2,2) * dy1 + r1(3,2) * dz1) / (r1(1,3) * dx1 + r1(2,3) * dy1 + r1(3,3) * dz1)) * P1.f;
%     Rgt.x = ((r2(1,1) * dx2 + r2(2,1) * dy2 + r2(3,1) * dz2) / (r2(1,3) * dx2 + r2(2,3) * dy2 + r2(3,3) * dz2)) * P2.f;
%     Rgt.y = ((r2(1,2) * dx2 + r2(2,2) * dy2 + r2(3,2) * dz2) / (r2(1,3) * dx2 + r2(2,3) * dy2 + r2(3,3) * dz2)) * P2.f;