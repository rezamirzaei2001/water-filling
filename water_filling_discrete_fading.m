
clc;
clear;
close all;

%% Discrete fading channel parameters
g = [0.1 0.5 1 2];       % Channel power gains
prob = [0.25 0.25 0.25 0.25]; % State probabilities
N0 = 1;                  % Noise power
Pavg = 1;                % Average transmit power

%% 1) Uniform power allocation
P_uniform = Pavg * ones(size(g));

C_uniform = sum(prob .* ...
    log2(1 + g .* P_uniform / N0));

%% 2) Optimal water-filling using bisection
% P_i = max(mu - N0/g_i, 0)

noiseLevel = N0 ./ g;

mu_low = 0;
mu_high = max(noiseLevel) + Pavg/min(prob);

for k = 1:200
    mu = (mu_low + mu_high)/2;

    P_test = max(mu - noiseLevel, 0);
    avgPower = sum(prob .* P_test);

    if avgPower > Pavg
        mu_high = mu;
    else
        mu_low = mu;
    end
end

mu = (mu_low + mu_high)/2;
P_WF = max(mu - noiseLevel, 0);

C_WF = sum(prob .* ...
    log2(1 + g .* P_WF / N0));

%% Print results
fprintf('Uniform capacity = %.6f bit/s/Hz\n', C_uniform);
fprintf('Water-filling capacity = %.6f bit/s/Hz\n', C_WF);
fprintf('Water level = %.6f\n', mu);
fprintf('Average WF power = %.6f\n', sum(prob.*P_WF));

improvement = 100*(C_WF/C_uniform - 1);
fprintf('Capacity improvement = %.2f %%\n', improvement);

disp('Uniform powers:');
disp(P_uniform);

disp('Water-filling powers:');
disp(P_WF);

%% Plot 1: Power allocation
figure;
bar([P_uniform(:), P_WF(:)]);
xlabel('Channel state');
ylabel('Transmit power');
legend('Uniform','Water-Filling','Location','northwest');
title('Power Allocation Comparison');
grid on;

%% Plot 2: Capacity vs average transmit power
P_range = linspace(0.01,10,150);
C_U = zeros(size(P_range));
C_W = zeros(size(P_range));

for j = 1:length(P_range)
    Pbar = P_range(j);

    % Uniform allocation
    C_U(j) = sum(prob .* log2(1 + g*Pbar/N0));

    % Water-filling
    lo = 0;
    hi = max(noiseLevel) + Pbar/min(prob);

    for k = 1:100
        level = (lo + hi)/2;
        powers = max(level - noiseLevel,0);

        if sum(prob.*powers) > Pbar
            hi = level;
        else
            lo = level;
        end
    end

    level = (lo + hi)/2;
    powers = max(level - noiseLevel,0);

    C_W(j) = sum(prob .* ...
        log2(1 + g.*powers/N0));
end

figure;
plot(P_range,C_U,'b--','LineWidth',2);
hold on;
plot(P_range,C_W,'r-','LineWidth',2);
xlabel('Average Transmit Power');
ylabel('Capacity (bit/s/Hz)');
legend('Uniform','Water-Filling','Location','northwest');
title('Capacity Comparison in Discrete Fading Channel');
grid on;
