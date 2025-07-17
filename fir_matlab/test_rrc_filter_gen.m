% Created on 2025/07/17 by jihan

clc;

% RRC filter coefficient
rolloff = 0.3;
span = 16;
sps = 2;
rrc_coef = rcosdesign(rolloff, span, sps, "sqrt");
%[H,w] = freqz(rrc_coef);
%plot(w, abs(H), 'r'), grid;
freqz(rrc_coef);
