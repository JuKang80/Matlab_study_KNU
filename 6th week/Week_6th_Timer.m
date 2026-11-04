%% =========================================================================
% [Week 6th] 과제 구현 - 1. 타이머 방식 (3초 화면 전환 주기) (상세 주석판)
% 
% [문제 요구사항 만족]
% 1. 3초 타이머 주기마다 화면이 전환되며 두 타원이 랜덤 거리 이동
% 2. 엑셀/메모장에서 열 수 있는 CSV 파일('race_result_timer.csv')로 결과 기록
% 3. [선택1] 중간 지점 통과 시 5초 휴식 및 남은 휴식 시간 실시간 타이머 표시
% 4. [선택2] 각 타원의 현재 이동 거리 및 누적 총 이동 거리 화면 표시
% 5. 언제든지 ESC 키를 누르면 안전하게 즉시 종료
% =========================================================================

% [기본설정 1] 이전 실행의 메모리 잔여물과 열려있는 창들을 깨끗하게 초기화합니다.
clear;          % 작업 공간(Workspace) 메모리에 남아있는 모든 변수를 삭제합니다.
clc;            % 명령창(Command Window)의 텍스트 로그를 모두 지웁니다.
close all;      % 일반 MATLAB Figure 창이 열려 있다면 모두 닫습니다.
sca;            % Screen('CloseAll')의 약자로, 열려 있는 Psychtoolbox(PTB) 화면을 모두 닫습니다.

% [기본설정 2] Psychtoolbox 실행 환경 설정
Screen('Preference', 'SkipSyncTests', 1); % 모니터 주사율 동기화 오차로 인한 오류를 건너뜁니다.
PsychDefaultSetup(1);                      % 키보드 이름 체계(KbName) 통합 및 기본 OpenGL 설정을 켭니다.

