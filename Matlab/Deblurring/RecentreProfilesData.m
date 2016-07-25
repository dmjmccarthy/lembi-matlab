% RecentreProfilesData
% D McCarthy - Jan
%
% Modifies the origin of ProfilesData
% Usage:
% [NewProfilesData] = RecentreProfilesData(OldProfilesData, NewCropCorner, [OldCropCorner])

function [NewProfilesData] = RecentreProfilesData(OldProfilesData, NewCropCorner, varargin)

if isfield(OldProfilesData,'crop_corner')
    OldCropCorner = OldProfilesData.crop_corner;
else
    if size(varargin,1) > 0
        OldCropCorner = varargin{1};
    else
        warning('RecentreProfilesData: There is no existing crop_corner.')
        OldCropCorner = [0,0];
    end
end

 OldProfilesData.blob_WeightedCentroid(:,[1 2]) = ...
     OldProfilesData.blob_WeightedCentroid(:,[1 2]) - NewCropCorner + OldCropCorner;
 
 OldProfilesData.blob_WeightedCentroid(:,[1 2]) = ...
     OldProfilesData.blob_WeightedCentroid(:,[1 2]) - NewCropCorner + OldCropCorner;
 
 OldProfilesData.circfit_result(:,[1 2]) = ...
     OldProfilesData.circfit_result(:,[1 2]) + repmat( -NewCropCorner + OldCropCorner,2,1);
 
 NewProfilesData = OldProfilesData;
 NewProfilesData.crop_corner = NewCropCorner;