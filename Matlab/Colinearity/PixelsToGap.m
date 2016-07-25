function PixelsToGap(filein,fileout)

% filein = '\\hs8.lboro.ac.uk\cvdm7\MATLAB\DeblurTo3D\pobsP.txt';
% fileout = '\\hs8.lboro.ac.uk\cvdm7\MATLAB\DeblurTo3D\pobs.txt';
filetype = 'pobs';

disp('WARNING: Check if the correct image/format dimensions are being used!')

% formats{1} = [23.9953 16.0661]
% formats{2} = [23.6 15.8]

imagewidth = 3872;
imageheight = 2592;
% formatwidth = 23.9953; %23.6
% formatheight = 16.0661; %15.8

% Open input file + scan all lines
in_data_fid = fopen(filein,'rt');
preamble = textscan(in_data_fid,'%s', ...
    'delimiter','\n');
fclose(in_data_fid);

% Print initiall commented lines
out_data_fid = fopen(fileout,'wt');
for line = 1:length(preamble{1})
    if strcmp(preamble{1}{line}(1),'#')
        fprintf(out_data_fid,'%s\n',preamble{1}{line});
    else
        break
    end
end
fprintf(out_data_fid,'#  Data converted from pixels to gap format using PixelsToGap run %s\n',datestr(now));
fprintf(out_data_fid,'#\n');

% Reopen input file + can without comment lines
in_data_fid = fopen(filein,'rt');
in_data_read = textscan(in_data_fid,'%s %s %f %f %f %f %*[^\n]', ...
    'Delimiter','\t', ...
    'CommentStyle','#');
fclose(in_data_fid);

number_of_obs = length(in_data_read{1});
switch filetype
    case 'pobs'
        for line = 1:number_of_obs
            if strcmp(in_data_read{1}{line},'2')
                formatwidth = 23.996733; %23.6
                formatheight = 16.066116; %15.8
            else
                formatwidth = 23.996733; %23.6
                formatheight = 16.066116; %15.8
            end
            fprintf(out_data_fid,'%s\t%s\t% 1.4f\t% 1.4f\t%1.1f\t%1.1f\n', ...
                in_data_read{1}{line}, ...
                in_data_read{2}{line}, ...
                (in_data_read{3}(line) - imagewidth/2) *formatwidth/imagewidth, ...
                (-in_data_read{4}(line) + imageheight/2) *formatheight/imageheight, ...
                in_data_read{5}(line) *formatwidth/imagewidth *10E3, ...
                in_data_read{6}(line) *formatheight/imageheight *10E3);
        end
end
fclose(out_data_fid);

