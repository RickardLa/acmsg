% a)
clc
clf
clear all
close all


preamble = [1 1 1 -1 -1 1 -1];     % Barker code, https://en.wikipedia.org/wiki/Barker_code
        
   
Tp = length(preamble);                                  % length of preamble
Tx = randi([1,20], 1);                                  % Generate a random delay between 1 and 20
%rx = awgn([zeros(1, Tx) preamble], 10, 'measured');     % insert the sequence after the delay
rx = [zeros(1,Tx) preamble];
corr = conv(rx, fliplr(preamble));                      % correlate the sequence and received vector
figure;
plot(corr, '.-r')                                       % plot correlation

E = sum(abs(preamble).^2);                              % find the energy of the sequence

[tmp, Tmax] = max(corr);                                %find location of max correlation
Tx_hat = Tmax - length(preamble);                       %find delay
fprintf('delay = %d, estimation = %d\n', Tx, Tx_hat)

%  corr_coeff = corr/E;                                  % get correlation coefficient
%  figure; 
%  plot(corr_coeff,'.-b')  % plot it


% % b
% seq_error = preamble;
% seq_error(1) = ~seq_error(1);
% seq_error(7) = ~seq_error(7);
% 
% Tx = randi([1,20], 1);       % Generate a random delay between 1 and 20
% rx = awgn([zeros(1, Tx) seq_error], -0, 'measured');     % insert the sequence after the delay
% corr = conv(rx, fliplr(seq_error));   % correlate the sequence and received vector
% figure; plot(corr, '.-r')       % plot correlation
% 
% E = sum(abs(seq_error).^2);           % find the energy of the sequence
% 
% [tmp, Tmax] = max(corr);         %find location of max correlation
% Tx_hat = Tmax - length(seq_error);  %find delay
% fprintf('delay = %d, estimation = %d\n', Tx, Tx_hat)
% 
% corr_coeff = corr/E;            % get correlation coefficient
% figure; plot(corr_coeff,'.-b')  % plot it


%% 
% Is the choice of the sequence important for estimating the delay?
% Try different sequences and see if it answers the question above. 
% Try, plot(xcorr(seq)) on different sequences and observe the shape and
% width besides the point of maximum correlation coefficient
