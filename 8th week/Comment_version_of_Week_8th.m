% =========================================================================
% [8주차 과제] Windows 버전 상세 주석 해설본 (Comment_version_of_Week_8th.m)
% =========================================================================
% [전체 진행 논리 지도 (Big Picture)]
%   Part 1. 환경 초기화 & Windows 창 열기 (도화지 준비)
%   Part 2. 실험 설정 & 변수 선언 (키 코드, 삼각형, 타겟 영역, 빈 결과표)
%   Part 3. 메인 시행 루프 (for trial = 1:totalTrials, 총 10회 반복)
%       ├─ (1) 초기 위치 배치: 삼각형(왼쪽), 타겟(오른쪽 중앙)
%       ├─ (2) [내부 루프 1] 방향키로 오른쪽 이동 -> 스페이스 누르면 break
%       ├─ (3) 영역 안/밖 판정: IsInRect -> 'correct' or 'wrong'
%       ├─ (4) [내부 루프 2] 결과 띄우고 오직 스페이스만 대기 -> break
%       ├─ (5) 결과 1줄 기록: results(trial, :)
%       └─ (6) 절반(5회) 지나면 [내부 루프 3] 휴식 화면 대기 -> break
%   Part 4. 결과 표(Table) 변환 & CSV 파일 저장
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
    TrimoveSpeed = 8;             % 방향키 1회 누를 때 오른쪽으로 이동하는 거리(px)
    TriColor = [255, 255, 255];   % 삼각형 색상: 흰색 [R, G, B]

    % [R, G, B, Alpha] 4개 값 사용 (Alpha 0=완전투명, 255=완전불투명)
    targetFillColor = [0, 220, 120, 80];    % 반투명 초록색 채우기
    targetBorderColor = [0, 220, 120, 255]; % 선명한 초록색 테두리
    targetWidth = 180;
    targetHeight = 180;

    % [cell(행, 열)]
    % - 인수: (1) 행 개수 totalTrials(10), (2) 열 개수 8
    % - 결과: 숫자(좌표)와 문자열('correct'/'wrong')을 한 표에 섞어 담을 수 있는 10x8 빈 셀 배열 생성
    results = cell(totalTrials, 8);

    %% [Part 3] 메인 실험 루프 (총 totalTrials 회 시행 반복)
    % [진행 논리] 바깥 for문 1바퀴 = 실험 1시행(Trial). 10바퀴를 모두 돌면 Part 4(파일 저장)로 넘어감.
    for trial = 1:totalTrials

        % -----------------------------------------------------------------
        % (1) 삼각형 & 특정 영역 초기 위치 배치
        % -----------------------------------------------------------------
        triX = 150;     % 삼각형은 매 시행 왼쪽(X=150)에서 출발
        triY = centerY; % Y좌표는 화면 세로 정중앙에 고정

        % [randi([최솟값, 최댓값])]
        % - 인수: 정수 범위 [min, max] (round(centerX)로 소수점 해상도 에러 방지)
        % - 적용: 화면 중앙(centerX)부터 오른쪽 여백 전(screenWidth - 150) 사이에서 무작위 정수 1개 추출
        % - 결과: 타겟 영역 중심 X좌표(targetX) 결정
        targetX = randi([round(centerX), screenWidth - 150]);
        targetY = centerY; % 1차원 오른쪽 이동 과제이므로 타겟 Y좌표도 중앙으로 맞춤

        % [CenterRectOnPointd(기준사각형, 중심X, 중심Y)]
        % - 인수: (1) [0, 0, 너비, 높이] 크기 상자, (2) 옮길 중심 X, (3) 옮길 중심 Y
        % - 적용: 180x180 상자를 (targetX, targetY) 중심으로 이동
        % - 결과: [Left, Top, Right, Bottom] 4개 좌표가 담긴 targetRect 반환
        targetRect = CenterRectOnPointd([0, 0, targetWidth, targetHeight], targetX, targetY);

        % -----------------------------------------------------------------
        % (2) [내부 루프 1] 삼각형 이동 구간 (스페이스 누를 때까지 반복)
        % [진행 논리] 사람이 스페이스바를 누를 때까지 무한 반복하며 매 순간 화면을 새로 그림.
        %             스페이스바를 누르면 break로 이 while문만 빠져나와 (3) 판정으로 이동.
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

            % 오른쪽 화살표 키가 눌렸다면(1이면) 좌표 이동
            if keyCode(rightKey)
                % [min(값1, 값2)]
                % - 인수: (1) 오른쪽 끝 한계선(screenWidth - TriSize/2), (2) 이동 후 위치(triX + TrimoveSpeed)
                % - 결과: 두 값 중 작은 쪽을 택해 삼각형이 화면 오른쪽 벽 밖으로 나가지 못하게 제한
                triX = min(screenWidth - TriSize/2, triX + TrimoveSpeed);

                % [KbReleaseWait]
                % - 인수: 없음
                % - 결과: 누른 키에서 손가락을 뗄 때까지 멈춰 기다림 -> 1번 누름 = 1칸 이동 구현
                KbReleaseWait;
            end

            % 스페이스바를 누르면 현재 위치로 제출하고 이동 루프 종료
            if keyCode(spaceKey)
                KbReleaseWait; % 손을 뗄 때까지 기다려야 바로 뒤 [내부 루프 2]가 연달아 통과되지 않음
                break;         % 가장 가까운 while문([내부 루프 1])만 탈출 -> (3) 판정 단계로 이동
            end

            % ESC 키를 누르면 즉시 에러를 발생시켜 catch 블록(안전 종료)으로 점프
            if keyCode(escKey)
                error('사용자에 의해 중단되었습니다');
            end
        end

        % -----------------------------------------------------------------
        % (3) 영역 안/밖 판정 ('correct' or 'wrong')
        % -----------------------------------------------------------------
        % [IsInRect(점X, 점Y, 사각형)]
        % - 인수: (1) 삼각형 최종 X좌표 triX, (2) 최종 Y좌표 triY, (3) 타겟 사각형 targetRect
        % - 결과: 점이 사각형 경계 안에 들어있으면 1(true), 밖이면 0(false) 반환
        isInside = IsInRect(triX, triY, targetRect);

        if isInside
            resultText = 'correct';
        else
            resultText = 'wrong';
        end

        % -----------------------------------------------------------------
        % (4) [내부 루프 2] 결과 표시 후 오직 스페이스 키로만 다음 시행 넘어가기
        % [진행 논리] 허용 키를 스페이스·ESC로 잠근 뒤, 스페이스가 눌릴 때까지 무한 대기.
        %             break로 탈출하자마자 키 잠금을 해제([])해야 다음 시행 방향키가 작동함!
        % -----------------------------------------------------------------
        % [RestrictKeysForKbCheck(허용키배열)]
        % - 인수: 검사할 키 번호 목록 [spaceKey, escKey]
        % - 결과: 목록에 없는 다른 키를 눌러도 KbCheck가 전부 0으로 무시함
        RestrictKeysForKbCheck([spaceKey, escKey]);
        while true
            % 'center', 'center'를 넘기면 화면 정중앙에 resultText('correct' 또는 'wrong') 출력
            DrawFormattedText(window, resultText, 'center', 'center', white);
            Screen('Flip', window);

            [keyIsDown, ~, keyCode] = KbCheck;
            if keyCode(escKey)
                error('사용자에 의해 중단되었습니다');
            end
            if keyCode(spaceKey)
                KbReleaseWait;
                break; % [내부 루프 2] 탈출 -> (5) 결과 기록으로 이동
            end
        end
        % 인수 [] (빈 배열) 전달 -> 모든 키 입력 제한 해제 (다음 시행에서 방향키 정상 작동)
        RestrictKeysForKbCheck([]);

        % -----------------------------------------------------------------
        % (5) 이번 시행 결과 1줄 기록
        % -----------------------------------------------------------------
        % results(trial, :) = { ... }
        % - trial번째 행의 모든 열(:)에 8가지 정보(시행번호, 최종좌표X/Y, 타겟 L/T/R/B, 정답여부)를 채움
        results(trial, :) = {trial, triX, triY, targetRect(1), targetRect(2), targetRect(3), targetRect(4), resultText};

        % -----------------------------------------------------------------
        % (6) 절반 시행이 지났을 때 휴식 시간 부여
        % [진행 논리] 현재 시행이 restTrials(5)이고 마지막 시행이 아닐 때만 [내부 루프 3] 실행
        % -----------------------------------------------------------------
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
                    break; % 휴식 대기 종료 -> 바깥 for문의 다음 시행(6회차)으로 이동
                end
            end
        end
    end

    %% [Part 4] 결과 저장 (CSV 파일 내보내기)
    % 8개 열의 제목을 cell 배열로 정의 (results의 8열과 개수·순서가 반드시 일치해야 함)
    colNames = {'Trial', 'FinalTriX', 'FinalTriY', 'TargetL', 'TargetT', 'TargetR', 'TargetB', 'Result'};

    % [cell2table(셀배열, 'VariableNames', 열이름배열)]
    % - 인수: (1) 10x8 결과 데이터 results, (2) 열 제목 colNames
    % - 결과: 엑셀 표처럼 열 제목이 달린 MATLAB Table 객체(resultTable) 생성
    resultTable = cell2table(results, 'VariableNames', colNames);

    % [writetable(테이블, 파일이름)]
    % - 인수: (1) resultTable, (2) 저장할 파일명 'week8_result.csv'
    % - 결과: 현재 작업 폴더에 엑셀/메모장 모두에서 열리는 CSV 파일 생성
    writetable(resultTable, 'week8_result.csv');

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
