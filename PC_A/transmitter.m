function transmitter(packet,fc)

run('commonParameters.m')

% Map data to constellation
message = buffer(packet,N/2);              % Buffers bitstream into data frames with length 2
messageIdx = bi2de(message, 'left-msb')+1;    % Convert data frames to decimal. Adding 1 for correct matrix-indexing
dataMap = constQAM(messageIdx);               % Map each data frame to a constellation point

% Upsample map and convolve with RRC-pulse
map = [preambleMap dataMap];
mapUP =upsample(map,fsfsy);                   % Space the data fsfsy-apart to sample once per symbol
signalBase = conv(pulse,mapUP);               % Convolving generates a complex baseband signal 

% Convert baseband-signal to passband-signal by modulation
t = (0:length(signalBase)-1)*Ts;                                % Signal contains samples
signalPass = real(signalBase.*exp(-1i*2*pi*fc.*t));             % Baseband to passband
signalPass = signalPass/(max(abs(signalPass)));                 % Normalize signal
sound(signalPass,fs)                                            % Play through speakers

end