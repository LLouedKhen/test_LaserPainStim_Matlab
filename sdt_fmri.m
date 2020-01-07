function explist=sdt_fmri(~,run,medium,high,inscanner)

% % % cond:
% % % 1 L H
% % % 2 LT H
% % % 3 L M
% % % 4 LT M
% % % 5 T

% % % inscanner = %0 pilot, 1 scanner

close all;
sca;

%% SET PARAMETERS

blocks = 5;


% setuptime = 11;
resptime = 3;


LaserFootPulse = 6; % ms
LaserFootSpotsize = 7; % mm
LaserFootPulseCode = LaserFootPulse - 1;
LaserFootSpotsizetCode = LaserFootSpotsize - 4;


% medium = 3.5;
% high = 3.75;

%% SET AUDIO

[y, freq]=audioread('move.wav');
wavedata.move{:,:,1}=[y';y'];
nrchannels = size(wavedata.move,1);
WaitSecs(0.1);
[y2, freq2]=audioread('touch_tone.wav');
wavedata.touch{:,:,1}=[y2';y2'];
nrchannels = size(wavedata.touch,1);
WaitSecs(0.1);
InitializePsychSound;
pahandle = PsychPortAudio('Open');
WaitSecs(1);
fprintf('audio setup completed\n');

%% SET Response Box

%% SET SCREEN & SHOW FIXATION

% Here we call some default settings for setting up Psychtoolbox
PsychDefaultSetup(2);

% Get the screen numbers. This gives us a number for each of the screens
% attached to our computer.
screens = Screen('Screens');

% To draw we select the maximum of these numbers. So in a situation where we
% have two screens attached to our monitor we will draw to the external
% screen.
screenNumber = max(screens);


% Define black and white (white will be 1 and black 0). This is because
% in general luminace values are defined between 0 and 1 with 255 steps in
% between. All values in Psychtoolbox are defined between 0 and 1
white = WhiteIndex(screenNumber);
black = BlackIndex(screenNumber);
grey = white / 2;

% Open an on screen window
[window, windowRect] = PsychImaging('OpenWindow', screenNumber, black);

% Get the size of the on screen window
[screenXpixels, screenYpixels] = Screen('WindowSize', window);

% Query the frame duration
ifi = Screen('GetFlipInterval', window);

% Set up alpha-blending for smooth (anti-aliased) lines
Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');

% Setup the text type for the window
Screen('TextFont', window, 'Ariel');
Screen('TextSize', window, 36);

% Get the centre coordinate of the window
[xCenter, yCenter] = RectCenter(windowRect);

% Here we set the size of the arms of our fixation cross
fixCrossDimPix = 40;

% Now we set the coordinates (these are all relative to zero we will let
% the drawing routine center the cross in the center of our monitor for us)
xCoords = [-fixCrossDimPix fixCrossDimPix 0 0];
yCoords = [0 0 -fixCrossDimPix fixCrossDimPix];
allCoords = [xCoords; yCoords];

% Set the line width for our fixation cross
lineWidthPix = 4;

% Draw the fixation cross in white, set it to the center of our screen and
% set good quality antialiasing
Screen('DrawLines', window, allCoords,...
    lineWidthPix, white, [xCenter yCenter], 2);

% Flip to the screen
Screen('Flip', window);
WaitSecs(1);

%% SETUP serial port for laser control

[FootLaserPort, errmsg] = IOPort('OpenSerialPort','COM1');
IOPort('Purge', FootLaserPort);

fprintf('\n Start connection...Switch to Serial NOW!');
t0=GetSecs;
while GetSecs-t0<7
    IOPort('Write',FootLaserPort, uint8(uint8(char(80))));
end
% WaitSecs(2);

% %% precalibrate energies
% FootLaserPort = SetupFootLaserSerialControl(medium,iti);
% IOPort('Close',FootLaserPort);
% FootLaserPort = SetupFootLaserSerialControl(high,iti)
% IOPort('Close',FootLaserPort);


%% Prepare Des List

