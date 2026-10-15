% =========================================================================
% 오직 Screen('OpenWindow')만 사용한 플랭커 테스트 단일 스크립트
% =========================================================================
clear; clc; sca; % 이전 데이터 및 열려있는 화면 창 모두 초기화

% Psychtoolbox 기본 설정 (윈도우 환경 최적화 및 동기화 테스트 생략)
PsychDefaultSetup(2);
Screen('Preference', 'SkipSyncTests', 1); 

% -------------------------------------------------------------------------
% [차이점 단계 1] PsychImaging 설정 과정이 통째로 생략됨
% -------------------------------------------------------------------------
% (PsychImaging의 'PrepareConfiguration'이나 'AddTask' 같은 
%  GPU 파이프라인 예약 명령을 사용할 수 없으며, 곧바로 창을 엽니다.)

% -------------------------------------------------------------------------
% [차이점 단계 2] Screen 단독 명령으로 온스크린 창 생성
% -------------------------------------------------------------------------
screenNumber = max(Screen('Screens'));
black = BlackIndex(screenNumber);
white = WhiteIndex(screenNumber);

% [핵심 차이] PsychImaging 대신 Screen 함수를 직접 호출하여 창을 엽니다.
[windowPtr, windowRect] = Screen('OpenWindow', screenNumber, black);

% 기본 텍스트 세팅 (고정폭 서체인 Courier New를 사용해 자극 정렬 유지)
Screen('TextSize', windowPtr, 60);
Screen('TextFont', windowPtr, 'Courier New');

% 5회 반복용 플랭커 자극 배열 정의
stimuli = {'<<<<<<<', '<<<<<<<', '<<<>>>>', '>>>><>>>', '>>>>>>>'};

% -------------------------------------------------------------------------
% [단계 3] 5회 자극 제시 루프 (이 부분은 이전 코드와 완벽히 동일)
% -------------------------------------------------------------------------
for trial = 1:5
    % 1. 화면 중앙에 플랭커 문자열 그리기
    currentStim = stimuli{trial};
    DrawFormattedText(windowPtr, currentStim, 'center', 'center', white);

    % 2. 화면 하단에 안내 메시지 표시 (폰트 크기 조절)
    Screen('TextSize', windowPtr, 24);
    DrawFormattedText(windowPtr, '아무 키나 누르면 다음 자극으로 넘어갑니다.', 'center', windowRect(4)*0.8, white);
    Screen('TextSize', windowPtr, 60); % 자극용 크기로 원복

    % 3. 화면 업데이트 (추가적인 GPU 보정 없이 백버퍼의 내용이 그대로 출력됨)
    Screen('Flip', windowPtr);

    % 4. 이전 키 입력이 떼어질 때까지 대기 후 새 입력 받기
    KbReleaseWait;
    KbStrokeWait;
end

% -------------------------------------------------------------------------
% [단계 4] 스크립트 정상 종료 및 화면 닫기
% -------------------------------------------------------------------------
sca; 
disp('테스트가 성공적으로 완료되었습니다.');
