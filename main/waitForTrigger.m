function [triggerTime] = waitForTrigger()

    trigger = input('Waiting for trigger...','s');

    if strcmp(trigger,'t')
        triggerTime = datetime;
    else
        triggerTime = wait_for_trigger;
    end

    
