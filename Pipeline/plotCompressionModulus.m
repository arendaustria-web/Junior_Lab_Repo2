function results = plotCompressionModulus(opts)
%PLOTCOMPRESSIONMODULUS Compression modulus vs AP loading.
%
%   results = plotCompressionModulus()
%   results = plotCompressionModulus(Name=Value)
%
%   For every usable compression specimen in the processed workbook:
%     E = slope of a straight-line fit of stress vs strain over FitWindow
%   (same method and limits as the old calculateYoungsModulusResults).
%   A fit counts only when it has at least MinFitPoints points and
%   R^2 >= MinRSquared.
%
%   Saves
%     <repo>/Figures/Compression/Compression_Modulus_vs_AP.png
%         x = AP % (40, 50, 60, 70; year in brackets), y = modulus.
%         Dots = accepted specimens, line + bars = mean +/- 1 SD,
%         CNT and NEAT side by side at each AP loading.
%     <repo>/ProcessedData/Compression_Modulus.xlsx
%         "All Specimens"  every fit, accepted or not, with R^2 and points
%         "Summary"        mean, SD, n, min, max per AP loading and material
%
%   Options
%     ProcessedFile      workbook from prepareData (default location)
%     OutputFolder       where the PNG goes (default <repo>/Figures/Compression)
%     ResultsFile        modulus workbook (default above)
%     FitWindow          [start end] strain for the fit (default [0.002 0.010])
%     MinFitPoints       default 8
%     MinRSquared        default 0.90
%     Materials          default ["CNT","NEAT"]
%     ShowFigures        keep the figure open (default false)
%     IncludeDuplicates  also use CSVs flagged as copies (default false)
%
%   Example
%     plotCompressionModulus(FitWindow=[0.005 0.015], ShowFigures=true)

arguments
    opts.ProcessedFile     (1,1) string = ""
    opts.OutputFolder      (1,1) string = ""
    opts.ResultsFile       (1,1) string = ""
    opts.FitWindow         (1,2) double = [0.002 0.010]
    opts.MinFitPoints      (1,1) double = 8
    opts.MinRSquared       (1,1) double = 0.90
    opts.Materials         (1,:) string = ["CNT", "NEAT"]
    opts.ShowFigures       (1,1) logical = false
    opts.IncludeDuplicates (1,1) logical = false
end

p = pipelinePaths();
if opts.ProcessedFile == "", opts.ProcessedFile = p.ProcessedFile;                          end
if opts.OutputFolder  == "", opts.OutputFolder  = fullfile(p.Figures, 'Compression');        end
if opts.ResultsFile   == "", opts.ResultsFile   = fullfile(p.ProcessedDir, 'Compression_Modulus.xlsx'); end

[specimens, curves] = loadSpecimens(opts.ProcessedFile, "Compression", opts.IncludeDuplicates);
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

for i = 1:n
    r = specimens.CurveRows{i};
    [E(i), R2(i), nPt(i)] = fitModulus(curves.Strain(r), curves.Stress_MPa(r), opts.FitWindow);
end

accepted = isfinite(E) & E > 0 & isfinite(R2) & ...
           R2 >= opts.MinRSquared & nPt >= opts.MinFitPoints;

results = table( ...
    specimens.SpecimenID, specimens.APRatio_pct, specimens.Year, specimens.Material, ...
    specimens.Batch, specimens.Day, specimens.Group, specimens.SampleName, ...
    E, R2, nPt, ...
    repmat(opts.FitWindow(1), n, 1), repmat(opts.FitWindow(2), n, 1), ...
    accepted, specimens.FilePath, ...
    'VariableNames', {'SpecimenID', 'APRatio_pct', 'Year', 'Material', ...
                      'Batch', 'Day', 'Group', 'Sample', ...
                      'Modulus_MPa', 'RSquared', 'NumberFitPoints', ...
                      'FitStartStrain', 'FitEndStrain', 'FitAccepted', 'FilePath'});
results = sortrows(results, {'APRatio_pct', 'Material', 'SpecimenID'});

%% ------------------------------------------------------------ summary per AP and material
ok = results(results.FitAccepted, :);
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
    'VariableNames', {'MeanModulus_MPa', 'SD_MPa', 'NumberAccepted', ...
                      'MinModulus_MPa', 'MaxModulus_MPa'})];

fprintf('\nCompression modulus (accepted fits)\n');
fprintf('  AP %%   Year  Material   mean (MPa)   SD (MPa)   n\n');
for g = 1:nG
    fprintf('  %4g   %4d  %-8s  %10.1f  %9.1f  %3d\n', groups.APRatio_pct(g), ...
        groups.Year(g), groups.Material(g), meanE(g), sdE(g), nE(g));
