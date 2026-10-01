%% Psychtoolbox 기본 화면 설정

% 기존 환경 초기화
sca;                    % Psychtoolbox 화면 닫기
close all;              % MATLAB Figure 창 닫기
clear;                  % Workspace 변수 삭제
clc;                    % Command Window 내용 삭제


% Synchronization 설정
Screen('Preference', 'SkipSyncTests', 1);
% VBL Synchronization 검사 생략
% 1: 검사 생략 / 0: 검사 수행
% 현재는 디버깅을 위해 1 사용
% 실제 실험에서는 정확한 timing을 위해 검사 필요


% Psychtoolbox 기본 설정
PsychDefaultSetup(2);
% Psychtoolbox 기본 환경 설정
% 색상값을 0~1 범위로 사용


% 사용 가능한 디스플레이 확인
screens = Screen('Screens');
% Psychtoolbox가 인식한 디스플레이 번호 반환
% 예: [0 1]


% 실험에 사용할 디스플레이 지정
screenNumber = 0;
% 외부 모니터의 번호를 직접 지정
% 0이 항상 외부 모니터를 의미하는 것은 아님


% 색상 설정
white = WhiteIndex(screenNumber);    % 흰색, 스크린 넘버에 해당하는 디스플레이에서 흰색의 숫자가 뭔지 가져온다. 
black = BlackIndex(screenNumber);    % 검정색, 스크린 넘버에 해당하는 디스플레이에서 검정의 숫자가 뭔지 가져온다. 
grey = white / 2;                    % 회색, 흰색을 절반한 값을 회색으로 한다. 추측하건데 검정은 0일거고 흰색이 1이면 그것의 절반하는식으로 하지 않을까? 


% 실험 화면 생성
[window, windowRect] = Screen( ...  % 그냥 줄바꿈. 대괄호 안에서 여러개의 값을 받겠는다는 뜻이다. PTB가 생성한 실험용 화면을 가리키는 핸들, 즉 실험용 화면을 조종하는 것이다. 그러니까 어떤 디스플레이를 다룰것이고 그것의 좌표 및 크기 정보는 어떠한지 받는다는 뜻이다. 
% "=" 이것은 결국 오른쪽에서 나온 값을 왼쪽에 저장하겠다는 뜻 
    'OpenWindow', screenNumber, grey); % openwindow로 화면을 생성하고 그 생성된 화면을 대괄호 안의 window로 핸들하겠다 라는 의미이다. screenNumber로 어디에 열지 지정해주고, grey로 연 실험 배경화면을 무엇으로 할지 설정하는 것이다. 지금은 회색으로 설정했다. 
% 지정한 디스플레이에 회색 배경의 실험 화면 생성
% window: 실험 화면을 제어하기 위한 핸들
% windowRect: 화면의 좌표 및 크기 정보. window rectangle이란 뜻. 


% 키보드 입력 대기
KbName('UnifyKeyNames'); 
disp('아무 키나 눌러보세요.'); 
KbStrokeWait; 
disp('키 입력 확인!');
% KbStrokeWait는 참가자가 키를 누를 때까지 대기하는 것이다. 


% 실험 화면 종료
sca;
% Psychtoolbox로 생성한 화면 닫기
