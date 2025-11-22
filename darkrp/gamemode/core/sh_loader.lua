-- ═══════════════════════════════════════════════════════════════════════════
--  DarkRP Advanced File Loader System
--  Based on PANTHEON Loader v3.0 - Adapted for DarkRP gamemode
-- ═══════════════════════════════════════════════════════════════════════════

DarkRP = DarkRP or {}
DarkRP.loader = DarkRP.loader or {}
DarkRP.loader.VERSION = "1.0.0"

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  Configuration                                                ║
-- ╚═══════════════════════════════════════════════════════════════╝

DarkRP.loader.config = {
	verbose = GetConVar("developer"):GetBool() or false,
	benchmarking = true,
	colorOutput = true,
	throwErrors = false,
	maxDepth = 8,
	cacheEnabled = true,
	showLoadOrder = false
}

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  Internal State                                               ║
-- ╚═══════════════════════════════════════════════════════════════╝

DarkRP.loader._internal = {
	cache = {},
	loading = {},
	dependencies = {},
	loadOrder = {},
	benchmarks = {},
	errors = {},
	warnings = {},
	metadata = {},
	hooks = {},
	stats = {
		totalLoads = 0,
		totalErrors = 0,
		totalTime = 0,
		filesLoaded = 0
	}
}

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  Color Palette                                                ║
-- ╚═══════════════════════════════════════════════════════════════╝

DarkRP.loader.colors = {
	primary = Color(52, 73, 94),      -- Dark Blue-Gray
	success = Color(46, 204, 113),    -- Green
	warning = Color(241, 196, 15),    -- Yellow
	error = Color(231, 76, 60),       -- Red
	info = Color(52, 152, 219),       -- Blue
	debug = Color(149, 165, 166),     -- Gray
	white = Color(255, 255, 255),
	dim = Color(189, 195, 199)
}

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  Utility Functions                                            ║
-- ╚═══════════════════════════════════════════════════════════════╝

function DarkRP.loader.normalizePath(path)
	if not path then return '' end
	path = string.gsub(path, '\\', '/')
	path = string.gsub(path, '/+', '/')
	return path
end

function DarkRP.loader.getRealm(filename)
	if not filename then return 'shared' end
	if string.find(filename, '^sv_') or string.find(filename, '_sv%.lua$') then return 'server' end
	if string.find(filename, '^cl_') or string.find(filename, '_cl%.lua$') then return 'client' end
	if string.find(filename, '^sh_') or string.find(filename, '_sh%.lua$') then return 'shared' end
	return 'shared'
end

function DarkRP.loader.shouldLoad(realm)
	if realm == 'shared' then return true end
	if realm == 'server' then return SERVER end
	if realm == 'client' then return CLIENT end
	return true
end

function DarkRP.loader.fileExists(path)
	path = DarkRP.loader.normalizePath(path)
	
	-- For gamemode files, use GAME path
	if file.Exists(path, 'GAME') then
		return true
	end
	
	-- Also check LUA path for addons
	if file.Exists(path, 'LUA') then
		return true
	end
	
	return false
end

function DarkRP.loader.getFileSize(path)
	path = DarkRP.loader.normalizePath(path)
	local size = file.Size(path, 'GAME')
	if not size or size == -1 then
		size = file.Size(path, 'LUA') or 0
	end
	return size
end

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  Logging System                                               ║
-- ╚═══════════════════════════════════════════════════════════════╝

function DarkRP.loader.print(color, prefix, ...)
	if not DarkRP.loader.config.colorOutput then
		print(prefix, ...)
		return
	end
	
	local args = {...}
	local msg = table.concat(args, ' ')
	MsgC(color or DarkRP.loader.colors.primary, prefix, DarkRP.loader.colors.white, msg, '\n')
end

function DarkRP.loader.verbose(...)
	if DarkRP.loader.config.verbose then
		DarkRP.loader.print(DarkRP.loader.colors.debug, '[DARKRP:LOADER:VERBOSE] ', ...)
	end
end

