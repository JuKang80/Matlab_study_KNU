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

    %% TODO: 과제에 필요한 도형 크기, 색상, 좌표, 타이머 변수 등을 여기에 선언하세요.
    % 랜덤한 원이 필요한데... 시행 단위로 해야해서 week 8에서 사용한 for문을 가져와야 할 것 같다.
    % 그전에, 원이 필요하니 일단 원을 만드는 코드를 넣자. 랜덤하게 사이즈가 나와야 할것 같다. 
    

    
    history = []; % 데이터 기록용 빈 배열

    % 비동기 키보드 입력 감지 큐 시작
    KbQueueCreate;
    KbQueueStart;

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
    KbQueueRelease;
    sca;
    ShowCursor;
    disp('Experiment successfully finished');

catch info
    % 에러 발생 시 화면 먹통 방지 및 안전한 리소스 복구
    fclose('all');
    KbQueueRelease;
    sca;
    ShowCursor;
    rethrow(info);
end
