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
    trial = 0; % 시행횟수를 세기 위함이다.

    % 키보드 정의
    leftKey = KbName('LeftArrow');
    rightKey = KbName('RightArrow');
    upKey = KbName('UpArrow');
    downKey = KbName('DownArrow');
    spaceKey = KbName('space');
    escKey = KbName('ESCAPE');

    % 조절하는 용도
    sizeStep = 10; % 한번 누를 때 변화량. 
    tolerance = 20; % 얼마나 오차를 허용할 것인지. 일단 20으로 설정하였다. 

    % 중간에 휴식을 취했는지 확인하는 변수도 필요하다. 
    Break = false; 

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