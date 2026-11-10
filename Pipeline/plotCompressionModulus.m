function results = plotCompressionModulus(opts)
%PLOTCOMPRESSIONMODULUS Compression modulus vs AP loading.
%
%   results = plotCompressionModulus()
%   results = plotCompressionModulus(Name=Value)
%
%   plotYoungsModulus("Compression", ...) with the original file names:
%     <repo>/Figures/Compression/Compression_Modulus_vs_AP.png
%     <repo>/ProcessedData/Compression_Modulus.xlsx
%   See plotYoungsModulus for the method and the options (all of them can
%   be passed here).
%
%   Example
%     plotCompressionModulus(NumSpecimens=Inf, ShowFigures=true)

arguments
    opts.ProcessedFile     (1,1) string = ""
    opts.OutputFolder      (1,1) string = ""
    opts.PDFFolder         (1,1) string = ""
    opts.ResultsFile       (1,1) string = ""
    opts.FileName          (1,1) string = "Compression_Modulus_vs_AP"
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

if opts.ResultsFile == ""
    p = pipelinePaths();
    opts.ResultsFile = fullfile(p.ProcessedDir, 'Compression_Modulus.xlsx');
end

args = namedargs2cell(opts);
results = plotYoungsModulus("Compression", args{:});
end
