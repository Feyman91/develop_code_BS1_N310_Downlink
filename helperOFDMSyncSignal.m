function syncSignal = helperOFDMSyncSignal()
%helperOFDMSyncSignal Generates synchronization signal
%   This function returns a length-62 complex-valued vector for the
%   frequency-domain representation of the sync signal.
%
%   By default, this function uses a length-62 Zadoff-Chu sequence with
%   root index 25. Zadoff-Chu is a constant amplitude signal so long as the
%   length is a prime number, so the sequence is generated with a length of
%   63 and adjusted for a length of 62.
%
%   This sequence can be user-defined as needed (e.g. a maximum length
%   seqeunce) as long as the sequence is of length 62 to fit the OFDM
%   simulation.
%
%   syncSignal = helperOFDMSyncSignal() 
%   syncSignal - frequency-domain sync signal


% Copyright 2023 The MathWorks, Inc.

zcRootIndex = 25;
seqLen      = 62;
nPart1      = 0:((seqLen/2)-1);
nPart2      = (seqLen/2):(seqLen-1);

ZC = zadoffChuSeq(zcRootIndex, seqLen+1);
syncSignal = [ZC(nPart1+1); ZC(nPart2+2)];

% Output check
if length(syncSignal) ~= 62
    error('Sync signal must be of length 62.');
end

end
