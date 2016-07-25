clear
% PathName = '\\hs8.lboro.ac.uk\cvdm7\Shake table 26.4.13\A200';
PathName = 'C:\Users\cvdm7\Personal Documents - Not Backed Up\Wooden upright 26 120514\D80-2R';
FileType = 'txt';

Files = dir(PathName);
StoredFileNo = 1;


switch FileType
    case 'm'
        for file = 3:length(Files)
            if strcmpi(Files(file).name(end-3:end),'.jpg')
                FileName{StoredFileNo} = Files(file).name;
                StoredFileNo = StoredFileNo + 1;
            end
        end
        save(fullfile(PathName,'folder_ImageNames'),'FileName')
    case 'txt'
        fid = fopen(fullfile(PathName,'image_names.txt'),'wt');
        for file = 3:length(Files)
            if strcmpi(Files(file).name(end-3:end),'.jpg')
                if StoredFileNo > 1
                    fprintf(fid,'\n');
                end
                fprintf(fid,'%s',strtrim(Files(file).name));
                StoredFileNo = StoredFileNo + 1;
            end
        end
        fclose(fid);
end