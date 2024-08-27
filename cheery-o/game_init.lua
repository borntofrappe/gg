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