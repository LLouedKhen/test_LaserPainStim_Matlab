function FootLaserPort = SetupFootLaserSerialControl(LaserFootEnergy,FootLaserPort,iti)

fprintf('\nRelease Laser Foot Pedal NOW!');
WaitSecs(1);

% laser pulse duration: 4 for 5 ms and 5 for 6 ms
% laser energy conversion: (Energy-0.5)/0.25, e.g. 10 for 3J - SEEMS THAT 1
% FOR 0.5J AND 11 FOR 3J

% fprintf('\n\nThis is COM1 laser.\n\n');

% LaserFootEnergy = 3.5; % J
LaserFootPulse = 6; % ms
LaserFootSpotsize = 7; % mm

LaserFootEnergyCode = (LaserFootEnergy-0.5)/0.25+1;
LaserFootPulseCode = LaserFootPulse - 1;
LaserFootSpotsizetCode = LaserFootSpotsize - 4;

% switch laser on
IOPort('Write',FootLaserPort, uint8([char(204) 'L111' char(185)]));
WaitSecs(1);
% switch HeNe on
IOPort('Write',FootLaserPort, uint8([char(204) 'H111' char(185)]));
WaitSecs(1);
% switch operate on
IOPort('Write',FootLaserPort, uint8([char(204) 'O111' char(185)]));
WaitSecs(0.5);

% calibrate for the specified laser parameters
IOPort('Write',FootLaserPort, uint8([char(204) 'C' char(LaserFootPulseCode) char(LaserFootEnergyCode) char(1) char(185)]));
WaitSecs(7.5);

% load
IOPort('Write',FootLaserPort, uint8([char(204) 'P' char(LaserFootPulseCode) char(LaserFootEnergyCode) char(LaserFootSpotsizetCode) char(185)]));
fprintf('\n!!!!!!!!!Press the Laser Foot Pedal!!!!!!');
WaitSecs(iti);

