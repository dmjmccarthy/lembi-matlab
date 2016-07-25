% Given an image, returns the centre of a target

function [I_estimated_centre] = search_for_target_in_image(I,I_user_selected_point)

include_circle_check = false;

I_threshold = graythresh(I);
I_bw = im2bw(I,I_threshold);
% figure, imshow(I_bw)
I_CC = bwconncomp(I_bw);
I_stats = regionprops( I_CC , I, 'WeightedCentroid','Perimeter','Area'); % This doesn't use any particular blob!!!
if I_CC.NumObjects == 1
    % If there's only one blob, choose it
    I_blob_id = 1;
else
    % If there's more than one, choose the same position
    I_L = labelmatrix(I_CC);
    I_blob_id = I_L(round(I_user_selected_point(1)),round(I_user_selected_point(2)));
    if I_blob_id == 0
        %        % We've still not found the target!
        %         % We'll pick the largest blob instead
        %         [~, Isharp_blob_id] = max(cellfun(@length,Isharp_CC.PixelIdxList));
        % That's a silly idea, we'll find the nearest blob instead
        list2 = zeros(1,2);
        for b = 1:I_CC.NumObjects
            if include_circle_check && ...
                    (sqrt(I_stats(b).Area) / I_stats(b).Perimeter) < 0.3 % Check if circle
                continue, end
            if I_stats(b).Area < 5
                continue, end
            list1 = I_CC.PixelIdxList{b}(:);
            size_list1 = size(list1,1);
            list2(end+1:end+size_list1,1) = ones(size_list1,1)*b;
            list2(end-size_list1+1:end,2) = list1;
        end
        list2(1,:) = [];
        [list2(:,3), list2(:,4)] = ind2sub(size(I),list2(:,2));
        list2(:,[5 6]) = list2(:,[3 4]) - repmat(I_user_selected_point,length(list2),1);
        list2(:,7) = hypot(list2(:,5),list2(:,6));
        [~, shortest] = min(list2(:,7));
        I_blob_id = list2(shortest,1);
        % And the new estimated centre is...
    end
end
I_estimated_centre = I_stats(I_blob_id).WeightedCentroid([2 1]); % GOT THE CENTRE!
% figure, imshow(Isharp), hold on, plot(Isharp_stats.WeightedCentroid(1),Isharp_stats.WeightedCentroid(2),'g+'), title('STAGE 1');