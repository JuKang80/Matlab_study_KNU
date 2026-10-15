clear;
clc;
close all;
sca;

Screen('Preference', 'SkipSyncTests', 1);
PsychDefaultSetup(1);

try
    screens = Screen('Screens');
    screenNumber = min(screens);
    white = WhiteIndex(screenNumber);
    black = BlackIndex(screenNumber);
    gray = white / 2;

    [window, windowRect] = Screen('OpenWindow', screenNumber, gray);
    Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');
    Screen('Flip', window);

    %% Task 1. 키보드를 누르면 색, 길이, 방위, 위치가 랜덤하게 변하는 20개의 선분을 그리세요. 전환 횟수는 최소 5회입니다.

    for screenIdx = 1:6
        numLines = 20;
        xy_mat = zeros(2, numLines * 2);
        color_mat = zeros(3, numLines * 2);

        for i = 1:numLines
            angle = rand * 360;
            lineLen = 50 + rand * 100;
            RandColor = rand(1, 3) * 255;
            cx = rand * windowRect(3);
            cy = rand * windowRect(4);
            idx = (i-1)*2 + 1;

            %% 방식 1. 기존 좌표 계산 방식
            % xy_mat(1, idx) = cx - (lineLen/2) * sind(angle);
            % xy_mat(2, idx) = cy - (lineLen/2) * cosd(angle);
            % xy_mat(1, idx+1) = cx + (lineLen/2) * sind(angle);
            % xy_mat(2, idx+1) = cy + (lineLen/2) * cosd(angle);

            %% 방식 2. 극좌표를 직교좌표로 변환
            % [dx, dy] = pol2cart(deg2rad(90-angle), lineLen/2);
            % xy_mat(:, idx)   = [cx-dx; cy-dy];
            % xy_mat(:, idx+1) = [cx+dx; cy+dy];

            %% 방식 3. x, y 방향 이동량을 계산하여 양 끝점 구하기
            dx = (lineLen/2) * sind(angle);
            dy = (lineLen/2) * cosd(angle);

            xy_mat(:, idx)   = [cx-dx; cy-dy];
            xy_mat(:, idx+1) = [cx+dx; cy+dy];

            color_mat(:, idx) = RandColor';
            color_mat(:, idx+1) = RandColor';
        end

        Screen('FillRect', window, gray);
        Screen('DrawLines', window, xy_mat, 2, color_mat, [0 0], 0);
        Screen('Flip', window);

        %% Task 2. 전환 횟수만큼의 사진 파일을 만드세요. 각각의 화면을 사진 파일로 저장하시면 됩니다.
        % 첫 화면: pic1.png / 두 번째 화면: pic2.png

        Screenshot = Screen('GetImage', window);
        fileName = sprintf('pic%d.png', screenIdx);
        imwrite(Screenshot, fileName);

        KbStrokeWait;
    end

    sca;
    ShowCursor;
    disp('Experiment successfully finished');

catch info
    sca;
    ShowCursor;
    rethrow(info);
end