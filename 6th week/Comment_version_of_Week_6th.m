%% 1. 화면이 전환될 때마다 왼쪽에서 오른쪽으로 랜덤한 거리를 이동하는 빨간 타원과 파란 타원을 그리세요. 화면 전환 방식은 타이머, 키보드 입력, 마우스 입력 등 자유롭게 설정하세요. 오른쪽 맨 끝 혹은 임의의 도착 지점에 한 타원이 도달하면 'Red Win'과 같이 결과를 글자로 띄우세요.

%% 2. 엑셀 또는 메모장에 경기 결과와 각 타원의 이동 거리를 저장하세요.

% [선택 문제1] 한 타원이 화면 중간지점을 통과하면 5초 휴식 후 이동하게 만들어보세요. 남은 휴식 시간의 타이머를 보여주세요.

% [선택 문제2] 두 타원이 이동한 거리를 화면에 띄우세요.
% ex) red 총합: 300pixel, 현재: 5pixel

% =========================================================================
% [구두 발표 핵심 포인트 4가지 요약]
% 1. MATLAB다운 벡터화(Vectorization):
%    빨간 타원(1열)과 파란 타원(2열)의 변수를 따로 만들지 않고, [1x2] 행벡터(posX, posY,
%    totalDist, currDist, restLeft, hasRested)로 묶고 for i = 1:2로 처리해 중복을 없앴습니다.
% 2. 다중 도형 동시 렌더링 (5주차 기법 응용):
%    [3x2] 색상 행렬과 [4x2] 좌표 행렬을 만들어 Screen('FillOval') 단 한 번의 호출로
%    두 타원을 동시에 그렸습니다.
% 3. 직관적인 5초 휴식 타이머:
%    중간선 통과 다음 스텝부터 남은 휴식 시간(restLeft = 5)을 부여해 화면에 5.0초부터 띄우고,
%    WaitSecs(dt) 대기 직후에 dt(0.25초)씩 차감하는 카운트다운 방식을 사용했습니다.
% 4. 깔끔한 단일 결과 파일(race_result.csv) 저장:
%    엑셀과 메모장 모두에서 바로 열리는 CSV 파일 하나에 매 스텝 이동 거리와 최종 경기 결과를
%    fprintf로 직관적으로 기록했습니다.
% =========================================================================

% 기본설정 1: 기존 작업 환경과 열려있는 창들을 깨끗하게 초기화합니다.
clear;          % 작업 공간(Workspace) 메모리에 남아있는 모든 변수를 삭제합니다.
clc;            % 명령창(Command Window)의 이전 출력 기록을 모두 지웁니다.
close all;      % 열려 있는 모든 일반 MATLAB Figure 창을 닫습니다.
sca;            % Screen('CloseAll')의 약자로, 열려 있는 모든 Psychtoolbox(PTB) 창을 닫습니다.

% 기본설정 2: Psychtoolbox 실행 환경 및 키보드/색상 기본값을 설정합니다.
Screen('Preference', 'SkipSyncTests', 1); % 모니터 주사율 동기화 검사를 건너뛰어 맥/노트북 환경에서도 에러 없이 즉시 창이 열리게 합니다.
PsychDefaultSetup(1);                      % PTB의 기본 OpenGL 환경 확인 및 운영체제 통합 키보드 이름 체계(UnifyKeyNames)를 1단계로 초기화합니다.

