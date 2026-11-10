function results = plotCompressionModulus(opts)
%PLOTCOMPRESSIONMODULUS Compression modulus vs AP loading.
%
%   results = plotCompressionModulus()
%   results = plotCompressionModulus(Name=Value)
%
%   For every usable compression specimen in the processed workbook, the
%   modulus is the slope of the steepest straight part of the curve before
%   the peak (toe-compensated, as in ASTM D695):
%     - windows slide along the curve, each spanning FitStressSpan of the
%       peak stress, between FitLower and FitUpper of the peak
%     - every window is fitted with stress = E*strain + b
%     - E is the steepest window with R^2 >= MinRSquared and at least
%       MinFitPoints points
%   Taking the steepest straight window skips the seating (toe) region.
%   The old fixed 0.002-0.010 strain window landed in the toe on many
%   specimens and gave moduli of a few MPa. This method matches Bluehill's
%   own automatic modulus within 10 % on 96 % of specimens
%   (Compression_Modulus_Analysis.m in the repo root).
%
%   The NumSpecimens accepted fits closest to the median of their AP
%   loading and material (outliers removed first; private/selectSpecimens.m)
%   make the summary and figure. All specimens are listed, with an
%   InSelection column.
%
%   Saves
%     <repo>/Figures/Compression/Compression_Modulus_vs_AP.png
%         x = AP %, y = modulus. Dots = selected specimens, line + bars =
%         mean +/- 1 SD, CNT and NEAT side by side at each AP loading.
%     <repo>/ProcessedData/Compression_Modulus.xlsx
%         "All Specimens"  every fit, accepted or not, with R^2 and window
%         "Summary"        mean, SD, n, min, max per AP loading and material
%
%   Options
%     ProcessedFile      workbook from prepareData (default location)
%     OutputFolder       where the PNG goes (default <repo>/Figures/Compression)
%     ResultsFile        modulus workbook (default above)
%     FitStressSpan      stress rise each window covers, as a fraction of the
%                        peak (default 0.20)
%     FitLower           ignore the curve below this fraction of the peak (default 0.02)
%     FitUpper           ignore the curve above this fraction of the peak (default 0.90)
%     MinFitPoints       default 5
%     MinRSquared        default 0.995
%     Materials          default ["CNT","NEAT"]
%     ShowFigures        keep the figure open (default false)
%     IncludeDuplicates  also use CSVs flagged as copies (default false)
%     NumSpecimens       accepted fits per AP loading and material, closest to
%                        the group median (default 13; Inf = all)
%
%   Example
%     plotCompressionModulus(NumSpecimens=Inf, ShowFigures=true)

arguments
    opts.ProcessedFile     (1,1) string = ""
    opts.OutputFolder      (1,1) string = ""
    opts.ResultsFile       (1,1) string = ""
    opts.FitStressSpan     (1,1) double {mustBePositive} = 0.20
    opts.FitLower          (1,1) double = 0.02
    opts.FitUpper          (1,1) double = 0.90
    opts.MinFitPoints      (1,1) double = 5
    opts.MinRSquared       (1,1) double = 0.995
    opts.Materials         (1,:) string = ["CNT", "NEAT"]
    opts.ShowFigures       (1,1) logical = false
    opts.IncludeDuplicates (1,1) logical = false
    opts.NumSpecimens      (1,1) double {mustBePositive} = 13
end

p = pipelinePaths();
if opts.ProcessedFile == "", opts.ProcessedFile = p.ProcessedFile;                          end
if opts.OutputFolder  == "", opts.OutputFolder  = fullfile(p.Figures, 'Compression');        end
if opts.ResultsFile   == "", opts.ResultsFile   = fullfile(p.ProcessedDir, 'Compression_Modulus.xlsx'); end

% Every specimen here; the NumSpecimens are picked from the accepted fits below
[specimens, curves] = loadSpecimens(opts.ProcessedFile, "Compression", opts.IncludeDuplicates, ...
    Inf, false);
specimens = specimens(ismember(specimens.Material, opts.Materials), :);

if height(specimens) == 0
    warning('modulus:noData', 'No usable compression specimens.');
    results = table();
    return;
end

%% ------------------------------------------------------------ fit each specimen
n = height(specimens);
E   = NaN(n, 1);
R2  = NaN(n, 1);
nPt = zeros(n, 1);
x0  = NaN(n, 1);
x1  = NaN(n, 1);

for i = 1:n
    r = specimens.CurveRows{i};
    [E(i), R2(i), nPt(i), x0(i), x1(i)] = fitModulus(curves.Strain(r), curves.Stress_MPa(r), opts);
end

accepted = isfinite(E) & E > 0 & R2 >= opts.MinRSquared & nPt >= opts.MinFitPoints;

% The NumSpecimens closest to the median, picked among accepted fits
inSelection = false(n, 1);
if any(accepted)
    kept = selectSpecimens(specimens(accepted, :), "Compression", opts.NumSpecimens, true);
    inSelection = ismember(specimens.SpecimenID, kept.SpecimenID);
end

