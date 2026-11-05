%% 1. 화면이 전환될 때마다 왼쪽에서 오른쪽으로 랜덤한 거리를 이동하는 빨간 타원과 파란 타원을 그리세요. 화면 전환 방식은 타이머, 키보드 입력, 마우스 입력 등 자유롭게 설정하세요. 오른쪽 맨 끝 혹은 임의의 도착 지점에 한 타원이 도달하면 'Red Win'과 같이 결과를 글자로 띄우세요.

%% 2. 엑셀 또는 메모장에 경기 결과와 각 타원의 이동 거리를 저장하세요.

% [선택 문제1] 한 타원이 화면 중간지점을 통과하면 5초 휴식 후 이동하게 만들어보세요. 남은 휴식 시간의 타이머를 보여주세요.

% [선택 문제2] 두 타원이 이동한 거리를 화면에 띄우세요.
% ex) red 총합: 300pixel, 현재: 5pixel

%% ======================
% 기본 설정 1
clear;
clc;
close all;
sca;

% 기본 설정 2
Screen('Preferences', 'SkipSyncTests', 1);
PsychDefaultSetup(1);
%% =======================

try
    % 모니터 번호와 기본 색상값을 정의한다. 
    screens = Screen('Screens');
    screenNumber = max(screens);
    white = WhiteIndex(screenNumber);
    black = BlackIndex(screenNumber);
    gray = white / 2;

    % 실험 화면 창을 열고 텍스트 및 투명도 옵션을 설정한다. 
    [window, windowRect] = Screen('OpenWindow', screenNumber, gray);
    Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA'); % 알파블렌딩
    Screen('TextSize', window, 24); % 화면에 출력할 글자의 기본 크기를 24포인트로 설정

    % 화면 가로/세로 해상도를 추출하고 기준선의 X 좌표를 구한다. 
    screenWidth = windowRect(3); % 화면 전체 가로 픽셀 값 가져옴 
    screenHeight = windowRect(4); % 화면 전체 세로 픽셀 값 가져옴

    startX = 50; % 출발선은 화면 왼쪽 끝에서 50픽셀 떨어진 지점으로 설정
    middleX = screenWidth / 2; % 휴식 기준은 X 좌표 가로의 절반으로 구했다. 
    finishX = screenWidth - 80; % 도착선은 화면 오른쪽 끝에서 80픽셀만큼 들어간 곳으로 설정했다. 

    ovalWidth = 50; % 타원의 가로 길이를 50픽셀로 설정했다. 
    ovalHeight = 35; % 타원의 세로 길이를 35픽셀로 지정했다. 
    % 여기서 가로와 세로가 달라야 타원이기에 이렇게 설정했다. 

    redColor = [255, 0, 0]; 
    blueColor = [0, 0, 255];
    ovalColor = [redColor', blueColor']; % Screen('FillOval')에 한번에 넣기 위해 각 색상을 세로(열벡터)로 세워 3행 2열 행렬로 묶었다. 

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

    KbQueueCreate;
    KbQueueStart; % 키보드 입력을 받기 위한 설정 

    %% 메인 경주 루프 
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
