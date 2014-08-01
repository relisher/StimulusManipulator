% function presentGrating(movieDurationSecs, waitframes, ORI,TF)
Screen('CloseAll')
clear
import java.io.*;
import java.net.*;
import java.lang.*;
savePath = 'C:\Users\schummerslab\Documents';
%Screen('Preference', 'SkipSyncTests', 1);

timeAfter = GetSecs * 1000;

%%TCP CHECK

 %openSocket = ServerSocket(8153);
 %connectionSocket = openSocket.accept();
 %charAt = @(str,idx)str(idx); %operation to find the cmhar in a string, used later
 
 %%UDP CHECK
serverSocket = DatagramSocket(9865);
receiveData = int8(zeros(1,8));
charAt = @(str,idx)str(idx);
%% Set up DIO object for triggering
% global dio
% dio = digitalio('mcc',0);
% addline(dio,0,'in');% pin #25 on PCI-DAS08 connector cable
    

%% Stimulus position and size:
loadScreen
stimSize = 15;% size in DVA
stimPix = round(stimSize*Pix_deg);
try
    load('cp')
catch
    cp = [ScreenPixX/2, ScreenPixY/2];
end

rect = [0 0 stimPix,stimPix];
imSize = rect(3:4);
newRect = CenterRectOnPoint(rect,cp(1),cp(2));


defaultHorizontal = 600;
defaultVertical = 600;
horizontalCompare = defaultHorizontal;
verticalCompare = defaultVertical;





%% Input parameters:
waitframes = 1;
%% Grating Parameters:
RANDOM = 0;
CONTRAST = .5;
TF = 6;
% SFs = (1.92)./([1 2 4 8 16 32 64 128])./1; 
SFs = .5./[1 2 4 8 12 16 24 32];
OriStep = 22.5;% degrees per second
ORs = 0:(OriStep):359.99;
sq = 1;

%% Stimulus timing:
nRepeats = 1;
preStimTime = 4;
postStimTime = 1;
preStimFrames = preStimTime*Hz;
postStimFrames = postStimTime*Hz;
ONtime = 2;
OFFtime = 2;
ONframes = ONtime.*Hz;
OFFframes = OFFtime.*Hz;
nConds = 16; 

OriUpdateRate = 6;% should go into frame rate (144) - acceptable values are: [ 1     2     3     4     6     8     9    12   16    18    24    36    48    72]


ONOFF = cat(3,zeros(nConds,OFFframes),ones(nConds,ONframes));
ONOFF = permute(ONOFF,[2 3 1]);
ON = ones(nConds,ONframes);
OFF = zeros(nConds,OFFframes);

numFrames = round(Hz);
phases = (0:Hz-1)./Hz.*2*pi;

% phaseList = 1:size(ON,1);
% phaseList = floor(phaseList.*TF)+1;
% phaseList = mod(phaseList,Hz);


%% make stimulus sequence from the parameters:
OriList = ORs;
SFlist = repmat(.1,1,nConds);
TFlist = repmat(TF,1,nConds);
CONlist = repmat(CONTRAST,1,nConds);
phaseList = 1:size(ON,2);
phaseList = floor(phaseList.*TF)+1;
phaseList = mod(phaseList,360);
phaseList = phaseList(:);
% phaseList = zeros(size(phaseList));

