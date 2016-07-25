function ComputeIntersections(filepath_phots,filepath_cam,filepath_pobs,filepath_tar,output_residuals)

Rmat_type = 'opk';  %  opk or pok
Rmat_order = 'ZYX';
Reproj_version = 'standard'; %'standard' 'new'
% output_residuals = false;
output_rots = false;

% Read phots file
fid_phots = fopen(filepath_phots,'rt');
if fid_phots == -1
    error(['Cannot open phots file: ' filepath_phots])
end
readtext = textscan(fid_phots,'%s %f %f %f %f %f %f %f%*[^\n]', ...
    'CommentStyle','#', ...
    'Delimiter', ['\t',' '], ...
    'MultipleDelimsAsOne', true);
fclose(fid_phots);

% Read in EO for LH frame
Allphots = cell(1,2);
Allphots{1}.x = readtext{2}(1);
Allphots{1}.y = readtext{3}(1);
Allphots{1}.Z = readtext{4}(1);
Allphots{1}.omega = degtorad(readtext{5}(1));
Allphots{1}.phi = degtorad(readtext{6}(1));
Allphots{1}.kappa = degtorad(readtext{7}(1));
Allphots{1}.f = -readtext{8}(1) / 1000;
Allphots{1}.name = readtext{1}{1};

% Read in EO for RH frame
Allphots{2}.x = readtext{2}(2);
Allphots{2}.y = readtext{3}(2);
Allphots{2}.Z = readtext{4}(2);
Allphots{2}.omega = degtorad(readtext{5}(2));
Allphots{2}.phi = degtorad(readtext{6}(2));
Allphots{2}.kappa = degtorad(readtext{7}(2));
Allphots{2}.f = -readtext{8}(2) / 1000;
Allphots{2}.name = readtext{1}{2};

% Form LR rot matrix
rots{1} = FormR(Allphots{1});

% Form RH rot matrix
rots{2} = FormR(Allphots{2});

% Read in Inner Orientation for BOTH cameras from cam file
fid_cam = fopen(filepath_cam,'rt');
readtext = textscan(fid_cam,'%f %f %f %f %f %f %f %f %f %f %f %s%*[^\n]', ...
    'CommentStyle','#', ...
    'delimiter', '\t', ...
    'MultipleDelimsAsOne', true);
fclose(fid_cam);

% Check for extra lines
bad_lines = isnan(readtext{1});
if sum(bad_lines)>0
    for col=1:12
        readtext{col}(bad_lines) = [];
    end
end

IOParas = cell([1 ceil(size(readtext{1},1)/2)]);
for cam_no = 1:ceil(length(readtext{1})/2)
    IOParas{cam_no}.f =  -readtext{1}(cam_no*2-1) / 1000;
    IOParas{cam_no}.Xp = -readtext{2}(cam_no*2-1) / 1000;
    IOParas{cam_no}.Yp = -readtext{3}(cam_no*2-1) / 1000;
    IOParas{cam_no}.DeltaF = readtext{4}(cam_no*2-1);
    IOParas{cam_no}.DiffScale = readtext{5}(cam_no*2-1);
    IOParas{cam_no}.Affine = readtext{6}(cam_no*2-1);
    IOParas{cam_no}.K1 = -readtext{7}(cam_no*2-1);
    IOParas{cam_no}.K2 = -readtext{8}(cam_no*2-1);
    IOParas{cam_no}.K3 = -readtext{9}(cam_no*2-1);
    IOParas{cam_no}.P1 = -readtext{10}(cam_no*2-1);
    % IOParas.P2 = readtext{11}
    IOParas{cam_no}.P2 = -0;
end

% Assign cameras to photos
for phot_no = 1:2
    cam_line = Allphots{phot_no}.f *-1000  == readtext{1};
    Allphots{phot_no}.Cam_No = (find(cam_line)+1)/2;
end

% Read in photocoords
fid_pobs = fopen(filepath_pobs,'rt');
pobs_read_text = textscan(fid_pobs,'%s %s %f %f %f %f %*[^\n]', ...
    'CommentStyle','#', ...
    'delimiter', '\t', ...
    'MultipleDelimsAsOne', true);
fclose(fid_pobs);

number_of_pobs = length(pobs_read_text{1});

PtsXYZ = cell(number_of_pobs,2);
points_with_singular_pobs = false;

