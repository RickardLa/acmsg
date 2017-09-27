%------------------------------
%         EXERCISE C1
% 
%       ADVICE:
%       how to create time vector (span several symbol times and 
%       sinc
%       fft
%       fftshift
%       unwrap
%       anonymous functions
%------------------------------
function Ex123
close all
clc
% RC
func0 = @(alpha,tau,tvec) sinc(tvec/tau).*cos((pi*alpha/tau)*tvec)./(1-((2*alpha/tau)*tvec).^2);
% Bandlimited signals made of sinc
func1 = @(Ts,tvec) 6*sinc(tvec/(2*Ts)).^2 + sinc(tvec/(6*Ts)).^6 + 6*sinc(tvec/(10*Ts)).^10;
% Twosided exponential
func2 = @(a,tvec) exp(-a*abs(tvec));
% Sum of sinusoids
func3 = @(f1,f2,f3,f4,tvec) sin(2*pi*f1.*tvec) + (1/3)*sin(2*pi*f2.*tvec) + (1/5)*sin(2*pi*f3.*tvec) + (1/7)*sin(2*pi*f4.*tvec);
% Gaussian
func4 = @(sigma,tvec) exp(-tvec.^2/(2*sigma^2))/(sigma*sqrt(2*pi));
% Rectangular pulse
func5 = @(tau,tvec) heaviside(tau/2 + eps + tvec) - heaviside(tvec - eps - tau/2);

%% Sampling and reconstruction, RC pulse
funflag = 1;
                
if funflag == 0           
    Ts = 0.01;                      % Symbol time [s]
    alpha = 0.3;                    % Excess bandwidth factor
    BW = (1+alpha)/(2*Ts);          % Occupied bandwidth (one-sided)
else
    Ts = 0.025;                     % Symbol time [s]
    BW = 1/(2*Ts);                  % Bandwidth (one-sided)
end

fs = 2*BW;                          %sampling frequency
span = 6;                           % span of time vector

tvec = eps:(1/fs):span*Ts;          % create time vector (positive times)
tvec = [-fliplr(tvec(2:end)) tvec]; % Make symmetric around zero



% Similar looking to continuous-time signal
fss = 50*BW;                                % high sampling rate
tvecc = eps:(1/fss):span*Ts;                % create time vector for sampling rate
tvecc = [-fliplr(tvecc(2:end)) tvecc];      % Make symmetric around zero

switch funflag
    case 0
        fun = func0;                         % assign function handle
        sig = fun(alpha,Ts,tvec);            % create sampled signal
        p_continuous = fun(alpha,Ts,tvecc);  % create "continuous" signal
        
    case 1
        fun = func1;                         % assign function handle
        sig = fun(Ts,tvec);                  % create sampled signal
        p_continuous = fun(Ts,tvecc);        % create "continuous" signal
        
    case 2
        a = 2;                              % damping
        fun = func2;                        % assign function handle
        sig = fun(a,tvec);                  % create sampled signal
        p_continuous = fun(a,tvecc);        % create "continuous" signal
        
    case 3
        f1 = 1e3; f2= 2e3; f3 = 3e3; f4 = 4e3;  % frequencies of sinusoids
        fun = func3;                            % assign function handle
        sig = fun(f1,f2,f3,f4,tvec);            % create sampled signal
        p_continuous = fun(f1,f2,f3,f4,tvecc);  % create "continuous" signal
        
    case 4
        sigma = 1;                              % Standard deviation of pulse
        fun = func4;                            % assign function handle
        sig = fun(sigma,tvec);                  % create sampled signal
        p_continuous = fun(sigma,tvecc);        % create "continuous" signal
        
    case 5
        fun = func5;                            % assign function handle
        sig = fun(Ts,tvec);                     % create sampled signal
        p_continuous = fun(Ts,tvecc);           % create "continuous" signal
        
    otherwise
        return;
end

%[p_recons,t_recons, fs1]= reconstruct_sinc(sig,fs);     % Reconstruction
[p_recons,t_recons]= reconstruct_sinc_forloop(sig,fs);     % Reconstruction using for loop


% % Perform DFT and convert the digital frequencies to corresponding analog
N = length(sig);            % get length of signal
P = fftshift(fft(sig));     % Compute the Fourier transform of signal and center around zero
phase = unwrap(angle(P));   % compute phase
df = fs/N;                  % sampling frequency is split into N bins
fvec = df*(-floor(N/2):1:ceil(N/2)-1); % Truncated, has wide bandwidth


% Plot things
figure; stem(tvec,sig); title('Sampled signal')
hold on;
plot(tvecc,p_continuous,'r');
figure;
subplot(2,1,1);plot(fvec, 20*log10(abs(P)));
title('Frequency response of sampled signal')
xlabel('Frequency in Hz')
ylabel('Power in dB')
subplot(2,1,2); plot(fvec, phase*180/pi)
title('Phase response of sampled signal')
xlabel('Frequency in Hz')
ylabel('Phase (Degrees)')

figure; plot(t_recons, p_recons); hold on;
plot(tvecc,p_continuous,'r');
title('Reconstructed signal');
legend('Reconstructed','Equivalent to Continuous')


end

function [p_recons,t_recons]= reconstruct_sinc(sig,fs)
% % Reconstruction using truncated sinc
span1 = 20;                         % One sided width of the sinc pulse as multiple of Ts
fs1 = 10*fs;                        % Sampling rate of sinc function, chose integer multiple of f_samp
tau = 1/fs;                          % sampling time
tvec = eps:(1/fs1):span1*tau;        % create time vector
tvec = [-fliplr(tvec(2:end)) tvec];  % Create symmetric time vector
sinc_pulse = sinc(fs*tvec);          % Generate sinc pulse centered around 0 for reconstruction

% Upsample the pulse p to bring it to the same sampling time reference
p_upsamp = upsample(sig,fs1/fs);               % This signal now has a sampling rate of fs1, same as the sinc function
p_upsamp(end-fs1/fs+2:end)=[];                 % Remove the additional zeros introduced in the end
p_recons = conv(p_upsamp,sinc_pulse,'same');   % Expression (3) in exercise document
t_recons = (1/fs1).*(-floor(length(p_recons)/2):1:floor(length(p_recons)/2));
end



function [p_recons,t_recons]= reconstruct_sinc_forloop(sig,fs)
% % Reconstruction using truncated sinc
span1 = 20;                          % One sided width of the sinc pulse as multiple of Ts
fs1 = 10*fs;                         % Sampling rate of sinc function, chose integer multiple of f_samp
tau = 1/fs;                          % sampling time
tvec = eps:(1/fs1):span1*tau;        % create time vector
tvec = [-fliplr(tvec(2:end)) tvec];  % Create symmetric time vector

p_recons = zeros(1, length(tvec));                                  %allocate for reconstructed signal
for n = -floor(length(sig)/2) : floor(length(sig)/2)                %loop over all samples we have 
    curr_idx = n + floor(length(sig)/2) + 1;                        %sig has to start at 1
    p_recons = p_recons + sig(curr_idx)*sinc(fs*(tvec-n*tau));      % add current reconstruction signal
end

t_recons = (1/fs1).*(-floor(length(p_recons)/2):1:floor(length(p_recons)/2)); %make time vector for reconstructed signal

end