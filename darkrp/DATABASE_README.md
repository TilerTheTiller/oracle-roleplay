# DarkRP Database System - MySQLoo Integration

This gamemode now uses MySQLoo for persistent data storage. Important player data (economy, jobs, intro progress) is stored in MySQL, while less critical data (HUD preferences, visual settings) uses file-based storage.

## 📊 Data Storage Strategy

### SQL Database (Important Data)
- **Economy System**: Player money, bank balance, transactions
- **Jobs System**: Current job, job statistics, playtime per job
- **Intro System**: Whether player has seen intro, reward status

### File Storage (Preferences)
- **HUD Preferences**: HUD position, visibility, scale, theme
- **Visual Settings**: Camera effects, shake intensity, vignette, music volume

## 🔧 Installation

### 1. Install MySQLoo9

Download MySQLoo9 from: https://github.com/FredyH/MySQLOO/releases

Extract the appropriate binary to `garrysmod/lua/bin/`:
- Windows 32-bit: `gmsv_mysqloo_win32.dll`
- Windows 64-bit: `gmsv_mysqloo_win64.dll`
- Linux 32-bit: `gmsv_mysqloo_linux.dll`
- Linux 64-bit: `gmsv_mysqloo_linux64.dll`

**Important**: Create the `bin` folder if it doesn't exist!

### 2. Setup MySQL Database

```sql
-- Create database
CREATE DATABASE darkrp CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- Create user (optional, for security)
CREATE USER 'darkrp_user'@'localhost' IDENTIFIED BY 'your_password_here';
GRANT ALL PRIVILEGES ON darkrp.* TO 'darkrp_user'@'localhost';
FLUSH PRIVILEGES;
```

### 3. Configure Connection

Copy `database_config_example.txt` to `garrysmod/data/darkrp/database_config.txt` and edit:

```lua
return {
    host = "localhost",
    username = "darkrp_user",
    password = "your_password_here",
    database = "darkrp",
    port = 3306,
}
```

### 4. Start Server

The database tables will be created automatically on first startup!

## 📋 Database Schema

### darkrp_players
Main player data table
```sql
- steamid (VARCHAR 32, PRIMARY KEY)
- name (VARCHAR 128)
- money (BIGINT) - Wallet balance
- bank_money (BIGINT) - Bank balance
- salary (INT) - Current salary amount
- job_id (INT) - Current job team ID
- total_playtime (INT) - Total seconds played
- last_seen (TIMESTAMP)
- first_joined (TIMESTAMP)
```

### darkrp_transactions
Economy transaction history
```sql
- id (INT AUTO_INCREMENT, PRIMARY KEY)
- steamid (VARCHAR 32, FOREIGN KEY)
- amount (BIGINT) - Transaction amount (+ or -)
- reason (VARCHAR 255)
- transaction_type (VARCHAR 32) - SALARY, TRANSFER, PURCHASE, etc.
- balance_after (BIGINT)
- timestamp (TIMESTAMP)
```

### darkrp_jobs_data
Job statistics and history
```sql
- steamid (VARCHAR 32)
- job_id (INT)
- total_time (INT) - Seconds played in this job
- times_played (INT) - Number of times played
- last_played (TIMESTAMP)
- PRIMARY KEY (steamid, job_id)
```

### darkrp_intro_data
Server intro system data
```sql
- steamid (VARCHAR 32, PRIMARY KEY, FOREIGN KEY)
- seen_intro (BOOLEAN)
- received_reward (BOOLEAN)
- last_seen (TIMESTAMP)
```

## 🎮 Console Commands

### Database Management
```
darkrp_db_stats         - Show database statistics
darkrp_db_reconnect     - Reconnect to database
darkrp_db_test          - Test database connection
```

### HUD Preferences (Client)
```
darkrp_hud_reset        - Reset HUD preferences to defaults
darkrp_hud_reload       - Reload HUD preferences from file
darkrp_hud_save         - Manually save HUD preferences
darkrp_hud_set <key> <value> - Set a preference value
darkrp_hud_get <key>    - Get a preference value
darkrp_hud_list         - List all HUD preferences
```

### Visual Preferences (Client)
```
darkrp_visual_reset     - Reset visual preferences to defaults
darkrp_visual_reload    - Reload visual preferences from file
darkrp_visual_save      - Manually save visual preferences
darkrp_visual_set <key> <value> - Set a preference value
darkrp_visual_get <key> - Get a preference value
darkrp_visual_list      - List all visual preferences
```

## 🔌 API Usage

### Database Queries (Server)
```lua
-- Execute a query
DarkRP.database.Query([[
    SELECT * FROM darkrp_players WHERE steamid = ?
]], {ply:SteamID()}, function(data, success, err)
    if success and data then
        -- Process results
        print(data[1].money)
    else
        ErrorNoHalt("Query failed: " .. tostring(err))
    end
end)

-- Check connection status
if DarkRP.database.IsConnected() then
    -- Safe to query
end

-- Get statistics
local stats = DarkRP.database.GetStats()
PrintTable(stats)
```

### Economy System (Server)
```lua
-- Money management
ply:SetMoney(1000)
ply:AddMoney(500, "Bonus")
ply:TakeMoney(200, "Purchase")

-- Bank management
ply:SetBankMoney(5000)
ply:AddBankMoney(1000)
ply:TakeBankMoney(500)

-- Check balance
if ply:CanAfford(100) then
    -- Player has enough money
end

-- Transfer money
DarkRP.Economy.TransferMoney(sender, receiver, amount, reason)

-- Get transactions
local transactions = DarkRP.Economy.GetPlayerTransactions(ply, 10)
```

