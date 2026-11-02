function figureFiles = plotTension(opts)
%PLOTTENSION Tension stress-strain figures, one per AP loading per material.
%
%   plotTension()                     uses the default processed workbook
%   plotTension(Name=Value)           see options below
%
%   Reads only the workbook made by prepareData (Specimens + Tension sheets).
%   Saves  <repo>/Figures/Tension/Tension_AP<ratio>_<year>_<CNT|NEAT>.png
%   e.g.   Tension_AP40_2024_CNT.png. Year -> AP % is set in private/apRatio.m.
%
%   Options
%     ProcessedFile workbook to read (default <repo>/ProcessedData/JuniorLab_ProcessedData.xlsx)
%     OutputFolder  where the PNGs go (default <repo>/Figures/Tension)
%     StrainLimit   x-axis upper limit (default 0.03; the old 0.015 hid the
%                   failure point of the more ductile coupons)
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
%     plotTension(StrainLimit=0.02, Years=2026, ShowFigures=true)

arguments
    opts.ProcessedFile (1,1) string = ""
    opts.OutputFolder  (1,1) string = ""
    opts.StrainLimit   (1,1) double {mustBePositive} = 0.03
    opts.YLimit        double = []
    opts.APRatios      double = []
    opts.Years         double = []
    opts.Materials     (1,:) string = ["CNT", "NEAT"]
    opts.ShowFigures   (1,1) logical = false
    opts.IncludeDuplicates (1,1) logical = false
end

p = pipelinePaths();
if opts.ProcessedFile == "", opts.ProcessedFile = p.ProcessedFile;               end
if opts.OutputFolder == "", opts.OutputFolder = fullfile(p.Figures, 'Tension'); end

figureFiles = plotStressStrainByYear("Tension", opts.ProcessedFile, opts);
end
