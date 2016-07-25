%
%
% Usage: scanlines_estimate(I,image_profiles_parameters,estimated_target_centre,~,Isharp,[Isharp_estimated_centre])
%
% Where     I:                        The grayscale image
%           image_profile_parameters  Is a structure array
%           estimated_target_centre:  After thresolding the image, the blob
%                                     at this position will be examined.
%           Isharp:                   Used to test blur type (Int/Ext)
%           Isharp_estimated_centre:
%
% Outputs:
%    1: [xc1 yc1 xc2 yc2]
%    2: Weighted centroid
%    3: [xc1 yc1 R1 ; xc2 yc2 R2 ] (scanline_circle_data)
%    4: profiles_data structure array

function [varargout] = scanlines_estimate(I,image_profiles_parameters,estimated_target_centre,~, varargin)

SCANMODE = 'auto';                    % OPTIONS: 'auto' 'manual'
auto_accept_auto_threshold_increases = true;

% Unpack variables
NumberOfScanLines = image_profiles_parameters.NumberOfScanLines;
MinorAxisExpand = image_profiles_parameters.MinorAxisExpand;
MajorAxisExpand = image_profiles_parameters.MajorAxisExpand;
threshold_adjust = image_profiles_parameters.threshold_adjust;
sensitivity = image_profiles_parameters.sensitivity;
profile_length = image_profiles_parameters.profile_length;
POINT_MARKING_METHOD = image_profiles_parameters.POINT_MARKING_METHOD;     % OPTIONS: 'threshold' 'max difference' 'profile_ransac'
suppress_output = image_profiles_parameters.suppress_output;
if strcmp(SCANMODE,'manual'); suppress_output = false; end;

if image_profiles_parameters.include_blur_type_test && nargin < 6
    error('scanlines_estimate was requested a blur type test but did not recieve the Isharp image')
elseif image_profiles_parameters.include_blur_type_test
    Isharp = varargin{1};
    Isharp_estimated_centre = varargin{2};
end

if isfield(image_profiles_parameters,'low_threshold')
    low_threshold = image_profiles_parameters.low_threshold;
    high_threshold = image_profiles_parameters.high_threshold;
end

% check we've got the centre of the target
[estimated_target_centre] = search_for_target_in_image(I,estimated_target_centre);
% THIS COULD BE MOVED TO PARENT FUNCTION


