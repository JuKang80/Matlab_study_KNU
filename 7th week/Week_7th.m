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

    screenWidth = windowRect(3);
    screenHeight = windowRect(4);

    centerX = screenWidth / 2;
    centerY = screenHeight / 2;

    rectSize = 50;
    sizeStep = 10;
    rectColor = [255, 255, 255];

    % 키보드 입력을 제한하는 방식이 Queue로 감시하는 것보다 좋은것 같다. 
    RestrictKeysForKbCheck(KbName('ESCAPE'));

    while true
        
        baseRect = [0, 0, rectSize, rectSize]; % 배열에 저장된 값은 각각 left, top, right, bottom이다. 
        rectCoords = CenterRectOnPointd(baseRect, centerX, centerY);
    
        Screen('FillRect', window, gray);
        Screen('FillRect', window, rectColor, rectCoords);
        DrawFormattedText(window, 'Click mouse to Grow(ESC to exit)', 'center', screenHeight - 50, white);
        Screen('Flip', window);
        
        buttons = 0; % 마우스의 버튼 상태를 담는 배열이다. 만약 다르게 선언한다면, [왼쪽, 휠, 오른쪽] 같이 [0, 0, 0]으로 선언할 수 있다. 
        while ~any(buttons) % any(buttons): 배열 안의 0이 아닌 값(참, true)이 하나라도 있는지 검사하는 함수이다. 
            % 그래서 마우스를 안눌렀을 때: buttons = [0 0 0] -> any의 결과는 0 (false)
            % 마우스 왼쪽을 눌렀을 때: buttons = [1 0 0] -> any 결과는 1(true)
            % ~(물결표시)는 not이다. 즉, 참과 거짓을 뒤집는다. 따라서 이 루프는 버튼이 하나도 안눌러있는 동안(아무것도 안눌린게 참인 동안) 루프를 돌며 대기하라는 뜻이다.
            [~, ~, buttons] = GetMouse(window);
            % GetMouse 함수는 [x, y, buttons]인데, x는 마우스 커서 x좌표, y는 마우스 커서 y좌표이다. 
            % 세번째 buttons는 각 마우스 버튼의 클릭 여부를 담은 1x3 벡터이다. (논리를 담음. T/F)
            % 왜 틸드(물결표시, ~)를 사용했냐면, 현재 우리의 관심사는 마우스가 눌렀는가 이다. 
            % 마우스의 위치는 관심사가 아니다. 따라서, 틸드를 통해 이 부분은 무시하겠다고 컴퓨터에게 알려준다.
            if KbCheck 
                    sca;
                    error('사용자에 의해 프로그램이 중단되었습니다.');
            end
        end

        while any(buttons) % 만약 버튼이 하나라도 눌러있는 동안, 이라는 뜻이다. 피험자가 마우스를 클릭하면 1번 루프를 통과하게 된다. 
            % 아니만 여전히 피험자의 손가락이 마우스 버튼을 누르고 있다면 이 루프로 들어와 손가락을 뗄 때까지 대기한다. 
            % 손가락을 때는 순간, buttons가 [0 0 0]이 되어서 any(buttons)가 0(false)이 되어 루프를 빠져나오고, 그 다음 코드로 넘어간다. 
            [~, ~, buttons] = GetMouse(window);
        end

        randomSize = randi([0, 100], 1,1); 
        rectSize = rectSize + randomSize;
        % rectSize = rectSize + sizeStep;
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
