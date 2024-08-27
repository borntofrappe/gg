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