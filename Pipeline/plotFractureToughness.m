function results = plotFractureToughness(opts)
%PLOTFRACTURETOUGHNESS K_Ic and G_Ic of the compact-tension specimens vs AP loading.
%
%   results = plotFractureToughness()
%   results = plotFractureToughness(Name=Value)
%
%   For every usable fracture specimen in the processed workbook
%     a    = NotchLength_mm + PreCrackLength_mm,  W = Width_mm,  B = Thickness_mm
%     K_Ic = P_max / (B sqrt(W)) * f(a/W)                          [MPa m^0.5]
%            f = (2 + a/W)(0.886 + 4.64 a/W - 13.32 (a/W)^2 + 14.72 (a/W)^3
%                - 5.6 (a/W)^4) / (1 - a/W)^1.5    (ASTM D5045 / E399 CT)
%     G_Ic = U / (B (W - a))                                       [kJ/m^2]
%            U = area under the force-displacement curve up to P_max
%            (energy method with the compliance factor phi = 1, as in the
%            original script)
%   A specimen is valid when ValidAOverW(1) < a/W < ValidAOverW(2) (default
%   0.2-0.8, the original rule) and 2 <= W/B <= 4 (ASTM D5045 proportions;
%   this also rejects dimension rows with swapped or shifted columns, such
%   as several 2023 sections). ASTM D5045 itself asks for a/W 0.45-0.55;
%   these specimens sit near 0.57-0.62, so call the values K_Q / G_Q if you
%   need to be strict.
%
%   The NumSpecimens valid specimens closest to the median of their AP
%   loading and material (outliers removed first; private/selectSpecimens.m)
%   make the summary and figures, so every group has NumSpecimens results
%   when it has that many valid specimens. All specimens are listed, with
%   an InSelection column.
%
%   Differences from the old Fracture_GIc_KIc_Analysis.m
%     - P_max is the measured peak load. The old script subtracted the load
%       at the start of loading (~6 % of peak), so its K_Ic were ~6 % low and
%       its G_Ic ~12 % low. Slack is removed by toe compensation instead
%       (private/toForceDisplacement.m).
%     - Dimensions: the CSV files do not say which of the four measured
%       specimens of a section they are, so by default each specimen uses
%       the average B, W and a of its section and material. Dimensions =
%       "matched" reproduces the old pairing by max-force rank, which adds
%       up to ~15 % random scatter to K_Ic.
%     - Year -> AP loading comes from apRatio.m (the old script used
%       2023 = 50 % and 2025 = 60 %).
%     - Compact-tension files with "Tension" in the name (2025) are included.
%
%   Saves
%     <repo>/Figures/Fracture/Fracture_KIc_vs_AP.png
%     <repo>/Figures/Fracture/Fracture_GIc_vs_AP.png
%     <repo>/ProcessedData/Fracture_Toughness.xlsx  ("All Specimens", "Summary")
%
%   Options
%     ProcessedFile      workbook from prepareData (default location)
%     OutputFolder       where the PNGs go (default <repo>/Figures/Fracture)
%     PDFFolder          where vector PDFs of the figures go ("" = none, default)
%     ResultsFile        toughness workbook (default above)
%     Dimensions         "section average" (default) or "matched"
%     ValidAOverW        [low high] a/W window (default [0.2 0.8])
%     Materials          default ["CNT","NEAT"]
%     ShowFigures        keep the figures open (default false)
%     IncludeDuplicates  also use CSVs flagged as copies (default false)
%     NumSpecimens       valid specimens per AP loading and material, closest to
%                        the group median (default 13; Inf = all)
%
%   Example
%     plotFractureToughness(Dimensions="matched", ShowFigures=true)

arguments
    opts.ProcessedFile     (1,1) string = ""
    opts.OutputFolder      (1,1) string = ""
    opts.PDFFolder         (1,1) string = ""
    opts.ResultsFile       (1,1) string = ""
    opts.Dimensions        (1,1) string = "section average"
    opts.ValidAOverW       (1,2) double = [0.2 0.8]
    opts.Materials         (1,:) string = ["CNT", "NEAT"]
    opts.ShowFigures       (1,1) logical = false
    opts.IncludeDuplicates (1,1) logical = false
    opts.NumSpecimens      (1,1) double {mustBePositive} = 13
