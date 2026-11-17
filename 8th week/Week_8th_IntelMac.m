% 1. 임의의 삼각형을 하나 만들고 키보드를 이용하여 움직이게 만드세요.
% 
% 2. 삼각형이 특정 영역 내에 들어간 후, 스페이스 키를 누르면 correct, 아니면 wrong이 뜨도록 만드세요. 
% 다시 스페이스 키를 누르면 다음 시행으로 넘어가도록 하세요(다른 키 누르면 반응 없어야 함).
% 
% 3. 메모장 또는 엑셀에 각 시행의 최종 삼각형 위치, 특정 영역의 위치, correct or wrong을 저장하세요. 
% 
% ‘특정 영역’은 삼각형, 사각형 등 자유롭게 만들기. 투명하게 해도 됨
% - 반복 횟수는 10회 
% - 시행의 절반이 지나면 휴식 시간 부여 (10회인 경우, 5회 후에 휴식 시간)
% - 다만, 필요에 따라 반복 횟수를 편하게 바꿀 수 있어야 하고, 휴식 타이밍도 이에 맞게 변경되어야 함!

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

% 2. 텍스트 렌더러 크래시 방지 (DrawFormattedText 호출 시 MATLAB 강제 종료 방지)
Screen('Preference', 'TextRenderer', 0);
Screen('Preference', 'TextAntiAliasing', 1);

% 3. 시작 시 깜빡이는 경고 화면 생략 및 불필요한 콘솔 경고 억제
Screen('Preference', 'VisualDebugLevel', 1);
Screen('Preference', 'SuppressAllWarnings', 1);

% 4. Intel 내장 그래픽(HD/Iris) 및 macOS WindowServer VRAM 충돌 방지 플래그
Screen('Preference', 'ConserveVRAM', 64);

% PTB 기본 환경 초기화 (키보드 명칭 통일)
PsychDefaultSetup(1);

