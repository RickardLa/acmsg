function [] = receiverTest(RxSignal,pulse)
% Parameters to edit
fc = 5000;                               % Carrier frequency [Hz]
N = 432;                                 % Number of bits
fs = 44000;                              % Sampling frequency [samples/s]
Rb = 440;                                % Bit rate [bit/s]
const = [(1 + 1i) (1 - 1i) ...           % Constellation for 4-QAM.
    (-1 -1i) (-1 + 1i)]/sqrt(2);     % Divide by sqrt(2) for unit energy
preamble = [1 1 1 -1 -1 1 -1];
pilot = ones(1,20);

preLength = length(preamble);
pLength = length(pilot);
% Declare additional parameters
fsy = Rb/2;                              % Symbol frequency [symbols/s]
Tsy = 1/fsy;                             % Symbol time/period [s/symbols]
Ts = 1/fs;                               % Sampling time/period [s/sample]
fsfsy = fs/fsy;                          % Used for upsampling [samples/symbols]
pilotUP = upsample(pilot,fsfsy);

% Demodulate signal
t = (0:length(RxSignal)-1)*Ts;           % Signal contains samples. Multiplying by the sampling time gives the time of the signal
signalBase = RxSignal.*cos(2*pi*fc.*t);  % Passband to baseband

% Phase and frequency synchronization
crosscorr = conv(real(signalBase), fliplr(pilotUP));
[peak, index] = max(abs(crosscorr));    
plot(crosscorr,'-r')
if peak > 5                                              % Set threshold
    tStart = index - length(pilotUP);                         
    pilot1 = signalBase(tStart:tStart+length(pilotUP));
    fourier = fft(pilot1);
    tmpFourier = [real(fourier) imag(fourier)];
    phaseShift = wrapTo2Pi(angle(((mean(tmpFourier)))))
    
else
    disp('Pilot not found')
end


% Filter baseband-signal with matched filter
MF = fliplr(conj(pulse));
MF_output = conv(MF, signalBase)/fsfsy;
MF_output = MF_output(length(MF):end-length(MF)+1);
signalDown = downsample(MF_output,fsfsy);


% % Minimum Eucledian distance detector from EX 6
% metric = abs(repmat(signalDown.',1,4) - repmat(const, length(signalDown), 1)).^2;   % compute the distance to each possible symbol
% [tmp m_hat] = min(metric, [], 2);                                           % find the closest constellation point for each received symbol
% a_hat_buffer = de2bi(m_hat-1, 2, 'left-msb')';                              % make symbols into bits
% a_hat = a_hat_buffer(:)';                                                   % write as a vector


% % Frame Synch
% crosscorr = conv(real(signalDown), fliplr(preamble));
% [peak, index] = max(crosscorr);                          % Find peak
% plot(crosscorr,'.-b')
% if peak > 2                                              % Set threshold
%     tDelay = index - preLength;                            % Time delay 
%     signalDown = signalDown(index+1:end);                % Remove delay and preamble
%     %scatterplot(signalDown)
% else
%     disp('Preamble not found')
% end

%------------------------------------------------------------------------------
% NOW THAT WE HAVE DECODED OUR MESSAGE; IT IS TIME TO SAVE THE DATA FOR THE GUI
%------------------------------------------------------------------------------

% % Step 1: save the estimated bits
% recObj.UserData.pack = a_hat;
% 
% % Step 2: save the sampled symbols
% recObj.UserData.const = rx_vec;
% 
% % Step 3: provide the matched filter output for the eye diagram
% recObj.UserData.eyed.r = MF_output;
% recObj.UserData.eyed.fsfd = fsfd;
% 
% % Step 4: Compute the PSD and save it. Note that it has to be computed on
% % the BASE BAND signal BEFORE matched filtering
% [pxx, f] = pwelch(received_signal,1024,768,1024, fs); % note that pwr_spect.f will be normalized frequencies
% f = fftshift(f); %shift to be centered around fs
% f(1:length(f)/2) = f(1:length(f)/2) - fs; % center to be around zero
% p = fftshift(10*log10(pxx/max(pxx))); % shift, normalize and convert PSD to dB
% recObj.UserData.pwr_spect.f = f;
% recObj.UserData.pwr_spect.p = p;
% 
% % In order to make the GUI look at the data, we need to set the
% % receive_complete flag equal to 1:
% recObj.UserData.receive_complete = 1; 









end
