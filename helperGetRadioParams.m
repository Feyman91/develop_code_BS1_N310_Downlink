function ofdmRadioParams = helperGetRadioParams(sysParams,radioDevice,sampleRate,centerFrequency,gain,channelmapping)
%helperGetRadioParams(SYSPARAM,RADIODEVICE,SAMPLERATE,CENTERFREQUENCY,GAIN) defines a set of
% required parameters OFDMTX, for the radio system object initialization. The
% parameters are derived based on the user chosen radio device RADIODEVICE,
% sample rate SAMPLERATE and other system parameters SYSPARAM. This
% function searches for the radio device as selected by the user and if one
% such device is connected to the host computer, it fetches the IP address,
% and derives the Master Clock Rate and decimation/interpolation factor
% based on the given sample rate. 

% Copyright 2023-2024 The MathWorks, Inc.
ofdmRadioParams.RadioDevice     = radioDevice;
ofdmRadioParams.CenterFrequency = centerFrequency;
ofdmRadioParams.Gain            = gain;
ofdmRadioParams.channelmapping  = channelmapping;
ofdmRadioParams.SampleRate      = sampleRate;                % Sample rate of transmitted signal
ofdmRadioParams.NumFrames       = sysParams.numFrames;       % Number of frames for transmission/reception
ofdmRadioParams.txWaveformSize  = sysParams.txWaveformSize;  % Size of the transmitted waveform
ofdmRadioParams.modOrder        = sysParams.modOrder;
if ~strcmpi(radioDevice,'PLUTO')
    foundUSRPs = findsdru;
    deviceStatus = foundUSRPs({foundUSRPs.Platform} == radioDevice);
    if ~isempty(deviceStatus)
        if matches(radioDevice, {'B200', 'B210'})
            ofdmRadioParams.SerialNum = deviceStatus(1).SerialNum;
        else
            ofdmRadioParams.IPAddress = deviceStatus(1).IPAddress;
        end
    else
        error("USRP Device %s not found ", radioDevice);
    end

    switch radioDevice
        case {'B200','B210'}
            masterClockRate = sampleRate*2; % Minimum master clock rate should be 5 MHz
        case {'N320/N321'}
            masterClockRate = 245.76e6;
        case {'X310','X300'}
            masterClockRate = 184.32e6;
        case {'N310','N300'}
            masterClockRate = 153.6e6;
        % case {'N200/N210/USRP2'}
        %     masterClockRate = 100e6;
        %     ofdmTx.Gain = 25;
         otherwise
            error('The given radio device is not supported');
    end
    ofdmRadioParams.MasterClockRate = masterClockRate;
    ofdmRadioParams.InterpDecim = masterClockRate/sampleRate;
end
end

