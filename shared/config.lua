Config = {}

Config.FrameworkBased = false -- If true then get duty value from ESX or QBCore else built in.

Config.Jobs = {
    "police",
    "mechanic",
}

-- Phone numbers come from yecoyz_core (its Config.Phone, sd-phone is used automatically). The settings below are
-- only used when the core has no number.
-- Only if you use ESX. ESX has no phone number by default, it comes from your phone script.
-- Default fits phone scripts that add `phone_number` to `users` (gksphone, qs-smartphone, npwd).
-- lb-phone: table = "phone_phones", column = "phone_number", identifierColumn = "owner_id".
-- If the table or column does not exist the phone number shows as Unknown.
Config.PhoneNumber = {
    table = "users",
    column = "phone_number",
    identifierColumn = "identifier",
}

Config.OffDutySettings = {
    PayOffDuty = false, -- Should you be paid if your not in duty.
    OffDutyMultiplier = 1 -- How much of your salary should you be paid if your off duty.
}

-- Every job keeps its own multiplier. Changing job ends the current shift, so a multiplier
-- built up in one job is never paid out in another.
Config.MultiplierSettings = {
    SalaryMultiplier = true,
    Hourlyloss = 0.1,
    Multiplier = {
        ["police"] = {
            increasePerHour = 0.2, -- How much it will add per hour.
            maxMultiplier = 2.0, -- The limit of how high your multiplier can go.
        },
        ["mechanic"] = {
            increasePerHour = 0.1, -- How much it will add per hour.
            maxMultiplier = 1.8, -- The limit of how high your multiplier can go.
        }
    }
}

-- Lets the boss/chief fix the shift history of their workers in the Manage tab,
-- for example when someone stayed on duty AFK to farm hours.
Config.HistoryManagement = {
    AllowEdit = true, -- Boss can change how long a shift lasted.
    AllowRemove = true, -- Boss can remove a shift completely.
    AllowSelfEdit = false, -- Boss can also change their own shifts.
    MaxShiftHours = 24, -- The longest a shift can be set to when it is edited.
    Log = true, -- Print every change to the server console.
}

-- The duty menu as an app on yecoyz_tablet. Ignored when yecoyz_tablet is not running.
-- Only the jobs in Config.Jobs see the app.
Config.Tablet = {
    Enabled = true,
    Label = "Duty", -- Name under the icon (max 24 characters).
    Icon = "clock", -- A built-in tablet icon name, see yecoyz_tablet/sdk/README.md.
    Description = "Go on duty, see your shifts and manage your workers",
    InstalledByDefault = true, -- false: players install it from the Apps app first.
    Removable = true, -- false: players can not remove it.
}

-- Only if you use ESX.
Config.BossGrades = {
    "boss",
    "chef"
}
