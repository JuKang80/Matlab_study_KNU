%% 1. 화면이 전환될 때마다 왼쪽에서 오른쪽으로 랜덤한 거리를 이동하는 빨간 타원과 파란 타원을 그리세요. 화면 전환 방식은 타이머, 키보드 입력, 마우스 입력 등 자유롭게 설정하세요. 오른쪽 맨 끝 혹은 임의의 도착 지점에 한 타원이 도달하면 'Red Win'과 같이 결과를 글자로 띄우세요.

%% 2. 엑셀 또는 메모장에 경기 결과와 각 타원의 이동 거리를 저장하세요.

% [선택 문제1] 한 타원이 화면 중간지점을 통과하면 5초 휴식 후 이동하게 만들어보세요. 남은 휴식 시간의 타이머를 보여주세요.

% [선택 문제2] 두 타원이 이동한 거리를 화면에 띄우세요.
% ex) red 총합: 300pixel, 현재: 5pixel

% 기본설정 1
clear;
clc;
close all;
sca;

% 기본설정 2
Screen('Preference', 'SkipSyncTests', 1);
PsychDefaultSetup(1);

try
    screens = Screen('Screens');
    screenNumber = max(screens);
    white = WhiteIndex(screenNumber);
    black = BlackIndex(screenNumber);
    gray = white / 2;

    [window, windowRect] = Screen('OpenWindow', screenNumber, gray);
    Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');
    Screen('TextSize', window, 24);

    % 화면 크기 및 기준선(출발선, 중간선, 도착선) 설정
    screenWidth = windowRect(3);
    screenHeight = windowRect(4);

    startX = 50;
    middleX = screenWidth / 2;
    finishX = screenWidth - 80;

    % 타원 크기 및 색상 설정 (1열: 빨간 타원, 2열: 파란 타원)
    ovalWidth = 50;
    ovalHeight = 35;

    redColor = [255, 0, 0];
    blueColor = [0, 0, 255];
    ovalColors = [redColor', blueColor']; % 3행 2열 색상 행렬

    % 두 타원의 상태 변수 초기화 (1x2 행벡터 -> 1열: Red, 2열: Blue)
    posX = [startX, startX] + ovalWidth / 2;
    posY = screenHeight * [0.35, 0.65];

    totalDist = [0, 0];         % 누적 이동 거리
    currDist = [0, 0];          % 현재 이동 거리
    restLeft = [0, 0];          % 남은 휴식 시간(초)
    hasRested = [false, false]; % 중간 지점 휴식 완료 여부

    % 이동 범위 및 타이머 설정
    minStep = 10;
    maxStep = 45;
    restDuration = 5;           % 중간 지점 휴식 시간 (5초)
    dt = 0.25;                  % 화면 전환 주기 (0.25초)

    winner = 'None';
    step = 0;

    % 결과 저장용 파일 열기 (엑셀 및 메모장 겸용 CSV 파일)
    fileID = fopen('race_result.csv', 'w');
    fprintf(fileID, 'Step,RedCurrent,BlueCurrent,RedTotal,BlueTotal\n');

    % 키보드 입력 큐 시작
    KbQueueCreate;
    KbQueueStart;

    % 메인 경주 루프
    while true
        step = step + 1;

        % 1. 두 타원(1: Red, 2: Blue)의 휴식 및 랜덤 이동 처리
        for i = 1:2
            % 이전 스텝 이동으로 중간 지점을 처음 통과했다면 이번 스텝부터 5초 휴식 시작
            if posX(i) >= middleX && ~hasRested(i)
                restLeft(i) = restDuration;
                hasRested(i) = true;
            end

            % 휴식 시간이 남아있으면 제자리 대기, 아니면 랜덤 거리만큼 오른쪽으로 이동
            if restLeft(i) > 0
                currDist(i) = 0;
            else
                currDist(i) = randi([minStep, maxStep]);
                totalDist(i) = totalDist(i) + currDist(i);
                posX(i) = min(posX(i) + currDist(i), finishX - ovalWidth/2);
            end
        end

        % 2. 도착선 통과 판정 (타원의 오른쪽 끝 기준)
        isFinished = (posX + ovalWidth/2) >= finishX;
        if isFinished(1) && isFinished(2)
            winner = 'Draw';
        elseif isFinished(1)
            winner = 'Red Win';
        elseif isFinished(2)
            winner = 'Blue Win';
        end

        % 3. 화면 그리기 (배경, 기준선, 두 타원, 텍스트)
        Screen('FillRect', window, gray);

        Screen('DrawLine', window, white, startX, 50, startX, screenHeight - 50, 2);
        Screen('DrawLine', window, white, finishX, 50, finishX, screenHeight - 50, 2);
        Screen('DrawLine', window, white, middleX, 50, middleX, screenHeight - 50, 1);

        % 4행 2열 좌표 행렬로 두 타원을 한 번에 그리기
        ovalRects = [posX - ovalWidth/2; posY - ovalHeight/2; posX + ovalWidth/2; posY + ovalHeight/2];
        Screen('FillOval', window, ovalColors, ovalRects);

        % 누적 및 현재 이동 거리 표시
        redText = sprintf('Red Total: %d pixel, Current: %d pixel', totalDist(1), currDist(1));
        blueText = sprintf('Blue Total: %d pixel, Current: %d pixel', totalDist(2), currDist(2));
        DrawFormattedText(window, redText, 'center', posY(1) - 60, redColor);
        DrawFormattedText(window, blueText, 'center', posY(2) - 60, blueColor);

        % 남은 휴식 시간 타이머 표시
        if restLeft(1) > 0
            DrawFormattedText(window, sprintf('Red Rest: %.1f sec', restLeft(1)), 'center', posY(1) + 40, white);
        end
        if restLeft(2) > 0
            DrawFormattedText(window, sprintf('Blue Rest: %.1f sec', restLeft(2)), 'center', posY(2) + 40, white);
        end

        % 승리 결과 표시
        if ~strcmp(winner, 'None')
            DrawFormattedText(window, winner, 'center', 'center', white);
        end

        Screen('Flip', window);

        % 4. 현재 스텝의 이동 거리를 파일에 한 줄씩 저장
        fprintf(fileID, '%d,%d,%d,%d,%d\n', step, currDist(1), currDist(2), totalDist(1), totalDist(2));

        % 승자가 결정되면 2초간 결과를 보여준 뒤 종료
        if ~strcmp(winner, 'None')
            WaitSecs(2);
            break;
        end

        % ESC 입력 시 중단
        [pressed, firstPress] = KbQueueCheck;
        if pressed && firstPress(KbName('ESCAPE'))
            winner = 'Aborted';
            break;
        end

        % 다음 화면 전환까지 dt(0.25초) 대기 후, 휴식 중인 타원의 남은 휴식 시간 차감
        WaitSecs(dt);
        restLeft = max(0, restLeft - dt);
    end

    % 파일 맨 아래에 최종 경기 결과와 총 이동 거리를 기록하고 닫기
    fprintf(fileID, '\nResult,%s\nRed Total,%d\nBlue Total,%d\n', winner, totalDist(1), totalDist(2));
    fclose(fileID);

    KbQueueRelease;
    sca;
    ShowCursor;
    disp('Experiment successfully finished');

catch info
    fclose('all');
    KbQueueRelease;
    sca;
    ShowCursor;
    rethrow(info);
end
