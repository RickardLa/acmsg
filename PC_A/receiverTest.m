function [] = receiverTest(RxSignal,bitstream)
run('commonParameters.m')

% Demodulate signal
t = (0:length(RxSignal)-1)*Ts;           
baseBandSignal = RxSignal.*exp(1i*2*pi*fc.*t);  

% Low-pass filter
[b,a] = butter(1, fc/(2*fs), 'low');
signalBase = filtfilt(b,a,baseBandSignal);
signalBase = signalBase/(max(abs(signalBase)));                     % Normalize signal


% Cross correlation to find start of preamble
E_pre = sum(abs(preamblePulse).^2);                                 % Energy in preamble 
E_sig = conv(ones(1,length(preamblePulse)), abs(signalBase.^2));    % Energy of signal in a window the same length as the preamble
crosscorr = conv(signalBase, fliplr(preamblePulse)) ./ sqrt(E_pre*E_sig);

[peak, index] = max(abs(crosscorr));            
% plot(real(crosscorr))
if peak > 0.5
    tStart = index -length(preamblePulse);       % Start of preamble
    preamble = signalBase(tStart+1:index);       % Extract preamble from signalBase
    
    % Matched filtering and downsampling
    MF = fliplr(conj(pulse));
    MF_output1 = conv(MF,preamble)/fsfsy;
    MF_output1 = MF_output1(length(MF):end-(length(MF)+1));
    preamble = downsample(MF_output1,fsfsy);
    
    % First 5 bits of preamble are ones. Expected phase is then pi/4.
    % Calculate difference from received preamble.
    phaseShift = mean((wrapToPi(angle(preamble(1:5)))))+3*pi/4;
    
else
    disp('No preamble found')
    return;
end


% Recover correct phase and extract data from signalBase
signalBase = signalBase.*exp(-1i*phaseShift);   
dataStart = index+span*(1-fsfsy);
data = signalBase(dataStart:end-span*(1+fsfsy));

% Matched filter data and down-sample
MF = fliplr(conj(pulse));
MF_output1 = conv(MF,data)/fsfsy;
MF_output1 = MF_output1(length(MF)+ span*(1-fsfsy):end-(length(MF)+span*(1-fsfsy)));
data = downsample(MF_output1,fsfsy);
% scatterplot(data)
% title('Data')

% 4-QAM --> 4 decision regions
data(real(data) > 0 & imag(data) > 0) = 1;    
data(real(data) > 0 & imag(data) < 0) = 2;
data(real(data) < 0 & imag(data) < 0) = 3;
data(real(data) < 0 & imag(data) > 0) = 4;

% Convert symbols to bits
receivedBitPairs = de2bi(data-1, 'left-msb',2);       % Convert the integer [0,1,2,3] to bits
bitVector = reshape(receivedBitPairs,[N,1]);          % Reshape matrix into vector with N rows
bitError = sum(bitVector ~= bitstream)                % Calculates biterror 








  
end
