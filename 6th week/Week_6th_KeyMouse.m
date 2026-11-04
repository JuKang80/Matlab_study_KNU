%% =========================================================================
% [Week 6th] 과제 구현 - 2. 키보드('n') 및 마우스 클릭 방식 (상세 주석판)
% 
% [문제 요구사항 만족]
% 1. 키보드 'n' 키를 누르거나 마우스를 클릭할 때마다 화면이 전환되며 타원 이동
% 2. 엑셀/메모장에서 열 수 있는 CSV 파일('race_result_keymouse.csv')로 결과 기록
% 3. [선택1] 중간 지점 통과 시 5초 휴식 (5초 동안은 입력을 받아도 정지 대기)
%    - 남은 휴식 시간 실시간 타이머 표시
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

    % [핵심 설계] 키/마우스 입력 방식에서의 5초 휴식 관리:
    % 사용자가 키를 언제 누를지 예측할 수 없으므로, '현재 시각 + 5초'라는 절대 시각(restEndTime)을 기록합니다.
    % GetSecs가 restEndTime보다 작다면 키를 아무리 눌러도 해당 타원은 대기 상태를 유지합니다!
    restEndTime = [0, 0];                 % 각 타원의 5초 휴식이 끝나는 절대 시각 (초 단위)
    hasRested = [false, false];           % [선택1] 중간선 5초 휴식 완료 여부 플래그

    minStep = 10;                         % 최소 이동 거리 (10px)
    maxStep = 45;                         % 최대 이동 거리 (45px)
    restDuration = 5.0;                   % [선택1] 중간 지점 통과 시 휴식 시간 (5초)

    winner = 'None';                      % 승자 상태 ('None', 'Red Win', 'Blue Win', 'Draw')
    step = 0;                             % 이동 횟수 카운터

    % 4. CSV 파일 오픈 및 열 헤더 기록
    fileID = fopen('race_result_keymouse.csv', 'w');
    fprintf(fileID, 'Step,RedCurrent,BlueCurrent,RedTotal,BlueTotal\n');

    % 5. 비동기 키보드 큐 시작 ('n' 키 및 ESC 키 감지용)
    KbQueueCreate;
    KbQueueStart;

    % 키 코드 미리 조회
    keyN = KbName('n');
    keyESC = KbName('ESCAPE');

    % =====================================================================
    % 메인 경주 루프 시작 (키보드 'n' 또는 마우스 클릭 시마다 1스텝씩 진행)
    % =====================================================================
    while true
        % -----------------------------------------------------------------
        % A. 현재 상태 화면 렌더링 및 사용자 입력('n' 키 / 마우스 클릭) 대기 루프
        % -----------------------------------------------------------------
        inputTriggered = false;

        while ~inputTriggered
            nowSecs = GetSecs; % 현재 절대 시각

            % 1. [선택1] 실시간 남은 휴식 시간(초) 계산: (종료시각 - 현재시각)
            restLeft = max(0, restEndTime - nowSecs);

            % 2. 화면 배경 및 기준선 그리기
            Screen('FillRect', window, gray);
            Screen('DrawLine', window, white, startX, 50, startX, screenHeight - 50, 2);
            Screen('DrawLine', window, white, finishX, 50, finishX, screenHeight - 50, 2);
            Screen('DrawLine', window, white, middleX, 50, middleX, screenHeight - 50, 1);

            % 3. 타원 그리기 (4행 2열 행렬로 일괄 렌더링)
            ovalRects = [posX - ovalWidth/2; posY - ovalHeight/2; posX + ovalWidth/2; posY + ovalHeight/2];
            Screen('FillOval', window, ovalColors, ovalRects);

            % 4. [선택2] 이동 거리 텍스트 표시
            redText = sprintf('Red Total: %d pixel, Current: %d pixel', totalDist(1), currDist(1));
            blueText = sprintf('Blue Total: %d pixel, Current: %d pixel', totalDist(2), currDist(2));
            DrawFormattedText(window, redText, 'center', posY(1) - 60, redColor);
            DrawFormattedText(window, blueText, 'center', posY(2) - 60, blueColor);

            % 5. [선택1] 5초 휴식 카운트다운 타이머 실시간 표시 (소수점 1자리)
            if restLeft(1) > 0
                DrawFormattedText(window, sprintf('Red Rest: %.1f sec', restLeft(1)), 'center', posY(1) + 40, white);
            end
            if restLeft(2) > 0
                DrawFormattedText(window, sprintf('Blue Rest: %.1f sec', restLeft(2)), 'center', posY(2) + 40, white);
            end

            % 6. 안내 텍스트 또는 최종 승자 표시
            if strcmp(winner, 'None')
                guideMsg = 'Press ''n'' or Click Mouse to Move  |  ESC to Exit';
                DrawFormattedText(window, guideMsg, 'center', screenHeight - 50, white);
            else
                % 승자가 결정되었다면 화면 정중앙에 크게 표시
                DrawFormattedText(window, winner, 'center', 'center', white);
            end

            Screen('Flip', window);

            % 만약 이미 승자가 결정된 상태라면 결과를 2.5초간 보여주고 대기 루프 종료
            if ~strcmp(winner, 'None')
                WaitSecs(2.5);
                break;
            end

            % -------------------------------------------------------------
            % 7. 사용자 입력 감지부 (키보드 'n', ESC, 마우스 클릭)
            % -------------------------------------------------------------
            % (1) 키보드 큐 확인
            [pressed, firstPress] = KbQueueCheck;
            if pressed
                if firstPress(keyESC)
                    winner = 'Aborted'; % ESC 누르면 중단
                    break;
                elseif firstPress(keyN)
                    inputTriggered = true; % 'n' 키를 누르면 다음 이동 트리거 활성화
                end
            end

            % (2) 마우스 클릭 확인
            [~, ~, mouseButtons] = GetMouse(window);
            if any(mouseButtons)
                inputTriggered = true; % 마우스 클릭 시 다음 이동 트리거 활성화

                % [중요: 디바운싱(Debouncing)]
                % 마우스 버튼을 누르고 있는 동안 루프가 수백 번 돌며 연타되는 것을 방지합니다.
                % 사용자가 마우스 버튼에서 손을 뗄 때까지 잠시 대기합니다.
                while any(mouseButtons)
                    [~, ~, mouseButtons] = GetMouse(window);
                    WaitSecs(0.01);
                end
            end

            WaitSecs(0.02); % CPU 과부하 방지 (초당 약 50회 검사)
        end

        % 승부가 났거나 사용자가 ESC를 눌렀으면 메인 루프 탈출
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
                currDist(i) = 0; % 5초가 지나지 않았으므로 제자리 대기
            else
                % 5초 휴식이 끝났거나 아직 중간선에 도달하지 않은 경우 정상 이동
                currDist(i) = randi([minStep, maxStep]);
                totalDist(i) = totalDist(i) + currDist(i);
                posX(i) = min(posX(i) + currDist(i), finishX - ovalWidth/2);

                % 이번 이동으로 중간선(middleX)을 처음 통과했다면 지금부터 5초 휴식 시작!
                if posX(i) >= middleX && ~hasRested(i)
                    restEndTime(i) = nowSecs + restDuration; % 지금 시각 + 5.0초를 만료 시각으로 설정
                    hasRested(i) = true;                     % 중복 휴식 방지
                end
            end
        end

        % -----------------------------------------------------------------
        % C. 도착선 판정 (타원 우측 끝 기준)
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

    % 6. 최종 경기 결과 기록 및 파일 닫기
    fprintf(fileID, '\nResult,%s\nRed Total,%d\nBlue Total,%d\n', winner, totalDist(1), totalDist(2));
    fclose(fileID);

    % 정상 종료 자원 해제
    KbQueueRelease;
    sca;
    ShowCursor;
    disp(['Experiment Finished. Result: ', winner]);

catch info
    % 오류 또는 강제 종료 시 안전 해제
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
