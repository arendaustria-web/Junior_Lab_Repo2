function exportJuniorLab(opts)
%EXPORTJUNIORLAB Young's modulus and fracture toughness exports from the 13 selected specimens.
%
%   exportJuniorLab()
%   exportJuniorLab(Name=Value)
%
%   Writes, in <repo>/JuniorLabExports:
%     Youngs_Modulus/
%       PNG/Compression_Youngs_Modulus_vs_AP.png, Tension_Youngs_Modulus_vs_AP.png
%       PDF/  the same figures as vector PDFs
%       Compression_Youngs_Modulus.xlsx, Tension_Youngs_Modulus.xlsx
%     Fracture_GIc_KIc/
%       PNG/Fracture_KIc_vs_AP.png, Fracture_GIc_vs_AP.png
%       PDF/  the same figures as vector PDFs
%       Fracture_GIc_KIc.xlsx
%   Each workbook has a "Summary" sheet (mean, SD, n per AP loading and
%   material) and an "All Specimens" sheet with an InSelection column.
%
%   Every value comes from the NumSpecimens valid specimens closest to the
%   median of their AP loading and material (private/selectSpecimens.m).
%   Methods: plotYoungsModulus (steepest straight window before the peak)
%   and plotFractureToughness (ASTM D5045 compact tension).
%
%   Options
%     ProcessedFile   workbook from prepareData (default location)
%     OutputFolder    default <repo>/JuniorLabExports
%     NumSpecimens    specimens per AP loading and material (default 13)
%     ShowFigures     keep the figures open (default false)

arguments
    opts.ProcessedFile (1,1) string = ""
    opts.OutputFolder  (1,1) string = ""
    opts.NumSpecimens  (1,1) double {mustBePositive} = 13
    opts.ShowFigures   (1,1) logical = false
end

p = pipelinePaths();
if opts.ProcessedFile == "", opts.ProcessedFile = p.ProcessedFile;                     end
if opts.OutputFolder  == "", opts.OutputFolder  = fullfile(p.Root, 'JuniorLabExports'); end

modulusDir  = fullfile(opts.OutputFolder, 'Youngs_Modulus');
fractureDir = fullfile(opts.OutputFolder, 'Fracture_GIc_KIc');

for testName = ["Compression", "Tension"]
    plotYoungsModulus(testName, ...
        'ProcessedFile', opts.ProcessedFile, ...
        'OutputFolder',  fullfile(modulusDir, 'PNG'), ...
        'PDFFolder',     fullfile(modulusDir, 'PDF'), ...
        'ResultsFile',   fullfile(modulusDir, testName + "_Youngs_Modulus.xlsx"), ...
        'NumSpecimens',  opts.NumSpecimens, ...
        'ShowFigures',   opts.ShowFigures);
end

plotFractureToughness( ...
    'ProcessedFile', opts.ProcessedFile, ...
    'OutputFolder',  fullfile(fractureDir, 'PNG'), ...
    'PDFFolder',     fullfile(fractureDir, 'PDF'), ...
    'ResultsFile',   fullfile(fractureDir, 'Fracture_GIc_KIc.xlsx'), ...
    'NumSpecimens',  opts.NumSpecimens, ...
    'ShowFigures',   opts.ShowFigures);

fprintf('\nJunior Lab exports are in %s\n', opts.OutputFolder);
end
