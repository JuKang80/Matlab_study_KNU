% 화면이 전환될 때마다 점점 크기가 커지며 색이 랜덤으로 변하는 사각형을 그리세요.
% 화면 전환 방식은 마우스 입력으로 설정하세요.

clear;
clc;
close all;
sca;

Screen('Preference', 'SkipSyncTests', 1);
PsychDefaultSetup(1);

try
    screens = Screen('Screens');
    screenNumber = max(screens);
    white = WhiteIndex(screenNumber);
    black = BlackIndex(screenNumber);
    gray = white / 2;

    [window, windowRect] = Screen('OpenWindow', screenNumber, gray);
    Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');
    Screen('TextSize', window, 22);

    % windowRect = [0, 0, 가로해상도, 세로해상도] 배열에서 3, 4번째 값을 추출한다.
    screenWidth = windowRect(3);
    screenHeight = windowRect(4);

    % 전체 해상도를 2로 나누어 화면 정중앙 좌표 (centerX, centerY)를 계산한다.
    centerX = screenWidth / 2;
    centerY = screenHeight / 2;

    rectSize = 50;
    sizeStep = 10;
    rectColor = [255, 255, 255];

    % 키보드 입력을 제한하는 방식이 Queue로 감시하는 것보다 좋은것 같다. 
    RestrictKeysForKbCheck(KbName('ESCAPE'));

    while true
        
        baseRect = [0, 0, rectSize, rectSize]; % 배열에 저장된 값은 각각 left, top, right, bottom이다. 
        % [수학/좌표 연산] CenterRectOnPointd(baseRect, centerX, centerY):
        % 원점 기준 사각형 [0, 0, rectSize, rectSize]의 중심을 (centerX, centerY)로 평행이동시키는 함수이다.
        % 내부 수식은 [centerX - rectSize/2, centerY - rectSize/2, centerX + rectSize/2, centerY + rectSize/2] 이다.
        % (함수 끝의 'd'는 double형 실수 정밀도 연산을 의미한다.)
        rectCoords = CenterRectOnPointd(baseRect, centerX, centerY);
    
        Screen('FillRect', window, gray);
        Screen('FillRect', window, rectColor, rectCoords);
        DrawFormattedText(window, 'Click mouse to Grow(ESC to exit)', 'center', screenHeight - 50, white);
        Screen('Flip', window);
        
        buttons = 0;
        % [논리 연산] ~any(buttons):
        % - any(buttons)는 벡터 [좌, 우, 휠] 원소들의 논리합(OR) 연산으로, 하나라도 1(눌림)이면 1, 모두 0이면 0을 반환한다.
        % - ~(NOT)는 논리값을 반전시키는 연산자이므로, 모든 버튼이 0(안 눌림)일 때만 조건식이 1(true)이 되어 루프를 유지한다.
        while ~any(buttons)
            [~, ~, buttons] = GetMouse(window);
            if KbCheck
                    sca;
                    error('사용자에 의해 프로그램이 중단되었습니다.');
            end
            WaitSecs(0.01); % 0.01초마다 클릭을 감지 
        end
        WaitSecs(0.2); % 감지된 후 나오면 0.2초 휴식
        
        % [난수 생성 함수] randi([최솟값, 최댓값], 행, 열):
        % - randi([0, 1000], 1, 1)은 0~1000 범위의 무작위 정수를 1행 1열(단일 값)로 생성하는 함수이다.
        randomSize = randi([0, 1000], 1,1); 
        rectSize = rectSize + randomSize;
        % rectSize = rectSize + sizeStep;
        
        % - randi([0, 255], 1, 3)은 0~255 범위의 무작위 정수를 1행 3열 벡터 [R, G, B]로 생성하는 함수이다.
        rectColor = randi([0, 255], 1,3);
        
        if rectSize > screenHeight 
            rectSize = 50;
        end
    end

    RestrictKeysForKbCheck([]);
    sca;
    ShowCursor;
    disp('Experiment finished.');

catch info
    RestrictKeysForKbCheck([]);
    sca;
    ShowCursor;
    rethrow(info);
end