try
    % 1. 화면 및 기준 색상 설정
    screens = Screen('Screens');          % 현재 PC의 모니터 목록 배열을 가져옵니다.
    screenNumber = max(screens);          % 보조 모니터 또는 기본 모니터를 선택합니다.
    white = WhiteIndex(screenNumber);     % 흰색 값 (255)
    black = BlackIndex(screenNumber);     % 검은색 값 (0)
    gray = white / 2;                     % 배경색으로 사용할 중간 회색 (127.5)

    % 실험 창 열기 및 텍스트/투명도 옵션 설정
    [window, windowRect] = Screen('OpenWindow', screenNumber, gray);
    Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA'); % 안티앨리어싱
    Screen('TextSize', window, 24);       % 글자 기본 크기 24pt

    screenWidth = windowRect(3);          % 화면 가로 픽셀 폭
    screenHeight = windowRect(4);         % 화면 세로 픽셀 폭

    startX = 50;                          % 출발선 X좌표
    middleX = screenWidth / 2;            % 중간 휴식 기준선 X좌표 (화면 가로 중앙)
    finishX = screenWidth - 80;           % 결승선 X좌표

    % 2. 타원 규격 및 색상 (1열: Red, 2열: Blue)
    ovalWidth = 50;                       % 타원의 가로 직경
    ovalHeight = 35;                      % 타원의 세로 직경 (가로 != 세로 이므로 완전한 타원)

    redColor = [255, 0, 0];               % 빨간색 RGB 벡터
    blueColor = [0, 0, 255];              % 파란색 RGB 벡터
    ovalColors = [redColor', blueColor']; % 3행 2열 [R; G; B] 색상 행렬

    % 3. 상태 변수 초기화 (1x2 행벡터: [Red, Blue])
    posX = [startX, startX] + ovalWidth / 2; % 출발선에 타원 왼쪽 끝이 닿도록 중심 좌표 지정
    posY = screenHeight * [0.35, 0.65];   % 상단(35%)과 하단(65%) 트랙 분리 배치

    totalDist = [0, 0];                   % [선택2] 누적 이동 거리
    currDist = [0, 0];                    % [선택2] 현재 스텝 이동 거리
    restLeft = [0, 0];                    % [선택1] 남은 5초 휴식 시간
    hasRested = [false, false];           % [선택1] 중간선 5초 휴식 완료 여부 플래그

    minStep = 10;                         % 최소 이동 거리 (10px)
    maxStep = 45;                         % 최대 이동 거리 (45px)
    stepDuration = 3.0;                   % [핵심 요구사항] 화면 전환 주기 (3초 타이머)
    restDuration = 5.0;                   % [선택1] 중간 지점 통과 시 휴식 시간 (5초)

    winner = 'None';                      % 승자 상태 ('None', 'Red Win', 'Blue Win', 'Draw')
    step = 0;                             % 화면 전환 스텝 카운터

    % 4. CSV 파일 오픈 및 열 헤더 기록
    fileID = fopen('race_result_timer.csv', 'w');
    fprintf(fileID, 'Step,RedCurrent,BlueCurrent,RedTotal,BlueTotal\n');

    % 5. 비동기 키보드 큐 시작 (대기 중 ESC 입력을 빠짐없이 감지하기 위해 필수)
    KbQueueCreate;
    KbQueueStart;

    % =====================================================================
    % [출발 준비 화면] 출발선에 정지해 있는 초기 상태를 모니터에 먼저 출력!
    % =====================================================================
    Screen('FillRect', window, gray);
    Screen('DrawLine', window, white, startX, 50, startX, screenHeight - 50, 2);
    Screen('DrawLine', window, white, finishX, 50, finishX, screenHeight - 50, 2);
    Screen('DrawLine', window, white, middleX, 50, middleX, screenHeight - 50, 1);

    % 타원 4x2 좌표 행렬 계산 및 일괄 그리기
    ovalRects = [posX - ovalWidth/2; posY - ovalHeight/2; posX + ovalWidth/2; posY + ovalHeight/2];
    Screen('FillOval', window, ovalColors, ovalRects);

    DrawFormattedText(window, 'Ready... Race will start in 3 seconds (ESC to quit)', 'center', screenHeight - 80, white);
    Screen('Flip', window);

    % 출발 전 3초 동안 준비 대기 (대기 루프를 0.05초 단위로 쪼개어 ESC 키를 실시간 감지)
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

        % 1. 두 타원(i=1: Red, i=2: Blue)의 휴식 및 이동 판정
        for i = 1:2
            % 중간선 도달 판정 (처음 넘었을 때 1회만 5초 휴식 등록)
            if posX(i) >= middleX && ~hasRested(i)
                restLeft(i) = restDuration; % 5초 등록
                hasRested(i) = true;        % 재등록 방지
            end

            % 휴식 중인지 여부에 따른 이동 처리
            if restLeft(i) > 0
                currDist(i) = 0; % 휴식 중인 타원은 이번 3초 턴에서 이동 거리 0 (제자리 대기)
            else
                currDist(i) = randi([minStep, maxStep]); % 10~45 난수 생성
                totalDist(i) = totalDist(i) + currDist(i);
                posX(i) = min(posX(i) + currDist(i), finishX - ovalWidth/2); % 결승선 고정
            end
        end

        % 2. 결승선 통과 판정 (타원의 오른쪽 끝 'posX + ovalWidth/2' 기준)
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

        % -----------------------------------------------------------------
        % 4. [타이머 핵심 메커니즘] 3초 카운트다운 루프
        % WaitSecs(3.0)으로 통째로 쉬어버리면 숫자가 줄어드는 타이머를 화면에 갱신할 수 없고
        % 대기 중에 ESC 키를 눌러도 프로그램이 멍때리게 됩니다.
        % 따라서 내부에서 짧은 주기(0.04초)로 돌며 타이머 텍스트를 실시간으로 갱신합니다!
        % -----------------------------------------------------------------
        turnStartTime = GetSecs; % 이번 3초 턴이 시작된 절대 시각
        while true
            elapsed = GetSecs - turnStartTime;                % 턴 시작 후 흐른 시간(초)
            remainStepTime = max(0, stepDuration - elapsed);  % 다음 이동까지 남은 시간(초)

            % 화면 배경 및 기준선 그리기
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

            % [선택1] 5초 휴식 남은 시간 실시간 표시 (소수점 1자리)
            if restLeft(1) > 0
                DrawFormattedText(window, sprintf('Red Rest: %.1f sec', restLeft(1)), 'center', posY(1) + 40, white);
            end
            if restLeft(2) > 0
                DrawFormattedText(window, sprintf('Blue Rest: %.1f sec', restLeft(2)), 'center', posY(2) + 40, white);
            end

            % 화면 하단 3초 타이머 카운트다운 및 종료 안내 표시
            if strcmp(winner, 'None')
                statusText = sprintf('Next Move In: %.1f sec | ESC to Exit', remainStepTime);
                DrawFormattedText(window, statusText, 'center', screenHeight - 50, white);
            else
                % 승자 발생 시 결과 문구 표시
                DrawFormattedText(window, winner, 'center', 'center', white);
            end

            % 백버퍼의 그래픽을 모니터에 출력
            Screen('Flip', window);

            % 승부가 난 경우 결과 화면을 3초간 보여주고 탈출
            if ~strcmp(winner, 'None')
                if elapsed >= 3.0
                    break;
                end
            else
                % 정해진 3초 타이머가 다 지나면 다음 이동 스텝으로 전환하기 위해 탈출
                if elapsed >= stepDuration
                    break;
                end
            end

            % 대기 시간 도중 ESC 키가 눌렸다면 즉시 비상 탈출
            [pressed, firstPress] = KbQueueCheck;
            if pressed && firstPress(KbName('ESCAPE'))
                winner = 'Aborted';
                break;
            end

            WaitSecs(0.04); % 모니터 갱신과 CPU 낭비 방지를 위해 40ms 단위로 루프 회전
        end

        % 이번 3초 턴이 끝났으므로, 휴식 중인 타원의 남은 시간에서 3초를 차감합니다.
        restLeft = max(0, restLeft - stepDuration);

        % 승부가 났거나 사용자가 ESC를 눌렀으면 메인 경주 루프 완전 종료
        if ~strcmp(winner, 'None')
            break;
        end
    end

    % 6. 최종 경기 결과 기록 및 파일 닫기
    fprintf(fileID, '\nResult,%s\nRed Total,%d\nBlue Total,%d\n', winner, totalDist(1), totalDist(2));
    fclose(fileID);

    % 정상 종료 자원 해제
    KbQueueRelease;
    sca;
    ShowCursor;
    disp(['Experiment Finished. Result: ', winner]);

catch info
    % 오류 또는 강제 종료(ESC) 발생 시 자원을 안전하게 반환
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
