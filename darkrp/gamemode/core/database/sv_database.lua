-- ═══════════════════════════════════════════════════════════════════════════
--  DarkRP Database System - MySQLoo Integration
--  Centralized database connection and query management
-- ═══════════════════════════════════════════════════════════════════════════

if CLIENT then return end

DarkRP = DarkRP or {}
DarkRP.database = DarkRP.database or {}

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  Configuration                                                ║
-- ╚═══════════════════════════════════════════════════════════════╝

DarkRP.database.config = {
	-- Database connection settings
	host = "91.229.114.43",
	username = "u10402_JPIIUJ3b8n",
	password = "u.=+HyRwFm2bU!XIJB0LQBhL",
	database = "s10402_darkrp",
	port = 3306,
	
	-- Connection pool settings
	maxPoolSize = 5,
	connectionTimeout = 10,
	
	-- Query settings
	queryTimeout = 30,
	retryAttempts = 3,
	retryDelay = 1,
	
	-- Logging
	logQueries = false,
	logErrors = true,
	logConnections = true,
	
	-- Performance
	enableCache = true,
	cacheExpiration = 300, -- 5 minutes
}

-- Load config from file if exists
if file.Exists("darkrp/database_config.txt", "DATA") then
	local configData = file.Read("darkrp/database_config.txt", "DATA")
	if configData then
		local configFunc = CompileString(configData, "DarkRP Database Config", false)
		if configFunc then
			local success, config = pcall(configFunc)
			if success and config then
				table.Merge(DarkRP.database.config, config)
				print("[DarkRP:Database] Loaded custom database configuration")
			end
		end
	end
end

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  Internal State                                               ║
-- ╚═══════════════════════════════════════════════════════════════╝

DarkRP.database._internal = {
	connection = nil,
	connected = false,
	connecting = false,
	queryQueue = {},
	activeQueries = 0,
	totalQueries = 0,
	failedQueries = 0,
	queryCache = {},
	preparedStatements = {},
	connectionAttempts = 0,
	lastError = nil,
}

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  Logging System                                               ║
-- ╚═══════════════════════════════════════════════════════════════╝

function DarkRP.database.Log(message, isError)
	local color = isError and Color(231, 76, 60) or Color(46, 204, 113)
	local prefix = isError and "[ERROR] " or ""
	MsgC(Color(52, 73, 94), "[DarkRP:Database] ", color, prefix, Color(255, 255, 255), message, "\n")
end

function DarkRP.database.LogQuery(query, duration)
	if DarkRP.database.config.logQueries then
		MsgC(Color(52, 152, 219), "[DarkRP:Query] ", Color(255, 255, 255), 
			string.format("%.3fms - %s\n", duration or 0, query:sub(1, 100)))
	end
end

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  Connection Management                                        ║
-- ╚═══════════════════════════════════════════════════════════════╝

function DarkRP.database.Connect(callback)
	if DarkRP.database._internal.connected then
		if callback then callback(true) end
		return
	end
	
	if DarkRP.database._internal.connecting then
		DarkRP.database.Log("Already attempting to connect...", false)
		return
	end
	
	-- Check if MySQLoo is installed
	if not mysqloo then
		DarkRP.database.Log("MySQLoo module not found! Please install MySQLoo9.", true)
		if callback then callback(false, "MySQLoo not installed") end
		return
	end
	
	DarkRP.database._internal.connecting = true
	DarkRP.database._internal.connectionAttempts = DarkRP.database._internal.connectionAttempts + 1
	
	local cfg = DarkRP.database.config
	
	if cfg.logConnections then
		DarkRP.database.Log(string.format("Connecting to %s@%s:%s/%s (Attempt #%d)", 
			cfg.username, cfg.host, cfg.port, cfg.database, 
			DarkRP.database._internal.connectionAttempts))
	end
	
	-- Create connection
	local db = mysqloo.connect(cfg.host, cfg.username, cfg.password, cfg.database, cfg.port)
	
	function db:onConnected()
		DarkRP.database._internal.connected = true
		DarkRP.database._internal.connecting = false
		DarkRP.database._internal.connection = db
		DarkRP.database._internal.connectionAttempts = 0
		
		DarkRP.database.Log("Successfully connected to database!")
		
		-- Set UTF-8 encoding
		local query = db:query("SET NAMES utf8mb4")
		function query:onSuccess()
			DarkRP.database.Log("Character set configured (utf8mb4)")
		end
		function query:onError(err)
			DarkRP.database.Log("Failed to set character set: " .. err, true)
		end
		query:start()
		
		-- Initialize tables
		DarkRP.database.InitializeTables()
		
		-- Process queued queries
		DarkRP.database.ProcessQueue()
		
		-- Call hooks
		hook.Call("DarkRP.Database.Connected", nil, db)
		
		if callback then callback(true) end
	end
	
	function db:onConnectionFailed(err)
		DarkRP.database._internal.connecting = false
		DarkRP.database._internal.lastError = err
		
		DarkRP.database.Log("Connection failed: " .. err, true)
		
		-- Retry connection after delay
		if DarkRP.database._internal.connectionAttempts < cfg.retryAttempts then
			timer.Simple(cfg.retryDelay, function()
				DarkRP.database.Connect(callback)
			end)
		else
			DarkRP.database.Log("Max connection attempts reached. Giving up.", true)
			if callback then callback(false, err) end
		end
	end
	
	-- Start connection
	db:connect()
