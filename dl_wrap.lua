-- Beatmap download wrapper
-- Part of Live Simulator: 2
-- See copyright notice in main.lua

local AquaShine = ...
local dummy = function() end
local BackgroundImage = AquaShine.LoadModule("uielement.background_image")
local BackNavigation = AquaShine.LoadModule("uielement.backnavigation")
local DLWrap = {}

function DLWrap.IsLLPOK()
	return AquaShine.Download.HasHTTPS() or love.filesystem.getInfo("external/download_beatmap_llp.lua")
end

function DLWrap.GetLLPDestination()
	if AquaShine.Download.HasHTTPS() then
		return "download_beatmap_llp.lua"
	else
		return "external/download_beatmap_llp.lua"
	end
end

function DLWrap.Start()
	DLWrap.Delay = 10000
	DLWrap.Download = AquaShine.GetCachedData("BeatmapDLHandle", AquaShine.Download)
	DLWrap.LiveIDFont = AquaShine.LoadFont("MTLmr3m.ttf", 24)
	DLWrap.MainNode = BackNavigation("Download Beatmap", ":beatmap_select")
end

function DLWrap.Update(deltaT)
	local dest = DLWrap.IsLLPOK() and DLWrap.GetLLPDestination()
	DLWrap.Delay = DLWrap.Delay - deltaT
	if not(DLWrap.Download:IsDownloading()) then
		AquaShine.LoadEntryPoint(AquaShine.LoadConfig("DL_CURRENT", dest or "download_beatmap_sif.lua"))
	end
	
	if DLWrap.Delay <= 0 then
		DLWrap.Delay = math.huge
		DLWrap.Download:Cancel()
	end
end

function DLWrap.Draw()
	DLWrap.MainNode:draw()
	love.graphics.setFont(DLWrap.LiveIDFont)
	love.graphics.print("Please wait...", 102, 136)
end

function DLWrap.MousePressed(x, y, b, t)
	return DLWrap.MainNode:triggerEvent("MousePressed", x, y, b, t)
end

function DLWrap.MouseMoved(x, y, dx, dy, t)
	return DLWrap.MainNode:triggerEvent("MouseMoved", x, y, dx, dy, t)
end

function DLWrap.MouseReleased(x, y, b, t)
	return DLWrap.MainNode:triggerEvent("MouseReleased", x, y, b, t)
end

return DLWrap
