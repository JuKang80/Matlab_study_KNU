%% 2. 도형끼리 겹치지 않도록 위치를 설정해 주세요. 원 2개, 삼각형 2개, 사각형 2개, 오각형 2개, 육각형 2개를 그리세요.
% 5초마다 사진을 찍어서 저장하세요(타이머가 5초일 때, 10초일 때, 15초일때, ..)

% 우선, 색은 특정 색 하나로 고정하자(랜덤한 한 색 뽑으면 될것같다). 
% 그리고, 도형끼리 겹치지 않기 위해선 그리드 형식을 채택하는게 좋을것 같다. 
% 10개를 그려야 하는데, 각 도형에 해당하는 것을 먼저 저장하자. 
% 그 후 Shape_1에서와 비슷하게 제시하는데 위치에 대한 것을 그리드로 설정하는 코드로 바꾸면 될것 같다.
% 크기는 이전 코드 그대로 옮겨와 사용하자. 
% 스크린샷은 새로운 파일로 5초마다 한장씩, 일단 1분까지만 설정하고 찍자. 


% 기본설정 1
clear;
clc;
close all;
sca;

% 기본설정 2
Screen('Preference', 'SkipSyncTests', 1);
PsychDefaultSetup(1);

try
    screens = Screen('Screens');
    screenNumber = max(screens);
    white = WhiteIndex(screenNumber);
    black = BlackIndex(screenNumber);
    gray = white / 2;
    % 색 지정 및 바탕화면 색 지정

    [window, windowRect] = Screen('OpenWindow', screenNumber, gray);
    Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');
    Screen('Flip', window);


    gridX = linspace(windowRect(3) * 0.1, windowRect(3) * 0.9, 4);
    gridY = linspace(windowRect(4) * 0.2, windowRect(4) * 0.8, 4);
    [X, Y] = meshgrid(gridX, gridY);
    allRooms = [X(:), Y(:)];

    ShapeTypes =[0, 0, 4, 4, 3, 3, 5, 5, 6, 6];


    chosenRooms = allRooms(randperm(16, 10), :);
    sz = double(randi([50, 100], 10, 1));
    singleColor = randi([0 255], 3, 1);

    KbQueueCreate;
    KbQueueStart;

    for timer = 1:20 % 1초씩 올라가는 것이다. 원하는 만큼 올리면 된다. 

        for i = 1:10 % 그림을 미리 그려놓는 것이 좋을 것 같아 10번 루프를 돈다. 
            n = ShapeTypes(i); % i번째 그릴 그림의 종류(꼭짓점 개수)를 가져온다. 
            cx = chosenRooms(i, 1); % 랜덤한 방 중 i번째 방의 X 중심 좌표 가져온다. 
            cy = chosenRooms(i, 2); % 랜덤한 방 중 i번째 방의 Y 중심 좌표 가져온다. 

            if n == 0 % 꼭짓점 개수가 없다면 꼭짓점 개수를 360개로 하여 원처럼 보이게 한다. 
                rect = [cx - sz(i)/2, cy - sz(i)/2, cx + sz(i)/2, cy + sz(i)/2];
                Screen('FillOval', window, singleColor, rect);
                
            else
                r = sz(i) / 2; % 반지름을 구하기 위해 도형 크기를 반으로 나눈다. 
                theta = linspace(0, 2*pi, n+1)'; % 숫자를 일정한 간격으로 나누어준다. 0부터 시작하여 어디까지? 360도까지, 그리고 언제까지? n+1, 즉 꼭짓점 개수까지 나누어준다. 삼각형은 꼭짓점이 세개, 사각형은 4개, ... 그래서 각 도형에 맞는 꼭짓점 개수만큼 나누어준다. 
                % 그리고 세로줄로 변형해준다. 
                every_points = [cx + r*cos(theta), cy + r*sin(theta)];
                % 각도를 x,y좌표로 변형하기 위해 cos, sin을 이용한다. 
                Screen('FillPoly', window, singleColor, every_points);        
            end 
        end

        infoText = sprintf('Time Passed: %ds / 20s\n\n [Press ESC to Quit]', timer);
        DrawFormattedText(window, infoText, 50, 50, white);

        Screen('Flip', window);

        if mod(timer, 5) == 0
            imageArray = Screen('GetImage', window);

            filename = sprintf('screenshot_%ds.png', timer);
            imwrite(imageArray, filename);
        end
        WaitSecs(1);

        [pressed, firstPress] = KbQueueCheck;
        if pressed && firstPress(KbName('ESCAPE'))
            error('사용자가 ESC를 눌러 종료했습니다.') % error로 만들어 catch로 빠져나가게 한다. 
        end
    end   
    
    KbQueueRelease;
    sca;
    ShowCursor;
    disp('Experiment successfully finished');

catch info
    KbQueueRelease;
    sca;
    ShowCursor;
    rethrow(info);
end