end

function DarkRP.database.Disconnect()
	if not DarkRP.database._internal.connected then return end
	
	if DarkRP.database._internal.connection then
		DarkRP.database._internal.connection:disconnect()
		DarkRP.database._internal.connection = nil
	end
	
	DarkRP.database._internal.connected = false
	DarkRP.database.Log("Disconnected from database")
end

function DarkRP.database.IsConnected()
	return DarkRP.database._internal.connected
end

function DarkRP.database.GetConnection()
	return DarkRP.database._internal.connection
end

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  Query System                                                 ║
-- ╚═══════════════════════════════════════════════════════════════╝

function DarkRP.database.Query(queryStr, params, callback)
	if not queryStr or queryStr == "" then
		DarkRP.database.Log("Empty query string provided", true)
		if callback then callback(nil, false, "Empty query") end
		return
	end
	
	-- Queue query if not connected
	if not DarkRP.database._internal.connected then
		table.insert(DarkRP.database._internal.queryQueue, {
			query = queryStr,
			params = params,
			callback = callback
		})
		
		if not DarkRP.database._internal.connecting then
			DarkRP.database.Connect()
		end
		return
	end
	
	local db = DarkRP.database._internal.connection
	if not db then
		DarkRP.database.Log("No database connection", true)
		if callback then callback(nil, false, "No connection") end
		return
	end
	
	-- Escape parameters
	local finalQuery = queryStr
	if params and #params > 0 then
		for i, param in ipairs(params) do
			local escaped = db:escape(tostring(param))
			finalQuery = string.gsub(finalQuery, "?", "'" .. escaped .. "'", 1)
		end
	end
	
	DarkRP.database._internal.totalQueries = DarkRP.database._internal.totalQueries + 1
	DarkRP.database._internal.activeQueries = DarkRP.database._internal.activeQueries + 1
	
	local startTime = SysTime()
	local query = db:query(finalQuery)
	
	function query:onSuccess(data)
		local duration = (SysTime() - startTime) * 1000
		DarkRP.database._internal.activeQueries = DarkRP.database._internal.activeQueries - 1
		DarkRP.database.LogQuery(finalQuery, duration)
		
		if callback then
			local success, err = pcall(callback, data, true, nil)
			if not success then
				DarkRP.database.Log("Callback error: " .. tostring(err), true)
			end
		end
	end
	
	function query:onError(err, sql)
		local duration = (SysTime() - startTime) * 1000
		DarkRP.database._internal.activeQueries = DarkRP.database._internal.activeQueries - 1
		DarkRP.database._internal.failedQueries = DarkRP.database._internal.failedQueries + 1
		DarkRP.database._internal.lastError = err
		
		if DarkRP.database.config.logErrors then
			DarkRP.database.Log("Query failed: " .. err, true)
			DarkRP.database.Log("SQL: " .. (sql or finalQuery), true)
		end
		
		if callback then
			local success, callbackErr = pcall(callback, nil, false, err)
			if not success then
				DarkRP.database.Log("Callback error: " .. tostring(callbackErr), true)
			end
		end
	end
	
	query:start()
end

