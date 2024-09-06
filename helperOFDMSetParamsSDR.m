function [sysParam,txParam,payload] = helperOFDMSetParamsSDR(OFDMParam, dataParam, allRadioResource)
%helperOFDMSetParamsSDR(OFDMParam,dataParam) Generates simulation parameters.
%   This function generates transmit-specific and common transmitter/receiver
%   parameters for the OFDM simulation, based on the high-level user
%   parameter settings passed into the helper function, specifically used in the SDR. Coding parameters may
%   be changed here, subject to some constraints noted below. This function
%   also generates a payload of the computed transport block size 
%
%   [sysParam,txParam,payload] = helperOFDMSetParameters(userParam)
%   OFDMParam - structure of OFDM related parameters
%   dataParam - structure of data related parameters
%   alloc_RadioResource - structure of allocated radio resource
%   sysParam  - structure of system parameters common to tx and rx
%   txParam   - structure of tx parameters
%   payload   - known data payload generated for the trBlk size

% Copyright 2023-2024 The MathWorks, Inc.

% Set shared tx/rx parameter structure
sysParam = struct();

% Set transmit-specific parameter structure
txParam = struct();

txParam.modOrder        = dataParam.modOrder;    

sysParam.isSDR = true;
sysParam.numFrames      = dataParam.numFrames;

sysParam.numSymPerFrame = dataParam.numSymPerFrame; 

sysParam.initState = [1 0 1 1 1 0 1]; % Scrambler/descrambler polynomials
sysParam.scrMask   = [0 0 0 1 0 0 1];
sysParam.allRadioResource = allRadioResource;
sysParam.headerIntrlvNColumns = 12;   % Number of columns of header interleaver, must divide into 72 evenly
sysParam.dataIntrlvNColumns = 18;     % Number of columns of data interleaver
sysParam.dataConvK = 7;               % Convolutional encoder constraint length for data
sysParam.dataConvCode = [171 133];    % Convolution polynomials (1/2 rate) for data
sysParam.headerConvK = 7;             % Convolutional encoder constraint length for header
sysParam.headerConvCode = [171 133];  % Convolution polynomials (1/2 rate) for header

sysParam.headerCRCPoly = [16 12 5 0]; % header CRC polynomial

sysParam.CRCPoly = [32 26 23 22 16 12 11 10 8 7 5 4 2 1 0]; % data CRC polynomial
sysParam.CRCLen  = 32;                                      % data CRC length

% Transmission grid parameters
sysParam.ssIdx = 1;                         % Symbol 1 is the sync symbol
sysParam.rsIdx = 2;                     % Symbol 2 is the reference symbol
sysParam.headerIdx = 3;                     % Symbol 3 is the header symbol

% Simulation options
sysParam.enableCFO = true;
sysParam.enableCPE = true;
sysParam.enableScopes = dataParam.enableScopes;
sysParam.verbosity = dataParam.verbosity;

% Derived parameters from simulation settings
% The remaining parameters are derived from user selections. Checks are
% made to ensure that interdependent parameters are compatible with each
% other.

sysParam.BS_id                 = OFDMParam.BS_id;               % 基站 ID
sysParam.FFTLen                = OFDMParam.FFTLength;           % FFT 长度
sysParam.CPLen                 = OFDMParam.CPLength;            % 循环前缀长度
sysParam.usedSubCarr           = OFDMParam.NumSubcarriers;      % 总的使用子载波数量
sysParam.subcarrier_start_index = OFDMParam.subcarrier_start_index;  % BWP 子载波起始索引
sysParam.subcarrier_end_index   = OFDMParam.subcarrier_end_index;    % BWP 子载波结束索引
sysParam.subcarrier_center_offset = OFDMParam.subcarrier_center_offset;  % 中心偏移
sysParam.BWPoffset              = OFDMParam.BWPoffset;          % 对应分配的BWP人为设置Offset
sysParam.channelBW                    = OFDMParam.channelBW;           % 分配的信道总带宽(滤波器通带)
sysParam.signalBW                     = OFDMParam.signalBW;           % 分配的信号总带宽(滤波器阻带)
sysParam.scs                   = OFDMParam.Subcarrierspacing;   % 子载波间隔 (Hz)
sysParam.pilotSpacing          = OFDMParam.PilotSubcarrierSpacing;  % 导频子载波间隔
codeRate                = str2num(dataParam.coderate);       % Coding rate
if codeRate == 1/2
    sysParam.tracebackDepth =  30;                      % Traceback depth is 30 for coderate
    sysParam.codeRate = 1/2;
    sysParam.codeRateK = 2;
    sysParam.puncVec = [1 1];
    txParam.codeRateIndex = 0;
