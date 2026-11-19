% 8주차 확장 버전 (4방향 이동 + 피험자 데이터 덮어쓰기 방지 연습용)

%% [Part 1] 기본 환경 초기화 및 인텔 맥 호환성 특화 설정
clear;
clc;
close all;
sca;

Screen('Preference', 'SkipSyncTests', 2);
Screen('Preference', 'TextRenderer', 0);
Screen('Preference', 'TextAntiAliasing', 1);
Screen('Preference', 'VisualDebugLevel', 1);
Screen('Preference', 'SuppressAllWarnings', 1);
Screen('Preference', 'ConserveVRAM', 64);

PsychDefaultSetup(1);

try
    screens = Screen('Screens');
    screenNumber = max(screens);
    white = WhiteIndex(screenNumber);
    black = BlackIndex(screenNumber);
    gray = white / 2;

    useWindowedMode = true;

    if useWindowedMode
        [window, windowRect] = Screen('OpenWindow', screenNumber, gray, [0, 0, 1280, 800]);
    else
        [window, windowRect] = Screen('OpenWindow', screenNumber, gray);
    end

    Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');
    Screen('TextSize', window, 24);

    screenWidth = windowRect(3);
    screenHeight = windowRect(4);
    [centerX, centerY] = RectCenter(windowRect);

    %% [Part 2] 실험 설정 및 변수 정의
    totalTrials = 10;
    restTrials = floor(totalTrials / 2);

    leftKey = KbName('LeftArrow');
    rightKey = KbName('RightArrow');
    upKey = KbName('UpArrow');
    downKey = KbName('DownArrow');
    spaceKey = KbName('space');
    escKey = KbName('ESCAPE');

    TriSize = 60;
    TrimoveSpeed = 50; % 한번 눌렀을 때 움직이는 거리
    TriColor = [255, 255, 255];
    % 색 랜덤을 원한다면 for문 초반에 TriColor = randi([0, 255], 1, 3); 집어넣기

    targetFillColor = [0, 220, 120, 80]; % 타겟의 색 지정. 이 대괄호 안의 파라미터가 각각 R, G, B, Alpha인데, 마지막 값이 0이면 완전 투명이고 255면 완전 불투명이다. 
    targetBorderColor = [0, 220, 120, 255]; % 테두리 색 자체는 선명하게 하였다. 
    targetWidth = 180;
    targetHeight = 180;

    results = cell(totalTrials, 8);

    % [인지실험 팁] 실험 시작 전 눌려있던 키가 1회차로 넘어오지 않게 초기화
    KbReleaseWait;

    %% [Part 3] 메인 실험 루프
    for trial = 1:totalTrials
        KbReleaseWait; 
        % [경계 조건 힌트] 매 시행 시작 시에도 이전 키 눌림 잔여(Carryover) 방지: KbReleaseWait;
        % [반응시간(RT) 아이디어 메모 - 구현은 선택]
        %   루프 1 직전에 startTime = GetSecs; 를 찍고, spaceKey 누를 때 rt = GetSecs - startTime; 으로 측정 가능

        % [TODO A - 선택] 4방향 이동이므로 타겟 Y좌표도 랜덤으로 바꿔볼 수 있습니다!
        % - 힌트: targetY = randi([150, screenHeight - 150]);
        triX = 150;
        triY = centerY;
        targetX = randi([round(centerX), screenWidth - 150]);
        targetY = randi([150, screenHeight - 150]); 
        % targetY = centerY;

        targetRect = CenterRectOnPointd([0, 0, targetWidth, targetHeight], targetX, targetY);

        % [내부 루프 1] 4방향 키보드 이동 (스페이스 누르면 제출)
        while true
            triPoints = [triX - TriSize/2, triY - TriSize/2;
                triX - TriSize/2, triY + TriSize/2;
                triX + TriSize/2, triY];

            Screen('FillRect', window, gray);
            Screen('FillRect', window, targetFillColor, targetRect);
            Screen('FrameRect', window, targetBorderColor, targetRect, 3);
            Screen('FillPoly', window, TriColor, triPoints);

            DrawFormattedText(window, sprintf('Trial %d/%d', trial, totalTrials), 40, 40, white);
            Screen('Flip', window);

            [keyIsDown, ~, keyCode] = KbCheck;

            if keyCode(rightKey)
                triX = min(screenWidth - TriSize/2, triX + TrimoveSpeed);
                KbReleaseWait;
            end
            if keyCode(leftKey);
                triX = max(TriSize/2, triX - TrimoveSpeed); 
            end
            if keyCode(upKey)
                triY = max(TriSize/2, triY - TrimoveSpeed);
            end
            if keyCode(downKey)
                triY = min(screenHeight - TriSize/2, triY + TrimoveSpeed);
            end
            

            if keyCode(spaceKey)
                KbReleaseWait;
                break;
            end
            if keyCode(escKey)
                error('사용자에 의해 중단되었습니다');
            end
        end

        % -----------------------------------------------------------------
        % [TODO D] 영역 안/밖 판정 — 3가지 구현 방법 중 선택해 보세요!
        % - [방법 1: 중심점 기준 (현재)] 삼각형 중심만 들어가면 정답
        %   isInside = IsInRect(triX, triY, targetRect);
        % - [방법 2: 꼭짓점 3개 전부 포함 (엄격)] triPoints 3점이 모두 타겟 안에 있어야 정답
        %   isInside = all(IsInRect(triPoints(:, 1), triPoints(:, 2), targetRect));
        % - [방법 3: IsInRect 없이 직접 부등식 비교 (원리)] Left<=X<=Right & Top<=Y<=Bottom
        %   isInside = (triX >= targetRect(1)) && (triX <= targetRect(3)) && ...
        %              (triY >= targetRect(2)) && (triY <= targetRect(4));
        % -----------------------------------------------------------------
        isInside = IsInRect(triX, triY, targetRect);
        if isInside
            resultText = 'correct';
        else
            resultText = 'wrong';
        end

        % [내부 루프 2] 결과 표시 후 스페이스 키만 대기
        % [매트랩다운 개선 팁 1] 움직이지 않는 글자(resultText)는 while 밖에 1번만 그리고 Flip해도 됩니다!
        % [매트랩다운 개선 팁 2] RestrictKeysForKbCheck로 키를 잠갔다면, while true 대신
        %   KbWait([], 2); [~, ~, keyCode] = KbCheck; if keyCode(escKey), error(...); end
        %   로 줄일 수 있습니다. (아래 Break Time 대기 루프도 동일!)
        키 잠궜다면 while true대신 사용할수있다는거 이해못함 
        RestrictKeysForKbCheck([spaceKey, escKey]);
        DrawFormattedText(window, resultText, 'center', 'center', white);
        while true
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
        RestrictKeysForKbCheck([]);

        % 결과 기록 & 절반 지점 휴식
        results(trial, :) = {trial, triX, triY, targetRect(1), targetRect(2), targetRect(3), targetRect(4), resultText};

        if trial == restTrials && trial < totalTrials
            DrawFormattedText(window, 'Break Time! Press SPACE to continue', 'center', 'center', white);
            Screen('Flip', window);

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

    %% [Part 4] 결과 저장 (피험자 데이터 덮어쓰기 방지)
    colNames = {'Trial', 'FinalTriX', 'FinalTriY', 'TargetL', 'TargetT', 'TargetR', 'TargetB', 'Result'};
    resultTable = cell2table(results, 'VariableNames', colNames);

    % ---------------------------------------------------------------------
    % [TODO C] 매번 같은 'week8_result.csv'에 덮어쓰지 않도록 날짜/시간 붙이기!
    % 1) 현재 시각을 '20261117_211200' 같은 문자열로 만들기:
    %    timeStr = string(datetime('now', 'Format', 'yyyyMMdd_HHmmss'));
    % 2) sprintf로 파일 이름 합치기 (%s 자리에 timeStr 들어감):
    %    fileName = sprintf('week8_result_%s.csv', timeStr);
    % 3) 아래 writetable의 두 번째 인수를 'week8_result.csv' 대신 fileName 으로 바꾸세요!
    % ---------------------------------------------------------------------
    timeStr = string(datetime('now','Format','yyyyMMdd_HHmmss'));
    fileName = sprintf('week8_result_%s.csv', timeStr);
    writetable(resultTable, fileName);

    %% [Part 5] 정상 종료 및 자원 해제
    RestrictKeysForKbCheck([]);
    sca;
    ShowCursor;
    disp('Experiment successfully finished');

catch info
    fclose('all');
    RestrictKeysForKbCheck([]);
    sca;
    ShowCursor;
    rethrow(info);
end
