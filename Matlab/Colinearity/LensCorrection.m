function [Pobs] = LensCorrection(Pobs,IOP)

% Apply Principal Point offsets
xakt = Pobs.x - IOP.Xp;
yakt = Pobs.y - IOP.Yp;

tt1 = xakt * xakt;
tt3 = yakt * yakt;
tt2 = tt1 + tt3;
tt4 = tt2 * tt2;
tt6 = tt2 * tt4;
tt7 = (2 * tt1) + tt2;
tt8 = (2 * tt3) + tt2;
tt9 = 2 * xakt * yakt;

% Compute correction for Radial lens distortion
Radial = IOP.K1 * tt2 + IOP.K2 * tt4 + IOP.K3 * tt6;
Corr.x = xakt * Radial;
Corr.y = yakt * Radial;

% Compute correction for Tangential lens distortion
Corr.x = Corr.x - (IOP.P1 * tt7 + IOP.P2 * tt9);
Corr.y = Corr.y - (IOP.P2 * tt8 + IOP.P1 * tt9);

% Debug.Print "Corrections: "; Corr.x * 1000000; Corr.y * 1000000
Pobs.x = Pobs.x - IOP.Xp - Corr.x;
Pobs.y = Pobs.y - IOP.Yp - Corr.y;
