% An example showing how to load and play a waveform,
% Plot Power spectral density using Welch's periodogram averaging method
clc; close all; clear all
*
%[Y, fs]  = wavread('tms');      % help wavread, is fs necessary?
[Y, fs] = audioread('tms.wav');
% Plot and look at the signal Y
figure; pwelch(Y,[] ,[] ,[],fs) % help pwelch, Welch's periodogram averaging

% Add noise
Y_noise = awgn(Y, 10);          % help awgn, try different SNRs
figure; pwelch(Y_noise,[] ,[] ,[],fs) 

%% Play the waveforms
sound(Y,fs)                     % Is fs necessary? Try different fs
pause(0.5)
sound(Y_noise,fs)

% Generate your own waveforms 