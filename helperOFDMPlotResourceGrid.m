function helperOFDMPlotResourceGrid(txGrid,sysParam)
%helperOFDMPlotResourceGrid Plots the resource grid.
%   This function plots the resource grid and differentiates signals with
%   different colors.
%
%   helperOFDMPlotResourceGrid(txGrid)
%   txGrid - packed transmission grid
%   sysParam - structure of system parameters

% Copyright 2023 The MathWorks, Inc.

fftLen = sysParam.FFTLen; % FFT length
numSubCar = size(txGrid,1); % Number of subcarriers per symbol
symPerFrame = sysParam.numSymPerFrame; % Number of OFDM symbols per frame
numOFDMSym = size(txGrid,2);
numFrames = numOFDMSym/symPerFrame;

% Just for plotting resource grid assigning different index to
% different signals.
ssMapIndex = 1;
rsMapIndex = 2;
headerMapIndex = 3;
pilotMapIndex = 4;
dataMapIndex = 5;
dcMapIndex = 6;
guardMapIndex = 7;

SS_IDX = 1; % sync symbol index
RS_IDX = 2; % reference symbol index
HDR_IDX = 3; % header symbol index

% Initialize resource grid
resourceGrid = zeros(numSubCar,symPerFrame);

% Load synchronization, reference, header signal map indices to resource grid
syncSignalInd = (numSubCar/2)-31+(1:62);
syncSignalNull = setdiff(1:numSubCar,syncSignalInd);
resourceGrid(syncSignalInd,SS_IDX) = ssMapIndex;   % Load synchronous signal map index
resourceGrid(syncSignalNull,SS_IDX) = guardMapIndex;
resourceGrid(1:numSubCar,RS_IDX) = rsMapIndex;   % Load reference signal map index
headerInd = (numSubCar/2)-36+(1:72);
headerNull = setdiff(1:numSubCar,headerInd);
resourceGrid(headerInd,HDR_IDX) = headerMapIndex; % Load header signal map index
resourceGrid(headerNull,HDR_IDX) = guardMapIndex;

% Load data and pilots signal map indices to resource grid
gridSpacing = numSubCar / 12;
pilotIdx = sysParam.pilotIdx - (sysParam.FFTLen-sysParam.usedSubCarr)/2;
resourceGrid(pilotIdx,HDR_IDX+1:end) = pilotMapIndex; % Load pilot signal map index
modDataInd = 1:numSubCar;
modDataInd(pilotIdx) = []; % remove the pilot indices from modData indices
resourceGrid(modDataInd,HDR_IDX+1:end) = dataMapIndex; % Load data signal map index

% Append left, and right guard, and DC map indices to the resource grid
numLgSc = (fftLen-numSubCar)/2;
numRgSc = numLgSc-1;
resGridFFTLen = [guardMapIndex*ones(numLgSc,symPerFrame);resourceGrid(1:numSubCar/2,:);...
    dcMapIndex*ones(1,symPerFrame);resourceGrid(numSubCar/2+1:end,:);...
    guardMapIndex*ones(numRgSc,symPerFrame)];
resGridFFTLen = repmat(resGridFFTLen,1,numFrames);
% Plot resource grid
% Fix RGB values for different signals in the resource grid
map = [0     1   0;...
    0.4  0.5  1;...
    1     0   0;...
    0     1   1;...
    1     1   0;...
    0.3  0.3  0.3;...
    1    0.71 0.75 ];
figure (1)
image(resGridFFTLen)
ax = gca;
ax.XTick = 0:10:symPerFrame*numFrames;
ax.YTick = 0:floor(fftLen/10):fftLen;
grid(ax);
axis('xy')
title('OFDM Resource Grid');
xlabel('OFDM Symbol');
ylabel('Subcarrier');
colormap(map);
colorbar('Ticks',[1 2 3 4 5 6 7]+0.5,...
    'TickLabels',{'SS','RS','Header','Pilot','Data','DC','Guard'},...
    'Direction','reverse');
end