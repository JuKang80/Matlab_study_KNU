% 1. 임의의 삼각형을 하나 만들고 키보드를 이용하여 움직이게 만드세요.
% 
% 2. 삼각형이 특정 영역 내에 들어간 후, 스페이스 키를 누르면 correct, 아니면 wrong이 뜨도록 만드세요. 다시 스페이스 키를 누르면 다음 시행으로 넘어가도록 하세요(다른 키 누르면 반응 없어야 함).
% 
% 3. 메모장 또는 엑셀에 각 시행의 최종 삼각형 위치, 특정 영역의 위치, correct or wrong을 저장하세요. 
% 
% ‘특정 영역’은 삼각형, 사각형 등 자유롭게 만들기. 투명하게 해도 됨
% - 반복 횟수는 10회 
% - 시행의 절반이 지나면 휴식 시간 부여 (10회인 경우, 5회 후에 휴식 시간)
% - 다만, 필요에 따라 반복 횟수를 편하게 바꿀 수 있어야 하고, 휴식 타이밍도 이에 맞게 변경되어야 함!

%% [Part 1] 기본 환경 초기화 및 PTB 설정 (Windows / 일반 보일러플레이트 상세 해설판)
% [초기화 4종 세트] 이전 실행의 잔여 상태가 다음 실험을 오염시키지 않도록 깨끗이 비웁니다.
clear;      % 작업 공간(Workspace)에 남아 있는 모든 변수를 삭제합니다.
clc;        % 명령 창(Command Window)의 이전 출력 텍스트를 지웁니다.
close all;  % 열려 있는 모든 MATLAB Figure 창을 닫습니다.
sca;        % Screen('CloseAll')의 약자: 이전에 열려 있던 Psychtoolbox(PTB) 창을 모두 닫습니다.

% [모니터 주사율 동기화 검사 건너뛰기]
% PTB는 원래 화면 주사율(예: 60Hz, 144Hz)과 Flip 타이밍이 정확한지 엄격히 검사(Sync Test)합니다.
% 하지만 노트북, 듀얼 모니터, 창 모드, OS 그래픽 드라이버 환경에서는 사소한 오차로도
% 빨간 경고 화면과 함께 실행이 중단되므로, 실습/디버깅 시 1을 주어 검사를 건너뜁니다.
% (참고: 인텔 맥 호환 버전에서는 경고마저 완전히 끄기 위해 레벨 2를 사용하기도 합니다.)
Screen('Preference', 'SkipSyncTests', 1);

% [PTB 기본 환경 일괄 설정]
% PsychDefaultSetup(featureLevel):
% - 0: AssertOpenGL 실행 (OpenGL 지원 여부 확인)
% - 1: 0의 기능 + KbName('UnifyKeyNames') 자동 실행
%      -> Windows, macOS, Linux에서 서로 다른 키보드 이름('Return' vs 'Enter', 'ESCAPE' 등)을
%         표준 macOS/USB HID 명칭으로 통일해 줍니다. (이후 KbName('ESCAPE') 등이 OS 무관하게 동작)
% - 2: 1의 기능 + 색상 범위를 0~255 정수가 아니라 0.0~1.0 실수로 정규화 (여기서는 1을 쓰므로 0~255 사용)
PsychDefaultSetup(1);