%% Set up the scan lines
switch SCANMODE
    case 'auto'
        accept_auto_profile_lines = false;
        while ~accept_auto_profile_lines
            % This makes some estimates about the shape of the blur using
            % simple thresholding
            threshold = graythresh(I) + threshold_adjust;
            bw = im2bw(I,threshold);
            blobs = bwconncomp(bw, 4);
            blobs_labelled =  labelmatrix(blobs);
            
            estimated_target_centre = round(estimated_target_centre);
            
            selected_blob_no = blobs_labelled(estimated_target_centre(1),estimated_target_centre(2));
            blob_prop = regionprops(struct('Connectivity',4,'ImageSize',blobs.ImageSize, ...
                'NumObjects',1, ...
                'PixelIdxList', {{ blobs.PixelIdxList{selected_blob_no} }} ) ...
                , I ...
                , 'Centroid','Orientation','MajorAxisLength','MinorAxisLength','WeightedCentroid','PixelList');
            
            % Does the blur orientation need correcting?
            if image_profiles_parameters.force_blur_direction
                switch image_profiles_parameters.assumed_blur_direction
                    case 'horiz'
                        blob_prop.Orientation = 0;
                    case 'vert'
                        blob_prop.Orientation = 90;
                end
            elseif blob_prop.MajorAxisLength/blob_prop.MinorAxisLength <= 1.1
                % If the blur is almost a circle, sometimes the estimated
                % orientation is the opposite to what it really is, so we fix it
                % horizontal  !!!!!!!!
                disp('This is quite a circular blob. Im going to assume the blur direction to be ')
                switch image_profiles_parameters.assumed_blur_direction
                    case 'horiz'
                        fprintf('\bHORIZONTAL.\n');
                        blob_prop.Orientation = 0;
                    case 'vert'
                        fprintf('\bVERTICAL.\n');
                        blob_prop.Orientation = 90;
                end
            end
            
            % Set up two basic vectors that are used to select coordinates in
            % the image
            BasicMajorVector = [ cos(blob_prop.Orientation*pi()/180) -sin(blob_prop.Orientation*pi()/180) ] .* blob_prop.MajorAxisLength/2;
            BasicMinorVector = [ -sin(blob_prop.Orientation*pi()/180) -cos(blob_prop.Orientation*pi()/180) ] .* blob_prop.MinorAxisLength/2;
            % Create X,Y pairs for the scan lines, saved in ScanLines array.
            profile_coordinates = zeros(NumberOfScanLines,4);
            for profile_number = 0:NumberOfScanLines-1
                profile_coordinates(profile_number+1,[1 2]) = ...
                    blob_prop.Centroid + BasicMinorVector*(2*profile_number/(NumberOfScanLines-1)-1)*MinorAxisExpand ...
                    - BasicMajorVector*MajorAxisExpand ;
                profile_coordinates(profile_number+1,[3 4]) = ...
                    blob_prop.Centroid + BasicMinorVector*(2*profile_number/(NumberOfScanLines-1)-1)*MinorAxisExpand ...
                    + BasicMajorVector*MajorAxisExpand ;
            end
            
            % Check if image profiles exceed image dimensions
            if ...
                    sum(sum(profile_coordinates(:,[1 3]) > size(I,2))) + ...
                    sum(sum(profile_coordinates(:,[1 3]) < 0)) + ...
                    sum(sum(profile_coordinates(:,[2 4]) > size(I,1))) + ...
                    sum(sum(profile_coordinates(:,[2 4]) < 0)) ...
                    ~= 0
                warning('scanlines_estimate: Profile lines coordinates exceed the dimensions of the image')
                if threshold >= 0.95 % Can't reduce threshold further
                    figure;
                    title('Profile lines exceed image dimensions')
                    subplot(1,2,1)
                    imshow(I);
                    subplot(1,2,2)
                    imshow(I);
                    hold on;
                    plot(blob_prop.PixelList(:,1),blob_prop.PixelList(:,2),'r.')
                    drawnow
                    error('scanlines_estimate: Profile lines coordinates exceed the dimensions of the image, and threshold couldn''t be increased further')
                else % Reduce threshold a little more
                    threshold_adjust = threshold_adjust + 0.05;
                    if ~auto_accept_auto_threshold_increases
                        waitfor(msgbox(['threshold is being adjusted to ' num2str(threshold+0.05)]))
                    end
                end
            else
                accept_auto_profile_lines = true;
            end
        end
        
    case 'manual'
        % If we're testing in manual mode, just get a pair of coordinates
        % from the user for a single scan line.
        figure
        imshow(I)
        title('scanlines_estimate: Manual mode. Select two points to take improfile between')
        [inputX,inputY] = ginput(2);
        profile_coordinates = [inputX(1) inputY(1) inputX(2) inputY(2)];
        close
        NumberOfScanLines = 1;
end

%% Check if image profiles exceed image dimensions
if ...
        sum(sum(profile_coordinates(:,[1 3]) > size(I,2))) + ...
        sum(sum(profile_coordinates(:,[1 3]) < 0)) + ...
        sum(sum(profile_coordinates(:,[2 4]) > size(I,1))) + ...
        sum(sum(profile_coordinates(:,[2 4]) < 0)) ...
        ~= 0
    warning('scanlines_estimate: Profile lines coordinates exceed the dimensions of the image')
    figure;
    title('Profile lines exceed image dimensions')
    subplot(1,2,1)
    imshow(I);
    subplot(1,2,2)
    imshow(I);
    hold on;
    plot(blob_prop.PixelList(:,1),blob_prop.PixelList(:,2),'r.')
    drawnow
