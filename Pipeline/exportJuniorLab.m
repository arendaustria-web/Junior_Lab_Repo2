function exportJuniorLab(opts)
%EXPORTJUNIORLAB Young's modulus, fracture toughness and AP comparison exports.
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
%     AP_Comparison/
%       Tension/PNG, Tension/PDF          <Test>_<CNT|NEAT>_AP_Comparison
%       Compression/PNG, Compression/PDF  (every AP loading on one plot, mean
%       Fracture/PNG, Fracture/PDF         curve ending at the mean fracture point)
%   Each workbook has a "Summary" sheet (mean, SD, n per AP loading and
%   material) and an "All Specimens" sheet with an InSelection column.
%
%   Modulus and toughness values come from the valid specimens closest to
%   the median of their AP loading and material (private/selectSpecimens.m):
%   13 per group for Young's modulus, 54 for fracture
%   (private/specimensPerGroup.m). The AP comparison figures use 54 per
%   group for fracture and every specimen for tension and compression.
%   Methods: plotYoungsModulus (steepest straight window before the peak),
%   plotFractureToughness (ASTM D5045 compact tension) and plotAPComparison.
%
%   Options
%     ProcessedFile   workbook from prepareData (default location)
%     OutputFolder    default <repo>/JuniorLabExports
%     NumSpecimens    specimens per AP loading and material for the modulus
%                     and toughness results (default from
%                     private/specimensPerGroup.m: modulus 13, fracture 54)
%     ShowFigures     keep the figures open (default false)

arguments
    opts.ProcessedFile (1,1) string = ""
    opts.OutputFolder  (1,1) string = ""
    opts.NumSpecimens  double {mustBePositive} = []
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

plotAPComparison( ...
    'ProcessedFile', opts.ProcessedFile, ...
    'OutputFolder',  fullfile(opts.OutputFolder, 'AP_Comparison'), ...
    'ShowFigures',   opts.ShowFigures);

fprintf('\nJunior Lab exports are in %s\n', opts.OutputFolder);
end
