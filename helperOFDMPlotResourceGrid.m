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
numSubCar = sysParam.usedSubCarr; % Number of subcarriers per symbol
symPerFrame = sysParam.numSymPerFrame; % Number of OFDM symbols per frame
numOFDMSym = size(txGrid.rsgrid,2);
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
resourceGrid = zeros(fftLen,symPerFrame);

% Load DC signal map index
resourceGrid(txGrid.dcIdx,:) = dcMapIndex; % Load DC signal map index

% Load synchronization, reference, header signal map indices to resource grid
resourceGrid(txGrid.syncSignalIndAbs,SS_IDX) = ssMapIndex;   % Load synchronous signal map index
resourceGrid(txGrid.syncSignalNullInd,SS_IDX) = guardMapIndex;
resourceGrid(txGrid.refSignalIndAbs,RS_IDX) = rsMapIndex;   % Load reference signal map index
resourceGrid(txGrid.refSignalNullInd,RS_IDX) = guardMapIndex;   % Load reference signal map index
resourceGrid(txGrid.headerSymIndAbs,HDR_IDX) = headerMapIndex; % Load header signal map index
resourceGrid(txGrid.headerSymNullInd,HDR_IDX) = guardMapIndex;

% Load data and pilots signal map indices to resource grid
resourceGrid(txGrid.pilotIndAbs,HDR_IDX+1:end) = pilotMapIndex; % Load pilot signal map index
resourceGrid(txGrid.modDataIndAbs,HDR_IDX+1:end) = dataMapIndex; % Load data signal map index
resourceGrid(txGrid.dataSymNullInd,HDR_IDX+1:end) = guardMapIndex; % Load null signal map index
% resourceGrid(txGrid.dcIdx,:) = dcMapIndex; % Load DC signal map index

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
image(resourceGrid)
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