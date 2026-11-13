function ap = apRatio(testName, year)
%APRATIO AP loading (%) used for each Junior Lab year, per test.
%   ap  = apRatio(testName, year)   AP % for each year (NaN if the year is not listed)
%   map = apRatio(testName)         the whole table as [year, AP%] rows
%
%   This is the only place the year -> AP relationship is defined.
%   The fracture specimens have their own table: for them 2026 is 60 % and
%   2023 is 70 %. Tension and compression use 2023 = 60 % and 2026 = 70 %.
%   Add a row to both tables when a new year's samples are made.

switch lower(string(testName))
    case "fracture"
        map = [ 2024  40
                2025  50
                2026  60
                2023  70 ];
    otherwise                       % tension, compression
        map = [ 2024  40
                2025  50
                2023  60
                2026  70 ];
end

if nargin < 2
    ap = sortrows(map, 2);
    return;
end

ap = NaN(size(year));
for i = 1:numel(year)
    k = find(map(:, 1) == year(i), 1);
    if ~isempty(k)
        ap(i) = map(k, 2);
    end
end
end
