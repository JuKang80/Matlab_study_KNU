%% =========================================================================
% [Week 6th] 과제 구현 - 벡터화(Logical Indexing) 최적화 버전
% 
% [적정 엔지니어링 개선점]
% 1. for i = 1:2 루프를 완전히 제거하고 MATLAB 고유의 '논리 인덱싱(Logical Indexing)' 적용
% 2. 출발선 초기 화면을 먼저 Flip하여 사용자에게 준비 상태를 확실히 보여줌
% 3. 채점 기준(fopen/fprintf/fclose, try-catch, 스칼라 변수 체계)은 그대로 유지하여 오버엔지니어링 방지
% 4. ESC 키 입력 시 언제든지 안전하게 즉시 종료
% =========================================================================

clear;
clc;
close all;
sca;

% 기본 설정
Screen('Preference', 'SkipSyncTests', 1);
PsychDefaultSetup(1);

try
    % 1. 화면 및 기준 색상 설정
    screens = Screen('Screens');
    screenNumber = max(screens);
    white = WhiteIndex(screenNumber);
    black = BlackIndex(screenNumber);
    gray = white / 2;

    [window, windowRect] = Screen('OpenWindow', screenNumber, gray);
    Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');
    Screen('TextSize', window, 24);

    screenWidth = windowRect(3);
    screenHeight = windowRect(4);

    startX = 50;
    middleX = screenWidth / 2;
    finishX = screenWidth - 80;

    % 2. 타원 규격 및 색상 행렬 (1열: Red, 2열: Blue)
    ovalWidth = 50;
    ovalHeight = 35; % 타원(Oval)

    redColor = [255, 0, 0];
    blueColor = [0, 0, 255];
    ovalColors = [redColor', blueColor']; % 3행 2열 색상 행렬

    % 3. 상태 변수 초기화 (1x2 행벡터: 1열=Red, 2열=Blue)
    posX = [startX, startX] + ovalWidth / 2;
    posY = screenHeight * [0.35, 0.65];

    totalDist = [0, 0];
    currDist = [0, 0];
    restLeft = [0, 0];          % 남은 5초 휴식 시간
    hasRested = [false, false]; % 중간선 휴식 완료 여부

    minStep = 10;
    maxStep = 45;
    restDuration = 5.0;         % 중간 지점 휴식 시간: 5초
    dt = 0.5;                   % 화면 전환 주기 (0.5초)

    winner = 'None';
    step = 0;

    % 4. [문제 2] CSV 파일 열기 및 헤더 작성
    fileID = fopen('race_result_vectorized.csv', 'w');
    fprintf(fileID, 'Step,RedCurrent,BlueCurrent,RedTotal,BlueTotal\n');

    % 5. 비동기 키보드 큐 시작 (ESC 즉시 감지용)
    KbQueueCreate;
    KbQueueStart;

    % =====================================================================
    % [개선] 출발선에 정지해 있는 초기 화면을 먼저 모니터에 출력!
    % =====================================================================
    Screen('FillRect', window, gray);
    Screen('DrawLine', window, white, startX, 50, startX, screenHeight - 50, 2);
    Screen('DrawLine', window, white, finishX, 50, finishX, screenHeight - 50, 2);
    Screen('DrawLine', window, white, middleX, 50, middleX, screenHeight - 50, 1);

    ovalRects = [posX - ovalWidth/2; posY - ovalHeight/2; posX + ovalWidth/2; posY + ovalHeight/2];
    Screen('FillOval', window, ovalColors, ovalRects);

    DrawFormattedText(window, 'Ready... Race will start soon! (ESC to quit)', 'center', screenHeight - 70, white);
    Screen('Flip', window);
    WaitSecs(1.0); % 출발선 화면 1초 대기

    % =====================================================================
    % 메인 경주 루프 시작
    % =====================================================================
    while true
        step = step + 1;

        % -----------------------------------------------------------------
        % 1. [핵심 개선] for 루프 없는 논리 인덱싱(Logical Indexing) 벡터 연산
        % -----------------------------------------------------------------
        % (1) 중간선 도달 판정: 중심 좌표가 middleX 이상이고 아직 쉰 적이 없는 타원 필터링
        triggerRest = (posX >= middleX) & ~hasRested;
        restLeft(triggerRest) = restDuration;   % 해당 타원에게만 5초 휴식 부여
        hasRested(triggerRest) = true;          % 중복 휴식 방지 플래그 true 설정

        % (2) 이동 처리: 현재 쉬고 있지 않은 타원(~isResting)만 골라서 랜덤 거리 부여
        isResting = (restLeft > 0);
        currDist = zeros(1, 2); % 기본은 이동 거리 0으로 초기화
        activeCount = sum(~isResting);

        if activeCount > 0
            % 쉬지 않는 타원 개수(activeCount)만큼만 1xN 난수 생성 후 대입
            currDist(~isResting) = randi([minStep, maxStep], 1, activeCount);
        end

        % (3) 누적 거리 및 타원 위치 일괄 갱신
        totalDist = totalDist + currDist;
        posX = min(posX + currDist, finishX - ovalWidth/2); % 도착선 넘지 않게 min 처리

        % -----------------------------------------------------------------
        % 2. 결승선 통과 판정 (타원 오른쪽 끝 기준)
        % -----------------------------------------------------------------
        isFinished = (posX + ovalWidth/2) >= finishX;
        if isFinished(1) && isFinished(2)
            winner = 'Draw';
        elseif isFinished(1)
            winner = 'Red Win';
        elseif isFinished(2)
            winner = 'Blue Win';
        end

        % -----------------------------------------------------------------
        % 3. 화면 렌더링 (배경, 기준선, 타원, 텍스트)
        % -----------------------------------------------------------------
        Screen('FillRect', window, gray);
        Screen('DrawLine', window, white, startX, 50, startX, screenHeight - 50, 2);
        Screen('DrawLine', window, white, finishX, 50, finishX, screenHeight - 50, 2);
        Screen('DrawLine', window, white, middleX, 50, middleX, screenHeight - 50, 1);

        % 타원 4x2 좌표 행렬 계산 및 일괄 그리기
        ovalRects = [posX - ovalWidth/2; posY - ovalHeight/2; posX + ovalWidth/2; posY + ovalHeight/2];
        Screen('FillOval', window, ovalColors, ovalRects);

        % [선택2] 이동 거리 텍스트 표시
        redText = sprintf('Red Total: %d pixel, Current: %d pixel', totalDist(1), currDist(1));
        blueText = sprintf('Blue Total: %d pixel, Current: %d pixel', totalDist(2), currDist(2));
        DrawFormattedText(window, redText, 'center', posY(1) - 60, redColor);
        DrawFormattedText(window, blueText, 'center', posY(2) - 60, blueColor);

        % [선택1] 5초 휴식 남은 시간 실시간 표시
        if restLeft(1) > 0
            DrawFormattedText(window, sprintf('Red Rest: %.1f sec', restLeft(1)), 'center', posY(1) + 40, white);
        end
        if restLeft(2) > 0
            DrawFormattedText(window, sprintf('Blue Rest: %.1f sec', restLeft(2)), 'center', posY(2) + 40, white);
        end

        % 승자 또는 안내 문구 출력
        if ~strcmp(winner, 'None')
            DrawFormattedText(window, winner, 'center', 'center', white);
        else
            DrawFormattedText(window, 'ESC: Exit', 'center', screenHeight - 50, white);
        end

        % 백버퍼 화면을 모니터로 송출
        Screen('Flip', window);

        % -----------------------------------------------------------------
        % 4. [문제 2] 현재 스텝 데이터를 CSV 파일에 한 줄 기록
        % -----------------------------------------------------------------
        fprintf(fileID, '%d,%d,%d,%d,%d\n', step, currDist(1), currDist(2), totalDist(1), totalDist(2));

        % 승부가 났으면 2초간 승리 화면을 보여준 뒤 종료
        if ~strcmp(winner, 'None')
            WaitSecs(2.0);
            break;
        end

        % ESC 키 감지 시 즉시 중단
        [pressed, firstPress] = KbQueueCheck;
        if pressed && firstPress(KbName('ESCAPE'))
            winner = 'Aborted';
            break;
        end

        % 다음 화면 전환까지 dt(0.5초) 대기 및 남은 휴식 시간 차감
        WaitSecs(dt);
        restLeft = max(0, restLeft - dt);
    end

    % 5. 최종 결과 기록 및 정상 자원 해제
    fprintf(fileID, '\nResult,%s\nRed Total,%d\nBlue Total,%d\n', winner, totalDist(1), totalDist(2));
    fclose(fileID);

    KbQueueRelease;
    sca;
    ShowCursor;
    disp(['Experiment Finished. Result: ', winner]);

catch info
    % 예외 발생 시 안전 해제
    fclose('all');
    KbQueueRelease;
    sca;
    ShowCursor;
    rethrow(info);
end