function DarkRP.loader.info(...)
	DarkRP.loader.print(DarkRP.loader.colors.info, '[DARKRP:LOADER] ', ...)
end

function DarkRP.loader.success(...)
	DarkRP.loader.print(DarkRP.loader.colors.success, '[DARKRP:LOADER:OK] ', ...)
end

function DarkRP.loader.warn(msg, context)
	DarkRP.loader.print(DarkRP.loader.colors.warning, '[DARKRP:LOADER:WARN] ', msg)
	table.insert(DarkRP.loader._internal.warnings, {
		msg = msg,
		context = context,
		time = os.time(),
		realm = SERVER and 'server' or 'client'
	})
end

function DarkRP.loader.error(msg, err, context)
	DarkRP.loader.print(DarkRP.loader.colors.error, '[DARKRP:LOADER:ERROR] ', msg)
	if err then
		DarkRP.loader.print(DarkRP.loader.colors.error, '  └─ ', tostring(err))
	end
	
	table.insert(DarkRP.loader._internal.errors, {
		msg = msg,
		error = err,
		context = context,
		time = os.time(),
		realm = SERVER and 'server' or 'client',
		stack = debug.traceback()
	})
	
	DarkRP.loader._internal.stats.totalErrors = DarkRP.loader._internal.stats.totalErrors + 1
end

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  Benchmarking System                                          ║
-- ╚═══════════════════════════════════════════════════════════════╝

function DarkRP.loader.startBenchmark(name)
	if DarkRP.loader.config.benchmarking then
		DarkRP.loader._internal.benchmarks[name] = SysTime()
	end
end

function DarkRP.loader.endBenchmark(name)
	if DarkRP.loader.config.benchmarking and DarkRP.loader._internal.benchmarks[name] then
		local elapsed = (SysTime() - DarkRP.loader._internal.benchmarks[name]) * 1000
		DarkRP.loader._internal.benchmarks[name] = nil
		return elapsed
	end
	return 0
end

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  Hook System                                                  ║
-- ╚═══════════════════════════════════════════════════════════════╝

function DarkRP.loader.addHook(hookName, identifier, callback)
	if not DarkRP.loader._internal.hooks[hookName] then
		DarkRP.loader._internal.hooks[hookName] = {}
	end
	
	DarkRP.loader._internal.hooks[hookName][identifier] = callback
	DarkRP.loader.verbose('Registered hook: ' .. hookName .. '.' .. identifier)
end

function DarkRP.loader.removeHook(hookName, identifier)
	if DarkRP.loader._internal.hooks[hookName] then
		DarkRP.loader._internal.hooks[hookName][identifier] = nil
	end
end

function DarkRP.loader.callHook(hookName, ...)
	if not DarkRP.loader._internal.hooks[hookName] then return end
	
	local results = {}
	for identifier, callback in pairs(DarkRP.loader._internal.hooks[hookName]) do
		local success, result = pcall(callback, ...)
		if success then
			table.insert(results, result)
		else
			DarkRP.loader.error('Hook error: ' .. hookName .. '.' .. identifier, result)
		end
	end
	
	return results
end

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  Cache Management                                             ║
-- ╚═══════════════════════════════════════════════════════════════╝

function DarkRP.loader.getCache(path)
	if not DarkRP.loader.config.cacheEnabled then return nil end
	return DarkRP.loader._internal.cache[path]
end

function DarkRP.loader.setCache(path, value)
	if DarkRP.loader.config.cacheEnabled then
		DarkRP.loader._internal.cache[path] = value
	end
end

function DarkRP.loader.clearCache(pattern)
	if pattern then
		local cleared = 0
		for path, _ in pairs(DarkRP.loader._internal.cache) do
			if path:match(pattern) then
				DarkRP.loader._internal.cache[path] = nil
				cleared = cleared + 1
			end
		end
		DarkRP.loader.verbose('Cleared ' .. cleared .. ' cache entries matching: ' .. pattern)
	else
		DarkRP.loader._internal.cache = {}
		DarkRP.loader.info('Cache cleared completely')
	end
