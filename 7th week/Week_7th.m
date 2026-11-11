% 화면이 전환될 때마다 점점 크기가 커지며 색이 랜덤으로 변하는 사각형을 그리세요.
% 화면 전환 방식은 마우스 입력으로 설정하세요.

clear;
clc;
close all;
sca;

Screen('Preference', 'SkipSyncTests', 1);
PsychDefaultSetup(1);

try
    screens = Screen('Screens');
    screenNumber = max(screens);
    white = WhiteIndex(screenNumber);
    black = BlackIndex(screenNumber);
    gray = white / 2;

    [window, windowRect] = Screen('OpenWindow', screenNumber, gray);
    Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');
    Screen('TextSize', window, 22);

    screenWidth = windowRect(3);
    screenHeight = windowRect(4);

    centerX = screenWidth / 2;
    centerY = screenHeight / 2;

    rectSize = 50;
    sizeStep = 10;
    rectColor = [255, 255, 255];

    KbQueueCreate;
    KbQueueStart;

    while true
        
        baseRect = [0, 0, rectSize, rectSize]; % 배열에 저장된 값은 각각 left, top, right, bottom이다. 
        rectCoords = CenterRectOnPointd(baseRect, centerX, centerY);
    
        Screen('FillRect', window, gray);
        Screen('FillRect', window, rectColor, rectCoords);
        DrawFormattedText(window, 'Click mouse to Grow(ESC to exit)', 'center', screenHeight - 50, white);
        Screen('Flip', window);
        
        buttons = 0;
        while ~any(buttons)
            [~, ~, buttons] = GetMouse(window);
            [keyIsDown, ~, keyCode] = KbCheck;
            if keyIsDown
                if keyCode(KbName('ESCAPE'))
                    sca;
                    error('사용자에 의해 프로그램이 중단되었습니다.');
                end
            end
            WaitSecs(0.01);
        end

        while any(buttons)
            [~, ~, buttons] = GetMouse(window);
            WaitSecs(0.01);
        end
        
        randomSize = randi([0, 1000], 1,1); 
        rectSize = rectSize + randomSize;
        % rectSize = rectSize + sizeStep;
        rectColor = randi([0, 255], 1,3);
        
        if rectSize > screenHeight 
            rectSize = 50;
        end
    end

    KbQueueRelease;
    sca;
    ShowCursor;
    disp('Experiment finished.');

catch info
    KbQueueRelease;
    sca;
    ShowCursor;
    rethrow(info);
end
