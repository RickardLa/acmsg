function [] = receiverTest(RxSignal)

% RxSignal is a normalized passband signal 

run('commonParameters.m')

% Demodulate signal
t = (0:length(RxSignal)-1)*Ts;           
signalBase = RxSignal.*exp(1i*2*pi*fc.*t);  

% Low-pass filter
[b,a] = butter(10, fc/(2*fs), 'low');
signalBase = filtfilt(b,a,signalBase);
signalBase = signalBase/(max(abs(signalBase)));                 % Normalize signal
length(signalBase)

% Cross correlation to find start of preamble
E_pre = sum(abs(preamblePulse).^2); %energy in preamble 
E_sig = conv(ones(1,length(preamblePulse)), abs(signalBase.^2)); % energy of signal in a window the same length as the preamble
crosscorr = conv(signalBase, fliplr(preamblePulse)) ./ sqrt(E_pre*E_sig);
[peak, index] = max(abs(crosscorr));            
tStart = index -length(preamblePulse);     % Index of start of preamble   
preamble = signalBase(tStart+1:index);      % Extract preamble from signalBase

data = signalBase(index+1:216*fsfsy);
% % Matched filtering and downsampling
% MF = fliplr(conj(pulse));
% MF_output1 = conv(MF,preamble)/fsfsy;
% MF_output1 = MF_output1(length(MF):end-(length(MF)+1));
% preamble = downsample(MF_output1,fsfsy);
% lengthPreamble = length(preamble)
% scatterplot(preamble)
% title('Preamble')
        

length(data)

% Matched filtering and downsampling
MF = fliplr(conj(pulse));
MF_output1 = conv(data,MF)/fsfsy;
MF_output1 = MF_output1(length(MF):end-(length(MF)+1));
data = downsample(MF_output1,fsfsy);
lengthData = length(data)
scatterplot(data)
title('Data')

  
end
