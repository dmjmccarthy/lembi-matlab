function [ varargout ] = refine_with_simulation(~,~,~,estimate,window_size,Padding,aa,iterations,Isharp_cropped,Isharp_cropped_estimated_centre,I_cropped,Iblurred_estimated_centre,scanline_target,image_profiles_parameters,~,first_profiles_data)

CORRELATION_METHOD = 'scanlines'; % OPTIONS: 'image correlation' 'scanlines' 'polar-d';
SEARCH_MODE = 'cartesian'; % OPTIONS: 'cartesian' 'polar';

if size(I_cropped,1) == 0, disp('Blurred image is empty'), return, end
if size(Isharp_cropped,1) == 0, disp('Sharp image is empty'), return, end

% Sets each blur displacement that will be
% tested in the first iteration
% and defines the target


switch SEARCH_MODE
    case 'cartesian'
        xc1 = estimate(1);   % Just collecting the input variables
        xc2 = estimate(2);
        yc1 = estimate(3);
        yc2 = estimate(4);
        
        % Gets the estimated blur size from the
        % coordinates
        estimated_blur_size = first_profiles_data.separation_cartesian;

        % row_th = estimated_blur_size(1):1:estimated_blur_size(1);
        row_th = estimated_blur_size(1)-5:0.25:estimated_blur_size(1)+3;
        col_th = estimated_blur_size(2)-5:0.25:estimated_blur_size(2)+3;
        col_th(col_th <= 0) = [];       % Don't create as PSFs that are
                                        % have negative widths.
        % col_th = [31.098];
        
    case 'polar'
        profiles_polar_target = first_profiles_data.separation_polar;
        row_th = profiles_polar_target(1)-2:0.25:profiles_polar_target(1)+2 ; % Row = dist
        col_th = profiles_polar_target(2)-5:1:profiles_polar_target(2)+5 ; % Col = angle
        
end

row_ind = 1:size(row_th,2);     % Numbers the blur displacements
col_ind = 1:size(col_th,2);

I_blur_centre = Iblurred_estimated_centre;
% I_blur_centre = [(yc1+yc2)/2 (xc1+xc2)/2];
iteration = 1;                  % The first iteration will be numbered 1



% Plot first image with scanlines data
figure(10)
subplot(3,3,1)
imshow(I_cropped)
caxis auto
hold on

first_profiles_fit_circles = first_profiles_data.circfit_result;
xc1 = first_profiles_fit_circles(1,1);
yc1 = first_profiles_fit_circles(1,2);
R1 = first_profiles_fit_circles(1,3);
xc2 = first_profiles_fit_circles(2,1);
yc2 = first_profiles_fit_circles(2,2);
R2 = first_profiles_fit_circles(2,3);

th = linspace(0,2*pi,20)';
xe1 = R1*cos(th)+xc1; ye1 = R1*sin(th)+yc1;     % plot1
plot([xe1;xe1(1)],[ye1;ye1(1)],'b-',xc1,yc1,'bx')
xe2 = R2*cos(th)+xc2; ye2 = R2*sin(th)+yc2;     % plot2
plot([xe2;xe2(1)],[ye2;ye2(1)],'r-',xc2,yc2,'rx')
hold off
title('Blurred observation image')


%% THIS IS WHERE ITERATIONS START
while iteration <= iterations
    c = nan(row_ind(end),col_ind(end));
    scanline_difference = nan(row_ind(end),col_ind(end));
    [ polar_dist_difference, polar_ang_difference] = deal(nan(row_ind(end),col_ind(end)));
    
    % For each blur size that we defined above,
    % calculate the correlation coefficient
    for row = row_ind
        for col = col_ind

            % GET IMAGE CORRELATION
            switch SEARCH_MODE
                case 'polar'
                    profiles_polar_current_filter = [row_th(row), col_th(col)];
                    fprintf( 'refine_with_simulation:  Polar mode  Iter:%1u  Ind:%2.0u, %2.0u  Dist: %5.3f Ang: %5.3f \n', iteration, row, col, row_th(row), col_th(col) );
                    
                    [c(row,col), scanline_current, ~, profiles_data_current] = ...
                        verify_with_simulation(I_cropped,Isharp_cropped, ...
                        0,[0 0 0 0], window_size, ...
                        Padding,aa,Isharp_cropped_estimated_centre, ...
                        image_profiles_parameters, profiles_polar_current_filter);
                    
                case 'cartesian'
                    fprintf( 'refine_with_simulation:  Cart. mode  Iter:%1u  Ind:%2.0u, %2.0u   Dims: %5.3f, %5.3f \n', iteration, row, col, row_th(row), col_th(col) );
                    BlurDisplacementsPair = [ ...
                        I_blur_centre(2)-col_th(col)/2 ...
                        I_blur_centre(2)+col_th(col)/2 ...
                        I_blur_centre(1)-row_th(row)/2 ...
                        I_blur_centre(1)+row_th(row)/2 ];
                    
                    [c(row,col), scanline_current, ~, profiles_data_current] = ...
                        verify_with_simulation(I_cropped,Isharp_cropped, ...
                        0,BlurDisplacementsPair, window_size, ...
                        Padding,aa,Isharp_cropped_estimated_centre, ...
                        image_profiles_parameters);
            end
            
            profiles_polar_current = profiles_data_current.separation_polar;
            
            % CALCULATE SCANLINES DIFFERENCE
            scanline_difference(row,col) = sqrt(sum(scanline_current - scanline_target).^2);
            
            if strcmp(SEARCH_MODE,'polar')
                % CALCULATE POLAR DIFFERENCES
                polar_dist_difference(row,col) = profiles_polar_current(1) - profiles_polar_target(1);
                polar_ang_difference_current = profiles_polar_current(2) - profiles_polar_target(2);
                
                
                % Output range: -180 ~ 180
                if polar_ang_difference_current < 0
                    polar_ang_difference_current = polar_ang_difference_current + 180;
                end % Output range: 0 ~ 180
                if polar_ang_difference_current > 90
                    polar_ang_difference_current = polar_ang_difference_current - 180;
                end % Output range: -90 ~ 90
                
                polar_ang_difference(row,col) = polar_ang_difference_current;
            end
            
            fprintf('\b  c: %1.5f   sd: %1.5f \n',c(row,col),scanline_difference(row,col));
            figure(10), subplot(3,3,4:6),
            plot(col_th,c)
