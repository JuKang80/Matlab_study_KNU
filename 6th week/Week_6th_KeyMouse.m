%% =========================================================================
% [Week 6th] 과제 구현 - 2. 키보드('n') 및 마우스 클릭 방식
% 
% [문제 요구사항 만족]
% 1. 키보드 'n' 키를 누르거나 마우스를 클릭할 때마다 화면이 전환되며 타원 이동
% 2. 엑셀/메모장에서 열 수 있는 CSV 파일('race_result_keymouse.csv')로 결과 기록
% 3. [선택1] 중간 지점 통과 시 5초 휴식 (5초 동안은 입력을 받아도 정지 대기)
%    - 남은 휴식 시간 실시간 타이머 표시
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
    ovalHeight = 35;

    redColor = [255, 0, 0];
    blueColor = [0, 0, 255];
    ovalColors = [redColor', blueColor'];

    % 3. 상태 변수 초기화 (1x2 행벡터: [Red, Blue])
    posX = [startX, startX] + ovalWidth / 2;
    posY = screenHeight * [0.35, 0.65];

    totalDist = [0, 0];
    currDist = [0, 0];
    restEndTime = [0, 0];       % 각 타원의 5초 휴식이 끝나는 절대 시각 (GetSecs 기준)
    hasRested = [false, false]; % 5초 휴식 완료 여부

    minStep = 10;
    maxStep = 45;
    restDuration = 5.0;         % 중간 지점 휴식 시간: 5초

    winner = 'None';
    step = 0;

    % 4. CSV 파일 오픈
    fileID = fopen('race_result_keymouse.csv', 'w');
    fprintf(fileID, 'Step,RedCurrent,BlueCurrent,RedTotal,BlueTotal\n');

    % 5. 키보드 큐 시작 (n 키 및 ESC 감지용)
    KbQueueCreate;
    KbQueueStart;

    % 키 코드 미리 정의
    keyN = KbName('n');
    keyESC = KbName('ESCAPE');

    % =====================================================================
    % 메인 경주 루프 (키보드 'n' 또는 마우스 클릭 시마다 1스텝씩 진행)
    % =====================================================================
    while true
        % -----------------------------------------------------------------
        % A. 현재 상태 화면 렌더링 및 사용자 입력(키보드 'n' / 마우스 클릭) 대기
        % -----------------------------------------------------------------
        inputTriggered = false;

        while ~inputTriggered
            nowSecs = GetSecs;

            % 1. 남은 휴식 시간(초) 실시간 계산
            restLeft = max(0, restEndTime - nowSecs);

            % 2. 화면 배경 및 기준선 그리기
            Screen('FillRect', window, gray);
            Screen('DrawLine', window, white, startX, 50, startX, screenHeight - 50, 2);
            Screen('DrawLine', window, white, finishX, 50, finishX, screenHeight - 50, 2);
            Screen('DrawLine', window, white, middleX, 50, middleX, screenHeight - 50, 1);

            % 3. 타원 그리기
            ovalRects = [posX - ovalWidth/2; posY - ovalHeight/2; posX + ovalWidth/2; posY + ovalHeight/2];
            Screen('FillOval', window, ovalColors, ovalRects);

            % 4. [선택2] 이동 거리 텍스트 표시
            redText = sprintf('Red Total: %d pixel, Current: %d pixel', totalDist(1), currDist(1));
            blueText = sprintf('Blue Total: %d pixel, Current: %d pixel', totalDist(2), currDist(2));
            DrawFormattedText(window, redText, 'center', posY(1) - 60, redColor);
            DrawFormattedText(window, blueText, 'center', posY(2) - 60, blueColor);

            % 5. [선택1] 5초 휴식 카운트다운 타이머 표시
            if restLeft(1) > 0
                DrawFormattedText(window, sprintf('Red Rest: %.1f sec', restLeft(1)), 'center', posY(1) + 40, white);
            end
            if restLeft(2) > 0
                DrawFormattedText(window, sprintf('Blue Rest: %.1f sec', restLeft(2)), 'center', posY(2) + 40, white);
            end

            % 6. 안내 텍스트 또는 승자 표시
            if strcmp(winner, 'None')
                guideMsg = 'Press ''n'' or Click Mouse to Move  |  ESC to Exit';
                DrawFormattedText(window, guideMsg, 'center', screenHeight - 50, white);
            else
                DrawFormattedText(window, winner, 'center', 'center', white);
            end

            Screen('Flip', window);

            % 만약 이미 승자가 결정되었다면 결과를 보여주고 종료
            if ~strcmp(winner, 'None')
                WaitSecs(2.5);
                break;
            end

            % -------------------------------------------------------------
            % 7. 사용자 입력 검사 (키보드 'n', ESC, 마우스 클릭)
            % -------------------------------------------------------------
            % (1) 키보드 검사
            [pressed, firstPress] = KbQueueCheck;
            if pressed
                if firstPress(keyESC)
                    winner = 'Aborted';
                    break;
                elseif firstPress(keyN)
                    inputTriggered = true;
                end
            end

            % (2) 마우스 검사
            [~, ~, mouseButtons] = GetMouse(window);
            if any(mouseButtons)
                inputTriggered = true;
                % 마우스를 누르고 있을 때 중복 입력 방지 (마우스 버튼 뗄 때까지 대기)
                while any(mouseButtons)
                    [~, ~, mouseButtons] = GetMouse(window);
                    WaitSecs(0.01);
                end
            end

            WaitSecs(0.02); % CPU 과점유 방지
        end

        % 승부가 났거나 ESC로 중단되었으면 메인 루프 탈출
        if ~strcmp(winner, 'None')
            break;
        end

        % -----------------------------------------------------------------
        % B. 입력 발생 시 타원 이동 처리 및 중간 지점 휴식 판정
        % -----------------------------------------------------------------
        step = step + 1;
        nowSecs = GetSecs;

        for i = 1:2
            % 타원이 아직 5초 휴식 시간 내에 있다면 이동 불가
            if nowSecs < restEndTime(i)
                currDist(i) = 0; % 정지
            else
                % 휴식이 끝났거나 휴식 대상이 아니면 정상 랜덤 이동
                currDist(i) = randi([minStep, maxStep]);
                totalDist(i) = totalDist(i) + currDist(i);
                posX(i) = min(posX(i) + currDist(i), finishX - ovalWidth/2);

                % 이번 이동으로 중간선(middleX)을 처음 통과했다면 5초 휴식 시작!
                if posX(i) >= middleX && ~hasRested(i)
                    restEndTime(i) = nowSecs + restDuration; % 지금부터 5초 뒤까지 휴식
                    hasRested(i) = true;
                end
            end
        end

        % -----------------------------------------------------------------
        % C. 도착선 판정
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
        % D. CSV 파일에 스텝 기록
        % -----------------------------------------------------------------
        fprintf(fileID, '%d,%d,%d,%d,%d\n', step, currDist(1), currDist(2), totalDist(1), totalDist(2));
    end

    % 6. 최종 결과 기록 및 안전 종료
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