try
    % ---------------------------------------------------------------------
    % 1-1. 모니터 번호 및 기본 색상값 정의
    % ---------------------------------------------------------------------
    screens = Screen('Screens');
    screenNumber = max(screens);
    white = WhiteIndex(screenNumber);
    black = BlackIndex(screenNumber);
    gray = white / 2;

    % ---------------------------------------------------------------------
    % 1-2. 실험 화면 창 열기 (인텔 맥 전체 화면 먹통 방지 창 모드 기본 적용)
    % ---------------------------------------------------------------------
    % 인텔 맥에서는 안전한 창 모드(true) 사용을 권장합니다.
    % 전체 화면이 필요할 때만 false로 변경하세요.
    useWindowedMode = true;

    if useWindowedMode
        [window, windowRect] = Screen('OpenWindow', screenNumber, gray, [0, 0, 1280, 800]);
    else
        [window, windowRect] = Screen('OpenWindow', screenNumber, gray);
    end

    Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA'); % 알파블렌딩
    Screen('TextSize', window, 24); % 기본 폰트 크기 설정

    % ---------------------------------------------------------------------
    % 1-3. 화면 가로/세로 해상도 및 정중앙 좌표 추출
    % ---------------------------------------------------------------------
    screenWidth = windowRect(3);
    screenHeight = windowRect(4);
    [centerX, centerY] = RectCenter(windowRect);

    %% [참고] PTB3 핵심 요약 & 공식 데모 (필요할 때 명령창에 입력)
    % - 좌표계: 좌상단 (0,0), 오른쪽(+X), 아래쪽(+Y), 위쪽(-Y) / Rect = [L, T, R, B]
    % - 데모: open KbDemo (키보드 이동) | open HelloShapesDemo (삼각형/사각형)
    %         open MullerLyerIllusion (시행 루프·결과 저장) | help IsInRect (영역 판정)

    %% [Part 2] 실험 설정 및 변수 정의
    % [TODO 1 - 완료] 시행 횟수 및 절반 휴식 타이밍 (홀수 대비 시 floor 권장)
    totalTrials = 10;
    restTrials = totalTrials / 2;
    
    % [TODO 2 - 완료] 키 코드, 삼각형/특정 영역 속성, 결과 배열 선언
    leftKey = KbName('LeftArrow'); 
    rightKey = KbName('RightArrow');
    upKey = KbName('UpArrow');
    downKey = KbName('DownArrow');
    spaceKey = KbName('space');
    escKey = KbName('ESCAPE');

    TriSize = 60;
    TrimoveSpeed = 8;
    TriColor = [255, 255, 255];

    % target zone 구현
    targetFillColor = [0, 220, 120, 80]; % 알파 80 -> 반투명 초록색
    targetBorderColor = [0, 220, 120, 255];
    targetWidth = 180;
    targetHeight = 180; 
    
    % 10행(시행 수) x 8열(기록 항목 8개) 빈 표 사전 할당 (숫자+글자 혼합 저장을 위해 cell 사용)
    results = cell(totalTrials, 8);

    %% [Part 3] 메인 실험 루프
    for trial = 1:totalTrials

        % [TODO 3 - 완료] 삼각형(왼쪽) & 특정 영역(오른쪽 중앙) 초기 위치 설정
        triX = 150;
        triY = centerY;
        targetX = randi([round(centerX), screenWidth - 150]);
        targetY = centerY;

        % 중심 (targetX, targetY)에 맞춰 [Left, Top, Right, Bottom] 사각형 좌표 생성
        targetRect = CenterRectOnPointd([0, 0, targetWidth, targetHeight], targetX, targetY);

        % (나중에 복습용) cos/sin으로 오른쪽 향하는 삼각형(▶) 만들기:
        %   angles = [0; 2*pi/3; 4*pi/3];
        %   triPoints = [triX + (TriSize/2)*cos(angles), triY + (TriSize/2)*sin(angles)];

        % [내부 루프 1] 키보드를 누를수록 삼각형이 점점 오른쪽으로 이동
        while true
            % [TODO 4 - 완료]
            triPoints = [triX - TriSize/2, triY - TriSize/2; % 왼쪽 위
                triX - TriSize/2, triY + TriSize/2;  % 왼쪽 아래
                triX + TriSize/2, triY];         % 오른쪽 끝

            Screen('FillRect', window, gray);                             % 배경
            Screen('FillRect', window, targetFillColor, targetRect);      % 반투명 영역
            Screen('FrameRect', window, targetBorderColor, targetRect, 3);% 테두리 (두께 3px)
            Screen('FillPoly', window, TriColor, triPoints);              % 삼각형

            DrawFormattedText(window, sprintf('Trial %d/%d', trial, totalTrials), 40, 40, white);
            Screen('Flip', window); % 화면에 출력

            % [TODO 5 - 완료] 키보드 입력 처리 (이동 / 제출 / 중단)
            [keyIsDown, ~, keyCode] = KbCheck;

            if keyCode(rightKey)
                % 화면 끝(screenWidth - TriSize/2)을 넘지 않도록 두 값 중 작은 값(min) 선택
                triX = min(screenWidth - TriSize/2, triX + TrimoveSpeed);
                KbReleaseWait; % 1번 누름 = 1칸 이동
            end
            if keyCode(spaceKey)
                KbReleaseWait; % 스페이스에서 손 뗄 때까지 대기 (다음 루프 오작동 방지)
                break;         % 내부 루프 1 탈출 -> 아래 [TODO 6]으로 이동
            end
            if keyCode(escKey)
                error('사용자에 의해 중단되었습니다'); % catch 블록으로 이동해 창 닫고 종료
            end
        end

        % [TODO 6 - 완료] 영역 안/밖 판정 ('correct' or 'wrong')
        % IsInRect: triX가 Left~Right 사이, triY가 Top~Bottom 사이인지 한 번에 검사 (안=1, 밖=0)
        isInside = IsInRect(triX, triY, targetRect);

        if isInside
            resultText = 'correct';
        else
            resultText = 'wrong';
        end

        % [내부 루프 2 - 완료] 결과 표시 후 오직 스페이스 키로만 다음 시행 넘어가기
        RestrictKeysForKbCheck([spaceKey, escKey]);
        while true
            DrawFormattedText(window, resultText, 'center', 'center', white);
            Screen('Flip', window);

            [keyIsDown, ~, keyCode] = KbCheck;
            if keyCode(escKey)
                error('사용자에 의해 중단되었습니다');
            end
            if keyCode(spaceKey)
                KbReleaseWait;
                break; % 내부 루프 2만 탈출 -> 아래 결과 기록으로 이동
            end
        end
        RestrictKeysForKbCheck([]);

        % [TODO 8-1 - 완료] 이번 시행 결과 기록 및 절반 지점 휴식
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

    %% [Part 4] 결과 저장 (CSV 파일 내보내기)
    % [TODO 8-2 - 완료]
    colNames = {'Trial', 'FinalTriX', 'FinalTriY', 'TargetL', 'TargetT', 'TargetR', 'TargetB', 'Result'};
    resultTable = cell2table(results, 'VariableNames', colNames);
    writetable(resultTable, 'week8_result.csv');
    % (선택) 매번 덮어쓰기 방지를 원할 때:
    %   timeStr = string(datetime('now', 'Format', 'yyyyMMdd_HHmmss'));
    %   writetable(resultTable, sprintf('week8_result_%s.csv', timeStr));

    %% [Part 5] 정상 종료 및 자원 해제
    RestrictKeysForKbCheck([]);
    KbQueueRelease;
    sca;
    ShowCursor;
    disp('Experiment successfully finished');

catch info
    % 에러 발생 시 화면 먹통 방지 및 안전한 리소스 복구
    fclose('all');
    RestrictKeysForKbCheck([]);
    KbQueueRelease;
    sca;
    ShowCursor;
    rethrow(info);
end
