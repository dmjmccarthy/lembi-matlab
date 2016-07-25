function [ControlPoints SurveyPoints] = ReadPMPointTable(PMdata,PhotoNumber)
% PhotoNumber = 1
ControlPoints = []; SurveyPoints = [];

for line = 1:size(PMdata{1,1},1)
    if PMdata{1,1}(line,2) == PhotoNumber
        if PMdata{1,1}(line,1) < 1000
            ControlPoints(end+1,[2 3]) = PMdata{1,1}(line,[3 4]);
            ControlPoints(end,1) = PMdata{1,1}(line,1);
        else
            SurveyPoints(end+1,[1 2]) = PMdata{1,1}(line,[3 4]);
        end
    end
end