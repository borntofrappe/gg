-- a shmup
-- following lazy devs' tut
cartdata("ashmup")
local high_score = dget(0)
local mode = nil
local i = nil
local waves = {
	{
		{ 1, 1, 1, 1, 1, 1 }, 
		{ 1, 1, 1, 1, 1, 1 }, 
	},
	{
		{ 1, 2, 0, 0, 2, 1 },
		{ 1, 0, 2, 2, 0, 1 },
		{ 1, 2, 2, 2, 2, 1 },
	},
	{
		{ 2, 0, 3, 1, 3, 0, 2 }, 
		{ 2, 0, 3, 1, 3, 0, 2 }, 
		{ 2, 0, 3, 1, 3, 0, 2 }, 
		{ 2, 0, 3, 1, 3, 0, 2 }, 
	},
	{
		{ 1, 2, 1, 1, 2, 1 }, 
		{ 3, 1, 2, 2, 1, 3 }, 
		{ 1, 2, 4, 4, 2, 1 }, 
	},
	{
		{ 1, 0, 1, 1, 1, 1, 0, 1 }, 
		{ 1, 0, 0, 0, 0, 0, 0, 1, }, 
		{ 1, 0, 0, 5, 0, 0, 1 }, 
	},
	{
		{ 5, 0, 2, 2, 2, 2, 0, 5 }, 
		{ 1, 3, 1, 2, 2, 1, 3, 1 }, 
		{ 1, 0, 0, 5, 0, 0, 1 }, 
	},
	"boss",
}

local sfxs = { 
	player_shoots = 0,
	player_bullet_hits = 1,
	player_defeats_enemy = 2,
	enemy_shoots = 3, 
	player_suffer_damage = 4, 
	player_pickup_regular = 5,
	player_pickup_bonus = 6,
	player_shoots_special = 7,
	player_missing_ammo = 8,
	boss_shoots = 9,
	small_explosion = 2,
	big_explosion = 10,
	intro_start = 11,
	intro_enemies = 12,
	clear_wave = 13,
	outro_gameover = 14
}

local button_pressed = false

local camera_shake = 0
local shake = { x = 0, y = 0 }
local camera_flash = 0
local flash_color = 0
local fade_colors = { 0, 1, 6, 6, 7, 7, 7, 7, 6, 6, 1, 0 }

local peeker_y = 27
local peeker = { xs = { 40, 80 }, x = 56, y = peeker_y, dy = 1, t = 0, sprites = { 10, 11, 10, 12 }, is = 1, ds = 0.35 }
function play_sound(title)
	local n = sfxs[title]
	if n then sfx(n) end
end

function shake_camera(d)
	camera_shake = d or 2
end

function flash_screen(c)
	camera_flash = 2
	flash_color = c or 2
end

function check_collision(a, b)
	if a.x + a.w + a.inset.x < b.x + b.inset.x or a.x + a.inset.x > b.x + b.w + b.inset.x or a.y + a.h + a.inset.y < b.y + b.inset.x or a.y + a.inset.y > b.y + b.h + b.inset.y then
		return false
	end
	return true
end

function start_game()
	peeker.y = peeker_y
	peeker.t = 0
	i = 0
	starfield_init(80)
	local title = high_score != 0 and "high score:" .. format_score(high_score) or ""
	local colors = { { 10 }, fade_colors }
	screen_step_init(title, "press ❎ to shoot ", colors)
	mode = "start"
end

function lose_game(score)
	button_pressed = true

	local title = "gameover"
	local colors = { { 8, 0, 6, 10 }, fade_colors }
	if score and score > high_score then
		high_score = score
		dset(0, high_score)
		title = title .. "\n\nbut!\nnew high score:" .. format_score(high_score)
	end
	screen_step_init(title, "press ❎ to reset ", colors)
	mode = "end"
end

function new_wave(score)
	i += 1
	if i > #waves then 
		button_pressed = true

		local title = "victory"
		local colors = { { 12, 0, 7, 10 }, fade_colors }
		if score and score > high_score then
			high_score = score -- save score
			dset(0, high_score)
			title = title .. "\n\nand!\nnew high score:" .. format_score(high_score)
		end
		screen_step_init(title, "press ❎ to reset ", colors)
		mode = "end"
	else
		local title = i == #waves and "final showdown" or "wave " .. i .. " - " .. #waves - i + 1 .. " left"
		screen_through_init(title, function()
			init_wave(waves[i])
			mode = "play"
			if i != #waves then
				play_sound("intro_enemies")
			end
		end)
		mode = "ease-in"
	end
end

function _init()
	start_game()
end

function _update()
	if mode == "start" then 
		peeker.is += peeker.ds
		if peeker.is > #peeker.sprites then
			peeker.is = 1
		end
		peeker.t += 0.01
		peeker.y = peeker_y + sin(peeker.t) * peeker.dy * 16
		if peeker.t > 0.5 then
			peeker.t = 0
			peeker.x = peeker.xs[1] + flr(rnd() * (peeker.xs[2] - peeker.xs[1]))
			peeker.dy = rnd() > 0.5 and 1 or -1
		end
		screen_step_update()
		if btnp(❎) and not button_pressed then
			button_pressed = true
			play_sound("intro_start")
			game_init()
			new_wave()
		end
	elseif mode == "ease-in" then
		for i = 1, 3 do 
			starfield_update()
		end
		game_update()
		screen_through_update()
	elseif mode == "play" then 
		starfield_update()
		game_update()
	elseif mode == "end" then
		fxs_update()
		screen_step_update()
		if btnp(❎) and not button_pressed then
			button_pressed = true
			start_game()
		end
	end

	if not btn(❎) then
		button_pressed = false
	end

	if camera_shake > 0 then
		camera_shake *= 0.9
		camera_shake = max(0, camera_shake - 1)
		shake.x = rnd(camera_shake)
		shake.y = rnd(camera_shake)
	end

	if camera_flash > 0 then
		camera_flash-=1
	end
end

function _draw()
	camera(shake.x, shake.y)
	if camera_flash > 0 then
		cls(flash_color)
	else
		cls()
	end
	starfield_draw()
	if mode == "start" then 
		screen_step_draw()
		spr(peeker.sprites[flr(peeker.is)], peeker.x, peeker.y)
		spr(128, 0, 24, 16, 4)
	elseif mode == "ease-in" then 
		game_draw()
		screen_through_draw()
	elseif mode == "play" then 
		game_draw()
	elseif mode == "end" then 
		game_draw()
		screen_step_draw()
	end
end