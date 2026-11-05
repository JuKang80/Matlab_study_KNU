%% =========================================================================
% [Week 6th] 과제 구현 - 벡터화(Logical Indexing) + onCleanup 최적화 버전 (상세 주석판)
% 
% [적정 엔지니어링 개선점]
% 1. for i = 1:2 루프를 완전히 제거하고 MATLAB 고유의 '논리 인덱싱(Logical Indexing)' 적용
% 2. onCleanup 객체를 등록하여 정상 종료/에러 발생/강제 중단 시 모든 자원(PTB 창, 파일, 키 큐) 자동 안전 해제
% 3. 출발선 초기 화면을 먼저 Flip하여 사용자에게 준비 상태를 확실히 보여줌
% 4. ESC 키 입력 시 언제든지 안전하게 즉시 종료
% =========================================================================

% [기본설정 1] 이전 실행의 메모리 잔여물과 열려있는 창들을 깨끗하게 초기화합니다.
clear;          % 작업 공간(Workspace) 메모리에 남아있는 모든 변수를 삭제합니다.
clc;            % 명령창(Command Window)의 텍스트 로그를 모두 지웁니다.
close all;      % 일반 MATLAB Figure 창이 열려 있다면 모두 닫습니다.
sca;            % Screen('CloseAll')의 약어로, 열려 있는 Psychtoolbox(PTB) 화면을 모두 닫습니다.

% [기본설정 2] Psychtoolbox 실행 환경 설정
Screen('Preference', 'SkipSyncTests', 1); % 모니터 화면 주사율 동기화 오차로 인한 강제 중단을 방지합니다.
PsychDefaultSetup(1);                      % 키보드 이름 체계(KbName)를 통합하고 OpenGL 기본 파라미터를 설정합니다.

% =========================================================================
% [Modern MATLAB 핵심] onCleanup 객체 등록 (자원 안전 해제 보장)
% =========================================================================
% cleanUpObj 변수는 스크립트가 실행되는 동안 메모리에 상주합니다.
% 스크립트가 정상적으로 끝나든, 도중에 빨간색 에러가 터지든, 사용자가 Ctrl+C를 누르든
% 이 변수가 메모리에서 사라지는(Destroy) 순간 하단의 cleanupRoutine() 함수를 100% 무조건 강제 실행합니다.
% 덕분에 긴 try-catch 문이나 중복된 sca/fclose 호출을 모두 없앨 수 있습니다.
cleanUpObj = onCleanup(@() cleanupRoutine());

% 1. 화면 및 기준 색상 설정
screens = Screen('Screens');          % 현재 PC에 연결된 모든 디스플레이 번호 목록을 배열로 가져옵니다.
screenNumber = max(screens);          % 듀얼 모니터일 경우 보조 모니터(최댓값), 단일 모니터면 0번을 선택합니다.
white = WhiteIndex(screenNumber);     % 해당 화면의 최고 밝기 흰색 값(255)을 가져옵니다.
black = BlackIndex(screenNumber);     % 해당 화면의 최저 밝기 검은색 값(0)을 가져옵니다.
gray = white / 2;                     % 배경으로 사용할 중간 회색(127.5)을 만듭니다.

% 회색 배경의 전체 화면 창을 열고 해상도 정보(windowRect = [0, 0, 가로폭, 세로폭])를 받아옵니다.
[window, windowRect] = Screen('OpenWindow', screenNumber, gray);
Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA'); % 도형 테두리의 매끄러운 곡선 처리를 켭니다.
Screen('TextSize', window, 24);       % 안내 텍스트의 글자 크기를 24포인트로 설정합니다.

screenWidth = windowRect(3);          % 화면 전체 가로 길이(픽셀)
screenHeight = windowRect(4);         % 화면 전체 세로 길이(픽셀)

startX = 50;                          % 출발선 X좌표 (왼쪽 끝에서 50px)
middleX = screenWidth / 2;            % 중간 휴식 기준선 X좌표 (화면 정중앙)
finishX = screenWidth - 80;           % 결승선 X좌표 (오른쪽 끝에서 80px 안쪽)

% 2. 타원 규격 및 색상 행렬 (1열: Red, 2열: Blue)
ovalWidth = 50;                       % 타원의 가로 직경
ovalHeight = 35;                      % 타원의 세로 직경 (가로 != 세로 이므로 완전한 타원 형태)

redColor = [255, 0, 0];               % 빨간색 RGB 벡터
blueColor = [0, 0, 255];              % 파란색 RGB 벡터
ovalColor = [redColor', blueColor']; % Screen('FillOval')에 한 번에 넣기 위해 3행 2열 행렬로 구성합니다.

% 3. 상태 변수 초기화 (1x2 행벡터: 항상 1열은 Red, 2열은 Blue를 의미합니다)
positionX = [startX, startX] + ovalWidth / 2; % 출발할 때 타원의 왼쪽 끝이 출발선에 딱 닿도록 중심 좌표를 설정합니다.
positionY = screenHeight * [0.35, 0.65];   % 빨간 타원은 상단 트랙(35%), 파란 타원은 하단 트랙(65%)에 배치합니다.

