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

    %% Task 2 방위 45도 선분은 빨간색, 방위 60도 선분은 초록색, 방위 90도 선분은 파란색인 100픽셀짜리 선분을 10개씩 그리세요. 총 30개 선부 그리기
    numLines2 = 30;
    lineLen2 = 100;

    xy_mat2 = zeros(2, numLines2 * 2);
    color_mat2 = zeros(3, numLines2 * 2);

    angle2 = [45 60 90];
    color2 = [255 0 0; 
        0 255 0; 
        0 0 255];

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
    numLines3 = 10;
    xy_mat3 = zeros(2, 30*2);
    color_mat3 = zeros(3, 30*2);
    angles = [45, 60, 90]; % 각도를 미리 저장해두었다. 

    xMargin = 100; % 화면 가로 여백
    yMargin = 100; % 화면 세로 여백


    sectorWidth = (windowRect(3) - (xMargin * 2)) / 3;

    yList = linspace(yMargin, windowRect(4) - yMargin, numLines3); % yMargin에서 시작함. 그리고 windowRect(4)-yMargin이 끝이다. 그리고 그 구역을 10개로 나눈다. 
    lineIdx = 1;
    padList = [200, 25, 0]; % 이전 코드와 다른 점으로, 굳이 if문 사용할 필요 없이 인덱스로 참조하게 하였다. 각각 왼쪽 구역의 패딩, 중앙구역 패딩, 오른쪽 구역 패딩이다. 

    for i = 1:3
        minX = (i-1) * sectorWidth;
        maxX = i * sectorWidth;
        currentAngle = angles(i);
        pad = padList(i);


        for k = 1:10
            cx = (minX + pad) + rand * ((maxX - pad) - (minX + pad)); % 최소값에 100 더하고, 최대값에 -100을 하여 끝 부분 100px 안쪽에서만 나타난다.
            cy = yList(k) + (rand * 30 - 15); % 나눈 구역 중 각 숫자의 해당하는 구역이 선택된다. 구역을 나누니 너무 반듯하게 나와 약간의 jitter를 주었다.

            randLen = 40 + rand * 40; % 선 길이 조정함. 40~80픽셀 사이로 나옴. 
            randColor = rand(1, 3) * 255;

            idx = (lineIdx-1)*2 + 1;

            xy_mat3(1, idx) = cx - (randLen/2) * sind(currentAngle);
            xy_mat3(2, idx) = cy - (randLen/2) * cosd(currentAngle);
            xy_mat3(1, idx+1) = cx + (randLen/2) * sind(currentAngle);
            xy_mat3(2, idx+1) = cy + (randLen/2) * cosd(currentAngle);

            % color_mat3(:, idx) = randColor';
            % color_mat3(:, idx+1) = randColor';
            color_mat3(:, idx:idx+1) = repmat(randColor', 1,2);
            % 우변의 repmat은 배열을 원하는 개수 만큼 복사하여 붙여넣는 함수이다.
            % 원하는 배열이 randColor을 transpose한 것인데, 즉 1행 3열값을 3열 1행 값으로 바꾼다. 
            % 그래서 동작하는 것은 3행 1열짜리 열벡터를 행 방향으로 1번(그대로), 열 방향으로 2번 복사하여 3행 2열 형태의 행렬로 만든다.
            % randColor'은 이미 3행 1열의 데이터이므로 행을 더 늘릴 필요 없기 때문에, 1번(그대로) 유지했다. 
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
