function stimulate(stimulator, channels, waveform, delay, pulses, frequency)

    % STIMULATE
    %
    % waveform must already be defined using setStimPattern()

    if isempty(stimulator)
        disp("Cannot stimulate: no device connected");
        return
    end

    if delay == -2
        return
    end

    stimulator.beginSequence();

    if delay == -1

        stimulator.autoStim(channels(1), waveform);

    elseif delay == 0

        stimulator.beginGroup();

        stimulator.autoStim(channels(1), waveform);
        stimulator.autoStim(channels(2), waveform);

        stimulator.endGroup();


    elseif delay > 0

        InterPairInterval = (1000 / frequency) - delay;

        for i = 1:pulses

            stimulator.autoStim(channels(1), waveform);
            stimulator.autoStim(channels(2), waveform);
            stimulator.wait(InterPairInterval);

        end
    end

    stimulator.endSequence();

    stimulator.play(1);

end