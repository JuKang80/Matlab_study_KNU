%% =========================================================================
% [Week 6th] 과제 구현 - 1. 타이머 방식 (3초 화면 전환 주기)
% 
% [문제 요구사항 만족]
% 1. 3초 타이머 주기마다 화면이 전환되며 두 타원이 랜덤 거리 이동
% 2. 엑셀/메모장에서 열 수 있는 CSV 파일('race_result_timer.csv')로 결과 기록
% 3. [선택1] 중간 지점 통과 시 5초 휴식 및 남은 휴식 시간 실시간 타이머 표시
% 4. [선택2] 각 타원의 현재 이동 거리 및 누적 총 이동 거리 화면 표시
% 5. 언제든지 ESC 키를 누르면 안전하게 즉시 종료
% =========================================================================

clear;
clc;
close all;
sca;

% 모니터 동기화 검사 건너뛰기 및 기본 설정
Screen('Preference', 'SkipSyncTests', 1);
PsychDefaultSetup(1);

try
    % 1. 화면 및 색상 설정
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

    % 2. 타원 규격 및 색상 (1열: Red, 2열: Blue)
    ovalWidth = 50;
    ovalHeight = 35; % 가로 != 세로 이므로 타원

    redColor = [255, 0, 0];
    blueColor = [0, 0, 255];
    ovalColors = [redColor', blueColor'];

    % 3. 상태 변수 초기화 (1x2 행벡터: [Red, Blue])
    posX = [startX, startX] + ovalWidth / 2;
    posY = screenHeight * [0.35, 0.65];

    totalDist = [0, 0];
    currDist = [0, 0];
    restLeft = [0, 0];          % 남은 5초 휴식 시간
    hasRested = [false, false]; % 5초 휴식 완료 여부

    minStep = 10;
    maxStep = 45;
    stepDuration = 3.0;         % [핵심] 화면 전환 주기: 3초
    restDuration = 5.0;         % 중간 지점 휴식 시간: 5초

    winner = 'None';
    step = 0;

    % 4. CSV 파일 오픈
    fileID = fopen('race_result_timer.csv', 'w');
    fprintf(fileID, 'Step,RedCurrent,BlueCurrent,RedTotal,BlueTotal\n');

    % 5. 키보드 큐 시작 (ESC 감지용)
    KbQueueCreate;
    KbQueueStart;

    % =====================================================================
    % [개선 포인트] 출발선에 정지해 있는 초기 화면을 먼저 모니터에 출력!
    % =====================================================================
    Screen('FillRect', window, gray);
    Screen('DrawLine', window, white, startX, 50, startX, screenHeight - 50, 2);
    Screen('DrawLine', window, white, finishX, 50, finishX, screenHeight - 50, 2);
    Screen('DrawLine', window, white, middleX, 50, middleX, screenHeight - 50, 1);

    ovalRects = [posX - ovalWidth/2; posY - ovalHeight/2; posX + ovalWidth/2; posY + ovalHeight/2];
    Screen('FillOval', window, ovalColors, ovalRects);

    DrawFormattedText(window, 'Ready... Race will start in 3 seconds (ESC to quit)', 'center', screenHeight - 80, white);
    Screen('Flip', window);

    % 출발 전 3초 대기 (대기 중 ESC 체크)
    readyStart = GetSecs;
    while GetSecs - readyStart < stepDuration
        [pressed, firstPress] = KbQueueCheck;
        if pressed && firstPress(KbName('ESCAPE'))
            error('UserAbort');
        end
        WaitSecs(0.05);
    end

    % =====================================================================
    % 메인 경주 루프 (3초 타이머 주기마다 전환)
    % =====================================================================
    while true
        step = step + 1;

        % 1. 이동 및 중간 지점 5초 휴식 처리
        for i = 1:2
            % 중간선 통과 판정 (최초 1회만 휴식 등록)
            if posX(i) >= middleX && ~hasRested(i)
                restLeft(i) = restDuration;
                hasRested(i) = true;
            end

            % 휴식 중인지 여부에 따른 이동 처리
            if restLeft(i) > 0
                currDist(i) = 0; % 휴식 중이므로 이동 거리 0
            else
                currDist(i) = randi([minStep, maxStep]);
                totalDist(i) = totalDist(i) + currDist(i);
                posX(i) = min(posX(i) + currDist(i), finishX - ovalWidth/2);
            end
        end

        % 2. 결승선 통과 판정 (타원 우측 끝 기준)
        isFinished = (posX + ovalWidth/2) >= finishX;
        if isFinished(1) && isFinished(2)
            winner = 'Draw';
        elseif isFinished(1)
            winner = 'Red Win';
        elseif isFinished(2)
            winner = 'Blue Win';
        end

        % 3. CSV 데이터 기록
        fprintf(fileID, '%d,%d,%d,%d,%d\n', step, currDist(1), currDist(2), totalDist(1), totalDist(2));

        % 4. 3초 타이머 카운트다운 루프 (화면 갱신 및 ESC 실시간 감지)
        turnStartTime = GetSecs;
        while true
            elapsed = GetSecs - turnStartTime;
            remainStepTime = max(0, stepDuration - elapsed);

            % 화면 그리기
            Screen('FillRect', window, gray);
            Screen('DrawLine', window, white, startX, 50, startX, screenHeight - 50, 2);
            Screen('DrawLine', window, white, finishX, 50, finishX, screenHeight - 50, 2);
            Screen('DrawLine', window, white, middleX, 50, middleX, screenHeight - 50, 1);

            % 타원 그리기
            ovalRects = [posX - ovalWidth/2; posY - ovalHeight/2; posX + ovalWidth/2; posY + ovalHeight/2];
            Screen('FillOval', window, ovalColors, ovalRects);

            % [선택2] 이동 거리 표시
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

            % 화면 하단 3초 타이머 및 종료 안내
            if strcmp(winner, 'None')
                statusText = sprintf('Next Move In: %.1f sec | ESC to Exit', remainStepTime);
                DrawFormattedText(window, statusText, 'center', screenHeight - 50, white);
            else
                % 승자 발생 시 결과 표시
                DrawFormattedText(window, winner, 'center', 'center', white);
            end

            Screen('Flip', window);

            % 승부가 난 경우 3초간 승리 화면을 유지하고 종료
            if ~strcmp(winner, 'None')
                if elapsed >= 3.0
                    break;
                end
            else
                % 3초가 다 지나면 다음 이동 스텝으로 전환
                if elapsed >= stepDuration
                    break;
                end
            end

            % ESC 입력 시 즉시 루프 탈출
            [pressed, firstPress] = KbQueueCheck;
            if pressed && firstPress(KbName('ESCAPE'))
                winner = 'Aborted';
                break;
            end

            WaitSecs(0.04); % 부드러운 텍스트 갱신을 위해 짧게 대기
        end

        % 휴식 중인 타원의 남은 시간에서 이번 턴 소요 시간(3초) 차감
        restLeft = max(0, restLeft - stepDuration);

        % 승부가 났거나 사용자가 ESC를 눌렀으면 메인 루프 종료
        if ~strcmp(winner, 'None')
            break;
        end
    end

    % 6. 최종 결과 기록 및 종료
    fprintf(fileID, '\nResult,%s\nRed Total,%d\nBlue Total,%d\n', winner, totalDist(1), totalDist(2));
    fclose(fileID);

    KbQueueRelease;
    sca;
    ShowCursor;
    disp(['Experiment Finished. Result: ', winner]);

catch info
    fclose('all');
    KbQueueRelease;
    sca;
    ShowCursor;
    if strcmp(info.message, 'UserAbort')
        disp('Experiment aborted by user (ESC).');
    else
        rethrow(info);
    end
end
