%% =========================================================================
% [PTB Boilerplate 참고 가이드: 실험 결과 기록 및 안전 저장 방식]
%
% 파일명: DataSaving_Guide.m (MATLAB .m 파일 규칙상 영문/숫자/밑줄만 사용)
% 목적  : 보일러플레이트의 데이터 기록(struct) 및 CSV 안전 저장(try/catch)
%         코드가 왜 이렇게 작성되었는지 한눈에 복습·설명하기 위한 가이드입니다.
%
% ※ Psychtoolbox 없이 일반 MATLAB에서 바로 실행(Run)해 볼 수 있습니다.
% =========================================================================

%% [1] 왜 기존 cell 방식 대신 struct 방식을 쓰는가?
% -------------------------------------------------------------------------
% [기존 방식 (cell + colNames 따로 관리)]
%   result = {};
%   result(trial, :) = {trial, initUserSize, userSize, rt, resultText};
%   ... (수십 줄 아래) ...
%   colNames = {'Trial', 'InitUserSize', 'UserSize', 'RT', 'Result'};
%   resultTable = cell2table(result, 'VariableNames', colNames);
%
% -> 문제점:
%    1) 값 넣는 줄과 이름표(colNames) 줄이 떨어져 있어, 수정하다 순서가 1칸만
%       어긋나도 엉뚱한 열 이름으로 저장됩니다.
%    2) 열 개수가 1개라도 안 맞으면 실험이 끝난 마지막 저장 줄에서 에러가
%       터지면서 데이터 전체가 저장되지 않습니다.
%
% [바뀐 방식 (struct: 값을 넣을 때 바로 이름표 붙이기)]
%   logData = struct([]);
%   logData(trial).피험자ID   = string(subjectID);
%   logData(trial).시행번호   = trial;
%   logData(trial).반응시간_초 = rt;
%   logData(trial).정답여부   = isCorrect;  % 1(정답) 또는 0(오답)
%
% -> 장점:
%    1) 마침표(.) 뒤의 필드명이 그대로 CSV 열 이름이 되므로 순서가 꼬이지 않습니다.
%    2) colNames를 따로 맞출 필요가 없어 열 개수 불일치 에러가 사라집니다.
% -------------------------------------------------------------------------

%% [2] 왜 정답여부를 'correct'/'wrong' 대신 1 / 0 숫자로 저장하는가?
% -------------------------------------------------------------------------
% - 문자열('correct', 'wrong')은 MATLAB/Excel/R/SPSS에서 바로 평균을 낼 수 없어
%   나중에 1/0으로 다시 바꾸는 전처리가 필요하고, 오타('Corect') 위험도 있습니다.
% - 처음부터 1(정답), 0(오답) 숫자로 저장하면:
%     · mean(resultTable.정답여부)  -> 바로 정답률 (예: 0.80 = 80%)
%     · sum(resultTable.정답여부)   -> 바로 총 정답 개수
% -------------------------------------------------------------------------

%% [3] 저장 코드 한 줄씩 해석 (data/ 폴더 + struct2table + UTF-8)
% -------------------------------------------------------------------------
% 1) dataDir = fullfile(pwd, 'data');
%    - 현재 작업 폴더(pwd) 아래 'data' 폴더 경로를 만듭니다.
%    - fullfile을 쓰면 Mac('/')과 Windows('\') 경로 구분자를 자동 처리합니다.
%    - .m 코드 파일과 .csv 데이터 파일이 한 폴더에 뒤섞이는 것을 막아줍니다.
%
% 2) if ~isfolder(dataDir), mkdir(dataDir); end
%    - 'data' 폴더가 아직 없으면 자동으로 생성합니다.
%
% 3) if ~isempty(logData)
%    - 0시행 상태에서 저장하려다 에러가 나는 것을 막아줍니다.
%
% 4) resultTable = struct2table(logData, 'AsArray', true);
%    - struct(logData)를 엑셀 표(table)로 변환합니다.
%    - 'AsArray', true를 꼭 붙이는 이유:
%      피험자가 딱 1시행만 하고 ESC를 눌렀을 때(1줄짜리 데이터), MATLAB이
%      표 모양을 이상하게 바꾸거나 에러를 내는 현상을 막아줍니다.
%
% 5) fileName = fullfile(dataDir, sprintf('%s_result_%s.csv', subjectID, timeStr));
%    - 피험자 ID + 날짜/시간 타임스탬프(yyyyMMdd_HHmmss)를 붙여
%      누구 파일인지 바로 구분되고, 이전 파일 덮어쓰기를 방지합니다.
%
% 6) writetable(resultTable, fileName, 'Encoding', 'UTF-8');
%    - 한글 열 이름('피험자ID', '반응시간_초' 등)이 엑셀에서 깨지지 않도록
%      UTF-8 인코딩을 명시합니다.
% -------------------------------------------------------------------------