### Jobs System (Server)
```lua
-- Change player job
DarkRP.changeJob(ply, TEAM_POLICE)

-- Get job info
local job = DarkRP.getJobByTeam(teamID)
local job, teamID = DarkRP.getJobByCommand("police")

-- Check if player can become job
local canJoin, reason = DarkRP.canBecomeJob(ply, TEAM_POLICE)

-- Get job statistics
DarkRP.jobs.GetPlayerJobStats(ply, TEAM_POLICE)
```

### HUD Preferences (Client)
```lua
-- Get preference
local hudScale = DarkRP.HUD.GetPreference("hudScale", 1.0)

-- Set preference
DarkRP.HUD.SetPreference("hudScale", 1.5)

-- Set multiple preferences
DarkRP.HUD.SetMultiplePreferences({
    hudScale = 1.5,
    showHealth = true,
    showMoney = false
})

-- Reset to defaults
DarkRP.HUD.ResetPreferences()
```

### Visual Preferences (Client)
```lua
-- Get preference
local shakeEnabled = DarkRP.Visual.GetPreference("enableIntroShake")

-- Set preference
DarkRP.Visual.SetPreference("introShakeIntensity", 0.8)

-- Utility functions
if DarkRP.Visual.IsIntroShakeEnabled() then
    local intensity = DarkRP.Visual.GetIntroShakeIntensity()
end

-- Reset to defaults
DarkRP.Visual.ResetPreferences()
```

## 🎣 Hooks

### Database Hooks
```lua
-- Called when database connects
hook.Add("DarkRP.Database.Connected", "MyHook", function(db)
    print("Database connected!")
end)

-- Called when tables are initialized
hook.Add("DarkRP.Database.TablesInitialized", "MyHook", function()
    print("Tables ready!")
end)
```

### Economy Hooks
```lua
-- Called when player money changes
hook.Add("DarkRP.Economy.MoneyChanged", "MyHook", function(ply, oldAmount, newAmount)
    print(ply:Nick() .. "'s money changed from " .. oldAmount .. " to " .. newAmount)
end)

-- Called when player receives salary
hook.Add("DarkRP.Economy.SalaryPaid", "MyHook", function(ply, amount)
    print(ply:Nick() .. " received salary: " .. amount)
end)

-- Called on money transfer
hook.Add("DarkRP.Economy.MoneyTransferred", "MyHook", function(sender, receiver, amount, fee, reason)
    print("Transfer: " .. amount .. " from " .. sender:Nick() .. " to " .. receiver:Nick())
end)
```

### Jobs Hooks
```lua
-- Called when player changes job
hook.Add("DarkRP_PlayerChangedJob", "MyHook", function(ply, newJob, oldJob)
    print(ply:Nick() .. " changed from job " .. oldJob .. " to " .. newJob)
end)
```

## 🛠️ Troubleshooting

### MySQLoo not found
- Ensure the DLL/SO file is in `garrysmod/lua/bin/`
- Check you're using the correct binary for your OS/architecture
- Restart the server completely

### Connection failed
- Verify MySQL is running
- Check firewall settings
- Confirm database exists
- Verify username/password
- Try: `mysql -u username -p database` from command line

### Tables not created
- Check console for SQL errors
- Ensure MySQL user has CREATE TABLE permission
- Run `darkrp_db_reconnect` console command
- Check `darkrp_db_stats` to see connection status

### Data not saving
- Check `darkrp_db_stats` - should show queries increasing
- Look for errors in server console
- Verify player data hooks are not being blocked
- Check MySQL error logs

### Permission denied
```sql
-- Grant permissions
GRANT ALL PRIVILEGES ON darkrp.* TO 'your_user'@'localhost';
FLUSH PRIVILEGES;
```

## 📁 File Locations

### Database Config
`garrysmod/data/darkrp/database_config.txt`

### HUD Preferences (per player)
`garrysmod/data/darkrp/hud_preferences_<steamid64>.txt`

### Visual Preferences (per player)
`garrysmod/data/darkrp/visual_preferences_<steamid64>.txt`

### Intro Config (admin-saved)
`garrysmod/data/darkrp_intro/config.txt`

## 🔒 Security Best Practices

1. **Never commit credentials**: Add `database_config.txt` to `.gitignore`
2. **Use dedicated user**: Create a MySQL user specifically for DarkRP
3. **Limit permissions**: Only grant necessary privileges
4. **Strong passwords**: Use complex passwords for MySQL users
5. **Local only**: Use `localhost` instead of `0.0.0.0` when possible
6. **Regular backups**: Backup your database regularly
7. **Update MySQLoo**: Keep MySQLoo9 updated to latest version

## 📊 Performance Tips

1. **Connection pooling**: Adjust `maxPoolSize` based on player count
2. **Query optimization**: Use indexes for frequently queried columns
3. **Batch operations**: Save data in batches rather than per-action
4. **Cache results**: Enable query caching for read-heavy operations
5. **Monitor stats**: Use `darkrp_db_stats` to track performance

## 🆘 Support

For issues:
1. Check server console for errors
2. Run `darkrp_db_stats` to verify connection
3. Check MySQL error logs
4. Verify MySQLoo9 is installed correctly
5. Test connection with `darkrp_db_test`

## 📝 License

This database system is part of the DarkRP gamemode and follows the same license.
