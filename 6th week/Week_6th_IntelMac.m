%% =========================================================================
% [Week 6th] 인텔 맥 (Intel Mac / macOS Ventura) 호환성 특화 버전
% 
% [인텔 맥 및 macOS Ventura 환경 주요 해결 과제]
% 1. VBL 동기화(SyncTests) 실패로 인한 강제 중단 방지 (SkipSyncTests=2)
% 2. macOS Ventura 텍스트 렌더러(FreeType) 충돌로 인한 매트랩 크래시 방지 (TextRenderer=0)
% 3. macOS WindowServer 전체 화면 전환 시 먹통/검은 화면 방지 (안전 창 모드 옵션)
% 4. Intel 내장 그래픽 VRAM 관리 및 경고 생략 (ConserveVRAM=64, VisualDebugLevel=1)
% =========================================================================

%% [Part 1] 기본 환경 초기화 및 인텔 맥 호환성 특화 설정
clear;
clc;
close all;
sca;

% -------------------------------------------------------------------------
% ★ [Intel Mac / macOS Ventura 필수 호환성 세팅 4종 세트]
% -------------------------------------------------------------------------
% 1. 주사율 동기화 검사 완전 비활성화 (레벨 2: 모든 VBL 동기화 오류/경고 무시)
Screen('Preference', 'SkipSyncTests', 2); 

% 2. 텍스트 렌더러 크래시 방지 (macOS Ventura에서 DrawFormattedText 시 MATLAB 강제 종료 방지)
%    0으로 설정하면 외부 FreeType 라이브러리 대신 macOS 기본 그래픽스 엔진을 사용합니다.
Screen('Preference', 'TextRenderer', 0); 
Screen('Preference', 'TextAntiAliasing', 1);

% 3. 시작 시 깜빡이는 PTB 로고/시각 진단 화면 생략 및 불필요한 경고 억제
Screen('Preference', 'VisualDebugLevel', 1);
Screen('Preference', 'SuppressAllWarnings', 1);

% 4. Intel 내장 그래픽(HD/Iris) 및 macOS WindowServer VRAM 충돌 방지 플래그
Screen('Preference', 'ConserveVRAM', 64);

% PTB 기본 환경 초기화 (키보드 명칭 통일)
PsychDefaultSetup(1);                      

