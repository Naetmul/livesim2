-- NoteLoader2, OOP, efficient NoteLoader
-- Part of Live Simulator: 2
-- See copyright notice in main.lua

--[[
// Loader class
class NoteLoaderLoader
{
public:
	bool ProjectLoader;
	
	/// @brief Load specificed note from filename
	/// @returns Loaded note object on success, NULL on failure
	virtual NoteLoaderNoteObject* LoadNoteFromFilename(const char* filename) = 0;
	virtual const char* GetLoaderName() = 0;
};

// Returned from loader
class NoteLoaderNoteObject
{
public:
	/// \brief Get notes list
	/// \returns Notes list. This one never return NULL
	virtual std::vector<Livesim2::Note> GetNotesList() = 0;
	
	/// \brief Get beatmap name, or filename if no suitable filename found
	/// \returns Beatmap name. This one never return NULL
	virtual const char* GetName() = 0;
	
	/// \brief Get beatmap type name (friendly name)
	/// \returns Beatmap type name
	virtual const char* GetBeatmapTypename() = 0;
	
	/// \brief Get cover art information
	/// \returns Cover art information (or NULL)
	virtual Livesim2::CoverArt* GetCoverArt();
	
	/// \brief Get custom unit informmation
	/// \returns Custom unit information. Index 0 is rightmost (8 is leftmost). Some index may be NULL, but the returned pointer never NULL.
	/// \note Lua is 1-based, so it should be index 1 is rightmost.
	virtual Livesim2::Unit*[9] GetCustomUnitInformation();
	
	/// \brief Get score information sequence.
	/// \description This function returns unsigned integer with these index:
	///              - [0], score needed for C score
	///              - [1], score needed for B score
	///              - [2], score needed for A score
	///              - [3], score needed for S score
	/// \returns Score information array (or NULL if no score information present)
	virtual unsigned int* GetScoreInformation();
	
	virtual unsigned int* GetComboInformation();
	virtual Livesim2::Storyboard* GetStoryboard();
	
	/// \brief Retrieves background ID
	/// \returns -1, if custom background present, 0 if no background ID (or video) present, otherwise the background ID
	virtual int GetBackgroundID();
	
	/// \brief Retrieves custom background
	/// \returns NULL if custom background not present, otherwise handle to custom background object
	virtual Livesim2::Background* GetCustomBackground();
	
	/// Returns the video handle or NULL if video not found
	virtual Livesim2::Video* GetVideoBackground();
	
	/// Returns score per tap or 0 to use from config
	virtual int GetScorePerTap();
	/// Returns stamina or 0 to use from config
	virtual char GetStamina();
	/// Returns: 1 = old, 2 = v5, 0 = no enforcing
	virtual int GetNotesStyle();
	
	virtual Livesim2::SoundData* GetBeatmapAudio();
	virtual Livesim2::SoundData* GetLiveClearSound();
	
	/// \brief Get star difficulty information.
	/// \param random Retrieve star difficulty information for random notes instead?
	/// \returns Star difficulty information, or 0 if not available
	virtual int GetStarDifficultyInfo(bool random);
	
	virtual void ReleaseBeatmapAudio();
	virtual void Release();
};
]]

local AquaShine = ...
local love = love
local NoteLoader = {}
local NoteLoaderLoader = {}
local NoteLoaderNoteObject = {}

NoteLoaderLoader.__index = NoteLoaderLoader
NoteLoaderNoteObject.__index = NoteLoaderNoteObject

NoteLoader.NoteLoaderNoteObject = NoteLoaderNoteObject
NoteLoader.FileLoaders = {}
NoteLoader.ProjectLoaders = {}

---------------------------
-- Note Loading Function --
---------------------------
function NoteLoader._GetBasenameWOExt(file)
	return ((file:match("^(.+)%..*$") or file):gsub("(.*/)(.*)", "%2"))
end

function NoteLoader._LoadDefaultAudioFromFilename(file)
	return AquaShine.LoadAudio("audio/"..NoteLoader._GetBasenameWOExt(file)..".wav")
end

function NoteLoader._UnzipOnGone(zip_path)
	local x = newproxy(true)
	local y = getmetatable(x)
	
	y.__gc = function()
		AquaShine.MountZip(zip_path, nil)
	end
	
	return x
end

