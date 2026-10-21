
clear;
clc;
close all;
sca;

PsychDefaultSetup(2);
Screen('Preference', 'SkipSyncTests', 1);
KbName('UnifyKeyNames');

try
    % ========================================
    % 1. PsychImaging 설정
    % ========================================

    PsychImaging('PrepareConfiguration');

    % 32-bit floating-point framebuffer
    PsychImaging('AddTask', ...
        'General', 'FloatingPoint32Bit');

    % LUT 기반 색상 보정 파이프라인 활성화
    PsychImaging('AddTask', ...
        'FinalFormatting', ...
        'DisplayColorCorrection', 'LookupTable');

    screens = Screen('Screens');
    screenNumber = max(screens);

    white = WhiteIndex(screenNumber);
    black = BlackIndex(screenNumber);
    gray = (white + black) / 2;

    [window, windowRect] = PsychImaging( ...
        'OpenWindow', screenNumber, gray);

    % ========================================
    % 2. 직접 RGB LUT 만들기
    % ========================================

    % 256개 입력 단계: 0~1
    x = linspace(0, 1, 256)';

    % 각 열은 R, G, B 채널의 출력값
    % 빨강: 그대로 유지
    % 초록: 비선형 변환
    % 파랑: 그대로 유지
    clut = [x, x.^1.6, x];

    % LUT를 PsychImaging 색상 보정 파이프라인에 전달
    PsychColorCorrection('SetLookupTable', ...
        window, clut);

    % ========================================
    % 3. 색 명명 데모 설정
    % ========================================

    [xCenter, yCenter] = RectCenter(windowRect);

    patchSize = 300;
    patchRect = CenterRectOnPointd( ...
        [0 0 patchSize patchSize], ...
        xCenter, yCenter);

    % 입력 자극 색상
    colorRGB = [0.65 0.80 0.25];

    fKey = KbName('f');
    jKey = KbName('j');
    escKey = KbName('ESCAPE');

    % 처음에는 LUT를 적용하지 않은 상태로 표시
    identityCLUT = [x, x, x];

    PsychColorCorrection('SetLookupTable', ...
        window, identityCLUT);

    while true

        % 원래 색상과 LUT 적용 색상 비교
        Screen('FillRect', window, gray);
        Screen('FillRect', window, colorRGB, patchRect);

        DrawFormattedText(window, ...
            ['F: Original color\n' ...
             'J: LUT-transformed color\n' ...
             'ESC: Exit'], ...
            'center', yCenter + 220, white);

        Screen('Flip', window);

        % 키 입력 대기
        [keyIsDown, ~, keyCode] = KbCheck;

        if keyIsDown

            if keyCode(escKey)
                break;

            elseif keyCode(fKey)

                % 항등 LUT: 입력 RGB 값을 그대로 통과
                PsychColorCorrection('SetLookupTable', ...
                    window, identityCLUT);

            elseif keyCode(jKey)

                % 직접 만든 변환 LUT 적용
                PsychColorCorrection('SetLookupTable', ...
                    window, clut);

            end

            % 키를 계속 누르고 있는 상태에서 반복 입력 방지
            KbReleaseWait;
        end

        WaitSecs(0.01);
    end

    sca;

catch ME
    sca;
    rethrow(ME);
end