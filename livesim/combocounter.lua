-- Combo counter animation
-- Part of Live Simulator: 2
-- See copyright notice in main.lua

local tween = require("tween")
local love = love
local DEPLS = ...
local ComboCounter = {CurrentCombo = 0}

local combo_scale = {s = 1.15}
local combo_tween = tween.new(150, combo_scale, {s = 1}, "inOutSine")
local combo_boom = {s = 1.25, op = 127}
local combo_boom_tween = tween.new(330, combo_boom, {s = 1.65, op = 0})

local function get_combo_num_idx(combo)
	if combo < 50 then
		-- 0-49
		return 1
	elseif combo < 100 then
		-- 50-99
		return 2
	elseif combo < 200 then
		-- 100-199
		return 3
	elseif combo < 300 then
		-- 200-299
		return 4
	elseif combo < 400 then
		-- 300-399
		return 5
	elseif combo < 500 then
		-- 400-499
		return 6
	elseif combo < 600 then
		-- 500-599
		return 7
	elseif combo < 1000 then
		-- 600-999
		return 8
	elseif combo < 2000 then
		-- 1000-1999
		return 9
	else
		-- >= 2000
		return 10
	end
end

function ComboCounter.Update(deltaT)
	if ComboCounter.Replay then
		combo_tween:reset()
		combo_boom_tween:reset()
		ComboCounter.Replay = false
	end
	
	-- Don't draw if combo is 0
	if ComboCounter.CurrentCombo > 0 then
		combo_tween:update(deltaT)
		combo_boom_tween:update(deltaT)
	end
end


function ComboCounter.Draw()
	local cc = ComboCounter.CurrentCombo
	if cc > 0 then
		-- "combo" pos: 541x267+61+17
		-- number pos: 451x267+24+24; aligh right; subtract by 43 for distance
		-- ImageMagick coordinate notation is used
		local combo_str = {string.byte(tostring(cc), 1, 20)}
		local img = DEPLS.Images.ComboNumbers[get_combo_num_idx(cc)]
		
		love.graphics.push()
		love.graphics.translate(480, 320)
		love.graphics.scale(DEPLS.TextScaling)
		love.graphics.setColor(255, 255, 255, combo_boom.op * DEPLS.LiveOpacity / 255)
		love.graphics.draw(img.combo, 61, -54, 0, combo_boom.s, combo_boom.s, 61, 18)
		love.graphics.setColor(1, 1, 1, DEPLS.LiveOpacity)
		
		for i = 1, #combo_str do
			-- Draw numbers
			love.graphics.draw(img[combo_str[i] - 47], -29 - (#combo_str - i) * 43, -53, 0, combo_scale.s, combo_scale.s, 24, 24)
		end
		
		love.graphics.draw(img.combo, 61, -54, 0, combo_scale.s, combo_scale.s, 61, 17)
		love.graphics.setColor(1, 1, 1)
		love.graphics.pop()
	end
end

return ComboCounter
