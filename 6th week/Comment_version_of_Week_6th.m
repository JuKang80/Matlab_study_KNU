%% 1. 빨간 타원과 파란 타원의 랜덤 이동 경주
% 화면이 전환될 때마다 랜덤한 거리만큼 오른쪽으로 이동한다.
% 먼저 도착 지점에 도달한 타원이 승리한다.
% 선택 문제 1: 화면 중간 지점에서 5초 휴식
% 선택 문제 2: 현재 이동 거리와 누적 이동 거리 표시
% 경기 결과와 이동 기록을 CSV 파일로 저장

% 기본설정1
clear;
clc;
close all;
sca;

% 기본설정2
Screen('Preference', 'SkipSyncTests', 1);
PsychDefaultSetup(2);

try
    screens = Screen('Screens');
    screenNumber = max(screens);

    white = WhiteIndex(screenNumber);
    black = BlackIndex(screenNumber);
    gray = white / 2;

    redColor = [255 0 0];
    blueColor = [0 0 255];

    [window, windowRect] = Screen('OpenWindow', screenNumber, gray);
    Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');

    Screen('TextSize', window, 24);

    % 화면 크기 설정
    screenWidth = windowRect(3);
    screenHeight = windowRect(4);

    % 타원 크기 설정
    ovalWidth = 50;
    ovalHeight = 35;

    % 출발 지점과 도착 지점 설정
    startX = 50;
    finishX = screenWidth - 80;

    % 화면 중간 지점
    middleX = screenWidth / 2;

    % 빨간 타원과 파란 타원의 Y 좌표
    redY = screenHeight * 0.35;
    blueY = screenHeight * 0.65;

    % 타원의 중심 좌표 초기화
    redX = startX + ovalWidth / 2;
    blueX = startX + ovalWidth / 2;

    % 랜덤 이동 거리 범위
    minStep = 1;
    maxStep = 10;

    % 누적 이동 거리
    redTotal = 0;
    blueTotal = 0;

    % 현재 이동 거리
    redCurrent = 0;
    blueCurrent = 0;

    % 휴식 시간 설정
    restDuration = 5;

    % 휴식 종료 시각
    redRestUntil = 0;
    blueRestUntil = 0;

    % 중간 지점 통과 여부
    redRested = false;
    blueRested = false;

    % 경기 결과
    winner = 'None';

    % 프레임 번호 및 시작 시간
    frame = 0;
    startTime = GetSecs;

    % 기록 저장용 배열
    % 1: 프레임
    % 2: 경과 시간
    % 3: 빨간 타원 위치
    % 4: 파란 타원 위치
    % 5: 빨간 타원 현재 이동 거리
    % 6: 파란 타원 현재 이동 거리
    % 7: 빨간 타원 누적 이동 거리
    % 8: 파란 타원 누적 이동 거리
    % 9: 빨간 타원 남은 휴식 시간
    % 10: 파란 타원 남은 휴식 시간

    movementData = zeros(0, 10);

    % 키보드 입력 설정
    KbQueueCreate;
    KbQueueStart;

    % 경주 시작
    while true

        frame = frame + 1;

        currentTime = GetSecs;
        elapsedTime = currentTime - startTime;

        % 현재 프레임 이동 거리 초기화
        redCurrent = 0;
        blueCurrent = 0;

        % 빨간 타원 이동
        if redX < finishX && currentTime >= redRestUntil

            % 휴식이 끝났으면 휴식 상태 해제
            redRestUntil = 0;

            % 랜덤한 거리만큼 이동
            redCurrent = randi([minStep, maxStep]);

            % 도착 지점을 넘어가지 않도록 제한
            redCurrent = min(redCurrent, finishX - redX);

            redX = redX + redCurrent;
            redTotal = redTotal + redCurrent;

            % 중간 지점을 처음 통과하면 5초 휴식
            if redX >= middleX && ~redRested
                redRestUntil = GetSecs + restDuration;
                redRested = true;
            end
        end

        % 파란 타원 이동
        if blueX < finishX && currentTime >= blueRestUntil

            % 휴식이 끝났으면 휴식 상태 해제
            blueRestUntil = 0;

            % 랜덤한 거리만큼 이동
            blueCurrent = randi([minStep, maxStep]);

            % 도착 지점을 넘어가지 않도록 제한
            blueCurrent = min(blueCurrent, finishX - blueX);

            blueX = blueX + blueCurrent;
            blueTotal = blueTotal + blueCurrent;

            % 중간 지점을 처음 통과하면 5초 휴식
            if blueX >= middleX && ~blueRested
                blueRestUntil = GetSecs + restDuration;
                blueRested = true;
            end
        end

        % 남은 휴식 시간 계산
        redRestRemaining = max(0, redRestUntil - GetSecs);
        blueRestRemaining = max(0, blueRestUntil - GetSecs);

        % 승리 조건 확인
        if redX >= finishX && blueX >= finishX
            winner = 'Draw';
        elseif redX >= finishX
            winner = 'Red Win';
        elseif blueX >= finishX
            winner = 'Blue Win';
        end

        % 화면 그리기
        Screen('FillRect', window, gray);

        % 출발선과 도착선
        Screen('DrawLine', window, white, ...
            startX, 50, startX, screenHeight - 50, 2);

        Screen('DrawLine', window, white, ...
            finishX, 50, finishX, screenHeight - 50, 2);

        % 중간 지점
        Screen('DrawLine', window, white, ...
            middleX, 50, middleX, screenHeight - 50, 1);

        % 빨간 타원
        redRect = [ ...
            redX - ovalWidth/2, ...
            redY - ovalHeight/2, ...
            redX + ovalWidth/2, ...
            redY + ovalHeight/2];

        Screen('FillOval', window, redColor, redRect);

        % 파란 타원
        blueRect = [ ...
            blueX - ovalWidth/2, ...
            blueY - ovalHeight/2, ...
            blueX + ovalWidth/2, ...
            blueY + ovalHeight/2];

        Screen('FillOval', window, blueColor, blueRect);

        % 이동 거리 표시
        redText = sprintf( ...
            'Red Total: %.0f pixel, Current: %.0f pixel', ...
            redTotal, redCurrent);

        blueText = sprintf( ...
            'Blue Total: %.0f pixel, Current: %.0f pixel', ...
            blueTotal, blueCurrent);

        DrawFormattedText(window, redText, ...
            'center', redY - 60, redColor);

        DrawFormattedText(window, blueText, ...
            'center', blueY - 60, blueColor);

        % 휴식 타이머 표시
        if redRestRemaining > 0
            restText = sprintf('Red Rest: %.1f sec', redRestRemaining);

            DrawFormattedText(window, restText, ...
                'center', redY + 40, white);
        end

        if blueRestRemaining > 0
            restText = sprintf('Blue Rest: %.1f sec', blueRestRemaining);

            DrawFormattedText(window, restText, ...
                'center', blueY + 40, white);
        end

        % 경과 시간 표시
        timeText = sprintf('Time: %.1f sec', elapsedTime);

        DrawFormattedText(window, timeText, ...
            50, 30, white);

        % 경기 결과 표시
        if ~strcmp(winner, 'None')
            DrawFormattedText(window, winner, ...
                'center', 'center', white);
        end

        % 화면 업데이트
        Screen('Flip', window);

        % 이동 기록 저장
        movementData(end+1, :) = [ ...
            frame, ...
            elapsedTime, ...
            redX, ...
            blueX, ...
            redCurrent, ...
            blueCurrent, ...
            redTotal, ...
            blueTotal, ...
            redRestRemaining, ...
            blueRestRemaining];

        % 승자가 결정되면 종료
        if ~strcmp(winner, 'None')
            WaitSecs(2);
            break;
        end

        % ESC 입력 확인
        [pressed, firstPress] = KbQueueCheck;

        if pressed && firstPress(KbName('ESCAPE'))
            winner = 'Aborted';
            break;
        end

        % 다음 화면 업데이트까지 대기
        WaitSecs(0.05);
    end

    % 키보드 큐 종료
    KbQueueRelease;

    % 화면 종료
    sca;
    ShowCursor;

    %% 결과 파일 저장

    % 파일 이름 설정
    timestamp = datestr(now, 'yyyymmdd_HHMMSS');
    filename = ['RaceResult_' timestamp '.csv'];

    % 이동 기록을 테이블로 변환
    movementTable = array2table(movementData, ...
        'VariableNames', { ...
        'Frame', ...
        'ElapsedTime', ...
        'RedPosition', ...
        'BluePosition', ...
        'RedCurrentDistance', ...
        'BlueCurrentDistance', ...
        'RedTotalDistance', ...
        'BlueTotalDistance', ...
        'RedRestRemaining', ...
        'BlueRestRemaining'});

    % 이동 기록 저장
    writetable(movementTable, filename);

    % 경기 결과 저장
    resultFilename = ['RaceSummary_' timestamp '.txt'];

    fileID = fopen(resultFilename, 'w');

    fprintf(fileID, 'Race Result: %s\n', winner);
    fprintf(fileID, 'Red Total Distance: %.0f pixels\n', redTotal);
    fprintf(fileID, 'Blue Total Distance: %.0f pixels\n', blueTotal);
    fprintf(fileID, 'Elapsed Time: %.2f seconds\n', ...
        GetSecs - startTime);

    fclose(fileID);

    % 명령 창에 결과 출력
    fprintf('\n===== Race Result =====\n');
    fprintf('Winner: %s\n', winner);
    fprintf('Red Total Distance: %.0f pixels\n', redTotal);
    fprintf('Blue Total Distance: %.0f pixels\n', blueTotal);
    fprintf('CSV file: %s\n', filename);
    fprintf('Summary file: %s\n', resultFilename);

    disp('Experiment successfully finished');

catch info

    KbQueueRelease;
    sca;
    ShowCursor;

    rethrow(info);

end