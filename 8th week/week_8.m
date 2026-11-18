% =========================================================================
% [week_8.m 학습용 질문 가이드]
% 각 줄(또는 블록) 위에 달린 '% [Q]' 질문을 보면서,
% "이 코드가 왜 여기에 있고, 정확히 어떤 역할을 하는지" 내 말로 설명해 보세요!
% =========================================================================

% [Q] clear, clc, close all, sca 네 가지 명령어는 각각 무엇을 지우거나 닫는 역할을 하나요?
%     실험 시작 맨 앞에 이 4가지를 두는 이유는 무엇인가요?
clear;
clc;
close all;
sca;

% [Q] 아래 6줄의 Screen('Preference', ...) 설정은 왜 필요한가요?
%     특히 SkipSyncTests=2, TextRenderer=0, ConserveVRAM=64 는 어떤 환경을 대비한 것인가요?
Screen('Preference', 'SkipSyncTests', 2);
Screen('Preference', 'TextRenderer', 0);
Screen('Preference', 'TextAntiAliasing', 1);
Screen('Preference', 'VisualDebugLevel', 1);
Screen('Preference', 'SuppressAllWarnings', 1);
Screen('Preference', 'ConserveVRAM', 64);

% [Q] PsychDefaultSetup(1)은 어떤 기능을 수행하나요? 인자 1 대신 2를 넣으면 무엇이 달라지나요?
PsychDefaultSetup(1);

