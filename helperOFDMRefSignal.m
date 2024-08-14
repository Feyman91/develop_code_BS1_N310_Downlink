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

rep = floor(numSubCarr / length(seq));
endSeqLen = (numSubCarr - (rep * length(seq)))/2;
refSignal = [seq(end-(endSeqLen-1):end); repmat(seq,rep,1); seq(1:endSeqLen)];

% Output check
if length(refSignal) > numSubCarr
    error('Reference signal length too long for FFT.');
end

end
