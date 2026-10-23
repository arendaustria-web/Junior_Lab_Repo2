clear
clc
close all

Mb = 1.5e6;              % Building mass (kg)
Kb = 15e6;               % Building stiffness (N/m)
zetab = 0.005;           % Building damping ratio
g = 9.81;                % Gravity (m/s^2)

Cb = 2*zetab*sqrt(Mb*Kb);

wn = sqrt(Kb/Mb);

fprintf('Natural frequency = %.4f rad/s\n',wn)
fprintf('Natural frequency = %.4f Hz\n',wn/(2*pi))
fprintf('Building damping = %.2f N*s/m\n\n',Cb)

om = linspace(0.1,6,5000);

% 1) 
Gnum = ones(size(om));

Gden = Kb - Mb*om.^2 + 1i*Cb*om;

XF = abs(Gnum./Gden);

[peakResponse,peakIndex] = max(XF);

wr = om(peakIndex);

fprintf('Theoretical natural frequency = %.4f rad/s\n',wn)
fprintf('Resonant peak frequency       = %.4f rad/s\n',wr)
fprintf('Peak response                 = %.4e m/N\n\n',peakResponse)

figure(1)

semilogy(om,XF,'LineWidth',2)

hold on

xline(wn,'--','\omega_n','LineWidth',1.5)

plot(wr,peakResponse,'o','MarkerSize',8,'LineWidth',2)

title('Frequency Response of Building',...
      'FontSize',24,...
      'FontName','Times New Roman')

xlabel('Frequency (rad/s)',...
       'FontSize',24,...
       'FontName','Times New Roman')

ylabel('|X/F| (m/N)',...
       'FontSize',24,...
       'FontName','Times New Roman')

grid on

set(gca,'FontSize',18,...
        'LineWidth',2,...
        'FontName','Times New Roman')

set(gcf,'Position',[50 50 1000 600])

% 2) 
ma = 0.01*Mb;            % Absorber mass
ca = 0;                  % No absorber damping

L = g/wn^2;

fprintf('Absorber mass = %.0f kg\n',ma)
fprintf('Tuned pendulum length = %.4f m\n\n',L)

% frequency response numerator

Gnum = ma*g*L ...
       - ma*L^2*om.^2 ...
       + 1i*ca*om;

% frequency response denominator

Gden = (Kb - (Mb+ma)*om.^2 + 1i*Cb*om) .* ...
       (ma*g*L - ma*L^2*om.^2 + 1i*ca*om) ...
       - (ma*L*om.^2).^2;

XF = abs(Gnum./Gden);

figure(2)

semilogy(om,XF,'LineWidth',2)

xline(wn,'--')

title('Building With Tuned Pendulum Absorber',...
      'FontSize',24,...
      'FontName','Times New Roman')

xlabel('Frequency (rad/s)',...
       'FontSize',24,...
       'FontName','Times New Roman')

ylabel('|X/F| (m/N)',...
       'FontSize',24,...
       'FontName','Times New Roman')

grid on

h = gca;

set(h,'FontSize',18,...
      'LineWidth',2,...
      'FontName','Times New Roman')

set(gcf,'Position',[50 50 1000 600])

% 3)
zetaValues = [0.005 0.01 0.02 0.05];

figure(3)
hold on

for j = 1:length(zetaValues)

    CbTest = 2*zetaValues(j)*sqrt(Mb*Kb);

    % Frequency response numerator

    Gnum = ma*g*L ...
           - ma*L^2*om.^2;

    % Frequency response denominator

    Gden = (Kb - (Mb+ma)*om.^2 + 1i*CbTest*om) .* ...
           (ma*g*L - ma*L^2*om.^2) ...
           - (ma*L*om.^2).^2;

    XF = abs(Gnum./Gden);


    semilogy(om,XF,'LineWidth',2)

end

xline(wn,'--')

title('Effect of Building Damping',...
      'FontSize',24,...
      'FontName','Times New Roman')

xlabel('Frequency (rad/s)',...
       'FontSize',24,...
       'FontName','Times New Roman')

ylabel('|X/F| (m/N)',...
       'FontSize',24,...
       'FontName','Times New Roman')

legend('\zeta_b = 0.005',...
       '\zeta_b = 0.01',...
       '\zeta_b = 0.02',...
       '\zeta_b = 0.05')

grid on

h = gca;

set(h,'FontSize',18,...
      'LineWidth',2,...
      'FontName','Times New Roman')

set(gcf,'Position',[50 50 1000 600])

% 4)
zetab = 0.005;

Cb = 2*zetab*sqrt(Mb*Kb);

massRatios = [0.01 0.03 0.05 0.075 0.10];

