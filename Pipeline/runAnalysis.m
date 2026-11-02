%% Junior Lab analysis: run this file top to bottom
%
%  Folder layout
%    Pipeline/                 code (this file + the functions below)
%      prepareData.m           OrganizedData CSVs  ->  processed workbook
%      plotTension.m           processed workbook  ->  Figures/Tension
%      plotCompression.m       processed workbook  ->  Figures/Compression
%      plotCompressionModulus.m processed workbook ->  modulus vs AP figure + xlsx
%      private/apRatio.m       year -> AP loading (2024 40%, 2025 50%, 2023 60%, 2026 70%)
%      private/                helpers used by the functions above
%    ProcessedData/
%      JuniorLab_ProcessedData.xlsx   (made by prepareData)
%      Compression_Modulus.xlsx       (made by plotCompressionModulus)
%    Figures/
%      Tension/Tension_AP<ratio>_<year>_<CNT|NEAT>.png
%      Compression/Compression_AP<ratio>_<year>_<CNT|NEAT>.png
%      Compression/Compression_Modulus_vs_AP.png
%
%  The plotting functions read ONLY the processed workbook. Run prepareData
%  again only when the raw data or SpecimenDimensions workbooks change.
%  Type "help prepareData" (or plotTension / plotCompression) for options.

clear; clc; close all;

pipelineFolder = fileparts(mfilename('fullpath'));
addpath(pipelineFolder);

rebuildProcessedData = true;    % false = reuse the existing workbook

%% 1) Data preparation
if rebuildProcessedData
    processedFile = prepareData();
else
    processedFile = fullfile(fileparts(pipelineFolder), ...
        'ProcessedData', 'JuniorLab_ProcessedData.xlsx');
end

%% 2) Tension figures
plotTension('ProcessedFile', processedFile);

%% 3) Compression figures
plotCompression('ProcessedFile', processedFile);

%% 4) Compression modulus vs AP loading
plotCompressionModulus('ProcessedFile', processedFile);

fprintf('\nAll figures are in %s\n', fullfile(fileparts(pipelineFolder), 'Figures'));
