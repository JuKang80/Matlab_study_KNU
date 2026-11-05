%% =========================================================================
% [과제 목표]
% 1. 화면이 전환될 때마다 왼쪽에서 오른쪽으로 랜덤 거리를 이동하는 빨강/파랑 타원 그리기
% 2. 엑셀/메모장에 경기 결과와 각 타원의 이동 거리 기록하기
% [선택 1] 중간선 통과 시 5초 휴식 부여 및 남은 휴식 시간 타이머 표시
% [선택 2] 두 타원의 이동 거리(총합, 현재) 화면 표시
%
% [코드 설계 철학: MATLAB다운 벡터화(Vectorization)]
% C/Python처럼 타원마다 for 루프나 if문을 쓰지 않고, 
% 모든 데이터를 [1열: 빨간 타원, 2열: 파란 타원] 형태의 '1x2 행벡터'로 묶어
% 행렬 단위로 한 번에 연산하고 그리는 구조를 학습합니다.
% =========================================================================

%% [Part 1] 기본 환경 초기화 및 Psychtoolbox(PTB) 창 설정
clear;          % Workspace 메모리의 모든 변수 제거 (이전 실행 잔여 데이터 방지)
clc;            % Command Window 콘솔 기록 청소
close all;      % 일반 MATLAB Figure 그래프 창 모두 닫기
sca;            % Screen('CloseAll') 축약어: 열려 있는 PTB 그래픽 창 강제 닫기

% 스터디/실습 환경에서 빠른 창 생성을 위해 화면 주사율 동기화 테스트 생략
Screen('Preference', 'SkipSyncTests', 1); 

% PTB 기본 환경 초기화 (운영체제 간 일관된 키보드 명칭 UnifyKeyNames 자동 적용)
PsychDefaultSetup(1);                      

