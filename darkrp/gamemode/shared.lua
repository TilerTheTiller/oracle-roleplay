AddCSLuaFile()

DeriveGamemode("sandbox")

GM.Name 		= "DarkRP"
GM.Author 		= "Custom"
GM.Email 		= ""
GM.Website 		= ""

-- Load job system (core must load before configs)
include("core/jobs/sh_jobs.lua")
include("configs/sh_jobs.lua")

-- Load database module first (server-only)
if SERVER then
	include("core/database/sv_database.lua")
	print("[DarkRP] Database module loaded first")
end

function recursiveInclusion( scanDirectory, isGamemode )
	-- Null-coalescing for optional argument
	isGamemode = isGamemode or false
	
	local queue = { scanDirectory }
	
	-- Loop until queue is cleared
	while #queue > 0 do
		-- For each directory in the queue...
		for _, directory in pairs( queue ) do
			print( "[DarkRP:Loader] Scanning directory: ", directory )
			
			local files, directories = file.Find( directory .. "/*", "LUA" )
			
			-- Include files within this directory
			for _, fileName in pairs( files ) do
				if fileName != "shared.lua" and fileName != "init.lua" and fileName != "cl_init.lua" then
					print( "[DarkRP:Loader] Found file: ", fileName, " in ", directory )
					
					-- Create a relative path for inclusion functions
					-- Also handle pathing case for including gamemode folders
					local relativePath = directory .. "/" .. fileName
					if isGamemode then
						relativePath = string.gsub( directory .. "/" .. fileName, GM.FolderName .. "/gamemode/", "" )
					end
					
					-- Include server files
					if string.match( fileName, "^sv" ) then
						if SERVER then
							print( "[DarkRP:Loader] Including server file: ", relativePath )
							include( relativePath )
						end
					end
					
					-- Include shared files
					if string.match( fileName, "^sh" ) then
						print( "[DarkRP:Loader] Including shared file: ", relativePath )
						AddCSLuaFile( relativePath )
						include( relativePath )
					end
					
					-- Include client files
					if string.match( fileName, "^cl" ) then
						print( "[DarkRP:Loader] Adding/Including client file: ", relativePath )
						AddCSLuaFile( relativePath )
						
						if CLIENT then
							include( relativePath )
						end
					end
				end
			end
			
			-- Append directories within this directory to the queue
			for _, subdirectory in pairs( directories ) do
				-- print( "Found directory: ", subdirectory )
				table.insert( queue, directory .. "/" .. subdirectory )
			end
			
			-- Remove this directory from the queue
			table.RemoveByValue( queue, directory )
		end
	end
end

recursiveInclusion( GM.FolderName .. "/gamemode", true )

-- Override sandbox hooks to prevent infinite recursion
if CLIENT then
	function GM:HUDPaint()
		-- Custom HUD implementation goes here
		-- Don't call base or you'll get infinite recursion
		
		-- Manually call registered HUDPaint hooks (skip the gamemode hook)
		for hookName, hookFunc in pairs(hook.GetTable()["HUDPaint"] or {}) do
			if hookName != "GM" then
				local success, result = pcall(hookFunc)
				if not success then
					ErrorNoHalt("HUDPaint hook error [" .. hookName .. "]: " .. tostring(result) .. "\n")
				end
			end
		end
	end
	
	function GM:PostRenderVGUI()
		-- Custom VGUI rendering goes here
		-- Don't call base or you'll get infinite recursion
	end
	
	-- Weed system is loaded automatically by the loader in core/weed/ directory
end
