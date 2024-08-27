-- update functions
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