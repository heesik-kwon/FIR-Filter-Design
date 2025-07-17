clc

%fixed_mode = 0; % '0' = floating
fixed_mode = 1; % '1' = fixed

[FileName, PathName] = uigetfile('*.txt', 'select the capture binary file');
FullPath = fullfile(PathName, FileName);

[FID, message] = fopen(FullPath, 'r');

if (fixed_mode)
    waveform = fscanf(FID, '%d', [1 Inf]);
else
    waveform = fscanf(FID, '%f', [1 Inf]);
end

fclose(FID);

Iwave = waveform(1,:);

figure
pwelch(double(Iwave))