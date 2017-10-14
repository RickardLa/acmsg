%% Common parameters for transmitter and receiver
N = 432;                                 % Number of bits
fs = 22050;                              % Sampling frequency [samples/s]
Rb = 390;                                % Bit rate [bit/s]
rollOff = 0.35;                           % Roll off factor for RRC-pulse
span = 4;                               % Truncation of pulse

preamble = [1 1 1 1 1 0 0 1 1 0 1 0 1];

constQAM = [(1 + 1i) (1 - 1i) ...          
    (-1 -1i) (-1 + 1i)]/sqrt(2);
constBPSK = [(1 + 1i) (-1 - 1i)]/sqrt(2);


fsy = Rb/2;                              % Symbol frequency [symbols/s]
Tsy = 1/fsy;                             % Symbol time/period [s/symbols]
Ts = 1/fs;                               % Sampling time/period [s/sample]
fsfsy = floor(fs/fsy);                          % Used for upsampling [samples/symbols]
pulse = rtrcpuls(rollOff,Tsy,fs,span);   % Generate pulse using rtrcpuls()

preambleIdx = bi2de(preamble', 'left-msb')+1;
preambleMap = constBPSK(preambleIdx);
preambleUP = upsample(preambleMap,fsfsy);
preamblePulse = conv(preambleUP,pulse);