function NoteLoader.NoteLoader(file)
	local project_mode = love.filesystem.isDirectory(file)
	local destination = file
	local project_destination = "temp/.beatmap/"..file:gsub("(.*/)(.*)", "%2")
	local zip_path
	
	if not(project_mode) and AquaShine.MountZip(file, project_destination) then
		-- File is mountable. Project-based beatmap.
		project_mode = true
		destination = project_destination
		zip_path = file
	end
	
	if project_mode then
		-- Project folder loading
		for i = 1, #NoteLoader.ProjectLoaders do
			local ldr = NoteLoader.ProjectLoaders[i]
			local success, nobj = pcall(ldr.LoadNoteFromFilename, destination)
			
			if success then
				if zip_path then
					nobj._zipobj = NoteLoader._UnzipOnGone(zip_path)
				end
				
				return nobj
			end
			
			AquaShine.Log("NoteLoader2", "Failed to load %q with loader %s: %s", file, ldr.GetLoaderName(), nobj)
		end
		
		if zip_path then
			assert(AquaShine.MountZip(file, nil), "ZIP unmount failed")
		end
	else
		-- File loading
		for i = 1, #NoteLoader.FileLoaders do
			local ldr = NoteLoader.FileLoaders[i]
			local success, nobj = pcall(ldr.LoadNoteFromFilename, destination)
			
			if success then
				return nobj
			end
			
			AquaShine.Log("NoteLoader2", "Failed to load %q with loader %s: %s", file, ldr.GetLoaderName(), nobj)
		end
	end
end

function NoteLoader.Enumerate()
	local a = {}
	
	for _, f in ipairs(love.filesystem.getDirectoryItems("beatmap/")) do
		local b = NoteLoader.NoteLoader("beatmap/"..f)
		
		if b then
			a[#a + 1] = b
		end
	end
	
	return a
end

------------------------
-- NoteLoader Loaders --
------------------------
function NoteLoaderLoader.LoadNoteFromFilename()
	assert(false, "Derive NoteLoaderLoader then implement LoadNoteFromFilename")
end

function NoteLoaderLoader.GetLoaderName()
	assert(false, "Derive NoteLoaderLoader then implement GetLoaderName")
end

----------------------------
-- NoteLoader Note Object --
----------------------------
local function nilret() return nil end
local function zeroret() return 0 end

-- Derive function
function NoteLoaderNoteObject._derive(tbl)
	return setmetatable(tbl, NoteLoaderNoteObject)
end

function NoteLoaderNoteObject.GetNotesList()
	assert(false, "Derive NoteLoaderNoteObject then implement GetNotesList")
end

function NoteLoaderNoteObject.GetName()
	assert(false, "Derive NoteLoaderNoteObject then implement GetName")
end

function NoteLoaderNoteObject.GetBeatmapTypename()
	assert(false, "Derive NoteLoaderNoteObject then implement GetBeatmapTypename")
end

function NoteLoaderNoteObject.GetCustomUnitInformation()
	return {}
end

NoteLoaderNoteObject.GetStarDifficultyInfo = zeroret
NoteLoaderNoteObject.GetBackgroundID = zeroret
NoteLoaderNoteObject.GetScorePerTap = zeroret
NoteLoaderNoteObject.GetStamina = zeroret
NoteLoaderNoteObject.GetNotesStyle = zeroret

NoteLoaderNoteObject.GetCoverArt = nilret
NoteLoaderNoteObject.GetScoreInformation = nilret
NoteLoaderNoteObject.GetComboInformation = nilret
NoteLoaderNoteObject.GetStoryboard = nilret
NoteLoaderNoteObject.GetCustomBackground = nilret
NoteLoaderNoteObject.GetVideoBackground = nilret
NoteLoaderNoteObject.GetBeatmapAudio = nilret
NoteLoaderNoteObject.GetLiveClearSound = nilret
NoteLoaderNoteObject.ReleaseBeatmapAudio = nilret
NoteLoaderNoteObject.Release = nilret

----------------
-- Initialize --
----------------

-- Load any note loaders with this glob: noteloader/load_*.lua
for _, f in ipairs(love.filesystem.getDirectoryItems("noteloader/")) do
	if f:find("load_", 1, true) == 1 and select(2, f:find(".lua", 4, true)) == #f then
		local loader = assert(love.filesystem.load("noteloader/"..f))(AquaShine, NoteLoader)
		local dest = loader.ProjectLoader and NoteLoader.ProjectLoaders or NoteLoader.FileLoaders
		
		dest[#dest + 1] = loader
		
		AquaShine.Log("NoteLoader2", "Registered note loader %s", loader.GetLoaderName())
	end
end

return NoteLoader