end

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  Dependency Management                                        ║
-- ╚═══════════════════════════════════════════════════════════════╝

function DarkRP.loader.registerDependency(file, dependencies)
	file = DarkRP.loader.normalizePath(file)
	
	if type(dependencies) == 'string' then
		dependencies = {dependencies}
	end
	
	DarkRP.loader._internal.dependencies[file] = dependencies
	DarkRP.loader.verbose('Registered dependencies for: ' .. file)
end

function DarkRP.loader.getDependencies(file)
	file = DarkRP.loader.normalizePath(file)
	return DarkRP.loader._internal.dependencies[file] or {}
end

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  Core Loading Functions                                       ║
-- ╚═══════════════════════════════════════════════════════════════╝

function DarkRP.loader.includeFile(path, realm)
	path = DarkRP.loader.normalizePath(path)
	realm = realm or DarkRP.loader.getRealm(path)
	
	-- Send to clients if on server
	if SERVER then
		if realm == 'shared' or realm == 'client' then
			if not DarkRP.loader.fileExists(path) then
				error('File does not exist (server trying to send to client): ' .. path)
			end
			
			AddCSLuaFile(path)
			DarkRP.loader.verbose('AddCSLuaFile: ' .. path)
		end
	end
	
	-- Include on appropriate realm
	if DarkRP.loader.shouldLoad(realm) then
		if not DarkRP.loader.fileExists(path) then
			error('File does not exist: ' .. path)
		end
		return include(path)
	end
	
	return nil
end

function DarkRP.loader.load(path, options)
	path = DarkRP.loader.normalizePath(path)
	options = options or {}
	
	local realm = options.realm or DarkRP.loader.getRealm(path)
	local cache = options.cache ~= false
	local force = options.force or false
	local silent = options.silent or false
	
	-- Call pre-load hook
	DarkRP.loader.callHook('PreLoad', path, options)
	
	-- Check cache
	if cache and not force then
		local cached = DarkRP.loader.getCache(path)
		if cached ~= nil then
			DarkRP.loader.verbose('Cache hit: ' .. path)
			return cached
		end
	end
	
	-- Check if file exists
	if not DarkRP.loader.fileExists(path) then
		DarkRP.loader.error('File not found: ' .. path)
		return nil
	end
	
	-- Detect circular dependencies
	if DarkRP.loader._internal.loading[path] then
		DarkRP.loader.error('Circular dependency detected: ' .. path)
		return nil
	end
	
	-- Load dependencies first
	local deps = DarkRP.loader.getDependencies(path)
	for _, dep in ipairs(deps) do
		dep = DarkRP.loader.normalizePath(dep)
		if not DarkRP.loader.getCache(dep) then
			DarkRP.loader.verbose('Loading dependency: ' .. dep .. ' for ' .. path)
			DarkRP.loader.load(dep, options)
		end
	end
	
	-- Mark as loading
	DarkRP.loader._internal.loading[path] = true
	DarkRP.loader.startBenchmark(path)
	
	-- Attempt to load file
	local success, result = pcall(DarkRP.loader.includeFile, path, realm)
	
	local loadTime = DarkRP.loader.endBenchmark(path)
	DarkRP.loader._internal.loading[path] = nil
	
	-- Handle load failure
	if not success then
		DarkRP.loader.error('Failed to load: ' .. path, result, {realm = realm})
		
		if DarkRP.loader.config.throwErrors then
			error(result)
		end
		
		DarkRP.loader.callHook('LoadError', path, result, options)
		return nil
	end
	
	-- Cache result
	if cache then
		DarkRP.loader.setCache(path, result)
	end
	
	-- Track load order and metadata
	table.insert(DarkRP.loader._internal.loadOrder, path)
	DarkRP.loader._internal.metadata[path] = {
		realm = realm,
		loadTime = loadTime,
		size = DarkRP.loader.getFileSize(path),
		timestamp = os.time()
	}
	
	-- Update statistics
	DarkRP.loader._internal.stats.totalLoads = DarkRP.loader._internal.stats.totalLoads + 1
	DarkRP.loader._internal.stats.totalTime = DarkRP.loader._internal.stats.totalTime + loadTime
	DarkRP.loader._internal.stats.filesLoaded = DarkRP.loader._internal.stats.filesLoaded + 1
	
	if not silent then
		if DarkRP.loader.config.showLoadOrder then
			DarkRP.loader.info(string.format('[%d] Loaded: %s [%s] (%.3fms)', 
				DarkRP.loader._internal.stats.filesLoaded, path, realm, loadTime))
		else
			DarkRP.loader.verbose(string.format('Loaded: %s [%s] (%.3fms)', path, realm, loadTime))
		end
	end
	
	-- Call post-load hook
	DarkRP.loader.callHook('PostLoad', path, result, options)
	
	return result
