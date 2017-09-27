function transmitter(packet,fc)


N = 432;                                 % Number of bits
fs = 44000;                              % Sampling frequency [samples/s]
Rb = 440;                                % Bit rate [bit/s]
rollOff = 0.3;                           % Roll off factor for RRC-pulse
span = 2;                                % Truncation of pulse
SNR = -10;                               % Signal-to-noise ratio [dB]
const = [(1 + 1i) (1 - 1i) ...           % Constellation for 4-QAM. Divide by sqrt(2) for unit energy
        (-1 -1i) (-1 + 1i)]/sqrt(2);     

% Declare additional parameters
fsy = Rb/2;                              % Symbol frequency [symbols/s]
Tsy = 1/fsy;                             % Symbol time/period [s/symbols]
Ts = 1/fs;                               % Sampling time/period [s/sample]
fsfsy = fs/fsy;                          % Used for upsampling [samples/symbols]
pulse = rtrcpuls(rollOff,Tsy,fs,span);   % Generate pulse using rtrcpuls()

% Generate bitstream and map to constellation points 
%bitstream = randsrc(N,1,[0 1]);              % Generates column-vector with bits
message = buffer(packet,N/2);                 % Buffers bitstream into data frames with length 2
messageIdx = bi2de(message, 'left-msb')+1;    % Convert data frames to decimal. Adding 1 for correct matrix-indexing
map = const(messageIdx);                      % Map each data frame to a constellation point

% Upsample map and convolve with RRC-pulse
mapUP = upsample(map,fsfsy);                  % Space the data fsfsy-apart to sample once per symbol
signalBase = conv(pulse,mapUP);               % Convolving generates a baseband signal containing real and imaginary parts

% Convert baseband-signal to passband-signal by modulation
t = (0:length(signalBase)-1)*Ts;                                % Signal contains samples. Multiplying by the sampling time gives the time of the signal       
signalPass = signalBase.*(cos(2*pi*fc.*t)-1i*sin(2*pi*fc.*t));  % Baseband to passband
signalPass = signalPass/(max(abs(signalPass)));                 % Normalize signal
% Add noise to modulated signal and then transmit 
%signalNoise = awgn(signalPass, SNR, 'measured'); 
sound(real(signalPass),fs);


end