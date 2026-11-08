clear; clc; close all;

%% ==========================================================
%% Quick raw plots — Force vs Displacement, no processing
%% One figure per test (Compression, Tension, Fracture)
%% Every run from every year overlaid, one color per year
%% No legend, tight x/y bounds, large figures
%% Run this script from inside Junior_Lab_Repo2
%% Folder/file conventions follow data_process_and_plot2.m
%% ==========================================================

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
        for i = 1:numel(files)
            data = readRaw(fullfile(files(i).folder, files(i).name));
            if size(data,2) < 3, continue; end

            d = data(:,2);   % Displacement (mm)
            f = data(:,3);   % Force (N)
            ok = ~isnan(d) & ~isnan(f);
            if ~any(ok), continue; end

            plot(ax, d(ok), f(ok), 'Color', yearColors(y,:), ...
                'LineWidth', 1);
            nPlotted = nPlotted + 1;
        end

        fprintf('%s %s: %d runs plotted\n', yearName, testName, nPlotted);
    end

    axis(ax, 'tight');
    xlabel(ax, 'Displacement (mm)', 'FontWeight','bold', 'FontSize', 20);
    ylabel(ax, 'Force (N)', 'FontWeight','bold', 'FontSize', 20);
    title(ax, sprintf('%s — Raw, All Years', testName), 'FontSize', 22);

    exportgraphics(fig, fullfile(outFolder, ...
        sprintf('%s_AllYears_Raw.png', testName)), 'Resolution', 300);
end

fprintf('\nDone. Plots saved to:\n%s\n', outFolder);

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
