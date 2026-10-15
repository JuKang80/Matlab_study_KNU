clear;
clc;
close all;
sca;

PsychDefaultSetup(2);
Screen('Preference', 'SkipSyncTests', 1);

try
    % ========================================
    % 1. PsychImaging 설정
    % ========================================

    PsychImaging('PrepareConfiguration');

    % 32-bit floating-point framebuffer
    PsychImaging('AddTask', ...
        'General', 'FloatingPoint32Bit');

    % 색상 보정 LUT 매핑 설정
    PsychImaging('AddTask', ...
        'AllViews', 'EnableCLUTMapping');

    % 화면 선택
    screens = Screen('Screens');
    screenNumber = max(screens);

    white = WhiteIndex(screenNumber);
    black = BlackIndex(screenNumber);
    gray = (white + black) / 2;

    % 설정을 적용하여 화면 열기
    [window, windowRect] = PsychImaging( ...
        'OpenWindow', screenNumber, gray);

    % ========================================
    % 2. 색 명명 자극
    % ========================================

    KbName('UnifyKeyNames');

    fKey = KbName('f');
    jKey = KbName('j');
    escKey = KbName('ESCAPE');

    [xCenter, yCenter] = RectCenter(windowRect);

    patchSize = 300;
    patchRect = CenterRectOnPointd( ...
        [0 0 patchSize patchSize], xCenter, yCenter);

    colorRGB = [0.65 0.80 0.25];

    Screen('FillRect', window, gray);
    Screen('FillRect', window, colorRGB, patchRect);

    DrawFormattedText(window, ...
        'Color Naming Demo\n\nF = Yeondu    J = Chorok\nESC = Exit', ...
        'center', yCenter + 230, white);

    Screen('Flip', window);

    % ========================================
    % 3. 응답 및 반응시간
    % ========================================

    startTime = GetSecs;
    response = '';

    while true
        [keyIsDown, secs, keyCode] = KbCheck;

        if keyIsDown
            if keyCode(escKey)
                break;
            elseif keyCode(fKey)
                response = 'Yeondu';
                RT = secs - startTime;
                break;
            elseif keyCode(jKey)
                response = 'Chorok';
                RT = secs - startTime;
                break;
            end
        end
    end

    if ~isempty(response)
        fprintf('Response: %s\n', response);
        fprintf('RT: %.3f seconds\n', RT);
    end

    sca;

catch ME
    sca;
    rethrow(ME);
end