function RemoveWrongPairsInPobs(pobsfile_in,pobsfile_out,pairings)
% pobsfile_in = '\\hs8.lboro.ac.uk\cvdm7\MATLAB\DeblurTo3D\pobs.txt';
% pairings = 'BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB';
% pobsfile_out = '\\hs8.lboro.ac.uk\cvdm7\MATLAB\DeblurTo3D\pobsG.txt';

pobs_fid = fopen(pobsfile_in,'rt');
pobs_file_read = textscan(pobs_fid,'%s','Delimiter','\n');
fclose(pobs_fid);

new_fid = fopen(pobsfile_out,'wt');

TagAdded = false;
for line_no = 1:length(pobs_file_read{1})
    
    current_line = pobs_file_read{1}{line_no};
    
    if strcmp(current_line(1) , '#' )  % Comment line
        fprintf(new_fid,'%s\n',pobs_file_read{1}{line_no});
        continue
    end
    
    if ~TagAdded
        fprintf(new_fid,'#  Incorrect pairings were removed by RemoveWrongPairsInPobs run %s \n#  \n',datestr(now));
        TagAdded = true;
    end
    
    pobs_id = textscan(current_line,'%*s %s [*\n]','Delimiter','\t');
    target_id = textscan(pobs_id{1}{1},'%s[*\n]','Delimiter','_');
    pair_id = textscan(pobs_id{1}{1},'%*s %c','Delimiter','_');
    
    correct_pairing = pairings(str2double(target_id{1}{1}));
    
    if strcmp(pair_id(1),correct_pairing)
        current_line_data = textscan(current_line,'%s%s%s%s%s%s','Delimiter','\t');
        
        fprintf(new_fid,'%s\t%s\t%s\t%s\t%s\t%s\n', ...
            current_line_data{1}{1}, ...
            [target_id{1}{1} '_' pobs_id{1}{1}(end)], ...
            current_line_data{3}{1}, ...
            current_line_data{4}{1}, ...
            current_line_data{5}{1}, ...
            current_line_data{6}{1});
    end
    
    
end
fclose(new_fid);