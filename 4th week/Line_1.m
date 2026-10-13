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
    Screen('Flip', window);

    %% Task 1
    numLines1 = 100;
    lineLen1 = 100;

    xy_mat1 = zeros(2, numLines1 * 2);

    for i = 1:numLines1
        cx1 = rand * windowRect(3);
        cy1 = rand * windowRect(4);
        angle = rand * 360;

        idx = (i-1)*2 + 1;

        xy_mat1(1, idx) = cx1 - (lineLen1/2) * sind(angle);
        xy_mat1(2, idx) = cy1 - (lineLen1/2) * cosd(angle);
        xy_mat1(1, idx+1) = cx1 + (lineLen1/2) * sind(angle);
        xy_mat1(2, idx+1) = cy1 + (lineLen1/2) * cosd(angle);
    end

    Screen('FillRect', window, gray);
    Screen('DrawLines', window, xy_mat1, 2, [0 0 0], [0 0], 2);
    Screen('Flip', window);

    % Save screenshot
    Screenshot = Screen('GetImage', window);
    imwrite(Screenshot, 'stimulus_output_1.png');


    KbStrokeWait;

    %% Task 2
    numLines2 = 30;
    lineLen2 = 100;

    xy_mat2 = zeros(2, numLines2 * 2);
    color_mat2 = zeros(3, numLines2 * 2);

    angle2 = [45 60 90];
    color2 = [255 0 0; 0 255 0; 0 0 255];

    lineIdx = 1;

    for i = 1:3
        currentAngle = angle2(i);
        currentColor = color2(i, :);

        for k = 1:10
            cx = rand * windowRect(3);
            cy = rand * windowRect(4);

            idx = (lineIdx-1)*2 + 1;

            xy_mat2(1, idx) = cx - (lineLen2/2) * sind(currentAngle);
            xy_mat2(2, idx) = cy - (lineLen2/2) * cosd(currentAngle);
            xy_mat2(1, idx+1) = cx + (lineLen2/2) * sind(currentAngle);
            xy_mat2(2, idx+1) = cy + (lineLen2/2) * cosd(currentAngle);

            color_mat2(:, idx) = currentColor';
            color_mat2(:, idx+1) = currentColor';

            lineIdx = lineIdx + 1;
        end
    end

    Screen('FillRect', window, gray);
    Screen('DrawLines', window, xy_mat2, 2, color_mat2, [0 0], 0);
    Screen('Flip', window);

    % Save screenshot
    Screenshot = Screen('GetImage', window);
    imwrite(Screenshot, 'stimulus_output_2.png');


    KbStrokeWait;

    %% Task 3
    xy_mat3 = zeros(2, 30*2);
    color_mat3 = zeros(3, 30*2);

    sectorWidth = windowRect(3) / 3;
    lineIdx = 1;

    for i = 1:3
        if i == 1
            currentAngle = 45;
            minX = 0;
            maxX = sectorWidth;
        elseif i == 2
            currentAngle = 60;
            minX = sectorWidth;
            maxX = sectorWidth * 2;
        else
            currentAngle = 90;
            minX = sectorWidth * 2;
            maxX = windowRect(3);
        end

        for k = 1:10
            cx = minX + rand * (maxX - minX);
            cy = rand * windowRect(4);

            randLen = 50 + rand * 100;
            randColor = rand(1, 3) * 255;

            idx = (lineIdx-1)*2 + 1;

            xy_mat3(1, idx) = cx - (randLen/2) * sind(currentAngle);
            xy_mat3(2, idx) = cy - (randLen/2) * cosd(currentAngle);
            xy_mat3(1, idx+1) = cx + (randLen/2) * sind(currentAngle);
            xy_mat3(2, idx+1) = cy + (randLen/2) * cosd(currentAngle);

            color_mat3(:, idx) = randColor';
            color_mat3(:, idx+1) = randColor';

            lineIdx = lineIdx + 1;
        end
    end

    Screen('FillRect', window, gray);
    Screen('DrawLines', window, xy_mat3, 2, color_mat3, [0 0], 0);
    Screen('Flip', window);

    KbStrokeWait;

    % Save screenshot
    Screenshot = Screen('GetImage', window);
    imwrite(Screenshot, 'stimulus_output_3.png');

    sca;
    ShowCursor;
    disp('Experiment successfully finished');

catch info
    sca;
    ShowCursor;
    rethrow(info);
end
