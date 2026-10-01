sca;
close all;
clear;

PsychDefaultSetup(2);

Screen('Preference', 'SkipSyncTests', 1);
Screen('Preference', 'ConserveVRAM', 16384);

screens = Screen('Screens');
screenNumber = 0;

white = WhiteIndex(screenNumber);
grey = white / 2;

% Open the screen
[window, windowRect] = Screen('OpenWindow', screenNumber, grey);

% --------------------
% Gabor information
% --------------------
gaborDimPix = windowRect(4) / 2;
sigma = gaborDimPix / 7;
orientation = 0;
contrast = 0.8;
aspectRatio = 1.0;
phase = 0;

numCycles = 5;
freq = numCycles / gaborDimPix;

backgroundOffset = [0.5 0.5 0.5 0.0];
disableNorm = 1;
preContrastMultiplier = 0.5;
 

gabortex = CreateProceduralGabor( ...
    window, gaborDimPix, gaborDimPix, [], ...
    backgroundOffset, disableNorm, preContrastMultiplier);

propertiesMat = [phase, freq, sigma, contrast, aspectRatio, 0, 0, 0];

Screen('DrawTextures', ...
    window, gabortex, [], [], orientation, [], [], [], [], ...
    kPsychDontDoRotation, propertiesMat');

Screen('Flip', window);

KbStrokeWait;

sca;
