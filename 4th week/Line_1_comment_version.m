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
    % 그림을 그릴때 기본적으로 기존에 있던 것을 다 지우고 그리는데 그러면 안되고 안티앨리어싱 방지 위해 한 코드를 위해 기존의 대각선 픽셀에 더하여 그려야 한다. 
    % 안티앨리어싱은 비스듬한 선의 끄트머리 픽셀들을 살짝 투명하게 처리하여 선을 매끄럽게 만드는 기술이다. 그러니까 해당 라인이 있어야 안티앨리어싱이 작동한다. 
    Screen('Flip', window);


    %% Task 1: 길이가 100픽셀인 검은색 선분 100개를 그리세요. (방위, 위치는 자유) 
    numLines1 = 100; % 제시할 자극 100개를 선언함 
    lineLen1 = 100; % 제시할 자극의 속성 중 픽셀의 고정된 값(100)을 미리 정의해 둔다. 

    xy_mat1 = zeros(2, numLines1 * 2); % Line을 그리기 위해 시작점과 끝점에 대한 정보가 필요하다. 즉, 100개의 선을 위해 200개의 정보가 있는 열이 필요하다. 그래서 numLines1 * 2를 했다. 
    
    for i = 1:numLines1 % 정의한 자극개수(100회)만큼 루프를 돈다.

        % 선분의 방위와 위치는 자유인데, 여기서 랜덤하게 제시할 수 있다. 그렇게 하기 위해 x,y 좌표 중심을 랜덤하게 구해준다. 
        % windowRect 안에는 [x축 처음좌표(0), y축 처음 좌표(0), x축 끝 좌표, y축 끝 좌표]의 정보가 들어있다. 
        
        cx1= rand * windowRect(3); % rand는 0~1 사이 실수를 내뱉는데, x축 끝 좌표(3)에 대하여 0~1 사이의 비율(%)로서 표현하여 x축의 랜덤한 값을 가지게 된다. 
        cy1 = rand * windowRect(4); % y축 끝 좌표(4)에 대하여 0~1 사이의 비율(%)로서 표현되어 y축의 랜덤한 값을 가지게 된다. 
        % 예시로, rand가 우연히도 x,y축 둘 다 0.5일 경우 모니터 해상도 가로값의 절반, 세로값 그래서 정중앙에 시작점이 오게 된다. 

        angle = rand * 360; % 선분이 무작위로 기울여질 값을 구한다. 

        idx = (i-1)*2 + 1; % i값 증가에 따라 200개의 열을 2칸씩 짚어주는 인덱스 포인터이다. 
        % 현재 xy_mat1에는 시작점 데이터와 끝점 데이터가 2개씩 쌍을 이루어 전체 데이터 개수는 200개이고, 
        % 이걸 line의 관점에서 보면 '(시작좌표, 끝좌표)'의 쌍이 100개가 있다. 
        % 그렇기 때문에 한번에 2씩 증가하여 1,3,5,7,9, ...로 올라가게 만들어야 한다. 

        xy_mat1(1, idx) = cx1 - (lineLen1/2) * sind(angle); % cx는 랜덤하게 선정된 "만들어질 선분의 가로 중심 픽셀 좌표이다. 이것을 왼쪽 방향으로(음수 방향) 빼야하는데(start point), 
        % 무얼빼냐하면 빗변의 길이가 50인, 그리고 거기에 사인 세타를 곱한 값을 뺀다. 여기서 각도 또한 랜덤으로 선정되었는데, 그건 angle로 선언한 것을 통해 알 수 있다. 
        % 그 이유는 어떻게 보면 x축에서 얼마만큼 이동했냐는 직각삼각형에서 밑변의 길이와 동일하다고 생각가능한데, 그래서 그 공식을 사용하여 50픽셀만큼 빗변이 있으면 가로가 얼마가 되어야 하는지 구했다. 
        xy_mat1(2, idx) = cy1 - (lineLen1/2) * cosd(angle); % 이 코드는 start point의 y좌표를 구하는 것이다. 구할때 cos 세타를 하는데, 그러니까 중등수학때 배웠을거라 생각한 공식에 빗대어 생각해보면 
        % 새로로 이동한 정도, 그러니까 y좌표에 대한 값이 나온다. 
        % 현재 xy_mat1의 1행 1열과 2행 1열에는 start point의 (x,y) 값이 있다. 
        % 그 다음은 end point를 구해야 한다. 
        xy_mat1(1, idx+1) = cx1 + (lineLen1/2) * sind(angle); % 더하여서 오른쪽 방향으로 얼마만큼 갔는데 end point를 구해야 하는데, 그래서 x축 이동량을 알 수 있는 sin 세타 * 빗변길이(50)을 했다. 
        % 언급하고 가야할 것이 왜 한쪽으로 50픽셀을 가고 다른 한쪽으로 50픽셀을 움직이느냐, 그 이유는 총 100픽셀의 선을 그려야 하는데 그걸 위해 양쪽으로 50씩, 총 100픽셀만큼 움직인 좌표를 구해 함수를 통해 그릴 것이다. 
        xy_mat1(2, idx+1) = cy1 + (lineLen1/2) * cosd(angle); % 이것은 2행 2열에 있는 end point의 y좌표이다. cos으로 구한다. 
        % 그래서 1행 2열과 2행 2열에 end point에 대한 값이 저장되었다. 

        % 여기서 왜 cosd, sind를 사용하냐면 360도로 각도를 설정했기 때문이다. 
    end

    Screen('FillRect', window, gray); % FillRect는 사각형(화면)을 채우는데, 영역 지정이 없으면 화면 전체를 채운다. window는 OpenWindow로 열어둔 화면의 포인터(열어둔 화면을 가리키는 무언가)이다. 그래서 그 화면에 그리라고 하는 것인데, 회색으로 채우겠다고 하는 것이다. 
    Screen('DrawLines', window, xy_mat1, 2, [0,0,0], [0,0], 2); % xy_mat1 행렬(2행 200열)에 있는 것을 window에 'Drawlines'를 한다. 3번째에 오는 2는 선분 굵기(픽셀)이다. 4번째의 [0,0,0]은 선분의 색상이다. 검정으로 그리겠다는 것이다. 다섯번째는 저장된 행렬의 값들에 대하여 가로로 얼마, 세로로 얼마만큼 움직여서 그릴지 정하는데 여기서는 [0,0]으로 설정했다. 
    % 마지막에 오는 2는 안티앨리어싱이라고 픽셀을 대각선으로 그리면 계단현상(깨지는현상)이 나타나는데 그걸 매끄럽게 그려주게 해준다. 
    Screen('Flip', window); % 백버퍼에 그려둔 것을 프론트버퍼로 flip하는 것이다. 

    % Save screenshot
    Screenshot = Screen('GetImage', window);
    imwrite(Screenshot, 'stimulus_output_1.png');

    KbStrokeWait; % 키보드 응답 받을때까지 기다리는 것이다. 

    %% TASK 2. 방위 45도 선분은 빨간색, 방위 60도 선분은 초록색, 방위 90도 선분은 파란색인 100픽셀짜리 선분을 10개씩 그리세요.

    numLines2 = 30; % 선분 10개를 미리 선언한다. 
    lineLen2 = 100; % 100픽셀짜리 그릴 선분에 대한 길이(100픽셀)을 미리 선언한다. 

    xy_mat2 = zeros(2, numLines2 * 2); % 선분 10개, 근데 45도/60도/90도 각각에 대하여 start point와 end point가 필요하므로 2행 60열을 선언한다. 

    color_mat2 = zeros(3, numLines2 * 2);
    % 위의 코드는 RGB를 담는 3행 60열 행렬이다.
    % 3행인 이유는 R, G, B의 integer를 담아야하고 60개로 xy_mat2와 열을 맞춰 주었다. 
    % 각 선분마다 색상을 다르게 하기 위해서이다. 
    
    angle2 =[45 60 90]; % 각도에 대한 것을 미리 선언해 둔다. 
    color2 = [255 0 0; 0 255 0; 0 0 255]; % 색에 대한 것을 미리 선언해 둔다. 
    % 차례대로 red, green, blue이다. 
    % 3행 3열. 1행은 red, 2행은 green, 3행은 blue이다. 

    % 각도에 따라 특정한 색을 가진 선분이 10개씩 나와야 한다. 
    % 각도에 따라 돌면서 선 백버퍼에 저장 -> 이중 for문 사용. 
    % 상위 for문은 각도고 그 아래에는 실제 선분이 출력되도록 하는것이 좋을것 같다. 

    lineIdx = 1; % 30까지 올라가며 count를 해야 하는 인덱스 숫자이다. 

    for i = 1:3 % 상위 for문에서는 각도 3개를 순회한다. 
        currentAngle = angle2(i); % 현재 루프 차례의 타겟 각도 추출 
        currentColor = color2(i, :); % 현재 루프 차례의 1행 3열 RGB 색 행을 추출

        for k = 1:10 % 각 조건(각도와 색)에 맞는 그림을 그린다. 
            cx = rand * windowRect(3); % 선분을 그릴때의 중앙값이 어디라 언급이 없기에 랜덤하게 처리했다. 
            cy = rand * windowRect(4); % y축의 값을 랜덤하게 하나 가져온다. 

            idx = (lineIdx-1)*2 + 1; % 1,3,5,7,9,...로 증가하여 인덱스를 참조하게 만들기 위해 넣었다. 

            xy_mat2(1, idx)   = cx - (lineLen2/2) * sind(currentAngle); % start point의 X값 
            xy_mat2(2, idx)   = cy - (lineLen2/2) * cosd(currentAngle); % start point의 y값
            xy_mat2(1, idx+1) = cx + (lineLen2/2) * sind(currentAngle); % end point의 x값 
            xy_mat2(2, idx+1) = cy + (lineLen2/2) * cosd(currentAngle);% end point의 y값





        
            color_mat3(:, idx:idx+1) = repmat(randColor', 1,2);
            % 우변의 repmat은 배열을 원하는 개수 만큼 복사하여 붙여넣는 함수이다.
            % 원하는 배열이 randColor을 transpose한 것인데, 즉 1행 3열값을 3열 1행 값으로 바꾼다. 
            % 그래서 동작하는 것은 3행 1열짜리 열벡터를 행 방향으로 1번(그대로), 열 방향으로 2번 복사하여 3행 2열 형태의 행렬로 만든다.
            % randColor'은 이미 3행 1열의 데이터이므로 행을 더 늘릴 필요 없기 때문에, 1번(그대로) 유지했다. 


            %% 아래 코드를 좀더 간결화 한 것이 위의 코드이다. 
            %color_mat2(:, idx) = currentColor'; % 현재 k를 1이라고 가정하면 
            % idx = 1, color_mat2의 모든 행과 1열의 값을 currentColor로 저장해야 한다.
            % 그러면 결국 transpose(')로 바꾸어진, 1행 3열의 값으로 color_mat2에 값이
            % 저장된다. 
            %color_mat2(:, idx+1) = currentColor';
            % DrawLines를 할 때 start point와 end point에 대한 값이 각각 필요하므로
            % 전체행과 2열에 대해서도 현재 1번 줄을 그릴때 필요한 색으로 바꾸어 준다(transpose)

            lineIdx = lineIdx + 1; % 이제 count 숫자를 올려준다.  
        end 

    end 

    Screen('FillRect', window, gray); % 화면을 일단 그레이로 바꾸어 준다. 

    Screen('DrawLines', window, xy_mat2, 2, color_mat2, [0 0], 0);
    % 안티앨리어싱은 0으로 두어 해제하였다. 
    % 3번째 인자는 선 두께(현재 2픽셀), 네번째는 색인데 아까 저장한 대로 출력되게 하였다. 
    Screen('Flip', window);

    % Save screenshot
    Screenshot = Screen('GetImage', window);
    imwrite(Screenshot, 'stimulus_output_2.png');

    KbStrokeWait;
        


    

    %% TASK 3. 화면의 왼쪽에는 방위 45도 선분 10개, 중앙에는 방위 60도 선분 10개, 오른쪽에는 방위 90도 선분 10개가 나오게 그리기. (색과 길이 랜덤)
    % 1) 색과 길이 랜덤, 2) 화면을 3등분, 3) 필요 방위는 45, 60, 90도, 4) 각 영역별 10개씩 출력, 총 30개의 선 출력

    % 처음 할 것은 선을 담을 행렬 선언, 2행 60열(30개 * 2)
    xy_mat3 = zeros(2, 30*2);

    % 색이 랜덤이어야 하는데 task2에서 사용했던 구조를 가져왔다. 
    color_mat3 = zeros(3, 30*2);

    % 화면을 3등분 해야하는것이면, 화면의 가로값을 3으로 나누는 것이 타당해보인다.
    sectorWidth = windowRect(3) / 3;

    % count로 숫자 세기 위함임
    lineIdx = 1;


    for i = 1:3 % 공간을 3등분 한 것이다. 1:왼쪽, 2: 중앙, 3: 오른쪽 

        % if-else를 통해 분기를 설정한다. 
        if i == 1
            currentAngle = 45; minX = 0; maxX = sectorWidth;
            % 왼쪽은 45도 각도의 선이 10개가 나와야 하는데, 
            % 여기서 X축의 값 최소값과 최대값을 고정했다. 
        elseif i == 2
            currentAngle = 60; minX = sectorWidth; maxX = sectorWidth * 2;
            % 중앙인 경우 60도, 그리고 최소값은 0이 아닌 왼쪽구역의 최대값, 3등분한 것 중 2영역을 합친 값이다. 
        else
            currentAngle = 90; minX = sectorWidth * 2; maxX = windowRect(3);
            % 오른쪽은 90도이고 최소값은 중앙값의 끝 부분, 최대값은 화면의 x축 최대 픽셀값이다.
        end

        for k = 1:10 % 3등분으로 나누어진 곳에서 선을 10개씩 그리는 것이다. 

            cx = minX + rand * (maxX - minX); % 최소값 + rand*(최대값-최소값)
            % 랜덤이라도 특정 구간 내에서만 나타나야 하기 때문에 이와같이 설정했다.
            cy = rand * windowRect(4); % 세로는 모든 영역이 다 와도 되니까 그냥 설정했다. 

            randLen = 50 + rand * 100; % 길이도 랜덤이어야 한다. 
            randColor = rand(1, 3) * 255; % 색도 랜덤이어야 하는데, 1행 3열로 랜덤하게 색을 설정해야한다. 
            % 그러기 위해 각 소수점 값에 255로 곱하여 랜덤한 값이 나오게 하였다. 

            idx = (lineIdx-1)*2 + 1; % DrawLines를 위하여 인덱스는 1,3,5,7,9,...로 올라가야 하기 때문에 이와같이 설정하였다. 

            xy_mat3(1, idx) = cx - (randLen/2) * sind(currentAngle); % randLen을 통해 뻗어나갈 길이를 결정한다. 
            xy_mat3(2, idx)   = cy - (randLen/2) * cosd(currentAngle); % start point의 y축 
            xy_mat3(1, idx+1) = cx + (randLen/2) * sind(currentAngle); % end point의 x축 
            xy_mat3(2, idx+1) = cy + (randLen/2) * cosd(currentAngle); % end point의 y축

            color_mat3(:, idx) = randColor'; % 색을 transpose하여 모든 행과 idx열에 넣어준다. 
            color_mat3(:, idx+1) = randColor'; % 그 다음 열(idx+1)에도 넣어준다. 

            lineIdx = lineIdx + 1; % 증감시킨다. 
        end
    end

    Screen('FillRect', window, gray);
    Screen('DrawLines', window, xy_mat3, 2, color_mat3, [0 0], 0);
    Screen('Flip', window);

    % Save screenshot
    Screenshot = Screen('GetImage', window);
    imwrite(Screenshot, 'stimulus_output_3.png');
    KbStrokeWait;


    %% 선택과제: 생성한 자극을 사진 파일로 저장하세요.
    Screenshot = Screen('GetImage', window); % PTB3의 내장 함수 호출

    imwrite(Screenshot, 'stimulus_output_1.png') % 현재 소스 폴더 경로 내에 png로 저장

    sca;
    ShowCursor;
    disp('Experiment successfully finished');
catch info 
    sca;
    ShowCursor; % 에러가 나서 작동이 중단될 경우 마우스를 다시 보이게 만드는 것이다. 
    rethrow(info); % try 블록 안에서 문제가 보통 생기고 그걸 해결해야 하기 때문에 rethrow를 사용했다. 
    endd