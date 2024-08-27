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