elseif codeRate == 2/3
    sysParam.puncVec = [1 1 0 1];
    sysParam.codeRate = 2/3;
    sysParam.codeRateK = 3;
    sysParam.tracebackDepth = 45;
    txParam.codeRateIndex = 1;
elseif codeRate == 3/4
    sysParam.puncVec = [1 1 1 0 0 1];
    sysParam.codeRate = 3/4;
    sysParam.codeRateK = 4;
    sysParam.tracebackDepth = 60;
    txParam.codeRateIndex = 2;
elseif codeRate == 5/6
    sysParam.puncVec = [1 1 1 0 0 1 1 0 0 1];
    sysParam.codeRate = 5/6;
    sysParam.codeRateK = 6;
    sysParam.tracebackDepth = 90;
    txParam.codeRateIndex = 3;
end

% 计算该基站的导频索引
numSubCar            = sysParam.usedSubCarr; % Number of subcarriers per symbol
sysParam.pilotIdx = sysParam.subcarrier_start_index + ...
    (1:sysParam.pilotSpacing:numSubCar).' -1;  % 导频间隔分布在 BWP 范围内
% 
% sysParam.pilotIdx    = ((sysParam.FFTLen-sysParam.usedSubCarr)/2) + ...
%     (1:sysParam.pilotSpacing:sysParam.usedSubCarr).';

% Check if a pilot subcarrier falls on the DC subcarrier; if so, then shift
% up the rest of the pilots by a subcarrier
dcIdx = (sysParam.FFTLen/2)+1;
if any(sysParam.pilotIdx == dcIdx)
    sysParam.pilotIdx(floor(length(sysParam.pilotIdx)/2)+1:end) = 1 + ...
        sysParam.pilotIdx(floor(length(sysParam.pilotIdx)/2)+1:end);
end

% Error checks
% pilotsPerSym = numSubCar/sysParam.pilotSpacing;
% if floor(pilotsPerSym) ~= pilotsPerSym
%     error('Number of subcarriers must be evenly divisible by the pilot spacing.');
% end
sysParam.pilotsPerSym = length(sysParam.pilotIdx);

numIntrlvRows = 72/sysParam.headerIntrlvNColumns;
if floor(numIntrlvRows) ~= numIntrlvRows
    error('Number of header interleaver rows must divide into number of header subcarriers evenly.');
end

if sysParam.numFrames < ceil(144/sysParam.numSymPerFrame)
    error('Number of frames must allow at least 144 symbols to be transmitted for AFC.');
end

numDataOFDMSymbols = sysParam.numSymPerFrame - ...
    length(sysParam.ssIdx)  - length(sysParam.rsIdx) - ...
    length(sysParam.headerIdx);             % Number of data OFDM symbols
if numDataOFDMSymbols < 1
    error('Number of symbols per frame must be greater than the number of sync, header, and reference symbols.');
end

% Calculate transport block size (trBlkSize) using parameters
bitsPerModSym = log2(txParam.modOrder);     % Bits per modulated symbol
numSubCar = sysParam.usedSubCarr;           % Number of subcarriers per symbol
pilotsPerSym = sysParam.pilotsPerSym; % Number of pilots per symbol
uncodedPayloadSize = (numSubCar-pilotsPerSym)*numDataOFDMSymbols*bitsPerModSym;
codedPayloadSize = floor(uncodedPayloadSize / sysParam.codeRateK) * ...
    sysParam.codeRateK;
sysParam.trBlkPadSize = uncodedPayloadSize - codedPayloadSize;
sysParam.trBlkSize = (codedPayloadSize * codeRate) - sysParam.CRCLen - ...
    (sysParam.dataConvK-1);
sysParam.txWaveformSize = ((sysParam.FFTLen +sysParam.CPLen)*sysParam.numSymPerFrame);
sysParam.timingAdvance = sysParam.txWaveformSize;
sysParam.modOrder = dataParam.modOrder;

% Generate payload message
sysParam.NumBitsPerCharacter = 7;
payloadMessage = char(readlines("transmit_data.txt"));
messageLength = length(payloadMessage);
numPayloads = ceil(sysParam.trBlkSize/(messageLength*sysParam.NumBitsPerCharacter)); 
message = repmat(payloadMessage,1,numPayloads);
trBlk = reshape(int2bit(double(message),sysParam.NumBitsPerCharacter),1,[]);
payload = trBlk(1:sysParam.trBlkSize);
end