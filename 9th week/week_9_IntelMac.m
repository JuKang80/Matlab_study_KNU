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
    correctCount = 0; % 누적 정답 숫자 세기용 
    

    % 키보드 정의
    spaceKey = KbName('space');
    escKey = KbName('ESCAPE');
    xKey     = KbName('x'); % 크기가 다른 경우를 위한 입력 키

    % 고정점 미리 정의 (나중에 center로 옮기면 돼서 지금은 좌표 (0,0)으로 선언함. 
    fixCoords = [-15, 15, 0, 0; 0, 0, -15, 15];

    % 원의 색 자체는 미리 선언해두는게 좋을것 같다. 랜덤한 값 보단 그냥 고점된 하나의 값(인지 실험에 영향 안받게)으로 하자. 
    % 색을 따로 선언한 이유는 혹시 색에 따라 무언가 달라지는걸 보기 위한 목적이 생긴다면 따로 해야할거 같아서 따로 변수로 저장했다. 
    target_Circle_color = white; % 색은 일단 화이트로 했다. 
    stimlus_Circle_color = white; 
    
    result = []; % 데이터 기록용 빈 배열
    
    % 전체 시행 수 만큼 타겟 원 반지름을 저장하는데, 크기를 60부터 100 사이로 정수값이 나오게 조절했다. 
    target_Circle_radius = randi([60, 100], 1, totalTrials); 
    
    % 전체 시행 수 만큼 자극 원 반지름을 저장하는데, 크기를 30부터 150 사이로 정수값이 나오게 조절했다.
    % 30부터 150까지 조정하여 오차범위가 생겨 오답이 나올 수 있게 의도하였다. 
    stimuㅇ/lus_Circle_radius = randi([30, 150], 1, totalTrials);

    
    

    % 랜덤한 원이 필요한데... 시행 단위로 해야해서 week 8에서 사용한 for문을 가져와야 할 것 같다.
    % 그전에, 원이 필요하니 일단 원을 만드는 코드를 넣자. 랜덤하게 사이즈가 나와야 할것 같다. 
    
    % 이후 고정점이 필요하면 Screen('DrawLines', window, fixCoords, 3, white, [centerX, centerY]); 이 한 줄로 호출하면 됨 

    % 그리고 원에 대한 처리를 하자. 
    

    

    %% [Part 3] 메인 루프 (화면 전환 및 자극 제시)
    while true
        % 1. 상태 업데이트 및 좌표 계산
        % TODO: 이동, 회전, 난수 생성 등 로직 작성

        % 2. 화면 버퍼 초기화 (배경 칠하기)
        Screen('FillRect', window, gray);

        % 3. 도형 / 선 / 텍스트 그리기
        % TODO: Screen('FillOval'), Screen('DrawLine'), DrawFormattedText 등 작성
        DrawFormattedText(window, 'Press ESC to Exit', 'center', centerY, white);

        % 4. 그린 요소를 실제 화면으로 전환(Flip)
        Screen('Flip', window);

        % 5. ESC 키 강제 종료 확인
        [pressed, firstPress] = KbQueueCheck;
        if pressed && firstPress(KbName('ESCAPE'))
            break;
        end

        % 6. 프레임/타이머 대기 (필요 시 조절)
        WaitSecs(0.05);
    end

    %% [Part 4] 결과 저장 (필요 시 주석 해제하여 사용)
    % --- (옵션 A) 표(Table) 형태로 CSV 저장 ---
    % resultTable = array2table(history, 'VariableNames', {'Col1', 'Col2'});
    % writetable(resultTable, 'result.csv');

    % --- (옵션 B) 현재 화면 스크린샷 이미지 저장 ---
    % screenshot = Screen('GetImage', window);
    % imwrite(screenshot, 'stimulus_result.png');

    %% [Part 5] 정상 종료 및 자원 해제
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
