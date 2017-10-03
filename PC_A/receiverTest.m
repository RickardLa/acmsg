function [] = receiverTest(RxSignal,pulse)
% Parameters to edit
fc = 5000;                               % Carrier frequency [Hz]
N = 432;                                 % Number of bits
fs = 44000;                              % Sampling frequency [samples/s]
Rb = 440;                                % Bit rate [bit/s]
const = [(1 + 1i) (1 - 1i) ...           % Constellation for 4-QAM.
    (-1 -1i) (-1 + 1i)]/sqrt(2);     % Divide by sqrt(2) for unit energy
preamble = [1 1 1 -1 -1 1 -1];
pLength = length(preamble);
% Declare additional parameters
fsy = Rb/2;                              % Symbol frequency [symbols/s]
Tsy = 1/fsy;                             % Symbol time/period [s/symbols]
Ts = 1/fs;                               % Sampling time/period [s/sample]
fsfsy = fs/fsy;                          % Used for upsampling [samples/symbols]


% Demodulate signal
t = (0:length(RxSignal)-1)*Ts;           % Signal contains samples. Multiplying by the sampling time gives the time of the signal
signalBase = RxSignal.*cos(2*pi*fc.*t);  % Passband to baseband

% PSD calculation
% pwelch(signalBase,[],[],[],fs,'power','centered');
% figure
 
% Filter baseband-signal with matched filter
MF = fliplr(conj(pulse));
MF_output = conv(MF, signalBase)/fsfsy;
MF_output = MF_output(length(MF):end-length(MF)+1);
signalDown = downsample(MF_output,fsfsy);


% Minimum Eucledian distance detector from EX 6
metric = abs(repmat(signalDown.',1,4) - repmat(const, length(signalDown), 1)).^2;   % compute the distance to each possible symbol
[tmp m_hat] = min(metric, [], 2);                                           % find the closest constellation point for each received symbol
a_hat_buffer = de2bi(m_hat-1, 2, 'left-msb')';                              % make symbols into bits
a_hat = a_hat_buffer(:)';                                                   % write as a vector
stem(a_hat)

% % Frame Synch
% crosscorr = conv(real(signalDown), fliplr(preamble));
% [peak, index] = max(crosscorr);                          % Find peak
% plot(crosscorr,'.-b')
% if peak > 2                                              % Set threshold
%     tDelay = index - pLength;                            % Time delay 
%     signalDown = signalDown(index+1:end);                % Remove delay and preamble
%     scatterplot(signalDown)
% else
%     disp('Preamble not found')
% end









end