end


%% Plot the scan lines
if suppress_output == false
    % Original image
    figure
    subplot(2,2,1), imshow(I)
    
    % Image superimposed with profiles
    subplot(2,2,2)
    subimage(255-I)
    colormap('jet')
    axis off
    hold on
    if strcmp(SCANMODE,'auto')
        % Plot the major and minor axis
        plot([blob_prop.Centroid(1)-BasicMajorVector(1) blob_prop.Centroid(1)+BasicMajorVector(1)], ...
            [blob_prop.Centroid(2)-BasicMajorVector(2) blob_prop.Centroid(2)+BasicMajorVector(2)],'r-')
        plot([blob_prop.Centroid(1)-BasicMinorVector(1) blob_prop.Centroid(1)+BasicMinorVector(1)], ...
            [blob_prop.Centroid(2)-BasicMinorVector(2) blob_prop.Centroid(2)+BasicMinorVector(2)],'b-')
    end
    % Plot profile lines
    for l=1:size(profile_coordinates,1)
        plot([profile_coordinates(l,1); profile_coordinates(l,3)] ,[profile_coordinates(l,2); profile_coordinates(l,4)],'-','color',[0 0.5 0]);
    end
end

%% Test for external blur
if strcmp(SCANMODE,'manual')
    image_profiles_parameters.include_blur_type_test = false;
end
if image_profiles_parameters.include_blur_type_test == true
    not_user_selected_centre = [blob_prop.Centroid(2), blob_prop.Centroid(1)];
    BlurType = thresholding_area_test(I,Isharp,not_user_selected_centre,Isharp_estimated_centre);
else
    BlurType = 'not_requested';
end


%% Get image profiles
[edge1, edge2, edge3, edge4] = deal(nan(NumberOfScanLines,2));

