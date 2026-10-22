%% 1. 5초마다 색, 크기, 위치가 랜덤하게 변하는 10개의 도형을 그리세요.
% 전환 횟수는 최소 5회이며 타이머가 보이도록 설정해보세요. 도형의 모양은 자유입니다. 

% 기본설정 1: 기존 작업 환경 및 화면 상태를 깨끗하게 초기화합니다.
clear;          % 메모리에 저장된 모든 변수를 삭제합니다.
clc;            % 명령창(Command Window)의 텍스트를 모두 지웁니다.
close all;      % 열려 있는 모든 MATLAB 일반 그림(Figure) 창을 닫습니다.
sca;            % Screen('CloseAll')과 동일하며, 열려 있는 모든 PTB 스크린 창을 닫습니다.

% 기본설정 2: Psychtoolbox 실행을 위한 하드웨어 최적화 및 기본 설정을 적용합니다.
Screen('Preference', 'SkipSyncTests', 1); % 주사율 동기화 테스트를 건너 뛰어 프로그램이 즉시 켜지도록 설정합니다. (디버깅용)
PsychDefaultSetup(1);                      % Psychtoolbox의 기본 키보드 매핑 및 설정을 초기화합니다.

try
    % 모니터 및 화면 정보를 가져옵니다.
    screens = Screen('Screens');          % 현재 컴퓨터에 연결된 모든 모니터의 인덱스 배열을 가져옵니다.
    screenNumber = max(screens);          % 듀얼 모니터일 경우 보조 모니터(가장 큰 숫자)를, 싱글이면 주 모니터(0)를 선택합니다.
    white = WhiteIndex(screenNumber);     % 해당 모니터에서 사용할 수 있는 가장 밝은 '흰색'의 코드값(보통 255)을 가져옵니다.
    black = BlackIndex(screenNumber);     % 해당 모니터에서 사용할 수 있는 가장 어두운 '검은색'의 코드값(보통 0)을 가져옵니다.
    gray = white / 2;                     % 흰색 코드의 절반 값을 계산하여 배경색으로 쓸 '회색' 값을 만듭니다.

    % 실험창(기본 화면)을 열고 블렌딩 함수를 설정합니다.
    [window, windowRect] = Screen('OpenWindow', screenNumber, gray); % 지정한 모니터에 회색 배경의 전체 화면 창을 열고, 창 ID(window)와 해상도 크기(windowRect)를 받습니다.
    Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA'); % 투명도(Alpha 채널) 처리가 가능하도록 그래픽 블렌딩 모드를 켭니다.
    Screen('Flip', window);               % 빈 회색 화면을 모니터에 실제로 출력(적용)합니다.

    % 화면을 4x4 격자(총 16개 방)로 나누기 위한 가상의 중심 좌표들을 생성합니다.
    gridX = linspace(windowRect(3) * 0.1, windowRect(3) * 0.9, 4); % 화면 가로 폭의 10%부터 90% 영역까지 4개의 X 좌표점을 일정한 간격으로 나눕니다.
    gridY = linspace(windowRect(4) * 0.2, windowRect(4) * 0.8, 4); % 화면 세로 폭의 20%부터 80% 영역까지 4개의 Y 좌표점을 일정한 간격으로 나눕니다.
    [X, Y] = meshgrid(gridX, gridY);      % 4개의 X좌표와 4개의 Y좌표를 조합하여 4x4 행렬 형태의 격자 평면 좌표를 생성합니다.
    allRooms = [X(:), Y(:)];              % 4x4 행렬 좌표를 풀어서 16행 2열(1열: X좌표, 2열: Y좌표) 형태의 좌표 목록으로 만듭니다.

    % 백그라운드 키보드 입력 감지 기능을 켭니다. (WaitSecs 도중의 입력도 기억함)
    KbQueueCreate;                        % 비동기 키 입력 감지를 위한 메모리 공간(큐)을 백그라운드에 생성합니다.
    KbQueueStart;                         % 키보드 입력 모니터링을 실제로 시작합니다.

    % 총 20회의 시행(Trial)을 수행하는 반복문입니다. (최소 5회 조건 만족)
    for trial = 1:20 

        % 16개의 격자 위치 중 10개를 중복 없이 랜덤하게 고릅니다.
        centers = allRooms(randperm(16, 10), :); % 1부터 16까지 무작위 순열을 만든 후 앞의 10개를 뽑아, 그 행에 해당하는 [X, Y] 중심 좌표를 가져옵니다.

        % 10개 도형 각각의 크기를 랜덤하게 지정합니다.
        sz = double(randi([50, 100], 10, 1)); % 50 픽셀에서 100 픽셀 사이의 정수 중 10행 1열 구조의 크기(정사각형의 한 변 길이) 데이터를 정밀한 실수 형태로 생성합니다.

        % 각 도형의 중심 좌표와 크기를 이용하여 그리기 영역(Left, Top, Right, Bottom)을 계산합니다.
        shapes = [centers(:,1)-sz/2, centers(:,2)-sz/2, centers(:,1)+sz/2, centers(:,2)+sz/2]'; 
        % 1열(X)-크기/2 = 왼쪽X  | 2열(Y)-크기/2 = 위쪽Y | 1열(X)+크기/2 = 오른쪽X | 2열(Y)+크기/2 = 아래쪽Y
        % 계산 결과는 10행 4열 구조가 되며, 마지막에 트랜스포즈(')를 취해 PTB가 요구하는 4행 10열 구조로 뒤집어 shapes에 대입합니다.

        % 10개 도형에 칠할 무작위 RGB 색상을 생성합니다.
        colors = randi([0, 255], 3, 10);   % 0~255 범위 안에서 [R; G; B] 구조를 가진 3행 10열의 색상 매트릭스를 무작위로 만듭니다.

        % 주석 해제하여 사용할 수 있는 지터(Jitter) 및 수동 위치 연산 코드 예시 영역입니다.
        % chosenRoom = randperm(16, 10); 
        % cx_grid = allRooms(chosenRoom, 1)'; 
        % cy_grid = allRooms(chosenRoom, 2)';
        % jitterX = double(randi([-25, 25], 1, 10));
        % jitterY = double(randi([-25, 25], 1, 10));
        % cx = cx_grid + jitterX;
        % cy = cy_grid + jitterY;
        % sz = double(randi([50, 100], 1, 10)); 
        % shapes = [cx-sz/2; cy-sz/2; cx + sz/2; cy + sz/2]; 

        % 5초부터 1초까지 타이머를 감소시키며 화면을 유지하는 반복문입니다.
        for timer = 5:-1:1
            % 메모리 버퍼 화면에 무작위 색상과 크기를 가진 타원(원) 10개를 한 번에 그립니다.
            Screen('FillOval', window, colors, shapes)

            % 상단에 띄울 안내 텍스트를 서식에 맞춰 생성합니다.
            infoText = sprintf('Trial: %d\nTime Left: %ds', trial, timer); % 현재 Trial 횟수와 남은 시간(초)을 문자열로 결합합니다.
            DrawFormattedText(window, infoText, 50, 50, white); % 지정한 window 창의 좌측 상단(X=50, Y=50) 위치에 흰색 텍스트를 배치합니다.

            % 버퍼에 그려진 도형과 글자를 모니터 실제 화면으로 뒤집어 전환(출력)합니다.
            Screen('Flip', window);

            % 1초 동안 프로그램 진행을 멈추고 대기합니다.
            WaitSecs(1);

            % 대기 시간(1초) 동안 백그라운드 큐에 누적된 키보드 입력을 확인합니다.
            [pressed, firstPress] = KbQueueCheck; % 키가 눌렸었는지 여부(pressed)와 처음 눌린 키들의 시간 기록 배열(firstPress)을 반환받습니다.
            if pressed && firstPress(KbName('ESCAPE')) % 어떤 키가 눌렸고, 그 키가 하필 ESC 키라면 참(True)이 됩니다.
                error('사용자가 ESC를 눌러 종료했습니다.') % 의도적인 오류를 강제로 발생시켜 아래 catch 블록으로 점프(탈출)하게 만듭니다.
            end
        end % 타이머 반복문 종료 (5초 경과 시 다음 위치와 색상으로 초기화하기 위해 루프 돌림)
    end % Trial 반복문 종료

    % 모든 실험 루프가 정상적으로 끝났을 때의 정리 작업입니다.
    KbQueueRelease;                       % 백그라운드 키 입력 감지 기능을 완전히 끄고 메모리를 해제합니다.
    sca;                                  % 실험창을 닫고 모니터 화면을 원래 매틀랩 환경으로 돌려놓습니다.
    ShowCursor;                           % 디스플레이에서 숨겨졌던 마우스 커서를 다시 보이게 만듭니다.
    disp('Experiment successfully finished'); % 명령창에 정상 종료 메시지를 띄웁니다.

catch info
    % try 블록 안에서 에러가 나거나 사용자가 ESC를 눌러 error가 강제 발생했을 때 실행되는 비상 처리 영역입니다.
    KbQueueRelease;                       % 에러 발생 시에도 키보드 큐가 메모리에 낭비되거나 꼬이지 않도록 정리합니다.
    sca;                                  % 화면이 서서히 굳어 먹통이 되는 현상을 방지하기 위해 강제로 PTB 실험창을 파괴합니다.
    ShowCursor;                           % 숨겨진 마우스 커서를 복구합니다.
    rethrow(info);                        % 매틀랩 명령창에 원래 발생했던 에러 문구(사용자가 ESC를 눌러 종료했습니다 등)를 그대로 출력합니다.
end