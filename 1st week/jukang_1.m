clear all; clc

% 1. 1~100까지 임의의 수로 이루어진 50x2 행렬을 만드세요.
RanDomMatrix = randi([1,100], 50, 2);


% 2. 3열에 해당 행의 1열과 2열의 합을 넣으세요.
a = RanDomMatrix(:,1);
b = RanDomMatrix(:,2);
RanDomMatrix(:, 3) = a + b;
% 다른 구현 방법 
% RanDomMatrix(:, 3) = RanDomMatrix(:,1) + RanDomMatrix(:,2);


% 3. 4열에 1~50까지 "모든 수"를 랜덤한 순서로 넣으세요.
c = randperm(50);
RanDomMatrix(:,4) = c;

% 4. 5열에 해당 행의 3열과 4열의 합을 3으로 나눈 수를 넣으세요.
Third = RanDomMatrix(:,3);
Fourth = RanDomMatrix(:, 4);
d = (Third + Fourth) / 3;
RanDomMatrix(:, 5) = d;

% zeros 사용해서 0으로 된 행렬 생성하여 자기가 넣고 싶은 숫자를 넣으면 된다. 
% 하나의 "틀"을 만드는 그런 것이다. 
% 행렬에서 자극셋을 미리 만들고 랜덤하게 자극 제시하는 그런 방식

