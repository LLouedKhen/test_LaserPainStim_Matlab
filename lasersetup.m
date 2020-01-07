function FootLaserPort=lasersetup

%% SETUP serial port for laser control

[FootLaserPort, errmsg] = IOPort('OpenSerialPort','COM1');
IOPort('Purge', FootLaserPort);

fprintf('\n Start connection...Switch to Serial NOW!');
t0=GetSecs;
while GetSecs-t0<7
    IOPort('Write',FootLaserPort, uint8(uint8(char(80))));
end
WaitSecs(2);