totalDistant = [0, 0];                   % [선택2] 각 타원의 누적 총 이동 거리
currDistant = [0, 0];                    % [선택2] 각 타원의 현재 스텝 이동 거리
restLeft = [0, 0];                    % [선택1] 각 타원의 남은 휴식 시간 (카운트다운용)
hasRested = [false, false];           % [선택1] 중간선을 넘어 5초 휴식을 이미 치렀는지 기억하는 논리형(logical) 플래그

minStep = 10;                         % 1회 화면 전환 시 최소 이동 픽셀
maxStep = 45;                         % 1회 화면 전환 시 최대 이동 픽셀
restDuration = 5.0;                   % [선택1] 중간 지점 휴식 시간 (5초)
dt = 0.5;                             % 화면 전환 주기 (0.5초 간격으로 전환되어 눈으로 읽기 편함)

winner = 'None';                      % 승자가 결정되기 전까지는 'None'
step = 0;                             % 이동 횟수를 세는 카운터

% 4. [문제 2] 결과 저장용 CSV 파일 오픈 및 열 제목(Header) 작성
fileID = fopen('race_result_vectorized.csv', 'w');
fprintf(fileID, 'Step,RedCurrent,BlueCurrent,RedTotal,BlueTotal\n');

% 5. 비동기 키보드 큐 시작 (ESC 입력을 대기 시간 중에도 유실 없이 즉시 감지)
KbQueueCreate;
KbQueueStart;

% =========================================================================
% [중요 개선] 출발선에 정지해 있는 초기 화면을 먼저 Flip하여 모니터에 출력!
% =========================================================================
Screen('FillRect', window, gray);     % 배경을 깨끗이 덮습니다.
Screen('DrawLine', window, white, startX, 50, startX, screenHeight - 50, 2);   % 출발선
Screen('DrawLine', window, white, finishX, 50, finishX, screenHeight - 50, 2); % 결승선
Screen('DrawLine', window, white, middleX, 50, middleX, screenHeight - 50, 1); % 중간선

% 두 타원의 [Left; Top; Right; Bottom] 좌표를 4행 2열 행렬로 묶어 동시에 그립니다.
ovalRects = [positionX - ovalWidth/2; positionY - ovalHeight/2; positionX + ovalWidth/2; positionY + ovalHeight/2];
Screen('FillOval', window, ovalColor, ovalRects);

DrawFormattedText(window, 'Ready... Race will start soon! (ESC to quit)', 'center', screenHeight - 70, white);
Screen('Flip', window);               % 출발선 정지 화면을 화면에 띄웁니다.
WaitSecs(1.0);                        % 1초간 출발 준비 상태를 보여줍니다.

