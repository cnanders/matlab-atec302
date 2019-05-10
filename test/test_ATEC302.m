%% Add src (function in this dir, navigate to this dir to run)

[cDirThis, ~, ~] = fileparts(mfilename('fullpath'));
cDirSrc = fullfile(cDirThis, '..', 'src');
addpath(genpath(cDirSrc));


%% Initiate the instrument class

cHost = '192.168.20.36';


comm1 = atec.ATEC302(...
    'u16Port', 4001, ...
    'cHost', cHost ...
);

comm1.init();
comm1.getSetValue()
comm1.getTemperature()


comm2 = atec.ATEC302(...
    'u16Port', 4002, ...
    'cHost', cHost ...
);

comm2.init();
comm2.getSetValue()
comm2.getTemperature()



comm3 = atec.ATEC302(...
    'u16Port', 4003, ...
    'cHost', cHost ...
);

comm3.init();
comm3.getSetValue()
comm3.getTemperature()


comm4 = atec.ATEC302(...
    'u16Port', 4004, ...
    'cHost', cHost ...
);

comm4.init();
comm4.getSetValue()
comm4.getTemperature()
