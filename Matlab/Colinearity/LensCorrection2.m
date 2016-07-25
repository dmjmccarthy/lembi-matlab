function [Pobs] = LensCorrection2(Pobs, IOP)
% To compute and apply IO & lens distortion corrections, new IO Model included
% working units m

Xr = Pobs.x;
Yr = Pobs.y;

%/*      printf("input image: %lf %lf   %lf\n", Xr, Yr, CamPt->xscale); */
% /* Compute corrections for XScale (note: NO correction for y photo-coords!) */
dxDig = Xr - (Xr * IOP.DiffScale);

%/* Compute corrections for Affine */
dxDig = dxDig + Yr - (Yr * IOP.Affine);
dyDig = Xr - (Xr * IOP.Affine);

R1 = Xr * Xr;
R3 = Yr * Yr;
R2 = R1 + R3;

R4 = R2 * R2;
R6 = R2 * R4;

R7 = 2 * R1 + R2;
R8 = 2 * R3 + R2;
R9 = 2 * Xr * Yr;

Dxt = Xr * (IOP.K1 * R2 + IOP.K2 * R4 + IOP.K3 * R6);
Dyt = Yr * (IOP.K1 * R2 + IOP.K2 * R4 + IOP.K3 * R6);

Dxt = Dxt + IOP.P1 * R7 + IOP.P2 * R9;
Dyt = Dyt + IOP.P2 * R8 + IOP.P1 * R9;

%'/* Add displacement of Principal point */
Pobs.x = Pobs.x + Dxt + dxDig + IOP.Xp;
Pobs.y = Pobs.y + Dyt + dyDig + IOP.Yp;

%' Debug.Print "Corrections: Dxt: "; Dxt * 1000000; "Dyt: "; Dyt * 1000000