for profile_number=1:NumberOfScanLines % FOR EACH SCAN LINE
    
    inputX = profile_coordinates(profile_number,[1 3]);   % Get the coordinates of this scan line
    inputY = profile_coordinates(profile_number,[2 4]);
    
    % Get the profile line
    image_profile_values = improfile(I,inputX,inputY,profile_length,'bilinear');
    
    % Basic filter
    image_profile_values = smooth(image_profile_values);
    
    switch POINT_MARKING_METHOD
        case 'threshold'
            % IDENTIFY POINTS USING THRESHOLD
            [~, mid_point] = max(image_profile_values);
            pixel_range = max(image_profile_values) - min(image_profile_values);
            
            left_crosssection = image_profile_values(1:mid_point);
            right_crosssection = image_profile_values(mid_point+1:end);
            low_left_points  = left_crosssection <= min(left_crosssection)+pixel_range*sensitivity;
            low_right_points  = right_crosssection <= min(right_crosssection)+pixel_range*sensitivity;
            
            high_points = image_profile_values >= max(image_profile_values)-pixel_range*sensitivity;
            
            point2 = find(high_points,1,'first');
            point3 = find(high_points,1,'last');
            
            point1 = find(low_left_points,1,'last');
            point4 = find(low_right_points,1,'first') + mid_point;
            
        case 'thresholds set'
            % IDENTIFY POINTS USING THRESHOLD
            [~, mid_point] = max(image_profile_values);
            pixel_range = max(image_profile_values) - min(image_profile_values);
            
            if ~exist('low_threshold','var');
                low_threshold = min(image_profile_values)+pixel_range*sensitivity;
                high_threshold = max(image_profile_values)-pixel_range*sensitivity;
            end
            
            left_crosssection = image_profile_values(1:mid_point);
            right_crosssection = image_profile_values(mid_point+1:end);
            low_left_points  = left_crosssection <= low_threshold;
            low_right_points  = right_crosssection <= low_threshold;
            
            high_points = image_profile_values >= high_threshold;
            
            point2 = find(high_points,1,'first');
            point3 = find(high_points,1,'last');
            
            point1 = find(low_left_points,1,'last');
            point4 = find(low_right_points,1,'first') + mid_point;
            
        case 'threshold findpeaks'
            % IDENTIFY POINTS USING THRESHOLD
            [~, mid_point] = max(image_profile_values);
            pixel_range = max(image_profile_values) - min(image_profile_values);
            
            left_crosssection = image_profile_values(1:mid_point);
            right_crosssection = image_profile_values(mid_point+1:end);
            low_left_points  = left_crosssection <= min(left_crosssection)+pixel_range*sensitivity;
            low_right_points  = right_crosssection <= min(right_crosssection)+pixel_range*sensitivity;
            
            point1 = find(low_left_points,1,'last');
            point4 = find(low_right_points,1,'first') + mid_point;
            
            % findpeaks for high points
            mid_threshold = min(image_profile_values) + round(pixel_range/2);
            high_points = image_profile_values >= mid_threshold;
            high_points_left = find(high_points,true,'first');
            high_points_right = find(high_points,true,'last');
            mid_values = image_profile_values(high_points_left:high_points_right);
            [~, peak_locs] = findpeaks(mid_values,'NPEAKS',2,'SORTSTR','descend');
            if size(peak_locs,1) == 2
                if peak_locs(1) > peak_locs(2)
                    peak_locs = [peak_locs(2) peak_locs(1)];
                end
                point2 = peak_locs(2) + high_points_left-1;
                point3 = peak_locs(1) + high_points_left-1;
            else
                %threshold for high points
                high_points = image_profile_values >= max(image_profile_values)-pixel_range*sensitivity;
                point2 = find(high_points,1,'first');
                point3 = find(high_points,1,'last');
            end
            
            0;
            
        case 'max difference'
            % IDENTIFY POINTS USING DIFFERENTIATED PROFILE
            differentsection = zeros(profile_length,1);
            for step = 2:profile_length
                differentsection(step,1) = image_profile_values(step) - image_profile_values(step-1);
            end
            
            % Rudimentary filter
            differentsection = differentsection.*abs(differentsection)/max(abs(differentsection));
            
            maxdifferent = max(abs(differentsection)); mindifferent = -maxdifferent;
            
            positivegradientind = find(differentsection > maxdifferent*sensitivity);
            negativegradientind = find(differentsection < mindifferent*sensitivity);
            
            point1 = positivegradientind(1);
            point2 = positivegradientind(end);
            point3 = negativegradientind(1);
            point4 = negativegradientind(end);
            if sum(isnan([point1 point2 point3 point4])) > 0
                warndlg 'Some points have not been located. Try raising threshold'
            end
            
        case 'profile_ransac'
            % IDENTIFY POINTS USING RANSAC
            gravity_weighted_centre = sum((image_profile_values*1:size(image_profile_values)))/size(image_profile_values,1);
            left_crosssection = image_profile_values(1:round(gravity_weighted_centre));
            pts = [ [1:size(left_crosssection)] ; left_crosssection' ; zeros(size(left_crosssection))'];
            % RANSAC
            [V, L, inliers] = ransacfitline(pts, thDist)
            
            
            iterNum = 150;
            thDist = 2;
            thInlrRatio = .1;
            [t,r] = ransac(pts,iterNum,thDist,thInlrRatio);
            k1 = -tan(t);
            b1 = r/cos(t);
            figure
            plot(X,k1*X+b1,'r')
            
        case 'type2'
            [~] = type2_detection(image_profile_values);
            
        case 'type3'
            [~] = type3_detection(image_profile_values);
            
        case 'type4'
            [point1, point2, point3, point4] = type4_detection(image_profile_values,sensitivity);
    end
    
    
    
    if ~size(point1,1) || ~size(point2,1) || ~size(point3,1) || ~size(point4,1)
        figure
        imshow(I)
        hold on
        plot(estimated_target_centre(2),estimated_target_centre(1),'r+')
        0;
        error('Some points are missing')
    end
    
    % Calculate coordinates and save edge points into an array
    % Point 1
    edgeX = inputX(1) + (inputX(2)-inputX(1))/(profile_length-1)*(point1-1);
    edgeY = inputY(1) + (inputY(2)-inputY(1))/(profile_length-1)*(point1-1);
    edge1(profile_number,[1 2]) = [edgeX edgeY ];
    
    % Point 2
    edgeX = inputX(1) + (inputX(2)-inputX(1))/(profile_length-1)*(point2-1);
    edgeY = inputY(1) + (inputY(2)-inputY(1))/(profile_length-1)*(point2-1);
    edge2(profile_number,[1 2]) = [edgeX edgeY];
    
    % Point 3
    edgeX = inputX(1) + (inputX(2)-inputX(1))/(profile_length-1)*(point3-1);
    edgeY = inputY(1) + (inputY(2)-inputY(1))/(profile_length-1)*(point3-1);
    edge3(profile_number,[1 2]) = [edgeX edgeY];
    
    % Point 4
    edgeX = inputX(1) + (inputX(2)-inputX(1))/(profile_length-1)*(point4-1);
    edgeY = inputY(1) + (inputY(2)-inputY(1))/(profile_length-1)*(point4-1);
    edge4(profile_number,[1 2]) = [edgeX edgeY];
    
    % Halfway though, plot a profile
    if (profile_number == round(NumberOfScanLines/2))
        if suppress_output == false
            subplot(2,2,4);
            plot(image_profile_values,'-k'); hold on
            plot([point1 point3],image_profile_values(round([point1 point3])),'ob');
            plot([point2 point4],image_profile_values(round([point2 point4])),'or');
        end
    end
    
    %     % Halfway through, decide if we've got INTERNAL or EXTERNAL blur
    %     if (profile_number == round(NumberOfScanLines/2))
    %         if suppress_output == false
    %             subplot(2,2,4);
    %             plot(image_profile_values,'-k'); hold on
    %             plot([point1 point3],image_profile_values([point1 point3]),'ob');
    %             plot([point2 point4],image_profile_values([point2 point4]),'or');
    %         end
    %         switch POINT_MARKING_METHOD
    %             case {'max difference','threshold findpeaks'}
    %                 if point2 > point3
    %                     BlurType = 'external';
    %                 else
    %                     BlurType = 'internal';
    %                 end
    %             case 'threshold'
    %                 pks = findpeaks(255-image_profile_values(point2-3:point3+3), ...
    %                     'NPEAKS',1);
    %                 size(pks);
    %                 if size(pks) > 0
    %                     BlurType = 'external';
    %                 else
    %                     BlurType = 'internal';
    %                 end
    %         end
    %     end
    
