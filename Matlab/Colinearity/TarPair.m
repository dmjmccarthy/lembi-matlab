% TarPair - D McCarthy October 2013
% Selects the desired combination of target pairings
%
% Usage:
% [pairings] = TarPair(filein,fileout,pairing_method,[set_pairs])
%
% filein, fileout:   Filenames of gap format text files
% pairing_method:   ['resids', 'smallest', 'largest', 'set']
%
% filein must be the output from ComputeIntersection, complete with resids.
%
% If pairing method is 'set', include the set_pairs variable stimulating
% pairs to select 'AABBABAB'. 'X' can be used to set a pair to NaN

function [varargout] = TarPair(filein,fileout,varargin)

if nargin==2
    method = 'resids';
else
    if sum(strcmp(varargin{1},{'resids', 'smallest', 'set', 'largest'})) == 0
        error('Unrecognised pairing type')
    end
    method = varargin{1};
end
output_residuals = false;

% filein = '\\hs8.lboro.ac.uk\cvdm7\MATLAB\DeblurTo3D\tarFromIntersections.txt';
% fileout = '\\hs8.lboro.ac.uk\cvdm7\MATLAB\DeblurTo3D\tarPaired.txt';



% Read in computed target file
fid_TarIntersection = fopen(filein,'rt');
tar_read_text = textscan(fid_TarIntersection,'%s', ...
    'delimiter', '\n');
fclose(fid_TarIntersection);

no_of_lines = length(tar_read_text{1});
% start_line = 7;


fileout_fid = fopen(fileout,'wt');
% fprintf introductory jargon
for line = 1:no_of_lines
    if ~strcmp(tar_read_text{1}{line}(1), '#')
        start_line = line;
        break
    end
    fprintf(fileout_fid,'%s\n',tar_read_text{1}{line} );
end
fprintf(fileout_fid,'#  Most likely pairs identified and selected by TarPair program run %s\n',datestr(now));
fprintf(fileout_fid,'#  Pairing method: %s\n# \n',method);


number_of_points = (no_of_lines-start_line+1)/12;

% Make the selections
if strcmp(method,'set')
    selected_combinations = varargin{2};
else
    for point_ind = 0:number_of_points-1
        switch method
            case 'resids'
                tar_read_text{1}{start_line+point_ind*12};   % A1
                A_resids1 = cell2mat(textscan(tar_read_text{1}{start_line+point_ind*12+1}, '#resid''s. xl: %f yl: %f xr: %f yr: %f', 'Delimiter', ' ')); % R
                tar_read_text{1}{start_line+point_ind*12+3}; % A2
                A_resids2 = cell2mat(textscan(tar_read_text{1}{start_line+point_ind*12+4}, '#resid''s. xl: %f yl: %f xr: %f yr: %f', 'Delimiter', ' ')); % R
                
                tar_read_text{1}{start_line+point_ind*12+6}; % B1
                B_resids1 = cell2mat(textscan(tar_read_text{1}{start_line+point_ind*12+7}, '#resid''s. xl: %f yl: %f xr: %f yr: %f', 'Delimiter', ' ')); % R
                tar_read_text{1}{start_line+point_ind*12+9}; % B2
                B_resids2 = cell2mat(textscan(tar_read_text{1}{start_line+point_ind*12+10}, '#resid''s. xl: %f yl: %f xr: %f yr: %f', 'Delimiter', ' ')); % R
                
                A_combination = sqrt(sum([ sqrt( sum(hypot(A_resids1([1 3]),A_resids1([2 4])).^2)  ), ...
                    sqrt( sum(hypot(A_resids2([1 3]),A_resids2([2 4])).^2)  )     ].^2));
                
                B_combination = sqrt(sum([ sqrt( sum(hypot(B_resids1([1 3]),B_resids1([2 4])).^2)  ), ...
                    sqrt( sum(hypot(B_resids2([1 3]),B_resids2([2 4])).^2)  )     ].^2));
                
                if A_combination <= B_combination
                    selected_combinations(point_ind+1) = 'A';
                else
                    selected_combinations(point_ind+1) = 'B';
                end
                
            case {'smallest','largest'}
                
                A1_line = tar_read_text{1}{start_line+point_ind*12};   % A1
                A2_line = tar_read_text{1}{start_line+point_ind*12+3}; % A2
                B1_line = tar_read_text{1}{start_line+point_ind*12+6}; % B1
                B2_line = tar_read_text{1}{start_line+point_ind*12+9}; % B2
                
                A1_coords = cell2mat(textscan(A1_line,'%*s %f %f %f %*f %*f %*f','Delimiter', '\t'));
                A2_coords = cell2mat(textscan(A2_line,'%*s %f %f %f %*f %*f %*f','Delimiter', '\t'));
                B1_coords = cell2mat(textscan(B1_line,'%*s %f %f %f %*f %*f %*f','Delimiter', '\t'));
                B2_coords = cell2mat(textscan(B2_line,'%*s %f %f %f %*f %*f %*f','Delimiter', '\t'));
                
                A_diff = A2_coords-A1_coords;
                B_diff = B2_coords-B1_coords;
                
                A_dist = sqrt(sum(A_diff.^2));
                B_dist = sqrt(sum(B_diff.^2));
                
                switch method
                    case 'smallest'
                        if A_dist < B_dist
                            selected_combinations(point_ind+1) = 'A';
                        else
                            selected_combinations(point_ind+1) = 'B';
                        end
                    case 'largest'
                        if A_dist < B_dist
                            selected_combinations(point_ind+1) = 'B';
                        else
                            selected_combinations(point_ind+1) = 'A';
                        end
                end
        end
    end
