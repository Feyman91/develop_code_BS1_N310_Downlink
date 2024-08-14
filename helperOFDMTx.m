function [txWaveform,grid,diagnostics] = helperOFDMTx(txParamConfig,sysParam,txObj)
%helperOFDMTx Generates OFDM transmitter waveform
%   Generates OFDM transmitter waveform with synchronization, reference,
%   header, pilots, and data signals. This function returns txWaveform,
%   txGrid, and diagnostics using transmitter parameters txParamConfig.
%
%   [txWaveform,grid,diagnostics] = helperOFDMTx(txParamConfig,sysParam,txObj)
%   txParamConfig - Specify as structure or array of structure with the
%   following attributes as shown below:
%   modOrder      - Specify 2, 4, 16, 64, 256, or 1024 
%   codeRateIndex - Specify 0, 1, 2, and 3 for the rates '1/2', '2/3',
%                   '3/4', and '5/6' respectively. 
%   txDataBits    - Specify binary values in a row or column vector of
%                   length trBlkSize. Default is column vector containing
%                   randomly generated binary values of length trBlkSize.
%
%   Calculate transport block size (trBlkSize) as follows:
%   numSubCar - Number of data subcarriers per symbol
%   pilotsPerSym - Number of pilots per symbol
%   numDataOFDMSymbols - Number of data OFDM symbols per frame
%   bitsPerModSym - Number of bits per modulated symbol
%   codeRate - Punctured code rate
%   dataConvK - Constraint length of the convolutional encoder
%   dataCRCLen - CRC length
%   trBlkSize = ((numSubCar - pilotsPerSym) * 
%              numDataOFDMSymbols * bitsPerModSym * codeRate) - 
%              (dataConvK-1) - dataCRCLen
%
%   txWaveform  - Transmitter waveform, returned as a column vector of length
%               ((fftLen+cpLen)*numSymPerFrame), where
%               fftLen - FFT length
%               cpLen - Cyclic prefix length
%               numSymPerFrame - Number of OFDM symbols per frame
%
%   grid        - Grid, returned as a matrix of dimension
%               numSubCar-by-numSymPerFrame
%
%   diagnostics - Diagnostics,returned as a structure or array of structure
%   based on txParamConfig. Diagnostics has the following attributes:
%   headerBits - Header bits as column vector of size 22 includes:
%                Number of bits to represent FFT length index       =  3
%                Number of bits to represent symbol modulation type =  2
%                Number of bits to represent code rate index        =  2
%                Number of spare bits                               = 15
%   dataBits   - Actual data bits transmitted
%                dataBits is a binary row or column vector of length
%                trbBlkSize. Row or column vector
%                depends on the dimension of txParamConfig.dataBits.
%                Default size is a column vector of length trbBlkSize.
%   ofdmModOut - OFDM modulated output as a column vector of length
%                (fftLen+cpLen)*numSymPerFrame.

% Copyright 2023 The MathWorks, Inc.

ssIdx = sysParam.ssIdx;         % sync symbol index
rsIdx = sysParam.rsIdx;         % reference symbol index
headerIdx = sysParam.headerIdx; % header symbol index
numCommonChannels = length(ssIdx) + length(rsIdx) + length(headerIdx);

% Generate OFDM modulator output for each input configuration structure
fftLen = sysParam.FFTLen;   % FFT length
cpLen  = sysParam.CPLen;    % CP length
numSubCar = sysParam.usedSubCarr; % Number of subcarriers per OFDM symbol
numSymPerFrame = sysParam.numSymPerFrame; % Number of OFDM symbols per frame

% Initialize transmitter grid
grid = zeros(numSubCar,numSymPerFrame);

% Derive actual parameters from inputs
[modType,bitsPerModSym,puncVec,~] = ...
    getParameters(txParamConfig.modOrder,txParamConfig.codeRateIndex);

%% Synchronization signal generation
syncSignal = helperOFDMSyncSignal();
syncSignalInd = (numSubCar/2) - 31 + (1:62);

% Load synchronization signal on the grid
grid(syncSignalInd,ssIdx) = syncSignal;

%% Reference signal generation
refSignal = helperOFDMRefSignal(numSubCar);
refSignalInd = 1:length(refSignal);

% Load reference signals on the grid
grid(refSignalInd,rsIdx(1)) = refSignal;

%% Header generation
% Generate header bits
% Map FFT length
nbitsFFTLenIndex = 3;
switch fftLen
    case 64                               % 0 -> 64
        FFTLenIndexBits = dec2bin(0,nbitsFFTLenIndex) == '1';
    case 128                              % 1 -> 128
        FFTLenIndexBits = dec2bin(1,nbitsFFTLenIndex) == '1';
    case 256                              % 2 -> 256
        FFTLenIndexBits = dec2bin(2,nbitsFFTLenIndex) == '1';
    case 512                              % 3 -> 512
        FFTLenIndexBits = dec2bin(3,nbitsFFTLenIndex) == '1';
    case 1024                             % 4 -> 1024
        FFTLenIndexBits = dec2bin(4,nbitsFFTLenIndex) == '1';
    case 2048                             % 5 -> 2048
        FFTLenIndexBits = dec2bin(5,nbitsFFTLenIndex) == '1';
    case 4096                             % 6 -> 4096
        FFTLenIndexBits = dec2bin(6,nbitsFFTLenIndex) == '1';
