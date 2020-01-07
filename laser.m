function laser(LaserFootEnergy,mode)
iti=3;
FootLaserPort = 0;

if mode == 1
    lasersetup
else
end

SetupFootLaserSerialControl(LaserFootEnergy,FootLaserPort,iti)
IOPort('Write',FootLaserPort, uint8([char(204) 'G111' char(185)]));
WaitSecs(0.01);
IOPort('Purge',FootLaserPort);
