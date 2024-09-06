function refSignal = helperOFDMRefSignal(numSubCarr)
%helperOFDMRefSignal Generates reference signal.
%   This function generates a reference signal (refSignal) for the given
%   number of active subcarriers (numSubCarr). This reference signal is
%   known to both the transmitter and receiver.
%
%   By default, this function uses a BPSK-modulated pseudo random binary
%   sequence, repeated as necessary to fill the desired subcarriers. The
%   sequence is designed to be centered around DC. The sequence for the
%   smallest FFT length is also used for the other larger FFT lengths within
%   those subcarriers, so that receivers that can only support the minimum
%   FFT length can use the reference signal to demodulate the header (which
%   is transmitted at the minimum FFT length to support all receivers
%   independent of supported bandwidth). The sequence can be less than the
%   FFT length to accommodate for null carriers within the OFDM symbol.
%
%   This sequence can be user-defined as needed.
%
%   refSignal = helperOFDMRefSignal(numSubCarr)
%   numSubCarr - number of subcarriers per symbol
%   refSignal - frequency-domain reference signal

% Copyright 2023 The MathWorks, Inc.

seq1 = [1; 1;-1;-1; ...
    1; 1;-1; 1; ...
    -1; 1; 1; 1; ...
    1; 1; 1;-1; ...
    -1; 1; 1;-1; ...
    1;-1; 1; 1; ...
    1; 1;];
seq2 = [1; ...
    -1;-1; 1; 1; ...
    -1; 1;-1; 1; ...
    -1;-1;-1;-1; ...
    -1; 1; 1;-1; ...
    -1; 1;-1; 1; ...
    -1; 1; 1; 1; 1];
seq = [seq1 ; seq2];

rep = floor(numSubCarr / length(seq));     % 计算可以完全重复的序列次数
remainder = mod(numSubCarr, length(seq));  % 计算剩余的子载波数
% 处理基数情况，并计算 seq 的长度调整
endSeqLen = floor(remainder / 2);  % 确保 endSeqLen 为整数
if numSubCarr < length(seq)
    refSignal = [seq(end-(endSeqLen-1):end); seq(1:endSeqLen+1)];
else
    % 生成完整的 refSignal，并在需要时对两端进行补充
    refSignal = [seq(end-(endSeqLen-1):end); repmat(seq,rep,1); seq(1:endSeqLen)];
    
    % 如果长度不符，则调整
    if length(refSignal) < numSubCarr
        refSignal = [refSignal; seq(endSeqLen+1)];  % 长度不足时，添加一个额外元素
    elseif length(refSignal) > numSubCarr
        refSignal(end) = [];  % 长度超出时，移除最后一个元素
    end
end

% Output check
if length(refSignal) ~= numSubCarr
    error('Reference signal length not fit for FFT.');
end


end
