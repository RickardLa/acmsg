function [] = receiverTest(RxSignal)

run('commonParameters.m')

% Demodulate signal
t = (0:length(RxSignal)-1)*Ts;           % Signal contains samples. Multiplying by the sampling time gives the time of the signal
signalBase = RxSignal.*cos(2*pi*fc.*t);  % Passband to baseband

% Phase and frequency synchronization
crosscorr = conv(signalBase, fliplr(preamblePulse));
[peak, index] = max(abs(crosscorr));    
plot(real(crosscorr),'-r')

    if peak > 250                                             % Set threshold
        tStart = floor((index - length(preamblePulse)));
        preamble = signalBase(tStart+1:index);

        % Filter and downsample found preamble
        MF = fliplr(conj(pulse));
        MF_output = conv(MF, preamble)/fsfsy;
        MF_output = MF_output(length(MF):end-length(MF)+1);
        preambleDown = downsample(MF_output,fsfsy);

        % Time to find the phase
        % stem(preambleDown)
    else
        disp('Pilot not found. Try changing threshold.')
    end

end