%             subimage(c), colormap('jet'), caxis auto, colorbar('southOutside');
            ylabel('Correlation coefficient')

            
            subplot(3,3,7:9);
            plot(col_th,scanline_difference);
 %             subimage(scanline_difference,cmap), caxis auto;
            ylabel('Distance error (pixels)')
          
            figure(11)
            subplot(1,3,1), imshow(scanline_difference), title('Scanline eclud. dist. diff.')
            subplot(1,3,2), imshow(polar_dist_difference), title('Polar. dist. diff.')
            subplot(1,3,3), imshow(polar_ang_difference), title('Polar. ang. diff.')
            colormap('jet'), caxis auto
            figure(10)
            
            fprintf( 'refine_with_simulation:  Polar differences: Dist:%4.2f Ang:%4.2f\n\n', polar_dist_difference(row,col), polar_ang_difference(row,col) );
            drawnow; 
        end
    end
    
    % Get the greatest correlation coefficient
    
    switch CORRELATION_METHOD
        case 'image correlation'
            [~, highest_correlation_sub(2)] = max(c);
            [~, highest_correlation_sub(1)] = max(max(c));
        case 'scanlines'
%             [~, highest_correlation_sub(2)] = min(scanline_difference);
            highest_correlation_cols = min(scanline_difference); 
            [~, highest_correlation_sub(1)] = min(min(scanline_difference));
            highest_correlation_sub(2) = highest_correlation_cols(highest_correlation_sub(1));
        case 'polar-d'
            [~, highest_correlation_sub(2)] = min(polar_dist_difference);
            [~, highest_correlation_sub(1)] = min(min(polar_dist_difference));            
    end
    
    if iteration < iterations   % Check if there are more iterations to go
        
        col_no = size(col_th,2);
        col_th_span = col_th(end) - col_th(1) ;
        
        % Check if the highest correlation is at an edge
        if highest_correlation_sub(2) < 6 || highest_correlation_sub(2) > size(col_th,2)-6
            % Expand the search
            % Columns
            col_th_start = col_th(1)-col_th_span*0.1;
            col_th_end = col_th(end)+col_th_span*0.1;
            iteration = iteration - 1;
        else   % All ok: set the next iteration parameters
            % Columns
            col_th_start = col_th(highest_correlation_sub(2)-5);
            col_th_end = col_th(highest_correlation_sub(2)+5);
        end
        
        if col_th_start < 0
            col_th_start = 0;
            iteration = iteration + 1;
        end
        
        % Set the next search
        col_th_span = col_th_end - col_th_start ;
        col_th = col_th_start:(col_th_span/col_no):col_th_end;
        row_ind = 1:size(row_th,2);     % Numbers the blur displacements
        col_ind = 1:size(col_th,2);
        
    else   % This was the final iteration - this value
        % will be passed back to the parent
        % function.
        best_match_row = row_th(highest_correlation_sub(1));
        best_match_col = col_th(highest_correlation_sub(2));
        best_match = [best_match_row best_match_col];
    end
    iteration = iteration + 1; % Increase the counter
    
    
end
0;

switch CORRELATION_METHOD
    case {'scanlines', 'polar-d'}
        varargout{1} = 0;
    case 'image correlation'
        varargout{1} = highest_correlation;
end
varargout{2} = best_match;