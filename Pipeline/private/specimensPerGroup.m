function n = specimensPerGroup(testName)
%SPECIMENSPERGROUP How many specimens each AP loading and material uses, per test.
%   n = specimensPerGroup(testName)
%
%   The one place this is set. Every plot, average and result picks the n
%   specimens closest to the median of their AP loading and material
%   (private/selectSpecimens.m) unless a function is given NumSpecimens.
%
%     Tension      13
%     Compression  13
%     Fracture     54   (every fracture group has at least 55 valid specimens;
%                        the smallest is 60% AP NEAT)

switch lower(string(testName))
    case "fracture"
        n = 54;
    otherwise
        n = 13;
end
end
