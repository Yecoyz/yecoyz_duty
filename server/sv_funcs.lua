local function DecodeJson(value)
    if (type(value) ~= "string") or (value == "") then return {} end
    local ok, result = pcall(json.decode, value)
    if (not ok) or (type(result) ~= "table") then return {} end
    return result
end

local function GetDutyRow(identifier)
    return MySQL.single.await("SELECT `history`, `jobs` FROM `yecoyz_duty` WHERE `identifier` = ? LIMIT 1", {
        identifier
    })
end

function HasAllowedJob(jobName)
    for i = 1, #Config.Jobs do
        if (jobName == Config.Jobs[i]) then
            return true
        end
    end
    return false
end

function IsOnShift(source)
    local dutyData = Cache.DutyData[source]
    return (dutyData ~= nil) and (dutyData.startTime ~= nil)
end

function FormatDutyTime(startTime)
    if (not startTime) then return "N/A" end
    local elapsedSeconds = os.time() - startTime
    return string.format("%d h, %d m", math.floor(elapsedSeconds / 3600), math.floor((elapsedSeconds % 3600) / 60))
end

-- The stored multiplier for one job, minus the hourly loss since that job's last shift.
function GetMultiplier(identifier, jobName)
    if (not Config.MultiplierSettings.Multiplier[jobName]) then return 1.0 end

    local row = GetDutyRow(identifier)
    local jobData = row and DecodeJson(row.jobs)[jobName]
    if (not jobData) then return 1.0 end

    local multiplier = tonumber(jobData.multiplier) or 1.0
    local offDuty = tonumber(jobData.offDuty)

    if (offDuty) then
        local hoursPassed = (os.time() - offDuty) / 3600
        if (hoursPassed >= 1) then
            multiplier = multiplier - (Config.MultiplierSettings.Hourlyloss * hoursPassed)
        end
    end

    return math.max(1.0, multiplier)
end

local function GetShiftMultiplier(dutyData, now)
    local settings = Config.MultiplierSettings.Multiplier[dutyData.job]
    if (not settings) then return 1.0 end

    local hoursOnDuty = (now - dutyData.startTime) / 3600
    local multiplier = (dutyData.multiplier or 1.0) + (hoursOnDuty * settings.increasePerHour)

    return math.min(multiplier, settings.maxMultiplier)
end

function CalculateSalaryMultiplier(source)
    if (not Config.MultiplierSettings.SalaryMultiplier) then return 1.0 end
    if (not IsOnShift(source)) then return 1.0 end

    local dutyData = Cache.DutyData[source]
    -- The bonus only counts for the job the shift was started in.
    if (GetPlayerJob(source) ~= dutyData.job) then return 1.0 end

    return GetShiftMultiplier(dutyData, os.time())
end

function StartDuty(source)
    local jobName = GetPlayerJob(source)
    if (not jobName) or (not HasAllowedJob(jobName)) then return false end

    if (IsOnShift(source)) then
        if (Cache.DutyData[source].job == jobName) then return true end
        StopDuty(source)
    end

    local identifier = GetIdentifier(source)
    if (not identifier) then return false end

    Cache.DutyData[source] = {
        onDuty = true,
        startTime = os.time(),
        identifier = identifier,
        job = jobName,
        jobLabel = GetPlayerJobLabel(source) or jobName,
        multiplier = GetMultiplier(identifier, jobName),
    }
    return true
end

local function SaveShift(dutyData, endTime)
    local shift = {
        job = dutyData.job,
        jobLabel = dutyData.jobLabel,
        startTime = dutyData.startTime,
        endTime = endTime,
        startTimeFormatted = os.date("%Y-%m-%d %H:%M:%S", dutyData.startTime),
        endTimeFormatted = os.date("%Y-%m-%d %H:%M:%S", endTime),
        duration = endTime - dutyData.startTime,
    }

    local row = GetDutyRow(dutyData.identifier)
    local history = row and DecodeJson(row.history) or {}
    local jobs = row and DecodeJson(row.jobs) or {}

    history[#history + 1] = shift
    jobs[dutyData.job] = {
        multiplier = GetShiftMultiplier(dutyData, endTime),
        offDuty = endTime,
    }

    if (not row) then
        local inserted = MySQL.insert.await("INSERT INTO `yecoyz_duty` (`identifier`, `history`, `jobs`) VALUES (?, ?, ?)", {
            dutyData.identifier, json.encode(history), json.encode(jobs)
        })
        return inserted ~= nil
    end

    local updated = MySQL.update.await("UPDATE `yecoyz_duty` SET `history` = ?, `jobs` = ? WHERE `identifier` = ?", {
        json.encode(history), json.encode(jobs), dutyData.identifier
    })
    return updated ~= nil
end

function StopDuty(source)
    if (not IsOnShift(source)) then return false end

    -- Clear the cache before saving so the same shift can't be saved twice.
    local dutyData = Cache.DutyData[source]
    Cache.DutyData[source] = nil

    return SaveShift(dutyData, os.time())
end

lib.callback.register("yecoyz_duty:getActiveDutyTime", function(source)
    return Cache.DutyData[source] and Cache.DutyData[source].startTime or nil
end)

lib.callback.register("yecoyz_duty:startDuty", function(source)
    return StartDuty(source)
end)

lib.callback.register("yecoyz_duty:stopDuty", function(source)
    return StopDuty(source)
end)

lib.callback.register("yecoyz_duty:isBoss", function(source)
    return GetBossPermission(source)
end)

-- The job is read on the server, so a client can't ask for another job's staff.
lib.callback.register("yecoyz_duty:getActiveWorkers", function(source)
    return GetActiveWorkers(GetPlayerJob(source))
end)

lib.callback.register("yecoyz_duty:getAllEmployees", function(source)
    return GetAllEmployees(GetPlayerJob(source))
end)

-- Kept for scripts that call it, shifts are now saved when duty stops.
lib.callback.register("yecoyz_duty:updateHistory", function()
    return true
end)

lib.callback.register("yecoyz_duty:getHistory", function(source)
    local identifier = GetIdentifier(source)
    if (not identifier) then return {} end

    local row = GetDutyRow(identifier)
    if (not row) then return {} end

    return DecodeJson(row.history)
end)

-- Bosses only see the shifts worked in their own job. Old shifts saved before
-- multijob support have no job and are still shown.
lib.callback.register("yecoyz_duty:getEmployeHistory", function(source, identifier)
    if (type(identifier) ~= "string") or (not GetBossPermission(source)) then return {} end

    local jobName = GetPlayerJob(source)
    local row = GetDutyRow(identifier)
    if (not row) then return {} end

    local shifts = {}
    for _, shift in ipairs(DecodeJson(row.history)) do
        if (shift.job == nil) or (shift.job == jobName) then
            shifts[#shifts + 1] = shift
        end
    end

    return shifts
end)

lib.callback.register("yecoyz_duty:getStandaloneDuty", function(source)
    return GetPlayerOnDuty(source)
end)

exports("GetDutyState", function(source)
    return GetPlayerOnDuty(source)
end)

exports("GetSalaryMultiplier", function(source)
    return CalculateSalaryMultiplier(source)
end)

exports("GetOffDutyPayInfo", function()
    local offDutyInfo = {
        offDutyPay = Config.OffDutySettings.PayOffDuty,
        multiplier  = Config.OffDutySettings.OffDutyMultiplier,
    }
    return offDutyInfo
end)