end

p = pipelinePaths();
if opts.ProcessedFile == "", opts.ProcessedFile = p.ProcessedFile;                                   end
if opts.OutputFolder  == "", opts.OutputFolder  = fullfile(p.Figures, 'Fracture');                    end
if opts.ResultsFile   == "", opts.ResultsFile   = fullfile(p.ProcessedDir, 'Fracture_Toughness.xlsx'); end

dimsMode = lower(strtrim(opts.Dimensions));
if ~ismember(dimsMode, ["section average", "matched"])
    error('toughness:dimensions', 'Dimensions must be "section average" or "matched".');
end

% Every specimen here; the NumSpecimens are picked from the valid ones below
specimens = loadSpecimens(opts.ProcessedFile, "Fracture", opts.IncludeDuplicates, Inf, false);
specimens = specimens(ismember(specimens.Material, opts.Materials), :);
if height(specimens) == 0
    warning('toughness:noData', 'No usable fracture specimens.');
    results = table();
    return;
end

%% ------------------------------------------------------------ K and G per specimen
W = specimens.Width_mm;
B = specimens.Thickness_mm;
a = specimens.NotchLength_mm + specimens.PreCrackLength_mm;

if dimsMode == "section average"
    g = findgroups(specimens.Year, specimens.Batch, specimens.Group, specimens.Material);
    W = groupMean(W, g);
    B = groupMean(B, g);
    a = groupMean(a, g);
end

alpha = a ./ W;
f = NaN(size(alpha));
inRange = alpha > 0 & alpha < 1;                 % outside this the factor is undefined
al = alpha(inRange);
f(inRange) = (2 + al) .* (0.886 + 4.64 * al - 13.32 * al.^2 + 14.72 * al.^3 - 5.6 * al.^4) ...
             ./ (1 - al).^1.5;

K = specimens.PeakForce_N ./ ((B / 1000) .* sqrt(W / 1000)) .* f / 1e6;     % MPa m^0.5
G = specimens.Energy_J ./ ((B / 1000) .* ((W - a) / 1000)) / 1000;          % kJ/m^2
G(~(W > a)) = NaN;

widthToThickness = W ./ B;
valid = isfinite(K) & isfinite(G) & alpha > opts.ValidAOverW(1) & alpha < opts.ValidAOverW(2) & ...
        widthToThickness >= 2 & widthToThickness <= 4;

% The NumSpecimens closest to the median, picked among valid specimens
inSelection = false(height(specimens), 1);
if any(valid)
    kept = selectSpecimens(specimens(valid, :), "Fracture", opts.NumSpecimens, true);
    inSelection = ismember(specimens.SpecimenID, kept.SpecimenID);
end

if dimsMode == "section average"
    dimSource = repmat("section average", height(specimens), 1);
else
    dimSource = specimens.DimensionSource;
end

results = table( ...
    specimens.SpecimenID, specimens.APRatio_pct, specimens.Year, specimens.Material, ...
    specimens.Batch, specimens.Day, specimens.Group, specimens.SampleName, ...
    W, B, a, alpha, widthToThickness, specimens.PeakForce_N, specimens.Energy_J, K, G, ...
    valid, inSelection, dimSource, specimens.FilePath, ...
    'VariableNames', {'SpecimenID', 'APRatio_pct', 'Year', 'Material', ...
                      'Batch', 'Day', 'Group', 'Sample', ...
                      'Width_mm', 'Thickness_mm', 'CrackLength_mm', 'a_over_W', 'W_over_B', ...
                      'PeakForce_N', 'Energy_J', 'KIc_MPa_sqrtm', 'GIc_kJ_per_m2', ...
                      'Valid', 'InSelection', 'Dimensions', 'FilePath'});
results = sortrows(results, {'APRatio_pct', 'Material', 'SpecimenID'});

%% ------------------------------------------------------------ summary per AP and material
ok = results(results.Valid & results.InSelection, :);
groups = unique(results(:, {'APRatio_pct', 'Year', 'Material'}));
groups = sortrows(groups, {'APRatio_pct', 'Material'});
nG = height(groups);

