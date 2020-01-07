function laserrep

IOPort('Write',FootLaserPort, uint8([char(204) 'G111' char(185)]));
WaitSecs(0.01);
IOPort('Purge',FootLaserPort);

