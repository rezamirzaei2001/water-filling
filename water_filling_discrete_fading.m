
%% Four parallel Rayleigh fading subchannels: Uniform vs Water-Filling
clear; clc; close all;
rng(42,'twister');

%% Simulation parameters
N = 4;
numTrials = 20000;
noisePower = 1;
Ptotal = 4;
epsilon = 0.10;
powerGrid = logspace(-1,1.5,35);

%% Generate independent Rayleigh fading power gains
g = -log(max(rand(numTrials,N),realmin));

%% Calculate power allocation and instantaneous capacity
[Pu,Pw,Cu,Cw] = allocateAndCapacity(g,Ptotal,noisePower);

fprintf('Ergodic capacity: Uniform %.6f, WF %.6f bit/s/Hz\n',mean(Cu),mean(Cw));
fprintf('10%% outage capacity: Uniform %.6f, WF %.6f bit/s/Hz\n', ...
    quantileLocal(Cu,epsilon),quantileLocal(Cw,epsilon));
fprintf('Relative ergodic improvement: %.2f%%\n', ...
    100*(mean(Cw)/mean(Cu)-1));

assert(max(abs(sum(Pw,2)-Ptotal)) < 1e-8);
assert(all(Cw >= Cu-1e-10));

if ~exist('Figures','dir')
    mkdir('Figures');
end

%% Figure 1: Power allocation comparison
g_example = [0.1 0.5 1 2];
[Pu_ex,Pw_ex] = allocateAndCapacity(g_example,Ptotal,noisePower);

figure('Color','w');
bar([Pu_ex(:),Pw_ex(:)]);
xlabel('Subchannel');
ylabel('Allocated Power');
legend('Uniform','Water-Filling','Location','northwest');
title('Power Allocation - Single Realization');
xticks(1:N);
grid on;
saveas(gcf,fullfile('Figures','power_allocation_comparison.png'));

%% Figures 2 & 3: Capacity versus transmit power
EU = zeros(size(powerGrid));
EW = EU;
OU = EU;
OW = EU;

for k = 1:numel(powerGrid)
    [~,~,a,b] = allocateAndCapacity(g,powerGrid(k),noisePower);
    EU(k) = mean(a);
    EW(k) = mean(b);
    OU(k) = quantileLocal(a,epsilon);
    OW(k) = quantileLocal(b,epsilon);
end

figure('Color','w');
semilogx(powerGrid,EU,'LineWidth',1.8);
hold on;
semilogx(powerGrid,EW,'LineWidth',1.8);
xlabel('Total Transmit Power');
ylabel('Ergodic Capacity (bit/s/Hz)');
title('Ergodic Capacity vs. Total Transmit Power');
legend('Uniform','Water-Filling','Location','northwest');
grid on;
saveas(gcf,fullfile('Figures','ergodic_capacity_vs_power.png'));

figure('Color','w');
semilogx(powerGrid,OU,'LineWidth',1.8);
hold on;
semilogx(powerGrid,OW,'LineWidth',1.8);
xlabel('Total Transmit Power');
ylabel('10% Outage Capacity (bit/s/Hz)');
title('10% Outage Capacity vs. Total Transmit Power');
legend('Uniform','Water-Filling','Location','northwest');
grid on;
saveas(gcf,fullfile('Figures','outage_capacity_vs_power.png'));

%% Figure 4: Outage probability versus target rate
rates = linspace(0,3,120);
outU = zeros(size(rates));
outW = outU;

for k = 1:numel(rates)
    outU(k) = mean(Cu < rates(k));
    outW(k) = mean(Cw < rates(k));
end

figure('Color','w');
plot(rates,outU,'LineWidth',1.8);
hold on;
plot(rates,outW,'LineWidth',1.8);
xlabel('Target Rate (bit/s/Hz)');
ylabel('Outage Probability');
title('Outage Probability vs. Target Rate');
legend('Uniform','Water-Filling','Location','southeast');
grid on;
saveas(gcf,fullfile('Figures','outage_probability_vs_rate.png'));

%% Figure 5: Empirical CDF of instantaneous capacity
figure('Color','w');
plot(sort(Cu),(1:numTrials)/numTrials,'LineWidth',1.8);
hold on;
plot(sort(Cw),(1:numTrials)/numTrials,'LineWidth',1.8);
xlabel('Instantaneous Spectral Efficiency (bit/s/Hz)');
ylabel('CDF');
title('Empirical CDF of Instantaneous Capacity');
legend('Uniform','Water-Filling','Location','southeast');
grid on;
saveas(gcf,fullfile('Figures','capacity_cdf.png'));

%% Water-Filling and capacity calculation
function [Pu,Pw,Cu,Cw] = allocateAndCapacity(g,Ptotal,noisePower)
    [M,N] = size(g);
    Pu = (Ptotal/N)*ones(M,N);

    effectiveNoise = noisePower./max(g,realmin);
    lo = zeros(M,1);
    hi = max(effectiveNoise,[],2)+Ptotal;

    for iteration = 1:65
        mu = (lo+hi)/2;
        candidate = max(bsxfun(@minus,mu,effectiveNoise),0);
        consumed = sum(candidate,2);

        lo(consumed<Ptotal) = mu(consumed<Ptotal);
        hi(consumed>=Ptotal) = mu(consumed>=Ptotal);
    end

    Pw = max(bsxfun(@minus,(lo+hi)/2,effectiveNoise),0);

    Cu = mean(log2(1+g.*Pu/noisePower),2);
    Cw = mean(log2(1+g.*Pw/noisePower),2);
end

%% Quantile calculation without Statistics Toolbox
function q = quantileLocal(x,p)
    x = sort(x(:));
    position = 1+(numel(x)-1)*p;
    i = floor(position);
    j = ceil(position);
    q = x(i)+(position-i)*(x(j)-x(i));
end
