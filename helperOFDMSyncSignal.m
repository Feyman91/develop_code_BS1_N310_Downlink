function ZCsyncSignal = helperOFDMSyncSignal(sysParam)
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
BS_id = sysParam.BS_id;
seqLen = min(63, sysParam.usedSubCarr);  % The ZC sequence length must fit within the BWP

rootindices63_total = [22 23 25 26 29 31 32 34 37 38 40 41 43 44 46 47 50];
rootindices137_total = [21 22 23 24	25 26 27 28 29 30 31 32 33 34 35 36	37 38 39 40 41 42 43 44 45 46 47 48 49 50];
zcRootIndex = mod(BS_id+(BS_id-1)*7+21, seqLen);  % Use BS_id to generate different root indices for each BS
% Ensure zcRootIndex and seqLen are relatively prime (gcd(zcRootIndex, seqLen) = 1)
while gcd(zcRootIndex, seqLen) ~= 1
    zcRootIndex = zcRootIndex + 1;  % Adjust root index until it's relatively prime with seqLen
end
ZCsyncSignal = zadoffChuSeq(zcRootIndex, seqLen);


end
