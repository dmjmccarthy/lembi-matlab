% verify_with_simulation
% D McCarthy Nov 2012
% Takes a blurred and unblurred image, artificially blurs the sharp image,
% and calculates the correlation statistic
%
% Usage: c = verify_with_simulation(Iblurred,Isharp,~, ...
%           BlurDisplacementsPair,window_size,~,aa, ...
%           Isharp_estimated_centre)
%
% where     Iblurred:                   Cropped blurred observations image
%           Isharp:                     Cropped sharp images with padding
%           BlurDisplacementsPair:      [xc1 xc2 yc1 yc2]
%           window_size:                Size of correlation window
%           aa:                         Parameter for the artificial psf
%           Isharp_estimated_centre:    Centre of the sharp image
%

function [varargout] = verify_with_simulation( Iblurred,Isharp,~,BlurDisplacementsPair,window_size,~,aa,Isharp_estimated_centre,image_profiles_parameters, varargin)


% searching_for_zero = varargin{2};

%% Estimate the blur PSF and filter the sharp image
% kernel_size = [50 50];

% if polar?
if nargin >= 10 
    polar_separation = varargin{1};
%     estimated_blur_size = [0 polar_separation(1)];
%     kernel_rotation = polar_separation(2);
else
    xc1 = BlurDisplacementsPair(1);  % Just collecting the input variables
    xc2 = BlurDisplacementsPair(2);
    yc1 = BlurDisplacementsPair(3);
    yc2 = BlurDisplacementsPair(4);
%     estimated_blur_size = [yc2-yc1, xc2-xc1];
%     kernel_rotation = 0;
end

% estimated_blur_size(1) = abs(estimated_blur_size(1));

% psf = fspecial('motion',estimated_blur_size(2));
% psf = sinusoidal_blur_kernel_subpixel(kernel_size,estimated_blur_size,aa);
% psf = sinusoidal_blur_kernel_subpixel2(kernel_size,estimated_blur_size,aa);
% psf = imrotate(psf,kernel_rotation,'bilinear');
psf = sinusoidal_blur_kernel5(polar_separation(1),polar_separation(2),aa);
Isharp_filtered = imfilter(Isharp,psf, 'replicate');

% Crop away the additional padding added earlier
Isharp_crop_corner2 = round(Isharp_estimated_centre) - window_size./2;
Isharp_filtered = imcrop(Isharp_filtered,[Isharp_crop_corner2(2) Isharp_crop_corner2(1) window_size(2)-1 window_size(1)-1]);
% Do the same for unfiltered Isharp
Isharp = imcrop(Isharp,[Isharp_crop_corner2(2) Isharp_crop_corner2(1) window_size(2)-1 window_size(1)-1]);
Isharp_estimated_centre = Isharp_estimated_centre - Isharp_crop_corner2;
% Pad = (size(Isharp)-size(Iblurred))/2;
% Isharp_filtered = imcrop(Isharp_filtered,[Pad+[1 1] window_size(2) window_size(1)]);
% Isharp = imcrop(Isharp,[Pad+[1 1] window_size(2) window_size(1)]);
% Isharp_estimated_centre = Isharp_estimated_centre - Pad;

% This is the NEW histmatched version
% Isharp_filtered_histmatched = imhistmatch(Isharp_filtered,I,256);

% SKIP ADJUSTMENT
% % Adjust using histmatching
% Iblurred_histogram = imhist(Iblurred);
% Isharp_filtered_histeq = histeq(Isharp_filtered,Iblurred_histogram);

%% Compare to the blurred image
% USING CORRELATION
% SKIP CORRELATION
% c = max(max( normxcorr2(double(Iblurred),double(Isharp_filtered_histeq)) ));
c = 0;

% USING PROFILES
I_user_selected_point = round(size(Isharp_filtered)/2);

image_profiles_parameters.is_simulated_image = true;
if isfield(image_profiles_parameters, 'overide_threshold_adjustment_at_verify')
    if image_profiles_parameters.overide_threshold_adjustment_at_verify
        image_profiles_parameters.threshold_adjust = 0;
    end
end

new_Isharp_crop_corner = ((size(Isharp) - size(Iblurred))/2);
% Isharp = imcrop(Isharp, [((size(Isharp) - size(Iblurred))/2) size(Iblurred)] );
% Crop the some additional padding?
Isharp = Isharp( new_Isharp_crop_corner(1)+1:new_Isharp_crop_corner(1)+size(Iblurred,1), ...
    new_Isharp_crop_corner(2)+1:new_Isharp_crop_corner(2)+size(Iblurred,2) );

[~, ~, ~, current_profiles_data] = scanlines_estimate(Isharp_filtered,image_profiles_parameters,I_user_selected_point,0,Isharp,Isharp_estimated_centre);
% [estimated_coords, ~, ~, current_profiles_data] = scanlines_estimate(Isharp_filtered,image_profiles_parameters,I_user_selected_point,0,Isharp,Isharp_estimated_centre);

% scanline_current = [estimated_coords(3)-estimated_coords(1) estimated_coords(4)-estimated_coords(2)];
scanline_current_magnitude = current_profiles_data.separation_polar(1);
scanline_current_rotation = current_profiles_data.separation_polar(2);
current_profiles_data.separation_polar;

%% Figures
% figure(10)
% % Observation image displayed by refine_with_simulation function
% subplot(1,2,2)
% imshow(Isharp_filtered)
% title('Sharp filtered image')
% hold on
% xc1 = current_profiles_data.circfit_result(1,1);
% yc1 = current_profiles_data.circfit_result(1,2);
% R1 = current_profiles_data.circfit_result(1,3);
% xc2 = current_profiles_data.circfit_result(2,1);
% yc2 = current_profiles_data.circfit_result(2,2);
% R2 = current_profiles_data.circfit_result(2,3);
% th = linspace(0,2*pi,20)';
% xe1 = R1*cos(th)+xc1; ye1 = R1*sin(th)+yc1;     % plot1
% plot([xe1;xe1(1)],[ye1;ye1(1)],'b-',xc1,yc1,'bx')
% plot(current_profiles_data.circle_1_points(:,1),current_profiles_data.circle_1_points(:,2),'bo')
% xe2 = R2*cos(th)+xc2; ye2 = R2*sin(th)+yc2;     % plot2
% plot([xe2;xe2(1)],[ye2;ye2(1)],'r-',xc2,yc2,'rx')
% plot(current_profiles_data.circle_2_points(:,1),current_profiles_data.circle_2_points(:,2),'ro')
% hold off
% axis equal

% subplot(3,3,3)
% imshow(Isharp_filtered_histeq)
% title('Histogram adjusted image')

% FULLSCREEN
% set(gcf, 'Position', get(0,'Screensize'));
if ~image_profiles_parameters.suppress_output
    caxis auto
    drawnow
end

0;

varargout{1} = Isharp_filtered;
varargout{2} = 0; %scanline_current; % UNUSED
varargout{3} = current_profiles_data.separation_polar; % UNUSED
varargout{4} = current_profiles_data;