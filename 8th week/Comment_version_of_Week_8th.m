% =========================================================================
% [8주차 과제] Windows 버전 상세 주석 해설본 — 전체 정답 치트시트 (Comment_version_of_Week_8th.m)
% =========================================================================
% [전체 진행 논리 지도 (Big Picture)]
%   Part 1. 환경 초기화 & Windows 창 열기 (도화지 준비)
%   Part 2. 실험 설정 & 변수 선언 (키 코드, 삼각형, 타겟 영역, 9열 빈 결과표, 중도종료 플래그)
%   Part 3. 시작 안내 화면 & 메인 시행 루프 (for trial = 1:totalTrials, 총 10회 반복)
%       ├─ (0) 시작 안내 화면: 'Press SPACE to start' (KbWait 대기)
%       ├─ (1) 초기 위치 배치: 삼각형(왼쪽), 타겟(오른쪽 영역 내 X·Y 무작위) & RT 시작 시각 기록
%       ├─ (2) [내부 루프 1] 4방향 이동(→←↑↓) -> 스페이스 누르면 RT 기록 후 break / ESC면 중도종료 플래그
%       ├─ (3) 영역 안/밖 판정: 꼭짓점 3개 전부 포함(엄격 판정) -> 'correct' or 'wrong' + 색상 분기
%       ├─ (4) [결과 피드백] 타겟+삼각형+결과 문구를 1회만 Flip -> RestrictKeys + KbWait로 스페이스만 대기
%       ├─ (5) 결과 1줄 기록: results(trial, :) (RT 포함 9열) & completedTrials 갱신
%       └─ (6) 절반(5회) 지나면 휴식 화면 대기 (RestrictKeys + KbWait)
%   Part 4. 완료된 시행분만 Table 변환 & 날짜/시간 CSV 저장 + 완료 안내 화면
%   Part 5. 정상 종료 및 에러 시 안전 복구 (try / catch)
% =========================================================================

%% [Part 1] 기본 환경 초기화 및 Windows용 PTB 설정
% - clear: 작업 공간(Workspace)의 기존 변수 모두 삭제
% - clc: 명령 창(Command Window) 출력 내용 깨끗이 지우기
% - close all: 열려 있는 일반 MATLAB 그래프 창 모두 닫기
% - sca: Screen('CloseAll')의 약자로, 열려 있는 PTB 실험 창 모두 닫기
clear;
clc;
close all;
sca;

% [Screen('Preference', 설정이름, 값)]
% - 인수: (1) 바꿀 설정 이름 문자열, (2) 적용할 숫자/옵션
% - 적용: 'SkipSyncTests'에 1 전달 (Windows 일반 모니터/듀얼 모니터 환경에서 주사율 동기화 검사 경고로 멈추는 현상 방지)
% - 결과: 동기화 테스트를 건너뛰고 바로 실험 창을 띄울 수 있음
% - (참고) Intel Mac(macOS Ventura 등)에서 실행할 때는 boilerplate/Boilerplate_IntelMac.m의
%   4종 호환 세팅(SkipSyncTests=2, TextRenderer=0, VisualDebugLevel=1, ConserveVRAM=64)과 창 모드(true)를 사용
Screen('Preference', 'SkipSyncTests', 1);

% [PsychDefaultSetup(featureLevel)]
% - 인수: 초기화 수준 숫자 (0, 1, 2 중 선택)
% - 적용: 1 전달 -> PTB 정상 설치 확인 + KbName('UnifyKeyNames') 자동 실행
% - 결과: Windows/Mac 어디서나 'space', 'RightArrow', 'ESCAPE' 같은 공통 키 이름을 쓸 수 있게 통일됨
PsychDefaultSetup(1);

