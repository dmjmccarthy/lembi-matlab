% Show points on images
function ShowGapPoints(coords_filepath)

data_fid = fopen(coords_filepath,'rt');
data_read = textscan(data_fid,'%*s %*s %f %f %*[^\n]', ...
    'CommentStyle','#');
fclose(data_fid);

pts = cell2mat(data_read);

% figure,
% imshow(imread(image_filepath))
% hold on
figure
plot(pts(1:2:end,1),pts(1:2:end,2),'b+', ...
    pts(2:2:end,1),pts(2:2:end,2),'r+');
xlim([-11.8 11.8])
ylim([-7.9 7.9])
axis equal