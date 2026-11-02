function figureFiles = plotCompression(opts)
%PLOTCOMPRESSION Compression stress-strain figures, one per AP loading per material.
%
%   plotCompression()                 uses the default processed workbook
%   plotCompression(Name=Value)       see options below
%
%   Reads only the workbook made by prepareData (Specimens + Compression sheets).
%   Saves  <repo>/Figures/Compression/Compression_AP<ratio>_<year>_<CNT|NEAT>.png
%   e.g.   Compression_AP40_2024_CNT.png. Year -> AP % is set in private/apRatio.m.
%
%   Options
%     ProcessedFile workbook to read (default <repo>/ProcessedData/JuniorLab_ProcessedData.xlsx)
%     OutputFolder  where the PNGs go (default <repo>/Figures/Compression)
%     StrainLimit   x-axis upper limit (default 0.35, same as the old script)
%     YLimit        [ymin ymax] in MPa; [] = automatic (default)
%     APRatios      e.g. [40 70]; [] = every AP loading in the workbook
%     Years         e.g. [2025 2026]; [] = every year in the workbook
%     Materials     default ["CNT","NEAT"]
%     ShowFigures   true keeps the figures open so you can hover curves to
%                   identify specimens (default false)
%     IncludeDuplicates  true also plots CSVs flagged as copies of another
%                   specimen (DuplicateOf in the Specimens sheet; default false)
%
%   Example
%     plotCompression(APRatios=50, Materials="CNT", ShowFigures=true)

arguments
    opts.ProcessedFile (1,1) string = ""
    opts.OutputFolder  (1,1) string = ""
    opts.StrainLimit   (1,1) double {mustBePositive} = 0.35
    opts.YLimit        double = []
    opts.APRatios      double = []
    opts.Years         double = []
    opts.Materials     (1,:) string = ["CNT", "NEAT"]
    opts.ShowFigures   (1,1) logical = false
    opts.IncludeDuplicates (1,1) logical = false
end

p = pipelinePaths();
if opts.ProcessedFile == "", opts.ProcessedFile = p.ProcessedFile;                   end
if opts.OutputFolder == "", opts.OutputFolder = fullfile(p.Figures, 'Compression'); end

figureFiles = plotStressStrainByYear("Compression", opts.ProcessedFile, opts);
end