end
fprintf('  %d of %d fits rejected (R^2 < %.2f or < %d points in the window)\n\n', ...
    sum(~results.FitAccepted), n, opts.MinRSquared, opts.MinFitPoints);

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
if ~isfolder(opts.OutputFolder), mkdir(opts.OutputFolder); end
if opts.ShowFigures, vis = 'on'; else, vis = 'off'; end

fig = figure('Visible', vis, 'Color', 'w', 'Units', 'pixels', 'Position', [100 100 1000 650]);
ax = axes(fig);
hold(ax, 'on'); grid(ax, 'on'); box(ax, 'on');

matColors = [0.000 0.447 0.741;     % first material  (CNT)  blue
             0.850 0.325 0.098];    % second material (NEAT) orange
nMat = numel(opts.Materials);
offsets = linspace(-1.2, 1.2, nMat);  % x shift in AP-% units so materials sit side by side
if nMat == 1, offsets = 0; end

handles = gobjects(0);
labels  = strings(0);

for m = 1:nMat
    mat   = opts.Materials(m);
    color = matColors(min(m, size(matColors, 1)), :);

    % individual accepted specimens, spread slightly so they don't overlap
    pts = ok(ok.Material == mat & isfinite(ok.APRatio_pct), :);
    if height(pts) > 0
        jitter = zeros(height(pts), 1);
        for a = unique(pts.APRatio_pct)'
            k = find(pts.APRatio_pct == a);
            if numel(k) > 1
                jitter(k) = linspace(-0.6, 0.6, numel(k));
            end
        end
        hs = scatter(ax, pts.APRatio_pct + offsets(m) + jitter, pts.Modulus_MPa, 36, ...
            color, 'filled', 'MarkerFaceAlpha', 0.35);
        hs.DataTipTemplate.DataTipRows(1).Label = "AP %";
        hs.DataTipTemplate.DataTipRows(2).Label = "E (MPa)";
        hs.DataTipTemplate.DataTipRows(end+1) = dataTipTextRow("File", cellstr(pts.FilePath));
    end

    % mean +/- 1 SD
    s = summary(summary.Material == mat & isfinite(summary.MeanModulus_MPa) & ...
                isfinite(summary.APRatio_pct), :);
    if height(s) > 0
        sd = s.SD_MPa;
        sd(~isfinite(sd)) = 0;    % single specimen: no bar
        he = errorbar(ax, s.APRatio_pct + offsets(m), s.MeanModulus_MPa, sd, 'o-', ...
            'Color', color, 'LineWidth', 2.2, 'MarkerSize', 8, ...
            'MarkerFaceColor', color, 'CapSize', 12);
        handles(end+1) = he;                                         %#ok<AGROW>
        labels(end+1)  = mat + " mean " + char(177) + " 1 SD";      %#ok<AGROW>
    end
end

% x axis: AP %, with the year underneath for traceability
map = apRatio();
map = map(ismember(map(:, 1), results.Year), :);
xticks(ax, map(:, 2));
xticklabels(ax, compose("%g%% (%d)", map(:, 2), map(:, 1)));
if ~isempty(map)
    xlim(ax, [min(map(:, 2)) - 5, max(map(:, 2)) + 5]);
end
ylim(ax, [0 Inf]);

xlabel(ax, 'AP loading (%)  (sample year)', 'FontWeight', 'bold', 'FontSize', 16);
ylabel(ax, 'Compression modulus (MPa)', 'FontWeight', 'bold', 'FontSize', 16);
title(ax, sprintf('Compression Modulus vs AP Loading  (fit %.3g-%.3g strain)', ...
      opts.FitWindow(1), opts.FitWindow(2)), 'FontSize', 18);
ax.FontSize = 13;
if ~isempty(handles)
    legend(ax, handles, cellstr(labels), 'Location', 'best', 'FontSize', 12);
end

outFile = fullfile(opts.OutputFolder, 'Compression_Modulus_vs_AP.png');
exportgraphics(fig, outFile, 'Resolution', 300);
fprintf('Saved %s\nSaved %s\n', outFile, opts.ResultsFile);

if ~opts.ShowFigures
    close(fig);
end
end

%% ========================================================================
function [E, R2, nPoints] = fitModulus(strain, stress, window)
% Least-squares line stress = E*strain + b over the strain window.
E = NaN; R2 = NaN;
strain = strain(:); stress = stress(:);
in = isfinite(strain) & isfinite(stress) & strain >= window(1) & strain <= window(2);
x = strain(in); y = stress(in);
nPoints = numel(x);
if nPoints < 2
    return;
end
c = polyfit(x, y, 1);
E = c(1);
ssRes = sum((y - polyval(c, x)).^2);
ssTot = sum((y - mean(y)).^2);
if ssTot > 0
    R2 = 1 - ssRes / ssTot;
end
end