try
    % ---------------------------------------------------------------------
    % 1-1. 모니터 번호 및 기본 색상 정의
    % ---------------------------------------------------------------------
    screens = Screen('Screens');
    screenNumber = max(screens);          % 단일 맥북이면 0번 모니터 선택
    white = WhiteIndex(screenNumber);
    black = BlackIndex(screenNumber);
    gray = white / 2;

    % ---------------------------------------------------------------------
    % 1-2. 실험 창 열기 (인텔 맥 전체 화면 멈춤 방지 옵션)
    % ---------------------------------------------------------------------
    % macOS Ventura에서는 전체 화면 독점 시 화면이 검게 멈추는 현상이 잦습니다.
    % 안정적인 테스트를 위해 창 모드(1280x800)를 기본 활성화해 두었습니다.
    % (전체 화면으로 돌리시려면 아래 useWindowedMode를 false로 바꾸시면 됩니다.)
    useWindowedMode = true; 

    if useWindowedMode
        % 안전한 1280x800 크기의 일반 윈도우 창으로 열기 (디버깅/실습 최적)
        [window, windowRect] = Screen('OpenWindow', screenNumber, gray, [0, 0, 1280, 800]);
    else
        % 전체 화면으로 열기
        [window, windowRect] = Screen('OpenWindow', screenNumber, gray);
    end

    Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA'); % 알파블렌딩
    Screen('TextSize', window, 24); % 화면에 출력할 글자의 기본 크기를 24포인트로 설정

    % ---------------------------------------------------------------------
    % 1-3. 화면 가로/세로 해상도를 추출하고 기준선의 X 좌표를 구한다.
    % ---------------------------------------------------------------------
    screenWidth = windowRect(3); % 화면 전체 가로 픽셀 값 가져옴 
    screenHeight = windowRect(4); % 화면 전체 세로 픽셀 값 가져옴

    startX = 50; % 출발선은 화면 왼쪽 끝에서 50픽셀 떨어진 지점으로 설정
    middleX = screenWidth / 2; % 휴식 기준은 X 좌표 가로의 절반으로 구했다. 
    finishX = screenWidth - 80; % 도착선은 화면 오른쪽 끝에서 80픽셀만큼 들어간 곳으로 설정했다. 

    % ---------------------------------------------------------------------
    % [Part 2] 타원 속성 및 경주 상태 변수
    % ---------------------------------------------------------------------
    ovalWidth = 50; % 타원의 가로 길이를 50픽셀로 설정했다. 
    ovalHeight = 35; % 타원의 세로 길이를 35픽셀로 지정했다. 

    redColor = [255, 0, 0]; 
    blueColor = [0, 0, 255];
    ovalColor = [redColor', blueColor']; % 3x2 색상 행렬

    positionY = screenHeight * [0.35, 0.65];

    totalDistant = [0, 0];
    currDistant = [0, 0];
    restLeft = [0, 0];
    hasRested = [false, false];

    minStep = 0; 
    maxStep = round((finishX - startX - ovalWidth) / 2);

    restDuration = 5; % 중간 지점 통과 시 부여할 휴식시간 5초이다. 
    dt = 0.5; % 화면 전환 간 대기 시간 (초)
    moveInterval = 2.0; % 타원이 실제로 이동하는 주기 (초)
    currentTime = 0; % 경과 시간 타이머 (초)
    
    winner = 'None'; % 우승자가 전해지기 전까지 None으로 문자열을 설정한다. 
    step = 0; % 몇 번째 화면 전환(스텝)인지 세는 변수이다. 
    
    history = []; % 매 스텝의 기록을 쌓아두기 위한 빈 배열 선언

    % ---------------------------------------------------------------------
    % 2-3. 키보드 큐 시작
    % ※ macOS 주의: '시스템 설정 > 개인정보 보호 및 보안 > 손쉬운 사용 / 입력 모니터링'에
    %    MATLAB이 체크(허용)되어 있어야 키보드가 정상 감지됩니다.
    % ---------------------------------------------------------------------
    KbQueueCreate;
    KbQueueStart;

    %% [Part 3] 메인 경주 루프 
    while true
        currentTime = currentTime + dt; % 타이머 시간 갱신

        % 타원이 움직일 타이밍인지 판단 (2초 주기)
        isMoveTime = (mod(currentTime, moveInterval) < 0.01);

        % 중앙을 넘었는지 체크하는 부분 
        rightEdge = startX + totalDistant + ovalWidth;
        startRest = (rightEdge >= middleX) & ~hasRested;
        
        restLeft(startRest) = restDuration;
        hasRested(startRest) = true;

        if isMoveTime
            step = step + 1; % 실제 이동 스텝 번호를 1씩 증가시킨다.
            randomSteps = randi([minStep, maxStep], 1, 2);
            currDistant = randomSteps .* (restLeft == 0);
            totalDistant = totalDistant + currDistant;

            % 실제 이동한 주기에만 데이터 기록하기
            history(step, :) = [step, currentTime, currDistant(1), currDistant(2), totalDistant(1), totalDistant(2)];
        else
            currDistant = [0, 0];
        end

        leftX = min(startX + totalDistant, finishX - ovalWidth);
        rightX = leftX + ovalWidth;

        isFinished = (rightX >= finishX);

        if isFinished(1) && isFinished(2)
            winner = "Tie";
        elseif isFinished(1)
            winner = 'Red Win';
        elseif isFinished(2)
            winner = 'Blue Win'; 
        end

        % 버퍼에 그리기 
        Screen('FillRect', window, gray); 

        % 출발선, 도착선, 중간선 그리기 
        Screen('DrawLine', window, white, startX, 50, startX, screenHeight - 50, 2);
        Screen('DrawLine', window, white, finishX, 50, finishX, screenHeight - 50, 2);
        Screen('DrawLine', window, white, middleX, 50, middleX, screenHeight - 50, 1);
        
        % 두 타원의 좌표 [왼쪽X; 위쪽Y; 오른쪽X; 아래쪽Y]를 4행 2열 행렬로 묶어 한 번에 그린다. 
        ovalRects = [leftX; positionY - ovalHeight/2; rightX; positionY + ovalHeight/2];
        Screen('FillOval', window, ovalColor, ovalRects);

        % 화면 상단 중앙에 전체 경주 타이머 표시
        DrawFormattedText(window, sprintf('Race Timer: %.1f sec (Moves every %.1f sec)', currentTime, moveInterval), 'center', 30, white);

        redText = sprintf('Red Total: %d pixel, Current: %d pixel', totalDistant(1), currDistant(1));
        blueText = sprintf('Blue Total: %d pixel, Current: %d pixel', totalDistant(2), currDistant(2));
        DrawFormattedText(window, redText, 'center', positionY(1) - 60, redColor);
        DrawFormattedText(window, blueText, 'center', positionY(2) - 60, blueColor);

        % 2. [선택 문제1] 휴식 중인 타원의 남은 휴식 시간 표시
        if restLeft(1) > 0
            DrawFormattedText(window, sprintf('Red Rest: %.1f sec', restLeft(1)), 'center', positionY(1) + 40, white);
        end
        if restLeft(2) > 0
            DrawFormattedText(window, sprintf('Blue Rest: %.1f sec', restLeft(2)), 'center', positionY(2) + 40, white);
        end
        
        % 3. 승자가 결정되었다면 화면 정중앙에 결과 표시
        if ~strcmp(winner, 'None')
            DrawFormattedText(window, winner, 'center', 'center', white);
        end

        % 지금까지 그린 요소를 화면으로 전환 
        Screen('Flip', window); 

        % 승자 결정 시 결과 보여주기 
        if ~strcmp(winner, 'None')
            WaitSecs(2);
            break;
        end

        % ESC로 강제 종료 확인 
        [pressed, firstPress] = KbQueueCheck;
        if pressed && firstPress(KbName('ESCAPE'))
            winner = 'Aborted';
            break;
        end

        % 다음 화면 전환까지 dt 대기 후 남은 휴식 시간 차감 
        WaitSecs(dt);
        restLeft = max(0, restLeft - dt);
    end

    %% [Part 4] 데이터 저장 및 종료
    resultTable = array2table(history, 'VariableNames', {'Step', 'Time_sec', 'RedCurrent', 'BlueCurrent', 'RedTotal', 'BlueTotal'});
    resultTable.Winner = repmat({winner}, height(resultTable), 1);
    writetable(resultTable, 'race_result.csv');

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