results = table( ...
    specimens.SpecimenID, specimens.APRatio_pct, specimens.Year, specimens.Material, ...
    specimens.Batch, specimens.Day, specimens.Group, specimens.SampleName, ...
    E, R2, nPt, x0, x1, accepted, inSelection, specimens.FilePath, ...
    'VariableNames', {'SpecimenID', 'APRatio_pct', 'Year', 'Material', ...
                      'Batch', 'Day', 'Group', 'Sample', ...
                      'Modulus_MPa', 'RSquared', 'NumberFitPoints', ...
                      'FitStartStrain', 'FitEndStrain', 'FitAccepted', 'InSelection', 'FilePath'});
results = sortrows(results, {'APRatio_pct', 'Material', 'SpecimenID'});

%% ------------------------------------------------------------ summary per AP and material
ok = results(results.FitAccepted & results.InSelection, :);
groups = unique(results(:, {'APRatio_pct', 'Year', 'Material'}));
groups = sortrows(groups, {'APRatio_pct', 'Material'});

nG = height(groups);
meanE = NaN(nG, 1); sdE = NaN(nG, 1); nE = zeros(nG, 1);
minE  = NaN(nG, 1); maxE = NaN(nG, 1);

for g = 1:nG
    v = ok.Modulus_MPa(ok.Year == groups.Year(g) & ok.Material == groups.Material(g));
    nE(g) = numel(v);
    if nE(g) >= 1
        meanE(g) = mean(v);
        minE(g)  = min(v);
        maxE(g)  = max(v);
    end
    if nE(g) >= 2
        sdE(g) = std(v);            % sample SD (N-1)
    end
end

summary = [groups, table(meanE, sdE, nE, minE, maxE, ...
    'VariableNames', {'MeanModulus_MPa', 'SD_MPa', 'NumberOfSpecimens', ...
                      'MinModulus_MPa', 'MaxModulus_MPa'})];

fprintf('\nCompression modulus (up to %g accepted fits per group)\n', opts.NumSpecimens);
fprintf('  AP %%   Year  Material   mean (MPa)   SD (MPa)   n\n');
for g = 1:nG
    fprintf('  %4g   %4d  %-8s  %10.1f  %9.1f  %3d\n', groups.APRatio_pct(g), ...
        groups.Year(g), groups.Material(g), meanE(g), sdE(g), nE(g));
end
fprintf('  %d of %d fits rejected (no straight window with R^2 >= %.3f)\n\n', ...
    sum(~results.FitAccepted), n, opts.MinRSquared);

%% ------------------------------------------------------------ write workbook
resultsDir = fileparts(opts.ResultsFile);
if ~isfolder(resultsDir), mkdir(resultsDir); end
if isfile(opts.ResultsFile)
    delete(opts.ResultsFile);
    if isfile(opts.ResultsFile)
        error('modulus:locked', 'Close %s in Excel and run again.', opts.ResultsFile);
    end
end
writetable(results, opts.ResultsFile, 'Sheet', 'All Specimens');
writetable(summary, opts.ResultsFile, 'Sheet', 'Summary');

%% ------------------------------------------------------------ figure
fo = struct('Materials', opts.Materials, ...
            'YLabel', 'Compression modulus (MPa)', ...
            'Title', "", ...
            'ValueLabel', "E (MPa)", ...
            'OutFile', fullfile(opts.OutputFolder, 'Compression_Modulus_vs_AP.png'), ...
            'ShowFigures', opts.ShowFigures);
outFile = plotMetricVsAP(ok, 'Modulus_MPa', summary, 'MeanModulus_MPa', 'SD_MPa', fo);
fprintf('Saved %s\nSaved %s\n', outFile, opts.ResultsFile);
end

%% ========================================================================
function [E, R2, nPoints, xStart, xEnd] = fitModulus(strain, stress, opts)
% Steepest straight window on the curve before the peak (see the header)
E = NaN; R2 = NaN; nPoints = 0; xStart = NaN; xEnd = NaN;

strain = strain(:); stress = stress(:);
ok = isfinite(strain) & isfinite(stress);
strain = strain(ok); stress = stress(ok);
if numel(stress) < opts.MinFitPoints
    return;
end

[peak, peakIdx] = max(stress);
if ~(peak > 0)
    return;
end
strain = strain(1:peakIdx);
stress = stress(1:peakIdx);

for i = 1:numel(stress)
    if stress(i) < opts.FitLower * peak
        continue;
    end

    % extend the window until stress has risen by the span
    j = find(stress(i:end) - stress(i) >= opts.FitStressSpan * peak, 1, 'first');
    if isempty(j)
        break;
    end
    j = i + j - 1;

    x = strain(i:j);
    y = stress(i:j);
    if numel(x) < opts.MinFitPoints || max(y) > opts.FitUpper * peak
        continue;
    end

    c = polyfit(x, y, 1);
    ssTot = sum((y - mean(y)).^2);
    if ssTot <= 0
        continue;
    end
    r2 = 1 - sum((y - polyval(c, x)).^2) / ssTot;

    if r2 >= opts.MinRSquared && (~isfinite(E) || c(1) > E)
        E = c(1);
        R2 = r2;
        nPoints = numel(x);
        xStart = x(1);
        xEnd = x(end);
    end
end
end
