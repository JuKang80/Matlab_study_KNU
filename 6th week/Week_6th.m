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

    redColor = [255, 0, 0]; % 빨간색을 정의했다.
    blueColor = [0, 0, 255]; % 파란색을 정의했다.
    ovalColor = [redColor', blueColor']; % Screen('FillOval')에 한번에 넣기 위해 각 색상을 세로(열벡터)로 세워 3행 2열 행렬로 묶었다. 

    positionY = screenHeight * [0.35, 0.65]; % 빨간 타원은 Y좌표(높이) 35%만큼 위치하고, 파란 타원은 65% 높이만큼 위치하기 위한 벡터이다. 
    % 각각 Y좌표를 구할 수 있다. 그래서, positionY(1)는 빨간 타원 Y 좌표, positionY(2)는 파란 타원 Y 좌표이다. 

    totalDistant = [0, 0]; % 각 타원의 누적 이동거리
    currDistant = [0, 0]; % 각 타원별 스텝당 이동한 거리
    restLeft = [0, 0]; % 남은 휴식시간 
    hasRested = [false, false]; % 5초 휴식을 거쳤는지 여부(논리형임) 

    % 한번 이동 시 극단적으로 많이 이동하게 만들었다. 만약 더 느리게 나아가게 하고 싶다면 나누는 값을 3,4,5, ..로 바꾸면 된다. 
    minStep = 0; % 1회 점프 시 최소 이동 거리
    maxStep = round((finishX - startX - ovalWidth) / 2); % 최대 이동 거리를 전체 길이의 절반으로 설정했다. 

    restDuration = 5; % 중간 지점 통과 시 부여할 휴식시간 5초이다. 
    dt = 0.5; % 화면 전환 간 대기 시간 (0.5초)
    moveInterval = 2.0; % 타원이 실제로 이동하는 주기 (2초)
    currentTime = 0; % 경과 시간 타이머 
    
    winner = 'None'; % 우승자가 전해지기 전까지 None으로 문자열을 설정한다. (가능한 문자열: None, Red Win, Blue Win, Tie)
    step = 0; % 몇 번째 화면 전환(스텝)인지 세는 변수이다. 
    
    history = []; % 매 스텝의 기록을 수직으로 쌓아두기 위한 빈 배열 선언

    % 큐 방식으로 esc 눌러 탈출가능하게 하였다.  
    KbQueueCreate;
    KbQueueStart; % 키보드 입력을 받기 위한 설정 

    %% 메인 경주 루프 
    while true
        currentTime = currentTime + dt; % 타이머. 0.5초마다 타이머 시간 증가
        % dt가 0.5이다. 루프돌때 마다 0.5초씩 증가한다. 

        % 타원이 움직일 타이밍인지 판단 (2초 주기)
        isMoveTime = (mod(currentTime, moveInterval) < 0.01);
        % mod(A, B)는 A를 B로 나눈 나머지를 구하는 함수이다. 
        % moveInterval이 2초이므로, currentTime이 2의 배수가 될 때 나머지가 0이된다. 
        % 컴퓨터 계산의 미세한 오차를 위해 ==0보다 <0.01을 사용했다. 
        % 결론적으로 isMoveTime은 타이머가 2의 배수를 가리키고 있으면 True, 아니면 false를 담는다. 

        % 중앙을 넘었는지 체크하는 부분 
        rightEdge = startX + totalDistant + ovalWidth; % 타원의 오른쪽 부분을 구한다. 
        startRest = (rightEdge >= middleX) & ~hasRested;
        % 두 가지 조건을 한번에 검사한다. 
        % 1) (rightEdge >= milldeX)로 타원 제일 오른쪽 부분이 중간선을 넘었는지, 
        % 2) ~는 반대, NOT으로 hasRested가 아닌지 판단한다. 
        % 그래서 startRest에 값이 [true, false] 등 논리값으로 들어갔다. 

        restLeft(startRest) = restDuration; 
        % 5초만큼 쉬라고 하는데, true인 원에게만 5초를 부여한다. 
        hasRested(startRest) = true; 
        % 그리고 휴식을 가진 적이 있다고 hasRested를 true로 바꾸어준다. 그래서 다음에 또 휴식을 가지는걸 방지한다. 

        if isMoveTime % isMoveTime이 2의 배수가 되면 true가 되어, 이 안의 코드를 읽게 된다. 
            step = step + 1; % 실제 이동 스텝 번호를 1씩 증가시킨다.
            randomSteps = randi([minStep, maxStep], 1, 2); % 랜덤한 수 두개를 뽑는다. 
            currDistant = randomSteps .* (restLeft == 0); % 쉬고 있는 것에는 0을 부여하고 곱하더라도 0이 나와 움직이지 않게 하였다. 
            totalDistant = totalDistant + currDistant; % 전체 거리는 전체 거리 + 현재 거리를 했다. 

            % 실제 이동한 주기에만 데이터 기록하기
            history(step, :) = [step, currentTime, currDistant(1), currDistant(2), totalDistant(1), totalDistant(2)];
            % history에 기록을 남겼다. step번째 가로줄에, 이 숫자들을 순서대로 적게 했다.
        else
            currDistant = [0, 0]; % 2초 주기가 아닐때는 이동 거리는 0이 되게 하였다. 
        end

        leftX = min(startX + totalDistant, finishX - ovalWidth); % 타원이 도착선을 뚫지 않게했다. 
        % min을 통해 최소값을 선택하게 했다. 
        rightX = leftX + ovalWidth; % 타원의 앞쪽을 기록했다. 

        isFinished = (rightX >= finishX); % 타원의 앞쪽이 도착선을 넘었는지 판단하게 했다. 
        % 빨강만 들어오면 true, false
        % 파랑만 들어오면 false, true

        if isFinished(1) && isFinished(2) % 둘다 true일 경우 이 안으로 들어가 판단한다. 
            winner = "Tie"; % 둘다 이겼으면 tie
        elseif isFinished(1)
            winner = 'Red Win'; % 1, red가 이겼으면 red win
        elseif isFinished(2)
            winner = 'Blue Win'; % 2, blue가 이겼으면 blue win 
        end

        % 버퍼에 그리기 
        Screen('FillRect', window, gray); % 다시 스크린 그린다. 

        % 출발선, 도착선, 중간선 그리기 
        Screen('DrawLine', window, white, startX, 50, startX, screenHeight - 50, 2); % 출발선은 그린다. 
        Screen('DrawLine', window, white, finishX, 50, finishX, screenHeight - 50, 2); % 도착선을 그린다. 
        Screen('DrawLine', window, white, middleX, 50, middleX, screenHeight - 50, 1); % 중간선을 그린다. 
        
        % 두 타원의 좌표 [왼쪽X; 위쪽Y; 오른쪽X; 아래쪽Y]를 4행 2열 행렬로 묶어 한 번에 그린다. 
        ovalRects = [leftX; positionY - ovalHeight/2; rightX; positionY + ovalHeight/2];
        % 4행 2열로 만들어서 빨강과 파랑을 한번에 넣었다. 
        Screen('FillOval', window, ovalColor, ovalRects); % 그걸 그렸다. 

        % 화면 상단 중앙에 전체 경주 타이머 표시
        DrawFormattedText(window, sprintf('Race Timer: %.1f sec (Moves every %.1f sec)', currentTime, moveInterval), 'center', 30, white);
        

        redText = sprintf('Red Total: %d pixel, Current: %d pixel', totalDistant(1), currDistant(1));
        blueText = sprintf('Blue Total: %d pixel, Current: %d pixel', totalDistant(2), currDistant(2));
        DrawFormattedText(window, redText, 'center', positionY(1) - 60, redColor); % positionY는 중심 위치인데, -60을 하면 바로 위에 글씨가 나온다. 
        DrawFormattedText(window, blueText, 'center', positionY(2) - 60, blueColor); 

        % 2. [선택 문제1] 휴식 중인 타원의 남은 휴식 시간 표시
        if restLeft(1) > 0 % 휴식 중인지 확인한다. 
            DrawFormattedText(window, sprintf('Red Rest: %.1f sec', restLeft(1)), 'center', positionY(1) + 40, white);
            % + 40을 하여 아래쪽에 나타나게 했다. 
        end
        if restLeft(2) > 0 % 휴식시간이 0이 아니면 휴식중이므로 이 if문에 들어오게 했다. 
            DrawFormattedText(window, sprintf('Blue Rest: %.1f sec', restLeft(2)), 'center', positionY(2) + 40, white);
        end
        
        % 3. 승자가 결정되었다면 화면 정중앙에 결과 표시
        if ~strcmp(winner, 'None') % 두 글자가 같은지 검사를 한다. ~는 not이란 뜻이다. 즉, winner가 None이 아닌 상태라면 이 안에 들어가게 된다. 
            DrawFormattedText(window, winner, 'center', 'center', white); % 화면 중앙에 나타나게 해준다. 
        end

        % 지금까지 그린 요소를 화면으로 전환 
        Screen('Flip', window); 

        % 승자 결정 시 결과 보여주기 
        if ~strcmp(winner, 'None') % winner가 None이 아니라면 글자를 2초 동안 보여주고 루프를 탈출하게 해준다. 
            WaitSecs(2);
            break;
        end

        % ESC로 강제 종료 확인 
        [pressed, firstPress] = KbQueueCheck;
        if pressed && firstPress(KbName('ESCAPE')) % esc가 눌러지면 탈출하게 된다. 
            winner = 'Aborted';
            break;
        end

        % 다음 화면 전환까지 dt 대기 후 남은 휴식 시간 차감 
        WaitSecs(dt); % 중간에 시간 안주면 바로 끝나서 0.5(dt)만큼 더 기다리게 했다. 
        restLeft = max(0, restLeft - dt); % 타원의 남은 휴식 시간도 dt만큼 깍이게 했다. 
        % 여기서 왜 max(0, ..)을 했느냐, 음수 방지를 위해서이다. 계산되었을때 음수가 안나오게 했다.
    end

    resultTable = array2table(history, 'VariableNames', {'Step', 'Time_sec', 'RedCurrent', 'BlueCurrent', 'RedTotal', 'BlueTotal'});
    % history는 지금까지 모은 데이터가 있다. (숫자만 있음)
    % array2table은 이 숫자에 열 제목을 달아준다. 
    resultTable.Winner = repmat({winner}, height(resultTable), 1);
    % 표 제일 오른쪽에 우승자 열을 추가한다. 
    % 중괄호({})를 사용하여 글자를 하나로 묶어주었다. 
    % resultTable.Winner로 새 열을 만들고, repmat을 통해 winner의 칸에 복사하여 넣어준다. 
    % 즉, winner 글자를 세로로 몇번, 가로로 몇줄 복사할건지 명령을 내린다.
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