trial = 0;
for block = 1:blocks;
    
    randcond = Shuffle([1:5]');
    randLiti = Shuffle([1:0.1:3.5]');   %check these timings
    randTiti = Shuffle([2:0.1:3]');     %check these timings
    
    for line = 1:length(randcond)
        trial = trial + 1;
        list(trial,:) = [randcond(line),randLiti(line),randTiti(line)];
    end
    
end

%% START & WAIT for SCANNER
ttl=0;

if inscanner == 1
    
    % Initialize trigger
    clear joymex
    JoyMEX('init',0);
    
    fprintf('wait 5 TRs\n')
    % Discard first 4 TRs
    while ttl < 5
        % Query postion and button state of joystick 1
        [x button] = JoyMEX(0);
        
        if any(button)
            fprintf(num2str(ttl))
            WaitSecs(0.1)
            ttl=ttl+1;
            fprintf('ttl detected\n');
        end
    end
    
else
    
end

fprintf('START\n');
tstart = GetSecs;

%% RUN Experiment, seq from list

trial=0;
for trial = 1 : length(list)
    fprintf('Trial %s\n', num2str(trial) );
%     fprintf('RELEASE the laser foot pedal\n');
    
    % play instruction to move laser beam
    PsychPortAudio('FillBuffer', pahandle, wavedata.move{:,:,1});
    PsychPortAudio('Start', pahandle, [], 0, 1);
    WaitSecs(0.1);
    
    % show fixation
    Screen('DrawLines', window, allCoords, lineWidthPix, white, [xCenter yCenter], 2);
    Screen('Flip', window);
    
    %     blockStartTime = tstart + ((block-1)*fixtime) + ((block-1)*blockon) + (length(find(deslist(1:(block-1),1) < 4))*estimtime) + (length(find(deslist(1:(block-1),2) == 1))*resptime);
%     blockStartTime = tstart + ((trial-1)*setuptime) + (trial-1)*resptime)); % fix
    
    if list(trial,1) == 5 % TOUCH ONLY
        
        % TOUCH ONLY
        % Wait right time $$$
        WaitSecs(2);
        PsychPortAudio('FillBuffer', pahandle, wavedata.touch{:,:,1});
        PsychPortAudio('Start', pahandle, [], 0, 1);
        WaitSecs(7);
        
    else
        
        if list(trial,1) < 2.5    % High energy
            LaserFootEnergy = high;
        else
            LaserFootEnergy = medium;
        end
        
        % SET LASER ENERGY
        LaserFootEnergyCode = (LaserFootEnergy-0.5)/0.25+1;
        % switch laser on
        IOPort('Write',FootLaserPort, uint8([char(204) 'L111' char(185)]));
        WaitSecs(0.1);        % TRY 0.5
        % switch HeNe on
        IOPort('Write',FootLaserPort, uint8([char(204) 'H111' char(185)]));
        WaitSecs(0.1);        % TRY 0.5
        % switch operate on
        IOPort('Write',FootLaserPort, uint8([char(204) 'O111' char(185)]));
        WaitSecs(0.2);
        
        % calibrate for the specified laser parameters
        IOPort('Write',FootLaserPort, uint8([char(204) 'C' char(LaserFootPulseCode) char(LaserFootEnergyCode) char(1) char(185)]));
        WaitSecs(4);
        
        if list(trial,1) == 2 | 4; %(cond 2 or 4 = LT)
            % touch ISI $        
            PsychPortAudio('FillBuffer', pahandle, wavedata.touch{:,:,1});
%             WaitSecs(7-list(trial,3));       % CHECK right duration
            % play auditory T cue & deliver touch
            PsychPortAudio('Start', pahandle, [], 0, 1);
            
        else if list(trial,1) == 1 | 3; %laser
%                 WaitSecs(7-list(trial,3)); % fix $
                
            else
            end
        end
        
        WaitSecs(3);
%         % laser ISI
%         WaitSecs(7-list(trial,3)); % NEEDS 7 sec minimum in total
        
        % load
        IOPort('Write',FootLaserPort, uint8([char(204) 'P' char(LaserFootPulseCode) char(LaserFootEnergyCode) char(LaserFootSpotsizetCode) char(185)]));
        fprintf('!!!!!!!!! PRESS the laser foot pedal NOW !!!!!!\n');
        
        % laser ISI
        WaitSecs(2);
%         WaitSecs(list(trial,2));
        %         t2 = WaitSecs('UntilTime', (blockStartTime  + 11 + sum(list(1:trial,2))) );
        
        % fire laser
        IOPort('Write',FootLaserPort, uint8([char(204) 'G111' char(185)]));
        WaitSecs(0.01);
        IOPort('Purge',FootLaserPort);
        
        % show screen response
        Screen('TextSize', window, 70);
        DrawFormattedText(window, 'Please respond..', 'center',...
            screenYpixels * 0.25, [1 0 0]);
        Screen('TextSize', window, 50);
        Screen('TextFont', window);
        DrawFormattedText(window, 'L button = not target', 'center', 'center', white);
        Screen('TextSize', window, 50);
        Screen('TextFont', window);
        DrawFormattedText(window, 'R button = target', 'center',...
            screenYpixels * 0.6, white);
        
        WaitSecs(0.2)
        Screen('Flip', window);
        
        % COLLECT RESPONSE HERE $
        fprintf('Release Laser Foot Pedal NOW!\n');
        
        WaitSecs(resptime);
        
    end
    
    %     explist(trial,:)=[sub,run,medium,high,trial,randcond(cond),LaserFootEnergy];
    
end


% save(['explist_sub' num2str(sub) '_run' num2str(run) '.mat'],'explist');
IOPort('Close',FootLaserPort);
sca;
PsychPortAudio('Close', pahandle);
end

%         SetupFootLaserSerialControl(LaserFootEnergy,FootLaserPort,iti); %approx 11 sec
