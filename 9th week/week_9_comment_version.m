% =========================================================================
% [9주차 과제] Windows 버전 완성본 & 초상세 인자별 주석 해설본 (week_9_comment_version.m)
% =========================================================================
% [과제 목표] 원 크기 기억 및 직접 조절(Method of Adjustment) 인지실험
%   1. 중앙 고정점(0.5초) -> 랜덤 크기 원(1.0초) -> 빈 화면 ISI(0.2초)
%   2. 임의 크기의 조절용 원 등장 -> 위/아래 방향키로 크기 조절 후 SPACE로 제출
%   3. 제시 원 지름과의 오차가 허용 오차(±20px) 이내면 correct(+1), 밖이면 wrong
%   4. SPACE로 다음 시행 진행 / 절반 시행(10회) 지나면 Break Time 휴식
%   5. 최대 20회 내 누적 정답 10개 달성 시 즉시 칭찬 화면 후 종료 (미달 시 완료 안내)
%   6. 각 시행의 초기 크기·조절 크기·제시 크기·반지름·오차(부호/절대)·RT·정답 여부를 CSV 저장
%
% [전체 진행 논리 지도 (Big Picture)]
%   Part 1. 환경 초기화 & Windows용 PTB 창 열기 (도화지 준비)
%   Part 2. 실험 설정 & 변수 선언 (시행/목표치, 키 코드, 조절·오차 설정, 고정점, 빈 결과표)
%   Part 3. 시작 안내 화면 & 메인 시행 루프 (for trial = 1:totalTrials)
%       ├─ (0) 시작 안내 화면 ('Press SPACE to start') + ifi(1프레임 시간) 측정
%       ├─ (1) 제시 원 & 조절 원 크기 랜덤 생성 (초기 크기 initUserSize 별도 백업)
%       ├─ (2) 예약 Flip 타이밍 제시: 고정점(0.5초) -> 제시 원(1.0초) -> ISI(0.2초) -> 조절 원 등장
%       ├─ (3) [내부 루프 1] 위/아래 화살표로 원 크기 조절 -> SPACE 제출(RT 계산) / ESC 중단
%       ├─ (4) 오차(sizeError, abserror)·반지름 계산 & 정오답 판정
%       ├─ (5) [내부 루프 2] correct/wrong 피드백 화면 -> SPACE로 다음 시행
%       ├─ (6) 결과 1줄 기록 (10열) -> 정답 10개 달성 시 즉시 break -> 절반 지점 휴식
%   Part 4. 종료(칭찬/완료) 화면 2초 예약 Flip & 날짜/시간 타임스탬프 CSV 저장
%   Part 5. 정상 종료 및 에러 시 안전 복구 (try / catch)
% =========================================================================

%% [Part 1] 기본 환경 초기화 및 Windows용 PTB 설정
% - clear     : 작업 공간(Workspace)에 남아 있는 모든 이전 변수 삭제
% - clc       : 명령 창(Command Window)의 이전 출력 텍스트 지우기
% - close all : 일반 MATLAB Figure 창 모두 닫기
% - sca       : Screen('CloseAll')의 약자. 열려 있는 PTB 그래픽 창 모두 닫기
clear;
clc;
close all;
sca;

% [Screen('Preference', preferenceName, value)]
% - 인자 1 ('Preference')    : PTB 환경 설정을 읽거나 바꾸는 하위 명령어
% - 인자 2 ('SkipSyncTests') : 모니터 주사율 동기화 검사(Sync Test) 옵션 이름
% - 인자 3 (1)               : 1 = 동기화 검사 경고로 실험이 멈추는 것을 방지 (Windows 실습/듀얼모니터 표준)
%   ※ 참고: Intel Mac에서는 SkipSyncTests=2, TextRenderer=0, VisualDebugLevel=1, ConserveVRAM=64 추가 사용
Screen('Preference', 'SkipSyncTests', 1);

% [PsychDefaultSetup(featureLevel)]
% - 인자 1 (1) : 초기화 단계 수준 (0, 1, 2 중 선택)
%   · 0: AssertOpenGL(OpenGL 지원 확인)만 실행
%   · 1: AssertOpenGL + KbName('UnifyKeyNames') 자동 실행, 색상 체계는 기존 0~255 유지 (본 코드 채택!)
%   · 2: 위 기능 + 색상 체계를 0.0~1.0 실수 범위로 정규화 (주의: [0, 255, 100] 같은 0~255 RGB와 섞어 쓰면 색이 깨짐)
PsychDefaultSetup(1);

