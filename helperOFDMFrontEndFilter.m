function firCoeff = helperOFDMFrontEndFilter(sysParam)
%helperOFDMFrontEndFilter() Generates the transceiver front-end filter.
%
%   firCoeff = helperOFDMFrontEndFilter(sysParam)
%   sysParam - system parameters structure
%   firCoeff - FIR filter coefficients for the specified bandwidth

% Copyright 2023 The MathWorks, Inc.

BWP_center_offset_bs1 = sysParam.subcarrier_center_offset;  % 从之前 BWP 的计算中获取中心偏移量
basband_center_freq_bs1 = BWP_center_offset_bs1 * sysParam.scs;  % 基于 BWP 中心索引与子载波间隔计算频率偏移
channelBW = sysParam.channelBW;                  % channel Bandwidth (in Hz) of OFDM signal
signalBW = sysParam.signalBW;           % signal Bandwidth (in Hz) of OFDM signal
fs = sysParam.scs*sysParam.FFTLen; % Sample rate of OFDM signal

%% FIR Filtering 
% Equiripple Lowpass filter designed using the |firpm| function.
% All frequency values are in Hz.
% 带通滤波器设计参数
Fpass = channelBW/2;               % Passband frequency
Fstop = signalBW/2;               % Stopband frequency
Dpass = 0.00033136495965;   % Passband ripple
Dstop = 0.05;               % Stopband ripple
dens  = 20;                 % Density factor

% Calculate the order from the parameters using the |firpmord| function.
[N, Fo, Ao, W] = firpmord([Fpass, Fstop]/(fs/2), [1 0], [Dpass, Dstop]);

% Calculate the coefficients using the |firpm| function.
firCoeff_lwp  = firpm(N, Fo, Ao, W, {dens});

% 计算频率偏移因子
Fc_offset = basband_center_freq_bs1 / (fs / 2);  % 将基带中心频率转换为归一化频率

% 频移以设计复数带通滤波器
firCoeff = firCoeff_lwp .* exp(1j * Fc_offset * pi * (0:N));

end

