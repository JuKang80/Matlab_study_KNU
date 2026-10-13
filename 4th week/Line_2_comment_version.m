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

    %% 1. 키보드를 누르면 색, 길이, 방위, 위치가 랜덤하게 변하는 20개의 선분을 그리세요. 전환 횟수는 최소 5회입니다.


    for screenIdx = 1:6 % 화면 전환 횟수 (현재 5번)
        numLines = 20; % 제시할 자극 20개를 선언. 
        xy_mat = zeros(2, numLines * 2); % 선분을 담을 행렬 선언. 
        color_mat = zeros(3, numLines * 2); % 색 랜덤을 담기 위한 행렬 선언 


        for i = 1:numLines
            angle = rand * 360;
            lineLen = 50 + rand * 100; % 50부터 150 미만 랜덤한 길이를 가진다.
            RandColor = rand(1, 3) * 255; % 색 랜덤 설정 
            cx = rand * windowRect(3); cy = rand * windowRect(4); % x, y좌표에 대한 랜덤 값 
            idx = (i-1)*2 + 1;

            % 각각 선분 길이 좌표 구하는 코드 
            xy_mat(1, idx) = cx - (lineLen/2) * sind(angle); 
            xy_mat(2, idx) = cy - (lineLen/2) * cosd(angle);
            xy_mat(1, idx+1) = cx + (lineLen/2) * sind(angle);
            xy_mat(2, idx+1) = cy + (lineLen/2) * cosd(angle);

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