function DarkRP.database.ProcessQueue()
	if not DarkRP.database._internal.connected then return end
	
	local queue = DarkRP.database._internal.queryQueue
	if #queue == 0 then return end
	
	DarkRP.database.Log("Processing " .. #queue .. " queued queries...")
	
	for _, queryData in ipairs(queue) do
		DarkRP.database.Query(queryData.query, queryData.params, queryData.callback)
	end
	
	DarkRP.database._internal.queryQueue = {}
end

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  Table Initialization                                         ║
-- ╚═══════════════════════════════════════════════════════════════╝

function DarkRP.database.InitializeTables()
	DarkRP.database.Log("Initializing database tables...")
	
	-- Players table
	DarkRP.database.Query([[
		CREATE TABLE IF NOT EXISTS darkrp_players (
			steamid VARCHAR(32) PRIMARY KEY,
			name VARCHAR(128) NOT NULL,
			money BIGINT DEFAULT 0,
			bank_money BIGINT DEFAULT 0,
			salary INT DEFAULT 0,
			job_id INT DEFAULT 1,
			total_playtime INT DEFAULT 0,
			last_seen TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
			first_joined TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
			INDEX idx_steamid (steamid),
			INDEX idx_last_seen (last_seen)
		) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
	]], {}, function(data, success, err)
		if success then
			DarkRP.database.Log("Table 'darkrp_players' ready")
		else
			DarkRP.database.Log("Failed to create 'darkrp_players': " .. tostring(err), true)
		end
	end)
	
	-- Economy transactions table
	DarkRP.database.Query([[
		CREATE TABLE IF NOT EXISTS darkrp_transactions (
			id INT AUTO_INCREMENT PRIMARY KEY,
			steamid VARCHAR(32) NOT NULL,
			amount BIGINT NOT NULL,
			reason VARCHAR(255),
			transaction_type VARCHAR(32),
			balance_after BIGINT,
			timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
			INDEX idx_steamid (steamid),
			INDEX idx_timestamp (timestamp),
			INDEX idx_type (transaction_type),
			FOREIGN KEY (steamid) REFERENCES darkrp_players(steamid) ON DELETE CASCADE
		) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
	]], {}, function(data, success, err)
		if success then
			DarkRP.database.Log("Table 'darkrp_transactions' ready")
		else
			DarkRP.database.Log("Failed to create 'darkrp_transactions': " .. tostring(err), true)
		end
	end)
	
	-- Jobs table
	DarkRP.database.Query([[
		CREATE TABLE IF NOT EXISTS darkrp_jobs_data (
			steamid VARCHAR(32) NOT NULL,
			job_id INT NOT NULL,
			total_time INT DEFAULT 0,
			times_played INT DEFAULT 1,
			last_played TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
			PRIMARY KEY (steamid, job_id),
			INDEX idx_steamid (steamid),
			INDEX idx_job_id (job_id),
			FOREIGN KEY (steamid) REFERENCES darkrp_players(steamid) ON DELETE CASCADE
		) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
	]], {}, function(data, success, err)
		if success then
			DarkRP.database.Log("Table 'darkrp_jobs_data' ready")
		else
			DarkRP.database.Log("Failed to create 'darkrp_jobs_data': " .. tostring(err), true)
		end
	end)
	
	-- Intro system table
	DarkRP.database.Query([[
		CREATE TABLE IF NOT EXISTS darkrp_intro_data (
			steamid VARCHAR(32) PRIMARY KEY,
			seen_intro BOOLEAN DEFAULT 0,
			received_reward BOOLEAN DEFAULT 0,
			last_seen TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
			INDEX idx_steamid (steamid),
			FOREIGN KEY (steamid) REFERENCES darkrp_players(steamid) ON DELETE CASCADE
		) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
	]], {}, function(data, success, err)
		if success then
			DarkRP.database.Log("Table 'darkrp_intro_data' ready")
		else
			DarkRP.database.Log("Failed to create 'darkrp_intro_data': " .. tostring(err), true)
		end
	end)
	
	-- Character system tables
	DarkRP.database.Query([[
		CREATE TABLE IF NOT EXISTS darkrp_characters (
			id INT AUTO_INCREMENT PRIMARY KEY,
			steamid VARCHAR(32) NOT NULL,
			character_name VARCHAR(64) NOT NULL,
			model VARCHAR(128) DEFAULT 'models/player/group01/male_01.mdl',
			money BIGINT DEFAULT 0,
			bank_money BIGINT DEFAULT 0,
			job_id INT DEFAULT 1,
			pos_x FLOAT DEFAULT 0,
			pos_y FLOAT DEFAULT 0,
			pos_z FLOAT DEFAULT 0,
			angle_p FLOAT DEFAULT 0,
			angle_y FLOAT DEFAULT 0,
			angle_r FLOAT DEFAULT 0,
			health INT DEFAULT 100,
			armor INT DEFAULT 0,
			hunger INT DEFAULT 100,
			thirst INT DEFAULT 100,
			playtime INT DEFAULT 0,
			last_played TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
			created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
			is_active BOOLEAN DEFAULT 0,
			INDEX idx_steamid (steamid),
			INDEX idx_active (steamid, is_active),
			UNIQUE KEY unique_name_per_player (steamid, character_name),
			FOREIGN KEY (steamid) REFERENCES darkrp_players(steamid) ON DELETE CASCADE
		) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
	]], {}, function(data, success, err)
		if success then
			DarkRP.database.Log("Table 'darkrp_characters' ready")
		else
			DarkRP.database.Log("Failed to create 'darkrp_characters': " .. tostring(err), true)
		end
	end)
	
	-- Character inventory table (for future expansion)
	DarkRP.database.Query([[
		CREATE TABLE IF NOT EXISTS darkrp_character_inventory (
			id INT AUTO_INCREMENT PRIMARY KEY,
			character_id INT NOT NULL,
			item_class VARCHAR(64) NOT NULL,
			item_data TEXT,
			quantity INT DEFAULT 1,
			slot INT DEFAULT 0,
			INDEX idx_character (character_id),
			FOREIGN KEY (character_id) REFERENCES darkrp_characters(id) ON DELETE CASCADE
		) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
	]], {}, function(data, success, err)
		if success then
			DarkRP.database.Log("Table 'darkrp_character_inventory' ready")
		else
			DarkRP.database.Log("Failed to create 'darkrp_character_inventory': " .. tostring(err), true)
		end
	end)
	
	hook.Call("DarkRP.Database.TablesInitialized", nil)
end

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  Statistics & Utilities                                       ║
-- ╚═══════════════════════════════════════════════════════════════╝

function DarkRP.database.GetStats()
	return {
		connected = DarkRP.database._internal.connected,
		totalQueries = DarkRP.database._internal.totalQueries,
		activeQueries = DarkRP.database._internal.activeQueries,
		failedQueries = DarkRP.database._internal.failedQueries,
		queueSize = #DarkRP.database._internal.queryQueue,
		lastError = DarkRP.database._internal.lastError,
		connectionAttempts = DarkRP.database._internal.connectionAttempts,
	}
end

function DarkRP.database.PrintStats()
	local stats = DarkRP.database.GetStats()
	
	print("\n╔════════════════════════════════════════════════════════════╗")
	print("║         DarkRP Database Statistics                        ║")
	print("╠════════════════════════════════════════════════════════════╣")
	print("  Connected:       " .. (stats.connected and "YES" or "NO"))
	print("  Total Queries:   " .. stats.totalQueries)
	print("  Active Queries:  " .. stats.activeQueries)
	print("  Failed Queries:  " .. stats.failedQueries)
	print("  Queue Size:      " .. stats.queueSize)
	if stats.lastError then
		print("  Last Error:      " .. stats.lastError)
	end
	print("╚════════════════════════════════════════════════════════════╝\n")
end

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  Console Commands                                             ║
-- ╚═══════════════════════════════════════════════════════════════╝

concommand.Add("darkrp_db_stats", function(ply, cmd, args)
	if IsValid(ply) and not ply:IsSuperAdmin() then return end
	DarkRP.database.PrintStats()
end)

concommand.Add("darkrp_db_reconnect", function(ply, cmd, args)
	if IsValid(ply) and not ply:IsSuperAdmin() then return end
	DarkRP.database.Disconnect()
	timer.Simple(1, function()
		DarkRP.database.Connect()
	end)
end)

concommand.Add("darkrp_db_test", function(ply, cmd, args)
	if IsValid(ply) and not ply:IsSuperAdmin() then return end
	
	DarkRP.database.Query("SELECT 1 + 1 AS result", {}, function(data, success, err)
		if success and data then
			print("[DarkRP:Database] Test query successful! Result: " .. (data[1] and data[1].result or "N/A"))
		else
			print("[DarkRP:Database] Test query failed: " .. tostring(err))
		end
	end)
end)

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  Shutdown Handler                                             ║
-- ╚═══════════════════════════════════════════════════════════════╝

hook.Add("ShutDown", "DarkRP.Database.Shutdown", function()
	DarkRP.database.Log("Server shutting down, closing database connection...")
	DarkRP.database.Disconnect()
end)

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  Initialization                                               ║
-- ╚═══════════════════════════════════════════════════════════════╝

-- Auto-connect on load
timer.Simple(0.1, function()
	DarkRP.database.Connect()
end)

DarkRP.database.Log("Database module loaded")