% [try ~ catch]
% - try 블록 실행 중 에러(또는 ESC 강제 중단)가 발생하면 즉시 catch 블록으로 점프하여
%   화면(sca)과 키보드 제한(RestrictKeysForKbCheck)을 안전하게 복구함
try
    % ---------------------------------------------------------------------
    % 1-1. 모니터 번호 및 기본 색상값 정의
    % ---------------------------------------------------------------------
    % [Screen('Screens')]
    % - 인자 : 없음
    % - 반환 : 연결된 모니터 번호 배열 (단일 모니터면 [0], 듀얼 모니터면 [0, 1, 2])
    screens = Screen('Screens');

    % [max(screens)]
    % - 인자 : 모니터 번호 배열
    % - 반환 : 가장 큰 모니터 번호 (보조 모니터가 있으면 보조 모니터, 없으면 0번 메인 모니터 선택)
    screenNumber = max(screens);

    % [WhiteIndex(screenNumber) / BlackIndex(screenNumber)]
    % - 인자 : 모니터 번호 (screenNumber)
    % - 반환 : 현재 색상 체계에서 흰색(255)과 검은색(0)에 해당하는 숫자
    white = WhiteIndex(screenNumber);
    black = BlackIndex(screenNumber);
    gray  = white / 2; % 회색 배경값 (약 127.5)

    % ---------------------------------------------------------------------
    % 1-2. 실험 화면 창 열기 및 그래픽/텍스트 옵션 설정
    % ---------------------------------------------------------------------
    % Windows 실전 실행은 전체 화면(false)이 기본.
    % 디버깅/테스트 중 창 모드로 띄우고 싶으면 true로 변경하면 됨.
    useWindowedMode = false;

    % [Screen('OpenWindow', screenNumber, color, rect)]
    % - 인자 1 ('OpenWindow') : PTB 그래픽 창을 생성하는 하위 명령어
    % - 인자 2 (screenNumber) : 창을 띄울 대상 모니터 번호
    % - 인자 3 (gray)         : 창이 열릴 때 칠해질 초기 배경색
    % - 인자 4 ([0,0,1280,800]) : (선택) 창 위치/크기 [Left, Top, Right, Bottom] 픽셀 좌표. 생략 시 전체 화면
    % - 반환 1 (window)       : 생성된 그래픽 창 고유 번호(핸들). 이후 모든 Screen 명령의 대상
    % - 반환 2 (windowRect)   : 열린 창의 실제 영역 [0, 0, 가로해상도, 세로해상도]
    if useWindowedMode
        [window, windowRect] = Screen('OpenWindow', screenNumber, gray, [0, 0, 1280, 800]);
    else
        [window, windowRect] = Screen('OpenWindow', screenNumber, gray);
    end

    % [Screen('BlendFunction', windowPtr, sourceFactor, destinationFactor)]
    % - 인자 1 ('BlendFunction')      : 투명도(Alpha) 합성 및 안티앨리어싱 활성화 명령어
    % - 인자 2 (window)               : 적용할 창 핸들
    % - 인자 3 ('GL_SRC_ALPHA')       : 새로 그릴 그림의 알파값(투명도) 반영 비율
    % - 인자 4 ('GL_ONE_MINUS_SRC_ALPHA') : 기존 배경의 잔여 비율 (1 - 알파)
    % - 효과: 도형·선·원의 테두리가 계단 현상 없이 매끄럽게 출력됨
    Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');

    % [Screen('TextSize', windowPtr, textSize)]
    % - 인자 1 ('TextSize') : 글자 크기 설정 명령어
    % - 인자 2 (window)     : 대상 창 핸들
    % - 인자 3 (24)         : 기본 글자 크기 (포인트/픽셀 단위)
    Screen('TextSize', window, 24);

    % ---------------------------------------------------------------------
    % 1-3. 화면 해상도 및 정중앙 좌표 추출
    % ---------------------------------------------------------------------
    screenWidth  = windowRect(3); % 창의 가로 길이(픽셀)
    screenHeight = windowRect(4); % 창의 세로 길이(픽셀)

    % [RectCenter(rect)]
    % - 인자 : 사각형 영역 [Left, Top, Right, Bottom] (여기서는 전체 창 windowRect)
    % - 반환 : [centerX, centerY] 해당 사각형의 정중앙 (X, Y) 픽셀 좌표
    [centerX, centerY] = RectCenter(windowRect);

    %% [Part 2] 실험 설정 및 상태 변수 정의
    % ---------------------------------------------------------------------
    % 2-1. 시행 수 및 종료 조건
    % ---------------------------------------------------------------------
    totalTrials   = 20;                    % 최대 시행 횟수 (무한 루프 방지 상한)
    restTrials    = floor(totalTrials / 2);% 절반 지점(10회) 종료 후 휴식 시간 부여 (floor: 소수점 버림)
    targetCorrect = 10;                    % 목표 정답 수 (10개 맞추면 즉시 성공 종료)
    correctCount  = 0;                     % 현재까지 누적된 정답 수 카운터

    % ---------------------------------------------------------------------
    % 2-2. 키보드 키 코드 정의
    % ---------------------------------------------------------------------
    % [KbName(keyName)]
    % - 인자 : 표준 키 이름 문자열 (PsychDefaultSetup(1) 덕분에 OS 공통 이름 사용 가능)
    % - 반환 : 해당 키의 고유 번호(정수 인덱스). KbCheck의 256칸 논리 벡터(keyCode)를 조회할 때 사용
    upKey    = KbName('UpArrow');   % 위쪽 화살표: 원 크기 키우기
    downKey  = KbName('DownArrow'); % 아래쪽 화살표: 원 크기 줄이기
    spaceKey = KbName('space');     % 스페이스바: 크기 제출 및 다음 화면 진행
    escKey   = KbName('ESCAPE');    % ESC 키: 실험 즉시 강제 중단

    % ---------------------------------------------------------------------
    % 2-3. 자극 조절·오차·고정점·색상·결과 저장 배열 설정
    % ---------------------------------------------------------------------
    sizeStep  = 3;  % 꾹 누르기(연속 조절) 모드에서 1프레임당 변하는 지름 크기(픽셀)
    tolerance = 20; % 정답 인정 오차범위: |조절 지름 - 제시 지름| <= 20px 이면 correct

    % [고정점(+) 상대 좌표 행렬 (2행 x 4열)]
    % - Screen('DrawLines')는 2열씩 짝지어 선 1개(시작점 -> 끝점)를 그림
    %   · 1행(x좌표): [-15, 15] (가로선 좌->우), [0, 0] (세로선 중앙)
    %   · 2행(y좌표): [0, 0]    (가로선 중앙),   [-15, 15] (세로선 위->아래)
    % - 원점 (0, 0) 기준으로 선언해 두고, 호출 시 center 인자로 [centerX, centerY]를 넘겨 중앙에 출력
    fixCoords = [-15, 15, 0, 0; 0, 0, -15, 15];

    % 원 색상을 흰색 단일값으로 고정 (색상 변화가 크기 기억 판단에 혼입 변인으로 작용하지 않도록 통제)
    stimulus_Circle_color = white;

    % 데이터 기록용 빈 셀 배열 ({} 사용 이유: 숫자 데이터와 문자열 'correct'/'wrong'을 한 행에 함께 저장하기 위함)
    result = {};

    %% [Part 3] 시작 안내 화면 & 메인 시행 루프
    % ---------------------------------------------------------------------
    % 3-0. 시작 안내 화면 (Landing Screen)
    % ---------------------------------------------------------------------
    % [DrawFormattedText(win, tstring, sx, sy, color)]
    % - 인자 1 (window)                 : 글자를 그릴 창 핸들
    % - 인자 2 ('Press SPACE to start') : 화면에 표시할 문자열
    % - 인자 3 ('center')               : 가로 정렬 위치 ('center' = 화면 가로 정중앙)
    % - 인자 4 ('center')               : 세로 정렬 위치 ('center' = 화면 세로 정중앙)
    % - 인자 5 (white)                  : 글자 색상
    DrawFormattedText(window, 'Press SPACE to start', 'center', 'center', white);

    % 백버퍼(안 보이는 뒷면 도화지)에 그린 안내 문구를 실제 모니터 화면으로 뒤집어 출력
    Screen('Flip', window);

    % [RestrictKeysForKbCheck(enableKeys)]
    % - 인자 : 감시할 키 코드 배열 ([spaceKey, escKey]). 빈 배열 []을 넣으면 제한 해제(모든 키 감시)
    % - 효과 : 지정한 키 외의 실수 입력을 무시하여 실험 안정성을 높임
    RestrictKeysForKbCheck([spaceKey, escKey]);
    while true
        % [KbCheck]
        % - 인자 : 없음 (기본 키보드 장치 조회)
        % - 반환 1 (keyIsDown) : 아무 키나 눌려 있으면 1, 아니면 0
        % - 반환 2 (~)         : 키가 감지된 시각(초). 여기선 쓰지 않으므로 ~로 무시
        % - 반환 3 (keyCode)   : 256개 키의 눌림 상태(0 또는 1)를 담은 논리 벡터
        [keyIsDown, ~, keyCode] = KbCheck;
        if keyCode(escKey)
            error('사용자에 의해 중단되었습니다.');
        end
        if keyCode(spaceKey)
            % [KbReleaseWait]
            % - 인자 : 없음
            % - 동작 : 참가자가 누른 키에서 손을 완전히 뗄 때까지 대기 (다음 루프로 키 입력이 넘어가는 Carryover 방지)
            KbReleaseWait;
            break;
        end
    end
    RestrictKeysForKbCheck([]); % 키 제한 해제 (이제 방향키 포함 모든 키 입력 가능)

    % =====================================================================
    % ★ [핵심 개념] ifi (Inter-Frame Interval) & 예약 Flip 타이밍 원리
    % =====================================================================
    % [Screen('GetFlipInterval', windowPtr)]
    % - 인자 1 ('GetFlipInterval') : 모니터 1프레임 갱신 간격을 조회하는 하위 명령어
    % - 인자 2 (window)            : 대상 창 핸들
    % - 반환 (ifi)                 : 모니터가 화면 1장을 새로 그리는 데 걸리는 시간(초)
    %   · 60Hz 모니터: ifi = 1/60 ≈ 0.0167초 (16.7ms)
    %   · 120Hz 모니터: ifi = 1/120 ≈ 0.0083초 (8.3ms)
    %
    % [왜 WaitSecs 대신 Screen('Flip', window, t + duration - 0.5 * ifi)를 쓰는가?]
    % 1. 모니터는 연속적으로 바뀌는 게 아니라, 매 ifi(예: 16.7ms)마다 수직동기화(VBL) 시점에만 화면을 교체함.
    % 2. t = Screen('Flip', window)가 반환하는 t는 화면이 '실제로' 모니터에 뜬 VBL 시각(초).
    % 3. 다음 화면을 정확히 duration초(예: 1.0초) 뒤에 띄우고 싶을 때,
    %    딱 t + 1.0을 요청하면 미세한 OS 지연(0.1ms)만 생겨도 해당 VBL을 놓쳐 다음 프레임(+16.7ms)으로 밀림.
    % 4. 따라서 반 프레임 일찍(t + duration - 0.5 * ifi) 깨어나도록 예약하면,
    %    PTB가 바로 다음 VBL(정확히 t + duration 시점)에 칼같이 화면을 교체해 줌!
    %    (PTB3 공식 데모 DriftDemo4.m, FastMaskedNoiseDemo.m 표준 공식)
    ifi = Screen('GetFlipInterval', window);

    % ---------------------------------------------------------------------
    % 3-1. 메인 시행 루프 (최대 totalTrials = 20회, 정답 10개 달성 시 조기 종료)
    % ---------------------------------------------------------------------
    for trial = 1:totalTrials
        % [randi([imin, imax])]
        % - 인자 : [최솟값, 최댓값] 정수 범위
        % - 반환 : 해당 범위 내 무작위 정수 1개
        targetSize   = randi([100, 300]); % 기억해야 할 제시 원의 지름 (100~300px)
        userSize     = randi([80, 320]);  % 참가자가 조절을 시작할 초기 원 지름 (80~320px)
        initUserSize = userSize;          % 조절 전 초기 크기 백업 (CSV 기록용 — 초기값 편향 분석)

        % -----------------------------------------------------------------
        % [단계 A] 고정점(+) 제시 (0.5초 유지)
        % -----------------------------------------------------------------
        % [Screen('FillRect', windowPtr, color, rect)]
        % - 인자 1 ('FillRect') : 사각형 채우기 명령어
        % - 인자 2 (window)     : 대상 창
        % - 인자 3 (gray)       : 채울 색상 (rect 인자를 생략하면 화면 전체를 gray로 덮어 초기화)
        Screen('FillRect', window, gray);

        % [Screen('DrawLines', windowPtr, xy, width, color, center)]
        % - 인자 1 ('DrawLines')        : 여러 선분을 한 번에 그리는 명령어
        % - 인자 2 (window)             : 대상 창
        % - 인자 3 (fixCoords)          : 2x4 좌표 행렬 (2열씩 선 1개: 가로선 + 세로선)
        % - 인자 4 (3)                  : 선 굵기 (3픽셀)
        % - 인자 5 (white)              : 선 색상
        % - 인자 6 ([centerX, centerY]) : 기준 중심점 (fixCoords의 (0,0)을 화면 정중앙으로 평행이동)
        Screen('DrawLines', window, fixCoords, 3, white, [centerX, centerY]);

        % [Screen('Flip', windowPtr, when)]
        % - when 인자를 생략하면 즉시 다음 프레임에 화면을 교체하고,
        %   실제 화면이 뜬 VBL 시각을 변수 t에 저장 (이후 모든 타이밍의 기준 시계 0.0초)
        t = Screen('Flip', window);

        % -----------------------------------------------------------------
        % [단계 B] 제시 원(targetSize) 1.0초 제시
        % -----------------------------------------------------------------
        Screen('FillRect', window, gray); % 백버퍼 초기화 (원 제시 중에는 고정점 숨김 -> 기준선 효과 방지)

        % [CenterRectOnPointd(rect, x, y)]
        % - 인자 1 ([0, 0, targetSize, targetSize]) : 원점 기준 정사각형 크기 [L, T, R, B] (지름 x 지름)
        % - 인자 2 (centerX)                        : 옮길 중심 X좌표
        % - 인자 3 (centerY)                        : 옮길 중심 Y좌표
        % - 반환 (targetRect)                       : 화면 중앙에 배치된 [Left, Top, Right, Bottom] 좌표
        targetRect = CenterRectOnPointd([0, 0, targetSize, targetSize], centerX, centerY);

        % [Screen('FillOval', windowPtr, color, rect)]
        % - 인자 1 ('FillOval')            : 내부가 채워진 타원/원 그리기 명령어
        % - 인자 2 (window)                : 대상 창
        % - 인자 3 (stimulus_Circle_color) : 원 색상 (white)
        % - 인자 4 (targetRect)            : 원이 딱 맞게 들어갈 사각형 영역 (가로=세로이므로 정원)
        Screen('FillOval', window, stimulus_Circle_color, targetRect);

        % 고정점이 뜬 시각 t로부터 정확히 0.5초 뒤(반 프레임 미리 예약) 제시 원 출력 -> 원 뜬 시각으로 t 갱신
        t = Screen('Flip', window, t + 0.5 - 0.5 * ifi);

        % -----------------------------------------------------------------
        % [단계 C] 빈 회색 화면 ISI (0.2초 유지 — 기억 간격)
        % -----------------------------------------------------------------
        Screen('FillRect', window, gray); % 빈 회색 도화지 준비
        % 제시 원이 뜬 시각 t로부터 정확히 1.0초 뒤 원 제거 -> 사라진 시각으로 t 갱신
        t = Screen('Flip', window, t + 1.0 - 0.5 * ifi);

        % -----------------------------------------------------------------
        % [단계 D] 조절용 원(userSize) 등장 (WaitSecs 없이 0.2초 예약 Flip)
        % -----------------------------------------------------------------
        userRect = CenterRectOnPointd([0, 0, userSize, userSize], centerX, centerY);
        Screen('FillRect', window, gray);
        Screen('FillOval', window, stimulus_Circle_color, userRect);
        % 원이 사라진 시각 t로부터 정확히 0.2초 뒤 조절 원 등장 -> 조절 시작 시각(adjustStart) 기록 (RT 계산 기준)
        adjustStart = Screen('Flip', window, t + 0.2 - 0.5 * ifi);

        % -----------------------------------------------------------------
        % [내부 루프 1] 위/아래 방향키로 원 크기 조절 (SPACE 제출 / ESC 중단)
        % -----------------------------------------------------------------
        while true
            % secs: 키 입력이 감지된 정확한 시스템 시각(초, GetSecs 기준)
            [keyIsDown, secs, keyCode] = KbCheck;

            if keyCode(upKey)
                % [min(상한, 값)] : 원이 화면 세로 높이를 넘어가 잘리지 않도록 최대 크기 제한
                userSize = min(screenHeight - 50, userSize + sizeStep);
            end
            if keyCode(downKey)
                % [max(하한, 값)] : 원이 0 이하로 사라져 에러 나지 않도록 최소 크기(20px) 보장
                userSize = max(20, userSize - sizeStep);
            end
            if keyCode(spaceKey)
                rt = secs - adjustStart; % 반응시간(RT) = 제출 시각 - 조절 원 등장 시각 (초 단위)
                KbReleaseWait;           % 스페이스에서 손 뗄 때까지 대기 (피드백 화면 즉시 통과 방지)
                break;
            end
            if keyCode(escKey)
                error('사용자에 의해 중단되었습니다.');
            end

            % 변경된 userSize로 원과 진행 상황 텍스트를 매 프레임 다시 그려 실시간 크기 변화 표시
            userRect = CenterRectOnPointd([0, 0, userSize, userSize], centerX, centerY);
            Screen('FillRect', window, gray);
            Screen('FillOval', window, stimulus_Circle_color, userRect);

            % [sprintf(formatSpec, A1, A2, ...)]
            % - 인자 1 : 서식 문자열 (%d = 정수 자리표시자)
            % - 인자 2~ : %d 자리에 순서대로 채워 넣을 변수들
            % - 반환 : 완성된 문자열 (예: 'Trial 3/20 (Correct: 2/10)')
            DrawFormattedText(window, sprintf('Trial %d/%d (Correct: %d/%d)', trial, totalTrials, correctCount, targetCorrect), 40, 40, white);
            Screen('Flip', window);
        end

        % -----------------------------------------------------------------
        % [단계 E] 반지름·오차 계산 및 정오답 판정
        % -----------------------------------------------------------------
        userRadius   = userSize / 2;   % 참가자가 맞춘 원 반지름(px)
        targetRadius = targetSize / 2; % 원래 제시되었던 원 반지름(px)

        % ※ 주의: MATLAB 내장 함수 error()를 덮어쓰면 ESC 중단 시 error(...) 호출이 깨지므로
        %         변수명은 sizeError로 두고, CSV 저장 시 컬럼 헤더를 'Error'로 지정함!
        sizeError = userSize - targetSize; % 부호 포함 오차 (+면 크게 맞춤/과대평가, -면 작게 맞춤/과소평가)
        abserror  = abs(sizeError);        % [abs(x)]: 절댓값 함수. 크기 오차의 순수 거리(px)
        isCorrect = abserror <= tolerance; % 절대 오차가 허용 오차(20px) 이하이면 정답(true)

        if isCorrect
            correctCount = correctCount + 1;
            resultColor  = [0, 255, 100]; % 초록색 (R=0, G=255, B=100)
            resultText   = 'correct';
        else
            resultColor  = [255, 80, 80]; % 빨간색 (R=255, G=80, B=80)
            resultText   = 'wrong';
        end

        % -----------------------------------------------------------------
        % [내부 루프 2] 정오답 피드백 표시 -> SPACE 누르면 다음 시행
        % -----------------------------------------------------------------
        RestrictKeysForKbCheck([spaceKey, escKey]);
        Screen('FillRect', window, gray);
        DrawFormattedText(window, resultText, 'center', 'center', resultColor);
        Screen('Flip', window);

        while true
            [keyIsDown, ~, keyCode] = KbCheck;
            if keyCode(escKey)
                error('사용자에 의해 중단되었습니다.');
            end
            if keyCode(spaceKey)
                KbReleaseWait;
                break;
            end
        end
        RestrictKeysForKbCheck([]); % ★ 필수: 다음 시행에서 방향키가 정상 작동하도록 키 제한 해제

        % -----------------------------------------------------------------
        % [단계 F] 현재 시행 결과 1줄 기록 (10개 열)
        % -----------------------------------------------------------------
        result(trial, :) = {trial, initUserSize, userSize, targetSize, userRadius, targetRadius, sizeError, abserror, rt, resultText};

        % 목표 정답(10개) 달성 시 휴식 화면 없이 즉시 루프 탈출 -> 칭찬 화면으로 이동
        if correctCount >= targetCorrect
            break;
        end

        % -----------------------------------------------------------------
        % [내부 루프 3] 절반 지점(10회) 휴식 시간
        % -----------------------------------------------------------------
        if trial == restTrials && trial < totalTrials
            Screen('FillRect', window, gray);
            DrawFormattedText(window, 'Break Time! Press SPACE to continue', 'center', 'center', white);
            Screen('Flip', window);
            RestrictKeysForKbCheck([spaceKey, escKey]);

            while true
                [keyIsDown, ~, keyCode] = KbCheck;
                if keyCode(escKey)
                    error('사용자에 의해 중단되었습니다.');
                end
                if keyCode(spaceKey)
                    KbReleaseWait;
                    break;
                end
            end
            RestrictKeysForKbCheck([]);
        end
    end % --- 메인 for trial 루프 종료 ---

    %% [Part 4] 종료(칭찬/완료) 화면 & CSV 결과 파일 저장
    Screen('FillRect', window, gray);
    if correctCount >= targetCorrect
        endText = sprintf('Great Job! You got %d correct in %d trials!', correctCount, trial);
    else
        endText = sprintf('Experiment Finished! (%d/%d correct)', correctCount, targetCorrect);
    end
    DrawFormattedText(window, endText, 'center', 'center', white);

    % WaitSecs(2) 대신 예약 Flip으로 종료 화면을 정확히 2.0초 유지한 뒤 닫기
    tEnd = Screen('Flip', window);
    Screen('FillRect', window, gray);
    Screen('Flip', window, tEnd + 2.0 - 0.5 * ifi);

    % [cell2table(C, 'VariableNames', colNames)]
    % - 인자 1 (result)          : 숫자와 문자열이 섞여 있는 N x 10 셀 배열
    % - 인자 2 ('VariableNames') : 각 열의 제목(헤더)을 지정하는 옵션 이름
    % - 인자 3 (colNames)        : 10개 열 제목 셀 배열
    % - 반환 (resultTable)       : 엑셀/CSV로 바로 내보낼 수 있는 MATLAB Table 객체
    colNames = {'Trial', 'InitUserSize', 'UserSize', 'TargetSize', 'UserRadius', 'TargetRadius', 'Error', 'AbsError', 'RT', 'Result'};
    resultTable = cell2table(result, 'VariableNames', colNames);

    % [datetime('now', 'Format', 'yyyyMMdd_HHmmss')]
    % - 현재 날짜·시각을 파일명에 붙여 실험을 여러 번 돌려도 기존 CSV가 덮어쓰이지 않게 방지
    timeStr  = string(datetime('now', 'Format', 'yyyyMMdd_HHmmss'));
    fileName = sprintf('week9_result_%s.csv', timeStr);

    % [writetable(T, filename)]
    % - 인자 1 (resultTable) : 저장할 테이블 객체
    % - 인자 2 (fileName)    : 생성할 CSV 파일 경로/이름 (엑셀에서 바로 열림)
    writetable(resultTable, fileName);

    %% [Part 5] 정상 종료 및 자원 해제
    RestrictKeysForKbCheck([]); % 키보드 감시 제한 완전 해제
    sca;                        % PTB 그래픽 창 닫기
    ShowCursor;                 % 마우스 커서 복구
    disp('Experiment successfully finished');

catch info
    % [예외 처리] 에러 또는 ESC 중단 시 반드시 rethrow(info)보다 먼저 키보드·창 자원을 복구해야 함!
    RestrictKeysForKbCheck([]);
    fclose('all'); % 혹시 열려 있는 파일 핸들 모두 닫기
    sca;
    ShowCursor;
    % [rethrow(info)]: 복구 완료 후 원래 발생한 에러 메시지를 MATLAB 명령 창에 그대로 출력
    rethrow(info);
end
