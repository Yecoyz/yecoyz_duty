-- Player, job and employee lookups for duty, on top of yecoyz_core.

AddEventHandler("playerDropped", function()
    local src = source
    if (IsOnShift(src)) then
        StopDuty(src)
    end
    Cache.DutyData[src] = nil
end)

-- qbx_core always keeps duty on the framework, so treat it as framework based.
function UsesFrameworkDuty()
    return Config.FrameworkBased or (Core.Framework == "qbox")
end

function GetIdentifier(source)
    return Core.GetIdentifier(source)
end

function GetPlayerJob(source)
    local job = Core.GetJob(source)
    return job and job.name or nil
end

function GetPlayerJobLabel(source)
    local job = Core.GetJob(source)
    return job and job.label or nil
end

function GetPlayerOnDuty(source)
    if (not UsesFrameworkDuty()) then
        local dutyData = Cache.DutyData[source]
        return dutyData ~= nil and dutyData.onDuty == true
    end

    local job = Core.GetJob(source)
    if (not job) then return nil end
    return job.onDuty
end

-- Only plain table/column names are allowed since they are put straight into the query.
local function IsSafeSqlName(name)
    return type(name) == "string" and name:match("^[%w_]+$") ~= nil
end

local phoneColumnExists = nil

-- ESX does not ship a phone column, it is added by the phone script (if at all).
-- Check once that the configured table and column exist so the query can't fail.
local function HasPhoneColumn()
    if (phoneColumnExists ~= nil) then return phoneColumnExists end

    local settings = Config.PhoneNumber
    if (not settings) or (not IsSafeSqlName(settings.table)) or (not IsSafeSqlName(settings.column)) or (not IsSafeSqlName(settings.identifierColumn)) then
        phoneColumnExists = false
        return false
    end

    local count = MySQL.scalar.await([[
        SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = ? AND COLUMN_NAME IN (?, ?)
    ]], { settings.table, settings.column, settings.identifierColumn })

    phoneColumnExists = (tonumber(count) or 0) >= 2
    if (not phoneColumnExists) then
        print(("^3[yecoyz_duty] Could not find `%s`.`%s`, phone numbers will show as Unknown. Change Config.PhoneNumber to match your phone script.^7"):format(settings.table, settings.column))
    end

    return phoneColumnExists
end

function GetPhoneNumber(identifier)
    if (Core.Framework == "esx") then
        if (not HasPhoneColumn()) then return "Unknown" end

        local settings = Config.PhoneNumber
        local phone = MySQL.scalar.await(("SELECT `%s` FROM `%s` WHERE `%s` = ? LIMIT 1"):format(
            settings.column, settings.table, settings.identifierColumn
        ), { identifier })

        return phone or "Unknown"
    elseif (Core.Framework == "qb") or (Core.Framework == "qbox") then
        local result = MySQL.single.await("SELECT `charinfo` FROM `players` WHERE `citizenid` = ? LIMIT 1", {
            identifier
        })

        if (not result) then return "Unknown" end
        local charinfo = json.decode(result.charinfo) or {}
        return charinfo.phone or "Unknown"
    end
    return "Unknown"
end

-- Every employee of a job, online or not, read from the framework's tables.
function GetAllEmployees(jobName)
    if (Core.Framework == "esx") then
        local employees = MySQL.query.await([[
            SELECT u.identifier, u.firstname, u.lastname, g.label AS grade_label
            FROM users u
            LEFT JOIN job_grades g ON g.job_name = u.job AND g.grade = u.job_grade
            WHERE u.job = ?
        ]], {jobName}) or {}
        local jobLabel = MySQL.scalar.await("SELECT label FROM jobs WHERE name = ?", {jobName})

        for i = 1, #employees do
            employees[i] = {
                identifier = employees[i].identifier,
                firstname = employees[i].firstname,
                lastname = employees[i].lastname,
                phone_number = GetPhoneNumber(employees[i].identifier),
                job = jobLabel or "Unknown",
                job_grade = employees[i].grade_label or "Unknown",
            }
        end

        return employees
    elseif (Core.Framework == "qb") or (Core.Framework == "qbox") then
        local rawEmployees = MySQL.query.await("SELECT citizenid, charinfo, job FROM players WHERE JSON_UNQUOTE(JSON_EXTRACT(job, '$.name')) = ?", {jobName}) or {}
        local employees = {}

        for i = 1, #rawEmployees do
            local charinfo = json.decode(rawEmployees[i].charinfo) or {}
            local jobinfo = json.decode(rawEmployees[i].job) or {}

            employees[i] = {
                identifier = rawEmployees[i].citizenid,
                firstname = charinfo.firstname or "Unknown",
                lastname = charinfo.lastname or "Unknown",
                phone_number = charinfo.phone or "Unknown",
                job = jobinfo.label or "Unknown",
                job_grade = jobinfo.grade and jobinfo.grade.name or "Unknown"
            }
        end

        return employees
    end
    return {}
