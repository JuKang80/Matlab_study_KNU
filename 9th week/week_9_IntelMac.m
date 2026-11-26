%% 기본설정
clear;
clc;
close all;
sca;

Screen('Preference', 'SkipSyncTests', 2);
Screen('Preference', 'TextRenderer', 0);
Screen('Preference', 'TextAntiAliasing', 1);
Screen('Preference', 'VisualDebugLevel', 1);
Screen('Preference', 'SuppressAllWarnings', 1);
Screen('Preference', 'ConserveVRAM', 64);
PsychDefaultSetup(1); % 0~255 색상 체계 유지 ([0, 255, 100] 초록 / [255, 80, 80] 빨강 정상 출력)

try
    screens = Screen('Screens');
    screenNumber = max(screens);
    white = WhiteIndex(screenNumber);
    black = BlackIndex(screenNumber);
    gray = white / 2;

    useWindowedMode = true;

    if useWindowedMode
        [window, windowRect] = Screen('OpenWindow', screenNumber, gray, [0, 0, 1280, 800]);
    else
        [window, windowRect] = Screen('OpenWindow', screenNumber, gray);
    end

    Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA'); % 알파블렌딩
    Screen('TextSize', window, 24); % 기본 폰트 크기 설정

    screenWidth = windowRect(3);
    screenHeight = windowRect(4);
    [centerX, centerY] = RectCenter(windowRect);

    % 시행 수 정의
    totalTrials = 20;
    restTrials = floor(totalTrials / 2);
    targetCorrect = 10; 
    correctCount = 0;

    % 키보드 정의
    upKey = KbName('UpArrow'); % 위로 누르면 커지고 아래로 누르면 작아지게 할 것이다. 
    downKey = KbName('DownArrow');
    spaceKey = KbName('space');
    escKey = KbName('ESCAPE');

    % 조절하는 용도
    sizeStep = 3; % 한번 누를 때 변화량. 
    tolerance = 20; % 얼마나 오차를 허용할 것인지. 일단 20으로 설정하였다. 

    % 고정점 미리 정의 (나중에 center로 옮기면 돼서 지금은 좌표 (0,0)으로 선언함. 
    fixCoords = [-15, 15, 0, 0; 0, 0, -15, 15];

    % 원의 색 자체는 미리 선언해두는게 좋을것 같다. 랜덤한 값 보단 그냥 고점된 하나의 값(인지 실험에 영향 안받게)으로 하자. 
    % 색을 따로 선언한 이유는 혹시 색에 따라 무언가 달라지는걸 보기 위한 목적이 생긴다면 따로 해야할거 같아서 따로 변수로 저장했다. 
    stimulus_Circle_color = white;

    result = {}; % 데이터 기록용 빈 배열. 문자열(correct, wrong)도 같이 담아야 하기에 {} 사용

    % 처음 시작 시 랜딩 화면이다. 
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

    frameTime = Screen('GetFlipInterval', window); % 1프레임 시간 가져온다.

    % --- 여기서부터 메인 루프 작성 
    for trial = 1:totalTrials
        targetSize = randi([100, 300]); % 제시할 원 지름 
        userSize = randi([80, 320]); % 사용자가 조절할 원 지름
        initUserSize = userSize; % 조절 시작 시점의 초기 원 지름 저장

        % 고정점 제시 전 배경화면 그리기 
        Screen('FillRect', window, gray);
        % 고정점을 그린다. 
        Screen('DrawLines', window, fixCoords, 3, white, [centerX, centerY]);
        % 고정점이 뜬 시간을 저장해 둔다. 
        t = Screen('Flip', window);

        % 백 버퍼에 그림을 그린다. 
        Screen('FillRect', window, gray);
        % 원 그릴 차례 
        targetRect = CenterRectOnPointd([0,0, targetSize, targetSize], centerX, centerY);
        % 그림을 그려 놓는다 
        Screen('FillOval', window, stimulus_Circle_color, targetRect);

        % 고정점 뜬지 0.5초 뒤에 원으로 교체하고 원이 뜬 시간을 t에 다시 저장한다. 
        t = Screen('Flip', window, t + 0.5 - 0.5*frameTime);

        % 원이 나온지 1.0초 뒤에 빈 회색 화면으로 교체하여 원을 사라지게 한다. 
        Screen('FillRect', window, gray);
        t = Screen('Flip', window, t + 1.0 - 0.5*frameTime);        
        
        % 이제 사용자가 움직일 원을 제시해야 한다. 
        userRect = CenterRectOnPointd([0, 0, userSize, userSize], centerX, centerY);
        Screen('FillRect', window, gray);
        Screen('FillOval', window, stimulus_Circle_color, userRect);
        % 0.2초 뒤에 사용자가 조절할 원이 나오게 했다. (RT 측정 시작 시각 기록)
        adjustStart = Screen('Flip', window, t + 0.2 - 0.5*frameTime);
        
        while true
            [keyIsDown, secs, keyCode] = KbCheck; 
            if keyCode(upKey)
                userSize = min(screenHeight - 50, userSize + sizeStep); % 키우기
                % KbReleaseWait; % 부드럽게 하기 위해 주석처리함
            end
            if keyCode(downKey)
                userSize = max(20, userSize - sizeStep); % 줄이기
                % KbReleaseWait; % 부드럽게 하기 위해 주석처리함
            end
            if keyCode(spaceKey)
                rt = secs - adjustStart; % 조절 원 등장 후 Space 제출까지 걸린 시간(초)
                KbReleaseWait;
                break;
            end
            if keyCode(escKey)
                error('사용자에 의해 중단되었습니다.');
            end
            % 바뀐 크기로 다시 그리기. 
            userRect = CenterRectOnPointd([0, 0, userSize, userSize], centerX, centerY);
            Screen('FillRect', window, gray);
            Screen('FillOval', window, stimulus_Circle_color, userRect);
            
            DrawFormattedText(window, sprintf('Trial %d/%d (Correct: %d/%d)', trial, totalTrials, correctCount, targetCorrect), 40, 40, white);

            % Flip하여 보여준다. 
            Screen('Flip', window);
        end

        % 오차 및 반지름 계산 (MATLAB 내장 error() 함수 충돌 방지를 위해 변수명은 sizeError 사용)
        userRadius = userSize / 2;
        targetRadius = targetSize / 2;
        sizeError = userSize - targetSize; % 부호 포함 오차 (+: 과대평가, -: 과소평가)
        abserror = abs(sizeError);         % 절대 오차
        isCorrect = abserror <= tolerance;

        if isCorrect
            correctCount = correctCount + 1;
            resultColor = [0, 255, 100];
            resultText = 'correct';
        else
            resultColor = [255, 80, 80];
            resultText = 'wrong';
        end

        RestrictKeysForKbCheck([spaceKey, escKey]);
        Screen('FillRect', window, gray);
        DrawFormattedText(window, resultText, 'center', 'center', resultColor);
        Screen('Flip', window);

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

        % 시행 결과 1줄 기록 (10개 열)
        result(trial, :) = {trial, initUserSize, userSize, targetSize, userRadius, targetRadius, sizeError, abserror, rt, resultText};

        % 휴식보다 먼저 체크. 정답 10개 달성 시 즉시 종료
        if correctCount >= targetCorrect
            break;
        end

        % 절반 지점 휴식
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

    % 종료 화면 (칭찬 또는 완료 안내, WaitSecs 대신 예약 Flip으로 2초 유지)
    Screen('FillRect', window, gray);
    if correctCount >= targetCorrect
        endText = sprintf('Great Job! You got %d correct in %d trials!', correctCount, trial);
    else
        endText = sprintf('Experiment Finished! (%d/%d correct)', correctCount, targetCorrect);
    end
    DrawFormattedText(window, endText, 'center', 'center', white);
    tEnd = Screen('Flip', window);
    Screen('FillRect', window, gray);
    Screen('Flip', window, tEnd + 2.0 - 0.5 * frameTime);

    % CSV 결과 저장
    colNames = {'Trial', 'InitUserSize', 'UserSize', 'TargetSize', 'UserRadius', 'TargetRadius', 'Error', 'AbsError', 'RT', 'Result'};
    resultTable = cell2table(result, 'VariableNames', colNames);
    timeStr = string(datetime('now', 'Format', 'yyyyMMdd_HHmmss'));
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