% [try ... catch 안전장치]
% 실험 도중(전체 화면 상태 등) 에러가 발생하면 화면이 먹통이 되어 MATLAB으로 돌아오지 못할 수 있습니다.
% try 블록 안에서 에러가 나면 즉시 catch 블록으로 점프해 창을 닫고 커서/키보드 자원을 복구합니다.
try
    % ---------------------------------------------------------------------
    % 1-1. 모니터 번호 및 기본 색상값 정의
    % ---------------------------------------------------------------------
    % 연결된 모든 모니터의 번호 목록을 가져옵니다.
    % 단일 모니터면 [0], 듀얼 모니터면 [0, 1, 2]처럼 반환됩니다.
    screens = Screen('Screens');

    % 가장 큰 번호(보통 보조/외부 모니터, 단일 모니터면 0)를 실험용 화면으로 선택합니다.
    screenNumber = max(screens);

    % 해당 모니터의 색상 깊이(bit depth)에 맞는 흰색/검정색 숫자값을 조회합니다.
    % 일반 8비트(0~255) 환경에서는 white = 255, black = 0 이고, gray = 127.5가 됩니다.
    white = WhiteIndex(screenNumber);
    black = BlackIndex(screenNumber);
    gray = white / 2;

    % ---------------------------------------------------------------------
    % 1-2. 실험 화면 창 열기 및 기본 그래픽/텍스트 옵션 설정
    % ---------------------------------------------------------------------
    % 디버깅 시 작은 창으로 띄우려면 useWindowedMode = true 로 변경하세요.
    % (전체 화면에서 코드 에러가 났을 때 복구가 번거롭다면 개발 중엔 true가 안전합니다.)
    useWindowedMode = false;

    if useWindowedMode
        % 4번째 인자 rect = [Left, Top, Right, Bottom] 픽셀 좌표로 창 위치/크기를 지정합니다.
        % [0, 0, 1280, 800] -> 화면 왼쪽 위 (0,0)부터 가로 1280, 세로 800 크기의 창을 엽니다.
        % 반환값 window: 앞으로 모든 Screen('FillRect', ...), Screen('Flip', ...)에 넘길 창 핸들(번호)
        % 반환값 windowRect: 실제 열린 창의 크기 [0, 0, 가로, 세로]
        [window, windowRect] = Screen('OpenWindow', screenNumber, gray, [0, 0, 1280, 800]);
    else
        % 4번째 인자를 생략하면 선택한 모니터 전체 화면(Fullscreen)으로 gray 배경 창을 엽니다.
        [window, windowRect] = Screen('OpenWindow', screenNumber, gray);
    end

    % [알파 블렌딩(투명도) 활성화]
    % 색상 벡터를 [R, G, B, Alpha] 4개 값으로 줄 때 4번째 Alpha(0=완전투명 ~ 255=불투명)가
    % 배경과 자연스럽게 섞이도록 OpenGL 블렌딩 공식을 설정합니다.
    % 'GL_SRC_ALPHA': 새로 그릴 도형의 투명도 비율만큼 새 색을 반영
    % 'GL_ONE_MINUS_SRC_ALPHA': (1 - 투명도) 비율만큼 기존 배경 색을 남김
    % -> 이 설정이 있어야 반투명 사각형/원/부드러운 텍스트 안티앨리어싱이 정상 작동합니다.
    Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');

    % 앞으로 DrawFormattedText 등으로 그릴 기본 글자 크기(포인트/픽셀)를 24로 설정합니다.
    Screen('TextSize', window, 24);

    % ---------------------------------------------------------------------
    % 1-3. 화면 가로/세로 해상도 및 정중앙 좌표 추출
    % ---------------------------------------------------------------------
    % windowRect는 [Left, Top, Right, Bottom] 형태이므로
    % windowRect(3)은 오른쪽 끝 X(=전체 가로 폭), windowRect(4)는 아래쪽 끝 Y(=전체 세로 높이)입니다.
    screenWidth = windowRect(3);
    screenHeight = windowRect(4);

    % PTB 내장 함수 RectCenter: 사각형 [L, T, R, B]의 정중앙 (X, Y) 좌표를 한 번에 계산합니다.
    % 수동으로 [screenWidth/2, screenHeight/2]를 계산하는 것과 동일합니다.
    [centerX, centerY] = RectCenter(windowRect);

    %% [Part 2] 자극(Stimulus) 및 실험 상태 변수 정의
    % TODO: 과제에 필요한 도형 크기, 색상, 좌표, 타이머 변수 등을 여기에 선언하세요.
    
    history = []; % 데이터 기록용 빈 배열 (문자열과 숫자를 함께 저장하려면 cell(N, M) 권장)

    % [비동기 키보드 입력 감지 큐(Queue) 생성 및 시작]
    % KbCheck는 호출한 "그 순간" 눌려 있는 키만 확인하므로, 루프가 잠시 쉬는 사이(WaitSecs 등)에
    % 아주 짧게 눌렀다 뗀 키를 놓칠 수 있습니다.
    % 반면 KbQueueCreate + KbQueueStart를 켜두면 백그라운드에서 키 입력 이벤트를 큐에 계속 쌓아두므로,
    % 나중에 KbQueueCheck를 호출했을 때 그사이에 눌렸던 키와 정확한 누른 시각을 놓치지 않고 읽을 수 있습니다.
    % (주의: KbCheck / KbReleaseWait 방식과 섞어 쓰기보다 한 가지 방식으로 통일하는 것이 좋습니다.)
    KbQueueCreate;
    KbQueueStart;

    %% [Part 3] 메인 루프 (화면 전환 및 자극 제시)
    while true
        % 1. 상태 업데이트 및 좌표 계산
        % TODO: 이동, 회전, 난수 생성 등 로직 작성

        % 2. 화면 버퍼 초기화 (배경 칠하기)
        % PTB는 "더블 버퍼링"을 사용합니다.
        % Screen('FillRect', ...) 등은 보이지 않는 '뒷면(Back buffer)' 도화지에 그림을 그리는 명령입니다.
        % 매 프레임 배경색(gray)으로 먼저 덮어야 이전 프레임의 잔상이 남지 않습니다.
        Screen('FillRect', window, gray);

        % 3. 도형 / 선 / 텍스트 그리기
        % TODO: Screen('FillOval'), Screen('DrawLine'), DrawFormattedText 등 작성
        % DrawFormattedText(창, '문자열', X위치, Y위치, 색상):
        % X위치에 'center'를 주면 가로 중앙 정렬되고, Y위치에 centerY를 주면 세로 중앙 부근에 그려집니다.
        DrawFormattedText(window, 'Press ESC to Exit', 'center', centerY, white);

        % 4. 그린 요소를 실제 화면으로 전환(Flip)
        % 지금까지 뒷면 버퍼에 그려둔 모든 요소를 모니터 수직 동기화(VBL) 시점에 맞춰
        % 한 번에 '앞면(화면에 보이는 버퍼)'으로 뒤집어 출력합니다.
        Screen('Flip', window);

        % 5. ESC 키 강제 종료 확인
        % KbQueueCheck:
        % - pressed: 직전 확인 이후 한 개 이상의 키가 눌렸으면 1(true), 아니면 0(false)
        % - firstPress: 각 키 번호(인덱스)별로 처음 눌린 시각(초)이 담긴 배열 (안 눌린 키는 0)
        % 따라서 firstPress(KbName('ESCAPE'))가 0보다 크면 ESC가 눌렸다는 뜻입니다.
        [pressed, firstPress] = KbQueueCheck;
        if pressed && firstPress(KbName('ESCAPE'))
            break;
        end

        % 6. 프레임/타이머 대기 (필요 시 조절)
        % CPU 점유율을 낮추기 위해 0.05초(50ms) 대기합니다.
        % (참고: 정밀한 실시간 키보드 반응이 필요할 때는 WaitSecs 없이 매 프레임 Flip으로 속도를 맞춥니다.)
        WaitSecs(0.05);
    end

    %% [Part 4] 결과 저장 (필요 시 주석 해제하여 사용)
    % --- (옵션 A) 표(Table) 형태로 CSV 저장 ---
    % 숫자 행렬(history)에 열 이름(VariableNames)을 붙여 MATLAB Table로 변환한 뒤 CSV 파일로 씁니다.
    % resultTable = array2table(history, 'VariableNames', {'Col1', 'Col2'});
    % writetable(resultTable, 'result.csv');

    % --- (옵션 B) 현재 화면 스크린샷 이미지 저장 ---
    % Screen('GetImage', window)는 현재 화면에 표시된 픽셀 데이터를 RGB 행렬로 캡처합니다.
    % imwrite로 PNG 이미지 파일로 저장할 수 있습니다.
    % screenshot = Screen('GetImage', window);
    % imwrite(screenshot, 'stimulus_result.png');

    %% [Part 5] 정상 종료 및 자원 해제
    KbQueueRelease; % KbQueueCreate로 점유한 키보드 큐 자원을 반드시 해제합니다.
    sca;            % 열린 PTB 실험 창을 모두 닫습니다.
    ShowCursor;     % 실험 중 숨겼을 수 있는 마우스 커서를 다시 보이게 복구합니다.
    disp('Experiment successfully finished');

catch info
    % [에러 발생 시 안전 복구 블록]
    % info에는 에러 메시지, 발생 파일/줄 번호 등이 담긴 MException 객체가 들어옵니다.
    fclose('all');  % 파일 쓰기(fopen) 중 에러가 났을 때 열려 있던 파일 핸들을 모두 닫습니다.
    KbQueueRelease; % 비동기 키보드 큐 자원을 해제합니다.
    sca;            % 전체 화면 창을 강제로 닫아 MATLAB이 먹통이 되지 않게 합니다.
    ShowCursor;     % 마우스 커서를 복구합니다.
    rethrow(info);  % 잡았던 에러 내용을 명령 창에 빨간 글씨로 다시 출력해 디버깅할 수 있게 합니다.
end
