%% 1. 화면이 전환될 때마다 왼쪽에서 오른쪽으로 랜덤한 거리를 이동하는 빨간 타원과 파란 타원을 그리세요. 화면 전환 방식은 타이머, 키보드 입력, 마우스 입력 등 자유롭게 설정하세요. 오른쪽 맨 끝 혹은 임의의 도착 지점에 한 타원이 도달하면 'Red Win'과 같이 결과를 글자로 띄우세요.

%% 2. 엑셀 또는 메모장에 경기 결과와 각 타원의 이동 거리를 저장하세요.

% [선택 문제1] 한 타원이 화면 중간지점을 통과하면 5초 휴식 후 이동하게 만들어보세요. 남은 휴식 시간의 타이머를 보여주세요.

% [선택 문제2] 두 타원이 이동한 거리를 화면에 띄우세요.
% ex) red 총합: 300pixel, 현재: 5pixel

% =========================================================================
% [학습용 실습 파일]
% 주요 구현 로직이 [빈칸 1] ~ [빈칸 11]로 비워져 있습니다.
% 각 빈칸의 힌트를 참고하여 직접 코드를 채워 넣으며 실습해보세요!
% (정답 확인 및 참고: Comment_version_of_Week_6th.m)
% =========================================================================

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

    % ---------------------------------------------------------------------
    % [빈칸 1] 결과 저장용 CSV 파일 열기 및 헤더(컬럼명) 작성
    % 힌트: fopen을 'w'(쓰기 모드)로 열고, fprintf로 'Step,RedCurrent,...' 헤더 작성
    % ---------------------------------------------------------------------
    % fileID = ________________________________________;
    % fprintf(________________________________________);

    % 키보드 입력 큐 시작
    KbQueueCreate;
    KbQueueStart;

    % 메인 경주 루프
    while true
        step = step + 1;

        % -----------------------------------------------------------------
        % 1. 두 타원(1: Red, 2: Blue)의 휴식 및 랜덤 이동 처리
        % -----------------------------------------------------------------
        for i = 1:2
            % -------------------------------------------------------------
            % [빈칸 2] 중간 지점(middleX) 통과 판정 및 5초 휴식 시작
            % 힌트: 타원 위치(posX(i))가 중간지점 이상이고, 아직 휴식한 적이 없다면(~hasRested(i))
            %       restLeft(i)에 restDuration(5초)을 넣고, hasRested(i)를 true로 변경
            % -------------------------------------------------------------
            % if ________________________________________
            %     restLeft(i) = ________________;
            %     hasRested(i) = _______________;
            % end

            % -------------------------------------------------------------
            % [빈칸 3] 휴식 및 이동 거리 계산
            % 힌트: restLeft(i)가 0보다 크면 currDist(i)는 0 (제자리 대기)
            %       그렇지 않다면 randi([minStep, maxStep])로 랜덤 이동 거리 생성 후
            %       totalDist와 posX를 누적 갱신 (단, posX는 finishX를 넘지 않도록 min 처리)
            % -------------------------------------------------------------
            % if restLeft(i) > 0
            %     currDist(i) = ____;
            % else
            %     currDist(i) = ________________________;
            %     totalDist(i) = ________________________;
            %     posX(i) = ________________________;
            % end
        end

        % -----------------------------------------------------------------
        % [빈칸 4] 2. 도착선(finishX) 통과 판정 (승자 결정)
        % 힌트: 타원의 오른쪽 끝(posX + ovalWidth/2)이 finishX 이상인지 비교
        %       둘 다 도착 시 'Draw', Red 도착 시 'Red Win', Blue 도착 시 'Blue Win'
        % -----------------------------------------------------------------
        % isFinished = ________________________________________;
        % if isFinished(1) && isFinished(2)
        %     winner = 'Draw';
        % elseif isFinished(1)
        %     winner = ____________;
        % elseif isFinished(2)
        %     winner = ____________;
        % end

        % -----------------------------------------------------------------
        % 3. 화면 그리기 (배경, 기준선, 두 타원, 텍스트)
        % -----------------------------------------------------------------
        Screen('FillRect', window, gray);

        % 기준선 그리기 (출발선, 도착선, 중간선)
        Screen('DrawLine', window, white, startX, 50, startX, screenHeight - 50, 2);
        Screen('DrawLine', window, white, finishX, 50, finishX, screenHeight - 50, 2);
        Screen('DrawLine', window, white, middleX, 50, middleX, screenHeight - 50, 1);

        % -----------------------------------------------------------------
        % [빈칸 5] 4행 2열 타원 좌표 행렬(ovalRects) 생성 및 타원 그리기
        % 힌트: [왼쪽; 위; 오른쪽; 아래] 형식으로 2개 타원의 좌표 행렬 구성 후
        %       Screen('FillOval', window, ovalColors, ovalRects) 호출
        % -----------------------------------------------------------------
        % ovalRects = [____________________________________________________];
        % Screen('FillOval', ______________________________________________);

        % -----------------------------------------------------------------
        % [빈칸 6] 누적 및 현재 이동 거리 화면에 텍스트로 띄우기
        % 힌트: sprintf를 사용해 텍스트 포맷을 만들고, DrawFormattedText로 출력
        % -----------------------------------------------------------------
        % redText = sprintf('Red Total: %d pixel, Current: %d pixel', totalDist(1), currDist(1));
        % blueText = sprintf('Blue Total: %d pixel, Current: %d pixel', totalDist(2), currDist(2));
        % DrawFormattedText(_______________________________________________);
        % DrawFormattedText(_______________________________________________);

        % -----------------------------------------------------------------
        % [빈칸 7] 남은 휴식 시간 타이머 화면에 표시
        % 힌트: restLeft(1) > 0 일 때와 restLeft(2) > 0 일 때 각각 DrawFormattedText 출력
        % -----------------------------------------------------------------
        % if restLeft(1) > 0
        %     DrawFormattedText(window, sprintf('Red Rest: %.1f sec', restLeft(1)), 'center', posY(1) + 40, white);
        % end
        % if restLeft(2) > 0
        %     DrawFormattedText(___________________________________________);
        % end

        % 승리 결과 표시
        if ~strcmp(winner, 'None')
            DrawFormattedText(window, winner, 'center', 'center', white);
        end

        % -----------------------------------------------------------------
        % [빈칸 8] 백버퍼에 그린 화면을 실제 모니터에 출력(Flip)
        % 힌트: Screen('Flip', ...)
        % -----------------------------------------------------------------
        % Screen(________, ________);

        % -----------------------------------------------------------------
        % [빈칸 9] 현재 스텝의 이동 데이터를 CSV 파일에 한 줄 기록
        % 힌트: fprintf(fileID, '%d,%d,%d,%d,%d\n', step, ...)
        % -----------------------------------------------------------------
        % fprintf(fileID, _________________________________________________);

        % 승자가 결정되면 2초간 결과를 보여준 뒤 루프 종료
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

        % -----------------------------------------------------------------
        % [빈칸 10] 화면 전환 주기 대기 및 남은 휴식 시간 차감
        % 힌트: WaitSecs(dt)로 대기하고, restLeft에서 dt를 뺀 값을 max(0, ...) 처리
        % -----------------------------------------------------------------
        % WaitSecs(____);
        % restLeft = max(0, ________________);
    end

    % ---------------------------------------------------------------------
    % [빈칸 11] 최종 경기 결과 및 총 이동 거리 기록 후 파일 닫기
    % 힌트: fprintf로 최종 요약 정보를 기록하고 fclose(fileID) 호출
    % ---------------------------------------------------------------------
    % fprintf(fileID, '\nResult,%s\nRed Total,%d\nBlue Total,%d\n', winner, totalDist(1), totalDist(2));
    % fclose(________);

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