% [Q] 전체 실험 코드를 try ... catch 블록으로 감싸는 가장 큰 이유는 무엇인가요?
try
    % [Q] Screen('Screens')는 어떤 값을 반환하며, 왜 max(screens)를 사용하나요?
    screens = Screen('Screens');
    screenNumber = max(screens);
    % [Q] WhiteIndex, BlackIndex를 직접 255, 0으로 쓰지 않고 함수로 구하는 이유는 무엇인가요?
    white = WhiteIndex(screenNumber);
    black = BlackIndex(screenNumber);
    gray = white / 2;

    % [Q] useWindowedMode 변수를 true/false로 나누어 분기한 이유는 무엇인가요?
    useWindowedMode = true;

    if useWindowedMode
        % [Q] [0, 0, 1280, 800] 네 숫자는 각각 무엇을 의미하나요?
        %     OpenWindow가 반환하는 window와 windowRect는 각각 어떤 값인가요?
        [window, windowRect] = Screen('OpenWindow', screenNumber, gray, [0, 0, 1280, 800]);
    else
        [window, windowRect] = Screen('OpenWindow', screenNumber, gray);
    end

    % [Q] BlendFunction을 설정하지 않으면 아래 targetFillColor의 4번째 값(알파)은 어떻게 되나요?
    Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');
    % [Q] Screen('TextSize', window, 24)는 이후 어떤 함수의 글자 크기에 영향을 주나요?
    Screen('TextSize', window, 24);

    % [Q] windowRect(3)과 windowRect(4)가 각각 가로, 세로 해상도가 되는 이유는 무엇인가요?
    screenWidth = windowRect(3);
    screenHeight = windowRect(4);
    % [Q] RectCenter(windowRect)는 어떤 좌표를 계산해 주나요?
    [centerX, centerY] = RectCenter(windowRect);

    % [Q] totalTrials와 restTrials를 분리해서 변수로 선언한 이유는 무엇인가요?
    %     만약 totalTrials를 7(홀수)로 바꾸면 restTrials는 어떤 값이 되고, 어떤 문제가 생길 수 있나요?
    totalTrials = 10;
    restTrials = totalTrials / 2;

    % [Q] KbName('space')처럼 키 이름을 숫자(키 코드)로 미리 변환해 두는 이유는 무엇인가요?
    leftKey = KbName('LeftArrow');
    rightKey = KbName('RightArrow');
    upKey = KbName('UpArrow');
    downKey = KbName('DownArrow');
    spaceKey = KbName('space');
    escKey = KbName('ESCAPE');

    % [Q] TriSize, TrimoveSpeed, TriColor는 각각 삼각형의 어떤 속성을 결정하나요?
    TriSize = 60;
    TrimoveSpeed = 8;
    TriColor = [255, 255, 255];

    % [Q] targetFillColor와 targetBorderColor의 4번째 숫자(80 vs 255)는 각각 어떤 효과를 내나요?
    targetFillColor = [0, 220, 120, 80];
    targetBorderColor = [0, 220, 120, 255];
    targetWidth = 180;
    targetHeight = 180;

    % [Q] 일반 숫자 행렬 zeros(totalTrials, 8) 대신 cell(totalTrials, 8)을 사용한 이유는 무엇인가요?
    results = cell(totalTrials, 8);

    % [Q] 이 바깥쪽 for 루프는 한 번 돌 때마다 실험에서 무엇을 의미하나요?
    for trial = 1:totalTrials
        % [Q] 매 시행 시작 시 triX, triY를 고정값으로 초기화하는 이유는 무엇인가요?
        triX = 150;
        triY = centerY;
        % [Q] randi([round(centerX), screenWidth - 150])에서 round와 -150을 해준 이유는 각각 무엇인가요?
        targetX = randi([round(centerX), screenWidth - 150]);
        targetY = centerY;

        % [Q] CenterRectOnPointd([0, 0, targetWidth, targetHeight], targetX, targetY)는
        %     어떤 형태의 4원소 벡터([L, T, R, B])를 만들어 주나요?
        targetRect = CenterRectOnPointd([0, 0, targetWidth, targetHeight], targetX, targetY);

        % [Q] 이 첫 번째 while true 루프의 목적은 무엇이며, 언제 종료되나요?
        while true
            % [Q] triPoints 3x2 행렬의 각 행(1행, 2행, 3행)은 삼각형의 어느 꼭짓점을 가리키나요?
            %     PTB 좌표계에서 Y축(+/-) 방향을 고려해 설명해 보세요.
            triPoints = [triX - TriSize/2, triY - TriSize/2;
                triX - TriSize/2, triY + TriSize/2;
                triX + TriSize/2, triY];

            % [Q] 아래 4개의 Screen 그리기 명령어는 왜 이 순서대로 호출되어야 하나요?
            %     (만약 FillPoly를 FillRect(배경)보다 먼저 그리면 어떻게 되나요?)
            Screen('FillRect', window, gray);
            Screen('FillRect', window, targetFillColor, targetRect);
            Screen('FrameRect', window, targetBorderColor, targetRect, 3);
            Screen('FillPoly', window, TriColor, triPoints);

            % [Q] sprintf('Trial %d/%d', trial, totalTrials)의 %d는 각각 어떤 변수로 채워지나요?
            DrawFormattedText(window, sprintf('Trial %d/%d', trial, totalTrials), 40, 40, white);
            % [Q] Screen('Flip', window)를 호출하기 전까지는 왜 화면에 아무것도 보이지 않나요?
            Screen('Flip', window);

            % [Q] KbCheck의 반환값 3개 중 첫 번째(keyIsDown)와 세 번째(keyCode)는 각각 어떤 자료형인가요?
            %     두 번째 자리에 '~'를 쓴 이유는 무엇인가요?
            [keyIsDown, ~, keyCode] = KbCheck;

            % [Q] min(screenWidth - TriSize/2, triX + TrimoveSpeed)는 어떤 상황을 막기 위한 코드인가요?
            %     또한 현재 코드에서는 왜 오른쪽으로만 이동할 수 있고 왼쪽으로는 돌아가지 못하나요?
            if keyCode(rightKey)
                triX = min(screenWidth - TriSize/2, triX + TrimoveSpeed);
                % [Q] 여기에 KbReleaseWait가 있으면 키를 눌렀을 때 움직임이 어떻게 동작하나요?
                KbReleaseWait;
            end
            if keyCode(spaceKey)
                % [Q] break 직전에 KbReleaseWait를 넣지 않으면 바로 아래 while 루프에 어떤 문제가 생기나요?
                KbReleaseWait;
                % [Q] 이 break는 바깥 for 루프와 안쪽 while 루프 중 어느 것을 빠져나가나요?
                break;
            end
            if keyCode(escKey)
                % [Q] error(...)를 호출하면 실행 흐름이 코드의 어느 부분으로 즉시 점프하나요?
                error('사용자에 의해 중단되었습니다');
            end
        end

        % [Q] IsInRect(triX, triY, targetRect)는 무엇과 무엇을 비교하여 1 또는 0을 반환하나요?
        %     삼각형 전체(triPoints)가 아니라 중심점(triX, triY)만 검사할 때 생길 수 있는 한계는 무엇인가요?
        isInside = IsInRect(triX, triY, targetRect);

        if isInside
            resultText = 'correct';
        else
            resultText = 'wrong';
        end

        % [Q] RestrictKeysForKbCheck([spaceKey, escKey])를 호출하면 키보드 입력이 어떻게 제한되나요?
        RestrictKeysForKbCheck([spaceKey, escKey]);
        % [Q] 이 두 번째 while true 루프의 목적은 무엇인가요?
        while true
            % [Q] 여기서는 배경이나 삼각형을 다시 그리지 않고 resultText만 그렸을 때 화면은 어떻게 보이나요?
            DrawFormattedText(window, resultText, 'center', 'center', white);
            Screen('Flip', window);

            [keyIsDown, ~, keyCode] = KbCheck;
            if keyCode(escKey)
                error('사용자에 의해 중단되었습니다');
            end
            if keyCode(spaceKey)
                KbReleaseWait;
                break;
            end
        end
        % [Q] 루프가 끝난 뒤 RestrictKeysForKbCheck([])를 반드시 호출해야 하는 이유는 무엇인가요?
        RestrictKeysForKbCheck([]);

        % [Q] results(trial, :) = {...} 에서 우변을 대괄호 []가 아닌 중괄호 {}로 감싼 이유는 무엇인가요?
        %     targetRect(1)~(4)는 각각 사각형의 어느 좌표(L, T, R, B)에 해당하나요?
        results(trial, :) = {trial, triX, triY, targetRect(1), targetRect(2), targetRect(3), targetRect(4), resultText};

        % [Q] 휴식 조건에 'trial == restTrials' 외에 '&& trial < totalTrials'를 함께 붙인 이유는 무엇인가요?
        if trial == restTrials && trial < totalTrials
            DrawFormattedText(window, 'Break Time! Press SPACE to continue', 'center', 'center', white);
            Screen('Flip', window);

            % [Q] 이 휴식 대기 루프에서는 왜 결과 화면과 달리 RestrictKeysForKbCheck가 없는데도
            %     다른 키를 눌렀을 때 넘어가지 않나요? (그래도 RestrictKeysForKbCheck를 쓰면 어떤 점이 좋을까요?)
            while true
                [keyIsDown, ~, keyCode] = KbCheck;
                if keyCode(escKey)
                    error('사용자에 의해 중단되었습니다');
                end
                if keyCode(spaceKey)
                    KbReleaseWait;
                    break;
                end
            end
        end
    end

    % [Q] cell 배열인 results를 바로 writetable에 넣지 않고 cell2table로 변환하는 이유는 무엇인가요?
    colNames = {'Trial', 'FinalTriX', 'FinalTriY', 'TargetL', 'TargetT', 'TargetR', 'TargetB', 'Result'};
    resultTable = cell2table(results, 'VariableNames', colNames);
    writetable(resultTable, 'week8_result.csv');

    % [Q] 정상 종료 시 RestrictKeysForKbCheck([]), sca, ShowCursor를 각각 왜 호출하나요?
    %     (참고: 현재 코드에서 KbQueueRelease는 어떤 역할을 하나요?)
    RestrictKeysForKbCheck([]);
    KbQueueRelease;
    sca;
    ShowCursor;
    disp('Experiment successfully finished');

% [Q] catch info 블록은 언제 실행되며, info 변수에는 무엇이 담기나요?
%     마지막에 rethrow(info)를 호출하는 이유는 무엇인가요?
catch info
    fclose('all');
    RestrictKeysForKbCheck([]);
    KbQueueRelease;
    sca;
    ShowCursor;
    rethrow(info);
end