end

-- QBCore / Qbox: the job's boss flag. ESX: the boss grades in Config.BossGrades (and yecoyz_core's).
function GetBossPermission(source)
    local job = Core.GetJob(source)
    if (not job) then return false end
    if (job.isBoss) then return true end

    if (Core.Framework == "esx") then
        for i = 1, #Config.BossGrades do
            if (job.gradeName == Config.BossGrades[i]) then
                return true
            end
        end
    end

    return false
end

local function ShiftStartFor(source, jobName)
    local dutyData = Cache.DutyData[source]
    if (dutyData) and (dutyData.startTime) and (dutyData.job == jobName) then
        return dutyData.startTime
    end
    return nil
end

function GetActiveWorkers(jobName)
    local activeWorkers = {}
    if (not jobName) then return activeWorkers end

    for _, src in ipairs(Core.GetPlayersByJob(jobName)) do
        if (GetPlayerOnDuty(src)) then
            local job = Core.GetJob(src) or {}
            local identifier = Core.GetIdentifier(src)
            local character = Core.GetCharacter(src) or {}
            local startTime = ShiftStartFor(src, jobName)

            activeWorkers[#activeWorkers + 1] = {
                source = src,
                identifier = identifier,
                name = GetFullName(src),
                job = job.label,
                grade = job.gradeLabel,
                phone = character.phone or GetPhoneNumber(identifier),
                dutyStarted = startTime,
                dutyTime = FormatDutyTime(startTime),
                online = true
            }
        end
    end

    return activeWorkers
end

function SetDuty(source, status)
    -- Close the running shift first so it is saved to the job it was worked in.
    if (not status) then
        StopDuty(source)
    end

    if (UsesFrameworkDuty()) then
        if (not Core.SetDuty(source, status)) then return false end
    end

    if (status) then
        StartDuty(source)
    end

    return GetPlayerOnDuty(source) == true
end

function GetFullName(source)
    return Core.GetFullName(source) or "Unknown Unknown"
end

-- Multijob: when the job changes mid shift the shift is closed and saved to the old job,
-- so hours can never be moved over to another job.
local function OnJobChanged(source, jobName, onDuty)
    source = tonumber(source)
    if (not source) or (not jobName) then return end

    local dutyData = Cache.DutyData[source]
    local onShift = (dutyData ~= nil) and (dutyData.startTime ~= nil)

    if (onShift) and (dutyData.job ~= jobName) then
        StopDuty(source)
        TriggerClientEvent("yecoyz_duty:notify", source, "dutyEndedJobChange", "inform")

        if (UsesFrameworkDuty()) and (onDuty) and (HasAllowedJob(jobName)) then
            StartDuty(source)
        end
        return
    end

    -- Keep in sync when duty is toggled by the framework or another script.
    if (UsesFrameworkDuty()) and (HasAllowedJob(jobName)) then
        if (onDuty) and (not onShift) then
            StartDuty(source)
        elseif (not onDuty) and (onShift) then
            StopDuty(source)
        end
    end
end

Core.OnJobUpdated(function(source, job)
    OnJobChanged(source, job.name, job.onDuty)
end)

Core.Callback.Register("yecoyz_duty:getFullName", function(source)
    return GetFullName(source)
end)

Core.Callback.Register("yecoyz_duty:setDuty", function(source, status)
    local onDuty = SetDuty(source, status == true)
    local dutyData = Cache.DutyData[source]

    return {
        onDuty = onDuty,
        dutyStarted = dutyData and dutyData.startTime or nil,
    }
end)

exports("SetDuty", function(source, status)
    return SetDuty(source, status)
end)
