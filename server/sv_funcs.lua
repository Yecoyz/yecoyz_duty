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

Core.Callback.Register("yecoyz_duty:getActiveDutyTime", function(source)
    return Cache.DutyData[source] and Cache.DutyData[source].startTime or nil
end)

Core.Callback.Register("yecoyz_duty:startDuty", function(source)
    return StartDuty(source)
end)

Core.Callback.Register("yecoyz_duty:stopDuty", function(source)
    return StopDuty(source)
end)

Core.Callback.Register("yecoyz_duty:isBoss", function(source)
    return GetBossPermission(source)
end)

-- The job is read on the server, so a client can't ask for another job's staff.
Core.Callback.Register("yecoyz_duty:getActiveWorkers", function(source)
    return GetActiveWorkers(GetPlayerJob(source))
end)

Core.Callback.Register("yecoyz_duty:getAllEmployees", function(source)
    return GetAllEmployees(GetPlayerJob(source))
end)

-- Kept for scripts that call it, shifts are now saved when duty stops.
Core.Callback.Register("yecoyz_duty:updateHistory", function()
    return true
end)

Core.Callback.Register("yecoyz_duty:getHistory", function(source)
    local identifier = GetIdentifier(source)
    if (not identifier) then return {} end

    local row = GetDutyRow(identifier)
    if (not row) then return {} end

    return DecodeJson(row.history)
end)

-- Old shifts only have the formatted date, so read the start time from that.
local function ShiftStartTime(shift)
    if (tonumber(shift.startTime)) then return tonumber(shift.startTime) end
    if (type(shift.startTimeFormatted) ~= "string") then return nil end

    local year, month, day, hour, min, sec = shift.startTimeFormatted:match("^(%d+)-(%d+)-(%d+) (%d+):(%d+):(%d+)$")
    if (not year) then return nil end
    return os.time({
        year = tonumber(year), month = tonumber(month), day = tonumber(day),
        hour = tonumber(hour), min = tonumber(min), sec = tonumber(sec),
    })
end

-- Bosses only see the shifts worked in their own job. Old shifts saved before
-- multijob support have no job and are still shown.
local function GetJobShifts(identifier, jobName, editable)
    local row = GetDutyRow(identifier)
    if (not row) then return {} end

    local shifts = {}
    for index, shift in ipairs(DecodeJson(row.history)) do
        if (shift.job == nil) or (shift.job == jobName) then
            -- Index and start time point at the shift in the saved history, so the boss can edit it.
            shift.index = index
            shift.key = ShiftStartTime(shift)
            shift.editable = editable and (shift.key ~= nil)
            shifts[#shifts + 1] = shift
        end
    end

    return shifts
end

local function CanManageHistory(source, identifier)
    if (not GetBossPermission(source)) then return false end
    if (Config.HistoryManagement.AllowSelfEdit) then return true end
    return GetIdentifier(source) ~= identifier
end

Core.Callback.Register("yecoyz_duty:getEmployeHistory", function(source, identifier)
    if (type(identifier) ~= "string") or (not GetBossPermission(source)) then return {} end

    local settings = Config.HistoryManagement
    local editable = (settings.AllowEdit or settings.AllowRemove) and CanManageHistory(source, identifier)
    return GetJobShifts(identifier, GetPlayerJob(source), editable == true)
end)

local function LogHistoryChange(source, identifier, text)
    if (not Config.HistoryManagement.Log) then return end
    print(("^3[yecoyz_duty] %s (%s) %s for %s.^7"):format(GetFullName(source), GetIdentifier(source) or "?", text, identifier))
end

-- Edits or removes one shift. `key` (the start time) has to match the saved shift, so a shift that
-- moved in the history (new shift saved, another one removed) is never changed by mistake.
local function ChangeShift(source, data, action)
    if (type(data) ~= "table") or (type(data.identifier) ~= "string") then return { success = false } end

    local identifier = data.identifier
    if (not CanManageHistory(source, identifier)) then return { success = false } end

    local jobName = GetPlayerJob(source)
    local row = GetDutyRow(identifier)
    if (not row) then return { success = false } end

    local history = DecodeJson(row.history)
    local index = tonumber(data.index)
    local shift = index and history[index]
    if (not shift) or ((shift.job ~= nil) and (shift.job ~= jobName)) then return { success = false } end

    local startTime = ShiftStartTime(shift)
    if (not startTime) or (tonumber(data.key) ~= startTime) then return { success = false } end

    local oldDuration = tonumber(shift.duration) or 0

    if (action == "remove") then
        table.remove(history, index)
        LogHistoryChange(source, identifier, ("removed a shift (%s, %d minutes)"):format(shift.job or "no job", math.floor(oldDuration / 60)))
    else
        local duration = math.floor(tonumber(data.duration) or 0)
        if (duration < 60) or (duration > Config.HistoryManagement.MaxShiftHours * 3600) then
            return { success = false }
        end

        shift.duration = duration
        shift.startTime = startTime
        shift.endTime = startTime + duration
        shift.endTimeFormatted = os.date("%Y-%m-%d %H:%M:%S", shift.endTime)
        -- Keep the first worked time so the change can always be seen.
        shift.edited = {
            by = GetFullName(source),
            at = os.time(),
            originalDuration = (shift.edited and shift.edited.originalDuration) or oldDuration,
        }
        LogHistoryChange(source, identifier, ("changed a shift (%s) from %d to %d minutes"):format(shift.job or "no job", math.floor(oldDuration / 60), math.floor(duration / 60)))
    end

    local updated = MySQL.update.await("UPDATE `yecoyz_duty` SET `history` = ? WHERE `identifier` = ?", {
        json.encode(history), identifier
    })
    if (not updated) then return { success = false } end

    return { success = true, shifts = GetJobShifts(identifier, jobName, true) }
end

Core.Callback.Register("yecoyz_duty:editShift", function(source, data)
    if (not Config.HistoryManagement.AllowEdit) then return { success = false } end
    return ChangeShift(source, data, "edit")
end)

Core.Callback.Register("yecoyz_duty:removeShift", function(source, data)
    if (not Config.HistoryManagement.AllowRemove) then return { success = false } end
    return ChangeShift(source, data, "remove")
end)

Core.Callback.Register("yecoyz_duty:getStandaloneDuty", function(source)
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
