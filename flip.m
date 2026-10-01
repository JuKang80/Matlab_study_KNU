sca;        % 열려 있는 모든 PTB 창 닫기
close all;  % 모든 MATLAB 그림(Figure) 창 닫기
clear;      % 작업 공간(Workspace)의 모든 변수 삭제

PsychDefaultSetup(2); % PTB 초기 설정 기본값 세팅 (색상 범위 0~1 등)

Screen('Preference', 'SkipSyncTests', 1); % 화면 동기화 테스트 건너뛰기 (디버깅용)
Screen('Preference', 'ConserveVRAM', 16384); % VRAM 절약을 위한 특수 설정 적용. 인텔 맥북에서 돌아가게 하기 위해서 설정한 값

screens = Screen('Screens'); % 사용 가능한 화면(모니터) 번호 목록 가져오기
screenNumber = 0; % 자극을 띄울 주 화면 번호 설정 (0은 주 모니터)

white = WhiteIndex(screenNumber); % 해당 화면의 흰색 픽셀 값 가져오기
grey = white / 2; % 배경으로 사용할 회색 값 계산

% Open the screen
[window, windowRect] = Screen('OpenWindow', screenNumber, grey);

% --------------------
% Gabor information
% --------------------
gaborDimPix = windowRect(4) / 2; % 가보 패치 크기를 화면 세로 해상도의 절반으로 설정
sigma = gaborDimPix / 7; % 가우시안 표준편차(크기 공간 범위) 설정
orientation = 0; % 가보 패치 회전 각도 (0도)
contrast = 0.8; % 대비(Contrast) 설정
aspectRatio = 1.0; % 가로세로 비율 (1.0은 원형)
phase = 0; % 위상(Phase) 설정

numCycles = 5; % 사이클(줄무늬) 개수 지정
freq = numCycles / gaborDimPix; % 픽셀당 주파수 계산

backgroundOffset = [0.5 0.5 0.5 0.0]; % 가보 배경 오프셋 [R, G, B, A]
disableNorm = 1; % 정규화 비활성화 플래그 세팅
preContrastMultiplier = 0.5; % 대비 곱셈 계수 설정
 
% 절차적 가보 텍스처(Procedural Gabor Texture) 생성
gabortex = CreateProceduralGabor( ...
    window, gaborDimPix, gaborDimPix, [], ...
    backgroundOffset, disableNorm, preContrastMultiplier);

% 가보 드로잉에 사용할 속성 행렬 정의
propertiesMat = [phase, freq, sigma, contrast, aspectRatio, 0, 0, 0];

Screen('DrawTextures', ... % back buffer에 그림을 그려놓는다
    window, gabortex, [], [], orientation, [], [], [], [], ...
    kPsychDontDoRotation, propertiesMat');

Screen('Flip', window); % 백 버퍼에 그려진 그림을 flip하여 제시한다. 

KbStrokeWait; % 사용자가 키보드를 누를 때까지 대기

sca; % 실험 종료 후 모든 PTB 창 닫기
