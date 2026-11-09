-- Puts the duty menu on yecoyz_tablet as an app. Nothing happens when yecoyz_tablet is not running.
local APP_ID = "yecoyz_duty"
local TABLET = "yecoyz_tablet"

local function GetAppJobs()
    local jobs = {}
    for i = 1, #Config.Jobs do
        jobs[Config.Jobs[i]] = 0
    end
    return jobs
end

local function RegisterTabletApp()
    local settings = Config.Tablet
    if (not settings) or (not settings.Enabled) then return end
    if (GetResourceState(TABLET) ~= "started") then return end

    local called, ok, err = pcall(function()
        return exports[TABLET]:RegisterApp({
            id = APP_ID,
            label = settings.Label or locale("ui_DutyTitle"),
            icon = settings.Icon or "clock",
            ui = "dist/tablet.html",
            description = settings.Description,
            author = "Yecoyz",
            -- Only hides the icon, the server checks the job for everything that matters.
            jobs = GetAppJobs(),
            installedByDefault = settings.InstalledByDefault ~= false,
            removable = settings.Removable ~= false,
        })
    end)

    if (not called) or (not ok) then
        print(("^3[yecoyz_duty] Could not add the tablet app: %s^7"):format(tostring(called and err or ok)))
    end
end

CreateThread(RegisterTabletApp)

-- yecoyz_tablet forgets its apps when it restarts.
AddEventHandler("onClientResourceStart", function(resourceName)
    if (resourceName == TABLET) then RegisterTabletApp() end
end)

-- Duty changed outside the app (/duty, another script): let an open app reload.
function RefreshTabletApp()
    if (not Config.Tablet) or (not Config.Tablet.Enabled) then return end
    if (GetResourceState(TABLET) ~= "started") then return end
    pcall(function()
        exports[TABLET]:SendAppMessage(APP_ID, "refresh", {})
    end)
end

-- A new job or grade changes what the app shows (and whether the player may use it).
Core.OnJobUpdated(function()
    RefreshTabletApp()
end)
