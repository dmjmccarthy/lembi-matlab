% Show points on images
function ShowPointsOnImage(filepath)

image_filepath = filepath;
coords_filepath = [filepath '_points.csv'];

data_fid = fopen(coords_filepath,'rt');
data_read = textscan(data_fid,'%*s %*s %f %f %f %f %*[^\n]', ...
    'Delimiter',',', ...
    'HeaderLines',3);
fclose(data_fid);

pts = cell2mat(data_read);

figure,
imshow(imread(image_filepath))
hold on
plot(pts(:,1),pts(:,2),'b+');
plot(pts(:,3),pts(:,4),'b+');