pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
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
-->8
-- game
local screen_size = 128
local char_width = 4
local sprite_size = 8

local timer = 0
local timer_cap = 50

local start_position = { x = flr(screen_size / 2), y = flr(screen_size * 3 / 4) }
local spaces = { ui = { 2, 2.5 }, formation = { nil, 12 }, enemies = { 4, 4 }, boss = { 4, 4 } }
local shakes = { camera = 5, enemies = 1, boss = 2 }

local fxs = {
	particles = { number = 30, colors = { 7, 10, 10, 9, 8, 3, 1 } },
	shockwaves = { colors = { 7, 10 } },
	sparks = { number = 30, colors = { 7, 10 } },
	floats = { colors = { 7, 14 } }
}

local frequencies = { enemies = { shoot_spread = 10 }, boss = { shoot_player = 7, shoot_down = 8, shoot_spread = 8, shoot_cardinal = 8 } }
local spread_shot = { player = 5, enemies = 6, boss = 6 }

local enemies_spec = {
	{ points = 1, type = 1, max_hp = 3, speed = 1.5, w = 8, h = 8, inset = { x = 0, y = 0 }, sprw = 1, sprh = 1, sprites = { 10, 11, 10, 12 }, ds = 0.5, colors = { 3, 3, 11, 11, 6, 13, 5 } },
	{ points = 4, type = 2, max_hp = 4, speed = 1.5, w = 8, h = 8, inset = { x = 0, y = 0 }, sprw = 1, sprh = 1, sprites = { 26, 27, 28, 29 }, ds = 0.25, colors = { 7, 14, 14, 15, 9, 5 } },
	{ points = 3, type = 3, max_hp = 2, speed = 2, w = 7, h = 8, inset = { x = 0.5, y = 0 }, sprw = 1, sprh = 1, sprites = { 42, 43, 44, 45 }, ds = 0.5, colors = { 10, 9, 6, 6, 13, 13, 5 } },
	{ points = 2, type = 1, max_hp = 4, speed = 2, w = 8, h = 8, inset = { x = 0, y = 0 }, sprw = 1, sprh = 1, sprites = { 58, 59, 60, 61 }, ds = 0.25, colors = { 10, 12, 12, 2, 1, 1 } },
	{ points = 12, type = 4, max_hp = 9, speed = 1, w = 16, h = 16, inset = { x = 1, y = 1 }, sprw = 2, sprh = 2, sprites = { 6, 8 }, ds = 0.25, colors = { 10, 10, 9, 9, 4, 4, 2, 1 } },
}
local enemies_bullet_spec = { damage = 1, speed = 2.5, w = 3, h = 3, inset = { x = 2.5, y = 2.5 }, sprites = { 48, 49, 50, 49, 48 }, ds = 0.5 }
local enemies = {}
local enemies_bullets = {}
local enemies_delays = { default = 1, spawn = 2, shake = 10, respawn = 16 }
local enemies_flash = { max = 9, skip = 3, color = 7 }

local boss_spec = { points = 110, max_hp = 50, timer_cap = 200, speed = 2, w = 32, h = 24, inset = { x = 0, y = 0 }, sprw = 4, sprh = 3, sprites = { 68, 72, 76, 72}, ds = 0.25, sprite_hit = 64, colors = { 11, 7, 7, 14, 8, 8, 7 } }
local boss = nil
local boss_bullets = {}
local boss_bullet_spec = { damage = 1, speed = 2, w = 3, h = 3, inset = { x = 2.5, y = 2.5 }, sprites = { 112, 113, 113, 114 }, ds = 0.5 }
local boss_flash = { max = 9, skip = 2, color = 8 }
local boss_explosion = { frequencies = { 4, 3 }, cap = { 40, 70 }, shakes = { 4, 6, 12 } }

local pickups = {}
local pickup_spec = { odds = 0.19, speed = 1, w = 5, h = 5, inset = { x = 1.5, y = 1.5 }, sprite = 31, outline = { colors = { 7, 14 }, color_skip = 5 } }

local player_bullet_spec = { damage = 1, speed = 5, w = 4, h = 7, inset = { x = 2, y = 1 }, sprites = { 32, 33, 34 }, ds = 0.5 }
local player_c_bullet_spec = { damage = 2, speed = 4.5, w = 7, h = 7, inset = { x = 0.5, y = 0.5 }, sprites = { 16 }, ds = 0 }
local space_x, space_y = spaces.ui[1], spaces.ui[2]
local player = {
	max_hps = { 3, 5 }, max_hp = 0, hp = 0, 
	speed = 3, dx = 0, dy = 0,
	x = 0, y = 0, w = 8, h = 8, inset = { x = 0, y = 0 },
	overload = 6, load = 0,
	sprite = 0, sprites = { default = 1, left = 2, right = 3 },
	lives = {
		sprites = { 14, 15 },
		xs = {}, y = screen_size - (space_x + sprite_size)
	},
	score = {
		value = 0,
		x = space_x, y = space_y,
		color = 12
	},
	pickups = {
		value = 0,
		points = 1000,
		max = 10,
		text = {
			color = 7,
			x = screen_size - (space_x + char_width), y = space_y + 1
		},
		sprite = {
			n = pickup_spec.sprite,
			x = screen_size - (space_x + char_width + space_x + sprite_size), y = space_y
		}, 
	},
	colors = { 7, 10, 10, 9, 8, 3, 1 }
}
local player_bullets = {}
local flame = { sprites = { 17, 18, 17, 19 }, is = 0 }
local muzzle = { r = 0, r_max = 4, dr = 1, color = 7 }
local shield = { r = 0, r_max = max(player.w, player.h), count = 0, count_max = 10, dcount = 0.3, color = 7 }

for i = 1, player.max_hps[2] do
	local x = space_x + (i -1) * (space_x + sprite_size)
	add(player.lives.xs, x)
end

function game_init()
	init_game()
end

function game_update()
	if player.hp > 0 then 
		update_player()
	end
	update_player_bullets()

	if #enemies > 0 then
		update_enemies()
	end
	update_enemies_bullets()

	if boss then
		update_boss()
	end
	update_boss_bullets()
	
	update_pickups()

	fxs_update()
end

function game_draw()
	draw_hud()
	draw_pickups()
	draw_bullets()
	draw_enemies()

	if boss then
		draw_boss()
	end

	if player.hp > 0 then 
		draw_player()
	end

	fxs_draw()
end
-->8
-- init functions
function init_game()
	timer = 0
	
	player.max_hp = player.max_hps[1]
	player.hp = player.max_hp
	player.x = start_position.x - flr(player.w / 2)
	player.y = start_position.y - flr(player.h / 2)
	player.load = 0
	player.sprite = player.sprites.default
	player.score.value = 0
	player.pickups.value = 0

	flame.is = 1
	muzzle.r = 0
	shield.r = 0
	shield.count = 0
	
	player_bullets = {}
	
	enemies = {}
	enemies_bullets = {}
	
	boss = nil
	boss_bullets = {}

	pickups = {}

	fxs_init()
end

