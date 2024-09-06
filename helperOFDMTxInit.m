function txObj = helperOFDMTxInit(sysParam)
%helperOFDMTxInit Initializes transmitter
%   This helper function is called once and sets up various transmitter
%   objects for use in per-frame processing of transport blocks.
%
%   txObj = helperOFDMTxInit(sysParam)
%   sysParam - structure of system parameters
%   txObj - structure of tx parameters and object handles

% Copyright 2023 The MathWorks, Inc.

% Create a tx filter object for baseband filtering
txFilterCoef = helperOFDMFrontEndFilter(sysParam);
txObj.txFilter = dsp.FIRFilter('Numerator',txFilterCoef);

% Configure PN sequencer for additive scrambler
txObj.pnSeq = comm.PNSequence(Polynomial= 'x^-7 + x^-3 + 1',...
    InitialConditionsSource="Input port",...
    Mask=sysParam.scrMask,...
    SamplesPerFrame=sysParam.trBlkSize+sysParam.CRCLen);

% Initialize CRC parameters
txObj.crcHeaderGen = crcConfig('Polynomial',sysParam.headerCRCPoly);
txObj.crcDataGen   = crcConfig('Polynomial',sysParam.CRCPoly);

% Plot frequency response
if sysParam.enableScopes
   [h,w] = freqz(txFilterCoef,1,1024,sysParam.scs*sysParam.FFTLen,'whole');
   figure;
   plot(w,20*log10(abs(h)));
   grid on;
   title('Tx Filter Frequency Response');
   xlabel('Frequency (Hz)');
   ylabel('Magnitude (dB)');
end

end