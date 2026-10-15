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

    %% 선분의 위치를 지정하기 위한 좌표 생성
    xPositions = linspace(100, windowRect(3)-100, 10);
    yPositions = linspace(100, windowRect(4)-100, 10);
    % linspace를 사용하여 화면의 가로, 세로 방향에 일정한 간격의 좌표를 만든다.
    % 화면 가장자리에서 100픽셀 안쪽부터 좌표를 생성한다.

    %% Task 1. 랜덤 선분 20개 그리기
    numLines = 20;

    for screenIdx = 1:6

        xy_mat = zeros(2, numLines * 2);
        color_mat = zeros(3, numLines * 2);

        for i = 1:numLines

            % 미리 생성한 좌표 중 하나를 무작위로 선택한다.
            cx = xPositions(randi(length(xPositions)));
            cy = yPositions(randi(length(yPositions)));
            % randi를 사용하여 좌표 목록에서 무작위 위치를 선택한다.

            % 선분의 길이, 방위, 색상 랜덤 설정
            angle = rand * 360;
            lineLen = 50 + rand * 100;
            RandColor = rand(1, 3) * 255;

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

            %% 방식 3. x, y 방향 이동량으로 양 끝점 계산
            dx = (lineLen/2) * sind(angle);
            dy = (lineLen/2) * cosd(angle);

            xy_mat(:, idx)   = [cx-dx; cy-dy];
            xy_mat(:, idx+1) = [cx+dx; cy+dy];

            % 선분 색상 지정
            color_mat(:, idx) = RandColor';
            color_mat(:, idx+1) = RandColor';

        end

        Screen('FillRect', window, gray);
        Screen('DrawLines', window, xy_mat, 2, color_mat, [0 0], 0);
        Screen('Flip', window);

        %% Task 2. 화면 이미지 저장
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