%% Plot all the points
figure
I = imread(filepath);
imshow(I)
hold on
plot(SavedLocatedCrosses(:,1),SavedLocatedCrosses(:,2),'xy');
if exist('BlurDisplacementsPairs','var') == 1
    if size(BlurDisplacementsPairs,1) > 0
        for p = 1:size(BlurDisplacementsPairs,1)
            plot(BlurDisplacementsPairs(p,[1 3]),BlurDisplacementsPairs(p,[2 4]),'g-')
            text(BlurDisplacementsPairs(p,1)+10,BlurDisplacementsPairs(p,2)+10,num2str(p));
        end
    end
end

while true == true
    
    [user_x,user_y] = ginput2(2);   
    for p = 1:2
        differences = repmat([user_x(p) user_y(p)],size(SavedLocatedCrosses,1),1) - SavedLocatedCrosses;
        EclDists = sqrt(differences(:,1).^2 + differences(:,2).^2);
        [~, nearestind] = min(EclDists);
        pair(p) = nearestind;
    end
    
    if exist('BlurDisplacementsPairs','var') == 0
        BlurDisplacementsPairs = [];
    end
    BlurDisplacementsPairs(end+1,[1 2]) = SavedLocatedCrosses(pair(1),:);
    BlurDisplacementsPairs(end,[3 4]) = SavedLocatedCrosses(pair(2),:);
    plot(BlurDisplacementsPairs(end,[1 3]),BlurDisplacementsPairs(end,[2 4]),'g-')
end