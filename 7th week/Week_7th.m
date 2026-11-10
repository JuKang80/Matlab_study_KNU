%% =========================================================================
% [Week 7th] 과제 실습 - 사각형 크기 확대 및 랜덤 색상 변경 (마우스 입력 기반)
% 
% [문제]
% 화면이 전환될 때마다 점점 크기가 커지며 색이 랜덤으로 변하는 사각형을 그리세요.
% 화면 전환 방식은 마우스 입력으로 설정하세요.
% 
% =========================================================================
% [실습 가이드]
% 사용자가 직접 생각하며 코드를 완성할 수 있도록 뼈대와 힌트(TODO 1 ~ TODO 5)만
% 제공되어 있습니다. 각 TODO의 힌트를 참고하여 직접 코드를 채워보세요!
% =========================================================================

% [기본설정 1] 이전 작업 환경 및 화면 초기화
clear;
clc;
close all;
sca;

% [기본설정 2] Psychtoolbox 환경 설정
Screen('Preference', 'SkipSyncTests', 1);
PsychDefaultSetup(1);

try
    % 1. 화면 및 중심 좌표 설정
    screens = Screen('Screens');
    screenNumber = max(screens);
    white = WhiteIndex(screenNumber);
    black = BlackIndex(screenNumber);
    gray = white / 2;

    [window, windowRect] = Screen('OpenWindow', screenNumber, gray);
    Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');
    Screen('TextSize', window, 22);

    screenWidth = windowRect(3);
    screenHeight = windowRect(4);

    % 사각형이 화면 정중앙에 위치하도록 중심점 정의
    centerX = screenWidth / 2;
    centerY = screenHeight / 2;

    % ---------------------------------------------------------------------
    % [TODO 1] 사각형의 초기 크기, 증가 단위, 초기 색상 변수 정의하기
    % 
    % 힌트:
    % 1. 사각형의 한 변의 길이(폭/높이)를 저장할 변수를 만드세요. (예: rectSize = 50;)
    % 2. 클릭할 때마다 얼마나 커질지 정하는 증가량을 정의하세요. (예: sizeStep = 30;)
    % 3. 처음에 보여줄 초기 RGB 색상 [R, G, B]를 정의하세요. (예: [255, 0, 0])
    % ---------------------------------------------------------------------
    % rectSize = ____________________;
    % sizeStep = ____________________;
    % rectColor = ___________________;

    % 키보드 비동기 큐 시작 (ESC 종료 감지용)
    KbQueueCreate;
    KbQueueStart;

    % 메인 애니메이션 루프
    while true
        % -----------------------------------------------------------------
        % [TODO 2] [중요] 화면 정중앙(centerX, centerY)에서 점점 커지는 사각형 좌표 계산
        % 
        % [원리 설명]
        % 좌상단(0,0)을 고정하고 키우면 사각형이 오른쪽 아래로만 커지게 됩니다.
        % 사각형이 "화면 중앙에서 사방으로 균등하게 팽창"하려면,
        % 매 스텝마다 사각형의 중심을 (centerX, centerY)에 고정시켜야 합니다.
        % 
        % PTB의 좌표 형식: [Left, Top, Right, Bottom]
        % 
        % [방법 A: 직접 사칙연산 계산]
        % - Left   = centerX - (rectSize / 2);
        % - Top    = centerY - (rectSize / 2);
        % - Right  = centerX + (rectSize / 2);
        % - Bottom = centerY + (rectSize / 2);
        %
        % [방법 B: PTB 내장 함수 CenterRectOnPointd 활용 (강력 추천)]
        % - baseRect = [0, 0, rectSize, rectSize];
        % - rectCoords = CenterRectOnPointd(baseRect, centerX, centerY);
        % -----------------------------------------------------------------
        % rectCoords = [_________________________________________________];

        % -----------------------------------------------------------------
        % [TODO 3] 사각형 및 안내 텍스트 화면에 그리기
        % 
        % 힌트:
        % 1. 배경을 지우려면: Screen('FillRect', window, gray);
        % 2. 사각형을 그리려면: Screen('FillRect', window, rectColor, rectCoords);
        % 3. 안내 문구 출력: DrawFormattedText를 사용해 "Click Mouse to Grow (ESC to exit)" 등을 표시
        % 4. 모니터로 송출: Screen('Flip', window);
        % -----------------------------------------------------------------
        % Screen('FillRect', ____________________________________________);
        % Screen('FillRect', ____________________________________________);
        % DrawFormattedText(_____________________________________________);
        % Screen('Flip', ________________________________________________);

        % -----------------------------------------------------------------
        % [TODO 4] 마우스 클릭(화면 전환) 대기 및 디바운싱(손 뗄 때까지 대기)
        % 
        % 힌트:
        % 1. GetMouse(window) 함수로 마우스 버튼 상태(buttons)를 가져올 수 있습니다.
        % 2. 사용자가 클릭할 때까지 while 루프를 돌며 기다리세요:
        %       while ~any(buttons)
        %           [~, ~, buttons] = GetMouse(window);
        %           ... (대기 중 ESC 키가 눌렸는지 KbQueueCheck로 확인) ...
        %           WaitSecs(0.01);
        %       end
        % 3. [중요!] 마우스 버튼을 길게 누르고 있을 때 사각형이 순식간에 커지는 것을
        %    방지하려면, 사용자가 마우스에서 손을 뗄 때까지 대기해야 합니다:
        %       while any(buttons)
        %           [~, ~, buttons] = GetMouse(window);
        %           WaitSecs(0.01);
        %       end
        % -----------------------------------------------------------------
        
        % [마우스 클릭 감지 로직 작성 공간]


        % -----------------------------------------------------------------
        % [TODO 5] 사각형 크기 증가 및 랜덤 색상 변경
        % 
        % 힌트:
        % 1. 크기 증가: rectSize에 sizeStep을 더해주세요.
        % 2. 랜덤 색상: RGB 각 채널은 0~255 사이의 정수입니다.
        %    randi([0, 255], 1, 3)을 사용하면 1행 3열의 새로운 랜덤 RGB 색상이 생성됩니다!
        % 3. (선택 팁) 사각형이 화면 높이(screenHeight)보다 커지면 너무 커서 화면을 넘어가므로,
        %    if문으로 최대 크기를 제한하거나 초기 크기로 리셋해주는 예외 처리를 넣으면 더 좋습니다.
        % -----------------------------------------------------------------
        % rectSize = ____________________;
        % rectColor = ___________________;

    end

    % 정상 종료 자원 해제
    KbQueueRelease;
    sca;
    ShowCursor;
    disp('Experiment finished.');

catch info
    % 오류 또는 비정상 종료 시 자원 안전 반환
    KbQueueRelease;
    sca;
    ShowCursor;
    rethrow(info);
end
