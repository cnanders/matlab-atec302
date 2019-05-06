%% Add src (function in this dir, navigate to this dir to run)

[cDirThis, ~, ~] = fileparts(mfilename('fullpath'));
cDirSrc = fullfile(cDirThis, '..', 'src');
addpath(genpath(cDirSrc));


%% Initiate the instrument class

cHost = '192.168.20.36';
comm = atec.ATEC302(...
    'cHost', cHost ...
);

comm.init();
comm.getSetValue();
% comm.getTemperature()