%% [4] ESC 중단 또는 에러 시 catch 블록의 동작 순서
% -------------------------------------------------------------------------
% 루프에서 ESC를 누르면 error('사용자에 의해 중단되었습니다.')가 실행되며,
% 정상 저장([Part 6])을 건너뛰고 즉시 catch info 블록으로 이동합니다.
%
%   catch info
%       % 1순위: 화면·커서·키보드 잠금·우선순위부터 무조건 먼저 복구!
%       % (저장을 먼저 하다가 에러가 나면 전체 화면이 먹통이 될 수 있기 때문)
%       RestrictKeysForKbCheck([]);
%       Priority(0);
%       fclose('all');
%       sca;
%       ShowCursor;
%
%       % 2순위: logData가 이미 생성되었고 1줄 이상 기록됐으면 '_aborted.csv'로 저장
%       % exist('logData', 'var') 이유: 창을 열기 전에 에러가 나면 logData 변수 자체가
%       % 아직 없을 수 있으므로, 변수가 존재할 때만 저장하도록 방어하는 안전장치입니다.
%       if exist('logData', 'var') && ~isempty(logData)
%           resultTable = struct2table(logData, 'AsArray', true);
%           timeStr     = string(datetime('now', 'Format', 'yyyyMMdd_HHmmss'));
%           fileName    = fullfile(dataDir, sprintf('%s_result_%s_aborted.csv', subjectID, timeStr));
%           writetable(resultTable, fileName, 'Encoding', 'UTF-8');
%           fprintf('중단 전까지의 결과가 저장되었습니다: %s\n', fileName);
%       end
%
%       rethrow(info); % 원래 에러 메시지를 명령 창에 출력
%   end
% -------------------------------------------------------------------------

%% [5] 바로 실행해 보는 미니 데모 (PTB 없이 MATLAB 명령 창에서 확인)
clear;
clc;

subjectID = 'S01';
logData   = struct([]);

% 예시 시행 3회 기록 시뮬레이션
sampleRTs     = [0.412, 0.538, 0.389];
sampleCorrect = [1, 0, 1]; % 1: 정답, 0: 오답

for trial = 1:length(sampleRTs)
    logData(trial).피험자ID   = string(subjectID);
    logData(trial).시행번호   = trial;
    logData(trial).반응시간_초 = sampleRTs(trial);
    logData(trial).정답여부   = sampleCorrect(trial);
end

% struct -> table 변환 결과 확인
resultTable = struct2table(logData, 'AsArray', true);
disp('=== 변환된 결과 표 (resultTable) ===');
disp(resultTable);
fprintf('평균 반응시간: %.3f초 / 정답률: %.1f%%\n', ...
    mean(resultTable.반응시간_초), mean(resultTable.정답여부) * 100);

% 실제 CSV 저장을 테스트해 보고 싶을 때 아래 5줄의 주석을 해제하세요.
% dataDir = fullfile(pwd, 'data');
% if ~isfolder(dataDir), mkdir(dataDir); end
% timeStr  = string(datetime('now', 'Format', 'yyyyMMdd_HHmmss'));
% fileName = fullfile(dataDir, sprintf('%s_demo_%s.csv', subjectID, timeStr));
% writetable(resultTable, fileName, 'Encoding', 'UTF-8');
