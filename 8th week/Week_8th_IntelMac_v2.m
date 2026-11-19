% 8주차 확장 버전 (4방향 이동 + 피험자 데이터 덮어쓰기 방지 연습용)
%
% =========================================================================
% [진행 현황 체크리스트] (실행 코드는 수정하지 않고 위치별 상태·개선점만 표시함)
%   [완료 ✅] TODO A (타겟 Y 랜덤), 4방향 이동+KbReleaseWait, leftKey ';' 제거,
%             결과 화면 Screen('Flip') while 밖 이동, Break Time 키 제한, TODO C (타임스탬프 CSV)
%
%   [수정 필요 #1] 시작 화면 while true의 'end' 누락 (try~catch 문법 에러 발생)
%   [수정 필요 #2] 시작 화면 'screen' 소문자 오타 -> 대문자 'Screen'으로 수정
%   [수정 필요 #3] 시작 화면 중복 'if keyCode(escKey)' 3줄 삭제 (질문 답변 포함)
%   [수정 필요 #4] 결과 판정 옛 'isInside = IsInRect(triX, triY, targetRect);'가 3점 판정 결과를 덮어씀!
%
%   [개선 제안 #1] 결과 화면에 타겟·삼각형 함께 표시 (도형 유지된 채 판정 확인)
%   [개선 제안 #2] Break Time 키 제한 위치 정리 & 결과 문구 색상/안내 선택
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

    % [완료 ✅] 시작 안내 화면 구조 잘 작성하셨습니다! 아래 3가지 버그만 고치면 완벽합니다.
    DrawFormattedText(window, 'Press SPACE to start', 'center', 'center', white);
    % [수정 필요 #2] 대소문자 주의: 'screen' -> 'Screen' (소문자면 실행 시 에러 발생)
    screen('Flip', window);
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
    % [수정 필요 #1] ★ 중요: 여기 바로 위에 `while true`를 닫는 `end`가 빠져 있어 catch에서 문법 에러가 납니다!
    % [수정 필요 #3 & 질문 답변] 네, 맞습니다! 아래 3줄(if keyCode(escKey) ~ end)은 100% 중복이므로 지워주세요!
    %   (while 안에서 escKey는 이미 검사했고, break로 나온 뒤엔 스페이스를 누른 상태라 실행될 일 없음)
    if keyCode(escKey) % 왜 또 필요하지? 없어도 되지않나? 중복되는 느낌인데 
        error('사용자에 의해 중단되었습니다.');
    end
    % [완료 ✅] RestrictKeysForKbCheck([]) 해제까지 정확히 작성됨!
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
        % [수정 필요 #4] ★ 중요 버그: 아래 옛 코드가 남아 있어 위에서 구한 3점 판정 결과를 덮어쓰고 있습니다!
        %   -> 아래 1줄(`isInside = IsInRect(triX, triY, targetRect);`)을 지우거나 맨 앞에 '%'를 붙여 주석 처리하세요.
        isInside = IsInRect(triX, triY, targetRect);
        % [개선 제안 #2-A (1/2)] 정답/오답 글자 색을 다르게 하고 싶을 때:
        %   if isInside 안에 `resultColor = [0, 255, 100];` (초록)
        %   else        안에 `resultColor = [255, 80, 80];` (빨강) 을 한 줄씩 추가해 두고,
        %   아래 DrawFormattedText의 마지막 인수 `white`를 `resultColor`로 바꾸면 됩니다!
        if isInside
            resultText = 'correct';
        else
            resultText = 'wrong';
        end

        % [완료 ✅] Screen('Flip')를 while 밖으로 빼서 결과 글자 사라짐 버그 해결 완료! (while true + KbCheck 유지 굿!)
        RestrictKeysForKbCheck([spaceKey, escKey]);
        % [개선 제안 #1] 결과 화면에 타겟·삼각형 함께 표시 (선택 — "도화지에 아래에서 위로 겹쳐 그리기")
        %   왜 필요? Screen('Flip')는 새 도화지를 여는 것이라 글자만 그리면 방금 움직인 상자·삼각형이 사라집니다.
        %   어떻게? 아래 `DrawFormattedText` 바로 위에 아래 순서(1 -> 2 -> 3)대로 코드를 넣으면
        %           도형이 그대로 보인 상태에서 맨 위에 correct/wrong 글자가 겹쳐 뜹니다!
        %     % (1) 최종 위치 (triX, triY)의 삼각형 꼭짓점 3개 다시 계산
        %     triPoints = [triX - TriSize/2, triY - TriSize/2;
        %                  triX - TriSize/2, triY + TriSize/2;
        %                  triX + TriSize/2, triY];
        %     % (2) 이동 루프에서 쓰던 도형 그리기 4줄을 그대로 복사 (배경 -> 상자 -> 테두리 -> 삼각형)
        %     Screen('FillRect', window, gray);
        %     Screen('FillRect', window, targetFillColor, targetRect);
        %     Screen('FrameRect', window, targetBorderColor, targetRect, 3);
        %     Screen('FillPoly', window, TriColor, triPoints);
        %     % (3) 그 다음 아래 DrawFormattedText(글자) -> Screen('Flip') 실행!
        %
        % [개선 제안 #2-A (2/2)] 위 if문에서 resultColor를 만들었다면, 아래 줄의 `white`를 `resultColor`로 교체!
        DrawFormattedText(window, resultText, 'center', 'center', white);
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

        RestrictKeysForKbCheck([spaceKey, escKey]);
        if trial == restTrials && trial < totalTrials
            % [완료 ✅] Break Time 키 제한 적용 완료!
            % [개선 제안 #2-B] 키 잠금 위치 정리 (동작은 지금도 되지만, if 안으로 옮기면 더 깔끔함!)
            %   이유: 지금처럼 `if` 바로 위·아래에 있으면 휴식이 아닌 1~4회차에도 매번 잠갔다가 바로 풉니다.
            %   방법: 바깥의 RestrictKeysForKbCheck 2줄을 아래처럼 `if` 안(while true 앞·뒤)으로 옮겨주세요:
            %     if trial == restTrials && trial < totalTrials
            %         DrawFormattedText(...);
            %         Screen('Flip', window);
            %         RestrictKeysForKbCheck([spaceKey, escKey]); % <- 여기로 이동
            %         while true ... end
            %         RestrictKeysForKbCheck([]);                 % <- 여기로 이동
            %     end
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
        RestrictKeysForKbCheck([]);
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
