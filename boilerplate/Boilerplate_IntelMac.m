%% =========================================================================
% [PTB Boilerplate - Intel Mac (macOS Ventura 등) 전용 기본 템플릿]
% 인텔 맥에서 Psychtoolbox 실행 시 발생하는 VBL 동기화 에러, 텍스트 렌더러 크래시,
% 전체 화면 검은 화면 먹통 현상을 방어하는 세팅이 기본 탑재된 뼈대 파일입니다.
%
% ※ 최초 1회 확인: '시스템 설정 > 개인정보 보호 및 보안 > 손쉬운 사용 / 입력 모니터링'에
%    MATLAB이 허용(체크)되어 있어야 키보드 입력이 정상 작동합니다.
% =========================================================================

%% [Part 1] 기본 환경 초기화 및 인텔 맥 호환성 특화 설정
clear;
clc;
close all;
sca;

% -------------------------------------------------------------------------
% ★ [Intel Mac / macOS Ventura 필수 호환성 세팅 4종 세트]
% -------------------------------------------------------------------------
% 1. 주사율 동기화 검사 완전 비활성화 (레벨 2: 모든 VBL 동기화 오류/경고 무시)
Screen('Preference', 'SkipSyncTests', 2);

% 2. 텍스트 렌더러 크래시 방지 (DrawFormattedText 호출 시 MATLAB 강제 종료 방지)
Screen('Preference', 'TextRenderer', 0);
Screen('Preference', 'TextAntiAliasing', 1);

% 3. 시작 시 깜빡이는 경고 화면 생략 및 불필요한 콘솔 경고 억제
Screen('Preference', 'VisualDebugLevel', 1);
Screen('Preference', 'SuppressAllWarnings', 1);

% 4. Intel 내장 그래픽(HD/Iris) 및 macOS WindowServer VRAM 충돌 방지 플래그
Screen('Preference', 'ConserveVRAM', 64);

% PTB 기본 환경 초기화 (키보드 명칭 통일)
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
    % 1-2. 실험 화면 창 열기 (인텔 맥 전체 화면 먹통 방지 창 모드 기본 적용)
    % ---------------------------------------------------------------------
    % 인텔 맥에서는 안전한 창 모드(true) 사용을 권장합니다.
    % 전체 화면이 필요할 때만 false로 변경하세요.
    useWindowedMode = true;

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