end

% Re-write tar file using selections
for point_ind = 1:number_of_points
    
    switch selected_combinations(point_ind)
        case 'A'
            %tar_read_text(start_line + (point_ind-1)*8);
            fprintf(fileout_fid,'%s\n', remove_option_from_string(tar_read_text{1}{start_line + (point_ind-1)*12+0}));   % 1 Coord
            if output_residuals, fprintf(fileout_fid,'%s\n# \n', tar_read_text{1}{start_line + (point_ind-1)*12+1}); end;  % 1 Resid
            fprintf(fileout_fid,'%s\n', remove_option_from_string(tar_read_text{1}{start_line + (point_ind-1)*12+3}));   % 2 Coord
            if output_residuals, fprintf(fileout_fid,'%s\n# \n', tar_read_text{1}{start_line + (point_ind-1)*12+4}); end;   % 2 Resid
        case 'B'
            fprintf(fileout_fid,'%s\n', remove_option_from_string(tar_read_text{1}{start_line + (point_ind-1)*12+6}));   % 1 Coord
            if output_residuals, fprintf(fileout_fid,'%s\n# \n', tar_read_text{1}{start_line + (point_ind-1)*12+7}); end;   % 1 Resid
            fprintf(fileout_fid,'%s\n', remove_option_from_string(tar_read_text{1}{start_line + (point_ind-1)*12+9}));   % 2 Coord
            if output_residuals, fprintf(fileout_fid,'%s\n# \n', tar_read_text{1}{start_line + (point_ind-1)*12+10}); end;   % 2 Resid
    end
end
fprintf(fileout_fid,'#\n#  Pairings were:\n#  %s',selected_combinations);
fclose(fileout_fid);
varargout{1} = selected_combinations;

%
%
%
% for line = 1:no_of_lines
%     current_line = tar_read_text{1}{line};
%
%     if current_line(1) == '#'
%         if length(current_line)==1
%             % it's just an empty comment line
%             continue
%         elseif current_line(2) == 'r'
%             % is a resids
%             resids_line = textscan(current_line,'%s %s %f %s %f %s %f %s %f', ...
%                 'Delimiter', ' ');
%
%             if isempty(stored_lines{1,5})
%             elseif isempty(stored_lines{1,6})
%             elseif isempty(stored_lines{1,7})
%             elseif isempty(stored_lines{1,8})
%             end
%
%             %TODO: Save the resids
%
%             if isempty(stored_lines{1,5})
%                 stored_lines{1,5}
%             elseif isempty(stored_lines{1,6})
%                 stored_lines{1,6}
%             elseif isempty(stored_lines{1,7})
%                 stored_lines{1,7}
%             elseif isempty(stored_lines{1,8})
%                 stored_lines{1,8}
%             end
%
%         end
%
%
%
%     else % it's a normal data row
%
%         data_line = textscan(current_line,'%s %f %f %f %f %f %f', ...
%             'Delimiter', '\t');
%
%         %TODO: Save the data
%         switch data_line{1}{:}(end-1:end)
%             case 'A1'
%                 stored_lines{1,1} = data_line;
%             case 'A2'
%                 stored_lines{1,2} = data_line;
%             case 'B1'
%                 stored_lines{1,3} = data_line;
%             case 'B2'
%                 stored_lines{1,4} = data_line;
%                 last_pending_line_read = true;
%         end
%
%     end
% end
