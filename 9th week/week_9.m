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

    screenWidth  = windowRect(3); % 창의 가로 길이(픽셀)
    screenHeight = windowRect(4); % 창의 세로 길이(픽셀)

    [centerX, centerY] = RectCenter(windowRect);

    totalTrials   = 20;                    % 최대 시행 횟수 
    restTrials    = floor(totalTrials / 2);% 절반 지점(10회) 종료 후 휴식 시간 부여 (floor: 소수점 버림)
    targetCorrect = 10;                    % 목표 정답 수 (10개 맞추면 즉시 성공 종료)
    correctCount  = 0;                     % 현재까지 누적된 정답 수 카운터

    upKey    = KbName('UpArrow');   % 위쪽 화살표: 원 크기 키우기
    downKey  = KbName('DownArrow'); % 아래쪽 화살표: 원 크기 줄이기
    spaceKey = KbName('space');     % 스페이스바: 크기 제출 및 다음 화면 진행
    escKey   = KbName('ESCAPE');    % ESC 키: 실험 즉시 강제 중단

    sizeStep  = 3; 
    tolerance = 100; % 정답 인정 오차범위

    fixCoords = [-15, 15, 0, 0; 0, 0, -15, 15]; % 고정점 미리 선언

    % 원 색상을 흰색으로 고정
    stimulus_Circle_color = white;

    % 데이터 기록용 빈 셀 배열 ({} 사용 이유: 숫자 데이터와 문자열 'correct'/'wrong'을 한 행에 함께 저장하기 위함)
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
    RestrictKeysForKbCheck([]); % 키 제한 해제 

    % =====================================================================
    % ★ [핵심 개념] ifi (Inter-Frame Interval) & 예약 Flip 타이밍 원리
    % =====================================================================
    % [Screen('GetFlipInterval', windowPtr)]
    % - 인자 1 ('GetFlipInterval') : 모니터 1프레임 갱신 간격을 조회하는 하위 명령어
    % - 인자 2 (window)            : 대상 창 핸들
    % - 반환 (ifi)                 : 모니터가 화면 1장을 새로 그리는 데 걸리는 시간(초)
    %   · 60Hz 모니터: ifi = 1/60 ≈ 0.0167초 (16.7ms)
    %   · 120Hz 모니터: ifi = 1/120 ≈ 0.0083초 (8.3ms)
    %
    % [왜 WaitSecs 대신 Screen('Flip', window, t + duration - 0.5 * ifi)를 쓰는가?]
    % 1. 모니터는 연속적으로 바뀌는 게 아니라, 매 ifi(예: 16.7ms)마다 수직동기화(VBL) 시점에만 화면을 교체함.
    % 2. t = Screen('Flip', window)가 반환하는 t는 화면이 '실제로' 모니터에 뜬 VBL 시각(초).
    % 3. 다음 화면을 정확히 duration초(예: 1.0초) 뒤에 띄우고 싶을 때,
    %    딱 t + 1.0을 요청하면 미세한 OS 지연(0.1ms)만 생겨도 해당 VBL을 놓쳐 다음 프레임(+16.7ms)으로 밀림.
    % 4. 따라서 반 프레임 일찍(t + duration - 0.5 * ifi) 깨어나도록 예약하면,
    %    PTB가 바로 다음 VBL(정확히 t + duration 시점)에 칼같이 화면을 교체해 줌!
    %    (PTB3 공식 데모 DriftDemo4.m, FastMaskedNoiseDemo.m 표준 공식)
    ifi = Screen('GetFlipInterval', window);

    for trial = 1:totalTrials

        targetSize   = randi([100, 300]); % 기억해야 할 제시 원의 지름 
        userSize     = randi([80, 320]);  % 참가자가 조절을 시작할 초기 원 지름 
        initUserSize = userSize;          % 조절 전 초기 크기 백업 (CSV 기록)

        Screen('FillRect', window, gray);
        Screen('DrawLines', window, fixCoords, 3, white, [centerX, centerY]); % 고정점을 중앙에 그린다. 

        % 화면이 뜬 시각을 변수 t에 저장 (이후 모든 타이밍의 기준 시계 0.0초)
        t = Screen('Flip', window);

        Screen('FillRect', window, gray); % 윈도우에 다시 그레이만 나오게(고정점이 사라짐)

        targetRect = CenterRectOnPointd([0, 0, targetSize, targetSize], centerX, centerY);

        Screen('FillOval', window, stimulus_Circle_color, targetRect);

        % 고정점이 뜬 시각 t로부터 정확히 0.5초 뒤(반 프레임 미리 예약) 제시 원 출력 -> 원 뜬 시각으로 t 갱신
        t = Screen('Flip', window, t + 0.5 - 0.5 * ifi);

        Screen('FillRect', window, gray); % 빈 회색 도화지 준비
        t = Screen('Flip', window, t + 1.0 - 0.5 * ifi);
        % 원이 뜬 시각 t로부터 1.0초 뒤 원 제거 -> 사라진 시각으로 t 갱신


        userRect = CenterRectOnPointd([0, 0, userSize, userSize], centerX, centerY);
        Screen('FillRect', window, gray);
        Screen('FillOval', window, stimulus_Circle_color, userRect);
        
        adjustStart = Screen('Flip', window, t + 0.2 - 0.5 * ifi);
        % 원이 사라진 시각 t로부터 정확히 0.2초 뒤 조절 원 등장 
        % % 조절 시작 시각(adjustStart) 기록 (RT 계산 기준)

        % 키보드 입력 부분
        while true
            % secs: 키 입력이 감지된 정확한 시스템 시각(초, GetSecs 기준)
            [keyIsDown, secs, keyCode] = KbCheck;

            if keyCode(upKey)
                userSize = min(screenHeight - 50, userSize + sizeStep);
            end
            if keyCode(downKey)
                userSize = max(20, userSize - sizeStep);
            end
            if keyCode(spaceKey)
                % 아까 위에서 secs 정보를 받기로 했는데 여기서 입력 감지된 시간과 조정 시작 시각을 빼서 rt를 구했다
                rt = secs - adjustStart; % 반응시간(RT) = 제출 시각 - 조절 원 등장 시각 (초 단위)
                KbReleaseWait;           % 스페이스에서 손 뗄 때까지 대기
                % 스페이스 여러번 눌리는 것 방지용
                break;
            end
            if keyCode(escKey)
                error('사용자에 의해 중단되었습니다.');
            end

            % 변경된 userSize로 원과 진행 상황 텍스트를 다시 그린다. 
            userRect = CenterRectOnPointd([0, 0, userSize, userSize], centerX, centerY);
            Screen('FillRect', window, gray);
            Screen('FillOval', window, stimulus_Circle_color, userRect);

            DrawFormattedText(window, sprintf('Trial %d/%d (Correct: %d/%d)', trial, totalTrials, correctCount, targetCorrect), 40, 40, white);
            Screen('Flip', window);
        end

        userRadius   = userSize / 2;   % 참가자가 맞춘 원 반지름(px)
        targetRadius = targetSize / 2; % 원래 제시되었던 원 반지름(px)

        sizeError = userSize - targetSize; % 부호 포함 오차
        abserror  = abs(sizeError);        % 오차 절댓값 
        isCorrect = abserror <= tolerance; % 절대 오차가 허용 오차(20px) 이하이면 정답(true)

        if isCorrect
            correctCount = correctCount + 1;
            resultColor  = [0, 255, 100]; % 초록색 
            resultText   = 'correct';
        else
            resultColor  = [255, 80, 80]; % 빨간색ㄴ
            resultText   = 'wrong';
        end

        Screen('FillRect', window, gray);
        DrawFormattedText(window, resultText, 'center', 'center', resultColor);
        time_Feedback = Screen('Flip', window);
        Screen('FillRect', window, gray);
        Screen('Flip', window, time_Feedback + 1.0 - 0.5 * ifi);
        % 피드백이 화면에 뜬 시각(time_Feedback)을 기록한 뒤, 1.0초 후 빈 화면으로 자동 전환


       
        result(trial, :) = {trial, initUserSize, userSize, targetSize, userRadius, targetRadius, sizeError, abserror, rt, resultText};

        % 목표 정답(10개) 달성 시 휴식 화면 없이 즉시 루프 탈출. 
        % 칭찬 화면으로 간다. 
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
    % 2.0초 뒤에 종료되게 하였다. 

    colNames = {'Trial', 'InitUserSize', 'UserSize', 'TargetSize', 'UserRadius', 'TargetRadius', 'Error', 'AbsError', 'RT', 'Result'};
    resultTable = cell2table(result, 'VariableNames', colNames);
    timeStr  = string(datetime('now', 'Format', 'yyyyMMdd_HHmmss'));
    fileName = sprintf('week9_result_%s.csv', timeStr);
    writetable(resultTable, fileName);

   
    RestrictKeysForKbCheck([]); 
    sca;                        
    ShowCursor; % 마우스 커서 복구
    disp('Experiment successfully finished');

catch info
    RestrictKeysForKbCheck([]);
    fclose('all');
    sca;
    ShowCursor; 
    rethrow(info);
end
