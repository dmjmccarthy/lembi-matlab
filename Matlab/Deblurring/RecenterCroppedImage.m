% RecenterCoppedImage
% Given an uncropped image, it crops to the right size
%
% D McCarthy - Jan 2013
%
% Usage: [I_cropped, I_crop_corner, I_new_estimated_centre] = RecenterCroppedImage(I,centre,window_size)

function [I_cropped, I_crop_corner, I_new_estimated_centre] = RecenterCroppedImage(I,centre,window_size)

if size(I,3) > 1
    I = rgb2gray(I);
end

if centre(1) > size(I,1) || centre(2) > size(I,2)
    error('Centre exceeds image dimensions')
end

I_crop_corner = floor(centre) - window_size./2 + [1 1];
decimal_part = centre - floor(centre);
disp(['RecenterCroppedImage: subpixel resampling using bilinear.  decimal_part = ' num2str(decimal_part)]);

I_cropped = imcrop(I, [I_crop_corner([2 1]) window_size([2 1])]);


% Create transform to pan image
input_points = [1 1; 2 2];
base_points = input_points - repmat(decimal_part,2,1);
TFORM = cp2tform(input_points, base_points, 'nonreflective similarity');
% Translate image
I_cropped = imtransform(I_cropped,TFORM,'bilinear','XData',[1 size(I_cropped,2)],'YData',[1 size(I_cropped,1)]);
% Cut away padding
I_cropped = I_cropped(1:end-1,1:end-1);



I_new_estimated_centre = centre - I_crop_corner;