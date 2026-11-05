%% =========================================================================
% [PTB Boilerplate - Windows 전용 기본 템플릿]
% 매주 새로운 과제나 실험 코드를 작성할 때 복사해서 바로 시작할 수 있는 기본 뼈대입니다.
% =========================================================================

%% [Part 1] 기본 환경 초기화 및 PTB 설정
clear;
clc;
close all;
sca;

% 모니터 주사율 동기화 검사 건너뛰기 (실습/디버깅 시 필수)
Screen('Preference', 'SkipSyncTests', 1);
PsychDefaultSetup(1);

try
    % ---------------------------------------------------------------------
    % 1-1. 모니터 번호 및 기본 색상값 정의
    % ---------------------------------------------------------------------
    screens = Screen('Screens');
    screenNumber = max(screens);
    white = WhiteIndex(screenNumber);
    black = BlackIndex(screenNumber);
    gray = white / 2;

    % ---------------------------------------------------------------------
    % 1-2. 실험 화면 창 열기 및 기본 그래픽/텍스트 옵션 설정
    % ---------------------------------------------------------------------
    % 디버깅 시 작은 창으로 띄우려면 useWindowedMode = true 로 변경하세요.
    useWindowedMode = false;

    if useWindowedMode
        [window, windowRect] = Screen('OpenWindow', screenNumber, gray, [0, 0, 1280, 800]);
    else
        [window, windowRect] = Screen('OpenWindow', screenNumber, gray);
    end

    Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA'); % 알파블렌딩
    Screen('TextSize', window, 24); % 기본 폰트 크기 설정

    % ---------------------------------------------------------------------
    % 1-3. 화면 가로/세로 해상도 및 정중앙 좌표 추출
    % ---------------------------------------------------------------------
    screenWidth = windowRect(3);
    screenHeight = windowRect(4);
    [centerX, centerY] = RectCenter(windowRect);

    %% [Part 2] 자극(Stimulus) 및 실험 상태 변수 정의
    % TODO: 과제에 필요한 도형 크기, 색상, 좌표, 타이머 변수 등을 여기에 선언하세요.
    
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
