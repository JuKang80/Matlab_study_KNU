%% 1. 5초마다 색, 크기, 위치가 랜덤하게 변하는 10개의 도형을 그리세요.
% 전환 횟수는 최소 5회이며 타이머가 보이도록 설정해보세요. 도형의 모양은 자유입니다. 

%% 문제 분해 
% 1) 색, 크기, 위치가 랜덤
% 2) 그 적용 대상은 도형이다. 제일 밖의 for문을 통해 색, 크기, 위치 랜덤을 설정하고 안의 for
% 문에서 숫자 카운트다운(타이머가 돌아가도록)을 넣으면 될 것 같다. 
% 3) 도형의 모양은 크게 설정된것이 없다. 원으로 시도해보자. 


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

    for trial = 1:20
    
        cx = double(randi([100, windowRect(3)-100], 1, 10)); % 도형 중심 x좌표 한번에 만들기
        cy = double(randi([100, windowRect(4)-100], 1, 10)); % 도형 중심 y좌표 한번에 만들기
        sz = double(randi([50, 150], 1, 10)); % 10개 도형 크기 한번에 만들기
       
        shapes = [cx-sz/2; cy-sz/2; cx + sz/2; cy + sz/2]; % 도형이 나타날 위치 저장을 위한 4행 10열 설정
        colors = randi([0 255], 3, 10); % 색상은 루프 필요 없이 랜덤 색 미리 생성

        for timer = 5:-1:1
            Screen('FillOval', window, colors, shapes)

            infoText = ['Trial:  ', num2str(trial), '\nTime Left: ', num2str(timer), 's'];
            DrawFormattedText(window, infoText, 50, 50, white);

            Screen('Flip', window);

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