OriShouldBe = repmat(OriList',[1,size(ON,2)]);
SFShouldBe = repmat(SFlist',[1,size(ON,2)]);
TFShouldBe = repmat(TFlist',[1,size(ON,2)]);
CONShouldBe = repmat(CONlist',[1,size(ON,2)]);
phaseShouldBe = repmat(phaseList',size(ON,1),1);

OriShouldBe = cat(2,OriShouldBe,OFF);
SFShouldBe = cat(2,SFShouldBe,OFF);
TFShouldBe = cat(2,TFShouldBe,OFF);
CONShouldBe = cat(2,CONShouldBe,OFF);
phaseShouldBe = cat(2,phaseShouldBe,OFF);

OriShouldBe = reshape(OriShouldBe',size(OriShouldBe,1)*size(OriShouldBe,2),1);
SFShouldBe = reshape(SFShouldBe',size(OriShouldBe,1)*size(OriShouldBe,2),1);
TFShouldBe = reshape(TFShouldBe',size(OriShouldBe,1)*size(OriShouldBe,2),1);
CONShouldBe = reshape(CONShouldBe',size(OriShouldBe,1)*size(OriShouldBe,2),1);
phaseShouldBe = reshape(phaseShouldBe',size(OriShouldBe,1)*size(OriShouldBe,2),1);

rand('twister',5489)
clear CondList
for i = 1:500;
    if RANDOM == 1
        CondList(i,:) = randperm(nConds);
        
    elseif RANDOM == 0
        CondList(i,:) = (1:nConds);
    end
end

SFShouldBe = cat(1,zeros(preStimFrames,1),SFShouldBe);
SFShouldBe = cat(1,SFShouldBe,zeros(postStimFrames,1));
SFratio = SFShouldBe;
SFratio = SFratio./max(SFs);

TFShouldBe = cat(1,zeros(preStimFrames,1),TFShouldBe);
TFShouldBe = cat(1,TFShouldBe,zeros(postStimFrames,1));

OriShouldBe = cat(1,zeros(preStimFrames,1),OriShouldBe);
OriShouldBe = cat(1,OriShouldBe,zeros(postStimFrames,1));

CONShouldBe = cat(1,zeros(preStimFrames,1),CONShouldBe);
CONShouldBe = cat(1,CONShouldBe,zeros(postStimFrames,1));

phaseShouldBe = cat(1,zeros(preStimFrames,1),phaseShouldBe);
phaseShouldBe = cat(1,phaseShouldBe,zeros(postStimFrames,1));
nPTBframes = length(phaseShouldBe);
phaseShouldBe(find(phaseShouldBe==0)) = 1;

% return

escapeKey               = KbName('esc'); %esc on Windows, ESCAPE on Mac OS
[touch, secs, keyCode]  = KbCheck;
ESC = 1;
% return

try
    
%% Make stimuli and load them to the graphics card
	%% This script calls Psychtoolbox commands available only in OpenGL-based 
	
	%% Get the list of screens and choose the one with the highest screen number.
	screens=Screen('Screens');
	screenNumber=max(screens);
%     testScreen = Screen('Resolution', screenNumber, ScreenPixX, ScreenPixY);
%     Screen('Resolution',screenNumber)
	
     % Open pipe to get information from Python
        
%     pipe_name = '/Users/intern/Documents/pipe_eyes';
%     y = fopen(pipe_name,'r')


    %% Find the color values which correspond to white and black: Usually
	white=WhiteIndex(screenNumber);
	black=BlackIndex(screenNumber);
	gray=round((white+black)/2);
    if gray == white
		gray=white / 2;
    end
	inc=white-black;

	w = Screen('OpenWindow',screenNumber, white);
	AssertGLSL;
    if sq == 1
        gratingtex = CreateProceduralSineGrating(w, stimPix, stimPix,[0.5 0.5 0.5 0.0],[],20);
    else
        gratingtex = CreateProceduralSineGrating(w, stimPix, stimPix,[0.5 0.5 0.5 0.0],[],.5);
    end
    m = ones(stimPix);
    c = 0;
    blankTex = Screen('MakeTexture', w, gray+inc*m'.*c);
    noiseTex = Screen('MakeTexture', w, inc*rand(size(m')));

	frameRate=Screen('FrameRate',screenNumber);
	priorityLevel=MaxPriority(w);
	Priority(priorityLevel);
    % NEW: Perform extra calibration pass to estimate monitor refresh
    [ ifi nvalid stddev ]= Screen('GetFlipInterval', w, 100, 0.00005, 20);
    fprintf('Measured refresh interval, as reported by "GetFlipInterval" is %2.5f ms. (nsamples = %i, stddev = %2.5f ms)\n', ifi*1000, nvalid, stddev*1000);

    % Perform initial Flip to sync us to the VBL and for getting an initial
    % VBL-Timestamp for our "WaitBlanking" emulation:
    vbl=Screen('Flip', w);
    HideCursor

%     bitval = getvalue(dio.Line(1));
    bitval = 0.4;
    tryal = 1;

    while ESC==1
        [touch, secs, keyCode] = KbCheck;ESC=(1-keyCode(escapeKey));
        
        while ESC==1 & bitval<0.5
%             bitval = getvalue(dio.Line(1)); %Uncomment afterwards
            bitval = 1; %comment out later
            [touch, secs, keyCode] = KbCheck;ESC=(1-keyCode(escapeKey));
            Screen('DrawTexture', w, noiseTex,[1 1 size(m,1) size(m,2)],newRect);
%             Screen('DrawTexture', w, maskTex,[1 1 size(m,1) size(m,2)], newRect);
            vbl = Screen('Flip', w, vbl + (waitframes - 0.5) * ifi);

        end
%         bitval = getvalue(dio.Line(1));
        
        %% save the stimulus info
        clear stim
        stim.rect = newRect;
        stim.TF = TFShouldBe;
        stim.SF = SFShouldBe;
        stim.ORI = OriShouldBe;
        stim.CONShouldBe = CONShouldBe;
        stim.Hz = Hz;
        % stim.cycleFrames = cycleFrames;
        stim.preStimTime = preStimTime;
        stim.postStimTime = postStimTime;
        stim.ScreenPixX = ScreenPixX;
        stim.ScreenPixY = ScreenPixY;
        stim.VD = VD;
        stim.CondOrder =  CondList(tryal,:)';
        
        tt = [(fix(clock))];
        fn = [sprintf('%02d',tt(1)) sprintf('%02d',tt(2)) sprintf('%02d',tt(3)) '_' sprintf('%02d',tt(4)) '_' sprintf('%02d',tt(5)) '_' sprintf('%02d',tt(6))];
        save([savePath,fn],'stim')
        
        %%NAMED PIPE INIT/ERROR CATCHING
        
%         notWorking = 1;
%         attempt = 1;
%         while notWorking == 1 && attempt < 4
%             information = fgets(y);
%             %information = jtcp('READ', jtcobj);
%             informationSplit = strsplit(information, ',');
%             try
%                 verticalGaze = informationSplit{2};
%                 notWorking = 0;
%             catch
%                 disp(['Attempt number: ' num2str(attempt')]);
%                 if attempt == 4
%                     notWorking = 1;
%                 else
%                     fprintf('will try to get stimulus information until attempt 4')
%                     attempt = attempt + 1;
%                     pause(5)
%                 end
%             end
%         end
        
%% Wait for trigger, and present the stimuli
        
            
           
        startTime = GetSecs;
        gazeInfo = '000,000';
        for i=1:nPTBframes %movieDurationFrames
            [touch, secs, keyCode] = KbCheck;ESC=(1-keyCode(escapeKey));
            
              
                
                %information = fgets(y); %for named pipe
                receivePacket = DatagramPacket(receiveData, 8);
                serverSocket.receive(receivePacket);
                information = receivePacket.getData();
                %information = '100,100';
                
%                 if isempty(information)
%                     openSocket.close();
%                     break
%                 end
%                 
                information = char(information); %change Java String to MATLAB char array
                iterator = 1;
%                 
                while iterator < 7
                    gazeInfo(iterator) = charAt(information, iterator);
                    iterator = iterator + 1;
                end
%                 
                if gazeInfo(4) == ','
                    information = char(gazeInfo);
                    
                    informationSplit = strsplit(information, ',');
                    verticalGaze = informationSplit{2};
                    horizontalGaze = informationSplit{1};
                    verticalGaze = str2num(verticalGaze);
                    horizontalGaze = str2num(horizontalGaze);
                    horizontalGaze = (((horizontalGaze * 2) * ((ScreenPixX-stimPix)/200)) + (0.5 * stimPix)); % scale imageY position
                   verticalGaze = ScreenPixY - (verticalGaze * (ScreenPixY/150) + (0.5 * stimPix)); % scale imageX position

                    
                    try
                        if horizontalCompare ~= horizontalGaze || verticalCompare ~= verticalGaze
                            newRect = CenterRectOnPoint(rect, horizontalGaze, verticalGaze);
                        else
                            ; % do nothing
                        end
                    catch
                        continue
                    end
                    
                    verticalGaze = [];
                    horizontalGaze = [];
                else
                    continue
                end
            
              %end
            % end
            
            
            
            if ESC~=1
                serverSocket.close();
                break
             end
            
            % Disable alpha-blending, so we can just overwrite the framebuffer
        % with our new pixels:
%         Screen('Blendfunction', w, GL_ONE, GL_ZERO);
        
        
        % Now we draw the noise texture and use alpha-blending of
        % the drawn noise color pixels with the destination alpha-channel,
        % thereby multiplying the incoming color values with the stored
        % alpha values -- effectively a contrast modulation. The GL_ONE
        % means that we add the final contrast modulated noise pixels to
        % the current content of the window == the neutral gray background.
%         Screen('Blendfunction', w, GL_DST_ALPHA, GL_ONE);
        
        
%             if(CONShouldBe(i)>0)
%                   Screen('DrawTexture', w  , gratingtex, [1 1 size(m,1)./2 size(m,2)./2],newRect, OriShouldBe(i)+90, [], [], [], [], 1, [0, SFShouldBe(i)./Pix_deg, CONShouldBe(i), 0]);
              Screen('DrawTexture', w  , gratingtex, [1 1 size(m,1)./2 size(m,2)./2],newRect, OriShouldBe(i)+90, [], [], [], [], 1, [phaseShouldBe(i), SFShouldBe(i)./Pix_deg, CONShouldBe(i), 0]);
%             else
%             end
            vbl = Screen('Flip', w, vbl + (waitframes - 0.5) * ifi);
%             time_str = toc;
        end
%         bitval = getvalue(dio.Line(1));

        loopTime = GetSecs-startTime
        pause(1)

        tryal = tryal+1;
    end
        Priority(0);


    Screen('Close');
    %daqreset
    Screen('CloseAll');
    ShowCursor
catch
    %this "catch" section executes in case of an error in the "try" section
    %above.  Importantly, it closes the onscreen window if its open.
    Screen('CloseAll');
    Priority(0);
    serverSocket.close();
    psychrethrow(psychlasterror);
end %try..catch..
