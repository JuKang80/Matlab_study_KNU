# 6주차 코드 리뷰: 더 MATLAB답게(간결하게) 다듬기 & 이해하기 어려운 부분 분석

대상 파일: [`Comment_version_of_Week_6th.m`](./Comment_version_of_Week_6th.m)

현재 코드는 모든 요구사항을 정확히 수행하지만, **C언어 스타일로 변수와 조건문을 일일이 나열**하고 있어서 전체 길이가 약 340줄에 달합니다. 우리가 4~5주 차에서 배운 **MATLAB의 행렬/벡터 연산**과 직관적인 상태 관리를 적용하면 코드를 **절반(약 150줄) 이하**로 줄이면서도 훨씬 읽기 쉽게 만들 수 있습니다.

---

## 1. 사람이 읽을 때 직관적이지 않거나 과하게 복잡한 부분 (3가지)

### ① 휴식 타이머 계산 방식 (`redRestUntil` vs `redRestRemaining`)
* **현재 방식 ([L72-L79](./Comment_version_of_Week_6th.m#L72-L79), [L117-L160](./Comment_version_of_Week_6th.m#L117-L160)):**
  * `redRestUntil = currentTime + restDuration`처럼 **'미래의 절대 시각(초)'**을 저장해 두고,
  * 매 프레임마다 `currentTime >= redRestUntil`로 휴식 종료 여부를 비교한 뒤,
  * 화면 출력용으로 또 `redRestRemaining = max(0, redRestUntil - currentTime)`을 따로 계산합니다.
  * 이 때문에 타원 하나당 휴식 관련 변수만 3개(`redRestUntil`, `redRested`, `redRestRemaining`), 두 타원 합쳐 **총 6개의 변수**가 서로 얽혀 있어 머릿속으로 시간 흐름을 따라가기가 어렵습니다.
* **더 직관적인 방식 (카운트다운 변수 하나로 통합):**
  * 사람이 생각하는 방식 그대로 **"남은 휴식 시간(`restLeft`)"** 변수 하나만 두면 됩니다.
  * 중간선을 처음 넘는 순간 `restLeft = 5.0;`으로 설정하고,
  * `restLeft > 0`이면 이동하지 않고 매 프레임 대기 시간(`dt = 0.25`)만큼 `restLeft = max(0, restLeft - dt);`로 깎아주기만 하면 끝납니다! (`RestUntil`이라는 개념 자체가 필요 없어집니다.)

---

### ② `movementData(end+1, :)` 동적 확장과 `repmat` 테이블 변환
* **현재 방식 ([L88-L100](./Comment_version_of_Week_6th.m#L88-L100), [L250-L260](./Comment_version_of_Week_6th.m#L250-L260), [L294-L309](./Comment_version_of_Week_6th.m#L294-L309)):**
  ```matlab
  movementData = zeros(0, 10);
  ...
  movementData(end+1, :) = [frame, elapsedTime, redX, blueX, ...]; % 10개 열
  ...
  movementTable.RaceResult = repmat({winner}, size(movementData, 1), 1);
  ```
  * **이해하기 어려운 이유:**
    1. 1열부터 10열까지 어떤 값이 들어가는지 주석과 일일이 대조해야 합니다.
    2. `while` 루프 안에서 `end+1`로 행렬 크기를 매번 늘리는 것은 MATLAB에서 메모리 재할당 경고가 뜨는 대표적인 패턴입니다.
    3. 셀 배열 `{winner}`를 `repmat`으로 행 개수만큼 복제해서 테이블 열에 붙이는 문법(`movementTable.RaceResult = repmat({winner}, ...)`)은 초보자가 보기에 생소하고 복잡합니다.
* **더 간단한 대안:**
  * 문제 요구사항은 *"엑셀 또는 메모장에 경기 결과와 각 타원의 이동 거리를 저장하세요"*입니다.
  * 꼭 `.csv`와 `.txt` 두 개를 다 만들 필요 없이, `fopen` / `fprintf`로 **메모장(`.txt`) 또는 `.csv` 파일 하나**에 매 프레임 이동 거리와 마지막 최종 결과(`Winner`, `Total Distance`)를 순서대로 출력하면 `array2table`이나 `repmat` 없이 10줄 이내로 끝납니다.

---

### ③ 줄바꿈(`...`)의 과도한 사용
* **현재 방식 ([L189-L204](./Comment_version_of_Week_6th.m#L189-L204)):**
  ```matlab
  redRect = [ ...
      redX - ovalWidth/2, ...
      redY - ovalHeight/2, ...
      redX + ovalWidth/2, ...
      redY + ovalHeight/2];
  ```
  * 5주 차 코드에서는 한 줄로 적었던 사각형 좌표나 `DrawLine`, `sprintf` 호출을 거의 모든 줄마다 `...`로 쪼개 놓아서, 스크롤이 길어지고 한눈에 코드 구조가 들어오지 않습니다.

---

## 2. 더 MATLAB답게(간결하게) 바꿀 수 있는 부분

### ① 빨간 타원 / 파란 타원 변수를 `[1 x 2]` 벡터로 묶기 (코드량 50% 감소)
현재 코드는 `redX`/`blueX`, `redTotal`/`blueTotal`, `redCurrent`/`blueCurrent`, `redRested`/`blueRested`처럼 **똑같은 변수와 `if`문을 빨강용, 파랑용으로 2번씩 복사-붙여넣기** 했습니다.

MATLAB의 강점인 **벡터(인덱스 `1`: Red, 인덱스 `2`: Blue)**를 쓰면 두 타원의 상태와 계산을 한 줄로 묶을 수 있습니다:

```matlab
% [1열: Red, 2열: Blue]로 한 번에 초기화
posX      = [startX, startX] + ovalWidth / 2;
posY      = screenHeight * [0.35, 0.65];
totalDist = [0, 0];
currDist  = [0, 0];
restLeft  = [0, 0];
hasRested = [false, false];
```

이렇게 묶으면 이동 및 휴식 로직도 `for i = 1:2` 루프 하나로 깔끔하게 합쳐집니다:

```matlab
dt = 0.25; % 프레임 간격

for i = 1:2
    % 1) 이전 프레임에서 중간선을 처음 넘었다면 5초 휴식 시작
    if posX(i) >= middleX && ~hasRested(i) && (posX(i) + ovalWidth/2 < finishX)
        restLeft(i) = restDuration;
        hasRested(i) = true;
    end

    % 2) 휴식 중이면 타이머만 감소, 아니면 랜덤 이동
    if restLeft(i) > 0
        currDist(i) = 0;
        restLeft(i) = max(0, restLeft(i) - dt);
    elseif posX(i) + ovalWidth/2 < finishX
        currDist(i)  = randi([minStep, maxStep]);
        totalDist(i) = totalDist(i) + currDist(i);
        posX(i)      = min(posX(i) + currDist(i), finishX - ovalWidth/2);
    end
end
```

---

### ② 5주 차에서 배운 `Screen('FillOval')` 다중 도형 그리기 활용
5주 차 [`Shape_1_grid_style.m`](../5th%20week/Shape_1_grid_style.m#L39-L62)에서 우리는 **`4 x N` 좌표 행렬**과 **`3 x N` 색상 행렬**을 사용해 `Screen('FillOval')` **한 번의 호출로 여러 개의 원을 동시에 그리는 법**을 이미 사용했습니다.

현재 6주 차 코드에서는 `FillOval`을 두 번 따로 부르고 있는데, 5주 차 방식으로 바꾸면 훨씬 MATLAB답습니다:

```matlab
% 3x2 색상 행렬 (1열: 빨강, 2열: 파랑)
ovalColors = [255,   0; ...
                0,   0; ...
                0, 255];

% 4x2 사각형 좌표 행렬 (1열: 빨간 타원, 2열: 파란 타원)
ovalRects = [posX - ovalWidth/2; ...
             posY - ovalHeight/2; ...
             posX + ovalWidth/2; ...
             posY + ovalHeight/2];

% 단 한 줄로 두 타원 동시에 그리기!
Screen('FillOval', window, ovalColors, ovalRects);
```

---

### ③ 4주 차에서 배운 `Screen('DrawLines')` 활용 (선택 사항)
출발선, 중간선, 도착선 3개의 세로선도 `Screen('DrawLine')`을 3번 호출하는 대신, 4주 차 [`Line_1.m`](../4th%20week/Line_1.m#L40)에서 쓴 `Screen('DrawLines')`로 한 번에 그릴 수도 있고, 혹은 가독성을 위해 지금처럼 한 줄짜리 `DrawLine` 3개로 두어도 좋습니다:

```matlab
Screen('DrawLine', window, white, startX,  50, startX,  screenHeight - 50, 2);
Screen('DrawLine', window, white, finishX, 50, finishX, screenHeight - 50, 2);
Screen('DrawLine', window, white, middleX, 50, middleX, screenHeight - 50, 1);
```

---

## 3. 요약 비교표

| 구분 | 현재 `Comment_version_of_Week_6th.m` | MATLAB다운 개선안 |
| :--- | :--- | :--- |
| **타원 변수 관리** | `redX`, `blueX` 등 모든 변수를 2개씩 개별 선언 (총 16개 이상) | `[Red, Blue]` 1x2 벡터로 통합 (`posX`, `totalDist` 등 6개) |
| **이동 및 휴식 로직** | 똑같은 25줄짜리 `if`문을 빨강/파랑 2번 복붙 | `for i = 1:2` 루프 하나로 통합 |
| **휴식 타이머 원리** | `GetSecs` 미래 목표 시각(`RestUntil`) 저장 후 역산 (복잡함) | 남은 시간(`restLeft = 5`)에서 `dt(0.25초)`씩 직접 차감 (직관적) |
| **타원 그리기** | `redRect`, `blueRect` 따로 계산 후 `FillOval` 2번 호출 | `4x2` 좌표 행렬로 묶어 `FillOval` 1번 호출 (5주 차 방식) |
| **결과 저장** | `movementData(end+1,:)` + `array2table` + `repmat` + 파일 2개 | `fprintf` 기반 텍스트/CSV 기록 또는 간단한 행렬 저장 |

