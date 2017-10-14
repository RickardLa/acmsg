function [audio_recorder] = receiver(fc)


audio_recorder = audiorecorder(22050,24,1);                             % Create recorder

%ADD USER DATA FOR CALLBACK FUNCTION
audio_recorder.UserData.receive_complete = 0;                           
audio_recorder.UserData.pack  = [];
audio_recorder.UserData.pwr_spect = [];
audio_recorder.UserData.const = [];
audio_recorder.UserData.eyed  = [];

audio_recorder.UserData.flag = 0;                                       % 0 = Preamble has not been found
audio_recorder.UserData.phaseShift = 0;                                 % Phaseshift in preamble
audio_recorder.UserData.index = 0;                                      % Index of peak in cross-correlation
audio_recorder.UserData.fc = fc;                                        % Carrier frequency


time_value = 0.1;                                                       % Initially, when listening for preamble, call function 10 times per second
set(audio_recorder,'TimerPeriod',time_value,'TimerFcn',@audioTimerFcn); % Call audioTimerFcn

record(audio_recorder);                                                 % Start recording

end



function audioTimerFcn(recObj, event, handles)

if exist('preamble','var') == 0                                         % Avoid running commonParameters.m every time the function is called
    run('commonParameters.m')
end


fc = recObj.UserData.fc;
preambleTime = length(preamble)/Rb;
dataTime = N/Rb;


if recObj.UserData.flag == 0
    
    % Listen for preambleTime seconds and save in RxPreamble
    pause(preambleTime);                                               
    RxPreamble = getaudiodata(recObj);                                 
    
    % Demodulate signal
    t = (0:length(RxPreamble')-1)*Ts;
    baseBandSignal = RxPreamble'.*exp(1i*2*pi*fc.*t);
    
    % Convolve with pulse to remove high frequencies and remove transients
    signalBase = conv(baseBandSignal,pulse);
    signalBase =  signalBase(length(pulse):end-(length(pulse)+1));
    
    % Correlate received signal with pulse to find preamble 
    E_pre = sum(abs(preamblePulse).^2);                                         % Energy in preamble
    E_sig = conv(ones(1,length(preamblePulse)), abs(signalBase.^2));            % Energy of signal in a window the same length as the preamble
    crosscorr = conv(signalBase, fliplr(preamblePulse)) ./ sqrt(E_pre*E_sig);
    [peak, recObj.UserData.index] = max(abs(crosscorr));
    
    
    if peak > 0.7                                                               % Set threshold of peak 
        
        % Find start of preamble and extract it from signalBase
        tStart = recObj.UserData.index -length(preamblePulse);                  
        preamble = signalBase(tStart+1:recObj.UserData.index);                  
        
        % Matched filter found preamble and downsample it 
        MF = fliplr(conj(pulse));
        MF_output1 = conv(MF,preamble)/fsfsy;
        MF_output1 = MF_output1(length(MF):end-(length(MF)+1));
        preamble = downsample(MF_output1,fsfsy);
        
        % First 5 bits of preamble are ones. Expected phase is pi/4.
        % Calculate difference from received preamble.
        recObj.UserData.phaseShift = mean((wrapToPi(angle(preamble(1:5)))))+3*pi/4;
        
        % Update time_value. audioTimerFcn will now only be called once
        % every second to listen to the actual data
        recObj.UserData.flag = 1;
        time_value = 1;
        set(audio_recorder,'TimerPeriod',time_value,'TimerFcn',@audioTimerFcn);
        
    else                                 % If preamble not found, exit audioTimerFcn
        return;                     
    end
    
else                                     % If preamble has been found, listen to data 
    
    pause(dataTime);
    RxData = getaudiodata(recObj);
    stop(recObj);                       % Preamble + data has been recorded -> Stop recording
    
    % Demodulate signal
    t = (0:length(RxData')-1)*Ts;
    baseBandSignal = RxData'.*exp(1i*2*pi*fc.*t);
    
    % Convolve with pulse to remove high frequencies and remove transients
    signalBase = conv(baseBandSignal,pulse);
    signalBase =  signalBase(length(pulse):end-(length(pulse)+1));
    
    % Recover phase and extract data from signalBase
    signalBase = signalBase.*exp(-1i*recObj.UserData.phaseShift);
    dataStart = recObj.UserData.index+span*(1-fsfsy);
    data = signalBase(dataStart:dataStart+N/2*fsfsy);
    
    % Matched filter data and down-sample
    MF = fliplr(conj(pulse));
    MF_output1 = conv(MF,data)/fsfsy;
    MF_output1 = MF_output1(length(MF)+ span*(1-fsfsy):end-(length(MF)+span*(1-fsfsy)));
    rx_vec = downsample(MF_output1,fsfsy);
    
    recObj.UserData.receive_complete = 1;
    
    % Calculate minimum distance to constellation points and make guess
    metric = abs(repmat(rx_vec.',1,4) - repmat(constQAM, length(rx_vec),1)).^2;
    [tmp m_hat] = min(metric, [], 2);
    a_hat_buffer = de2bi(m_hat-1,2,'left-msb');
    a_hat = a_hat_buffer(:)';
    
    
   
    recObj.UserData.pack =  a_hat;
    recObj.UserData.const = 10.*rx_vec';                       % Multiply by 10 to make scatterplot more visible
    recObj.UserData.eyed.r = MF_output1;
    recObj.UserData.eyed.fsfd = fsfsy;
    
 
    [pxx, f] = pwelch(baseBandSignal,1024,768,1024, fs);        % note that pwr_spect.f will be normalized frequencies
    f = fftshift(f);                                            %shift to be centered around fs
    f(1:length(f)/2) = f(1:length(f)/2) - fs;                   % center to be around zero
    p = fftshift(10*log10(pxx/max(pxx)));                       % shift, normalize and convert PSD to dB
    recObj.UserData.pwr_spect.f = f;
    recObj.UserData.pwr_spect.p = p;
    recObj.UserData.flag = 0;
    
end
end
