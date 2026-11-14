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

    %% =====================================================================
    % [전체 코드의 큰 그림 (다른 언어 경험자를 위한 MATLAB / PTB 구조 요약)]
    %
    % 1. MATLAB 필수 문법 4가지 (이것만 알면 됩니다)
    %    - 인덱스는 0이 아니라 1부터 시작합니다. (for trial = 1:10)
    %    - 중괄호 {} 없이 if / for / while 블록 끝을 반드시 'end'로 닫습니다.
    %    - 대괄호 [ ] 안의 쉼표(,)는 가로(열) 연결, 세미콜론(;)은 세로(줄바꿈/행) 연결입니다.
    %      예) [1, 2; 3, 4] -> 2행 2열 행렬
    %    - 숫자 행렬 []에는 글자('correct')를 같이 넣을 수 없으므로,
    %      숫자+글자를 섞어 표로 저장할 때는 중괄호 셀 배열 {} (Python 리스트와 유사)를 씁니다.
    %
    % 2. PTB 화면 좌표계 주의점
    %    - 좌상단이 (0, 0)입니다. 오른쪽(+X), 아래쪽(+Y), 위쪽(-Y) 입니다!
    %    - 사각형(Rect)은 항상 [Left, Top, Right, Bottom] 4개 숫자로 표현합니다.
    %
    % 3. 전체 제어 흐름 (아래 보일러플레이트 while true 자리를 이 구조로 바꿉니다)
    %    for trial = 1:totalTrials          <-- 전체 시행 반복 (10회)
    %        (1) 특정 영역 & 삼각형 초기 위치 배치 [TODO 3]
    %        while true                     <-- [내부 루프 1] 방향키 이동 구간
    %            삼각형 꼭짓점 계산 & 화면 그리기 & Flip [TODO 4]
    %            방향키면 좌표 이동 / 스페이스면 릴리즈 후 break [TODO 5]
    %        end
    %        (2) 영역 안/밖 판정 ('correct' or 'wrong') [TODO 6]
    %        while true                     <-- [내부 루프 2] 스페이스 전용 대기
    %            결과 글자 띄우고, 오직 스페이스 키만 눌렸을 때 break [TODO 7]
    %        end
    %        (3) 결과 한 줄 기록 + 절반 시행이면 휴식 [TODO 8-1]
    %    end
    %    (4) 표(Table) 또는 텍스트 파일로 저장 [TODO 8-2]
    % =====================================================================

    %% [Part 2] 자극(Stimulus) 및 실험 상태 변수 정의
    % ---------------------------------------------------------------------
    % [TODO 1] 반복 횟수 설정 및 절반 휴식 타이밍 자동 연동하기
    %
    % 요구사항: "반복 횟수는 10회, 절반 지나면 휴식, 횟수 바꾸면 휴식도 자동 변경"
    %
    % - [선택지 A: 절반 기준 변수를 미리 계산해 두기] (추천: 의도가 한눈에 보임)
    %     totalTrials = 10;
    %     restTrial = floor(totalTrials / 2);
    %     % 설명: floor()는 소수점 버림 함수입니다. 10->5, 7->3처럼 홀수도 안전합니다.
    %     % 나중에 루프 끝에서: if trial == restTrial && trial < totalTrials ...
    %
    % - [선택지 B: 루프 안에서 바로 나눗셈 조건 쓰기]
    %     % 별도 변수 없이 루프 끝 조건문에 바로 floor(totalTrials / 2) 작성
    % ---------------------------------------------------------------------

    % ---------------------------------------------------------------------
    % [TODO 2] 키 코드, 삼각형/특정 영역 속성, 데이터 기록용 배열 선언하기
    %
    % 1) 키보드 키 번호 미리 뽑아두기 (PsychDefaultSetup(1) 덕분에 통일된 이름 사용)
    %    leftKey  = KbName('LeftArrow');   rightKey = KbName('RightArrow');
    %    upKey    = KbName('UpArrow');     downKey  = KbName('DownArrow');
    %    spaceKey = KbName('space');       escKey   = KbName('ESCAPE');
    %    % 팁: KbName('space')처럼 소문자 'space'를 씁니다.
    %
    % 2) 삼각형 크기·속도·색상 정하기
    %    triSize = 60;         % 삼각형 크기 (픽셀)
    %    moveSpeed = 8;        % 1프레임(키 누를 때)당 이동 픽셀
    %    triColor = [255, 255, 255];  % RGB 색상 [0~255, 0~255, 0~255]
    %
    % 3) '특정 영역(Target Zone)' 모양 및 투명도 선택지
    %    - [선택지 A: 반투명 사각형] (그리기와 진입 판정 모두 가장 간단!)
    %      * Part 1에서 BlendFunction을 켰으므로 색상에 4번째 숫자(Alpha, 0~255)를 넣으면 투명해집니다.
    %      * 예: targetColor = [0, 220, 120, 80];   % 80이면 은은한 반투명 초록색
    %      * 크기: targetW = 180; targetH = 180;
    %      * 테두리도 원하면 나중에 Screen('FrameRect', window, [0, 220, 120], targetRect, 3);
    %    - [선택지 B: 반투명 원 또는 다각형(삼각형)]
    %      * 원: Screen('FillOval', window, targetColor, targetRect)
    %      * 다각형: Screen('FillPoly', window, targetColor, targetPoints)
    %
    % 4) 결과 저장용 빈 배열(컨테이너) 준비하기
    %    - [선택지 A: Cell Array로 한 번에 표 데이터 쌓기] (가장 추천)
    %      * results = cell(totalTrials, 8);  % 시행수 x 열개수 크기의 빈 셀 표
    %      * 숫자와 문자열('correct')을 같은 표에 섞어 넣을 수 있습니다.
    %    - [선택지 B: 시행마다 동적으로 행 추가]
    %      * results = {};   % 빈 셀 배열로 시작해 매 시행마다 행을 추가
    % ---------------------------------------------------------------------
    history = []; % (보일러플레이트 기본 변수 - results 사용 시 대체 가능)

    % 비동기 키보드 입력 감지 큐 시작 (방향키/ESC를 KbCheck로 할 경우 아래 두 줄은 생략 가능)
    KbQueueCreate;
    KbQueueStart;

    %% [Part 3] 메인 루프 (현재는 보일러플레이트 대기 루프 -> 구현 시 아래 내용을 참고해 수정)
    % ---------------------------------------------------------------------
    % 구현 시작 시 아래 `while true` 줄을 `for trial = 1:totalTrials` 로 바꾸고,
    % 그 안에 [TODO 3] ~ [TODO 8-1] 순서를 채워 넣으세요.
    % ---------------------------------------------------------------------
    while true
        % -----------------------------------------------------------------
        % [TODO 3] (시행 시작) 특정 영역 위치와 삼각형 출발 위치 정하기
        %
        % 1) 특정 영역(Target Zone) 배치 선택지
        %    - [선택지 A: 매 시행 랜덤 위치] (연구용 과제에 자연스러움)
        %      * randi([최소, 최대])로 중심 좌표 (tx, ty)를 뽑습니다.
        %      * 화면 끝에서 잘리지 않게 여백(margin = 150)을 두세요:
        %        tx = randi([margin, screenWidth - margin]);
        %        ty = randi([margin, screenHeight - margin]);
        %      * 사각형 좌표 [L, T, R, B] 변환 (PTB 내장함수 한 줄):
        %        targetRect = CenterRectOnPointd([0, 0, targetW, targetH], tx, ty);
        %        (참고 파일: 7th week/Week_7th.m 39번째 줄)
        %    - [선택지 B: 고정 위치 또는 4방향 중 랜덤 선택]
        %      * 예: 좌/우/상/하 정해진 좌표 목록에서 randi([1, 4])로 선택
        %
        % 2) 삼각형 출발 위치 선택지
        %    - [선택지 A: 매 시행 화면 정중앙에서 출발] -> triX = centerX; triY = centerY;
        %    - [선택지 B: 랜덤 출발] -> randi로 뽑되, 시작부터 영역 안이면 다시 뽑기
        % -----------------------------------------------------------------

        % -----------------------------------------------------------------
        % [TODO 4] (내부 루프 1: 이동 구간) 삼각형 꼭짓점 만들기 & 화면 그리기
        %
        % [내부 루프 1 시작: while true] 를 열고 매 프레임 아래를 반복합니다.
        %
        % 1) 중심점 (triX, triY) 기준으로 삼각형 꼭짓점 3개 좌표(3행 2열 행렬) 만들기
        %    Screen('FillPoly', window, triColor, triPoints) 는 [x, y] 행렬을 받습니다.
        %    - [선택지 A: 위/좌하/우하 꼭짓점을 직접 덧셈·뺄셈] (직관적이고 판정이 쉬움!)
        %      * triPoints = [ triX,              triY - triSize/2 ; ...  % 위쪽(Y감소!)
        %                      triX - triSize/2,  triY + triSize/2 ; ...  % 왼쪽 아래
        %                      triX + triSize/2,  triY + triSize/2 ];     % 오른쪽 아래
        %      * 참고: MATLAB에서 '...'은 줄이 길 때 다음 줄로 이어 쓰는 기호입니다.
        %    - [선택지 B: 5주차 방식 (cos/sin 회전)]
        %      * angles = linspace(0, 2*pi, 4)' - pi/2;  % 주의: 마지막 점이 첫 점과 중복됨
        %      * angles = angles(1:3);                   % 꼭짓점 3개만 남기기
        %      * triPoints = [triX + (triSize/2)*cos(angles), triY + (triSize/2)*sin(angles)];
        %      * (참고 파일: 5th week/Shape_2_comment_version.m 77~83번째 줄)
        %
        % 2) 화면 그리기 순서 (나중에 그린 것이 위에 겹쳐집니다!)
        %    - 배경 칠하기: Screen('FillRect', window, gray);
        %    - 특정 영역 그리기: Screen('FillRect', window, targetColor, targetRect);
        %    - 삼각형 그리기: Screen('FillPoly', window, triColor, triPoints);
        %    - 안내 문구(시행 번호 등): DrawFormattedText(window, sprintf('Trial %d / %d', trial, totalTrials), 40, 40, white);
        %    - 모니터 출력: Screen('Flip', window);
        % -----------------------------------------------------------------

        % -----------------------------------------------------------------
        % [TODO 5] (내부 루프 1: 이동 구간) 키보드로 움직이기 & 스페이스바 탈출
        %
        % - [선택지 A: KbCheck로 누르고 있는 동안 부드럽게 연속 이동] (추천)
        %   * [keyIsDown, ~, keyCode] = KbCheck;
        %   * 설명: keyCode는 모든 키의 눌림 여부(0 또는 1)를 담은 배열입니다.
        %   * keyIsDown이 참일 때 아래처럼 독립된 if문 4개를 쓰면 대각선 이동도 됩니다:
        %       if keyCode(leftKey),  triX = triX - moveSpeed; end
        %       if keyCode(rightKey), triX = triX + moveSpeed; end
        %       if keyCode(upKey),    triY = triY - moveSpeed; end   % 화면 위쪽은 -Y!
        %       if keyCode(downKey),  triY = triY + moveSpeed; end   % 화면 아래쪽은 +Y!
        %   * 화면 밖으로 나가지 않게 제한(Clamping):
        %       triX = max(triSize/2, min(screenWidth  - triSize/2, triX));
        %       triY = max(triSize/2, min(screenHeight - triSize/2, triY));
        %   * 스페이스바를 누르면 이동 루프 종료:
        %       if keyCode(spaceKey)
        %           KbReleaseWait;   % ★ 핵심! 손가락을 뗄 때까지 기다려야
        %           break;           %    바로 뒤 TODO 7 대기 루프가 한 번에 뚫리지 않습니다!
        %       end
        %   * ESC 키 종료 처리:
        %       if keyCode(escKey), error('사용자에 의해 중단되었습니다.'); end
        %       (또는 aborted = true; break; 후 바깥 for문도 탈출)
        %
        % - [선택지 B: 한 번 누를 때마다 1칸씩 딱딱 움직이기]
        %   * 각 방향키 처리 끝에 KbReleaseWait를 넣으면 1회 누름 = 1회 이동이 됩니다.
        %   * 단, 이동 후 즉시 손을 떼야 하므로 손가락이 아플 수 있어 선택지 A를 권장합니다.
        % -----------------------------------------------------------------

        % -----------------------------------------------------------------
        % [TODO 6] (이동 루프 탈출 직후) 삼각형이 특정 영역에 들어갔는지 판정하기
        %
        % 연구 설계에 따라 "들어갔다"의 기준을 고르세요:
        % - [선택지 A: 삼각형 꼭짓점 3개가 전부 사각형 영역 안에 들어와야 인정] (엄격/정확)
        %   * targetRect는 [Left, Top, Right, Bottom] 즉 (1)=L, (2)=T, (3)=R, (4)=B 입니다.
        %   * triPoints(:, 1) 은 꼭짓점 3개의 X좌표 전부, triPoints(:, 2) 는 Y좌표 전부입니다.
        %   * all(...) 함수는 배열의 모든 값이 참일 때만 true를 반환합니다:
        %     isInside = all(triPoints(:,1) >= targetRect(1) & ...
        %                    triPoints(:,1) <= targetRect(3) & ...
        %                    triPoints(:,2) >= targetRect(2) & ...
        %                    triPoints(:,2) <= targetRect(4));
        %
        % - [선택지 B: 삼각형 중심점 (triX, triY)만 사각형 안에 있으면 인정] (간단)
        %   * PTB 내장함수 한 줄로 끝납니다:
        %     isInside = IsInRect(triX, triY, targetRect);
        %
        % - [선택지 C: 특정 영역이 원 또는 삼각형(다각형)인 경우]
        %   * 원 영역: hypot(triX - tx, triY - ty) <= targetRadius  (두 점 사이 거리 <= 반지름)
        %   * 다각형 영역: all(inpolygon(triPoints(:,1), triPoints(:,2), targetPoly(:,1), targetPoly(:,2)))
        %
        % 판정 결과를 문자열로 변환:
        %   if isInside, resultText = 'correct'; else, resultText = 'wrong'; end
        % -----------------------------------------------------------------

        % -----------------------------------------------------------------
        % [TODO 7] (내부 루프 2) correct/wrong 표시 후 오직 스페이스 키로만 넘어가기
        %
        % 요구사항: "correct/wrong이 뜨도록... 다시 스페이스 키 누르면 다음 시행
        %            (다른 키 누르면 반응 없어야 함)"
        %
        % 1) 먼저 배경 + 영역 + 삼각형 + 결과 글자('correct' 또는 'wrong')를 화면에 띄웁니다.
        %    - 팁: correct면 초록색 [0, 255, 0], wrong이면 빨간색 [255, 0, 0]으로 주면 직관적입니다.
        %    - DrawFormattedText(window, [resultText, '\n\nPress SPACE for next trial'], 'center', 'center', msgColor);
        %    - Screen('Flip', window);
        %
        % 2) 오직 스페이스바만 반응하게 기다리는 선택지
        %    - [선택지 A: RestrictKeysForKbCheck로 허용 키를 아예 잠그기] (가장 깔끔!)
        %      * RestrictKeysForKbCheck([spaceKey, escKey]);  % 이제 다른 키는 아예 무시됨!
        %      * while true
        %            [~, ~, keyCode] = KbCheck;
        %            if keyCode(spaceKey)
        %                KbReleaseWait;   % 손 뗄 때까지 대기 (다음 시행 오작동 방지)
        %                break;
        %            elseif keyCode(escKey)
        %                error('사용자에 의해 중단되었습니다.');
        %            end
        %        end
        %      * RestrictKeysForKbCheck([]);  % ★ 필수! 루프 나오자마자 잠금 해제해야 다음 시행 방향키가 작동!
        %      * (참고 파일: 7th week/Week_7th.m 34, 78번째 줄)
        %
        %    - [선택지 B: 잠금 없이 if문으로 spaceKey / escKey만 걸러내기]
        %      * RestrictKeysForKbCheck 없이 while true 안에서
        %        if keyCode(spaceKey) ... elseif keyCode(escKey) ... 만 검사
        %      * 나머지 키를 눌렀을 때는 아무 코드도 실행하지 않으므로 반응이 없습니다.
        % -----------------------------------------------------------------

        % -----------------------------------------------------------------
        % [TODO 8-1] (시행 끝) 데이터 1줄 기록하기 & 절반 시행 지나면 휴식 시간 주기
        %
        % 1) 이번 시행의 [최종 삼각형 위치, 특정 영역 위치, 결과]를 results에 저장
        %    - 선택지 A(Cell Array) 사용 시 한 줄 예시 (중괄호 {} 주의!):
        %      results(trial, :) = {trial, triX, triY, targetRect(1), targetRect(2), targetRect(3), targetRect(4), resultText};
        %    - 설명: results(trial, :) = { ... } 는 trial번째 행 전체에 숫자들과 글자를 한 번에 채웁니다.
        %
        % 2) 시행의 절반이 지났을 때 휴식 시간 부여 (TODO 1의 restTrial 변수 활용)
        %    if trial == restTrial && trial < totalTrials
        %        - [선택지 A: 정해진 시간(예: 5초) 카운트다운 자동 휴식]
        %          * for sec = 5:-1:1   % 5, 4, 3, 2, 1 순서로 1씩 감소
        %                Screen('FillRect', window, gray);
        %                DrawFormattedText(window, sprintf('Break Time: %d sec', sec), 'center', 'center', white);
        %                Screen('Flip', window);
        %                WaitSecs(1);
        %            end
        %          * (참고 파일: 6th week/Week_6th.m 153~160번째 줄)
        %        - [선택지 B: 충분히 쉰 뒤 스페이스 키를 눌러 직접 재개]
        %          * 안내 문구 띄우고 Screen('Flip', window) 후 스페이스바 입력 + KbReleaseWait 대기
        %    end
        % -----------------------------------------------------------------

        % === [보일러플레이트 기본 대기 루프: 위 TODO 구현 시 for trial 루프로 교체하세요] ===
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

    %% [Part 4] 결과 저장 (메모장 또는 엑셀 파일 내보내기)
    % ---------------------------------------------------------------------
    % [TODO 8-2] 저장된 results를 엑셀 또는 메모장으로 파일 출력하기
    %
    % - [선택지 A: writetable로 CSV 또는 엑셀(.xlsx) 저장] (가장 간단, 추천!)
    %   * 열 이름 정의:
    %     colNames = {'Trial', 'FinalTriX', 'FinalTriY', 'TargetL', 'TargetT', 'TargetR', 'TargetB', 'Result'};
    %   * 셀 배열을 MATLAB Table로 변환 후 파일로 쓰기:
    %     resultTable = cell2table(results, 'VariableNames', colNames);
    %     writetable(resultTable, 'week8_result.csv');   % 메모장과 엑셀 둘 다 바로 열림!
    %     % (진짜 엑셀 전용 포맷을 원하면 확장자만 'week8_result.xlsx'로 바꾸면 됩니다.)
    %   * (참고 파일: 6th week/Week_6th.m 189~197번째 줄)
    %
    % - [선택지 B: fopen + fprintf로 메모장(.txt)에 직접 줄 단위 쓰기]
    %   * fid = fopen('week8_result.txt', 'w');
    %   * fprintf(fid, 'Trial\tFinalTriX\tFinalTriY\tTargetL\tTargetT\tTargetR\tTargetB\tResult\n');
    %   * for i = 1:size(results, 1)
    %         fprintf(fid, '%d\t%.1f\t%.1f\t%.1f\t%.1f\t%.1f\t%.1f\t%s\n', results{i, :});
    %     end
    %   * fclose(fid);
    %   * 설명: results{i, :} 처럼 중괄호를 쓰면 i번째 행의 모든 칸이 순서대로 펼쳐져 들어갑니다!
    %   * (참고 파일: 6th week/Week_6th_KeyMouse.m 72~73, 214~219번째 줄)
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
