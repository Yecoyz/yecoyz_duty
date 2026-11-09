lib.locale()

-- Everything the duty UI shows. Used by /duty and by the tablet app.
-- Returns nil when the player's job is not one of Config.Jobs.
function GetDutyData()
    local playerJob = GetPlayerJobName()
    if (not HasAllowedJob(playerJob)) then return nil end

    local isOnDuty = GetPlayerOnDuty() == true
    local dutyStarted = nil

    if (isOnDuty) then
        dutyStarted = Core.Callback.Await("yecoyz_duty:getActiveDutyTime")
    end

    local workers = Core.Callback.Await("yecoyz_duty:getActiveWorkers") or {}
    local employees = Core.Callback.Await("yecoyz_duty:getAllEmployees") or {}

    local existingEmployees = {}
    for i = 1, #workers do
        workers[i].online = true
        existingEmployees[workers[i].identifier] = true
    end

    for i = 1, #employees do
        local employee = employees[i]

        if (not existingEmployees[employee.identifier]) then
            workers[#workers + 1] = {
                identifier = employee.identifier,
                name = employee.firstname .. " " .. employee.lastname,
                job = employee.job,
                grade = employee.job_grade,
                phone = employee.phone_number or "Unknown",
                online = false
            }
            existingEmployees[employee.identifier] = true
        end
    end

    return {
        character = {
            name = GetPlayerFullName(),
            job = GetPlayerJobLabel(),
            jobName = playerJob,
            grade = GetPlayerJobGradeName(),
            isOnDuty = isOnDuty,
            dutyStarted = dutyStarted,
            isBoss = GetIfBoss()
        },
        historyManagement = {
            edit = Config.HistoryManagement.AllowEdit == true,
            remove = Config.HistoryManagement.AllowRemove == true,
            maxHours = Config.HistoryManagement.MaxShiftHours,
        },
        workers = workers,
        shifts = GetDutyHistory()
    }
end

RegisterCommand("duty", function()
    local dutyData = GetDutyData()
    if (not dutyData) then Core.Notify(locale("noAccess"), "error", nil, locale("ui_DutyTitle")) return end

    SetNuiFocus(true, true)
    dutyData.action = "showUI"
    SendNUIMessage(dutyData)
end, false)


AddEventHandler("onResourceStart", function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then
        return
    end
    local allowedJob = HasAllowedJob(GetPlayerJobName())
    if (not allowedJob) then return end

    if (GetPlayerOnDuty()) then
        Core.Callback.Await("yecoyz_duty:startDuty")
    end
end)
