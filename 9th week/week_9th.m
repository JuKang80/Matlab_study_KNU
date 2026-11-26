% 1. 1초간 랜덤 크기의 타원이 제시되고 사라진 후 임의의 타원 하나가 생성됩니다. 키보드를 이용하여 임의의 타원의 크기를 조절하여 사라진 타원의 크기를 맞추도록 하세요.

% 2. 제시되었던 타원 크기의 특정 오차 범위 내에 들어가는 경우 스페이스 키를 누르면 correct, 아니면 wrong이 뜨도록 만드세요. 스페이스 키를 누르면 다음 시행으로 넘어가도록 하세요.

% 3. correct가 10회가 되면 칭찬의 말과 함께 프로그램이 종료되도록 하세요(정답 10개가 될 때까지 trial 반복).

% 4. 메모장 또는 엑셀에 각 시행의 조절 타원 크기, 제시된 타원 크기, 정답 여부를 저장하세요. 

%[반복 횟수는 10회 이상] 

% [시행의 절반이 지나면 휴식 시간 부여]


% 기본설정
clear;
clc;
close all;
sca;


Screen('Preference', 'SkipSyncTests', 1);
PsychDefaultSetup(1);

try
    % 화면 정보 가져옴
    screens = Screen('Screens');
    screenNumber = max(screens);

    % 색에 대한 정보
    white = WhiteIndex(screenNumber);
    black = BlackIndex(screenNumber);
    gray  = white / 2;

    % 전체화면 할건지, 작게 볼건지
    useWindowedMode = false;

    if useWindowedMode
        [window, windowRect] = Screen('OpenWindow', screenNumber, gray, [0, 0, 1280, 800]);
    else
        [window, windowRect] = Screen('OpenWindow', screenNumber, gray);
    end


    % 선분 그리는 것과 관련
    Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');
    Screen('TextSize', window, 24); % 폰트 사이즈
    HideCursor; % 마우스 커서 숨기기

    
    % 가로 세로 정보 가져옴
    screenWidth  = windowRect(3);
    screenHeight = windowRect(4);
    [centerX, centerY] = RectCenter(windowRect); % 중앙에 대한 정보


    totalTrials   = 20; % 전체 시행 수 20회
    restTrials    = floor(totalTrials / 2);  % 절반 시행 횟수
    targetCorrect = 10; % 맞춰야 하는 개수
    correctCount  = 0; % 맞춘 개수 기록하는 용도

    upKey    = KbName('UpArrow'); % 키보드 응답 
    downKey  = KbName('DownArrow');
    spaceKey = KbName('space');
    escKey   = KbName('ESCAPE');


    sizeStep  = 3; % 한번 커질때 얼마나 커질지
    tolerance = 100; % 디버깅용으로 일단 100으로 설정함. 

    fixCoords = [-15, 15, 0, 0; 0, 0, -15, 15]; % 고정점 제시할건데 일단 (0,0)에서 그려놓고 나중에 중앙으로 옮길 것이다.
    stimulus_Circle_color = white; % 원 색은 하얀색으로 통일
    result = {}; % 결과를 담을 배열 선언. {}를 쓴 이유는 중간에 correct, wrong이 들어갈 것이라 그렇다. 



    % week 8에서 사용했던 처음 시작 화면. 스페이스바로 응답 받아 시작하게 됨. 
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
    RestrictKeysForKbCheck([]); % 제한된 키 해제

    % WaitSecs 대신 사용함. 
    % 'GetFlipInterval'은 모니터가 1프레임 갱신 간격을 조회한다. 
    % 그 조회할 곳이 window이다. 
    ifi = Screen('GetFlipInterval', window);


    for trial = 1:totalTrials % 1부터 전체 시행수까지 
        targetSize   = randi([100, 300]); % 첫번째 원 크기. 지름에 대한 정보이다. 
        userSize     = randi([80, 320]); % 피험자가 크기를 조절할 원. 지름에 대한 정보
        initUserSize = userSize; % 피험자가 크기를 조절할 원 정보를 담아 두는것이다. 

        Screen('FillRect', window, gray); % 일단 회색으로 채우고
        Screen('DrawLines', window, fixCoords, 3, white, [centerX, centerY]); % 고정점을 중앙에 제시한다. 
        t = Screen('Flip', window); % Screen에서 언제(when) 제시할지 생략하면 다음 프레임에 바로 화면을 교체한다. 
        % 근데 그 교체된 시간을 변수 t에 저장한다. (time)

        % 백버퍼 초기화한다. 
        Screen('FillRect', window, gray);
        targetRect = CenterRectOnPointd([0, 0, targetSize, targetSize], centerX, centerY); % 타겟 원에 대한 정보이다.  
        Screen('FillOval', window, stimulus_Circle_color, targetRect); % 타겟 원을 그린다. 
        t = Screen('Flip', window, t + 0.5 - 0.5 * ifi); 
        % 이제 t에 시간 정보를 담는데, 어떤 정보이냐. 
        % 고정점이 뜬 시간에 +0.5초 하여 제시를 하고 그 시간을 t에 저장한다. 
        % 여기서 0.5*ifi를 하는 이유는 FastMaskedNoiseDemo.m (191~203행)에서 사용한 것을 볼 수 있다.
        % when(언제)에 대해서, 이시간대 이후 제일 처음 수직동기화 시점에 flip하게 되는데, 그래서 수직동기화 시간보다 널널하게 설정하여 혹시 오차 때문에 생겨서 밀리지 않게 하였다. 

        % 다시 회색으로 채운다. 
        Screen('FillRect', window, gray);
        % 처음 원이 뜬 시각 t의 1.0초 이후 원을 제거한다. 
        % 그리고 t의 정보를 갱신
        t = Screen('Flip', window, t + 1.0 - 0.5 * ifi);


        % 피험자가 조정해야 할 원을 그린다. 
        userRect = CenterRectOnPointd([0, 0, userSize, userSize], centerX, centerY);

        Screen('FillRect', window, gray);
        Screen('FillOval', window, stimulus_Circle_color, userRect);
        % 원이 사라진 뒤 0.2초 뒤에 조절할 원이 나온다. 
        % 그리고 변수명을 다르게 한거는 조절 시작 시각을 통해 rt를 계산하기 위함이다. 
        adjustStart = Screen('Flip', window, t + 0.2 - 0.5 * ifi);

        % true니까 무조건 이 안으로 들어간다. 
        % 키보드 입력에 대한 것이다. 
        while true
            [keyIsDown, secs, keyCode] = KbCheck; % secs를 통해 키 입력이 감지된 시간을 알 수 있다. 

            if keyCode(upKey)
                userSize = min(screenHeight - 50, userSize + sizeStep);
            end
            if keyCode(downKey)
                userSize = max(20, userSize - sizeStep);
            end
            if keyCode(spaceKey)
                rt = secs - adjustStart; % rt는 스페이스바가 눌러진 시간 - 조절원이 등장한 시간으로 계산했다. 
                KbReleaseWait; % 스페이스바에서 손 땔때까지 대기하게 했다. 
                break;
            end
            if keyCode(escKey)
                error('사용자에 의해 중단되었습니다.');
            end

            % 조정된 원의 크기를 조절하는 것이다. 
            userRect = CenterRectOnPointd([0, 0, userSize, userSize], centerX, centerY);
            Screen('FillRect', window, gray);
            Screen('FillOval', window, stimulus_Circle_color, userRect);
            DrawFormattedText(window, sprintf('Trial %d/%d (Correct: %d/%d)', trial, totalTrials, correctCount, targetCorrect), 40, 40, white);
            Screen('Flip', window);
        end

        % 반지름에 대한 정보
        userRadius   = userSize / 2;
        targetRadius = targetSize / 2;

        % 타겟과 피험자가 조정한 지름이 얼마나 다른가 
        sizeError = userSize - targetSize;
        abserror  = abs(sizeError); % 절댓값도 구했다. 
        isCorrect = abserror <= tolerance; % correct는 오차절댓값이 용인 가능한 오차보다 작거나 작을때 정답이다. 

        % 그래서 정답이면 correctCount를 올려준다. 
        if isCorrect
            correctCount = correctCount + 1;
            resultColor  = [0, 255, 100]; % 초록
            resultText   = 'correct';
        else
            resultColor  = [255, 80, 80]; % 빨강
            resultText   = 'wrong';
        end

        

        Screen('FillRect', window, gray);
        DrawFormattedText(window, resultText, 'center', 'center', resultColor);
        time_Feedback = Screen('Flip', window);
        Screen('FillRect', window, gray);
        Screen('Flip', window, time_Feedback + 1.0 - 0.5 * ifi);
        % 여기도 1.0초 뒤에 flip을 하도록 했다. 
        % 이 부분은 덩정답인지, 오답인지 (resultText) 표시하는 부분이다. 


        % 결과를 담는 파트. 
        result(trial, :) = {trial, initUserSize, userSize, targetSize, userRadius, targetRadius, sizeError, abserror, rt, resultText};

        % 만약 정답이 타겟보다 같거나 커진다면 break로 탈출한다. (칭찬 말로 간다.)
        if correctCount >= targetCorrect
            break;
        end

        % 절반 지점 휴식 시간을 준다. 
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

    % 회색으로 화면 채운다. 
    Screen('FillRect', window, gray);
    % 만약 정답이 targetCorrect 이상이면 칭찬과 격려의 말을 출력한다. 
    if correctCount >= targetCorrect
        endText = sprintf('Great Job! WELL DONE!! :) You got %d correct in %d trials!', correctCount, trial);
    else % 그렇지 않다면 실험 종료를 알린다. 
        endText = sprintf('Experiment Finished!:) (%d/%d correct)', correctCount, targetCorrect);
    end
    DrawFormattedText(window, endText, 'center', 'center', white); % endText를 그린다. 

    time_End = Screen('Flip', window); % 여기서 flip이 된 시간 기록한다. 
    Screen('FillRect', window, gray);
    Screen('Flip', window, time_End + 2.0 - 0.5 * ifi); % 그리고 그 시간을 기준으로 2.0초 뒤에 종료되게 한다. 

    % 파일 저장 부분
    colNames = {'Trial', 'InitUserSize', 'UserSize', 'TargetSize', 'UserRadius', 'TargetRadius', 'Error', 'AbsError', 'RT', 'Result'};
    resultTable = cell2table(result, 'VariableNames', colNames);
    timeStr  = string(datetime('now', 'Format', 'yyyyMMdd_HHmmss'));
    fileName = sprintf('week9_result_%s.csv', timeStr);
    writetable(resultTable, fileName);

    % 키보드 해제 및 커서 다시 보이게 했다. 
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