end

function DarkRP.loader.loadFiles(files, options)
	local results = {}
	for i, file in ipairs(files) do
		results[i] = DarkRP.loader.load(file, options)
	end
	return results
end

function DarkRP.loader.loadDir(path, options)
	path = DarkRP.loader.normalizePath(path)
	options = options or {}
	
	local recursive = options.recursive ~= false
	local exclude = options.exclude or {}
	local filter = options.filter
	local maxDepth = options.maxDepth or DarkRP.loader.config.maxDepth
	local currentDepth = options._depth or 0
	local sortOrder = options.sortOrder or 'alphabetical'
	local sortFunc = options.sortFunc
	local pattern = options.pattern or '%.lua$'
	
	if currentDepth >= maxDepth then
		DarkRP.loader.warn('Max directory depth reached: ' .. path)
		return {}
	end
	
	DarkRP.loader.verbose('Scanning directory: ' .. path)
	
	local results = {}
	local files, folders = file.Find(path .. '/*', 'GAME')
	
	-- Try LUA path if GAME doesn't work
	if not files or #files == 0 then
		files, folders = file.Find(path .. '/*', 'LUA')
	end
	
	if not files or #files == 0 then
		DarkRP.loader.warn('Directory not found or empty: ' .. path)
		return {}
	end
	
	-- Sort files
	if sortOrder == 'alphabetical' then
		table.sort(files)
	elseif sortOrder == 'realm' then
		-- Sort by realm: server first, then shared, then client
		table.sort(files, function(a, b)
			local realmA = DarkRP.loader.getRealm(a)
			local realmB = DarkRP.loader.getRealm(b)
			local order = {server = 1, shared = 2, client = 3}
			local orderA = order[realmA] or 4
			local orderB = order[realmB] or 4
			if orderA == orderB then
				return a < b
			end
			return orderA < orderB
		end)
	elseif sortFunc then
		table.sort(files, sortFunc)
	end
	
	if folders then
		table.sort(folders)
	else
		folders = {}
	end
	
	-- Load files
	for _, filename in ipairs(files) do
		if filename:match(pattern) then
			local fullPath = path .. '/' .. filename
			local shouldExclude = false
			
			-- Skip shared.lua, init.lua, cl_init.lua (handled separately)
			if filename == 'shared.lua' or filename == 'init.lua' or filename == 'cl_init.lua' then
				shouldExclude = true
			end
			
			-- Check exclusions
			for _, excludePattern in ipairs(exclude) do
				if fullPath:match(excludePattern) or filename:match(excludePattern) then
					shouldExclude = true
					DarkRP.loader.verbose('Excluded: ' .. fullPath)
					break
				end
			end
			
			-- Check custom filter
			if not shouldExclude and filter and not filter(fullPath, filename) then
				shouldExclude = true
				DarkRP.loader.verbose('Filtered: ' .. fullPath)
			end
			
			if not shouldExclude then
				table.insert(results, DarkRP.loader.load(fullPath, options))
			end
		end
	end
	
	-- Load subdirectories if recursive
	if recursive then
		for _, folder in ipairs(folders) do
			if folder ~= '.' and folder ~= '..' then
				local subOptions = table.Copy(options)
				subOptions._depth = currentDepth + 1
				local subResults = DarkRP.loader.loadDir(path .. '/' .. folder, subOptions)
				table.Add(results, subResults)
			end
		end
	end
	
	DarkRP.loader.verbose(string.format('Loaded %d file(s) from: %s', #results, path))
	return results
end

function DarkRP.loader.loadModule(modulePath, options)
	modulePath = DarkRP.loader.normalizePath(modulePath)
	options = options or {}
	
	-- Try loading module/init.lua
	local initPath = modulePath .. '/init.lua'
	if DarkRP.loader.fileExists(initPath) then
		DarkRP.loader.verbose('Loading module via init.lua: ' .. modulePath)
		return DarkRP.loader.load(initPath, options)
	end
	
	-- Try loading module/shared.lua
	local sharedPath = modulePath .. '/shared.lua'
	if DarkRP.loader.fileExists(sharedPath) then
		DarkRP.loader.verbose('Loading module via shared.lua: ' .. modulePath)
		return DarkRP.loader.load(sharedPath, options)
	end
	
	-- Fall back to loading entire directory
	DarkRP.loader.verbose('Loading module via directory scan: ' .. modulePath)
	return DarkRP.loader.loadDir(modulePath, options)
end

function DarkRP.loader.reload(path, options)
	path = DarkRP.loader.normalizePath(path)
	
	-- Clear from cache
	DarkRP.loader._internal.cache[path] = nil
	DarkRP.loader._internal.metadata[path] = nil
	
	DarkRP.loader.info('Reloading: ' .. path)
	
	-- Force load
	local opts = options or {}
	opts.force = true
	
	return DarkRP.loader.load(path, opts)
end

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  Realm-Specific Convenience Functions                        ║
-- ╚═══════════════════════════════════════════════════════════════╝

function DarkRP.loader.loadShared(path, options)
	options = options or {}
	options.realm = 'shared'
	return DarkRP.loader.load(path, options)
end

function DarkRP.loader.loadServer(path, options)
	options = options or {}
	options.realm = 'server'
	return DarkRP.loader.load(path, options)
end

function DarkRP.loader.loadClient(path, options)
	options = options or {}
	options.realm = 'client'
	return DarkRP.loader.load(path, options)
end

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  Statistics & Reporting                                       ║
-- ╚═══════════════════════════════════════════════════════════════╝

function DarkRP.loader.getStats()
	return {
		version = DarkRP.loader.VERSION,
		filesLoaded = #DarkRP.loader._internal.loadOrder,
		cacheSize = table.Count(DarkRP.loader._internal.cache),
		errors = #DarkRP.loader._internal.errors,
		warnings = #DarkRP.loader._internal.warnings,
		loadOrder = DarkRP.loader._internal.loadOrder,
		totalLoads = DarkRP.loader._internal.stats.totalLoads,
		totalErrors = DarkRP.loader._internal.stats.totalErrors,
		totalTime = DarkRP.loader._internal.stats.totalTime,
		averageTime = DarkRP.loader._internal.stats.totalLoads > 0 and 
		             (DarkRP.loader._internal.stats.totalTime / DarkRP.loader._internal.stats.totalLoads) or 0
	}
end

function DarkRP.loader.getMetadata(path)
	path = DarkRP.loader.normalizePath(path)
	return DarkRP.loader._internal.metadata[path]
end

function DarkRP.loader.printReport()
	local stats = DarkRP.loader.getStats()
	
	DarkRP.loader.print(DarkRP.loader.colors.primary, '\n╔════════════════════════════════════════════════════════════╗')
	DarkRP.loader.print(DarkRP.loader.colors.primary, '║         DarkRP Loader v' .. DarkRP.loader.VERSION .. ' - Statistics           ║')
	DarkRP.loader.print(DarkRP.loader.colors.primary, '╠════════════════════════════════════════════════════════════╣')
	DarkRP.loader.print(DarkRP.loader.colors.info, '  Files Loaded:      ', tostring(stats.filesLoaded))
	DarkRP.loader.print(DarkRP.loader.colors.info, '  Total Loads:       ', tostring(stats.totalLoads))
	DarkRP.loader.print(DarkRP.loader.colors.info, '  Cache Size:        ', tostring(stats.cacheSize))
	DarkRP.loader.print(DarkRP.loader.colors.info, '  Total Load Time:   ', string.format('%.2fms', stats.totalTime))
	DarkRP.loader.print(DarkRP.loader.colors.info, '  Average Load Time: ', string.format('%.3fms', stats.averageTime))
	
	if stats.warnings > 0 then
		DarkRP.loader.print(DarkRP.loader.colors.warning, '  Warnings:          ', tostring(stats.warnings))
	end
	
	if stats.errors > 0 then
		DarkRP.loader.print(DarkRP.loader.colors.error, '  Errors:            ', tostring(stats.errors))
		DarkRP.loader.print(DarkRP.loader.colors.primary, '╠════════════════════════════════════════════════════════════╣')
		for i, err in ipairs(DarkRP.loader._internal.errors) do
			if i <= 5 then
				DarkRP.loader.print(DarkRP.loader.colors.error, '  ' .. i .. '. ', err.msg)
			end
		end
		if stats.errors > 5 then
			DarkRP.loader.print(DarkRP.loader.colors.dim, '  ... and ' .. (stats.errors - 5) .. ' more errors')
		end
	else
		DarkRP.loader.print(DarkRP.loader.colors.success, '  Errors:            ', '0')
	end
	
	DarkRP.loader.print(DarkRP.loader.colors.primary, '╚════════════════════════════════════════════════════════════╝\n')
end

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  Advanced Features                                            ║
-- ╚═══════════════════════════════════════════════════════════════╝

function DarkRP.loader.getLoadOrder()
	return DarkRP.loader._internal.loadOrder
end

function DarkRP.loader.isLoaded(path)
	path = DarkRP.loader.normalizePath(path)
	return DarkRP.loader.getCache(path) ~= nil
end

function DarkRP.loader.getErrors()
	return DarkRP.loader._internal.errors
end

function DarkRP.loader.getWarnings()
	return DarkRP.loader._internal.warnings
end

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  Console Commands                                             ║
-- ╚═══════════════════════════════════════════════════════════════╝

concommand.Add('darkrp_loader_verbose', function(ply, cmd, args)
	if IsValid(ply) and not ply:IsSuperAdmin() then return end
	
	local newState = args[1] == '1' or args[1] == 'true' or args[1] == 'on'
	DarkRP.loader.config.verbose = newState
	
	local msg = 'DarkRP Loader verbose mode: ' .. (newState and 'ENABLED' or 'DISABLED')
	if IsValid(ply) then
		ply:ChatPrint(msg)
	else
		print(msg)
	end
end)

concommand.Add('darkrp_loader_stats', function(ply, cmd, args)
	if IsValid(ply) and not ply:IsSuperAdmin() then return end
	DarkRP.loader.printReport()
end)

concommand.Add('darkrp_loader_errors', function(ply, cmd, args)
	if IsValid(ply) and not ply:IsSuperAdmin() then return end
	
	local errors = DarkRP.loader.getErrors()
	DarkRP.loader.info('Total errors: ' .. #errors)
	
	for i, err in ipairs(errors) do
		DarkRP.loader.print(DarkRP.loader.colors.error, '[' .. i .. '] ', err.msg)
		if err.error then
			DarkRP.loader.print(DarkRP.loader.colors.dim, '  └─ ', tostring(err.error))
		end
	end
end)

concommand.Add('darkrp_loader_clear_cache', function(ply, cmd, args)
	if IsValid(ply) and not ply:IsSuperAdmin() then return end
	DarkRP.loader.clearCache()
	local msg = 'DarkRP Loader cache cleared'
	if IsValid(ply) then
		ply:ChatPrint(msg)
	else
		print(msg)
	end
end)

DarkRP.loader.success('DarkRP Loader v' .. DarkRP.loader.VERSION .. ' initialized')

return DarkRP.loader
