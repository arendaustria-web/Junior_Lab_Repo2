function [specimens, curves] = loadSpecimens(processedFile, testName, includeDuplicates)
%LOADSPECIMENS Usable specimens of one test from the processed workbook.
%   Shared by plotTension, plotCompression and plotCompressionModulus.
%
%   specimens   Specimens-sheet rows with Status "ok" for this test, plus
%                 APRatio_pct  AP loading from apRatio(Year)
%                 CurveRows    row indices into curves for that specimen
%   curves      the test's curve sheet (SpecimenID, Displacement_mm,
%               Force_N, Strain, Stress_MPa)
%
%   Rows flagged as copies of another specimen (DuplicateOf) are dropped
%   unless includeDuplicates is true. Specimens listed in
%   excludedSpecimens.m are always dropped.

if ~isfile(processedFile)
    error('plot:noProcessedFile', ...
        ['Processed workbook not found:\n  %s\n' ...
         'Run prepareData() first.'], processedFile);
end

if ~ismember(string(testName), sheetnames(processedFile))
    error('plot:noTestSheet', ...
        ['%s has no "%s" sheet. It was made by an older prepareData;\n' ...
         'run prepareData() again (runAnalysis does this when rebuildProcessedData = true).'], ...
        processedFile, testName);
end

specimens = readtable(processedFile, 'Sheet', 'Specimens', 'TextType', 'string');
curves    = readtable(processedFile, 'Sheet', char(testName));

keep = specimens.Test == testName & specimens.Status == "ok";

nDuplicates = 0;
if ismember('DuplicateOf', specimens.Properties.VariableNames) && ~includeDuplicates
    dup = specimens.DuplicateOf;
    if ~isnumeric(dup), dup = str2double(dup); end   % all-empty column reads as text
    isDup = isfinite(dup);
    nDuplicates = sum(keep & isDup);
    keep = keep & ~isDup;
end

% Specimens listed in excludedSpecimens.m (bad tests the user has ruled out)
excluded = excludedSpecimens();
nExcluded = 0;
if ~isempty(excluded)
    normPath = @(p) lower(replace(strtrim(string(p)), "/", "\"));
    allPaths = normPath(specimens.FilePath);
    listed   = normPath(excluded(:, 1));
    isExcluded = ismember(allPaths, listed);
    nExcluded = sum(keep & isExcluded);
    keep = keep & ~isExcluded;
    notFound = excluded(~ismember(listed, allPaths), 1);
    for k = 1:numel(notFound)
        warning('plot:excludedNotFound', ...
            'excludedSpecimens.m lists a path that is not in the workbook:\n  %s', notFound(k));
    end
end

specimens = specimens(keep, :);
if nDuplicates > 0
    fprintf('%s: skipping %d duplicate CSVs (set IncludeDuplicates=true to use them)\n', ...
        testName, nDuplicates);
end
if nExcluded > 0
    fprintf('%s: leaving out %d specimens listed in excludedSpecimens.m\n', testName, nExcluded);
end

% AP loading always comes from apRatio.m, so editing that file is enough
specimens.APRatio_pct = apRatio(specimens.Year);
unknown = unique(specimens.Year(isnan(specimens.APRatio_pct)));
if ~isempty(unknown)
    warning('plot:noAPRatio', 'No AP ratio defined in apRatio.m for year(s): %s', ...
        strjoin(string(unknown'), ', '));
end

% Curve rows for each specimen
specimens.CurveRows = repmat({zeros(0, 1)}, height(specimens), 1);
if height(curves) > 0 && height(specimens) > 0
    [curveIDs, ~, g] = unique(curves.SpecimenID);
    rowsByID = accumarray(g, (1:height(curves))', [], @(r) {sort(r)});
    [found, loc] = ismember(specimens.SpecimenID, curveIDs);
    specimens.CurveRows(found) = rowsByID(loc(found));
end
end