end

%% If this was an external blur, correct it


if image_profiles_parameters.manual_edge_matching == 0
    
    %     % Method 1
    %     if point2 < point3
    %         % External
    %         circle_1_edge = [edge1; edge2];
    %         circle_2_edge = [edge3; edge4];
    %     else
    %         % Internal
    %         circle_1_edge = [edge1; edge3];
    %         circle_2_edge = [edge2; edge4];
    %     end
    
    % Method 2
    if (strcmp(POINT_MARKING_METHOD,'threshold findpeaks') || strcmp(POINT_MARKING_METHOD,'threshold') ) && strcmp(BlurType,'external')
        circle_1_edge = [ edge1; edge3 ];
        circle_2_edge = [ edge2; edge4 ];
        disp('scanlines_estimate: Switching some co-ords')
    else
        circle_1_edge = [edge1; edge2];
        circle_2_edge = [edge3; edge4];
    end
    
    
elseif image_profiles_parameters.manual_edge_matching == 1
    circle_1_edge = [edge1; edge2];
    circle_2_edge = [edge3; edge4];
elseif image_profiles_parameters.manual_edge_matching == 2
    circle_1_edge = [edge1; edge3];
    circle_2_edge = [edge2; edge4];
else
    error('scanlines_estimate: incorrect manual_edge_matching parameter')
