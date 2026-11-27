%% =========================================================================
% [PTB Boilerplate - Windows 전용 기본 템플릿]
% 9주차 표준(KbCheck, ifi 예약 Flip, ESC 세이프 세이브)과 디버그 모드 스위치가
% 기본 탑재된 인지 실험용 뼈대 파일입니다.
%
% ※ 참고할 만한 최신 PTB-3 실험 템플릿 (구조/설계 구경용):
%    - https://github.com/GidonFrischkorn/ExpTemplate-PTB3 (행동 인지실험 표준 템플릿)
%    - https://github.com/cpp-lln-lab/CPP_PTB              (행동·EEG·fMRI 모듈형 프레임워크)
%    - https://github.com/JnsLns/ptb_experiment_template   (정신물리학 실험 템플릿)
% =========================================================================

%% [Part 1] 기본 환경 초기화 및 디버그/본 실험 모드 설정
clear;
clc;
close all;
sca;

% -------------------------------------------------------------------------
% ★ [실험 실행 전 확인 항목]
% -------------------------------------------------------------------------
subjectID   = 'S01'; % 피험자 ID (CSV 파일명 및 데이터 열에 자동 기록)
isDebugMode = true;  % true: 디버깅(전체 화면 + Sync 생략) / false: 본 실험(전체 화면 + Sync 검사)

% [난수 시드 초기화 — 필요 시 주석 해제]
% MATLAB은 재시작할 때마다 같은 난수 순서(시드 0)로 시작합니다.
% 실행마다 다른 랜덤 순서가 필요할 때 아래 줄의 주석을 해제하세요.
% rng('shuffle');

if isDebugMode
    % 디버깅/실습 시 모니터 주사율 동기화 검사 건너뛰기
    Screen('Preference', 'SkipSyncTests', 1);
else
    % 본 실험 시 정밀 타이밍 검증 활성화
    Screen('Preference', 'SkipSyncTests', 0);
end

% [선택 옵션 — 없어도 정상 작동하며, 필요할 때만 주석 해제해서 사용]
% Screen('Preference', 'VisualDebugLevel', 1); % 시작 시 깜빡이는 PTB 로고/진단 화면 생략

% PTB 기본 환경 초기화 (키보드 명칭 통일, 0~255 색상 체계 유지)
PsychDefaultSetup(1);

