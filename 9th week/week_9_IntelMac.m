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
PsychDefaultSetup(2);

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
    sizeStep = 10; % 한번 누를 때 변화량. 
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
        userSize = randi([80, 320]); % 사용자가 조절한 원 지름

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

        % 고정점 뜬지 0.5초 뒤에 원으로 교체ㅐ하고 원이 뜬 시간을 t에 다시 저장한다. 
        t = Screen('Flip', window, t + 0.5 - 0.5*frameTime);

        % 원이 나온지 1.0초 뒤에 빈 회색 화면으로 교체하여 원을 사라지게 한다. 
        Screen('FillRect', window, gray);
        t = Screen('Flip', window, t + 1.0 - 0.5*frameTime);        
        
        % 이제 사용자가 움직일 원을 제시해야 한다. 
        userRect = CenterRectOnPointd([0, 0, userSize, userSize], centerX, centerY);
        Screen('FillRect', window, gray);
        Screen('FillOval', window, stimulus_Circle_color, userRect
        % 0.2초 뒤에 사용자가 조절할 원이 나오게 했다. 
        t = Screen('Flip', window, t + 0.2 - 0.5*frameTime);

        
    end

    

    sca;
    ShowCursor;
    disp('Experiment successfully finished');

catch info
    % 에러 발생 시 화면 먹통 방지 및 안전한 리소스 복구
    fclose('all');
    sca;
    ShowCursor;
    rethrow(info);
end