end

% Map modulation order
nbitsModTypeIndex = 3;
switch modType
    case 'BPSK'                                % 0 -> BPSK
        modTypeIndexBits = dec2bin(0,nbitsModTypeIndex) == '1';
    case 'QPSK'                                % 1 -> QPSK
        modTypeIndexBits = dec2bin(1,nbitsModTypeIndex) == '1';
    case '16QAM'                               % 2 -> 16-QAM
        modTypeIndexBits = dec2bin(2,nbitsModTypeIndex) == '1';
    case '64QAM'                               % 3 -> 64-QAM
        modTypeIndexBits = dec2bin(3,nbitsModTypeIndex) == '1';
    case '256QAM'                              % 4 -> 256-QAM
        modTypeIndexBits = dec2bin(4,nbitsModTypeIndex) == '1';
    case '1024QAM'                             % 5 -> 1024-QAM
        modTypeIndexBits = dec2bin(5,nbitsModTypeIndex) == '1';
    case '4096QAM'                             % 5 -> 1024-QAM
        modTypeIndexBits = dec2bin(6,nbitsModTypeIndex) == '1';
end

% Map code rate index
nbitsCodeRateIndex = 2;
switch txParamConfig.codeRateIndex
    case 0
        codeRateIndexBits = dec2bin(0,nbitsCodeRateIndex) == '1';
    case 1
        codeRateIndexBits = dec2bin(1,nbitsCodeRateIndex) == '1';
    case 2
        codeRateIndexBits = dec2bin(2,nbitsCodeRateIndex) == '1';
    case 3
        codeRateIndexBits = dec2bin(3,nbitsCodeRateIndex) == '1';
end
reserveBits = zeros(1,14-nbitsFFTLenIndex-nbitsCodeRateIndex-nbitsModTypeIndex); % Reserve bits for future use

% Form header bits
headerBits = [FFTLenIndexBits, modTypeIndexBits, codeRateIndexBits, reserveBits];
diagnostics.headerBits = headerBits.';