for PobsRow = 1:2:number_of_pobs
    % For PobsRow = 13 To (13 + 4)
    

    switch Reproj_version
        case 'new'
            
            warning('The new version of reproj is not fully tested')
            % Count the number of pobs
            Pobs_current_row = 1;
            ObjXYZ.Id = pobs_read_text{2}(PobsRow);
            %CurrentPtId = pobs_read_text{2}{PobsRow}
            Add_point_rows = 0;
            while strcmp(pobs_read_text{2}{Pobs_current_row+Add_point_rows+1},pobs_read_text{2}{Pobs_current_row})
                Add_point_rows = Add_point_rows + 1;
            end
            
            % check if there's only one pob
            if Add_point_rows == 0
                % Cannot continue with only one pob
                points_with_singular_pobs = true;
                [ObjXYZ.x, ObjXYZ.y, ObjXYZ.z] = deal(NaN);
                continue
            end
            
            
            SelectedPobs = {};
            SelectedPhots = {};
            SelectedRots = {};
            number_of_phots = length(Allphots);
            
            % Collect Pobs Phots and Rots
            for pob_no = 1:( 1 + Add_point_rows )
                SelectedPobs{end+1}.x = pobs_read_text{3}(pob_no) /1000;
                SelectedPobs{end}.y = pobs_read_text{4}(pob_no) /1000;
                
                for phot_no = 1:number_of_phots
                    if strcmp(Allphots{phot_no}.name,pobs_read_text{1}{pob_no})
                        SelectedPhots{end+1} = Allphots{phot_no};
                        SelectedRots{end+1} = rots{phot_no};
                        continue
                    end
                end
                % Correct for Lens distortion
                SelectedPobs{end} = LensCorrection2(SelectedPobs{end}, IOParas{SelectedPhots{end}.Cam_No});
            end
            
            % Compute XYZ coords of point
            [ObjXYZ] = Reproj3(SelectedPobs, SelectedPhots, SelectedRots, ObjXYZ);
            PtsXYZ{PobsRow,1} = ObjXYZ.Id;
            PtsXYZ{PobsRow,2} = [ObjXYZ.x ObjXYZ.y ObjXYZ.z];
            
            % TODO: Evaluate residuals
                PtsXYZ{PobsRow,3} = [0 0];
    PtsXYZ{PobsRow,4} = [0 0];
            
            
        case 'standard'
            
            if ~strcmp(pobs_read_text{2}(PobsRow) , pobs_read_text{2}(PobsRow+1))
                disp(['pobs file line ' num2str(PobsRow) ': PtID ' pobs_read_text{2}{PobsRow} ' is not followed by same PtID'])
                continue
            end
            
            if ~strcmp(pobs_read_text{1}(PobsRow) , Allphots{1}.name)
                disp(['photo name mismatch between pobs file line ' num2str(PobsRow) ' Phot: ' pobs_read_text{1}{PobsRow} '. Was expecting ' Allphots{1}.name])
                continue
            elseif ~strcmp(pobs_read_text{1}(PobsRow+1) , Allphots{2}.name)
                disp(['Photo name mismatch between pobs file line ' num2str(PobsRow+1) ' Phot: ' pobs_read_text{1}{PobsRow+1} '. Was expecting ' Allphots{2}.name])
                continue
            end
            
            ObjXYZ.Id = pobs_read_text{2}(PobsRow);
            PobsMeasL.x = pobs_read_text{3}(PobsRow) / 1000;  % convert to m
            PobsMeasL.y = pobs_read_text{4}(PobsRow) / 1000;
            PobsMeasR.x = pobs_read_text{3}(PobsRow+1) / 1000;
            PobsMeasR.y = pobs_read_text{4}(PobsRow+1) / 1000;
            
            % Correct for Lens distortion!
            PobsMeasL = LensCorrection2(PobsMeasL, IOParas{Allphots{1}.Cam_No});
            PobsMeasR = LensCorrection2(PobsMeasR, IOParas{Allphots{2}.Cam_No});
            
            % Compute XYZ coords of point
            ObjXYZ = Reproj(PobsMeasL, PobsMeasR, Allphots{1}, Allphots{2}, rots{1}, rots{2}, ObjXYZ);
            PtsXYZ{PobsRow,1} = ObjXYZ.Id;
            PtsXYZ{PobsRow,2} = [ObjXYZ.x ObjXYZ.y ObjXYZ.z];
            
            % Reproject back into image & compute photo-residuals
            [PobsCompL, PobsCompR] = Proj(Allphots{1}, Allphots{2}, rots{1}, rots{2}, ObjXYZ) ;
            
            % Evaluate residuals, convert to microns & return!
            PtsXYZ{PobsRow,3} = [ (PobsMeasL.x - PobsCompL.x) * 1000000, ...
                (PobsMeasL.y - PobsCompL.y) * 1000000 ];
            PtsXYZ{PobsRow,4} = [ (PobsMeasR.x - PobsCompR.x) * 1000000, ...
                (PobsMeasR.y - PobsCompR.y) * 1000000 ];
    end
    
