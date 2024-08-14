function pilot = helperOFDMPilotSignal(pilotsPerSym)
%helperOFDMPilotSignal  Generates pilot signal
%   This function generates the pilot signal (pilot). This pilot signal is
%   known to both the transmitter and receiver. This sequence uses a
%   BPSK-modulated pseudo random binary sequence. This sequence can be
%   user-defined.
%
%   pilot = helperOFDMPilotSignal(pilotsPerSym)
%   pilotsPerSym - pilots per symbol
%   pilot - frequency-domain pilot sequence

% Copyright 2023 The MathWorks, Inc.

s = RandStream("dsfmt19937","Seed",15);
pilot = (randi(s,[0 1],pilotsPerSym,1)-0.5)*2;

% Output check
if length(pilot) ~= pilotsPerSym
    error('Incorrect number of pilot symbols generated.');
end

end
