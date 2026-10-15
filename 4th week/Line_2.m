
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

    %% 그리드 설정
    numCols = 5;
    numRows = 4;
    numLines = 20;

    cellW = windowRect(3) / numCols;
    cellH = windowRect(4) / numRows;

    %% Task 1. 랜덤 선분 20개 그리기
    for screenIdx = 1:6

        xy_mat = zeros(2, numLines * 2);
        color_mat = zeros(3, numLines * 2);

        % 셀 번호 무작위 선택
        cellOrder = randperm(20);

        for i = 1:numLines

            % 셀 번호를 행과 열로 변환
            row = floor((cellOrder(i)-1) / numCols);
            col = mod(cellOrder(i)-1, numCols);

            % 셀 중앙에 선분 배치
            cx = (col + 0.5) * cellW;
            cy = (row + 0.5) * cellH;

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