[meanK, sdK, nK] = deal(NaN(nG, 1), NaN(nG, 1), zeros(nG, 1));
[meanG, sdG, nGv] = deal(NaN(nG, 1), NaN(nG, 1), zeros(nG, 1));
for i = 1:nG
    rows = ok.Year == groups.Year(i) & ok.Material == groups.Material(i);
    [meanK(i), sdK(i), nK(i)]  = meanSD(ok.KIc_MPa_sqrtm(rows));
    [meanG(i), sdG(i), nGv(i)] = meanSD(ok.GIc_kJ_per_m2(rows));
end

summary = [groups, table(meanK, sdK, nK, meanG, sdG, nGv, ...
    'VariableNames', {'MeanKIc_MPa_sqrtm', 'SDKIc_MPa_sqrtm', 'NumberK', ...
                      'MeanGIc_kJ_per_m2', 'SDGIc_kJ_per_m2', 'NumberG'})];

fprintf('\nFracture toughness (up to %g valid specimens per group, dimensions: %s)\n', ...
    opts.NumSpecimens, dimsMode);
fprintf('  AP %%   Year  Material   K_Ic (MPa m^0.5)      G_Ic (kJ/m^2)\n');
for i = 1:nG
    fprintf('  %4g   %4d  %-8s  %6.3f +/- %5.3f (%2d)   %6.3f +/- %5.3f (%2d)\n', ...
        groups.APRatio_pct(i), groups.Year(i), groups.Material(i), ...
        meanK(i), sdK(i), nK(i), meanG(i), sdG(i), nGv(i));
end
fprintf('  %d of %d specimens invalid (a/W outside %.2f-%.2f, W/B outside 2-4, or no dimensions)\n\n', ...
    sum(~results.Valid), height(results), opts.ValidAOverW(1), opts.ValidAOverW(2));

%% ------------------------------------------------------------ write workbook
resultsDir = fileparts(opts.ResultsFile);
if ~isfolder(resultsDir), mkdir(resultsDir); end
if isfile(opts.ResultsFile)
    delete(opts.ResultsFile);
    if isfile(opts.ResultsFile)
        error('toughness:locked', 'Close %s in Excel and run again.', opts.ResultsFile);
    end
end
writetable(results, opts.ResultsFile, 'Sheet', 'All Specimens');
writetable(summary, opts.ResultsFile, 'Sheet', 'Summary');

%% ------------------------------------------------------------ figures
fo = struct('Materials', opts.Materials, 'ShowFigures', opts.ShowFigures, ...
            'YLabel', 'K_{Ic} (MPa\cdotm^{1/2})', ...
            'Title', "", ...
            'ValueLabel', "K_Ic (MPa m^0.5)", ...
            'OutFile', fullfile(opts.OutputFolder, 'Fracture_KIc_vs_AP.png'), ...
            'PDFFile', "");
if opts.PDFFolder ~= ""
    fo.PDFFile = fullfile(opts.PDFFolder, 'Fracture_KIc_vs_AP.pdf');
end
fileK = plotMetricVsAP(ok, 'KIc_MPa_sqrtm', summary, 'MeanKIc_MPa_sqrtm', 'SDKIc_MPa_sqrtm', fo);

fo.YLabel     = 'G_{Ic} (kJ/m^2)';
fo.ValueLabel = "G_Ic (kJ/m^2)";
fo.OutFile    = fullfile(opts.OutputFolder, 'Fracture_GIc_vs_AP.png');
if opts.PDFFolder ~= ""
    fo.PDFFile = fullfile(opts.PDFFolder, 'Fracture_GIc_vs_AP.pdf');
end
fileG = plotMetricVsAP(ok, 'GIc_kJ_per_m2', summary, 'MeanGIc_kJ_per_m2', 'SDGIc_kJ_per_m2', fo);

fprintf('Saved %s\nSaved %s\nSaved %s\n', fileK, fileG, opts.ResultsFile);
end

%% ========================================================================
function x = groupMean(x, g)
% Replace every value by the mean of its group
m = splitapply(@(v) mean(v, 'omitnan'), x, g);
x = m(g);
end

function [m, s, n] = meanSD(v)
v = v(isfinite(v));
n = numel(v);
m = NaN;
s = NaN;
if n >= 1
    m = mean(v);
end
if n >= 2
    s = std(v);                 % sample SD (N-1)
end
end
