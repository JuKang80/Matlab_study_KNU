%% 1. 5초마다 색, 크기, 위치가 랜덤하게 변하는 10개의 도형을 그리세요.
% 전환 횟수는 최소 5회이며 타이머가 보이도록 설정해보세요. 도형의 모양은 자유입니다. 

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

    [window, windowRect] = Screen('OpenWindow', screenNumber, gray);
    Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');
    Screen('Flip', window);

    gridX = linspace(windowRect(3) * 0.1, windowRect(3) * 0.9, 4);
    gridY = linspace(windowRect(4) * 0.2, windowRect(4) * 0.8, 4);
    [X, Y] = meshgrid(gridX, gridY);
    allRooms = [X(:), Y(:)];

    KbQueueCreate;
    KbQueueStart;

    for trial = 1:20 

        centers = allRooms(randperm(16, 10), :); % 행은 비복원 추출로 산정된 값만 가져오고, 열은 전부다 가져와라(X, Y값 가져온다는 이야기)

        sz = double(randi([50, 100], 10, 1)); % 10행 1열 구조

        shapes = [centers(:,1)-sz/2, centers(:,2)-sz/2, centers(:,1)+sz/2, centers(:,2)+sz/2]'; 
        % Left, Top, Right, Bottom
        % centers의 1열에 적힌 숫자들은 X좌표, 2열에 적힌 숫자들은 Y좌표
        % 이렇게 각 left, top, right, bottom을 구하여 shapes에 값을 집어 넣고
        % transpose한다. 즉, 10행 4열 구조를 4행 10열로 바꾼다.

        colors = randi([0, 255], 3, 10);

        % chosenRoom = randperm(16, 10); 
        % cx_grid = allRooms(chosenRoom, 1)'; 
        % cy_grid = allRooms(chosenRoom, 2)';

        % jitterX = double(randi([-25, 25], 1, 10));
        % jitterY = double(randi([-25, 25], 1, 10));

        % cx = cx_grid + jitterX;
        % cy = cy_grid + jitterY;

        % sz = double(randi([50, 100], 1, 10)); % 격자 방 크기를 넘지 않게 최대 크기 살짝 조절

        % shapes = [cx-sz/2; cy-sz/2; cx + sz/2; cy + sz/2]; 

        for timer = 5:-1:1
            Screen('FillOval', window, colors, shapes)

            infoText = sprintf('Trial: %d\nTime Left: %ds', trial, timer);
            DrawFormattedText(window, infoText, 50, 50, white);

            Screen('Flip', window);
            WaitSecs(1);

            [pressed, firstPress] = KbQueueCheck; 
            if pressed && firstPress(KbName('ESCAPE'))
                    error('사용자가 ESC를 눌러 종료했습니다.')
            end
        end
    end

    KbQueueRelease;
    sca;
    ShowCursor;
    disp('Experiment successfully finished');

catch info
    sca;
    ShowCursor;
    rethrow(info);
end