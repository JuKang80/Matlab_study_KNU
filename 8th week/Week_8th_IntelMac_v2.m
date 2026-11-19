% 8주차 확장 버전 (4방향 이동 + 피험자 데이터 덮어쓰기 방지 연습용)
%
% =========================================================================
% [진행 현황 체크리스트] (단순 오타·세미콜론 3건만 반영 / 핵심 로직 버그 1건은 직접 수정용으로 유지)
%   [완료 ✅] 시작 화면 while true 'end' 추가 & 중복 escKey 제거,
%             TODO A (타겟 Y 랜덤), 4방향 이동+KbReleaseWait, leftKey ';' 제거,
%             결과 판정 3꼭짓점 || 로직, 정답/오답 resultColor 분기,
%             결과 화면 도형 다시 그리기 + Screen('Flip') while 밖 이동,
%             Break Time 키 제한 if 안 정리, TODO C (타임스탬프 CSV)
%   [자동 수정 ✅] 단순 오타·세미콜론 3건 반영 완료:
%                 (1) 'screen' -> 'Screen', (2) 'resultColor' 끝 ';', (3) 'target, FillColor' -> 'targetFillColor'
%
%   [수정 필요 #1] 결과 판정 옛 'isInside = IsInRect(triX, triY, targetRect);' 1줄 삭제/주석 처리 (마지막 1건!)
% =========================================================================

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

    % [완료 ✅] 시작 안내 화면 완성! ('screen' 대소문자 오타 -> 'Screen' 자동 수정 반영됨)
    DrawFormattedText(window, 'Press SPACE to start', 'center', 'center', white);
    Screen('Flip', window);
    RestrictKeysForKbCheck([spaceKey, escKey]);
    while true
        [keyIsDown, ~, keyCode] = KbCheck; % 이거 처음에 키가 눌렸는지도 검사해야 하지 않니? 단순히 어떤 키가 만약 1(눌려졌으면, 근데 여기선 구체적으로 스페이스바와 esc로만 제한함)이면 걍 그 다음 if문에서 뭐 처리가 되는건가 
        % [질문 답변] 네, 맞습니다! keyCode가 256개 키의 0/1 상태를 전부 담고 있어서
        %   아래 if keyCode(escKey) / if keyCode(spaceKey)만 바로 검사하면 충분합니다 (keyIsDown 검사 생략 가능).
        if keyCode(escKey)
            error('사용자에 의해 중단되었습니다.');
        end
        if keyCode(spaceKey)
            KbReleaseWait;
            break;
        end
    end
    % [완료 ✅] while true의 'end' 추가, 중복 escKey 제거, RestrictKeysForKbCheck([]) 해제까지 깔끔하게 완료!
    RestrictKeysForKbCheck([]);
    for trial = 1:totalTrials
        KbReleaseWait; 
        % [완료 ✅] 매 시행 시작 키 잔여(Carryover) 방지 (위 KbReleaseWait 적용됨)

        % [TODO A - 완료 ✅] 4방향 이동용 타겟 Y좌표 랜덤 배치 적용됨
        triX = 150;
        triY = centerY;
        targetX = randi([round(centerX), screenWidth - 150]);
        targetY = randi([150, screenHeight - 150]); 

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
            % [완료 ✅] leftKey 끝 불필요한 ';' 제거 완료
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
            if keyCode(escKey)
                error('사용자에 의해 중단되었습니다');
            end
        end

        % [완료 ✅] 꼭짓점 3개 중 1개라도 진입 시 정답(||) 로직 깔끔하게 작성 완료!
        %   (참고: 맨 끝 '||' 두 개를 '&&'로 바꾸면 꼭짓점 3개 모두 포함 기준이 됩니다)
        isInside = IsInRect(triX - TriSize/2, triY - TriSize/2, targetRect) || ...
            IsInRect(triX - TriSize/2, triY + TriSize/2, targetRect) || ...
            IsInRect(triX + TriSize/2, triY, targetRect);
        % [수정 필요 #1] ★ 마지막 남은 버그: 아래 옛 코드가 위에서 구한 3점 판정 결과를 덮어쓰고 있습니다!
        %   -> 아래 1줄(`isInside = IsInRect(triX, triY, targetRect);`)을 지우거나 맨 앞에 '%'를 붙여 주석 처리하면 완료됩니다.
        isInside = IsInRect(triX, triY, targetRect);
        % [완료 ✅] 정답(초록)/오답(빨강) resultColor 분기 적용 완료! (else 끝 ';' 누락 자동 수정 반영됨)
        if isInside
            resultColor = [0, 255, 100];
            resultText = 'correct';
        else
            resultColor = [255, 80, 80];
            resultText = 'wrong';
        end

        % [완료 ✅] Screen('Flip')를 while 밖으로 빼서 결과 글자 사라짐 버그 해결 완료! (while true + KbCheck 유지 굿!)
        RestrictKeysForKbCheck([spaceKey, escKey]);

        % [완료 ✅] 결과 화면 도형 다시 그리기 + resultColor 적용 완료! ('targetFillColor' 오타 자동 수정 반영됨)
        triPoints = [triX - TriSize/2, triY - TriSize/2; triX - TriSize/2, triY + TriSize/2; triX + TriSize/2, triY];
        Screen('FillRect', window, gray);
        Screen('FillRect', window, targetFillColor, targetRect);
        Screen('FrameRect', window, targetBorderColor, targetRect, 3);
        Screen('FillPoly', window, TriColor, triPoints);
        DrawFormattedText(window, resultText, 'center', 'center', resultColor);
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
        RestrictKeysForKbCheck([]);

        % 결과 기록 & 절반 지점 휴식
        results(trial, :) = {trial, triX, triY, targetRect(1), targetRect(2), targetRect(3), targetRect(4), resultText};

        if trial == restTrials && trial < totalTrials
            % [완료 ✅] Break Time 키 제한을 if 안(Screen('Flip') 아래~while 뒤)으로 깔끔하게 정리 완료!
            DrawFormattedText(window, 'Break Time! Press SPACE to continue', 'center', 'center', white);
            Screen('Flip', window);
            RestrictKeysForKbCheck([spaceKey, escKey]);

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
            RestrictKeysForKbCheck([]);
        end
    end

    %% [Part 4] 결과 저장 (피험자 데이터 덮어쓰기 방지)
    colNames = {'Trial', 'FinalTriX', 'FinalTriY', 'TargetL', 'TargetT', 'TargetR', 'TargetB', 'Result'};
    resultTable = cell2table(results, 'VariableNames', colNames);

    % [TODO C - 완료 ✅] 날짜/시간 타임스탬프 CSV 파일명 적용됨 (덮어쓰기 방지)
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
