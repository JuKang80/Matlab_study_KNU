% 8주차 확장 버전 (4방향 이동 + 피험자 데이터 덮어쓰기 방지 연습용)
%
% =========================================================================
% [진행 현황 체크리스트] (실행 코드는 수정하지 않고 위치별 상태만 표시함)
%   [완료 ✅] TODO A (타겟 Y좌표 랜덤), 4방향 이동+KbReleaseWait, 키 잔여 초기화, TODO C (타임스탬프 CSV)
%
%   [수정 필요 #1] 결과 화면 Screen('Flip')만 while 밖(DrawFormattedText 바로 아래)으로 빼기
%                  (기존 while true + KbCheck 구조는 그대로 두셔도 됩니다!)
%   [수정 필요 #2] leftKey 끝 불필요한 ';' 정리
%   [수정 필요 #3] Break Time 대기 루프 앞뒤에도 RestrictKeysForKbCheck 일관 적용
%
%   [추가 구현 #1] 실험 시작 안내 화면 ('Press SPACE to start') — 5단계 상세 힌트
%   [추가 구현 #2] 결과 화면에 타겟·삼각형 함께 표시 — 3단계 상세 힌트
%   [추가 구현 #3] 영역 판정 기준 선택 (TODO D: 중심점 vs 초간단 꼭짓점 IsInRect || / &&)
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

    DrawFormattedText(window, 'Press SPACE to start', 'center', 'center', white);
    screen('Flip', window);
    RestrictKeysForKbCheck([spaceKey, escKey]);
    while true
        [keyIsDown, ~, keyCode] = KbCheck; % 이거 처음에 키가 눌렸는지도 검사해야 하지 않니? 단순히 어떤 키가 만약 1(눌려졌으면, 근데 여기선 구체적으로 스페이스바와 esc로만 제한함)이면 걍 그 다음 if문에서 뭐 처리가 되는건가 
        if keyCode(escKey)
            error('사용자에 의해 중단되었습니다.');
        end
        if keyCode(spaceKey)
            KbReleaseWait;
            break;
        end
    if keyCode(escKey) % 왜 또 필요하지? 없어도 되지않나? 중복되는 느낌인데 
        error('사용자에 의해 중단되었습니다.');
    end
    RestrictKeysForKbCheck([]);
    % [추가 구현 #1] 실험 시작 안내 화면 ('Press SPACE to start') — 5단계 구현 힌트
    %   목표: 실행하자마자 1회차가 시작되지 않도록 안내 문구를 띄우고 스페이스 입력을 기다린 뒤 시작
    %   1단계 (안내 문구 1회 출력): for문 위에서 글자를 그리고 Flip (고정 화면이라 while 밖에서 1번만!)
    %     DrawFormattedText(window, 'Press SPACE to start', 'center', 'center', white);
    %     Screen('Flip', window);
    %   2단계 (허용 키 잠그기): 스페이스와 ESC 외 다른 키를 눌러도 안 넘어가게 제한
    %     RestrictKeysForKbCheck([spaceKey, escKey]);
    %   3단계 (키 입력 대기): 기존 코드처럼 익숙한 while true + KbCheck를 그대로 쓰시면 됩니다!
    %     while true
    %         [~, ~, keyCode] = KbCheck;
    %         if keyCode(escKey), error('사용자에 의해 중단되었습니다'); end
    %         if keyCode(spaceKey), KbReleaseWait; break; end
    %     end
    %     (참고: while문 대신 `[~, keyCode] = KbWait([], 2); KbReleaseWait;` 로 줄이는 방법도 있음)
    %   4단계 (ESC 체크): 시작 화면에서 ESC를 눌렀으면 실험 중단
    %     if keyCode(escKey), error('사용자에 의해 중단되었습니다'); end
    %   5단계 (★필수! 잠금 해제): 이 줄을 빼먹으면 1회차에서 화살표 키가 아예 먹히지 않습니다!
    %     RestrictKeysForKbCheck([]);
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
            % [수정 필요 #2] 아래 줄 끝 세미콜론(;)은 불필요하므로 제거하면 깔끔함 (`if keyCode(leftKey)`)
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

        % -----------------------------------------------------------------
        % [TODO D / 추가 구현 #3] 영역 안/밖 판정 — 원하는 기준 1가지를 선택하세요!
        %
        % - [방법 1: 중심점 기준 (현재 코드)] 삼각형 중심(triX, triY)만 들어가면 정답 (1줄)
        %   isInside = IsInRect(triX, triY, targetRect);
        %
        isInside = IsInRect(triX - TriSize/2, triY - TriSize/2, targetRect) || ...
            IsInRect(triX - TriSize/2, triY + TriSize/2, targetRect) || ...
            IsInRect(triX + TriSize/2, triY, targetRect);
        %  [방법 2-A: ★초간단 부분 진입 (추천)] 꼭짓점 3개 중 1개라도 들어오면 정답 ('||' = 또는)
        %   새 문법(행렬 슬라이싱/any/polyshape) 없이 이미 아는 IsInRect만 꼭짓점 3개에 각각 쓰면 끝!
        %   isInside = IsInRect(triX - TriSize/2, triY - TriSize/2, targetRect) || ... % 왼쪽 위 꼭짓점
        %              IsInRect(triX - TriSize/2, triY + TriSize/2, targetRect) || ... % 왼쪽 아래 꼭짓점
        %              IsInRect(triX + TriSize/2, triY,             targetRect);       % 오른쪽 끝 꼭짓점
        %
        % - [방법 2-B: ★초간단 완전 포함 (엄격)] 꼭짓점 3개가 전부 들어와야 정답 ('&&' = 그리고)
        %   위 방법 2-A에서 맨 끝의 '||' 두 개만 '&&'로 바꾸면 됩니다!
        %   isInside = IsInRect(triX - TriSize/2, triY - TriSize/2, targetRect) && ...
        %              IsInRect(triX - TriSize/2, triY + TriSize/2, targetRect) && ...
        %              IsInRect(triX + TriSize/2, triY,             targetRect);
        %
        % - (주의) 기존의 `all(IsInRect(triPoints(:,1), triPoints(:,2), targetRect))` 처럼
        %   IsInRect 한 번에 점 3개(벡터)를 묶어 넣으면 PTB 버전에 따라 에러가 나므로 위처럼 각각 호출하세요.
        % -----------------------------------------------------------------
        isInside = IsInRect(triX, triY, targetRect);
        if isInside
            resultText = 'correct';
        else
            resultText = 'wrong';
        end

        % [내부 루프 2] 결과 표시 후 스페이스 키만 대기
        % [안심 포인트] 아래 while true + KbCheck 대기 구조는 굳이 KbWait로 바꾸지 않고 그대로 쓰셔도 됩니다!
        
        RestrictKeysForKbCheck([spaceKey, escKey]);
        % [수정 필요 #1] ★ 중요 버그: 아래 DrawFormattedText만 while 밖이고 Screen('Flip')가 while 안에 있어,
        %   첫 1프레임(약 16ms)만 글자가 보였다가 다음 Flip(빈 백버퍼)에서 화면이 지워집니다!
        %   -> while true + KbCheck는 그대로 두시고, `Screen('Flip', window);` 한 줄만
        %      DrawFormattedText 바로 아래(while 밖)로 올려주세요 (아래 Break Time과 동일한 구조).
        % [추가 구현 #2] 결과 화면에 타겟·삼각형 함께 표시 — 3단계 구현 힌트
        %   이유: Screen('Flip')를 부르면 직전 화면(초록 상자·삼각형)이 지워지고 글자만 남기 때문!
        %   1단계 (도형 다시 그리기): 아래 DrawFormattedText 바로 위에 이동 루프의 그리기 4줄 복사
        %     Screen('FillRect', window, gray);                             % 배경 칠하기
        %     Screen('FillRect', window, targetFillColor, targetRect);      % 초록 상자 채우기
        %     Screen('FrameRect', window, targetBorderColor, targetRect, 3);% 초록 테두리
        %     Screen('FillPoly', window, TriColor, triPoints);              % 최종 삼각형 (triPoints 최신화 권장)
        %   2단계 (결과 글자 + 색상 선택): 도형 위에 겹쳐서 결과 문구 그리기
        %     - 기본: DrawFormattedText(window, resultText, 'center', 'center', white);
        %     - 추천(색상/안내): if문에서 resultColor([0 255 100] / [255 80 80]) 정해두고,
        %       msg = sprintf('%s\n\nPress SPACE for next trial', resultText);
        %       DrawFormattedText(window, msg, 'center', 'center', resultColor);
        %   3단계 (딱 1번 Flip): [수정 필요 #1]과 함께 Screen('Flip', window);를 while 밖(글자 바로 아래)으로 빼기!
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
            % [수정 필요 #3] 위 결과 대기 루프처럼 앞뒤를 `RestrictKeysForKbCheck([spaceKey, escKey]);`와
            %   `RestrictKeysForKbCheck([]);`로 감싸면 휴식 중 다른 키 입력을 일관되게 무시할 수 있습니다.
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