% =========================================================================
% 메인 경주 루프 시작
% =========================================================================
while true
    step = step + 1;

    % ---------------------------------------------------------------------
    % 1. [핵심] for i = 1:2 루프를 완전히 대체한 논리 인덱싱(Logical Indexing)
    % ---------------------------------------------------------------------
    % (1) 중간선 통과 감지:
    %     'positionX >= middleX'는 1x2 logical 배열 [red통과, blue통과]를 반환합니다.
    %     여기에 '~hasRested'를 AND(&) 연산하면 "이번에 처음으로 중간선을 넘은 타원"만 true가 됩니다.
    triggerRest = (positionX >= middleX) & ~hasRested;
    restLeft(triggerRest) = restDuration;   % true에 해당하는 타원 위치에만 5.0초를 대입합니다.
    hasRested(triggerRest) = true;          % true에 해당하는 타원 위치만 쉰 적 있음(true)으로 변경합니다.

    % (2) 이동 처리:
    %     현재 남은 휴식 시간이 0보다 큰 타원들을 찾습니다.
    isResting = (restLeft > 0);
    currDistant = zeros(1, 2);                 % 일단 두 타원 모두 이동 거리를 0으로 초기화합니다.
    activeCount = sum(~isResting);          % 현재 쉬지 않고 달려야 하는 타원의 개수(0, 1, 또는 2)

    if activeCount > 0
        % 쉬고 있지 않은 타원(~isResting) 자리에만 activeCount 개수만큼의 난수(10~45)를 뽑아 꽂아 넣습니다!
        currDistant(~isResting) = randi([minStep, maxStep], 1, activeCount);
    end

    % (3) 누적 거리 및 타원 위치 일괄 갱신 (1x2 벡터 덧셈):
    totalDistant = totalDistant + currDistant;
    % 도착선(finishX)을 타원의 오른쪽 끝이 뚫고 나가지 않도록 min 함수로 한 번에 제한합니다.
    positionX = min(positionX + currDistant, finishX - ovalWidth/2);

    % ---------------------------------------------------------------------
    % 2. 결승선 통과 판정 (타원의 오른쪽 테두리 'positionX + ovalWidth/2' 기준)
    % ---------------------------------------------------------------------
    isFinished = (positionX + ovalWidth/2) >= finishX; % 1x2 logical 벡터
    if isFinished(1) && isFinished(2)
        winner = 'Draw';              % 두 타원이 동시에 닿았다면 무승부
    elseif isFinished(1)
        winner = 'Red Win';           % 빨강이 먼저 닿음
    elseif isFinished(2)
        winner = 'Blue Win';          % 파랑이 먼저 닿음
    end

    % ---------------------------------------------------------------------
    % 3. 화면 렌더링 (배경, 기준선, 타원, 텍스트)
    % ---------------------------------------------------------------------
    Screen('FillRect', window, gray);
    Screen('DrawLine', window, white, startX, 50, startX, screenHeight - 50, 2);
    Screen('DrawLine', window, white, finishX, 50, finishX, screenHeight - 50, 2);
    Screen('DrawLine', window, white, middleX, 50, middleX, screenHeight - 50, 1);

    % 4행 2열 행렬로 묶인 두 타원을 단 한 번의 호출로 렌더링합니다.
    ovalRects = [positionX - ovalWidth/2; positionY - ovalHeight/2; positionX + ovalWidth/2; positionY + ovalHeight/2];
    Screen('FillOval', window, ovalColor, ovalRects);

    % [선택2] 이동 거리 텍스트 표시
    redText = sprintf('Red Total: %d pixel, Current: %d pixel', totalDistant(1), currDistant(1));
    blueText = sprintf('Blue Total: %d pixel, Current: %d pixel', totalDistant(2), currDistant(2));
    DrawFormattedText(window, redText, 'center', positionY(1) - 60, redColor);
    DrawFormattedText(window, blueText, 'center', positionY(2) - 60, blueColor);

    % [선택1] 5초 휴식 남은 시간 실시간 표시 (소수점 1자리)
    if restLeft(1) > 0
        DrawFormattedText(window, sprintf('Red Rest: %.1f sec', restLeft(1)), 'center', positionY(1) + 40, white);
    end
    if restLeft(2) > 0
        DrawFormattedText(window, sprintf('Blue Rest: %.1f sec', restLeft(2)), 'center', positionY(2) + 40, white);
    end

    % 승자가 나왔다면 화면 중앙에 결과 문구를 띄우고, 아니면 하단에 종료 안내를 띄웁니다.
    if ~strcmp(winner, 'None')
        DrawFormattedText(window, winner, 'center', 'center', white);
    else
        DrawFormattedText(window, 'ESC: Exit', 'center', screenHeight - 50, white);
    end

    % 백버퍼에 그린 완성본을 모니터로 송출(Flip)합니다.
    Screen('Flip', window);

    % ---------------------------------------------------------------------
    % 4. [문제 2] 현재 스텝 데이터를 CSV 파일에 한 줄 기록
    % ---------------------------------------------------------------------
    fprintf(fileID, '%d,%d,%d,%d,%d\n', step, currDistant(1), currDistant(2), totalDistant(1), totalDistant(2));

    % 승부가 났으면 결과 문구를 2초 동안 화면에 보여준 뒤 while 루프를 탈출합니다.
    if ~strcmp(winner, 'None')
        WaitSecs(2.0);
        break;
    end

    % ESC 키를 눌렀는지 확인하여 강제 중단 처리합니다.
    [pressed, firstPress] = KbQueueCheck;
    if pressed && firstPress(KbName('ESCAPE'))
        winner = 'Aborted';
        break;
    end

    % 다음 화면 전환 주기(dt=0.5초) 동안 대기한 뒤, 남은 휴식 시간에서 dt를 차감합니다.
    WaitSecs(dt);
    restLeft = max(0, restLeft - dt); % 음수로 내려가는 것을 max(0, ...)로 방지
end

% 5. 최종 경기 결과 기록 및 종료
fprintf(fileID, '\nResult,%s\nRed Total,%d\nBlue Total,%d\n', winner, totalDistant(1), totalDistant(2));
fclose(fileID);
disp(['Experiment Finished. Result: ', winner]);

% =========================================================================
% [로컬 정리 함수] onCleanup 객체에 의해 자동으로 호출되는 자원 해제 루틴
% =========================================================================
function cleanupRoutine()
    % 스크립트가 성공적으로 끝났을 때는 물론, 오류 발생 또는 강제 종료 시에도
    % 이 함수가 무조건 실행되어 모니터 먹통 현상이나 파일 손상을 원천 방지합니다.
    fclose('all');      % 열려 있는 모든 파일 핸들을 안전하게 닫습니다.
    try
        KbQueueRelease; % 백그라운드 키보드 큐 메모리를 반환합니다.
    catch
    end
    sca;                % 열려 있는 PTB 창을 닫아 원래 바탕화면으로 돌아옵니다.
    ShowCursor;         % 숨겨졌던 마우스 커서를 다시 보이게 합니다.
    disp('All resources have been safely cleaned up by onCleanup.');
end
