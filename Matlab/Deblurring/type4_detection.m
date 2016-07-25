function [P1, P2, P3, P4] = type4_detection(image_profile_values,sensitivity_level)

extend = 10;

[~, mid_point] = max(image_profile_values);
pixel_range = max(image_profile_values) - min(image_profile_values);

left_crosssection = image_profile_values(1:mid_point);
right_crosssection = image_profile_values(mid_point+1:end);
low_left_points  = left_crosssection <= min(left_crosssection)+pixel_range*sensitivity_level;
low_right_points  = right_crosssection <= min(right_crosssection)+pixel_range*sensitivity_level;

high_points = image_profile_values >= max(image_profile_values)-pixel_range*sensitivity_level;

point2 = find(high_points,1,'first');
point3 = find(high_points,1,'last');

point1 = find(low_left_points,1,'last');
point4 = find(low_right_points,1,'first') + mid_point;

xx=[-9999; 9999];
% tic
left_pts_x = [point1; point2];
left_pts_y = image_profile_values(left_pts_x);
left_line = fit(left_pts_x,left_pts_y,'poly1');

% y1 = min(left_crosssection);
y1 = mode(round(image_profile_values(max(1,(point1-extend)):point1)));
y1_line = fit(xx,[y1; y1],'poly1');

right_pts_x = [point3; point4];
right_pts_y = image_profile_values(right_pts_x);
right_line = fit(right_pts_x,right_pts_y,'poly1');

% y3 = min(right_crosssection);
y3 = mode(round(image_profile_values(point4:min(point4+extend,length(image_profile_values)))));
y3_line = fit(xx,[y3; y3],'poly1');

top_list = round(image_profile_values(point2:point3));
top_list(top_list>=max(top_list)-5)= [];
y2 = mode(top_list);
% y2 = max(image_profile_values);
y2_line = fit(xx,[y2; y2],'poly1');
% toc
% [P1, P2, P3, P4] = deal(zeros(2,1));
% tic
[P1(1), ~] = intersections(xx,left_line(xx),xx,y1_line(xx));
[P2(1), ~] = intersections(xx,left_line(xx),xx,y2_line(xx));
[P3(1), ~] = intersections(xx,right_line(xx),xx,y2_line(xx));
[P4(1), ~] = intersections(xx,right_line(xx),xx,y3_line(xx));
% toc
0;

if false
    figure
    plot(image_profile_values,'k')
    hold on
    plot([P1 P3],image_profile_values(round([P1 P3])),'ob');
    plot([P2 P4],image_profile_values(round([P2 P4])),'or');
    ylim([0 256])
    plot(left_line,'b')
    plot(right_line,'r')
    plot(y1_line,'m')
    plot(y2_line,'m')
    plot(y3_line,'m')
    legend off
end

0;

% P = [P1,P2,P3,P4]';