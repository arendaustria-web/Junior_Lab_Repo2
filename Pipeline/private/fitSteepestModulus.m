function [E, R2, nPoints, xStart, xEnd] = fitSteepestModulus(strain, stress, opts)
%FITSTEEPESTMODULUS Modulus = slope of the steepest straight part before the peak.
%   [E, R2, nPoints, xStart, xEnd] = fitSteepestModulus(strain, stress, opts)
%
%   Toe-compensated, as in ASTM D695 / D638: windows slide along the curve
%   up to the peak, each spanning opts.FitStressSpan of the peak stress,
%   between opts.FitLower and opts.FitUpper of the peak. Each window is
%   fitted with stress = E*strain + b, and E is the steepest window with
%   R^2 >= opts.MinRSquared and at least opts.MinFitPoints points. Taking
%   the steepest straight window skips the seating (toe) region.
%   Returns NaN when no window qualifies.

E = NaN; R2 = NaN; nPoints = 0; xStart = NaN; xEnd = NaN;

strain = strain(:); stress = stress(:);
ok = isfinite(strain) & isfinite(stress);
strain = strain(ok); stress = stress(ok);
if numel(stress) < opts.MinFitPoints
    return;
end

[peak, peakIdx] = max(stress);
if ~(peak > 0)
    return;
end
strain = strain(1:peakIdx);
stress = stress(1:peakIdx);

for i = 1:numel(stress)
    if stress(i) < opts.FitLower * peak
        continue;
    end

    % extend the window until stress has risen by the span
    j = find(stress(i:end) - stress(i) >= opts.FitStressSpan * peak, 1, 'first');
    if isempty(j)
        break;
    end
    j = i + j - 1;

    x = strain(i:j);
    y = stress(i:j);
    if numel(x) < opts.MinFitPoints || max(y) > opts.FitUpper * peak
        continue;
    end

    c = polyfit(x, y, 1);
    ssTot = sum((y - mean(y)).^2);
    if ssTot <= 0
        continue;
    end
    r2 = 1 - sum((y - polyval(c, x)).^2) / ssTot;

    if r2 >= opts.MinRSquared && (~isfinite(E) || c(1) > E)
        E = c(1);
        R2 = r2;
        nPoints = numel(x);
        xStart = x(1);
        xEnd = x(end);
    end
end
end
