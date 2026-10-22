CreateThread(function ()
    if (GetResourceState("es_extended") == "started") then
        Framework = "ESX"
        ESX = exports["es_extended"]:getSharedObject()
        print("[INFO] - ESX Framework")
    elseif (GetResourceState("qb-core") == "started") or (GetResourceState("qbx_core") == "started") then
        Framework = "QBCore"
        QBCore = exports['qb-core']:GetCoreObject()
        print("[INFO] - QBCore Framework")
    end
end)

AddEventHandler("playerDropped", function()
    local src = source
    if (IsOnShift(src)) then
        StopDuty(src)
    end
    Cache.DutyData[src] = nil
end)

-- qbx_core always keeps duty on the framework, so treat it as framework based.
function UsesFrameworkDuty()
    return Config.FrameworkBased or (GetResourceState("qbx_core") == "started")
end

function GetPlayerFromId(source)
    if (Framework == "ESX") then
        return ESX.GetPlayerFromId(source)
    elseif (Framework == "QBCore") and (GetResourceState("qbx_core") == "started") then
        return exports.qbx_core:GetPlayer(source)
    elseif (Framework == "QBCore") then
        return QBCore.Functions.GetPlayer(source)
    end
    return nil
end

function GetIdentifier(source)
    local player = GetPlayerFromId(source)
    if (not player) then return end

    if (Framework == "ESX") then
        return player.getIdentifier()
    elseif (Framework == "QBCore") then
        return player.PlayerData.citizenid
    end

    return nil
end

function GetPlayerJob(source)
    local player = GetPlayerFromId(source)
    if (not player) then return nil end

    if (Framework == "ESX") then
        return player.getJob().name
    elseif (Framework == "QBCore") then
        return player.PlayerData.job.name
    end

    return nil
end

function GetPlayerJobLabel(source)
    local player = GetPlayerFromId(source)
    if (not player) then return nil end

    if (Framework == "ESX") then
        return player.getJob().label
    elseif (Framework == "QBCore") then
        return player.PlayerData.job.label
    end

    return nil
end

function GetPlayerOnDuty(source)
    if (not UsesFrameworkDuty()) then
        local dutyData = Cache.DutyData[source]
        return dutyData ~= nil and dutyData.onDuty == true
    end

    local player = GetPlayerFromId(source)
    if (not player) then return nil end

    if (Framework == "ESX") then
        return player.getJob().onDuty
    elseif (Framework == "QBCore") then
        return player.PlayerData.job.onduty
    end
    return nil
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
    if (Framework == "ESX") then
        if (not HasPhoneColumn()) then return "Unknown" end

        local settings = Config.PhoneNumber
        local phone = MySQL.scalar.await(("SELECT `%s` FROM `%s` WHERE `%s` = ? LIMIT 1"):format(
            settings.column, settings.table, settings.identifierColumn
        ), { identifier })

        return phone or "Unknown"
    elseif (Framework == "QBCore") then
        local result = MySQL.single.await("SELECT `charinfo` FROM `players` WHERE `citizenid` = ? LIMIT 1", {
            identifier
        })

        if (not result) then return "Unknown" end
        local charinfo = json.decode(result.charinfo) or {}
        return charinfo.phone or "Unknown"
    end
    return "Unknown"
end

function GetAllEmployees(jobName)
    if (Framework == "ESX") then
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
    elseif (Framework == "QBCore") then
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

function GetBossPermission(source)
    local player = GetPlayerFromId(source)
    if (not player) then return false end

    if (Framework == "ESX") then
        for i = 1, #Config.BossGrades do
            if (player.getJob().grade_name == Config.BossGrades[i]) then
                return true
            end
        end
        return false
    elseif (Framework == "QBCore") then
        return player.PlayerData.job.isboss or false
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

    if (Framework == "ESX") then
        local playersWithSameJob = ESX.GetExtendedPlayers("job", jobName)

        for i = 1, #playersWithSameJob do
            local xPlayer = playersWithSameJob[i]
            if (GetPlayerOnDuty(xPlayer.source)) then
                local startTime = ShiftStartFor(xPlayer.source, jobName)
                activeWorkers[#activeWorkers + 1] = {
                    source = xPlayer.source,
                    identifier = xPlayer.identifier,
                    name = GetFullName(xPlayer.source),
                    job = xPlayer.job.label,
                    grade = xPlayer.job.grade_label,
                    phone = GetPhoneNumber(xPlayer.identifier),
                    dutyStarted = startTime,
                    dutyTime = FormatDutyTime(startTime),
                    online = true
                }
            end
        end
    elseif (Framework == "QBCore") then
        local activePlayers = QBCore.Functions.GetPlayers()
        for i = 1, #activePlayers do
            local player = GetPlayerFromId(activePlayers[i])

            if (player) and (player.PlayerData.job.name == jobName) and (GetPlayerOnDuty(player.PlayerData.source)) then
                local startTime = ShiftStartFor(player.PlayerData.source, jobName)
                activeWorkers[#activeWorkers + 1] = {
                    source = player.PlayerData.source,
                    identifier = player.PlayerData.citizenid,
                    name = GetFullName(player.PlayerData.source),
                    job = player.PlayerData.job.label,
                    grade = player.PlayerData.job.grade.name,
                    phone = player.PlayerData.charinfo.phone or "Unknown",
                    dutyStarted = startTime,
                    dutyTime = FormatDutyTime(startTime),
                    online = true
                }
            end
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
        local player = GetPlayerFromId(source)
        if (not player) then return false end

        if (Framework == "ESX") then
            local job = player.getJob()
            player.setJob(job.name, job.grade, status)
        elseif (GetResourceState("qbx_core") == "started") then
            exports.qbx_core:SetJobDuty(GetIdentifier(source), status)
        elseif (Framework == "QBCore") then
            player.Functions.SetJobDuty(status)
        end
    end

    if (status) then
        StartDuty(source)
    end

    return GetPlayerOnDuty(source) == true
end

function GetFullName(source)
    if (Framework == "ESX") then
        local playerData = GetPlayerFromId(source)
        local firstName = playerData?.firstName or playerData?.variables?.firstName or "Unknown"
        local lastName = playerData?.lastName or playerData?.variables?.lastName or "Unknown"

        return firstName .. " " .. lastName
    elseif (Framework == "QBCore") then
        local player = GetPlayerFromId(source)
        if (not player) then return "Unknown Unknown" end
        local firstName = player?.PlayerData?.charinfo?.firstname or "Unknown"
        local lastName = player?.PlayerData?.charinfo?.lastname or "Unknown"

        return firstName .. " " .. lastName
    end

    return "Unknown Unknown"
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

AddEventHandler("esx:setJob", function(source, job)
    if (not job) then return end
    OnJobChanged(source, job.name, job.onDuty)
end)

AddEventHandler("QBCore:Server:OnJobUpdate", function(source, job)
    if (not job) then return end
    OnJobChanged(source, job.name, job.onduty)
end)

lib.callback.register("yecoyz_duty:getFullName", function(source)
    return GetFullName(source)
end)

lib.callback.register("yecoyz_duty:setDuty", function(source, status)
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
