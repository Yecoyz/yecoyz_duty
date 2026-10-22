QueriesExecuted = false
local queries = [[
    CREATE TABLE IF NOT EXISTS `yecoyz_duty` (
        `index` int(11) unsigned NOT NULL AUTO_INCREMENT,
        `identifier` tinytext NOT NULL,
        `history` longtext NOT NULL,
        `jobs` longtext DEFAULT NULL,
        `multiplier` tinytext DEFAULT NULL,
        `offDuty` tinytext DEFAULT NULL,
        PRIMARY KEY (`index`)
    )
]]

MySQL.query.await(queries)

-- Tables made before multijob support are missing the per job multiplier column.
local hasJobsColumn = MySQL.scalar.await([[
    SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'yecoyz_duty' AND COLUMN_NAME = 'jobs'
]])

if ((tonumber(hasJobsColumn) or 0) == 0) then
    MySQL.query.await("ALTER TABLE `yecoyz_duty` ADD COLUMN `jobs` longtext DEFAULT NULL AFTER `history`")
    print("^2[yecoyz_duty] Added the jobs column for multijob support.^7")
end

print("^2[yecoyz_duty] Database initialized successfully.^7")
QueriesExecuted = true
