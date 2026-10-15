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

    %% 선분의 위치를 지정하기 위한 좌표 생성
    screenwidth = windowRect(3) - windowRect(1);
    screenHeight = windowRect(4) - windowRect(2);
    
    marginX = screenwidth * 0.05;
    marginY = screenHeight * 0.05;
    % 화면 가로와 세로 크기의 5%를 여백으로 설정한다. 

    xPositions = linspace(marginX, screenwidth - marginX, 20);
    yPositions = linspace(marginY, screenHeight - marginY, 20);
    % linspace는 지정한 범위 안에서 일정한 간격의 숫자를 만들어 주는 함수이다.
    % 화면 가장자리에서 각각 5% 안쪽에 10개의 좌표 후보를 생성한다. 
    
    %% Task 1. 랜덤 선분 20개 그리기
    numLines = 20; % 제시할 선분의 개수를 20개로 설정한다.

    for screenIdx = 1:6 % 화면을 총 6번 제시한다.

        xy_mat = zeros(2, numLines * 2); % 선분의 양 끝점 좌표를 저장할 행렬을 만든다.
        color_mat = zeros(3, numLines * 2); % 선분의 RGB 색상 정보를 저장할 행렬을 만든다.

        for i = 1:numLines

            %% 선분의 중심 위치를 랜덤하게 정한다.
            cx = xPositions(randi(length(xPositions)));
            cy = yPositions(randi(length(yPositions)));
            % xPositions와 yPositions에는 미리 만든 좌표 후보들이 저장되어 있다.
            % length는 좌표 후보가 몇 개 있는지 알려준다.
            % randi는 좌표 후보 중 몇 번째 값을 사용할지 무작위로 선택한다.
            % 따라서 cx는 선분의 가로 중심 좌표, cy는 선분의 세로 중심 좌표가 된다.
            % linspace로 좌표 후보를 만들고 randi로 하나를 선택하여 위치를 정한다.

            %% 선분의 길이, 방위, 색상을 랜덤하게 설정한다.
            angle = rand * 360; % 0도부터 360도 사이의 랜덤한 방위를 정한다.
            lineLen = 50 + rand * 50; % 랜덤한 길이를 정한다.
            RandColor = rand(1, 3) * 255; % RGB 색상을 랜덤하게 설정한다.

            idx = (i-1)*2 + 1;
            % 선분 하나는 양 끝점 2개로 이루어진다.
            % 따라서 선분마다 좌표 행렬의 열 2개를 사용한다.
            % idx는 해당 선분의 첫 번째 끝점이 저장될 열 번호이다.

            %% 방식 1. 기존 좌표 계산 방식
            % 선분의 중심에서 방위와 길이를 이용하여 양 끝점의 좌표를 구한다.
            % xy_mat(1, idx) = cx - (lineLen/2) * sind(angle);
            % xy_mat(2, idx) = cy - (lineLen/2) * cosd(angle);
            % xy_mat(1, idx+1) = cx + (lineLen/2) * sind(angle);
            % xy_mat(2, idx+1) = cy + (lineLen/2) * cosd(angle);

            %% 방식 2. 극좌표를 직교좌표로 변환
            % 극좌표 형태의 각도와 거리를 x, y 방향의 이동량으로 바꾼다.
            % [dx, dy] = pol2cart(deg2rad(90-angle), lineLen/2);
            % pol2cart는 각도와 거리를 x, y 좌표로 변환하는 함수이다.
            % deg2rad는 각도를 도 단위에서 라디안 단위로 바꾸는 함수이다.
            % 90-angle을 사용하는 이유는 기존 코드의 각도 기준과 pol2cart의 각도 기준을 맞추기 위해서이다.
            % lineLen/2를 사용하는 이유는 선분의 중심에서 한쪽 끝점까지의 거리를 구하기 위해서이다.

            % 선분의 양 끝점 좌표 계산
            % xy_mat(:, idx)   = [cx-dx; cy-dy];
            % xy_mat(:, idx+1) = [cx+dx; cy+dy];

            %% 방식 3. x, y 방향 이동량으로 양 끝점 계산
            dx = (lineLen/2) * sind(angle);
            dy = (lineLen/2) * cosd(angle);
            % dx는 선분 중심에서 끝점까지의 x 방향 이동량이다.
            % dy는 선분 중심에서 끝점까지의 y 방향 이동량이다.
            % 선분의 전체 길이가 아니라 절반의 길이를 사용한다.
            % sind와 cosd는 각도를 도 단위로 입력받아 삼각함수 값을 계산한다.

            % 선분의 양 끝점 좌표 계산
            xy_mat(:, idx)   = [cx-dx; cy-dy];
            xy_mat(:, idx+1) = [cx+dx; cy+dy];
            % xy_mat은 선분의 좌표를 저장하는 행렬이다.
            % (:, idx)는 idx번째 열의 모든 행을 의미한다.
            % [cx-dx; cy-dy]는 첫 번째 끝점의 x, y 좌표를 세로로 묶은 것이다.
            % [cx+dx; cy+dy]는 두 번째 끝점의 x, y 좌표를 세로로 묶은 것이다.
            % 중심 좌표에서 한쪽으로 이동한 위치와 반대쪽으로 이동한 위치를 각각 구한다.
            % 이렇게 선분마다 2개의 열에 좌표를 저장하여 DrawLines 함수에 전달한다.

            %% 선분의 색상 지정
            color_mat(:, idx) = RandColor';
            color_mat(:, idx+1) = RandColor';
            % RandColor에는 RGB 색상값 3개가 가로 방향으로 저장되어 있다.
            % 전치 연산자 '를 사용하여 세로 방향으로 바꾼다.
            % 선분의 양 끝점에 같은 색상을 지정하여 선분 전체가 동일한 색으로 보이게 한다.

        end

        %% 선분을 화면에 그린다.
        Screen('FillRect', window, gray);
        % 기존 화면을 회색으로 채워 이전 화면의 자극이 남지 않도록 한다.

        Screen('DrawLines', window, xy_mat, 2, color_mat, [0 0], 0);
        % xy_mat에 저장된 좌표를 이용하여 선분을 그린다.
        % 2는 선분의 두께를 의미한다.
        % color_mat은 각 선분의 색상을 지정한다.
        % [0 0]은 별도의 중심 오프셋을 적용하지 않는다는 뜻이다.
        % 마지막 0은 선분을 연결하여 닫힌 도형으로 그리지 않도록 하는 설정이다.

        Screen('Flip', window);
        % 준비한 자극을 실제 화면에 표시한다.

        %% Task 2. 화면 이미지 저장
        Screenshot = Screen('GetImage', window);
        % 현재 화면에 표시된 이미지를 가져온다.

        fileName = sprintf('pic%d.png', screenIdx);
        % 화면 번호에 맞춰 파일 이름을 만든다.
        % 첫 번째 화면은 pic1.png, 두 번째 화면은 pic2.png로 저장한다.

        imwrite(Screenshot, fileName);
        % 가져온 화면 이미지를 PNG 파일로 저장한다.

        KbStrokeWait;
        % 키보드 입력을 기다린다.
        % 키를 누르면 다음 화면으로 넘어간다.

    end

    sca;
    ShowCursor;
    disp('Experiment successfully finished');

catch info
    sca;
    ShowCursor;
    rethrow(info);
end