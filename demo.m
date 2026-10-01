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
white = WhiteIndex(screenNumber);    % 흰색
black = BlackIndex(screenNumber);    % 검정색
grey = white / 2;                    % 회색


% 실험 화면 생성
[window, windowRect] = PsychImaging( ...
    'OpenWindow', screenNumber, grey);
% 지정한 디스플레이에 회색 배경의 실험 화면 생성
% window: 실험 화면을 제어하기 위한 핸들
% windowRect: 화면의 좌표 및 크기 정보


% 키보드 입력 대기
KbName('UnifyKeyNames'); 
disp('아무 키나 눌러보세요.'); 
KbStrokeWait; disp('키 입력 확인!');
% KbStrokeWait;
% 참가자가 키를 누를 때까지 대기


% 실험 화면 종료
sca;
% Psychtoolbox로 생성한 화면 닫기
