function psf = sinusoidal_blur_kernel5(psf_magnitude,psf_rotation,aa)

% psf_magnitude = psf_magnitude/1.16;

% disp(['.............aa = ', num2str(aa)])

% psf_magnitude = 8.4;
% psf_rotation = 0;
% aa = 0;

kernel_size = [1 ceil(psf_magnitude/2)*2+5];

bb = 1 - aa;

psf = nan(kernel_size);       % Create an array for the blur kernel
centre_of_psf = kernel_size/2;

kernel_col_min = centre_of_psf(2)-psf_magnitude/2+0.5;
kernel_col_max = centre_of_psf(2)+psf_magnitude/2+0.5;

% Check for special cases
if psf_magnitude == 1
    psf = [0 1 1 0];
elseif psf_magnitude < 1
    psf = fspecial('motion',abs(psf_magnitude)+1);
elseif psf_magnitude < 2 && psf_magnitude > 1
    psf = [ 0,  psf_magnitude/2, 2-psf_magnitude, psf_magnitude/2, 0];
else
    % Not a special case
    row = round(kernel_size(1)/2);
    for col = 1:kernel_size(2)
        % pixel is on the minimum edge of the blur function
        if col == floor(kernel_col_min)
        %         if (col > floor(kernel_col_min)-1) && (col < floor(kernel_col_min))
%         if col == floor(kernel_col_min)
%             % Linear interpolation
            left = kernel_col_min-col;
            right = 1-left;
            left_part = 0;
            right_part = ( 1/2*cos( (( right/2  )) *2*pi()/(psf_magnitude) )+1/2 )*bb+aa;
            psf(row,col) = left * left_part + right * right_part ;
            continue
        end
        
        % pixel is inside the blur function
        if (col >= floor(kernel_col_min)) && (col < ceil(kernel_col_max))
            %             psf(row,col) = ...
            %                 1/2*cos( ((col-kernel_col_min+0.5)) *2*pi()/(dims(2)) )+1/2 ;
            psf(row,col) = ...
                (1/2*cos( ((col-kernel_col_min)) *2*pi()/psf_magnitude  )+1/2 )*bb+aa;
            continue
        end
        
        % pixel is on the maximum edge of the blur function
        %         if (col > floor(kernel_col_max)) && (col < floor(kernel_col_max)+1)
        if col == ceil(kernel_col_max)
            psf(row,col) = left * left_part + right * right_part ;
        end
%         if col == ceil(kernel_col_max)
%             left = kernel_col_max+1-col;
%             right = 1-left;
%             left_part = ( 1/2*cos( (( col-kernel_col_min+left/2  )) *2*pi()/(psf_magnitude) )+1/2)*bb+aa ;
%             right_part = 0;
%             psf(row,col) = left * left_part + right * right_part ;
%             continue
%         end
    end
end

psf(isnan(psf)) = 0;

% Rotate kernel
psf = imrotate(psf,psf_rotation,'bilinear');

psf = psf./sum(sum(psf));

% plot(psf)