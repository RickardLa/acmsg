function [audio_recorder] = receiver(fc)

fs = 22050; %sampling frequency
audio_recorder = audiorecorder(fs,24,1);% create the recorder

%ADD USER DATA FOR CALLBACK FUNCTION
audio_recorder.UserData.receive_complete = 0; % this is a flag that the while loop in the GUI will check
audio_recorder.UserData.pack  = []; %allocate for data package
audio_recorder.UserData.pwr_spect = []; %allocate for PSD
audio_recorder.UserData.const = []; %allocate for constellation
audio_recorder.UserData.eyed  = []; %allocate for eye diagram

%attach callback function
time_value = 1; % how often the function should be called in seconds
set(audio_recorder,'TimerPeriod',time_value,'TimerFcn',@audioTimerFcn); % attach a function that should be called every second, the function that is called is specified below.

record(audio_recorder); %start recording

end

% CALLBACK FUNCTION
% This function will be called every [time_value] seconds, where time_value
% is specified above. Note that, as stated in the project MEMO, all the
% fields: pwr_spect, eyed, const and pack need to be assigned if you want
% to get outputs in the GUI.

% So, let's see an example of where we have a pulse train as in Computer
% exercise 2 and let the GUI plot it. Note that we will just create 432
% random bits and hence, the GUI will not be able to decode the message but
% only to display the figures.
% Parameters in the example:
% f_s = 22050 [samples / second]
% R_s = 350 [symbols / second]
% fsfd = f_s/R_s [samples / symbol]
% a = 432 bits
% M = 4 (using QPSK as in computer exercise)

function audioTimerFcn(recObj, event, handles)

%-----------------------------------------------------------
% THE CODE BELOW IS FROM EX 5 AND EX 6:
%-----------------------------------------------------------
fs = 22050;                                             % sampling frequency
N = 432;                                                % number of bits
const = [(1 + 1i) (1 - 1i) (-1 -1i) (-1 + 1i)]/sqrt(2); % Constellation 1 - QPSK/4-QAM
M = length(const);                                      % Number of symbols in the constellation
bpsymb = log2(M);                                       % Number of bits per symbol
Rs = 350;                                               % Symbol rate [symb/s]
fsfd = fs/Rs;                                           % Number of samples per symbol (choose fs such that fsfd is an integer for simplicity) [samples/symb]
a = randsrc(1,N,[0 1]);                                 % Information bits
m_buffer = buffer(a, bpsymb)';                          % Group bits into bits per symbol
m = bi2de(m_buffer, 'left-msb')'+1;                     % Bits to symbol index
x = const(m);                                           % Look up symbols using the indices
x_upsample = upsample(x, fsfd);                         % Space the symbols fsfd apart, to enable pulse shaping using conv.
span = 6;                                               % Set span = 6
[pulse, t] = rtrcpuls(0.35,1/Rs,fs,span);               % create pulse with span = 6
pulse_train = conv(pulse,x_upsample);                   % make pulse train
pulse_train_notransient = pulse_train(span*fsfd:(end-span*fsfd + 1)); % remove transients 

received_signal = awgn(pulse_train_notransient, 5, 'measured'); %ADD NOISE, i.e., run through artificial channel

MF = fliplr(conj(pulse));                               % create matched filter impulse response
MF_output = conv(pulse, received_signal);               % Run through matched filter
MF_output = MF_output(span*fsfd:(end-span*fsfd + 1));   % remove transients
rx_vec = MF_output(1:fsfd:end);                         % sample output symbols

% Minimum Eucledian distance detector from EX 6
metric = abs(repmat(rx_vec.',1,4) - repmat(const, length(rx_vec), 1)).^2;   % compute the distance to each possible symbol
[tmp m_hat] = min(metric, [], 2);                                           % find the closest constellation point for each received symbol
a_hat_buffer = de2bi(m_hat-1, 2, 'left-msb')';                              % make symbols into bits
a_hat = a_hat_buffer(:)';                                                   % write as a vector

%------------------------------------------------------------------------------
% NOW THAT WE HAVE DECODED OUR MESSAGE; IT IS TIME TO SAVE THE DATA FOR THE GUI
%------------------------------------------------------------------------------

% Step 1: save the estimated bits
recObj.UserData.pack = a_hat;

% Step 2: save the sampled symbols
recObj.UserData.const = rx_vec;

% Step 3: provide the matched filter output for the eye diagram
recObj.UserData.eyed.r = MF_output;
recObj.UserData.eyed.fsfd = fsfd;

% Step 4: Compute the PSD and save it. Note that it has to be computed on
% the BASE BAND signal BEFORE matched filtering
[pxx, f] = pwelch(received_signal,1024,768,1024, fs); % note that pwr_spect.f will be normalized frequencies
f = fftshift(f); %shift to be centered around fs
f(1:length(f)/2) = f(1:length(f)/2) - fs; % center to be around zero
p = fftshift(10*log10(pxx/max(pxx))); % shift, normalize and convert PSD to dB
recObj.UserData.pwr_spect.f = f;
recObj.UserData.pwr_spect.p = p;

% In order to make the GUI look at the data, we need to set the
% receive_complete flag equal to 1:
recObj.UserData.receive_complete = 1; 

    
end