% [진행 논리] try ~ catch: 실험 중 에러가 나더라도 화면이 먹통으로 굳지 않게 보호하는 안전 울타리
try
    % ---------------------------------------------------------------------
    % 1-1. 모니터 번호 및 기본 색상값 정의
    % ---------------------------------------------------------------------
    % [Screen('Screens')]
    % - 인수: 없음
    % - 결과: 연결된 모니터 번호 배열 반환 (예: 메인 모니터만 있으면 [0], 듀얼이면 [0, 1, 2])
    screens = Screen('Screens');

    % [max(screens)]
    % - 인수: 모니터 번호 배열
    % - 결과: 가장 큰 번호 선택 (듀얼 모니터면 보조 모니터, 단일 모니터면 0번)
    screenNumber = max(screens);

    % [WhiteIndex(screenNumber) / BlackIndex(screenNumber)]
    % - 인수: 모니터 번호
    % - 결과: 해당 화면에서 흰색(보통 255)과 검은색(보통 0)을 뜻하는 숫자 반환
    white = WhiteIndex(screenNumber);
    black = BlackIndex(screenNumber);
    gray = white / 2; % 흰색과 검은색의 중간값(약 127.5)을 배경 회색으로 사용

    % ---------------------------------------------------------------------
    % 1-2. 실험 화면 창 열기 및 그래픽/텍스트 옵션 설정
    % ---------------------------------------------------------------------
    % 전체 화면(false)이 기본이며, 코드 테스트 중 창 모드로 보고 싶을 때만 true로 변경
    useWindowedMode = false;

    % [Screen('OpenWindow', 모니터번호, 배경색, [창크기좌표])]
    % - 인수: (1) screenNumber, (2) 초기 배경색 gray, (3) (선택) [Left, Top, Right, Bottom] 창 영역
    % - 적용: useWindowedMode가 true면 [0, 0, 1280, 800] 작은 창, false면 전체 화면
    % - 결과: window(앞으로 그림 그릴 도화지 ID)와 windowRect([0, 0, 가로, 세로] 크기 배열) 반환
    if useWindowedMode
        [window, windowRect] = Screen('OpenWindow', screenNumber, gray, [0, 0, 1280, 800]);
    else
        [window, windowRect] = Screen('OpenWindow', screenNumber, gray);
    end

    % [Screen('BlendFunction', 창ID, 소스비율, 대상비율)]
    % - 인수: (1) window, (2) 새 그림 투명도 기준, (3) 기존 배경 투명도 기준
    % - 적용: 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA' 조합 (표준 알파 블렌딩 공식)
    % - 결과: 색상에 4번째 숫자(알파값 0~255)를 넣었을 때 반투명하게 겹쳐 보이도록 활성화
    Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');

    % [Screen('TextSize', 창ID, 폰트크기)]
    % - 인수: (1) window, (2) 글자 크기(px)
    % - 적용: 24px 설정 -> 이후 DrawFormattedText로 그리는 모든 글자가 24 크기로 출력됨
    Screen('TextSize', window, 24);

    % ---------------------------------------------------------------------
    % 1-3. 화면 해상도 및 정중앙 좌표 추출
    % ---------------------------------------------------------------------
    % windowRect는 [Left, Top, Right, Bottom] 4개 숫자로 구성됨 (좌상단이 (0, 0))
    screenWidth = windowRect(3);  % 3번째 값(Right) = 화면 전체 가로 길이
    screenHeight = windowRect(4); % 4번째 값(Bottom) = 화면 전체 세로 길이

    % [RectCenter(rect)]
    % - 인수: [Left, Top, Right, Bottom] 4개짜리 사각형 배열
    % - 적용: windowRect 전체 화면 영역 전달
    % - 결과: 정중앙 좌표 [centerX, centerY] 두 개를 계산해 반환
    [centerX, centerY] = RectCenter(windowRect);

    %% [Part 2] 실험 설정 및 변수 정의
    % ---------------------------------------------------------------------
    % 2-1. 시행 횟수 및 휴식 타이밍 (횟수를 바꿔도 절반 지점이 자동 연동됨)
    % ---------------------------------------------------------------------
    totalTrials = 10;
    restTrials = floor(totalTrials / 2); % 총 시행을 2로 나눈 몫(10 -> 5, 홀수여도 정수로 안전)

    % ---------------------------------------------------------------------
    % 2-2. 키보드 키 코드 미리 변환해 두기
    % ---------------------------------------------------------------------
    % [KbName(키이름)]
    % - 인수: 키보드 키를 나타내는 표준 문자열 (예: 'RightArrow', 'space', 'ESCAPE')
    % - 결과: 해당 키의 고유 번호(정수 인덱스)를 반환 -> 루프 안에서 매번 찾지 않아 빠름
    leftKey = KbName('LeftArrow');
    rightKey = KbName('RightArrow');
    upKey = KbName('UpArrow');
    downKey = KbName('DownArrow');
    spaceKey = KbName('space');
    escKey = KbName('ESCAPE');

    % ---------------------------------------------------------------------
    % 2-3. 삼각형 및 특정 영역(Target Zone) 속성 정의
    % ---------------------------------------------------------------------
    TriSize = 60;                 % 삼각형 전체 가로/세로 폭(px)
    % [이동 거리 설정] KbReleaseWait(1회 누름=1칸) 방식이므로 50px로 쾌적하게 이동
    % - (참고) KbReleaseWait를 빼고 꾹 눌러 연속 이동하려면 8~10px 정도로 낮추는 것이 적당함
    TrimoveSpeed = 50;            % 방향키 1회 누를 때 이동하는 거리(px)
    TriColor = [255, 255, 255];   % 삼각형 색상: 흰색 [R, G, B]

    % [R, G, B, Alpha] 4개 값 사용 (Alpha 0=완전투명, 255=완전불투명)
    targetFillColor = [0, 220, 120, 80];    % 반투명 초록색 채우기
    targetBorderColor = [0, 220, 120, 255]; % 선명한 초록색 테두리
    targetWidth = 180;
    targetHeight = 180;

    % [추가] 결과 피드백 문구 색상 ([R, G, B]): 정답은 초록, 오답은 빨강으로 직관적 구분
    correctColor = [0, 255, 100];
    wrongColor = [255, 80, 80];

    % [cell(행, 열)]
    % - 인수: (1) 행 개수 totalTrials(10), (2) 열 개수 9 (기존 8열 + 반응시간 RT 1열 추가)
    % - 결과: 숫자(좌표·RT)와 문자열('correct'/'wrong')을 한 표에 섞어 담을 수 있는 10x9 빈 셀 배열 생성
    results = cell(totalTrials, 9);

    % [추가 — 중도 종료 시 부분 결과 보존 플래그]
    % - aborted: ESC를 눌렀는지 여부 (false=진행 중, true=사용자 중단)
    % - completedTrials: 실제로 판정·기록까지 완료한 시행 수 (중도 종료 시 1:completedTrials만 CSV 저장)
    aborted = false;
    completedTrials = 0;

    % [추가 — 실험 시작 전 키 초기화]
    % - 실험 실행 직전에 눌려 있던 키(예: MATLAB 실행 단축키)가 시작 화면/1회차로 넘어오지 않게 대기
    KbReleaseWait;

    %% [Part 3] 시작 안내 화면 & 메인 실험 루프 (총 totalTrials 회 시행 반복)
    % ---------------------------------------------------------------------
    % (0) [추가] 실험 시작 안내 화면 ('Press SPACE to start')
    % [진행 논리] 실행 즉시 1회차가 뜨면 참가자가 준비되지 않은 채 RT가 측정되므로,
    %             스페이스바를 누를 때까지 안내 문구를 1번만 띄워두고 대기함.
    % ---------------------------------------------------------------------
    DrawFormattedText(window, 'Press SPACE to start\n\n(Arrow keys: Move / SPACE: Submit / ESC: Quit)', 'center', 'center', white);
    Screen('Flip', window);

    % [RestrictKeysForKbCheck(허용키배열)]
    % - 인수: 검사할 키 번호 목록 [spaceKey, escKey]
    % - 결과: 목록에 없는 다른 키를 눌러도 KbCheck/KbWait가 전부 무시함
    RestrictKeysForKbCheck([spaceKey, escKey]);

    % [KbWait(deviceNumber, forWhat)]
    % - 인수: (1) [] (기본 전체 키보드), (2) 2 = "먼저 모든 키에서 손이 떼어진 뒤, 새로 키가 눌릴 때까지 대기"
    % - 적용: 위에서 RestrictKeysForKbCheck로 키를 잠갔으므로, 오직 SPACE 또는 ESC가 눌릴 때만 통과!
    % - 결과: 1번 출력 ~(눌린 시각, 미사용), 2번 출력 keyCode(방금 눌린 키의 0/1 배열)
    % - [장점] while true + KbCheck를 직접 돌리지 않아도 함수 내부에서 알아서 대기해 코드가 깔끔해짐
    [~, keyCode] = KbWait([], 2);
    KbReleaseWait; % 스페이스에서 손을 떼어야 1회차로 넘어감 (키 잔여 입력 방지)
    RestrictKeysForKbCheck([]); % 잠금 즉시 해제! (안 풀면 1회차 방향키가 먹히지 않음)

    if keyCode(escKey)
        aborted = true;
    end

    % [진행 논리] 바깥 for문 1바퀴 = 실험 1시행(Trial). 시작 화면에서 ESC를 안 눌렀을 때만 실행.
    if ~aborted
        for trial = 1:totalTrials
            % [추가] 매 시행 시작 시 이전 시행의 키 눌림 잔여(Carryover) 완전 차단
            KbReleaseWait;

            % -----------------------------------------------------------------
            % (1) 삼각형 & 특정 영역 초기 위치 배치
            % -----------------------------------------------------------------
            triX = 150;     % 삼각형은 매 시행 왼쪽(X=150)에서 출발
            triY = centerY; % Y좌표는 화면 세로 정중앙에서 출발

            % [randi([최솟값, 최댓값])]
            % - 인수: 정수 범위 [min, max] (round(centerX)로 소수점 해상도 에러 방지)
            % - 적용1: 화면 중앙(centerX)부터 오른쪽 여백 전(screenWidth - 150) 사이에서 무작위 정수 추출
            % - 결과1: 타겟 영역 중심 X좌표(targetX) 결정
            targetX = randi([round(centerX), screenWidth - 150]);

            % - 적용2 [추가 — 4방향 이동 확장]: 상단 150px ~ 하단 여백 150px 사이에서 Y좌표도 무작위 추출
            % - 결과2: 타겟이 화면 위/아래로도 매 시행 다르게 배치되어 4방향 조작이 의미 있게 작동함
            targetY = randi([150, screenHeight - 150]);

            % [CenterRectOnPointd(기준사각형, 중심X, 중심Y)]
            % - 인수: (1) [0, 0, 너비, 높이] 크기 상자, (2) 옮길 중심 X, (3) 옮길 중심 Y
            % - 적용: 180x180 상자를 (targetX, targetY) 중심으로 이동
            % - 결과: [Left, Top, Right, Bottom] 4개 좌표가 담긴 targetRect 반환
            targetRect = CenterRectOnPointd([0, 0, targetWidth, targetHeight], targetX, targetY);

            % [추가 — GetSecs: 반응시간(RT) 측정 시작 시각 기록]
            % - 인수: 없음
            % - 결과: PTB 고정밀 타이머 기준 현재 시각(초 단위 실수) 반환
            % - 적용: 이동 루프 진입 직전 시각을 찍어두고, 스페이스 제출 시각과의 차이로 RT(초) 계산
            startTime = GetSecs;

            % -----------------------------------------------------------------
            % (2) [내부 루프 1] 4방향 삼각형 이동 구간 (스페이스 누를 때까지 반복)
            % [진행 논리] 사람이 스페이스바를 누를 때까지 무한 반복하며 매 순간 화면을 새로 그림.
            %             스페이스바를 누르면 RT를 계산하고 break로 빠져나와 (3) 판정으로 이동.
            %             방향키와 스페이스/ESC를 elseif로 묶어 같은 프레임 동시 입력 충돌을 방지함.
            % -----------------------------------------------------------------
            while true
                % 삼각형 중심 (triX, triY) 기준으로 오른쪽을 향하는(▶) 꼭짓점 3개 계산 (3행 2열 [X, Y] 행렬)
                % (화면 좌표계: 오른쪽=+X, 아래쪽=+Y, 위쪽=-Y)
                triPoints = [triX - TriSize/2, triY - TriSize/2; % 1행: 왼쪽 위 꼭짓점
                             triX - TriSize/2, triY + TriSize/2; % 2행: 왼쪽 아래 꼭짓점
                             triX + TriSize/2, triY];            % 3행: 오른쪽 끝 꼭짓점

                % [Screen('FillRect', 창ID, 색상, (선택)영역)]
                % - 적용1: 영역 생략 시 창 전체를 gray로 칠해 이전 프레임 그림을 깨끗이 지움
                Screen('FillRect', window, gray);
                % - 적용2: targetRect 영역 내부를 반투명 초록색(targetFillColor)으로 채움
                Screen('FillRect', window, targetFillColor, targetRect);

                % [Screen('FrameRect', 창ID, 색상, 영역, 선두께)]
                % - 인수: 채우기 없이 테두리만 그림 (선 두께 3px)
                Screen('FrameRect', window, targetBorderColor, targetRect, 3);

                % [Screen('FillPoly', 창ID, 색상, 꼭짓점행렬)]
                % - 인수: triPoints(3x2 좌표)를 순서대로 이어 내부를 TriColor(흰색)로 채운 삼각형 그리기
                Screen('FillPoly', window, TriColor, triPoints);

                % [sprintf(서식문자열, 값1, 값2)]
                % - 인수: '%d' 자리에 정수 trial과 totalTrials를 순서대로 끼워 'Trial 1/10' 같은 문자열 생성
                % [DrawFormattedText(창ID, 문자열, X, Y, 색상)]
                % - 인수: 만든 문자열을 화면 좌상단 (40, 40) 위치에 흰색(white)으로 그림
                DrawFormattedText(window, sprintf('Trial %d/%d', trial, totalTrials), 40, 40, white);

                % [Screen('Flip', 창ID)]
                % - 인수: window
                % - 결과: 지금까지 백 버퍼(도화지)에 그린 모든 요소를 모니터 화면에 한 번에 출력
                Screen('Flip', window);

                % [KbCheck]
                % - 인수: 없음
                % - 결과: (1) keyIsDown(아무 키나 눌렸으면 1), (2) ~(시각, 미사용이라 버림), (3) keyCode(전체 키의 0/1 상태 배열)
                [keyIsDown, ~, keyCode] = KbCheck;

                % 오른쪽 화살표 키가 눌렸다면(1이면) 오른쪽(+X) 이동
                if keyCode(rightKey)
                    % [min(값1, 값2)]
                    % - 인수: (1) 오른쪽 끝 한계선(screenWidth - TriSize/2), (2) 이동 후 위치(triX + TrimoveSpeed)
                    % - 결과: 두 값 중 작은 쪽을 택해 삼각형이 화면 오른쪽 벽 밖으로 나가지 못하게 제한
                    triX = min(screenWidth - TriSize/2, triX + TrimoveSpeed);

                    % [KbReleaseWait]
                    % - 인수: 없음
                    % - 결과: 누른 키에서 손가락을 뗄 때까지 멈춰 기다림 -> 1번 누름 = 1칸 이동 구현
                    KbReleaseWait;

                % [추가] 왼쪽 화살표: 왼쪽(-X) 이동
                elseif keyCode(leftKey)
                    % [max(값1, 값2)]
                    % - 인수: (1) 왼쪽 끝 한계선(TriSize/2), (2) 이동 후 위치(triX - TrimoveSpeed)
                    % - 결과: 두 값 중 큰 쪽을 택해 삼각형 왼쪽 변이 0px 밖으로 나가지 못하게 제한
                    triX = max(TriSize/2, triX - TrimoveSpeed);
                    KbReleaseWait;

                % [추가] 위쪽 화살표: 화면 좌표계에서는 위쪽이 -Y 방향!
                elseif keyCode(upKey)
                    triY = max(TriSize/2, triY - TrimoveSpeed);
                    KbReleaseWait;

                % [추가] 아래쪽 화살표: 화면 좌표계에서는 아래쪽이 +Y 방향!
                elseif keyCode(downKey)
                    triY = min(screenHeight - TriSize/2, triY + TrimoveSpeed);
                    KbReleaseWait;

                % 스페이스바를 누르면 현재 위치로 제출하고 이동 루프 종료
                elseif keyCode(spaceKey)
                    % [추가 — 반응시간(RT) 계산] 제출 순간 시각에서 시행 시작 시각을 빼서 초(sec) 단위 RT 산출
                    rt = GetSecs - startTime;
                    KbReleaseWait; % 손을 뗄 때까지 기다려야 바로 뒤 결과 화면이 연달아 통과되지 않음
                    break;         % 가장 가까운 while문([내부 루프 1])만 탈출 -> (3) 판정 단계로 이동

                % [개선] ESC 키: error()로 강제 폭파하지 않고 aborted 플래그를 세워 완료된 시행 데이터를 보존
                elseif keyCode(escKey)
                    aborted = true;
                    KbReleaseWait;
                    break;
                end
            end

            % [진행 논리] 이동 중 ESC를 눌렀다면 미완료 시행은 판정/기록하지 않고 바깥 for문도 즉시 탈출
            if aborted
                break;
            end

            % [안전 장치] 최종 (triX, triY) 기준으로 꼭짓점 3개 좌표를 한 번 더 최신화 (판정 1프레임 오차 차단)
            triPoints = [triX - TriSize/2, triY - TriSize/2;
                         triX - TriSize/2, triY + TriSize/2;
                         triX + TriSize/2, triY];

            % -----------------------------------------------------------------
            % (3) 영역 안/밖 판정 ('correct' or 'wrong')
            % -----------------------------------------------------------------
            % [참고 — 방법 1: 중심점 기준 판정 (기존 기본 방식)]
            %   [IsInRect(점X, 점Y, 사각형)]
            %   - 인수: (1) 삼각형 최종 X좌표 triX, (2) 최종 Y좌표 triY, (3) 타겟 사각형 targetRect
            %   - 결과: 점이 사각형 경계 안에 들어있으면 1(true), 밖이면 0(false) 반환
            %   예) isInside = IsInRect(triX, triY, targetRect);
            %
            % [적용 — 방법 2: 꼭짓점 3개 전부 포함 기준 (엄격 판정)]
            % - 이유: IsInRect는 단일 점(스칼라) 기준 함수라 점 3개(벡터)를 넘기면 PTB 버전에 따라 에러가 날 수 있음.
            %         따라서 요소별 비교 연산자(&)와 all(...)을 직접 조합하는 것이 가장 안전함!
            % - triPoints(:, 1): 모든 행(:)의 1열 -> 꼭짓점 3개의 X좌표 [x1; x2; x3]
            % - triPoints(:, 2): 모든 행(:)의 2열 -> 꼭짓점 3개의 Y좌표 [y1; y2; y3]
            % - targetRect(1..4): [Left(1), Top(2), Right(3), Bottom(4)]
            % - all(...): 꼭짓점 3개가 전부(ALL) 경계 안에 있을 때만 1(true), 하나라도 삐져나가면 0(false)
            isInside = all(triPoints(:, 1) >= targetRect(1) & triPoints(:, 1) <= targetRect(3) & ...
                           triPoints(:, 2) >= targetRect(2) & triPoints(:, 2) <= targetRect(4));

            if isInside
                resultText = 'correct';
                resultColor = correctColor;
            else
                resultText = 'wrong';
                resultColor = wrongColor;
            end

            % -----------------------------------------------------------------
            % (4) [결과 피드백] 결과 표시 후 오직 스페이스 키로만 다음 시행 넘어가기
            % [진행 논리] 타겟과 삼각형을 함께 다시 그려 참가자가 왜 correct/wrong인지 눈으로 확인하게 함.
            %             움직이지 않는 화면이므로 Screen('Flip')는 while 밖에서 딱 1번만 호출해야 함!
            %             (Flip을 while 안에 넣으면 2번째 프레임부터 빈 백버퍼가 뒤집혀 글자가 사라짐)
            %             RestrictKeysForKbCheck로 키를 잠갔으므로 while true 대신 KbWait([], 2) 1줄로 대기!
            % -----------------------------------------------------------------
            Screen('FillRect', window, gray);
            Screen('FillRect', window, targetFillColor, targetRect);
            Screen('FrameRect', window, targetBorderColor, targetRect, 3);
            Screen('FillPoly', window, TriColor, triPoints);

            % [sprintf('%s\n\n...', resultText)]
            % - 인수: '%s' 자리에 문자열 resultText('correct' 또는 'wrong')를 끼우고 '\n\n'으로 줄바꿈
            % - 결과: 상단에는 정답/오답 문구, 아래에는 다음 행동 안내 문구를 함께 표시
            feedbackMsg = sprintf('%s\n\nPress SPACE for next trial', resultText);
            DrawFormattedText(window, feedbackMsg, 'center', 'center', resultColor);
            Screen('Flip', window); % 고정 화면이므로 딱 1번만 Flip!

            % [RestrictKeysForKbCheck(허용키배열)]
            % - 인수: 검사할 키 번호 목록 [spaceKey, escKey]
            % - 결과: 목록에 없는 다른 키를 눌러도 KbWait가 전부 무시함
            RestrictKeysForKbCheck([spaceKey, escKey]);
            [~, keyCode] = KbWait([], 2); % SPACE 또는 ESC가 새로 눌릴 때까지 대기
            KbReleaseWait;
            % 인수 [] (빈 배열) 전달 -> 모든 키 입력 제한 해제 (다음 시행에서 방향키 정상 작동)
            RestrictKeysForKbCheck([]);

            if keyCode(escKey)
                aborted = true;
            end

            % -----------------------------------------------------------------
            % (5) 이번 시행 결과 1줄 기록
            % -----------------------------------------------------------------
            % results(trial, :) = { ... }
            % - trial번째 행의 모든 열(:)에 9가지 정보(시행번호, 최종좌표X/Y, 타겟 L/T/R/B, 정답여부, RT)를 채움
            results(trial, :) = {trial, triX, triY, targetRect(1), targetRect(2), targetRect(3), targetRect(4), resultText, rt};
            completedTrials = trial; % 완료 시행 수 갱신 (방금 판정된 시행까지 안전하게 저장 대상 포함)

            % 결과 화면에서 ESC를 눌렀다면 방금 기록한 시행까지만 저장하고 실험 종료
            if aborted
                break;
            end

            % -----------------------------------------------------------------
            % (6) 절반 시행이 지났을 때 휴식 시간 부여
            % [진행 논리] 현재 시행이 restTrials(5)이고 마지막 시행이 아닐 때만 휴식 화면 표시.
            %             결과 화면과 동일하게 RestrictKeysForKbCheck + KbWait([], 2)로 일관되게 처리함.
            % -----------------------------------------------------------------
            if trial == restTrials && trial < totalTrials
                Screen('FillRect', window, gray);
                DrawFormattedText(window, 'Break Time! Press SPACE to continue', 'center', 'center', white);
                Screen('Flip', window);

                RestrictKeysForKbCheck([spaceKey, escKey]);
                [~, keyCode] = KbWait([], 2);
                KbReleaseWait;
                RestrictKeysForKbCheck([]);

                if keyCode(escKey)
                    aborted = true;
                    break;
                end
            end
        end
    end

    %% [Part 4] 결과 저장 (날짜·시간 CSV 파일 내보내기 & 완료 안내)
    % 9개 열의 제목을 cell 배열로 정의 (results의 9열과 개수·순서가 반드시 일치해야 함)
    colNames = {'Trial', 'FinalTriX', 'FinalTriY', 'TargetL', 'TargetT', 'TargetR', 'TargetB', 'Result', 'RT'};

    % [진행 논리] 완료한 시행이 1개 이상일 때만 1:completedTrials 행을 잘라 저장
    %             (중도 종료 시 빈 행이 CSV에 섞이거나 에러 나는 현상 방지)
    if completedTrials > 0
        % [cell2table(셀배열, 'VariableNames', 열이름배열)]
        % - 인수: (1) 완료된 행만 자른 results(1:completedTrials, :), (2) 열 제목 colNames
        % - 결과: 엑셀 표처럼 열 제목이 달린 MATLAB Table 객체(resultTable) 생성
        resultTable = cell2table(results(1:completedTrials, :), 'VariableNames', colNames);

        % [datetime('now', 'Format', 서식)]
        % - 인수: 'now'(현재 시각), 'Format'으로 'yyyyMMdd_HHmmss'(예: 20261119_143000) 지정
        % - 결과: 실행할 때마다 고유한 타임스탬프 문자열을 만들어 기존 CSV 덮어쓰기 방지
        timeStr = string(datetime('now', 'Format', 'yyyyMMdd_HHmmss'));

        % [sprintf('week8_result_%s.csv', timeStr)]
        % - 인수: '%s' 자리에 timeStr 문자열 삽입
        % - 결과: 예) 'week8_result_20261119_143000.csv' 파일명 생성
        fileName = sprintf('week8_result_%s.csv', timeStr);

        % [writetable(테이블, 파일이름)]
        % - 인수: (1) resultTable, (2) 타임스탬프가 붙은 fileName
        % - 결과: 현재 작업 폴더에 엑셀/메모장 모두에서 열리는 CSV 파일 생성
        writetable(resultTable, fileName);
        fprintf('Saved %d trial(s) to %s\n', completedTrials, fileName);
    else
        disp('완료된 시행이 없어 CSV 파일을 저장하지 않았습니다.');
    end

    % [추가] 정상 완료 시 실험 종료 안내 화면 표시 (창이 갑자기 닫히지 않도록 배려)
    if ~aborted
        Screen('FillRect', window, gray);
        DrawFormattedText(window, 'Experiment Complete!\n\nPress SPACE to exit', 'center', 'center', white);
        Screen('Flip', window);

        RestrictKeysForKbCheck([spaceKey, escKey]);
        KbWait([], 2);
        KbReleaseWait;
        RestrictKeysForKbCheck([]);
    end

    %% [Part 5] 정상 종료 및 자원 해제
    RestrictKeysForKbCheck([]); % 키 입력 제한이 남아있지 않도록 초기화
    sca;                        % 열린 PTB 화면 창 모두 닫기
    ShowCursor;                 % 숨겨졌을 수 있는 마우스 커서 다시 표시
    disp('Experiment successfully finished');

catch info
    % [예외 처리] ESC 중단이나 코드 에러 발생 시 화면이 굳지 않도록 자원을 먼저 정리한 뒤 에러 보고
    fclose('all');
    RestrictKeysForKbCheck([]);
    sca;
    ShowCursor;
    rethrow(info);
end