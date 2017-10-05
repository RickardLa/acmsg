%% Common parameters for transmitter and receiver
fc = 5000;                               % Carrier frequency [Hz]
N = 432;                                 % Number of bits
fs = 22005;                              % Sampling frequency [samples/s]
Rb = 440;                                % Bit rate [bit/s]
rollOff = 0.3;                           % Roll off factor for RRC-pulse
span = 6;                                % Truncation of pulse
constQAM = [(1 + 1i) (1 - 1i) ...           % Constellation for 4-QAM. Divide by sqrt(2) for unit energy
    (-1 -1i) (-1 + 1i)]/sqrt(2);
constBPSK = [1 -1];
preamble = [1 1 1 1 1 0 0 1 1 0 1 0 1];

fsy = Rb/2;                              % Symbol frequency [symbols/s]
Tsy = 1/fsy;                             % Symbol time/period [s/symbols]
Ts = 1/fs;                               % Sampling time/period [s/sample]
fsfsy = floor(fs/fsy);                          % Used for upsampling [samples/symbols]
pulse = rtrcpuls(rollOff,Tsy,fs,span);   % Generate pulse using rtrcpuls()

preambleIdx = bi2de(preamble', 'left-msb')+1;
preambleMap = constBPSK(preambleIdx);
preambleUP = upsample(preambleMap,fsfsy);
preamblePulse = conv(pulse,preambleUP);