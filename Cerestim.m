classdef Cerestim < mladapter

    properties
        Stimulator = []
        Channel = []              % [ch1 ch2]
        Delay = []                % defines condition
        Amplitude = []            
        Frequency = []            % main pulse frequency (Hz)
        Pulses = 1
        Duration = []
        verbose = 1
    end

    properties (Access = protected)
        currStimNum = 1
        doStim = []
    end

    methods
        function obj = Cerestim(varargin)
            obj@mladapter(varargin{1});

            obj.Stimulator = varargin{2};
            obj.Channel    = varargin{3};
%             obj.delay      = varargin{4};
            obj.Amplitude  = varargin{4};
            obj.Frequency  = varargin{5};
            obj.Pulses     = varargin{6};
            obj.Duration   = varargin{7};
            obj.Delay = varargin{8};

            obj.setPatterns();
        end

        function delete(obj)
            obj.disableStimulator();
        end

        function init(obj,p)
            init@mladapter(obj,p);
        end

        function fini(obj,p)
            fini@mladapter(obj,p);
        end

        function continue_ = analyze(obj,p)
            continue_ = analyze@mladapter(obj,p);

            if p.scene_frame() == 0 && ~isempty(obj.Stimulator)

                if obj.doStim(obj.currStimNum)

                    d = obj.Delay(obj.currStimNum);
                    freq_main = obj.Frequency(obj.currStimNum);
                    pulse_delay = max(d,0); 
                    % pulses = obj.Pulses(obj.currStimNum);
%disp(d)
                    % Time between pulse pairs
                    InterPairInterval = (1000/freq_main) - pulse_delay;
                    pulses = obj.Pulses(obj.currStimNum);
                    amp = obj.Amplitude;

                    % CONDITION LOGIC
                    
                    if d == -2
                        obj.Stimulator.beginSequence();
                        % No stimulation 
                        % obj.Stimulator.wait(1);
                        obj.Stimulator.endSequence();
                       

                    elseif d == -1
                        obj.Stimulator.beginSequence();
                      
                        % Single electrode 
                        obj.Stimulator.autoStim(obj.Channel(1), obj.currStimNum);
                       
                        obj.Stimulator.endSequence();

                    elseif d == 0
                        obj.Stimulator.beginSequence();
                      
                        % Two electrodes simultaneous 
                        obj.Stimulator.beginGroup();
                        obj.Stimulator.autoStim(obj.Channel(1), obj.currStimNum);
                        obj.Stimulator.autoStim(obj.Channel(2), obj.currStimNum);
                        obj.Stimulator.endGroup();
                        
                        obj.Stimulator.endSequence();

                    elseif d > 0
                        %  Two electrodes with delay 
                        obj.Stimulator.beginSequence();
                            for i = 1:pulses                     
                            obj.Stimulator.autoStim(obj.Channel(2), obj.currStimNum);
                            %obj.Stimulator.wait(d);
                            obj.Stimulator.autoStim(obj.Channel(1), obj.currStimNum);
                           obj.Stimulator.wait(InterPairInterval);
                           end
                        obj.Stimulator.endSequence();
                        

                    end

%                     obj.Stimulator.endSequence;
                end
            end

            obj.Success = obj.Adapter.Success;
        end

        function draw(obj,p)
            draw@mladapter(obj,p);

            if p.scene_frame() == 0 && ~isempty(obj.Stimulator)
                if obj.doStim(obj.currStimNum)
                    obj.Stimulator.play(1);
                end
                obj.currStimNum = obj.currStimNum + 1;
            end
        end

        
        % PATTERN SETUP
        
        function setPatterns(obj)

    totalStim = length(obj.Delay);

    if isempty(obj.Stimulator)
        obj.printToCommand("No stimulator connected");
        return;
    end

    %sobj.printToCommand('clc');
    
    for i = 1:totalStim

        d = obj.Delay(i);
        freq = obj.Frequency(i);
        pulses = obj.Pulses(i);
        amp=obj.Amplitude(i);

        
        % DEFINE AMPLITUDE HERE
        
%         if d == -2
%             amp = 0;              
        if d == -2
            amp = 0;             % no stim
        elseif d == -1
            amp = amp; 
        elseif d == 0 
            amp = amp/2;
        elseif d > 0
            amp = amp/2;             
            freq = 1000/d;
            pulses =1;
        end

       
        if amp == 0 || pulses == 0
            obj.doStim = [obj.doStim; false];
            continue;
        else
            obj.doStim = [obj.doStim; true];
        end

     
        if obj.Duration(i) > 0
            pulses = 1 + (obj.Duration(i) * freq) / 1000;
        end

        obj.printToCommand( ...
            sprintf("Stim: amp=%d uA, pulses=%d, freq=%.1f Hz", ...
            amp, pulses, freq));

      
        % SET WAVEFORM
       
        obj.Stimulator.setStimPattern( ...
            'waveform', i, ...
            'polarity', 0, ...
            'Pulses', pulses, ...
            'amp1', amp, ...
            'amp2', amp, ...
            'width1', 170, ...
            'width2', 170, ...
            'interphase', 60, ...
            'frequency', freq);

        
    end
end

        function disableStimulator(obj)
            obj.Stimulator = [];
        end

        function printToCommand(obj,message)
            if obj.verbose
                if strcmp(message,'clc')
                    clc;
                else
                    disp(message);
                end
            end
        end
    end
end