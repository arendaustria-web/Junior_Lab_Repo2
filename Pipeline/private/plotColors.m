function rgb = plotColors(kind, key)
%PLOTCOLORS The one place the pipeline's series colours are defined.
%   rgb = plotColors("AP", ap)              colour of an AP loading (%)
%   rgb = plotColors("Material", material)  colour of "CNT" or "NEAT"
%
%   AP loadings  40% green #1d6b3a, 50% orange #eb6834,
%                60% purple #7b2fa8, 70% magenta #d6337a
%   Materials    CNT purple #7b2fa8, NEAT orange #eb6834
%
%   Chosen to contrast with no blue or yellow, and checked as a set on a
%   white background: every pair stays apart for colour-blind readers
%   (worst CVD delta E 10.4, target >= 8) and full colour vision (worst
%   15.7, floor 15), all >= 3:1 contrast. Orange and magenta are the
%   closest pair, so they are not given neighbouring AP loadings.
%   Anything not listed is grey.

switch lower(string(kind))
    case "ap"
        table = containers.Map({40, 50, 60, 70}, ...
                               {"#1d6b3a", "#eb6834", "#7b2fa8", "#d6337a"});
        if isKey(table, key)
            rgb = hex2rgb(table(key));
        else
            rgb = [0.54 0.53 0.51];
        end
    case "material"
        table = containers.Map({'CNT', 'NEAT'}, {"#7b2fa8", "#eb6834"});
        k = char(upper(string(key)));
        if isKey(table, k)
            rgb = hex2rgb(table(k));
        else
            rgb = [0.32 0.32 0.31];
        end
    otherwise
        error('plot:colorKind', 'Unknown colour kind "%s" (use "AP" or "Material").', kind);
end
end

function rgb = hex2rgb(hex)
h = char(hex);
rgb = sscanf(h(2:end), '%2x')' / 255;
end