figure(4)
hold on

for j = 1:length(massRatios)

    % Absorber mass
    maTest = massRatios(j)*Mb;

    % Frequency response numerator

    Gnum = maTest*g*L ...
           - maTest*L^2*om.^2;

    % Frequency response denominator

    Gden = (Kb - (Mb+maTest)*om.^2 + 1i*Cb*om) .* ...
           (maTest*g*L - maTest*L^2*om.^2) ...
           - (maTest*L*om.^2).^2;

    XF = abs(Gnum./Gden);

    semilogy(om,XF,'LineWidth',2)

end

xline(wn,'--')

title('Effect of Absorber Mass',...
      'FontSize',24,...
      'FontName','Times New Roman')

xlabel('Frequency (rad/s)',...
       'FontSize',24,...
       'FontName','Times New Roman')

ylabel('|X/F| (m/N)',...
       'FontSize',24,...
       'FontName','Times New Roman')

legend('m_a = 0.01M_b',...
       'm_a = 0.03M_b',...
       'm_a = 0.05M_b',...
       'm_a = 0.075M_b',...
       'm_a = 0.10M_b')

grid on

h = gca;

set(h,'FontSize',18,...
      'LineWidth',2,...
      'FontName','Times New Roman')

set(gcf,'Position',[50 50 1000 600])


%  5) 
zetab = 0.005;

Cb = 2*zetab*sqrt(Mb*Kb);

ma = 0.01*Mb;

% Absorber damping values
caValues = 500:500:9500;

% Pendulum length values
LValues = linspace(0.951*L,...
                   1.049*L,...
                   30);

% Frequency range around resonance
omTest = linspace(2.5,3.8,2000);

% initialize values
bestResponse = inf;

bestCa = 0;

bestL = 0;


% damping and length varying

for j = 1:length(caValues)

    caTest = caValues(j);


    for k = 1:length(LValues)

        LTest = LValues(k);

        % Frequency response numerator

        Gnum = ma*g*LTest ...
               - ma*LTest^2*omTest.^2 ...
               + 1i*caTest*omTest;

        % Frequency response denominator

        Gden = (Kb - (Mb+ma)*omTest.^2 + 1i*Cb*omTest) .* ...
               (ma*g*LTest - ma*LTest^2*omTest.^2 ...
               + 1i*caTest*omTest) ...
               - (ma*LTest*omTest.^2).^2;

        XF = abs(Gnum./Gden);

        % Maximum response in frequency range
        maxResponse = max(XF);

        if maxResponse < bestResponse

            bestResponse = maxResponse;

            bestCa = caTest; % current ca value being tested

            bestL = LTest; % current L value being tested

        end

    end

end










fprintf('Part 5 Results:\n')
fprintf('Best absorber damping = %.0f N*m*s/rad\n',bestCa)
fprintf('Best pendulum length = %.4f m\n',bestL)
fprintf('Original pendulum length = %.4f m\n',L)
fprintf('Maximum response = %.4e m/N\n\n',bestResponse)

%  Plot Graphs

% Frequency response numerator

Gnum = ma*g*bestL ...
       - ma*bestL^2*om.^2 ...
       + 1i*bestCa*om;

% Frequency response denominator

Gden = (Kb - (Mb+ma)*om.^2 + 1i*Cb*om) .* ...
       (ma*g*bestL - ma*bestL^2*om.^2 ...
       + 1i*bestCa*om) ...
       - (ma*bestL*om.^2).^2;

XF = abs(Gnum./Gden);

figure(5)

semilogy(om,XF,'LineWidth',2)

xline(wn,'--')

title('"Good" Broadband Response',...
      'FontSize',24,...
      'FontName','Times New Roman')

xlabel('Frequency (rad/s)',...
       'FontSize',24,...
       'FontName','Times New Roman')

ylabel('|X/F| (m/N)',...
       'FontSize',24,...
       'FontName','Times New Roman')

grid on

h = gca;

set(h,'FontSize',18,...
      'LineWidth',2,...
      'FontName','Times New Roman')

set(gcf,'Position',[50 50 1000 600])













%{
Part 3 Graph Discussion:  It can be seen in the graph that the amplitude of the response curves for
 the building vary when you change the damping ratio. This makes 
 the graph more smoothed out at the higher damping ratio such as 0.05. Additionally, it is clear that each response curve approach the same notch
 value on the x-axis 
%}

%{
Part 4 Graph Discussion: From the graph, the curves are slightly shifted
based on the absorber's mass. Additionally, it is shown that the amplitude has a dependent relationship on the absorber mass because increasing absorber mass equates to a higher amplitude of the response curve.
%}