try
    % 모니터 번호와 기본 색상값(흰색, 검은색, 회색)을 정의합니다.
    screens = Screen('Screens');          % 현재 PC에 연결된 모든 모니터의 번호 목록을 배열로 가져옵니다.
    screenNumber = max(screens);          % 모니터가 여러 대면 외부 보조 모니터(최댓값)를, 한 대면 기본 모니터(0)를 선택합니다.
    white = WhiteIndex(screenNumber);     % 해당 모니터의 가장 밝은 흰색 값(255)을 가져옵니다.
    black = BlackIndex(screenNumber);     % 해당 모니터의 가장 어두운 검은색 값(0)을 가져옵니다.
    gray = white / 2;                     % 흰색의 절반 값(127.5)을 계산하여 배경으로 사용할 회색을 만듭니다.

    % 실험 화면 창을 열고 텍스트 및 투명도 옵션을 설정합니다.
    [window, windowRect] = Screen('OpenWindow', screenNumber, gray); % 회색 배경의 전체 화면 창을 열고, 창 핸들(window)과 화면 크기 배열(windowRect = [0, 0, 가로폭, 세로폭])을 반환받습니다.
    Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA'); % 도형 테두리와 투명도(Alpha 채널)가 부드럽게 표현되도록 알파 블렌딩을 켭니다.
    Screen('TextSize', window, 24);       % 화면에 출력할 모든 글자(이동 거리, 휴식 타이머, 승리 결과)의 기본 크기를 24포인트로 설정합니다.

    % 화면 가로/세로 해상도를 추출하고 기준선(출발선, 중간선, 도착선)의 X 좌표를 계산합니다.
    screenWidth = windowRect(3);          % windowRect의 3번째 원소인 화면 전체 가로 픽셀 길이를 가져옵니다.
    screenHeight = windowRect(4);         % windowRect의 4번째 원소인 화면 전체 세로 픽셀 길이를 가져옵니다.

    startX = 50;                          % 출발선은 화면 왼쪽 끝에서 오른쪽으로 50픽셀 떨어진 지점으로 설정합니다.
    middleX = screenWidth / 2;            % [선택 문제1] 휴식 기준이 되는 화면 정중앙의 X 좌표를 가로 폭의 절반으로 계산합니다.
    finishX = screenWidth - 80;           % 도착선은 화면 오른쪽 끝에서 왼쪽으로 80픽셀 안쪽 지점으로 설정합니다.

    % 타원의 가로/세로 지름 크기와 RGB 색상을 설정합니다. (1열: 빨간 타원, 2열: 파란 타원)
    ovalWidth = 50;                       % 타원의 가로 길이(폭)를 50픽셀로 설정합니다.
    ovalHeight = 35;                      % 타원의 세로 길이(높이)를 35픽셀로 설정합니다. (가로와 세로가 달라야 원이 아닌 타원이 됩니다)

    redColor = [255, 0, 0];               % 빨간 타원과 빨간 글씨에 사용할 RGB 색상 행벡터입니다.
    blueColor = [0, 0, 255];              % 파란 타원과 파란 글씨에 사용할 RGB 색상 행벡터입니다.
    ovalColors = [redColor', blueColor']; % Screen('FillOval')에 한 번에 넣기 위해 각 색상을 세로(열벡터)로 세워 3행 2열([R; G; B] x 2개 타원) 행렬로 묶습니다.

    % 두 타원의 위치 및 상태 변수를 [1행 2열] 벡터로 한 번에 초기화합니다. (항상 1열은 Red, 2열은 Blue를 의미합니다)
    posX = [startX, startX] + ovalWidth / 2; % 출발할 때 타원의 '왼쪽 끝'이 출발선(startX)에 딱 맞닿도록 중심 X 좌표를 'startX + 가로반지름(25)'으로 시작합니다.
    posY = screenHeight * [0.35, 0.65];   % 빨간 타원은 화면 세로 35%(위쪽 트랙), 파란 타원은 65%(아래쪽 트랙) 높이에 배치합니다.

    totalDist = [0, 0];                   % [선택 문제2] 두 타원의 누적 총 이동 거리(Total)를 저장할 1x2 벡터입니다.
    currDist = [0, 0];                    % [선택 문제2] 두 타원이 현재 화면 전환에서 이동한 거리(Current)를 저장할 1x2 벡터입니다.
    restLeft = [0, 0];                    % [선택 문제1] 두 타원의 남은 휴식 시간(초)을 카운트다운할 1x2 벡터입니다.
    hasRested = [false, false];           % [선택 문제1] 각 타원이 중간선에서 이미 5초 휴식을 했는지 기억하는 논리형(logical) 1x2 벡터입니다. (한 번만 쉬어야 하므로 필수)

    % 랜덤 이동 거리 범위와 시간 간격을 설정합니다.
    minStep = 10;                         % 한 번 화면이 전환될 때 이동할 수 있는 최소 픽셀 거리입니다.
    maxStep = 45;                         % 한 번 화면이 전환될 때 이동할 수 있는 최대 픽셀 거리입니다.
    restDuration = 5;                     % [선택 문제1] 중간 지점 통과 시 부여할 휴식 시간(5초)입니다.
    dt = 0.25;                            % 화면 전환 주기(타이머 간격)를 0.25초(초당 4번 이동)로 설정하여 눈으로 현재 이동 픽셀을 읽을 수 있게 합니다.

    winner = 'None';                      % 승자가 결정되기 전까지는 'None' 문자열로 상태를 유지합니다.
    step = 0;                             % 몇 번째 이동(화면 전환)인지 세는 카운터 변수입니다.

    % [문제 2] 엑셀과 메모장 모두에서 바로 열 수 있는 CSV 파일을 열고 첫 줄(열 제목)을 적어둡니다.
    fileID = fopen('race_result.csv', 'w'); % 현재 폴더에 'race_result.csv' 파일을 쓰기 모드('w')로 열고 파일 핸들(fileID)을 받습니다.
    fprintf(fileID, 'Step,RedCurrent,BlueCurrent,RedTotal,BlueTotal\n'); % 쉼표(,)로 구분된 열 제목(스텝, 현재 이동거리, 누적 이동거리)을 첫 줄에 기록합니다.

    % 비동기 키보드 입력 감지 큐를 준비하고 시작합니다. (WaitSecs 대기 중에 누른 ESC 키도 놓치지 않고 잡아냅니다)
    KbQueueCreate;                        % 키보드 입력을 백그라운드에서 저장할 큐(Queue) 메모리를 생성합니다.
    KbQueueStart;                         % 키보드 입력 모니터링을 시작합니다.

    % ==================== 메인 경주 루프 시작 ====================
    while true
        step = step + 1;                  % 화면이 전환될 때마다 스텝 번호를 1씩 증가시킵니다.

        % 1. 두 타원(i=1: 빨간 타원, i=2: 파란 타원)의 휴식 및 랜덤 이동을 처리하는 반복문입니다.
        for i = 1:2
            % [중간선 휴식 진입 체크] 이전 스텝의 이동으로 중심 좌표(posX)가 중간선(middleX)을 처음 넘었고 아직 쉰 적이 없다면:
            % (이 체크를 이동 코드보다 위에 두어야, 중간선을 넘은 스텝에는 이동 거리를 먼저 보여주고 '그 다음 스텝'부터 휴식이 시작됩니다!)
            if posX(i) >= middleX && ~hasRested(i)
                restLeft(i) = restDuration; % 남은 휴식 시간을 5초(5.0 sec)로 설정합니다.
                hasRested(i) = true;        % 이미 휴식을 시작했다고 표시하여, 5초 뒤 다시 출발할 때 중복으로 쉬지 않게 합니다.
            end

            % [휴식 중 vs 이동 중 분기 처리]
            % (어차피 한 타원이라도 도착선에 닿으면 아래에서 break로 경기가 즉시 종료되므로, 루프 안에서는 휴식 여부만 판단하면 됩니다)
            if restLeft(i) > 0            % 남은 휴식 시간이 0보다 크면(현재 휴식 중이면):
                currDist(i) = 0;          % 이번 화면 전환에서는 이동하지 않으므로 현재 이동 거리를 0으로 둡니다.
            else                          % 휴식 중이 아니라면 오른쪽으로 랜덤 이동합니다:
                currDist(i) = randi([minStep, maxStep]); % 10~45 픽셀 사이의 랜덤한 정수를 뽑아 이번 스텝 이동 거리로 저장합니다.
                totalDist(i) = totalDist(i) + currDist(i); % 뽑힌 랜덤 거리를 누적 총 이동 거리에 그대로 더합니다.
                posX(i) = min(posX(i) + currDist(i), finishX - ovalWidth/2); % 타원을 이동시키되, 타원의 오른쪽 끝(posX + ovalWidth/2)이 도착선(finishX)을 넘지 않도록 도착선 위치에서 딱 멈추게(min) 합니다.
            end
        end

        % 2. 도착선 통과 및 승리 판정 (타원의 오른쪽 끝 'posX + ovalWidth/2'가 도착선 'finishX'에 닿았는지 확인)
        isFinished = (posX + ovalWidth/2) >= finishX; % [1x2] 논리형 벡터: 1열은 빨강 도착 여부, 2열은 파랑 도착 여부입니다.
        if isFinished(1) && isFinished(2) % 두 타원이 같은 스텝에 동시에 도착선에 닿았다면:
            winner = 'Draw';              % 무승부('Draw')로 판정합니다.
        elseif isFinished(1)              % 빨간 타원이 먼저 도착선에 닿았다면:
            winner = 'Red Win';           % 'Red Win'으로 판정합니다.
        elseif isFinished(2)              % 파란 타원이 먼저 도착선에 닿았다면:
            winner = 'Blue Win';          % 'Blue Win'으로 판정합니다.
        end

        % 3. 화면 버퍼에 그래픽 요소(배경, 기준선 3개, 타원 2개, 안내 텍스트)를 순서대로 그립니다.
        Screen('FillRect', window, gray); % 이전 화면의 잔상을 지우기 위해 전체 화면을 회색 배경으로 다시 덮어줍니다.

        % 출발선(굵기 2), 도착선(굵기 2), 중간선(굵기 1)을 위쪽(Y=50)부터 아래쪽(Y=screenHeight-50)까지 흰색 세로선으로 그립니다.
        Screen('DrawLine', window, white, startX, 50, startX, screenHeight - 50, 2);
        Screen('DrawLine', window, white, finishX, 50, finishX, screenHeight - 50, 2);
        Screen('DrawLine', window, white, middleX, 50, middleX, screenHeight - 50, 1);

        % [핵심] 두 타원의 외곽 사각형 좌표 [Left; Top; Right; Bottom]을 4행 2열 행렬로 한 번에 계산합니다.
        % posX와 posY가 [1x2] 행벡터이므로, 위아래로 쌓으면 자동으로 [4x2] 행렬(1열: 빨간 타원 좌표, 2열: 파란 타원 좌표)이 완성됩니다!
        ovalRects = [posX - ovalWidth/2; posY - ovalHeight/2; posX + ovalWidth/2; posY + ovalHeight/2];
        Screen('FillOval', window, ovalColors, ovalRects); % 3x2 색상 행렬(ovalColors)과 4x2 좌표 행렬(ovalRects)을 넣어 두 타원을 동시에 그립니다.

        % [선택 문제2] 각 타원의 누적 이동 거리(Total)와 현재 이동 거리(Current)를 각 트랙 위쪽(posY - 60) 가로 중앙('center')에 표시합니다.
        redText = sprintf('Red Total: %d pixel, Current: %d pixel', totalDist(1), currDist(1));
        blueText = sprintf('Blue Total: %d pixel, Current: %d pixel', totalDist(2), currDist(2));
        DrawFormattedText(window, redText, 'center', posY(1) - 60, redColor);
        DrawFormattedText(window, blueText, 'center', posY(2) - 60, blueColor);

        % [선택 문제1] 휴식 중인 타원이 있다면 각 트랙 아래쪽(posY + 40)에 남은 휴식 시간을 소수점 첫째 자리(5.0 sec -> 4.8 sec ...)까지 표시합니다.
        if restLeft(1) > 0
            DrawFormattedText(window, sprintf('Red Rest: %.1f sec', restLeft(1)), 'center', posY(1) + 40, white);
        end
        if restLeft(2) > 0
            DrawFormattedText(window, sprintf('Blue Rest: %.1f sec', restLeft(2)), 'center', posY(2) + 40, white);
        end

        % 승자가 결정되었다면 화면 정중앙('center', 'center')에 결과('Red Win' 등)를 띄웁니다.
        if ~strcmp(winner, 'None')        % winner 문자열이 'None'이 아니라면(즉 승부가 났다면):
            DrawFormattedText(window, winner, 'center', 'center', white); % 화면 정중앙에 승리 문구를 그립니다.
        end

        % 버퍼에 그린 모든 그림과 글자를 실제 모니터 화면으로 전환(Flip)하여 보여줍니다.
        Screen('Flip', window);

        % 4. [문제 2] 현재 스텝에서 각 타원의 현재 이동 거리와 누적 이동 거리를 CSV 파일에 한 줄씩 기록합니다.
        fprintf(fileID, '%d,%d,%d,%d,%d\n', step, currDist(1), currDist(2), totalDist(1), totalDist(2));

        % 승자가 결정되었다면 화면에 뜬 'Red Win' 등의 결과를 2초 동안 보여준 뒤 while 루프를 종료(break)합니다.
        if ~strcmp(winner, 'None')
            WaitSecs(2);
            break;
        end

        % 대기 시간 동안 사용자가 ESC 키를 눌렀는지 확인하여 강제 종료할 수 있게 합니다.
        [pressed, firstPress] = KbQueueCheck; % 키가 눌렸는지 여부(pressed)와 각 키가 처음 눌린 시각 배열(firstPress)을 가져옵니다.
        if pressed && firstPress(KbName('ESCAPE')) % 키 입력이 있었고 그것이 ESC 키라면:
            winner = 'Aborted';           % 강제 종료 시 결과를 'Aborted'로 기록하고 루프를 빠져나갑니다.
            break;
        end

        % 다음 화면 전환까지 dt(0.25초) 동안 대기한 뒤, 휴식 중인 타원의 남은 휴식 시간을 dt만큼 차감합니다.
        % (대기 직후에 차감해야 첫 휴식 화면에서 정확히 5.0 sec가 먼저 표시되고, 5초가 끝난 직후 스텝에 지체 없이 바로 이동합니다!)
        WaitSecs(dt);
        restLeft = max(0, restLeft - dt); % [1x2] 벡터에서 0.25초를 빼되, 음수가 되지 않도록 max(0, ...)로 막아줍니다.
    end
    % ==================== 메인 경주 루프 종료 ====================

    % [문제 2] CSV 파일 맨 아래에 최종 경기 결과(승자)와 두 타원의 총 이동 거리를 기록하고 파일을 닫습니다.
    fprintf(fileID, '\nResult,%s\nRed Total,%d\nBlue Total,%d\n', winner, totalDist(1), totalDist(2));
    fclose(fileID);                       % 열었던 CSV 파일을 안전하게 닫아 저장을 완료합니다.

    % 실험 종료 후 키보드 큐와 PTB 화면 자원을 해제하고 마우스 커서를 복구합니다.
    KbQueueRelease;                       % 백그라운드 키보드 입력 감지 큐를 메모리에서 해제합니다.
    sca;                                  % 열려 있는 PTB 실험 창을 닫습니다.
    ShowCursor;                           % 숨겨졌던 마우스 커서를 다시 보이게 합니다.
    disp('Experiment successfully finished'); % 명령창에 정상 종료 메시지를 출력합니다.

catch info
    % 에러가 발생하더라도 열려 있는 파일과 PTB 창, 키보드 큐가 먹통이 되지 않도록 모두 안전하게 닫아줍니다.
    fclose('all');                        % 열려 있는 모든 파일을 안전하게 닫습니다.
    KbQueueRelease;                       % 에러 발생 시에도 키보드 큐를 해제합니다.
    sca;                                  % 화면이 멈추지 않도록 강제로 PTB 창을 닫습니다.
    ShowCursor;                           % 마우스 커서를 복구합니다.
    rethrow(info);                        % 발생한 에러 내용을 명령창에 그대로 출력합니다.
end
