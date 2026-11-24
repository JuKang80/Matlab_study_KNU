clear;
clc;
close all;
sca;

Screen('Preference', 'SkipSyncTests', 1);
PsychDefaultSetup(1);

try

    screens = Screen('Screens');
    screenNumber = max(screens);

    white = WhiteIndex(screenNumber);
    black = BlackIndex(screenNumber);
    gray = white / 2; 

    useWindowedMode = false;

    if useWindowedMode
        [window, windowRect] = Screen('OpenWindow', screenNumber, gray, [0, 0, 1280, 800]);
    else
        [window, windowRect] = Screen('OpenWindow', screenNumber, gray);
    end

    Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');
    Screen('TextSize', window, 24);
    
    screenWidth = windowRect(3);  % 3번째 값(Right) = 화면 전체 가로 길이
    screenHeight = windowRect(4); % 4번째 값(Bottom) = 화면 전체 세로 길이

    [centerX, centerY] = RectCenter(windowRect);

    totalTrials = 10;
    restTrials = floor(totalTrials / 2); 

    leftKey = KbName('LeftArrow');
    rightKey = KbName('RightArrow');
    upKey = KbName('UpArrow');
    downKey = KbName('DownArrow');
    spaceKey = KbName('space');
    escKey = KbName('ESCAPE');

    TriSize = 60; % 삼각형 전체 가로/세로 폭 
    TrimoveSpeed = 50; % 이동하는 거리
    TriColor = [255, 255, 255];

    targetFillColor = [0, 220, 120, 80];    % 반투명 초록색 채우기
    targetBorderColor = [0, 220, 120, 255]; % 선명한 초록색 테두리
    targetWidth = 180;
    targetHeight = 180;

    results = cell(totalTrials, 8);

    KbReleaseWait;

    DrawFormattedText(window, 'Press SPACE to start', 'center', 'center', white);
    Screen('Flip', window); 

    RestrictKeysForKbCheck([spaceKey, escKey]);
    while true
        [keyIsDown, ~, keyCode] = KbCheck;
        if keyCode(escKey)
            error('사용자에 의해 중단되었습니다');
        end
        if keyCode(spaceKey)
            KbReleaseWait; % 스페이스에서 손을 떼어야 다음으로 넘어감
            break;
        end
    end
    RestrictKeysForKbCheck([]); % 키 입력 제한 해제

    for trial = 1:totalTrials
        % 시행 시작 시 이전 시행의 키 눌림이 있을 가능성을 방지
        KbReleaseWait;

        triX = 150;     % 삼각형은 매 시행 왼쪽(X=150)에서 출발
        triY = centerY; % Y좌표는 화면 세로 정중앙에서 출발

        targetX = randi([round(centerX), screenWidth - 150]);
        targetY = randi([150, screenHeight - 150]);

        targetRect = CenterRectOnPointd([0, 0, targetWidth, targetHeight], targetX, targetY);

        while true
            triPoints = [triX - TriSize/2, triY - TriSize/2; % 왼쪽 위 꼭짓점
                         triX - TriSize/2, triY + TriSize/2; % 왼쪽 아래 꼭짓점
                         triX + TriSize/2, triY];            % 오른쪽 끝 꼭짓점

            Screen('FillRect', window, gray);
            Screen('FillRect', window, targetFillColor, targetRect);
            Screen('FrameRect', window, targetBorderColor, targetRect, 3);
            Screen('FillPoly', window, TriColor, triPoints);
            DrawFormattedText(window, sprintf('Trial %d/%d', trial, totalTrials), 40, 40, white);

            Screen('Flip', window);

            [keyIsDown, ~, keyCode] = KbCheck;

            % 오른쪽 화살표 키가 눌렸다면(1이면) 오른쪽으로 좌표 이동
            if keyCode(rightKey)
                triX = min(screenWidth - TriSize/2, triX + TrimoveSpeed);
                KbReleaseWait;
            end

            if keyCode(leftKey)            
                triX = max(TriSize/2, triX - TrimoveSpeed);
                KbReleaseWait;
            end

            if keyCode(upKey)
                triY = max(TriSize/2, triY - TrimoveSpeed);
                KbReleaseWait;
            end

            if keyCode(downKey)
                triY = min(screenHeight - TriSize/2, triY + TrimoveSpeed);
                KbReleaseWait;
            end

            if keyCode(spaceKey)
                KbReleaseWait; 
                break;     
            end

            % ESC 키를 누르면 에러를 발생시켜 catch 블록으로 이동
            if keyCode(escKey)
                error('사용자에 의해 중단되었습니다');
            end
        end

       
        % 중심점 기준 (기본): 삼각형 중심(triX, triY)만 들어가면 correct
        % isInside = IsInRect(triX, triY, targetRect);
        % 하지만 각 그런 방식보다 각 꼭짓점 3개 중 1개라도 타겟에 들어오면 정답으로 처리함
        isInside = IsInRect(triX - TriSize/2, triY - TriSize/2, targetRect) || ... % 왼쪽 위 꼭짓점
                   IsInRect(triX - TriSize/2, triY + TriSize/2, targetRect) || ... % 왼쪽 아래 꼭짓점
                   IsInRect(triX + TriSize/2, triY,             targetRect);       % 오른쪽 끝 꼭짓점

        if isInside
            resultColor = [0, 255, 100];
            resultText = 'correct';
        else
            resultColor = [255, 80, 80];
            resultText = 'wrong';
        end

        triPoints = [triX - TriSize/2, triY - TriSize/2;
                     triX - TriSize/2, triY + TriSize/2;
                     triX + TriSize/2, triY];

        % 배경 + 타겟 상자 + 최종 삼각형 다시 그리기
        Screen('FillRect', window, gray);
        Screen('FillRect', window, targetFillColor, targetRect);
        Screen('FrameRect', window, targetBorderColor, targetRect, 3);
        Screen('FillPoly', window, TriColor, triPoints);

        % 도형 위에 결과 문구('correct'=초록 / 'wrong'=빨강) 그리기
        DrawFormattedText(window, resultText, 'center', 'center', resultColor);

        % while 전 Flip 
        Screen('Flip', window);

        RestrictKeysForKbCheck([spaceKey, escKey]);
        while true
            [keyIsDown, ~, keyCode] = KbCheck;
            if keyCode(escKey)
                error('사용자에 의해 중단되었습니다');
            end
            if keyCode(spaceKey)
                KbReleaseWait;
                break; % 루프 나가서 기록 부분으로 나간다.
            end
        end
        RestrictKeysForKbCheck([]); % 키 제한 해제

       
        % trial번째 행의 모든 열에 8가지 정보(시행번호, 최종좌표X/Y, 타겟 왼/오/위/아래 좌표, 정답여부)
        results(trial, :) = {trial, triX, triY, targetRect(1), targetRect(2), targetRect(3), targetRect(4), resultText};

        % 절반 시행이 지났을 때 휴식 시간 부여
        % 현재 시행이 restTrials(5)이고 마지막 시행이 아닐 때 실행.
        if trial == restTrials && trial < totalTrials
            DrawFormattedText(window, 'Break Time!!! Press SPACE to continue', 'center', 'center', white);
            Screen('Flip', window);

            RestrictKeysForKbCheck([spaceKey, escKey]);
            while true
                [keyIsDown, ~, keyCode] = KbCheck;
                if keyCode(escKey)
                    error('사용자에 의해 중단되었습니다');
                end
                if keyCode(spaceKey)
                    KbReleaseWait;
                    break; % 휴식 대기 종료 
                end
            end
            RestrictKeysForKbCheck([]);
        end
    end


    colNames = {'Trial', 'FinalTriX', 'FinalTriY', 'TargetL', 'TargetT', 'TargetR', 'TargetB', 'Result'};
    % Target의 왼쪽 X좌표, Target의 Y좌표, Target의 오른쪽 좌표, Target의 아래쪽 좌표, correct인지 wrong인지
    resultTable = cell2table(results, 'VariableNames', colNames);
    timeStr = string(datetime('now', 'Format', 'yyyyMMdd_HHmmss'));
    fileName = sprintf('week8_result_%s.csv', timeStr);
    writetable(resultTable, fileName);

    
    RestrictKeysForKbCheck([]); % 키 입력 제한이 남아있지 않도록 초기화
    sca; % 열린 PTB 화면 창 모두 닫기
    ShowCursor; % 숨겨졌을 수 있는 마우스 커서 다시 표시
    disp('Experiment successfully finished');

catch info
    fclose('all');
    RestrictKeysForKbCheck([]);
    sca;
    ShowCursor;
    rethrow(info);
end