try
    % ---------------------------------------------------------------------
    % 1-1. 모니터 번호 및 기본 색상값 정의
    % ---------------------------------------------------------------------
    screens      = Screen('Screens');
    screenNumber = max(screens);
    white        = WhiteIndex(screenNumber);
    black        = BlackIndex(screenNumber);
    gray         = white / 2;

    % ---------------------------------------------------------------------
    % 1-2. 실험 화면 창 열기 (Windows는 디버깅 시에도 전체 화면 기본 적용)
    % ---------------------------------------------------------------------
    [window, windowRect] = Screen('OpenWindow', screenNumber, gray);

    Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA'); % 알파블렌딩
    Screen('TextSize', window, 24); % 기본 폰트 크기 설정
    HideCursor;                     % 실험 중 마우스 커서 숨기기

    % 실험 타이밍 정밀도를 위해 프로세스 우선순위 상향 (종료 시 Priority(0)로 원복)
    Priority(MaxPriority(window));

    % ---------------------------------------------------------------------
    % 1-3. 화면 해상도, 중앙 좌표 및 모니터 1프레임 시간(ifi) 추출
    % ---------------------------------------------------------------------
    screenWidth  = windowRect(3);
    screenHeight = windowRect(4);
    [centerX, centerY] = RectCenter(windowRect);
    ifi = Screen('GetFlipInterval', window); % 1프레임 갱신 간격(초)

    %% [Part 2] 실험 설정, 키보드 및 결과 기록 변수 정의
    totalTrials = 10;                    % 전체 시행 횟수
    restTrials  = floor(totalTrials / 2);% 절반 지점 휴식 기준

    % [패턴 1: 실험 시작 전 조건표(Design Matrix) 사전 생성 예시 — 필요 시 주석 해제]
    % 루프 안에서 randi로 즉석 생성하면 조건이 쏠릴 수 있으므로, 시작 전에 미리 만들어 섞습니다.
    % (단일 조건) conds = repmat([100, 200], 1, totalTrials / 2);
    %             trialConds = conds(randperm(length(conds)));
    % (복합 조건) [S, C] = ndgrid([100, 200], ["red", "blue"]);
    %             design = table(repmat(S(:), 5, 1), repmat(C(:), 5, 1), 'VariableNames', {'크기', '색상'});
    %             design = design(randperm(height(design)), :);

    % 자주 쓰는 키 이름 미리 정의
    spaceKey = KbName('space');
    escKey   = KbName('ESCAPE');

    % 중앙 응시점(+) 좌표 미리 정의
    fixCoords = [-15, 15, 0, 0; 0, 0, -15, 15];

    % [패턴 2: 결과 폴더(data/) 자동 생성 및 struct 기반 기록 준비]
    % fullfile을 쓰면 Mac('/')과 Windows('\') 경로 구분자를 자동으로 맞춰줍니다.
    dataDir = fullfile(pwd, 'data');
    if ~isfolder(dataDir)
        mkdir(dataDir);
    end
    logData = struct([]); % 이름표(필드명)로 기록하면 열 순서 실수를 방지할 수 있음

    % 실험 시작 전 눌려 있던 키 잔여 입력 방지
    KbReleaseWait;

    %% [Part 3] 시작 안내 화면
    Screen('FillRect', window, gray);
    DrawFormattedText(window, 'Press SPACE to start', 'center', 'center', white);
    Screen('Flip', window);

    RestrictKeysForKbCheck([spaceKey, escKey]);
    while true
        [~, ~, keyCode] = KbCheck;
        if keyCode(escKey)
            error('사용자에 의해 중단되었습니다.');
        end
        if keyCode(spaceKey)
            KbReleaseWait;
            break;
        end
    end
    RestrictKeysForKbCheck([]);

    %% [Part 4] 메인 실험 루프 (응시점 -> 자극 제시 & 응답 -> 기록 -> 휴식)
    for trial = 1:totalTrials
        KbReleaseWait; % 이전 시행 키 잔여(Carryover) 방지

        % 1. 응시점 제시 (0.5초)
        Screen('FillRect', window, gray);
        Screen('DrawLines', window, fixCoords, 3, white, [centerX, centerY]);
        t = Screen('Flip', window);

        % 2. 자극 그리기 및 예약 Flip (응시점 0.5초 후 출력, 실제 출력 시각 기록)
        % TODO: 과제에 맞는 자극(도형/텍스트 등)을 여기에 작성하세요.
        Screen('FillRect', window, gray);
        DrawFormattedText(window, sprintf('Trial %d / %d\n\nPress SPACE to respond (ESC to exit)', trial, totalTrials), ...
            'center', 'center', white);
        stimOnset = Screen('Flip', window, t + 0.5 - 0.5 * ifi);

        % 3. 응답 대기 루프 (RT 측정 루프 안에는 WaitSecs 금지)
        RestrictKeysForKbCheck([spaceKey, escKey]);
        while true
            [~, secs, keyCode] = KbCheck;
            if keyCode(escKey)
                error('사용자에 의해 중단되었습니다.');
            end
            if keyCode(spaceKey)
                rt = secs - stimOnset; % 반응시간 = 키 입력 시각 - 자극 실제 출력 시각
                KbReleaseWait;
                break;
            end
        end
        RestrictKeysForKbCheck([]);

        % 4. 시행 결과 1행 기록 (struct 필드명 = CSV 열 이름)
        % 정답여부는 문자열('correct'/'wrong')보다 숫자 1(정답)/0(오답)으로 기록해야
        % 추후 평균(mean)으로 정답률을 바로 계산하고 SPSS/R/Python 분석에 쓰기 좋습니다.
        isCorrect = 1; % TODO: 실제 과제 판정 조건에 따라 1(정답) 또는 0(오답) 대입
        logData(trial).피험자ID   = string(subjectID);
        logData(trial).시행번호   = trial;
        logData(trial).반응시간_초 = rt;
        logData(trial).정답여부   = isCorrect;

        % 5. 절반 지점 휴식 화면
        if trial == restTrials && trial < totalTrials
            Screen('FillRect', window, gray);
            DrawFormattedText(window, 'Break Time! Press SPACE to continue', 'center', 'center', white);
            Screen('Flip', window);

            RestrictKeysForKbCheck([spaceKey, escKey]);
            while true
                [~, ~, keyCode] = KbCheck;
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
    end

    %% [Part 5] 종료 안내 화면 (예약 Flip으로 2.0초 유지)
    Screen('FillRect', window, gray);
    DrawFormattedText(window, 'Experiment Finished! Thank you.', 'center', 'center', white);
    tEnd = Screen('Flip', window);
    Screen('FillRect', window, gray);
    Screen('Flip', window, tEnd + 2.0 - 0.5 * ifi);

    %% [Part 6] 정상 결과 저장 (data/ 폴더 + UTF-8 + 타임스탬프 덮어쓰기 방지)
    if ~isempty(logData)
        % 'AsArray', true: 1시행만 기록되어도 안전하게 표(table)로 변환
        resultTable = struct2table(logData, 'AsArray', true);
        timeStr     = string(datetime('now', 'Format', 'yyyyMMdd_HHmmss'));
        fileName    = fullfile(dataDir, sprintf('%s_result_%s.csv', subjectID, timeStr));
        writetable(resultTable, fileName, 'Encoding', 'UTF-8');
    end

    %% [Part 7] 정상 종료 및 자원 해제
    % (참고: 추후 function 기반 본 실험 코드를 작성할 때는 onCleanup으로 자동화 가능)
    RestrictKeysForKbCheck([]);
    Priority(0);
    fclose('all');
    sca;
    ShowCursor;
    disp('Experiment successfully finished');

catch info
    % [패턴 3: 실패-안전 복구] 저장보다 화면·커서·키 잠금·우선순위 복구를 무조건 먼저 실행
    RestrictKeysForKbCheck([]);
    Priority(0);
    fclose('all');
    sca;
    ShowCursor;

    % ESC 중단 또는 에러 발생 시에도 그때까지 기록된 결과 안전 저장
    if exist('logData', 'var') && ~isempty(logData)
        resultTable = struct2table(logData, 'AsArray', true);
        timeStr     = string(datetime('now', 'Format', 'yyyyMMdd_HHmmss'));
        fileName    = fullfile(dataDir, sprintf('%s_result_%s_aborted.csv', subjectID, timeStr));
        writetable(resultTable, fileName, 'Encoding', 'UTF-8');
        fprintf('중단 전까지의 결과가 저장되었습니다: %s\n', fileName);
    end

    rethrow(info);
end