end



%% Fit circle to the points
switch image_profiles_parameters.circle_fitting_method
    case 'standard'
        [xc1, yc1, R1] = circfit(circle_1_edge(:,1),circle_1_edge(:,2));
        [xc2, yc2, R2] = circfit(circle_2_edge(:,1),circle_2_edge(:,2));
    case 'ransac'
        trials = image_profiles_parameters.ransac_trials;
        dth = image_profiles_parameters.ransac_dth;
        percent = image_profiles_parameters.ransac_percent;
        rLimits = image_profiles_parameters.ransac_rLimits;
        
        [ransac_center, ransac_r] = ransaccircle(circle_1_edge, trials, dth, percent, rLimits );
        [xc1, yc1] = deal(ransac_center(1),ransac_center(2));
        R1 = ransac_r;
        
        [ransac_center, ransac_r] = ransaccircle(circle_2_edge, trials, dth, percent, rLimits );
        [xc2, yc2] = deal(ransac_center(1),ransac_center(2));
        R2 = ransac_r;
        %     case 'EllipseDirectFit'
        %         [ellipse_fit_result] = EllipseDirectFit(circle_1_edge(:,1),circle_1_edge(:,2));
        %         xc1 = ellipse_fit_result(4); yc1 = ellipse_fit_result(5);
        %         [ellipse_fit_result] = EllipseDirectFit(circle_2_edge(:,1),circle_2_edge(:,2));
        %         xc2 = ellipse_fit_result(4); yc2 = ellipse_fit_result(5);
    case 'fit_ellipse'
        ellipse_t_1 = fit_ellipse(circle_1_edge(:,1),circle_1_edge(:,2));
        xc1 = ellipse_t_1.X0_in;
        yc1 = ellipse_t_1.Y0_in;
        R1 = (ellipse_t_1.a+ellipse_t_1.b)/2;
        ellipse_t_2 = fit_ellipse(circle_2_edge(:,1),circle_2_edge(:,2));
        xc2 = ellipse_t_2.X0_in;
        yc2 = ellipse_t_2.Y0_in;
        R2 = (ellipse_t_2.a+ellipse_t_2.b)/2;
end
[circ1_residual] = circfit_residuals(xc1,yc1,R1,circle_1_edge(:,1),circle_1_edge(:,2));
[circ2_residual] = circfit_residuals(xc2,yc2,R2,circle_2_edge(:,1),circle_2_edge(:,2));
if circ1_residual > 0.5 || circ2_residual > 0.5
    fprintf('WARNING: circle fit might not be very good. Mean error: Blue: %1.3f   Red: %1.3f \n',circ1_residual,circ2_residual);
end


