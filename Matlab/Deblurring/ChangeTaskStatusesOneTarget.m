%
% D McCarthy - May 2014

OldTarget = 11;

StatusesChanged = 0;
for t = 1:number_of_tasks
    if tasklist{t}.target_number == OldTarget
        tasklist{t}.task_status = 'queued';
        StatusesChanged = StatusesChanged +1;
    end
end
disp([num2str(StatusesChanged) ' task statuses changed to queued.']);