function init_wave(wave)
	if wave == "boss" then
		local inset_y = spaces.formation[2]
		local w, h = boss_spec.w, boss_spec.h
		local ys = { h * 2 * -1, inset_y }
		boss = {
			points = boss_spec.points,
			hp = boss_spec.max_hp,
			mode = "spawn",
			ys = ys,
			speed = boss_spec.speed, dx = 0, dy = 0,
			x = screen_size / 2 - w / 2, y = ys[1], w = w, h = boss_spec.h, inset = boss_spec.inset,
			sprw = boss_spec.sprw, sprh = boss_spec.sprh,
			sprites = boss_spec.sprites, sprite_hit = boss_spec.sprite_hit, sprite = boss_spec.sprites[1], is = 1, ds = boss_spec.ds,
			colors = boss_spec.colors,
			timer = 0, timer_cap = boss_spec.timer_cap,
			flash = 0,
		}
	else
		local delay = enemies_delays.spawn
		local x = 0
		local y = 0
		local rows = #wave
		local gap_x, gap_y = spaces.enemies[1], spaces.enemies[2]
		for i = 1, #wave do 
			x = 0
			local h_max = sprite_size
			local row_enemies = {}
			for j = 1, #wave[i] do 
				local spec = enemies_spec[wave[i][j]]
				if spec then
					local w = spec.w
					local h = spec.h
					local row_enemy = {
						points = spec.points,
						type = spec.type,
						hp = spec.max_hp,
						mode = "",
						delay = delay + (j + (i - 1) * rows),
						xs = { spawn = 0, pause = 0 }, ys = { spawn = 0, pause = 0 },
						speed = spec.speed,
						x = x, y = y - h, w = w, h = h, inset = { x = spec.inset.x, y = spec.inset.y },
						sprw = spec.sprw, sprh = spec.sprh, sprites = spec.sprites, is = 1, ds = spec.ds,
						colors = spec.colors,
						flash = 0
					}
					add(row_enemies, row_enemy)
					x += w + gap_x
					if h > h_max then h_max = h end
				else
					x += sprite_size + gap_x
				end
			end
			y -= h_max + gap_y

			local x_offset = screen_size / 2 - (x - gap_x) / 2
			for enemy in all(row_enemies) do 
				enemy.x += x_offset
				add(enemies, enemy)
			end
		end

		local y_min = enemies[#enemies].y
		local y_inset = spaces.formation[2]
		for enemy in all(enemies) do
			local x, y = enemy.x, enemy.y
			enemy.xs.spawn = x
			enemy.xs.pause = x
			enemy.ys.spawn = y
			enemy.ys.pause = y + abs(y_min) + y_inset

			enemy.mode = "spawn"
		end
	end
end
-->8
--update functions
function new_bullet(spec, x, y, angle)
	local a = angle or 0
	local damage, speed, w, h, inset, sprites, ds = spec.damage, spec.speed, spec.w, spec.h, spec.inset, spec.sprites, spec.ds
	local sx = sin(a) * speed
	local sy = cos(a) * speed
	local bullet = {
		damage = damage,
		sx = sx, sy = sy,
		x = x - (w / 2 + inset.x), y = y - (h / 2 + inset.y), w = w, h = h, inset = inset,
		sprites = sprites, is = 1, ds = enemies_bullet_spec.ds
	}
	return bullet
end

function new_pickup(x, y)
	local speed, w, h, inset, sprite, colors, color_skip = pickup_spec.speed, pickup_spec.w, pickup_spec.h, pickup_spec.inset, pickup_spec.sprite, pickup_spec.outline.colors, pickup_spec.outline.color_skip
	local pickup = {
		sx = 0, sy = speed,
		x = x - (w / 2 + inset.x), y = y - (h / 2 + inset.y), w = w, h = h, inset = inset,
		sprite = sprite,
		colors = colors, color = colors[1], color_skip = color_skip, ci = 1
	}
	return pickup
end

function damage_player(damage)
	flash_screen(2)
	player.hp -= damage or 1

	local number = fxs.particles.number
	local x = player.x + player.w / 2 + player.inset.x
	local y = player.y + player.h / 2 + player.inset.y
	local colors = player.colors
	if player.hp <= 0 then
		lose_game(player.score.value)
		play_sound("outro_gameover")
	else
		shield.count = shield.count_max
		number = flr(number / 3)
	end
	fxs_particles(number, x, y, colors)
	play_sound("player_suffer_damage")
end

function player_shoot(spec, angles)
	player.load = player.overload
	muzzle.r = muzzle.r_max

	local x = player.x + player.inset.x + player.w / 2
	local y = player.y

	for angle in all(angles) do
		local bullet = new_bullet(spec, x, y, angle)
		add(player_bullets, bullet)
	end
end

function update_player()
	if btn(⬅️) then
		player.dx = -1
		player.sprite = player.sprites.left
	elseif btn(➡️) then
		player.dx = 1
		player.sprite = player.sprites.right
	else
		player.dx = 0
		player.sprite = player.sprites.default
	end
	if btn(⬆️) then
		player.dy = -1
	elseif btn(⬇️) then
		player.dy = 1
	else
		player.dy = 0
	end
	player.x += player.dx * player.speed
	player.y += player.dy * player.speed
	player.x = min(screen_size - player.w, max(0, player.x))
	player.y = min(screen_size - player.h, max(0, player.y))

	flame.is += 1
	if flame.is > #flame.sprites then
		flame.is = 1
	end
	if muzzle.r > 0 then
		muzzle.r = max(0, muzzle.r - muzzle.dr)
	end
	if shield.count > 0 then
		shield.count = max(0, shield.count - shield.dcount)
		shield.r = sin(shield.count) * shield.r_max
	end

	if player.load > 0 then 
		player.load -= 1
	end
	if btnp(🅾️) and player.load == 0 then
		if player.pickups.value > 0 then
			shake_camera(shakes.camera)
			flash_screen(9)
			
			local a1 = 0.4
			local a2 = 0.6
			local angles = {}
			for a = a1, a2, (a2 - a1) / spread_shot.player do 
				add(angles, a)
			end
	
			player.pickups.value-=1
			player_shoot(player_c_bullet_spec, angles)
			play_sound("player_shoots_special")
		else
			play_sound("player_missing_ammo")

		end
	end

	if btn(❎) and player.load == 0 then
		player_shoot(player_bullet_spec, {0.5})
		play_sound("player_shoots")
	end
end

function update_player_bullets()
	for bullet in all(player_bullets) do
		bullet.is += bullet.ds
		if bullet.is > #bullet.sprites then
			bullet.is = 1
		end

		bullet.x += bullet.sx
		bullet.y += bullet.sy

		if bullet.y < bullet.h * -1 then
			del(player_bullets, bullet)
		end

		if bullet.damage > 1 then
			for enemy_bullet in all(enemies_bullets) do
				if check_collision(bullet, enemy_bullet) then 
					player_score(1)
					local x = bullet.x + bullet.w / 2 + bullet.inset.x
					local y = bullet.y + bullet.h / 2 + bullet.inset.y
					fxs_float("+1", x, y, fxs.floats.colors)
					fxs_sparks(fxs.sparks.number, x, y, fxs.sparks.colors[1])
					del(enemies_bullets, enemy_bullet)
				end
			end
			for boss_bullet in all(boss_bullets) do
				if check_collision(bullet, boss_bullet) then 
					player_score(1)
					local x = bullet.x + bullet.w / 2 + bullet.inset.x
					local y = bullet.y + bullet.h / 2 + bullet.inset.y
					fxs_float("+1", x, y, fxs.floats.colors)
					del(boss_bullets, boss_bullet)
				end
			end
		end

		for enemy in all(enemies) do 
			if check_collision(bullet, enemy) then 
				enemy.hp -= bullet.damage
				del(player_bullets, bullet)

				local colors_shockwaves = fxs.shockwaves.colors
				local number_sparks, colors_sparks = fxs.sparks.number, fxs.sparks.colors
				if enemy.hp <= 0 then
					local x = enemy.x + enemy.w / 2 + enemy.inset.x
					local y = enemy.y + enemy.h / 2 + enemy.inset.y
					local y_bottom = enemy.y + enemy.h + enemy.inset.y
					local r = max(enemy.w, enemy.h)
					local r1, r_max = r, r * 2

					fxs_particles(fxs.particles.number, x, y, enemy.colors)
					fxs_shockwave(x, y, r1, colors_shockwaves[2])
					fxs_shockwave(x, y, r_max, colors_shockwaves[1])

					if enemy.mode == "attack" then
						player_score(enemy.points * 2)
						fxs_float("2x", x, y, fxs.floats.colors)
					else
						player_score(enemy.points)
					end
					del(enemies, enemy)
					if rnd() < pickup_spec.odds then
						add(pickups, new_pickup(x, y))
					end
					if #enemies == 0 and player.hp > 0 then
						new_wave(player.score.value)
						play_sound("clear_wave")
					end
					play_sound("player_defeats_enemy")
				else
					local x = enemy.x + enemy.inset.x + enemy.w / 2
					local y = enemy.y + enemy.inset.y + enemy.h * 3 / 4
					local r = max(enemy.w, enemy.h) / 2
					fxs_shockwave(x, y, r, colors_shockwaves[2])
					fxs_sparks(number_sparks, x, y, colors_sparks[1])
					
					enemy.flash = enemies_flash.max
					play_sound("player_bullet_hits")
				end
			end
		end
	end
end

function update_enemies()
	for enemy in all(enemies) do
		update_enemy(enemy)
	end

	if #enemies > 0 and player.hp > 0 then 
		timer += 1
		if timer % timer_cap == 0 then 
			timer = 0

			local candidates = {}
			for i = 1, #enemies do 
				if enemies[i].mode == "pause" then 
					local x, w, inset = enemies[i].x, enemies[i].w, enemies[i].inset
					local overlaps = false
					for candidate in all(candidates) do
						if not(x + w + inset.x < candidate.x + candidate.inset.x or x + inset.x > candidate.x + candidate.w + candidate.inset.x) then
							overlaps = true
							break
						end
					end
					if not overlaps then
						add(candidates, { i = i, x = x, w = w, inset = inset })
					end
				end
			end
			
			if #candidates > 0 then 
				local n = ceil(rnd() * 2)
				for i = 1, n do 
					local candidate = rnd(candidates)
					local enemy = enemies[candidate.i]
					if enemy.type == 1 then
						enemy.delay = enemies_delays.shake
						enemy.mode = "shake"
					else
						enemy.mode = "attack"
					end
				end
			end
		end
	end
end

function player_score(points)
	player.score.value += points
end

function update_enemy(enemy)
	enemy.is += enemy.ds
	if enemy.is > #enemy.sprites then
		enemy.is = 1
	end

	if enemy.flash > 0 then
		enemy.flash -= 1
	end

	if check_collision(player, enemy) and player.hp > 0 and shield.count == 0 then
		damage_player() 
		enemy.hp -= 1

		if enemy.hp <= 0 then
			fxs_particles(fxs.particles.number, enemy.x + enemy.w / 2 + enemy.inset.x, enemy.y + enemy.h / 2 + enemy.inset.y, enemy.colors)

			del(enemies, enemy)
			if #enemies == 0 and player.hp > 0 then
				new_wave(player.score.value)
				play_sound("clear_wave")
			end
		else
			enemy.flash = enemies_flash.max
		end
	end

	if enemy.mode == "spawn" then
		enemy.delay -= 1

		if enemy.delay <= 0 then
			enemy.delay = enemies_delays.default
			enemy.mode = "arrive"
		end
	elseif enemy.mode == "arrive" then
		local ease_ratio = (enemy.ys.pause - enemy.ys.spawn) / 8
		enemy.y += (enemy.ys.pause - enemy.y) / ease_ratio
		enemy.x += (enemy.xs.pause - enemy.x) / ease_ratio
		if enemy.ys.pause - enemy.y < 0.5 then
			enemy.y = enemy.ys.pause
			enemy.x = enemy.xs.pause
			enemy.mode = "pause"
		end
	elseif enemy.mode == "shake" then
		enemy.delay -= 1
		local shake = shakes.enemies
		local x = enemy.xs.pause
		enemy.x = enemy.delay % 2 == 0 and x - shake or x + shake
		if enemy.delay <= 0 then 
			enemy.x = x
			enemy.delay = enemies_delays.default
			enemy.mode = "pause"
			local odds = rnd()
			if odds < 0.2 then
				enemy.mode = "pause"
			elseif odds < 0.6 then
				enemy.mode = "attack"
			else
				enemy.mode = "shoot"
			end
		end
	elseif enemy.mode == "shoot" then
		local x = enemy.x + enemy.w / 2 + enemy.inset.x
		local y = enemy.y + enemy.h / 2 + enemy.inset.y
		if rnd() > 0.5 then 
			local px = player.x + player.w / 2 + player.inset.x + player.dx * player.speed
			local py = player.y + player.h / 2 + player.inset.y
			local angle = atan2(py - y, px - x)
			local bullet = new_bullet(enemies_bullet_spec, x, y, angle)
			add(enemies_bullets, bullet)
			play_sound("enemy_shoots")
		else
			local bullet = new_bullet(enemies_bullet_spec, x, y, 0)
			add(enemies_bullets, bullet)
			play_sound("enemy_shoots")
		end
		enemy.mode = "pause"
	elseif enemy.mode == "attack" then
		if enemy.type == 1 then
			local oscillations = 3 * 2
			enemy.y += enemy.speed
			enemy.x += sin(timer / (timer_cap / oscillations))
			if enemy.x < screen_size / 3 or enemy.x > screen_size * 2 / 3 then
				enemy.dx = enemy.x < player.x and 1 or -1
				enemy.x += enemy.dx * enemy.speed
			end
		elseif enemy.type == 2 then 
			local ease_ratio = (screen_size + enemy.h - enemy.ys.pause) / 12
			enemy.y += (screen_size + enemy.h - enemy.y) / ease_ratio
		elseif enemy.type == 3 then
			local y_stop = player.y - enemy.h
			if (y_stop - enemy.y < 0.5) then
				local dx = enemy.xs.pause < screen_size / 2 and -1 or 1
				enemy.x += dx * enemy.speed
			else
				local ease_ratio = (y_stop - enemy.ys.pause) / 6
				enemy.y += (y_stop - enemy.y) / ease_ratio
			end
		elseif enemy.type == 4 then
			enemy.y += enemy.speed
			if timer % frequencies.enemies.shoot_spread == 0 then
				local x = enemy.x + enemy.w / 2 + enemy.inset.x
				local y = enemy.y + enemy.h / 2 + enemy.inset.y
				local px = player.x + player.w / 2 + player.inset.x
				local py = player.y + player.h / 2 + player.inset.y
				local angle_player = atan2(py - y, px - x)
				local n = 6
				for i = 1, n do
					local angle =(1 / n * i + angle_player) % 1
					local bullet = new_bullet(enemies_bullet_spec, x, y, angle)
					add(enemies_bullets, bullet)
					play_sound("enemy_shoots")
				end
			end
		end
	end

	if enemy.y > screen_size or enemy.x < (enemy.w + enemy.inset.x) * -1 or enemy.x > screen_size then
		enemy.y = enemy.ys.spawn
		enemy.x = enemy.xs.spawn
		enemy.mode = "spawn"
		enemy.delay = enemies_delays.respawn
	end
end

function update_enemies_bullets()
	for bullet in all(enemies_bullets) do
		bullet.is += bullet.ds
		if bullet.is > #bullet.sprites then
			bullet.is = 1
		end

		bullet.x += bullet.sx
		bullet.y += bullet.sy

		if bullet.y < -bullet.h or bullet.y > screen_size or bullet.x < -bullet.w or bullet.x > screen_size then
			del(enemies_bullets, bullet)
		end

		if check_collision(bullet, player) and player.hp > 0 and shield.count == 0 then 
			del(enemies_bullets, bullet)
			damage_player(bullet.damage)
		end
	end 
end


function update_boss()
	boss.is += boss.ds
	boss.sprite = boss.sprites[flr(boss.is)]
	if boss.is > #boss.sprites then
		boss.is = 1
	end

	if boss.flash > 0 then
		boss.flash -= 1

		if boss.flash > boss_flash.max / 3 then
			boss.sprite = boss.sprite_hit
		end
	end

	if check_collision(boss, player) and player.hp > 0 and shield.count == 0 then
		damage_player()
	end

	for bullet in all(player_bullets) do
		if check_collision(bullet, boss) then
			del(player_bullets, bullet)
			if sub(boss.mode, 1, #"mission") == "mission" then
				boss.hp -= bullet.damage

				if boss.hp <= 0 then
					boss.timer = 0
					boss.mode = "explode"
					flash_screen(10)
					break
				else
					boss.flash = boss_flash.max
					local x = boss.x + boss.inset.x + boss.w / 2
					local y = boss.y + boss.inset.y + boss.h * 3 / 4
					local number_sparks, colors_sparks = fxs.sparks.number, fxs.sparks.colors
					fxs_sparks(number_sparks * 2, x, y, colors_sparks[1])
					play_sound("player_bullet_hits")
				end
			end
		end
	end

	if boss.mode == "spawn" then
		local ease_ratio = (boss.ys[2] - boss.ys[1]) / 4

		boss.y += (boss.ys[2] - boss.y) / ease_ratio
		if boss.ys[2] - boss.y < 0.5 then
			boss.y = boss.ys[2]
			boss.mode = "mission1"
			boss.dx = rnd() > 0.5 and 1 or -1
		end
	elseif boss.mode == "mission1" then
		boss.timer += 1
		boss.x += boss.dx * boss.speed

		if boss.x + boss.w > screen_size - spaces.boss[1] then
			boss.dx = -1
			boss.x = screen_size - spaces.boss[1] - boss.w
		elseif boss.x < spaces.boss[1] then 
			boss.dx = 1
			boss.x = spaces.boss[1]
		end

		if boss.timer >= boss.timer_cap and boss.dx == -1 then
			boss.timer = boss.timer % boss.timer_cap
			boss.mode = "mission2"
		elseif boss.timer % frequencies.boss.shoot_down == 0 then
			local x = boss.x + boss.w / 2 + boss.inset.x
			local y = boss.y + boss.h / 2 + boss.inset.y
			local bullet = new_bullet(boss_bullet_spec, x, y, 0)
			add(boss_bullets, bullet)
			play_sound("boss_shoots")
		end
	elseif boss.mode == "mission2" then
		boss.timer += 1
		if boss.timer % frequencies.boss.shoot_player == 0 then
			local x = boss.x + boss.w / 2 + boss.inset.x
			local y = boss.y + boss.h / 2 + boss.inset.y
			local px = player.x + player.w / 2 + player.inset.x + player.dx * player.speed
			local py = player.y + player.h / 2 + player.inset.y
			local angle = atan2(py - y, px - x)
			local bullet = new_bullet(boss_bullet_spec, x, y, angle)
			add(boss_bullets, bullet)
			play_sound("boss_shoots")
		end
		
		local inset_y = spaces.formation[2]
		local padding_x, padding_y = spaces.boss[1], spaces.boss[2]
		local x1 = padding_x
		local y1 = inset_y
		local x2 = screen_size - padding_x - boss.w
		local y2 = screen_size - padding_y - boss.h
		if boss.x > x1 and boss.y == y1 then
			boss.x = max(x1, boss.x - boss.speed)
		elseif boss.x == x1 and boss.y < y2 then
			boss.y = min(y2, boss.y + boss.speed)
		elseif boss.x < x2 and boss.y == y2 then
			boss.x = min(x2, boss.x + boss.speed)
		elseif boss.x == x2 and boss.y > y1 then
			boss.y = max(y1, boss.y - boss.speed)

			if boss.y == y1 then
				boss.timer = flr(boss.timer / 2)
				boss.mode = "mission3"
			end
		end
	elseif boss.mode == "mission3" then
		boss.timer += 1
		boss.x += boss.dx * boss.speed

		if boss.x + boss.w > screen_size - spaces.boss[1] then
			boss.dx = -1
			boss.x = screen_size - spaces.boss[1] - boss.w
		elseif boss.x < spaces.boss[1] then 
			boss.dx = 1
			boss.x = spaces.boss[1]
		end

		if boss.timer >= boss.timer_cap and boss.dx == 1 then
			boss.timer = boss.timer % boss.timer_cap
			boss.mode = "mission4"
		elseif boss.timer % frequencies.boss.shoot_spread == 0 then
			local spread_shot = spread_shot.boss
			local x = boss.x + boss.w / 2 + boss.inset.x
			local y = boss.y + boss.h / 2 + boss.inset.y
			for i = 1, spread_shot do
				local angle = (1 / spread_shot * i + time()) % 1
				local bullet = new_bullet(boss_bullet_spec, x, y, angle)
				add(boss_bullets, bullet)
				play_sound("boss_shoots")
			end
		end
	elseif boss.mode == "mission4" then
		boss.timer += 1
		
		local inset_y = spaces.formation[2]
		local padding_x, padding_y = spaces.boss[1], spaces.boss[2]
		local x1 = padding_x
		local y1 = inset_y
		local x2 = screen_size - padding_x - boss.w
		local y2 = screen_size - padding_y - boss.h

		if boss.timer % frequencies.boss.shoot_cardinal == 0 then
			local x = boss.x + boss.w / 2 + boss.inset.x
			local y = boss.y + boss.h / 2 + boss.inset.y
			local angle = 0
			if boss.x == x1 then
				angle = 0.75
			elseif boss.x == x2 then
				angle = 0.25
			elseif boss.y == y2 then
				angle = 0.5
			end
			local bullet = new_bullet(boss_bullet_spec, x, y, angle)
			add(boss_bullets, bullet)
			play_sound("boss_shoots")
		end

		if boss.x < x2 and boss.y == y1 then
			boss.x = min(x2, boss.x + boss.speed)
		elseif boss.x == x2 and boss.y < y2 then
			boss.y = min(y2, boss.y + boss.speed)
		elseif boss.x > x1 and boss.y == y2 then
			boss.x = max(x1, boss.x - boss.speed)
		elseif boss.x == x1 and boss.y > y1 then
			boss.y = max(y1, boss.y - boss.speed)
			if boss.y == y1 then
				boss.timer = 0
				boss.mode = "mission1"
			end
		end
	elseif boss.mode == "explode" then 
		boss.sprite = boss.sprite_hit
		boss.timer += 1
		if boss.timer < boss_explosion.cap[2] then
			local frequency = boss.timer < boss_explosion.cap[1] and boss_explosion.frequencies[1] or boss_explosion.frequencies[2]
			local shake = boss.timer < boss_explosion.cap[1] and boss_explosion.shakes[1] or boss_explosion.shakes[2]
			if boss.timer % frequency == 0 then
				shake_camera(shake)
				local colors_shockwaves = fxs.shockwaves.colors
				local number_sparks, colors_sparks = fxs.sparks.number, fxs.sparks.colors
				local number_particles = fxs.particles.number
				local colors_particles = boss.colors
				local w, h = boss.w, boss.y
				local x = boss.x + w / 2 + boss.inset.x
				local y = boss.y + h / 2 + boss.inset.y
				local ox = w * 0.9
				local oy = h * 0.5
				local r = min(w, h)
				fxs_shockwave(x + (rnd() - 0.5) * ox, y + (rnd() - 0.5) * oy, r, colors_shockwaves[1])
				fxs_sparks(number_sparks, x + (rnd() - 0.5) * ox, y + (rnd() - 0.5) * oy, colors_sparks[1])
				fxs_sparks(number_sparks, x + (rnd() - 0.5) * ox, y + (rnd() - 0.5) * oy, colors_sparks[1])
				fxs_particles(number_particles, x + (rnd() - 0.5) * ox, y + (rnd() - 0.5) * oy, colors_particles)
				fxs_particles(number_particles, x + (rnd() - 0.5) * ox, y + (rnd() - 0.5) * oy, colors_particles)
				play_sound("small_explosion")
			end
		elseif boss.timer == boss_explosion.cap[2] then
			shake_camera(boss_explosion.shakes[3])
			local colors_shockwaves = fxs.shockwaves.colors
			local number_particles = fxs.particles.number
			local colors_particles = boss.colors
			local w, h = boss.w, boss.y
			local x = boss.x + w / 2 + boss.inset.x
			local y = boss.y + h / 2 + boss.inset.y
			local ox = w / 2
			local oy = h
			local r = max(w, h)
			fxs_shockwave(x, y + oy / 2, r, colors_shockwaves[1])
			fxs_particles(number_particles * 4, x, y, colors_particles)
			fxs_particles(number_particles, x + ox, y + (rnd() - 0.5) * oy, colors_particles)
			fxs_particles(number_particles, x - ox, y + (rnd() - 0.5) * oy, colors_particles)
			boss.x = screen_size

			local points = boss.points
			player_score(points)
			fxs_float("kaboom", x, y, fxs.floats.colors)
			play_sound("big_explosion")
		elseif fxs_none() then
			boss = nil
			new_wave(player.score.value)
			play_sound("clear_wave")
		end
	end
end

function update_boss_bullets()
	for bullet in all(boss_bullets) do
		bullet.is += bullet.ds
		if bullet.is > #bullet.sprites then
			bullet.is = 1
		end

		bullet.x += bullet.sx
		bullet.y += bullet.sy

		if bullet.y < -bullet.h or bullet.y > screen_size or bullet.x < -bullet.w or bullet.x > screen_size then
			del(boss_bullets, bullet)
		end

		if check_collision(bullet, player) and player.hp > 0 and shield.count == 0 then 
			del(boss_bullets, bullet)
			damage_player(bullet.damage)
		end
	end 
end

function update_pickups()
	for pickup in all(pickups) do 
		pickup.x += pickup.sx
		pickup.y += pickup.sy

		pickup.color = timer % pickup.color_skip == 0 and pickup.colors[2] or pickup.colors[1]
		if check_collision(player, pickup) and player.hp > 0 then
			player.pickups.value += 1
			local w, h = pickup.w, pickup.h
			local x = pickup.x + w / 2 + pickup.inset.x
			local y = pickup.y + h / 2 + pickup.inset.y
			local r = max(w, h)
			fxs_shockwave(x, y, r, pickup.colors[2])

			if player.pickups.value >= player.pickups.max then
				play_sound("player_pickup_bonus")
				player.pickups.value -= player.pickups.max
				if player.hp == player.max_hps[2] then
					local points = player.pickups.points
					fxs_float("bonus!", x, y, fxs.floats.colors)
					player.score.value += points
				else
					fxs_float("1up!", x, y, fxs.floats.colors)
					player.hp += 1
					if player.hp > player.max_hp then
						player.max_hp = player.hp
					end
				end
			else
				play_sound("player_pickup_regular")
			end

			del(pickups, pickup)
		end
		if pickup.y > screen_size then
			del(pickups, pickup)
		end
	end
end
-->8
-- draw functions
function format_score(value)
	return value == 0 and "0" or value .. "000"
end

function draw_hud()
	print("score:" .. format_score(player.score.value), player.score.x, player.score.y, player.score.color)
	for i = 1, player.max_hp do
		local x = player.lives.xs[i]
		local j = player.hp >= i and 2 or 1
		spr(player.lives.sprites[j], x, player.lives.y)
	end
	print(player.pickups.value, player.pickups.text.x, player.pickups.text.y, player.pickups.text.color)
	spr(player.pickups.sprite.n, player.pickups.sprite.x, player.pickups.sprite.y)
end

function draw_pickups()
	for pickup in all(pickups) do
		for i = 1, 15 do 
			pal(i, pickup.color)
		end
		for offset in all({{1, 0}, {-1, 0}, {0, -1}, {0, 1}}) do
			spr(pickup.sprite, pickup.x + offset[1], pickup.y + offset[2])
		end
		pal()
		spr(pickup.sprite, pickup.x, pickup.y)
	end
end

function draw_bullets()
	for bullet in all(enemies_bullets) do
		spr(bullet.sprites[flr(bullet.is)], bullet.x, bullet.y)
	end

	for bullet in all(boss_bullets) do
		spr(bullet.sprites[flr(bullet.is)], bullet.x, bullet.y)
	end

	for bullet in all(player_bullets) do
		spr(bullet.sprites[flr(bullet.is)], bullet.x, bullet.y)
	end
end

function draw_enemies()
	for enemy in all(enemies) do
		if enemy.flash % enemies_flash.skip == 1 then
			for i = 1, 15 do 
				pal(i, enemies_flash.color)
			end
		end
		spr(enemy.sprites[flr(enemy.is)], enemy.x, enemy.y, enemy.sprw, enemy.sprh)
		pal()
	end
end

function draw_boss()
	if boss.flash % boss_flash.skip == 1 then
		for i = 1, 15 do 
			pal(i, boss_flash.color)
		end
	end
	spr(boss.sprite, boss.x, boss.y, boss.sprw, boss.sprh)
	pal()
end

function draw_player()
	spr(flame.sprites[flame.is], player.x, player.y + player.h)
	spr(player.sprite, player.x, player.y)
	circfill(player.x + player.w / 2, player.y, muzzle.r, muzzle.color)
	circfill(player.x + player.w / 2 - 1, player.y, muzzle.r, muzzle.color)
	circfill(player.x + player.w / 2, player.y + player.h / 2, shield.r, shield.color)
end
-->8
--[[ starfield
_init(number: +number, colors: {c1, c2}, speeds: {s1, s2})
]]
local screen_size = 128
local star_size = 0.5 
local starfield = {}

function starfield_init(number, colors, speeds)
	starfield = {}
	
	local n = number or 50
	local cs = colors or { 7, 5 }
	local ss = colors or { 1, 0.5 }

	for i = 1, 2 do
		local stars = {}
		for i = 1, n do 
			local x = flr(rnd(screen_size))
			local y = flr(rnd(screen_size))
			add(stars, { x = x, y = y })
			add(stars, { x = x, y = y - screen_size })
		end
		add(starfield, {
			r = star_size,
			color = cs[i],
			speed = ss[i],
			y = 0,
			stars = stars
		})
	end
end

function starfield_update()
	for field in all(starfield) do 
		field.y = (field.y + field.speed) % screen_size
	end
end

function starfield_draw()
	for field in all(starfield) do 
		for star in all(field.stars) do 
			circfill(star.x, star.y + field.y, field.r, field.color)
		end
	end
end
-->8
--[[ fxs
_particles(n: +number, x: +number, y: +number, colors: { number })
_shockwave(x: +number, y: +number, r: +number, color: number)
_sparks(n: +number, x: +number, y: +number, color: number)
_float(text: string, x: +number, y: +number, colors: { number, number })
]]
local particles = {}
local particle_spec = { times = { 14, 20 }, speeds = { 3, 6 }, frictions = { 0.6, 0.8 }, radii = { 1, 6 }, colors = { 7, 10, 10, 9, 8, 3, 1 } }
local shockwaves = {}
local shockwave_spec = { color = 7, expansion = 2.2, expansion_rate = 0.35 }
local sparks = {}
local spark_spec = { times = { 6, 14 }, speeds = { 0.4, 1 }, r = 0.5, color = 7 }
local floats = {}
local float_spec = { time = 22, skip = 4, speed = 0.5, dy = -1, colors = { 7, 10 } }

function fxs_particles(n, x, y, colors)
	local times, speeds, frictions, radii = particle_spec.times, particle_spec.speeds, particle_spec.frictions, particle_spec.radii, particle_spec.colors

	for i = 1, n do 
		local angle = rnd()
		local speed = speeds[1] + ceil((rnd() * (speeds[2] - speeds[1])) * 10) / 10
		local sx = cos(angle) * speed
		local sy = sin(angle) * speed
		local time_max = times[1] + ceil(rnd() * (times[2] - times[1]))
		local radii = {radii[1], radii[1] + ceil(rnd() * (radii[2] - radii[1]))}
		local friction = frictions[1] + ceil((rnd() * (frictions[2] - frictions[1])) * 10) / 10
		local particle = { time_max = time_max, time = 0, x = x, y = y, sx = sx, sy = sy, friction = friction, r = radii[1], radii = radii, colors = colors or particle_spec.colors, ci = 1 }
		add(particles, particle)
	end
end

function fxs_shockwave(x, y, r, color)
	local expansion, expansion_rate = shockwave_spec.expansion, shockwave_spec.expansion_rate
	local r_max = r * expansion
	local shockwave = { x = x, y = y, r = r, r_max = r_max, dr = (r_max - r) ^ expansion_rate, color = color or shockwave_spec.color }
	add(shockwaves, shockwave)
end

function fxs_sparks(n, x, y, color)
	local times, speeds = spark_spec.times, spark_spec.speeds

	for i = 1, n do 
		local angle = rnd()
		local speed = speeds[1] + ceil((rnd() * (speeds[2] - speeds[1])) * 10) / 10
		local sx = cos(angle) * speed
		local sy = sin(angle) * speed
		local time_max = times[1] + ceil(rnd() * (times[2] - times[1]))
		local spark = { time_max = time_max, time = 0, x = x, y = y, sx = sx, sy = sy, r = spark_spec.r, color = color or spark_spec.color }
		add(sparks, spark)
	end
end

function fxs_float(text, x, y, colors)
	local char_width = 4
	local time_max, skip, speed, dy = float_spec.time, float_spec.skip, float_spec.speed, float_spec.dy

	local float = { time_max = time_max, time = 0, skip = skip, x = x - (char_width * #text) / 2, y = y, sy = dy * speed, text = text, colors = colors or float_spec.dy.colors, ci = 1 }
	add(floats, float)
end

function fxs_init()
	particles = {}
	shockwaves = {}
	sparks = {}
	floats = {}
end

function fxs_update()
	for particle in all(particles) do
		particle.time += 1
		
		particle.x += particle.sx
		particle.y += particle.sy
		particle.sx *= particle.friction
		particle.sy *= particle.friction

		local t = particle.time / particle.time_max
		local r1, r2 = particle.radii[1], particle.radii[2]
		particle.r = r1 + (1 - t) * (r2 - r1)
		particle.ci = ceil(t * #particle.colors)

		if particle.time >= particle.time_max then
			del(particles, particle)
		end
	end

	for shockwave in all(shockwaves) do
		shockwave.r += shockwave.dr

		if shockwave.r >= shockwave.r_max then
			del(shockwaves, shockwave)
		end
	end

	for spark in all(sparks) do
		spark.time += 1
		
		spark.x += spark.sx
		spark.y += spark.sy

		if spark.time >= spark.time_max then
			del(sparks, spark)
		end
	end

	for float in all(floats) do 
		float.time += 1
		float.y += float.sy
		float.ci = float.time % float.skip == 0 and 1 or 2

		if float.time >= float.time_max then
			del(floats, float)
		end
	end
end

function fxs_draw()
	for particle in all(particles) do
		circfill(particle.x, particle.y, particle.r, particle.colors[particle.ci])
	end
	for shockwave in all(shockwaves) do
		circ(shockwave.x, shockwave.y, shockwave.r, shockwave.color)
	end
	for spark in all(sparks) do
		circ(spark.x, spark.y, spark.r, spark.color)
	end
	for float in all(floats) do
		print(float.text, float.x, float.y, float.colors[float.ci])
	end
end

function fxs_none()
	return #particles == 0 and #shockwaves == 0 and #sparks == 0 and #floats == 0
end
-->8
--[[ screen_step
_init(text_title: string, text_subtitle: string, colors: { {number}, {number} })
]]
local screen_size = 128
local char_width = 4
local char_height = 6
local line_height = 2

function screen_step_init(text_title, text_subtitle, colors)
	title = {}
	subtitle = {}
	title.text = text_title or "solid title\nwith possible subtitle"
	subtitle.text = text_subtitle or "possibly fading instruction"
	local cs = colors or { { 7, 6 }, { 0, 1, 6, 6, 7, 7, 7, 7, 6, 6, 1, 0 } }
	subtitle.colors = cs[2]

	title.lines = {}
	local title_lines = split(title.text, "\n")
	local y_start = screen_size / 2 - #title_lines * (char_height + line_height) - char_height
	local cs1 = cs[1]
	for i = 1, #title_lines do
		local text = title_lines[i]
		local x = flr(screen_size / 2  - #text / 2 * char_width)
		local y = y_start + (char_height + line_height) * i
		local color = cs1[(i - 1) % #cs1 + 1]
		add(title.lines, { text = text, x = x, y = y, color = color })
	end

	subtitle.x = flr(screen_size / 2 - #subtitle.text / 2 * char_width)
	subtitle.y = screen_size - char_height * 2
	subtitle.color_i = 1
	subtitle.color_d = 0.5
end

function screen_step_update()
	subtitle.color_i += subtitle.color_d
	if subtitle.color_i > #subtitle.colors then 
		subtitle.color_i = 1
	end
end

function screen_step_draw()
	for line in all(title.lines) do 
		print(line.text, line.x, line.y, line.color)
	end
	print(subtitle.text, subtitle.x, subtitle.y, subtitle.colors[flr(subtitle.color_i)])
end
-->8
--[[ screen_through
_init(text: string, callback: function, delay: +number, colors: {number})
]]
local screen_size = 128
local char_width = 4
local char_height = 6
local title = {}

function screen_through_init(text, callback, delay, colors)
	title = {}
	title.text = text or "fading title"
	title.callback = callback or function() end
	title.delay = delay or 3
	title.colors = colors or { 0, 1, 6, 6, 7, 7, 7, 7, 6, 6, 1, 0 }
	title.colors_i = 1

	title.x = flr(screen_size / 2 - #title.text / 2 * char_width)
	title.y = flr(screen_size / 2 - char_height)
	title.start = time()
	title.finish = time() + title.delay
	title.update = true
end

function screen_through_update()
	if title.update then
		title.start = time()
		title.color_i = ceil((1 - (title.finish - title.start) % 1) * #title.colors)
		if title.start >= title.finish then 
			title.callback()
			title.update = false
		end
	end
end

function screen_through_draw()
	print(title.text, title.x, title.y, title.colors[title.color_i])
end
__gfx__
00000000000770000007700000077000000000000000000000000000000000000000000000000000033003300330033003300330000000000000000000000000
0000000000288200002882000028820000000000000000000000000000000000000000000000000033b33b3333b33b3333b33b33000000000880088008800880
0070070000288200002882000028820000000000000000000000149aa941000000000122221000003bbbbbb33bbbbbb33bbbbbb3000000008008800888888888
00077000029889200298892002988920000000000000000000019777aa921000000029aaaa9200003b7717b33b7717b33b7717b3000000008000000888888888
000770002987b89229b7889229887b9200000000000000000d09a77a949920d00d0497777aa920d00b7117b00b7117b00b7117b0000000000800008008888880
0070070028855882285588822888558200000000000000000619aaa9422441600619a77944294160003773000037730000377300000000000080080000888800
00000000028dd82002dd88200288dd20000000000000000007149a922249417007149a9442244170030330300303303003033030000000000008800000088000
00000000002992000029920000299200000000000000000007d249aaa9942d7007d249aa99442d70030000303000000303300330000000000000000000000000
0099990000c77c00000770000cc77cc00000000000000000067d22444422d760077d22244222d7700022220000222200002222000022220000000000000bbbb0
09aaaa9000c77c000007700000cccc0000000000000000000d666224422666d00d776249942677d002eeee2002eeee2002eeee2002eeee2000000000000b0bb0
9aa77aa9000cc00000077000000000000000000000000000066d51499415d66001d1529749251d102ee77ee22ee77ee22eeeeee22ee77ee20000000000b00b00
9a7777a900000000000cc0000000000000000000000000000041519749151400066151944a1516602eeeeee22ee77ee22ee77ee22ee77ee20000000000b00880
9a7777a9000000000000000000000000000000000000000000a001944a100a0000400149a41004002eeeeee22eeeeee22eeeeee22eeeeee20000000008808788
9aa77aa9000000000000000000000000000000000000000000000049a400090000a0000000000a00222222222222222222222222222222220000000087888888
09aaaa90000000000000000000000000000000000000000000000000000000000000000000000900202020200202020220202020020202020000000088880880
00999900000000000000000000000000000000000000000000000000000000000000000000000000200020000200020000200020000200020000000008800000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000d89d000018910000189100001981000000000000000000
009999000009900000999900000000000000000000000000000000000000000000000000000000000d5115d00055151000111100015155000000000000000000
09977990009779000997799000000000000000000000000000000000000000000000000000000000d51aa15d01d1a15000155100051a1d100000000000000000
09a77a900097790009a77a9000000000000000000000000000000000000000000000000000000000d51aa15d0d51a15000d55d00051a15d00000000000000000
09a77a900097790009a77a9000000000000000000000000000000000000000000000000000000000d511115d0d55055000dddd00055055d00000000000000000
099aa990009aa900099aa99000000000000000000000000000000000000000000000000000000000665005660665056000666600065056600000000000000000
009aa900009aa900009aa90000000000000000000000000000000000000000000000000000000000066006600066066000066000066066000000000000000000
00099000000990000009900000000000000000000000000000000000000000000000000000000000006006000006060000066000006060000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000cccccc00c0000c000000000000000000000000000000000
00077000000ee000000ee00000000000000000000000000000000000000000000000000000000000c0c0c0ccc000000c00000000000000000000000000000000
007cc70000e88e0000e22e0000000000000000000000000000000000000000000000000000000000c022220ccc2c2c0cc022220c002222000000000000000000
07c77c700e87e8e00e2e82e000000000000000000000000000000000000000000000000000000000cc2cac0cc02aa20cc0cac2ccc02aa20c0000000000000000
07c77c700e8ee8e00e2882e000000000000000000000000000000000000000000000000000000000c02aa20cc0cac2ccc02aa20ccc2cac0c0000000000000000
007cc70000e88e0000e22e000000000000000000000000000000000000000000000000000000000000222200c022220ccc2c2c0cc022220c0000000000000000
00077000000ee000000ee000000000000000000000000000000000000000000000000000000000000000000000000000c000000cc0c0c0cc0000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c0000c00cccccc00000000000000000
00000ee00000bbbbbbbb00000ee0000000000ee00000bbbbbbbb00000ee0000000000ee00000bbbbbbbb00000ee0000000000ee00000bbbbbbbb00000ee00000
ee0008e7e1bbbbbaabbbbb1e7e8000eeee0008e7e1bbbbbaabbbbb1e7e8000eeee0008e7e1bbbbbaabbbbb1e7e8000eeee0008e7e1bbbbbaabbbbb1e7e8000ee
e7e0138873bbbaa77aabbb3788310e7ee7e0138873bbbaa77aabbb3788310e7ee7e0138873bbbaa77aabbb3788310e7ee7e0138873bbbaa77aabbb3788310e7e
8e783b333bbabaa77aababb333b387e88e783b333bbabaa77aababb333b387e88e783b333bbabaa77aababb333b387e88e783b333bbabaa77aababb333b387e8
08e813bbbbbbbba77abbbbbbbb318e8008e813bbbbbbbbbaabbbbbbbbb318e8008e813bbbbbbbbbaabbbbbbbbb318e8008e813bbbbbbbbbaabbbbbbbbb318e80
088811bbbbbbbbbaabbbbbbbbb11888008881133b33bbbbbbbbbb33b3311888008881133b33bbbbbbbbbb33b3311888008881133b33bbbbbbbbbb33b33118880
0011133bbbbb33bbbb33bbbbb331110000113b11bbb3333333333bbb11b3110000113b11bbb3333333333bbb11b3110000113b11bbb3333333333bbb11b31100
00bb113bbabbb33bb33bbbabb311bb0000bb13bb13bbb333333bbb31bb31bb0000bb13bb13bbb333333bbb31bb31bb0000bb13bb13bbb333333bbb31bb31bb00
bb333113bbabbbbbbbbbbabb311333bbbb3331333333bba77abb3333331333bbbb3331333333bba77abb3333331333bbbb3331333333bba77abb3333331333bb
bbbb31333bbaa7bbbb7aabb33313bbbbb7713ee6633333bbbb3333366ee3177bb7713ee6633333bbbb3333366ee3177bb7713ee6633333bbbb3333366ee3177b
3b333313333bbb7777bbb333313333b337113eefff663333333366fffee3117337113eefff663333333366fffee3117337113eefff663333333366fffee31173
c333333bb33333bbbb33333bb333333cc3773efff77f17711111f77fffe3773cc3773efff77f17711111f77fffe3773cc3773efff77f17711111f77fffe3773c
0c3bb3b3bbb3333333333bbb3b3bb3c00c3b3eff777717711c717777ffe3b3c00c3b3eff777717711c717777ffe3b3c00c3b3eff777717711c717777ffe3b3c0
00c1bb3b33bbbb3333bbbb33b3bb1c0000c1b3ef7777711cc7177777fe3b1c0000c1b3ef7777711cc7177777fe3b1c0000c1b3ef7777711cc7177777fe3b1c00
00013bb3bb333bbbbbb333bb3bb3100000013b3eff777711117777ffe3b3100000013b3eff777711117777ffe3b3100000013b3eff777711117777ffe3b31000
0331c3bb33aaa333333aaa33bb3c13300331c3b3eef7777777777fee3b3c13300031c3b3eef7777777777fee3b3c13000031c3b3eef7777777777fee3b3c1300
3bb31c3bbb333a7777a333bbb3c13bb33bb31c3b33eee777777eee33b3c13bb303b31c3b33eee777777eee33b3c13b30003b1c3b33eee777777eee33b3c1b300
3ccc13c3bbbbb333333bbbbb3c31ccc33ccc13c3bb333eeeeee333bb3c31ccc33bcc13c3bb333eeeeee333bb3c313cb303bc13c3bb333eeeeee333bb3c31cb30
00003b3c33bbbba77abbbb33c3b3000000003b3c33bbb333333bbb33c3b300003c003b3c33bbb333333bbb33c3b300cc03c0333c33bbb333333bbb33c3330c30
0003b3ccc333bbbbbbbb333ccc3b30000003b3ccc333bba77abb333ccc3b300000003b3cc333bba77abb333cc3b3000000003b3cc333bba77abb333cc3b30000
00033c003bc33bbbbbb33cb300c3300000033c003bc33bbbbbb33cb300c33000000033c03bc33bbbbbb33cb30c33000000003bc03bc33bbbbbb33cb30cb30000
0003c0003b3c3cb22bc3c3b3000c30000003c0003b3c3cb22bc3c3b3000c300000003c003b3c3cb22bc3c3b300c30000000003c0c3bc3cb22bc3cb3c0c300000
0000000033c0cc2112cc0c33000000000000000033c0cc2112cc0c330000000000000000c330cc2112cc033c00000000000000000c30cc2112cc03c000000000
00000000cc0000c33c0000cc0000000000000000cc0000c33c0000cc00000000000000000cc000c33c000cc0000000000000000000cc00c33c00cc0000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000ee0000003300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
007bb70000e33e000038830000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07b78b700e37e3e0038be83000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07b88b700e3ee3e0038ee83000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
007bb70000e33e000038830000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000ee0000003300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000888888888888888888888888888888888888888888888888888800000000000000000000000000000000000000
00000000000000000000000000000000000008888888888888888888888888888888888888888888888888888880000000000000000000000000000000000000
00000000000000000000000000000000000088888777888888888888888888888888888888888888888888888888000000000000000000000000000000000000
00000000000000000000000000000000000088887787787888878777778777788777788788878888888777788888000000000000000000000000000000000000
00000000000000000000000000000000000088877888787888878788888788878788878788878888887787778888000000000000000000000000000000000000
00000000000000000000000000000000000088878888887788778778888778878778878778778888877877777888000000000000000000000000000000000000
00000000000000000000000000000000000088878888887777778777788777788777788877788878877777777888000000000000000000000000000000000000
00000000000000000000000000000000000088877888787788778788888788778788778887888888877777777888000000000000000000000000000000000000
00000000000000000000000000000000000088887787787888878778888788878788878887888888887777778888000000000000000000000000000000000000
00000000000000000000000000000000000088888777887888878777778788878788878887888888888777788888000000000000000000000000000000000000
00000000000000000000000000000000000008888888888888888888888888888888888888888888888888888880000000000000000000000000000000000000
00000000000000000000000000000000000000888888888888888888888888888888888888888888888888888800000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000099900000990909099909090999000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000090900009000909099909090909000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000099900009990999090909090999000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000090900000090909090909090900000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000090a0000aa00a0a0a0a00aa0900000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000a0000000000000000000000a00000000000000000000000000000000000000000000000000000
__sfx__
000100003352033520305202b52027520245201f5201b520185201652013520115200f5200d520030200752007520055200552003520035200051000510005100000000000000000000000000000000000000000
910200000c31027310243000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300
910200003735007350335501d3300c320075200732007320053100335003310000000000000000003200000000000003300000000000003200000000000003200000000000000000000000000000000000000000
480200001835200000133420a32207322073200735007300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00020000226302b62024630226301d63018620136200c620076100361000610006000560003600006000060000000000000000000000000000000000000000000000000000000000000000000000000000000000
000900001805617066100662006622036290563103630006000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000800000c0561106613076180761d05622046240372e0372e0473300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4a020000276402b6602b6602e6602e660336602e6602e6602967027660226601f6601f660116501865016640076401364007640116400a6400764007630056300563003620036200062000610006100061000610
000300000744007420074200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000100000c1200a1400a1601116013140111400010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100
020400003a660276403766024620336602966030660246502b65029650276502465024650226401f6401f6401b6401b640186401664013630116300f6300c6200a62007620076200562003620036200061000610
00050000205401d540205401d540205401d540205401d54022540225502255022550005000050000500005000050025534225302553022530255301d530255302253025531275322753027530275322753027530
0002000039562375523555234552325522f5522d5522a55228552265522455222552215521f5421d5421c5421a54217542155421454212542115320f5320e5220c5220b512095120751206512055120351201512
080a0000000000000000000000001b030130001b0201d0201e0302003020040200400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000e00001e050000001e0501d0501b0501a0601a0621a062000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000100003350033500305002b50027500245001f5001b500185001650013500115000f5000d500030000750007500055000550003500035000050000500005000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0004000039562375523555234552325522f5522d5522a55228552265522455222552215521f5421d5421c5421a54217542155421454212542115320f5320e5220c5220b512095120751206512055120351201512
000c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