try
    % ---------------------------------------------------------------------
    % 1-1. 모니터 번호 및 색상 인덱스
    % ---------------------------------------------------------------------
    screens = Screen('Screens');          % 연결된 디스플레이 번호 목록 (예: [0, 1])
    screenNumber = max(screens);          % 듀얼 모니터 환경이면 확장 화면(최댓값), 단일이면 기본화면(0)
    white = WhiteIndex(screenNumber);     % 모니터 최대 밝기 흰색 (스칼라: 255)
    black = BlackIndex(screenNumber);     % 모니터 최소 밝기 검은색 (스칼라: 0)
    gray = white / 2;                     % 배경용 중간 회색 (스칼라: 127.5)

    % ---------------------------------------------------------------------
    % 1-2. PTB 창 생성 및 그래픽 옵션
    % ---------------------------------------------------------------------
    % [window, windowRect] 반환값:
    % - window: 생성된 그래픽 도화지(윈도우)의 식별 번호 (정수 핸들)
    % - windowRect: [left, top, right, bottom] 형태의 1x4 좌표 행벡터
    [window, windowRect] = Screen('OpenWindow', screenNumber, gray); 
    
    % 타원 테두리의 계단 현상(Anti-aliasing)을 제거하기 위한 알파 블렌딩 활성화
    Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA'); 
    
    % 화면에 출력할 텍스트 폰트 기본 크기 (24pt)
    Screen('TextSize', window, 24);       

    % ---------------------------------------------------------------------
    % 1-3. 해상도 좌표 및 경기장 기준선 (X 좌표)
    % ---------------------------------------------------------------------
    screenWidth = windowRect(3);          % windowRect(3): 화면 가로 전체 픽셀 폭
    screenHeight = windowRect(4);         % windowRect(4): 화면 세로 전체 픽셀 높이
    
    startX = 50;                          % 출발선 X 좌표 (화면 왼쪽 끝 0에서 50px 오른쪽)
    middleX = screenWidth / 2;            % 중간 휴식선 X 좌표 (화면 가로 길이의 정중앙)
    finishX = screenWidth - 80;           % 도착선 X 좌표 (화면 오른쪽 끝에서 80px 왼쪽 안쪽)

    %% [Part 2] 타원 속성 및 경주 상태 변수 (행렬 구조의 핵심!)
    ovalWidth = 50;                       % 타원의 가로 지름 (픽셀)
    ovalHeight = 35;                      % 타원의 세로 지름 (픽셀, 가로!=세로 -> 타원 형성)

    % ---------------------------------------------------------------------
    % [행렬 연산 1] 색상 행렬 전치(Transpose)와 수평 결합(Horizontal Concatenation)
    % ---------------------------------------------------------------------
    redColor = [255, 0, 0];               % 1x3 행벡터: [R, G, B]
    blueColor = [0, 0, 255];              % 1x3 행벡터: [R, G, B]
    
    % redColor'는 3x1 열벡터가 됩니다.
    % 이를 가로로 나란히 결합 [redColor', blueColor'] 하면 '3행 2열(3x2)' 행렬이 생성됩니다.
    % 
    %  ovalColor = [ 255     0 ]  <- Red 값
    %              [   0     0 ]  <- Green 값
    %              [   0   255 ]  <- Blue 값
    %               (1열)  (2열)
    %               빨강   파랑
    % 
    % PTB의 Screen('FillOval')은 열마다 각 도형의 색상을 매핑하므로 3x2 행렬을 그대로 입력받습니다.
    ovalColor = [redColor', blueColor']; 

    % ---------------------------------------------------------------------
    % [행렬 연산 2] 스칼라배를 이용한 Y 좌표 벡터 생성
    % ---------------------------------------------------------------------
    % 스칼라(screenHeight) * 1x2 행벡터([0.35, 0.65]) 
    % = 1x2 행벡터: [상단 35% Y좌표, 하단 65% Y좌표]
    positionY = screenHeight * [0.35, 0.65];

    % ---------------------------------------------------------------------
    % [행렬 연산 3] 상태 변수들을 1x2 행벡터로 통일 (1열: Red, 2열: Blue)
    % ---------------------------------------------------------------------
    totalDistant = [0, 0];                % 각 타원의 누적 이동 거리 (1x2 행벡터)
    currDistant = [0, 0];                 % 이번 스텝에 이동한 거리 (1x2 행벡터)
    restLeft = [0, 0];                    % 남은 휴식 시간(초 단위, 1x2 행벡터)
    hasRested = [false, false];           % 5초 휴식을 거쳤는지 여부 (1x2 논리형(logical) 벡터)

    % ---------------------------------------------------------------------
    % 2-2. 경기 규칙 및 타이머 상수
    % ---------------------------------------------------------------------
    minStep = 0;                          % 1회 점프 시 최소 이동 거리 (0픽셀: 제자리)
    % 단 한 번에 골인하여 5초 휴식 규칙이 무의미해지는 것을 방지하기 위해 
    % 최대 이동 거리를 전체 트랙의 '절반'으로 제한합니다.
    maxStep = round((finishX - startX - ovalWidth) / 2); 

    restDuration = 5;                     % 중간선 통과 시 부여되는 휴식 시간 (5초)
    dt = 0.5;                             % 화면 갱신 및 타이머 카운트다운 주기 (0.5초)
    moveInterval = 2.0;                   % 타원이 실제로 난수 점프하는 이동 주기 (2.0초)
    currentTime = 0;                      % 경주 시작 후 누적된 경과 시간(초)

    winner = 'None';                      % 승자 상태 문자열 ('None', 'Red Win', 'Blue Win', 'Tie')
    step = 0;                             % 화면 갱신 루프 횟수 카운터
    history = [];                         % 매 스텝 데이터를 수직으로 쌓아나갈 빈 행렬 선언

    % ---------------------------------------------------------------------
    % 2-3. 비동기 키보드 큐 (대기 중에도 ESC 즉각 감지)
    % ---------------------------------------------------------------------
    KbQueueCreate;
    KbQueueStart;

    %% [Part 3] 메인 경주 루프
    while true
        currentTime = currentTime + dt;   % 0.5초마다 타이머 시간 증가 (0.5, 1.0, 1.5, 2.0 ...)

        % -----------------------------------------------------------------
        % [연산 1] 부동소수점 오차를 고려한 이동 타이밍 판정
        % -----------------------------------------------------------------
        % mod(currentTime, 2.0)은 2.0초의 배수일 때 정확히 0이 되어야 하지만,
        % 컴퓨터 2진수 연산 특성상 0.0000000001 같은 미세 오차가 생길 수 있으므로
        % < 0.01 조건문으로 안전하게 매 2초를 감지합니다.
        isMoveTime = (mod(currentTime, moveInterval) < 0.01);

        % -----------------------------------------------------------------
        % [연산 2] 브로드캐스팅 덧셈과 논리 인덱싱(Logical Indexing)
        % -----------------------------------------------------------------
        % startX(스칼라) + totalDistant(1x2 벡터) + ovalWidth(스칼라)
        % 스칼라가 1x2 벡터 크기로 자동 확장(브로드캐스팅)되어 
        % 두 타원의 '오른쪽 앞코 X좌표'를 담은 1x2 행벡터가 나옵니다.
        rightEdge = startX + totalDistant + ovalWidth;

        % 요소별 비교(>=)와 논리곱(&) 연산:
        % - (rightEdge >= middleX): [Red통과여부, Blue통과여부] -> 1x2 logical 벡터
        % - ~hasRested: [Red미경험여부, Blue미경험여부] -> 1x2 logical 벡터
        % - 두 조건을 AND(&)하여 "이번에 처음으로 중간선을 넘은 타원"을 true로 마킹
        startRest = (rightEdge >= middleX) & ~hasRested;

        % 논리 인덱싱(Logical Indexing) 적용:
        % startRest가 [true, false]라면 1열(Red)에만 5초를 대입하고 2열은 그대로 둡니다.
        % if문 없이 단 한 줄로 다중 대상의 상태를 조건부 갱신합니다!
        restLeft(startRest) = restDuration;
        hasRested(startRest) = true;

        % -----------------------------------------------------------------
        % [연산 3] 요소별 곱셈(.*)을 이용한 이동 마스킹(Masking)
        % -----------------------------------------------------------------
        if isMoveTime
            step = step + 1;              % 타원이 실제로 이동하는 스텝 번호(1, 2, 3...) 1 증가

            % 1행 2열 난수 생성: [Red거리, Blue거리]
            randomSteps = randi([minStep, maxStep], 1, 2);

            % (restLeft == 0)은 1x2 논리 벡터:
            % 쉬지 않는 타원은 1, 쉬는 타원은 0을 반환합니다.
            % 행렬 곱(*)이 아닌 '요소별 곱(.*)'을 적용하면:
            % [randomRed, randomBlue] .* [1, 0] = [randomRed, 0]
            % -> 휴식 중인 타원은 거리가 자동으로 0이 되어 제자리 대기하게 됩니다.
            currDistant = randomSteps .* (restLeft == 0);
            
            % 누적 이동 거리(1x2) = 기존 누적(1x2) + 이번 이동(1x2)
            totalDistant = totalDistant + currDistant;

            % -------------------------------------------------------------
            % [연산 7] 실제 이동 주기에만 2차원 행렬(history)에 데이터 누적
            % -------------------------------------------------------------
            % 불필요한 제자리 프레임을 제외하고, 실제 점프한 2초 턴마다
            % history의 step번째 행에 [스텝, 경과시간, 빨강현재, 파랑현재, 빨강총합, 파랑총합] 기록
            history(step, :) = [step, currentTime, currDistant(1), currDistant(2), totalDistant(1), totalDistant(2)];
        else
            % 2초 주기가 아닌 0.5초 갱신 프레임에는 타원이 이동하지 않음
            currDistant = [0, 0];
        end

        % -----------------------------------------------------------------
        % [연산 4] 클램핑(Clamping)을 통한 결승선 초과 방지
        % -----------------------------------------------------------------
        % 타원의 왼쪽 끝 좌표(startX + totalDistant)가 도착선(finishX - ovalWidth)을
        % 넘어가더라도 화면에서는 도착선에 정확히 붙어 멈추도록 min 함수로 최댓값을 고정합니다.
        leftX = min(startX + totalDistant, finishX - ovalWidth);
        rightX = leftX + ovalWidth;

        % -----------------------------------------------------------------
        % [연산 5] 도착선 통과 및 승패 판정
        % -----------------------------------------------------------------
        isFinished = (rightX >= finishX); % 1x2 logical 벡터

        if isFinished(1) && isFinished(2)
            winner = "Tie";               % 두 타원 동시 도달
        elseif isFinished(1)
            winner = 'Red Win';           % 빨간 타원 단독 승리
        elseif isFinished(2)
            winner = 'Blue Win';          % 파란 타원 단독 승리
        end

        % -----------------------------------------------------------------
        % [연산 6] 수직 결합(;)을 통한 4행 2열(4x2) 바운딩 박스(Rect) 행렬 생성
        % -----------------------------------------------------------------
        % Screen('FillRect')로 배경을 회색으로 덮어 이전 잔상을 지웁니다.
        Screen('FillRect', window, gray); 

        % 기준선(출발선, 도착선, 중간선) 그리기
        Screen('DrawLine', window, white, startX, 50, startX, screenHeight - 50, 2);
        Screen('DrawLine', window, white, finishX, 50, finishX, screenHeight - 50, 2);
        Screen('DrawLine', window, white, middleX, 50, middleX, screenHeight - 50, 1);

        % [매트랩 행렬의 백미!]
        % leftX, rightX, positionY - ovalHeight/2, positionY + ovalHeight/2는 
        % 모두 1행 2열(1x2) 크기의 행벡터들입니다.
        % 이를 세미콜론(;)으로 위아래로 쌓으면 '4행 2열(4x2)' 행렬이 완성됩니다:
        %
        %  ovalRects = [ leftX(1)                    leftX(2)                    ]  <- Left
        %              [ positionY(1)-ovalHeight/2   positionY(2)-ovalHeight/2   ]  <- Top
        %              [ rightX(1)                   rightX(2)                   ]  <- Right
        %              [ positionY(1)+ovalHeight/2   positionY(2)+ovalHeight/2   ]  <- Bottom
        %                          (1열: Red 영역)             (2열: Blue 영역)
        %
        % PTB는 이 4x2 좌표 행렬과 앞서 만든 3x2 색상 행렬(ovalColor)을 받아
        % 단 한 번의 C-엔진 호출로 두 타원을 동시에 그립니다!
        ovalRects = [leftX; positionY - ovalHeight/2; rightX; positionY + ovalHeight/2];
        Screen('FillOval', window, ovalColor, ovalRects);

        % -----------------------------------------------------------------
        % 텍스트 렌더링
        % -----------------------------------------------------------------
        % 화면 최상단 중앙에 실시간 누적 경주 타이머 출력
        DrawFormattedText(window, sprintf('Race Timer: %.1f sec (Moves every %.1f sec)', currentTime, moveInterval), 'center', 30, white);

        % [선택 문제2] 각 타원의 트랙 상단에 이동 거리 정보 출력
        redText = sprintf('Red Total: %d pixel, Current: %d pixel', totalDistant(1), currDistant(1));
        blueText = sprintf('Blue Total: %d pixel, Current: %d pixel', totalDistant(2), currDistant(2));
        DrawFormattedText(window, redText, 'center', positionY(1) - 60, redColor);
        DrawFormattedText(window, blueText, 'center', positionY(2) - 60, blueColor);

        % [선택 문제1] 휴식 중인 타원에 대해서만 남은 휴식 시간 타이머 표시
        if restLeft(1) > 0
            DrawFormattedText(window, sprintf('Red Rest: %.1f sec', restLeft(1)), 'center', positionY(1) + 40, white);
        end
        if restLeft(2) > 0
            DrawFormattedText(window, sprintf('Blue Rest: %.1f sec', restLeft(2)), 'center', positionY(2) + 40, white);
        end
        
        % 승자 발생 시 화면 정중앙에 최종 결과 글자 출력
        if ~strcmp(winner, 'None')
            DrawFormattedText(window, winner, 'center', 'center', white);
        end

        % 도화지(Backbuffer)에 그린 모든 내용을 실제 모니터로 송출(Flip)
        Screen('Flip', window); 

        % 승자가 결정되었다면 화면에 2초간 승리 메시지를 유지한 뒤 루프 탈출
        if ~strcmp(winner, 'None')
            WaitSecs(2);
            break;
        end

        % ESC 키를 누르면 즉시 강제 종료 처리
        [pressed, firstPress] = KbQueueCheck;
        if pressed && firstPress(KbName('ESCAPE'))
            winner = 'Aborted';
            break;
        end

        % 0.5초 동안 대기 후 남은 휴식 시간에서 0.5초 차감 (음수가 되지 않도록 max 사용)
        WaitSecs(dt);
        restLeft = max(0, restLeft - dt);
    end

    %% [Part 4] 데이터 테이블화, CSV 파일 저장 및 안전한 종료
    % 1. 수치 행렬(history)을 구조화된 MATLAB Table 데이터형으로 변환
    resultTable = array2table(history, 'VariableNames', {'Step', 'Time_sec', 'RedCurrent', 'BlueCurrent', 'RedTotal', 'BlueTotal'});
    
    % 2. 승자 정보 열 추가:
    % repmat({winner}, 행의개수, 1)을 통해 테이블 높이와 동일한 크기의 문자열 셀형 배열(Cell Array)을 만들어
    % 테이블의 새 열 'Winner'로 결합합니다.
    resultTable.Winner = repmat({winner}, height(resultTable), 1);
    
    % 3. 테이블 데이터를 CSV 파일로 내보내기
    writetable(resultTable, 'race_result.csv');

    % 4. 하드웨어 자원 정상 해제
    KbQueueRelease;
    sca;
    ShowCursor;
    disp('Experiment successfully finished');

catch info
    % 코드 도중 오류 발생 시에도 창이 먹통이 되지 않도록 안전하게 리소스 해제
    fclose('all');
    KbQueueRelease;
    sca;
    ShowCursor;
    rethrow(info); % 콘솔에 실제 발생한 에러 메시지 원문 출력
end