% Append CRC bits
headerCRCOut = reshape(crcGenerate(headerBits',txObj.crcHeaderGen),1,[]);

% Perform convolutional coding
headerConvK = sysParam.headerConvK; 
headerConvCode = sysParam.headerConvCode; 
headerConvOut = convenc([headerCRCOut, zeros(1,headerConvK-1)], ...
    poly2trellis(headerConvK,headerConvCode)); % Terminated Mode

% Perform Interleaving
headerIntrlvLen = sysParam.headerIntrlvNColumns;
headerIntrlvOut = reshape(reshape(headerConvOut,headerIntrlvLen,[]).',[],1);

% Modulate header using BPSK
headerSym = pskmod(headerIntrlvOut,2,InputType="bit");
headerSymInd = (numSubCar/2)-36+(1:72);

% Load header signal on the grid
grid(headerSymInd,headerIdx) = headerSym;

%% Pilot generation
% Number of data/pilots OFDM symbols per frame
numDataOFDMSymbols = numSymPerFrame - numCommonChannels;
pilot    = helperOFDMPilotSignal(sysParam.pilotsPerSym);    % Pilot signal values
pilot    = repmat(pilot,1,numDataOFDMSymbols);              % Pilot symbols per frame
pilotGap = sysParam.pilotSpacing;                           % Pilot signal repetition gap in OFDM symbol
pilotInd = (1:pilotGap:numSubCar).';

%% Data generation
% Initialize convolutional encoder parameters
dataConvK = sysParam.dataConvK;
dataConvCode = sysParam.dataConvCode;

% Calculate transport block size
trBlkSize = sysParam.trBlkSize;
if (~isfield(txParamConfig,{'txDataBits'})) || ...
        isempty(txParamConfig.txDataBits)
    % Generate random bits if txDataBits is not a field
    txParamConfig.txDataBits = randi([0 1],trBlkSize,1);
else
    % Pad appropriate bits if txDataBits is less than required bits
    if length(txParamConfig.txDataBits) < trBlkSize
        if isrow(txParamConfig.txDataBits)
            txParamConfig.txDataBits = ...
                [txParamConfig.txDataBits zeros(1,trBlkSize-length(txParamConfig.txDataBits))];
        else
            txParamConfig.txDataBits = ...
                [txParamConfig.txDataBits ; zeros((trBlkSize-length(txParamConfig.txDataBits)),1)];
        end
    end
end
diagnostics.dataBits = txParamConfig.txDataBits(1:trBlkSize);

% Retrieve data to form a transport block
dataBits = txParamConfig.txDataBits;
if isrow(dataBits)
    dataBits = dataBits.';
end

% Append CRC bits to data bits
crcData = crcGenerate(dataBits, txObj.crcDataGen);

% Additively scramble using scramble polynomial
scrOut = xor(crcData,txObj.pnSeq(sysParam.initState));

% Perform convolutional coding
dataEnc = convenc([scrOut;zeros(dataConvK-1,1)], ...
    poly2trellis(dataConvK,dataConvCode),puncVec); % Terminated mode
dataEnc = [dataEnc; zeros(sysParam.trBlkPadSize,1)]; % append pad to factorize payload length
dataEnc = reshape(dataEnc,[],numDataOFDMSymbols); % form columns of symbols

% Perform interleaving and symbol modulation
modData   = zeros(numel(dataEnc)/(numDataOFDMSymbols*bitsPerModSym),numDataOFDMSymbols);
for i = 1:numDataOFDMSymbols
    % Interleave each symbol
    intrlvOut = OFDMInterleave(dataEnc(:,i),sysParam.dataIntrlvNColumns);
    % intrlvOut = dataEnc(:,i);

    % Modulate the symbol
    modData(:,i) = qammod(intrlvOut,txParamConfig.modOrder,...
        UnitAveragePower=true,InputType="bit");
end
modDataInd = 1:numSubCar;

% Remove the pilot indices from modData indices
modDataInd(pilotInd) = [];

% Load data and pilots on the grid
grid(pilotInd,(headerIdx+1:numSymPerFrame)) = pilot;
grid(modDataInd,(headerIdx+1:numSymPerFrame)) = modData;

   
%% OFDM modulation
dcIdx = (fftLen/2)+1;

% Generate sync symbol
nullLen = (fftLen - 62)/2;
syncNullInd = [1:nullLen dcIdx fftLen-nullLen+2:fftLen].';
ofdmSyncOut = ofdmmod(syncSignal,fftLen,cpLen,syncNullInd);

% Generate reference symbol
nullInd = [1:((fftLen-numSubCar)/2) dcIdx ((fftLen+numSubCar)/2)+1+1:fftLen].';
ofdmRefOut  = ofdmmod(refSignal,fftLen,cpLen,nullInd);

% Generate header symbol
nullLen = (fftLen - 72)/2;
headerNullInd = [1:nullLen dcIdx fftLen-nullLen+2:fftLen].';
ofdmHeaderOut = ofdmmod(headerSym,fftLen,cpLen,headerNullInd);

% Generate data symbols with embedded pilot subcarriers
ofdmDataOut = ofdmmod(modData,fftLen,cpLen,nullInd,sysParam.pilotIdx,pilot);
ofdmModOut = [ofdmSyncOut; ofdmRefOut; ofdmHeaderOut; ofdmDataOut];

% Filter OFDM modulator output
txWaveform = txObj.txFilter(ofdmModOut);

% Collect diagnostic information
diagnostics.ofdmModOut = txWaveform.';

end

function [modType,bitsPerModSym,puncVec,codeRate] = getParameters(modOrder,codeRateIndex)
% Select modulation type and bits per modulated symbol
switch modOrder
    case 2
        modType = 'BPSK';
        bitsPerModSym  = 1;
    case 4
        modType = 'QPSK';
        bitsPerModSym  = 2;
    case 16
        modType = '16QAM';
        bitsPerModSym  = 4;
    case 64
        modType = '64QAM';
        bitsPerModSym  = 6;
    case 256
        modType = '256QAM';
        bitsPerModSym  = 8;
    case 1024
        modType = '1024QAM';
        bitsPerModSym  = 10;
    case 4096
        modType = '4096QAM';
        bitsPerModSym  = 12;
    otherwise
        modType = 'QPSK';
        bitsPerModSym  = 2;
        fprintf('\n Invalid modulation order. By default, QPSK is applied. \n');
end

% Select puncture vector and punctured code rate
switch codeRateIndex
    case 0
        puncVec = [1 1];
        codeRate = 1/2;
    case 1
        puncVec = [1 1 0 1];
        codeRate = 2/3;
    case 2
        puncVec = [1 1 1 0 0 1];
        codeRate = 3/4;
    case 3
        puncVec = [1 1 1 0 0 1 1 0 0 1];
        codeRate = 5/6;
    otherwise
        puncVec = [1 1];
        codeRate = 1/2;
        fprintf('\n Invalid code rate. By default, 1/2 code rate is applied. \n');
end
end

function intrlvOut = OFDMInterleave(in,dataIntrlvLen)

lenIn = size(in,1);
numIntRows = ceil(lenIn/dataIntrlvLen);
numInPad = (dataIntrlvLen*numIntRows) - lenIn;  % number of padded entries needed to make the input data length factorable
numFullCols = dataIntrlvLen - numInPad;
inPad = [in ; zeros(numInPad,1)];               % pad the input data so it is factorable
temp = reshape(inPad,dataIntrlvLen,[]).';       % form interleave matrix
temp1 = reshape(temp(:,1:numFullCols),[],1);    % extract out the full rows
if numInPad ~= 0
    temp2 = reshape(temp(1:numIntRows-1,numFullCols+1:end),[],1); % extract out the partially-filled rows
else
    temp2 = [];
end
intrlvOut = [temp1 ; temp2]; % concatenate the two rows

end