end

% Write data to output file
fid_tar = fopen(filepath_tar,'wt');
default_weight = '0';
fprintf(fid_tar,'#  Computed target data file \n');
fprintf(fid_tar,'#\n');
fprintf(fid_tar,'#  Results from ComputeIntersections program run %s\n',datestr(now));
fprintf(fid_tar,'#\n');
fprintf(fid_tar,'#  Input files:\n');
fprintf(fid_tar,'#  Photo data       :  %s\n',filepath_phots);
fprintf(fid_tar,'#  Photo obs. data  :  %s\n',filepath_pobs);
fprintf(fid_tar,'#  Camera data      :  %s\n',filepath_cam);
fprintf(fid_tar,'#\n');
fprintf(fid_tar,'#  Output file:\n');
fprintf(fid_tar,'#  Target data      :  %s\n',filepath_tar);
if output_rots
    fprintf(fid_tar,'#\n');
    fprintf(fid_tar,'#  Rotation matrix  :  %s\n',Rmat_type);
    if strcmp(Rmat_type,'cosines'); fprintf(fid_tar,'#  Rotation order   :  %s\n',Rmat_order); end;
    fprintf(fid_tar,'#\n');
    fprintf(fid_tar,'#  Rotation matrix L:\n');
    fprintf(fid_tar,'#    % 1.5f   % 1.5f   % 1.5f\n', rots{1}(1,:));
    fprintf(fid_tar,'#    % 1.5f   % 1.5f   % 1.5f\n', rots{1}(2,:));
    fprintf(fid_tar,'#    % 1.5f   % 1.5f   % 1.5f\n', rots{1}(3,:));
    fprintf(fid_tar,'#\n');
    fprintf(fid_tar,'#  Rotation matrix R:\n');
    fprintf(fid_tar,'#    % 1.5f   % 1.5f   % 1.5f\n', rots{2}(1,:));
    fprintf(fid_tar,'#    % 1.5f   % 1.5f   % 1.5f\n', rots{2}(2,:));
    fprintf(fid_tar,'#    % 1.5f   % 1.5f   % 1.5f\n', rots{2}(3,:));
end
if points_with_singular_pobs
    fprintf(fid_tar,'#\n#  WARNING: Some points were only found in one photo. They have a NaN output.\n');
    fprintf(fid_tar,'#  This warning can occur if point observations are not consecutive in the pobs file. \n');
end
fprintf(fid_tar,'#\n');
fprintf(fid_tar,'#\n');
fprintf(fid_tar,'# Pt ID\tX\tY\tZ\tweight X\tweight Y\tweight Z\n');
fprintf(fid_tar,'#\n');
for PobsRow = 1:number_of_pobs
    if isempty(PtsXYZ{PobsRow,1})
        continue, end
    fprintf(fid_tar,'%s\t%1.6f\t%1.6f\t%1.6f\t%s\t%s\t%s\n', ...
        PtsXYZ{PobsRow,1}{1}, ...
        PtsXYZ{PobsRow,2}(1), ...
        PtsXYZ{PobsRow,2}(2), ...
        PtsXYZ{PobsRow,2}(3), ...
        default_weight, ...
        default_weight, ...
        default_weight);
    if output_residuals
        fprintf(fid_tar,'#resid''s. xl: %1.1f yl: %1.1f xr: %1.1f yr: %1.1f\n# \n', ...
            PtsXYZ{PobsRow,3}(1), ...
            PtsXYZ{PobsRow,3}(2), ...
            PtsXYZ{PobsRow,4}(1), ...
            PtsXYZ{PobsRow,4}(2));
    end
end
fclose(fid_tar);