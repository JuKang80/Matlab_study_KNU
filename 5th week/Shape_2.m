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

    for trial = 1:12
        chosenRooms = allRooms(randperm(16, 10), :);
        sz = double(randi([50, 100], 10, 1));
        singleColor = randi([0 255], 3, 1);

        for timer = 5:-1:1
            for i = 1:10
                n = ShapeTypes(i);
                r = sz(i) / 2;
                cx = chosenRooms(i, 1);
                cy = chosenRooms(i, 2);

            if n == 0
                Screen('FillOval', window, singleColor, [cx-r, cy-r, cx+r, cy+r])
            elseif n == 4
                Screen('FillRect', window, singleColor, [cx-r, cy-r, cx+r, cy+r]);
            else
                th = linspace(0, 2*pi, n+1)';
                pts = [cx + r*cos(th), cy + r*sin(th)];
                Screen('FillPoly', window, singleColor, pts);
            end

            end
            infoText = sprintf('Trial: %d / 12\nTime Left: %ds', trial, timer);
            DrawFormattedText(window, infoText, 50, 50, white);

            Screen('Flip', window);

            if timer == 5
                imageArray = Screen('GetImage', window);

                timePaseed = trial * 5;
                filename = sprintf('screenshot_%ds.png', timePaseed);
                imwrite(imageArray, filename);
            end
            WaitSecs(1);
        end   

    end

    sca;
    ShowCursor;
    disp('Experiment successfully finished');

catch info
    sca;
    ShowCursor;
    rethrow(info);
end


