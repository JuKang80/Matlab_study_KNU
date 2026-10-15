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

    %% 1. 키보드를 누르면 색, 길이, 방위, 위치가 랜덤하게 변하는 20개의 선분을 그리세요. 전환 횟수는 최소 5회입니다.

    %% 화면을 칸으로 나누기
    numCols = 5; % 화면을 가로 방향으로 5칸으로 나눈다.
    numRows = 4; % 화면을 세로 방향으로 4칸으로 나눈다.
    numLines = 20; % 제시할 자극 20개를 선언한다.

    cellW = windowRect(3) / numCols; % 화면 너비를 5칸으로 나누어 한 칸의 너비를 구한다.
    cellH = windowRect(4) / numRows; % 화면 높이를 4칸으로 나누어 한 칸의 높이를 구한다.

    for screenIdx = 1:6 % 화면 전환 횟수 (현재 6개 화면을 제시한다.)
        xy_mat = zeros(2, numLines * 2); % 선분을 담을 행렬 선언.
        color_mat = zeros(3, numLines * 2); % 색 랜덤을 담기 위한 행렬 선언.

        %% 20개의 칸을 중복 없이 랜덤한 순서로 선택한다.
        cellOrder = randperm(numLines); % 1부터 20까지의 숫자를 중복 없이 랜덤하게 섞는다.

        for i = 1:numLines
            angle = rand * 360;
            lineLen = 50 + rand * 100; % 50부터 150 미만 랜덤한 길이를 가진다.
            RandColor = rand(1, 3) * 255; % 색 랜덤 설정.

            %% 선분을 배치할 칸의 행과 열을 계산한다.
            row = floor((cellOrder(i)-1) / numCols);
            col = mod(cellOrder(i)-1, numCols);
            % cellOrder(i)는 랜덤하게 선택된 칸 번호이다.
            % 1부터 20까지의 칸 번호를 행과 열의 위치로 바꿔준다.
            % row는 세로 방향의 칸 위치, col은 가로 방향의 칸 위치를 나타낸다.
            % 여기서 row와 col은 화면 위치를 계산하기 위한 번호이며, MATLAB 배열의 인덱스를 의미하는 것은 아니다.

            %% 각 칸 안에서 선분의 중심 위치를 랜덤하게 정한다.
            cx = (col + rand) * cellW;
            cy = (row + rand) * cellH;
            % col과 row를 이용하여 선분이 들어갈 칸을 정한다.
            % rand는 0 이상 1 미만의 랜덤한 숫자를 만든다.
            % 따라서 선분의 중심이 칸의 정중앙에만 고정되지 않고, 칸 안에서 랜덤하게 바뀐다.
            % cellW는 한 칸의 너비, cellH는 한 칸의 높이를 의미한다.

            idx = (i-1)*2 + 1;

            %% 각각 선분 길이 좌표 구하는 코드
            % xy_mat(1, idx) = cx - (lineLen/2) * sind(angle);
            % xy_mat(2, idx) = cy - (lineLen/2) * cosd(angle);
            % xy_mat(1, idx+1) = cx + (lineLen/2) * sind(angle);
            % xy_mat(2, idx+1) = cy + (lineLen/2) * cosd(angle);

            %% 다른 방식 1
            % 선분의 반 길이를 x, y 방향으로 변환
            % [dx, dy] = pol2cart(deg2rad(90-angle), lineLen/2);
            % 극좌표를 x,y 형태 좌표로 바꾼다(직교좌표라고 함).
            % 레이더같이, x축으로 얼마만큼 이동, y축으로 얼마만큼 이동 이런 걸 극좌표라 하는데
            % 그것을 선분을 그리기 위해 직교좌표 형태로 바꾸어 준다.
            % 움직일 거리는 선분의 반 길이이므로 lineLen/2를 사용한다.
            % degree(각도)를 radian으로 바꾸어 주는데,
            % 그 바꾸는 값이 90-angle이다. 이것의 이유는 아래와 같다.
                % pol2cart(theta, r), 이 함수에서 theta는 각도(단위가 라디안), r은 원점에서 떨어진 거리,
                % 그리고 내뱉는 값이 [x, y]로 변환된 가로, 세로 좌표이다.
                % 내가 사용한 angle은 rand * 360으로 정의했다. 이것을 라디안 단위로 변환해야 한다.
                % 그리고 왜 90-angle을 했냐면, 내가 원래 설계한 코드는 0도를 세로로 생각했지만
                % pol2cart는 가로 직선에서 0도로 출발하여 계산하기 위해 사용했다.

            % 선분의 양 끝점 좌표 계산
            % xy_mat(:, idx)   = [cx-dx; cy-dy];
            % xy_mat(:, idx+1) = [cx+dx; cy+dy];

            %% 또 다른 방법
            % 선분의 반 길이를 x, y 방향으로 계산
            dx = (lineLen/2) * sind(angle);
            dy = (lineLen/2) * cosd(angle);

            % 선분의 양 끝점 좌표 계산
            % cx: 선분의 x좌표, cy: 선분의 y좌표
            % dx: 중심에서 끝점까지 x방향 이동량, dy: 중심에서 끝점까지 y방향 이동량
            % xy_mat : 선분 좌표를 저장하는 행렬
            % (:, idx) : idx번째 열의 모든 행
            % [cx-dx; cy-dy] : x좌표와 y좌표를 세로로 묶은 값. x좌표 아래에, 즉 다음 행에 y값을 넣는다.
                % 이렇게 되면 2개 열씩 자리를 차지하며 DrawLines를 할 준비를 할 수 있다.
            xy_mat(:, idx)   = [cx-dx; cy-dy];
            xy_mat(:, idx+1) = [cx+dx; cy+dy];

            color_mat(:, idx) = RandColor';
            color_mat(:, idx+1) = RandColor';
        end

        Screen('FillRect', window, gray);

        Screen('DrawLines', window, xy_mat, 2, color_mat, [0 0], 0);
        Screen('Flip', window);

        %% 2. 전환 횟수만큼의 사진 파일을 만드세요. 각각의 화면을 사진 파일로 저장하시면 됩니다.
        % ex) 첫 화면: pic1 / 두 번째 화면: pic2
        Screenshot = Screen('GetImage', window);
        fileName = sprintf('pic%d.png', screenIdx);
        imwrite(Screenshot, fileName);

        KbStrokeWait;

    end

    sca;
    ShowCursor;
    disp('Experiment successfully finished');

    %% [사진 저장 위치: 현재 폴더 or 사진 전용 폴더]

catch info
    sca;
    ShowCursor;
    rethrow(info);
end