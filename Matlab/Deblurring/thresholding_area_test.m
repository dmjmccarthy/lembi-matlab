function [varargout] = thresholding_area_test(I3,Isharp,I_user_selected_point,Isharp_user_selected_point)
% I3: Blurred image, already cropped and grayscale
% Isharp: Sharp image, already cropped and grayscale

% figure, subplot(1,2,1), imshow(I3), subplot(1,2,2), imshow(Isharp)

% Thresold the blurred image
blurred_threshold = graythresh(I3);
bw = im2bw(I3,blurred_threshold);
blobs = bwconncomp(bw, 4);
blobs_labelled =  labelmatrix(blobs);
I_user_selected_point = round(I_user_selected_point);
selected_blob_no = blobs_labelled( I_user_selected_point(1) , I_user_selected_point(2) );
blurred_blob_prop = regionprops(struct('Connectivity',4,'ImageSize',blobs.ImageSize, ...
    'NumObjects',1, ...
    'PixelIdxList', {{ blobs.PixelIdxList{selected_blob_no} }} ) ...
    ,'Area');

% figure, imshow(blobs_labelled), caxis auto, colormap('jet');

% Thresold the sharp image
sharp_threshold = graythresh(Isharp);
Isharp_bw = im2bw(Isharp,sharp_threshold);
blobs = bwconncomp(Isharp_bw, 4);
blobs_labelled =  labelmatrix(blobs);
Isharp_user_selected_point = round(Isharp_user_selected_point);
selected_blob_no = blobs_labelled(Isharp_user_selected_point(1),Isharp_user_selected_point(2));
sharp_blob_prop = regionprops(struct('Connectivity',4,'ImageSize',blobs.ImageSize, ...
    'NumObjects',1, ...
    'PixelIdxList', {{ blobs.PixelIdxList{selected_blob_no} }} ) ...
    ,'Area');

% figure, imshow(blobs_labelled), caxis auto, colormap('jet');
% figure;

% % if the blur threshold is significantly different
% % then this is an external blur!
% area_ratio = blurred_blob_prop.Area / sharp_blob_prop.Area;
% if area_ratio <= 1
%     blur_type = 'internal';
% elseif area_ratio > 1
%     blur_type = 'external';
% end
% % disp(['thresholding_area_test: This is an ' upper(blur_type) ' blur (blurred/sharp area ratio: ' num2str(area_ratio) ').'])

% work it out based on thresholds!
threshold_ratio = blurred_threshold / sharp_threshold;
if threshold_ratio < 0.7
    blur_type = 'external';
else
    blur_type = 'internal';
end
fprintf('thresholding_area_test: This is %s blur (threshold ratio: %1.3f ).\n',upper(blur_type),threshold_ratio);



varargout{1} = blur_type;
if exist('area_ratio','var')
varargout{2} = area_ratio;
end
% At the low threshold, 