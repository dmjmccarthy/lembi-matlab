%
% D McCarthy - May 2013

OldStatus = 'error';
NewStatus = 'queued';

StatusesChanged = 0;
for t = 1:number_of_tasks
    if strcmp(tasklist{t}.task_status,OldStatus) % && ...
            %tasklist{t}.image_number == 39
        tasklist{t}.task_status = NewStatus;
        StatusesChanged = StatusesChanged +1;
    end
end
disp([num2str(StatusesChanged) ' task statuses changed from ''' OldStatus ''' to ''' NewStatus '''.']);