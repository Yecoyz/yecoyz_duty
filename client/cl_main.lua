lib.locale()

RegisterCommand("duty", function()
    local playerJob = GetPlayerJobName()
    local allowedJob = HasAllowedJob(playerJob)
    if (not allowedJob) then ShowNotification(locale("noAccess"), "error") return end

    SetNuiFocus(true, true)
    local playerName = GetPlayerFullName()
    local playerJobLabel = GetPlayerJobLabel()
    local playerRank = GetPlayerJobGradeName()
    local isOnDuty = GetPlayerOnDuty() == true
    local dutyStarted = nil

    if (isOnDuty) then
        dutyStarted = Core.Callback.Await("yecoyz_duty:getActiveDutyTime")
    end

    local workers = Core.Callback.Await("yecoyz_duty:getActiveWorkers") or {}
    local dutyHistory = GetDutyHistory()
    local isBoss = GetIfBoss()
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

    SendNUIMessage({
        action = "showUI",
        character = {
            name = playerName,
            job = playerJobLabel,
            jobName = playerJob,
            grade = playerRank,
            isOnDuty = isOnDuty,
            dutyStarted = dutyStarted,
            isBoss = isBoss
        },
        historyManagement = {
            edit = Config.HistoryManagement.AllowEdit == true,
            remove = Config.HistoryManagement.AllowRemove == true,
            maxHours = Config.HistoryManagement.MaxShiftHours,
        },
        workers = workers,
        shifts = dutyHistory
    })
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