%% Plot the measured edges
%  The (last) sampled line profile will also be plotted in the case of
%  manual testing mode
if suppress_output == false
    subplot(2,2,3)
    imshow(255-I) %%%  THIS CHANGES THE INVERSE FOR IMAGE 3
    hold on,
    plot(circle_1_edge(:,1),circle_1_edge(:,2),'ob',circle_2_edge(:,1),circle_2_edge(:,2),'or'), caxis auto, %colorbar, colormap(jet)
    if strcmp(SCANMODE,'manual')
        figure
        subplot(1,3,1); % 1: Show the image
        hold off,imshow(I), hold on, caxis auto,
        plot(circle_1_edge(:,1),circle_1_edge(:,2),'ob'), caxis auto, %colorbar, colormap(jet)
        plot(circle_2_edge(:,1),circle_2_edge(:,2),'or'), caxis auto, %colorbar, colormap(jet)
        
        subplot(1,3,2); % 2: The line profile
        %         figure(20)
        plot(image_profile_values,'-k'); hold on
        plot([point1 point3],image_profile_values([point1 point3]),'om');
        plot([point2 point4],image_profile_values([point2 point4]),'om');
        if strcmp(POINT_MARKING_METHOD,'threshold')
            plot([0 mid_point],repmat(min(left_crosssection)+pixel_range*sensitivity,1,2),'g-')
            plot([mid_point profile_length],repmat(min(right_crosssection)+pixel_range*sensitivity,1,2),'g-')
            plot([0 profile_length],repmat(max(image_profile_values)-pixel_range*sensitivity,1,2),'g-')
        end
        hold off;
        
        % 3: the differentiate profile
        if strcmp(POINT_MARKING_METHOD,'max difference')
            subplot(1,3,3), plot(differentsection);figure(gcf), hold on
            plot([point1 point2 point3 point4],[maxdifferent*sensitivity maxdifferent*sensitivity mindifferent*sensitivity mindifferent*sensitivity],'or'), hold off
        end
    end
end

%% Plot and offer to the user
if suppress_output == false && strcmp(SCANMODE,'auto')
    th = linspace(0,2*pi,20)';
    % plot1
    xe1 = R1*cos(th)+xc1; ye1 = R1*sin(th)+yc1;
    plot([xe1;xe1(1)],[ye1;ye1(1)],'b-',xc1,yc1,'bx')
    % plot2
    xe2 = R2*cos(th)+xc2; ye2 = R2*sin(th)+yc2;
    plot([xe2;xe2(1)],[ye2;ye2(1)],'r-',xc2,yc2,'rx')
    axis equal
    set(gcf, 'Position', get(0,'Screensize'));
    drawnow
end

separation_polar(1) = hypot(yc2-yc1,xc2-xc1);
separation_polar(2) = atan2d((yc2-yc1),(xc2-xc1));

if strcmp(SCANMODE,'auto')
    varargout{1} = [xc1 yc1 xc2 yc2];
    varargout{2} = blob_prop.WeightedCentroid([2 1]);
    varargout{3} = [xc1 yc1 R1 ; xc2 yc2 R2 ];
    varargout{4} = struct( ...
        'circfit_result', [xc1 yc1 R1 ; xc2 yc2 R2 ], ...
        'blob_WeightedCentroid', blob_prop.WeightedCentroid([2 1]), ...
        'separation_rc', [yc2-yc1, xc2-xc1], ...
        'separation_cartesian', [yc2-yc1, xc2-xc1], ...
        'ecludian_separation', sqrt(sum([yc2-yc1, xc2-xc1].^2)), ...
        'blur_type', BlurType, ...
        'point_marking_method', POINT_MARKING_METHOD, ...
        'scanmode', SCANMODE, ...
        'circle_1_points', circle_1_edge, ...
        'circle_2_points', circle_2_edge, ...
        'separation_polar', separation_polar, ...
        'xc1yc1xc2yc2', [xc1 yc1 xc2 yc2], ...
        'separation_distance', hypot( yc2-yc1 , xc2-xc1 ));
    if strcmp(POINT_MARKING_METHOD,'thresholds set')
        varargout{4}.low_threshold = low_threshold;
        varargout{4}.high_threshold = high_threshold;
    end
    if strcmp(image_profiles_parameters.circle_fitting_method,'fit_ellipse')
        varargout{4}.ellipse_t_1 = ellipse_t_1;
        varargout{4}.ellipse_t_2 = ellipse_t_2;
    end
else
    [varargout{1}, varargout{2}, varargout{3}, varargout{4}] = deal(nan);
    disp('scanlines_estimate:  No useful outputs when in manual scan mode');
end

