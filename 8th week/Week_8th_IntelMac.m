% 1. 임의의 삼각형을 하나 만들고 키보드를 이용하여 움직이게 만드세요.
% 
% 2. 삼각형이 특정 영역 내에 들어간 후, 스페이스 키를 누르면 correct, 아니면 wrong이 뜨도록 만드세요. 다시 스페이스 키를 누르면 다음 시행으로 넘어가도록 하세요(다른 키 누르면 반응 없어야 함).
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

    %% [Part 2] 자극(Stimulus) 및 실험 상태 변수 정의
    % ---------------------------------------------------------------------
    % [TODO 1] 전체 반복 횟수(numTrials) 및 절반 휴식 타이밍 설정하기
    %
    % 핵심 목표: numTrials 숫자 하나만 바꾸면 절반 지점 휴식도 자동 연동되게 설계
    % - [선택지 A: 절반 시행 변수를 미리 계산해 두기] (가독성 추천)
    %   -> numTrials = 10;
    %   -> restAfterTrial = floor(numTrials / 2);  % 홀수(예: 7 -> 3)도 안전
    %   -> 휴식 조건: if trial == restAfterTrial ...
    % - [선택지 B: 루프 끝에서 조건식으로 직접 계산하기]
    %   -> if trial == floor(numTrials / 2) && trial < numTrials ...
    %   -> 참고: numTrials = 1일 때 불필요한 휴식을 막으려면 trial < numTrials 조건 추가
    % ---------------------------------------------------------------------

    % ---------------------------------------------------------------------
    % [TODO 2] 키 코드 정의 및 삼각형 / 특정 영역(Target Zone) 속성 선언
    %
    % 1) 사용할 키 코드 정의 (KbName('UnifyKeyNames')는 PsychDefaultSetup(1)에 포함)
    %    -> 참고 파일: demo/Color_discrimination.m (40~44번째 줄)
    %    -> leftKey, rightKey, upKey, downKey: KbName('LeftArrow'), 'RightArrow', 'UpArrow', 'DownArrow'
    %    -> spaceKey = KbName('space');  /  escKey = KbName('ESCAPE');
    %
    % 2) 움직이는 삼각형 기본 속성
    %    -> 크기(triRadius 또는 triSize), 이동 속도(moveSpeed, 예: 8~15px/프레임), 색상
    %
    % 3) '특정 영역(Target Zone)' 모양과 투명도 선택지
    %    - [선택지 A: 반투명 사각형 (구현 및 판정이 가장 직관적)]
    %      -> Part 1에서 Alpha Blending이 켜져 있으므로 [R, G, B, Alpha] 4원소 색상 가능
    %      -> 예: targetColor = [0, 200, 100, 80]; (Alpha 0=완전투명 ~ 255=불투명)
    %      -> 테두리만 그리려면 Screen('FrameRect', window, color, rect, penWidth) 활용
    %    - [선택지 B: 반투명 원 또는 다각형(삼각형 등)]
    %      -> 원: Screen('FillOval') 또는 Screen('FrameOval')
    %      -> 다각형: Screen('FillPoly') 또는 Screen('FramePoly')
    %
    % 4) 결과 저장용 변수 초기화 (Cell Array 또는 수치 행렬 + 결과 문자열)
    %    -> 참고 파일: 6th week/Week_6th.m (71, 189~192번째 줄)
    % ---------------------------------------------------------------------
    history = []; % 데이터 기록용 빈 배열

    % 비동기 키보드 입력 감지 큐 시작
    KbQueueCreate;
    KbQueueStart;

    %% [Part 3] 메인 루프 (화면 전환 및 자극 제시)
    % ---------------------------------------------------------------------
    % [안내] 실제 구현 시 아래 while true 대신 'for trial = 1:numTrials' 시행 루프로
    %        바꾸고, 그 안에서 응답 대기 루프를 돌리는 구조를 권장합니다.
    %        -> 참고 파일: demo/flanker_Screen.m (36~52번째 줄: for trial = 1:...)
    % ---------------------------------------------------------------------
    while true
        % -----------------------------------------------------------------
        % [TODO 3] 매 시행(trial) 시작 시 특정 영역 및 삼각형 초기 위치 배치
        %
        % - [선택지 A: 매 시행 특정 영역 위치를 랜덤 배치 (권장)]
        %   -> 화면 밖으로 잘리지 않도록 여백(margin)을 두고 randi로 중심 좌표 생성
        %   -> 사각형 영역이라면 CenterRectOnPointd([0, 0, targetW, targetH], tx, ty) 활용
        %   -> 참고 파일: 7th week/Week_7th.m (38~39번째 줄)
        % - [선택지 B: 고정 위치 또는 미리 만든 그리드에서 추출]
        %   -> 참고 파일: 5th week/Shape_2_comment_version.m (37~46번째 줄)
        %
        % - 삼각형 출발 위치 선택지:
        %   -> [1] 매 시행 화면 정중앙 (centerX, centerY)에서 출발
        %   -> [2] 랜덤 위치에서 출발 (단, 시작부터 특정 영역 안에 들어가지 않게 주의)
        % -----------------------------------------------------------------

        % -----------------------------------------------------------------
        % [TODO 4] 현재 중심점 (triX, triY) 기준으로 삼각형 꼭짓점 계산 및 그리기
        %
        % Screen('FillPoly', window, color, pointList)는 N행 2열 [x, y] 행렬을 받습니다.
        % - [선택지 A: 극좌표(linspace + cos/sin) 방식] (5주차 학습 방식)
        %   -> n = 3; theta = linspace(0, 2*pi, n+1)' - pi/2;
        %   -> points = [triX + r*cos(theta), triY + r*sin(theta)];
        %   -> 주의: linspace(0, 2*pi, 4)는 시작/끝점이 중복된 4x2 행렬이 되므로
        %      꼭짓점 포함 판정 시 points(1:3, :)만 사용하거나 end-1 처리 필요
        %   -> 참고 파일: 5th week/Shape_2_comment_version.m (75~83번째 줄)
        % - [선택지 B: 중심 좌표에서 3개 꼭짓점을 직접 오프셋 계산]
        %   -> 위쪽 꼭짓점: [triX, triY - h/2]
        %   -> 좌하 꼭짓점: [triX - w/2, triY + h/2]
        %   -> 우하 꼭짓점: [triX + w/2, triY + h/2]
        %   -> 3행 2열 행렬로 묶으면 꼭짓점 3개가 명확해 영역 판정이 매우 쉬움
        % -----------------------------------------------------------------

        % -----------------------------------------------------------------
        % [TODO 5] 방향키로 삼각형 움직이기 & 스페이스바 입력 시 판정 단계로 이동
        %
        % - [선택지 A: KbCheck 기반 연속 이동 (누르고 있는 동안 부드럽게 이동)]
        %   -> [keyIsDown, ~, keyCode] = KbCheck;
        %   -> if keyCode(leftKey) ... elseif/if keyCode(rightKey) ...
        %   -> 참고 파일: demo/Color_discrimination.m (70~86번째 줄)
        %   -> ★ 주의(디바운싱): 스페이스바를 누르는 순간 다음 단계(TODO 7)도
        %      스페이스바 대기이므로, 루프를 빠져나가기 전에 반드시 키를 뗄 때까지
        %      대기(KbReleaseWait 또는 while KbCheck; end)해야 화면이 건너뛰지 않음!
        %      참고 파일: 7th week/Week_7th.m (62~66번째 줄), demo/flanker_Screen.m (50번째 줄)
        % - [선택지 B: KbQueueCheck 기반 이산 이동 (한 번 누를 때마다 1칸씩 이동)]
        %   -> 참고 파일: 6th week/Week_6th_KeyMouse.m (143~151번째 줄)
        %
        % - [화면 이탈 방지 팁 (Clamping)]
        %   -> triX = max(minX, min(maxX, triX)); 형태로 화면 밖 탈출 방지
        %   -> 참고 파일: 6th week/Week_6th.m (115번째 줄: min 활용)
        % -----------------------------------------------------------------

        % -----------------------------------------------------------------
        % [TODO 6] 삼각형이 특정 영역 내에 들어갔는지 판정하기 ('correct' vs 'wrong')
        %
        % '삼각형이 특정 영역 내에 들어간' 기준을 먼저 정하세요:
        % - [기준 선택지 A: 삼각형의 모든 꼭짓점(3개)이 영역 안에 완전히 포함] (엄격한 포함)
        %   -> 사각형 영역 [L, T, R, B]: 모든 x가 [L, R] 사이 AND 모든 y가 [T, B] 사이
        %   -> PTB 내장 함수 IsInRect(x, y, targetRect)를 각 꼭짓점에 적용 가능
        % - [기준 선택지 B: 삼각형의 중심점 (triX, triY)만 영역 안에 포함] (간단한 포함)
        %   -> IsInRect(triX, triY, targetRect) 한 줄로 판정
        % - [기준 선택지 C: 특정 영역도 삼각형/다각형인 경우]
        %   -> MATLAB 내장 함수 inpolygon(xq, yq, polyX, polyY) 활용
        %
        % 판정 결과에 따라 resultStr = 'correct' 또는 'wrong' 저장
        % -----------------------------------------------------------------

        % -----------------------------------------------------------------
        % [TODO 7] 결과('correct' / 'wrong') 출력 후 오직 스페이스 키로만 다음 시행 넘어가기
        %
        % 요구사항: "다시 스페이스 키를 누르면 다음 시행으로 넘어가도록 하세요
        %            (다른 키 누르면 반응 없어야 함)."
        % - [선택지 A: RestrictKeysForKbCheck 활용] (가장 깔끔한 PTB 방식)
        %   -> 대기 직전 RestrictKeysForKbCheck([spaceKey, escKey]); 설정
        %   -> 스페이스바가 눌리고 떼어질 때까지(Press & Release) 대기 후
        %      RestrictKeysForKbCheck([]); 로 키 제한 해제 (다음 시행 방향키 복구!)
        %   -> 참고 파일: 7th week/Week_7th.m (34, 78번째 줄)
        % - [선택지 B: KbCheck 루프 안에서 spaceKey / escKey만 조건문 처리]
        %   -> while true 안에서 keyCode(spaceKey)일 때만 break (그 외 키는 무시)
        %   -> 탈출 전 KbReleaseWait 또는 키 릴리즈 대기로 다음 시행 오입력 방지
        % -----------------------------------------------------------------

        % -----------------------------------------------------------------
        % [TODO 8-1] 현재 시행 결과 기록 및 절반 지점 휴식 시간 부여하기
        %
        % 1) 시행 기록 누적 (예: 시행번호, 최종 삼각형 위치, 특정 영역 위치, 결과)
        %    -> cell 배열(예: trialLogs{trial, :})이나 struct 배열 활용 추천
        % 2) 절반 시행 후 휴식 시간 부여 (TODO 1의 restAfterTrial 활용)
        %    - [선택지 A: 1초 단위 for 루프 카운트다운 휴식 (예: 5초~10초)]
        %      -> 참고 파일: 6th week/Week_6th.m (153~160, 184~186번째 줄)
        %    - [선택지 B: GetSecs 기반 실시간 타이머 휴식 (휴식 중에도 ESC 즉각 반응)]
        %      -> 참고 파일: 6th week/Week_6th_KeyMouse.m (58~66, 93~96, 115~120번째 줄)
        %    - [선택지 C: 안내 화면 띄우고 특정 키(예: 스페이스)로 휴식 종료]
        % -----------------------------------------------------------------

        % === [보일러플레이트 기본 대기 루프: 위 TODO 구현 시 시행 루프로 대체] ===
        % 1. 화면 버퍼 초기화 (배경 칠하기)
        Screen('FillRect', window, gray);

        % 2. 도형 / 선 / 텍스트 그리기
        DrawFormattedText(window, 'Press ESC to Exit', 'center', centerY, white);

        % 3. 그린 요소를 실제 화면으로 전환(Flip)
        Screen('Flip', window);

        % 4. ESC 키 강제 종료 확인
        [pressed, firstPress] = KbQueueCheck;
        if pressed && firstPress(KbName('ESCAPE'))
            break;
        end

        % 5. 프레임/타이머 대기 (필요 시 조절)
        WaitSecs(0.05);
    end

    %% [Part 4] 결과 저장 (메모장 또는 엑셀 파일 내보내기 선택지)
    % ---------------------------------------------------------------------
    % [TODO 8-2] 각 시행의 최종 삼각형 위치, 특정 영역 위치, correct or wrong 저장
    %
    % - [선택지 A: Table + writetable로 CSV / Excel(.xlsx) 저장] (가장 깔끔함)
    %   -> cell2table 또는 table(...)로 열 이름 지정:
    %      예) {'Trial', 'TriX', 'TriY', 'TargetLeft', 'TargetTop', 'TargetRight', 'TargetBottom', 'Result'}
    %   -> writetable(resultTable, 'week8_result.csv');  % 엑셀/메모장 모두 호환
    %   -> 참고 파일: 6th week/Week_6th.m (189~197번째 줄)
    % - [선택지 B: fopen + fprintf로 텍스트(.txt) / CSV 직접 쓰기]
    %   -> fid = fopen('week8_result.txt', 'w');
    %   -> fprintf로 헤더 및 각 시행 데이터 한 줄씩 출력 후 fclose(fid);
    %   -> 참고 파일: 6th week/Week_6th_KeyMouse.m (72~73, 214~219번째 줄)
    % ---------------------------------------------------------------------

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
