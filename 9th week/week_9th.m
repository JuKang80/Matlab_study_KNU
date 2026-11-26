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
    gray  = white / 2;

    useWindowedMode = false;

    if useWindowedMode
        [window, windowRect] = Screen('OpenWindow', screenNumber, gray, [0, 0, 1280, 800]);
    else
        [window, windowRect] = Screen('OpenWindow', screenNumber, gray);
    end

    Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');
    Screen('TextSize', window, 24);
    HideCursor;

    screenWidth  = windowRect(3);
    screenHeight = windowRect(4);
    [centerX, centerY] = RectCenter(windowRect);

    totalTrials   = 20;
    restTrials    = floor(totalTrials / 2);
    targetCorrect = 10;
    correctCount  = 0;

    upKey    = KbName('UpArrow');
    downKey  = KbName('DownArrow');
    spaceKey = KbName('space');
    escKey   = KbName('ESCAPE');

    sizeStep  = 3;
    tolerance = 100;

    fixCoords = [-15, 15, 0, 0; 0, 0, -15, 15];
    stimulus_Circle_color = white;
    result = {};

    DrawFormattedText(window, 'Press SPACE to start', 'center', 'center', white);
    Screen('Flip', window);
    RestrictKeysForKbCheck([spaceKey, escKey]);

    while true
        [keyIsDown, ~, keyCode] = KbCheck;
        if keyCode(escKey)
            error('사용자에 의해 중단되었습니다.');
        end
        if keyCode(spaceKey)
            KbReleaseWait;
            break;
        end
    end
    RestrictKeysForKbCheck([]);

    ifi = Screen('GetFlipInterval', window);

    for trial = 1:totalTrials
        targetSize   = randi([100, 300]);
        userSize     = randi([80, 320]);
        initUserSize = userSize;

        Screen('FillRect', window, gray);
        Screen('DrawLines', window, fixCoords, 3, white, [centerX, centerY]);
        t = Screen('Flip', window);

        Screen('FillRect', window, gray);
        targetRect = CenterRectOnPointd([0, 0, targetSize, targetSize], centerX, centerY);
        Screen('FillOval', window, stimulus_Circle_color, targetRect);
        t = Screen('Flip', window, t + 0.5 - 0.5 * ifi);

        Screen('FillRect', window, gray);
        t = Screen('Flip', window, t + 1.0 - 0.5 * ifi);

        userRect = CenterRectOnPointd([0, 0, userSize, userSize], centerX, centerY);
        Screen('FillRect', window, gray);
        Screen('FillOval', window, stimulus_Circle_color, userRect);
        adjustStart = Screen('Flip', window, t + 0.2 - 0.5 * ifi);

        while true
            [keyIsDown, secs, keyCode] = KbCheck;

            if keyCode(upKey)
                userSize = min(screenHeight - 50, userSize + sizeStep);
            end
            if keyCode(downKey)
                userSize = max(20, userSize - sizeStep);
            end
            if keyCode(spaceKey)
                rt = secs - adjustStart;
                KbReleaseWait;
                break;
            end
            if keyCode(escKey)
                error('사용자에 의해 중단되었습니다.');
            end

            userRect = CenterRectOnPointd([0, 0, userSize, userSize], centerX, centerY);
            Screen('FillRect', window, gray);
            Screen('FillOval', window, stimulus_Circle_color, userRect);
            DrawFormattedText(window, sprintf('Trial %d/%d (Correct: %d/%d)', trial, totalTrials, correctCount, targetCorrect), 40, 40, white);
            Screen('Flip', window);
        end

        userRadius   = userSize / 2;
        targetRadius = targetSize / 2;

        sizeError = userSize - targetSize;
        abserror  = abs(sizeError);
        isCorrect = abserror <= tolerance;

        if isCorrect
            correctCount = correctCount + 1;
            resultColor  = [0, 255, 100];
            resultText   = 'correct';
        else
            resultColor  = [255, 80, 80];
            resultText   = 'wrong';
        end

        Screen('FillRect', window, gray);
        DrawFormattedText(window, resultText, 'center', 'center', resultColor);
        time_Feedback = Screen('Flip', window);
        Screen('FillRect', window, gray);
        Screen('Flip', window, time_Feedback + 1.0 - 0.5 * ifi);

        result(trial, :) = {trial, initUserSize, userSize, targetSize, userRadius, targetRadius, sizeError, abserror, rt, resultText};

        if correctCount >= targetCorrect
            break;
        end

        if trial == restTrials && trial < totalTrials
            Screen('FillRect', window, gray);
            DrawFormattedText(window, 'Break Time! Press SPACE to continue', 'center', 'center', white);
            Screen('Flip', window);
            RestrictKeysForKbCheck([spaceKey, escKey]);

            while true
                [keyIsDown, ~, keyCode] = KbCheck;
                if keyCode(escKey)
                    error('사용자에 의해 중단되었습니다.');
                end
                if keyCode(spaceKey)
                    KbReleaseWait;
                    break;
                end
            end
            RestrictKeysForKbCheck([]);
        end
    end

    Screen('FillRect', window, gray);
    if correctCount >= targetCorrect
        endText = sprintf('Great Job! WELL DONE!! :) You got %d correct in %d trials!', correctCount, trial);
    else
        endText = sprintf('Experiment Finished!:) (%d/%d correct)', correctCount, targetCorrect);
    end
    DrawFormattedText(window, endText, 'center', 'center', white);

    time_End = Screen('Flip', window);
    Screen('FillRect', window, gray);
    Screen('Flip', window, time_End + 2.0 - 0.5 * ifi);

    colNames = {'Trial', 'InitUserSize', 'UserSize', 'TargetSize', 'UserRadius', 'TargetRadius', 'Error', 'AbsError', 'RT', 'Result'};
    resultTable = cell2table(result, 'VariableNames', colNames);
    timeStr  = string(datetime('now', 'Format', 'yyyyMMdd_HHmmss'));
    fileName = sprintf('week9_result_%s.csv', timeStr);
    writetable(resultTable, fileName);

    RestrictKeysForKbCheck([]);
    sca;
    ShowCursor;
    disp('Experiment successfully finished');

catch info
    RestrictKeysForKbCheck([]);
    fclose('all');
    sca;
    ShowCursor;
    rethrow(info);
end
