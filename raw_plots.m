clear; clc; close all;

%% ==========================================================
%% Quick raw plots — Force vs Displacement, no processing
%% One figure per test (Compression, Tension, Fracture)
%% Every run from every year overlaid, one color per year
%% Fracture curves start-aligned to origin (others raw)
%% No legend, tight x/y bounds, large figures
%% Run this script from inside Junior_Lab_Repo2
%% Folder/file conventions follow data_process_and_plot2.m
%% ==========================================================

%% ==========================================================
%% USER SETTINGS — x-axis limits [min max] in mm
%% Leave as [] to use tight auto bounds
%% If set, any run with displacement outside [min max] is removed
%% ==========================================================
xLims.Compression = [];       % e.g. [0 3]
xLims.Tension     = [];       % e.g. [0 1.5]
xLims.Fracture    = [];       % e.g. [0 3.5]

organizedFolder = fullfile(pwd, 'OrganizedData');
outFolder = fullfile(organizedFolder, 'Raw_Plots');
if ~isfolder(outFolder), mkdir(outFolder); end

tests = {'Compression','Tension','Fracture'};

yearDirs = dir(fullfile(organizedFolder, '*_organized'));
yearDirs = yearDirs([yearDirs.isdir]);

yearColors = lines(numel(yearDirs));   % one color per year

for t = 1:numel(tests)

    testName = tests{t};

    fig = figure('Units','normalized','Position',[0 0 1 1]);  % full screen
    ax = axes(fig); hold(ax,'on'); grid(ax,'on'); box(ax,'on');
    set(ax, 'FontSize', 16, 'LineWidth', 1.2);

    for y = 1:numel(yearDirs)

        yearName = erase(yearDirs(y).name, '_organized');
        yearFolder = fullfile(organizedFolder, yearDirs(y).name);

        % All CSVs under batch*/<day>/<group>/...
        csvFiles = dir(fullfile(yearFolder, 'batch*', '**', '*.csv'));
        namesUpper = upper(string({csvFiles.name}));

        % Same filename rules as data_process_and_plot2.m
        switch testName
            case 'Compression'
                keep = contains(namesUpper, "COMPRESSION");
            case 'Tension'
                keep = contains(namesUpper, "TENSION") & ...
                       ~contains(namesUpper, "FRACTURE");
            case 'Fracture'
                keep = contains(namesUpper, "FRACTURE");
        end
        files = csvFiles(keep);

        nPlotted = 0;
        nRemoved = 0;
        for i = 1:numel(files)
            data = readRaw(fullfile(files(i).folder, files(i).name));
            if size(data,2) < 3, continue; end

            d = data(:,2);   % Displacement (mm)
            f = data(:,3);   % Force (N)
            ok = ~isnan(d) & ~isnan(f);
            if ~any(ok), continue; end
            d = d(ok); f = f(ok);

            % Fracture: align loading start to origin
            if strcmpi(testName,'Fracture')
                [d, f, aligned] = alignFractureStart(d, f);
                if ~aligned, continue; end
            end

            % Remove runs that go beyond the user x-limits
            lim = xLims.(testName);
            if ~isempty(lim) && (min(d) < lim(1) || max(d) > lim(2))
                nRemoved = nRemoved + 1;
                continue;
            end

            plot(ax, d, f, 'Color', yearColors(y,:), ...
                'LineWidth', 1);
            nPlotted = nPlotted + 1;
        end

        fprintf('%s %s: %d runs plotted, %d removed (outside x-limits)\n', ...
            yearName, testName, nPlotted, nRemoved);
    end

    axis(ax, 'tight');
    if ~isempty(xLims.(testName))
        xlim(ax, xLims.(testName));
    end
    xlabel(ax, 'Displacement (mm)', 'FontWeight','bold', 'FontSize', 20);
    ylabel(ax, 'Force (N)', 'FontWeight','bold', 'FontSize', 20);
    title(ax, sprintf('%s — Raw, All Years', testName), 'FontSize', 22);

    exportgraphics(fig, fullfile(outFolder, ...
        sprintf('%s_AllYears_Raw.png', testName)), 'Resolution', 300);
end

fprintf('\nDone. Plots saved to:\n%s\n', outFolder);

%% ==========================================================
%% Align fracture loading start (same start-detection steps as
%% data_process_and_plot2.m; no end cropping or outlier rejection)
%% ==========================================================
function [d, f, ok] = alignFractureStart(d, f)
    ok = false;

    peakForce = max(f);
    if isempty(peakForce) || isnan(peakForce) || peakForce <= 0
        return;
    end

    % Coarse trim: first point at 5% of peak
    i0 = find(f >= 0.05 * peakForce, 1, 'first');
    if isempty(i0), return; end
    d = d(i0:end); f = f(i0:end);

    % Sustained loading slope: >= 50 N/mm for 15 consecutive points
    fSmooth = movmean(f, 25);
    dFdx = gradient(fSmooth, d);
    sustained = movsum(dFdx >= 50, 15) >= 15;
    i1 = find(sustained, 1, 'first');
    if isempty(i1), i1 = 1; end
    i1 = max(1, i1 - 3);            % 3-point padding
    d = d(i1:end); f = f(i1:end);

    % Shift to origin, clamp noise negatives
    d = d - d(1);
    f = f - f(1);
    d(d < 0) = 0;
    f(f < 0) = 0;

    ok = true;
end

%% ==========================================================
%% Read CSV (header + units rows skipped) as numeric matrix
%% ==========================================================
function data = readRaw(filePath)
    opts = detectImportOptions(filePath);
    opts.DataLines = [3 Inf];
    T = readtable(filePath, opts);

    data = NaN(height(T), width(T));
    for c = 1:width(T)
        col = T{:,c};
        if isnumeric(col)
            data(:,c) = col;
        else
            data(:,c) = str2double(string(col));
        end
    end
end
