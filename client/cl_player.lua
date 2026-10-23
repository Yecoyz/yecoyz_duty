-- Player info for the duty UI, read through yecoyz_core.

function ShowNotification(text, notifyType)
    Core.Notify(text, notifyType)
end

function GetPlayerJobGradeName()
    local job = Core.GetJob()
    return job and job.gradeLabel or nil
end

function GetPlayerFullName()
    return Core.Callback.Await("yecoyz_duty:getFullName")
end

function GetPlayerJobLabel()
    local job = Core.GetJob()
    return job and job.label or nil
end

function GetPlayerJobName()
    local job = Core.GetJob()
    return job and job.name or nil
end

function GetPlayerOnDuty()
    if (Config.FrameworkBased) then
        local job = Core.GetJob()
        return job and job.onDuty or nil
    end
    return Core.Callback.Await("yecoyz_duty:getStandaloneDuty")
end

function SetDuty(status)
    return Core.Callback.Await("yecoyz_duty:setDuty", status)
end

exports("SetDuty", function(status)
    SetDuty(status)
end)

Core.OnPlayerLoaded(function()
    Duty = GetPlayerOnDuty()
    if (Duty) then
        Core.Callback.Await("yecoyz_duty:startDuty")
    end
end)
