lib.locale()
Duty = nil

function ToggleDuty()
    local result = SetDuty(not GetPlayerOnDuty())
    if (not result) then return nil end

    Duty = result.onDuty
    return result
end

function SaveDutyHistory()
    local updateHistory = Core.Callback.Await("yecoyz_duty:updateHistory")
    if (not updateHistory) then return false end

    return true
end

function GetDutyHistory()
    local history = Core.Callback.Await("yecoyz_duty:getHistory")
    if (not history) then return {} end

    return history
end

function GetIfBoss()
    local isBoss = Core.Callback.Await("yecoyz_duty:isBoss")
    if (not isBoss) then return false end

    return isBoss
end

function HasAllowedJob(jobName)
    for i = 1, #Config.Jobs do
        if (jobName == Config.Jobs[i]) then
            return true
        end
    end
    return false
end

RegisterNetEvent("yecoyz_duty:notify", function(localeKey, notifyType)
    ShowNotification(locale(localeKey), notifyType)
end)

RegisterNUICallback("Eventhandler", function(data, cb)
    if (data.event == "toggleDuty") then
        local result = ToggleDuty()
        if (not result) then return cb({ success = false }) end

        return cb({
            success = true,
            isOnDuty = result.onDuty,
            dutyStarted = result.dutyStarted,
            shifts = GetDutyHistory()
        })
    elseif (data.event == "getEmployeeHistory") then
        local employeHistory = Core.Callback.Await("yecoyz_duty:getEmployeHistory", data.data)
        return cb(employeHistory or {})
    elseif (data.event == "editShift") or (data.event == "removeShift") then
        local result = Core.Callback.Await("yecoyz_duty:" .. data.event, data.data)
        if (result and result.success) then
            ShowNotification(locale(data.event == "editShift" and "shiftEdited" or "shiftRemoved"), "success")
        else
            ShowNotification(locale("shiftChangeFailed"), "error")
        end
        return cb(result or { success = false })
    elseif (data.event == ("getLocale")) then
        local uiLocales = {}
        local locales = lib.getLocales()

        for k, v in pairs(locales) do
            if (k:find("^ui_")) then
                uiLocales[k] = v
            end
        end
        return cb(uiLocales)
    elseif (data.event == "closePage") then
        SetNuiFocus(false, false)
        return cb({ success = true })
    end

    return cb({ success = false })
end)

exports("GetOwnHistory", GetDutyHistory)
exports("SaveOwnDutyHistory", SaveDutyHistory)
