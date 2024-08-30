-- game_init(game_enemies)
local clear_offset = 3

local player = {
  sprite = 1,
  state = "",
  max_hp = 2,
  hp = 2,
  x = 0,
  y = 0,
  width = 4,
  height = 4,
  dx = 0,
  dy = 0,
  speeds = { walk = 3, fight = 2, continue = 3 },
}

local sword = {
  sprite = 17,
  x = 0,
  y = 0,
  width = 5,
  height = 5,
  inset = { x = 3, y = 1 }
}

local hearts = {
  sprites = { 49, 50 },
  y = 2,
  size = 5,
}

local base_enemies = { 
  { 
    max_hp = 1, 
    hp = 1, 
    threshold = 8, 
    width = 8, 
    height = 5,
    speed = 1,
    sprites = { 18, 19 }, 
    sprite_defeat = 20,
    sd = 0.2,
    spr_width = 1, 
    spr_height = 1
  } 
}

local enemies = {}

local sounds = {
  pickup_sword = 0,
  use_sword = 1,
  clear_room = 2,
  cross_threshold = 3,
  suffer_hit = 4,
  suffer_defeat = 5
}

local function check_collision(box1, box2)
  if box1.x + box1.width < box2.x or box1.x > box2.x + box2.width or box1.y + box1.height < box2.y or box1.y > box2.y + box2.height then 
    return false
  end
  return true
end

local function clear_collision(box1, box2)
  local is_sideway = box1.x + box1.width < box2.x + 1 or box1.x > box2.x + box2.width - 1
  if is_sideway then 
    local d = box1.x < box2.x and -1 or 1
    box1.x = mid(edge_left, box1.x + clear_offset * d, edge_right - box1.width)
    box2.x = mid(edge_left, box2.x + clear_offset * d * -1, edge_right - box2.width)
    box1.dx = d
    box2.dx = d * -1
  else
    local d = box1.y < box2.y and -1 or 1
    box1.y = mid(edge_top, box1.y + clear_offset * d, edge_bottom - box1.height)
    box2.y = mid(edge_top, box2.y + clear_offset * d * -1, edge_bottom - box2.height)
    box1.dy = d
    box2.dy = d * -1
  end
end

local function rnd_btw(min, max)
  return min + flr(rnd() * (max - min + 1))
end

function game_init(game_enemies)
  player.state = "walk"
  player.hp = player.max_hp
  player.dx = 0
  player.dy = 0

  player.x = rnd_btw(edge_left, edge_right - player.width)
  player.y = rnd_btw(edge_top, edge_bottom - player.height)
  
  repeat
    sword.x = rnd_btw(edge_left, edge_right - sword.width)
    sword.y = rnd_btw(edge_top, edge_bottom - sword.height)
  until not check_collision(player, sword)

  enemies = {}
  local start_enemies = game_enemies or base_enemies

  local box_player = { x = player.x - sprite_size, y = player.y - sprite_size, width = player.width + sprite_size * 2, height = player.height + sprite_size * 2 }
  for start_enemy in all(start_enemies) do
    local width, height = start_enemy.width, start_enemy.height, start_enemy.spr_width, start_enemy.spr_height

    local x, y
    local box_enemy = {}
    repeat
      x = rnd_btw(edge_left, edge_right - width)
      y = rnd_btw(edge_top, edge_bottom - height)
      box_enemy = { x = x, y = y, width = width, height = height }
    until not check_collision(box_player, box_enemy) and not check_collision(sword, box_enemy)
    
    local dx = flr(rnd() * 3) - 1
    local dy = flr(rnd() * 3) - 1

    local sprites = {}
    for sprite in all(start_enemy.sprites) do 
      add(sprites, sprite)
    end

    local max_hp, threshold, speed, sprite_defeat, sd, spr_width, spr_height = start_enemy.max_hp, start_enemy.threshold, start_enemy.speed, start_enemy.sprite_defeat, start_enemy.sd, start_enemy.spr_width, start_enemy.spr_height
    local enemy = { 
      max_hp = max_hp, 
      hp = max_hp, 
      count = 0, 
      threshold = threshold, 
      x = x,
      y = y,
      width = width,
      height = height,
      dx = dx,
      dy = dy,
      speed = speed, 
      sprites = sprites, 
      sprite_defeat = sprite_defeat, 
      si = 1,
      sd = sd,
      spr_width = spr_width, 
      spr_height = spr_height
    }
    add(enemies, enemy)
  end
end

function game_update()
  if btn(0) then
    player.dx = -1
  elseif btn(1) then
    player.dx = 1
  else
    player.dx = 0
  end

  if btn(2) then
    player.dy = -1
  elseif btn(3) then
    player.dy = 1
  else
    player.dy = 0
  end

  player.x += player.dx * player.speeds[player.state]
  player.y += player.dy * player.speeds[player.state]
  player.x = mid(edge_left, player.x, edge_right - player.width)
  player.y = mid(edge_top, player.y, edge_bottom - player.height)

  if player.state == "walk" then
    for enemy in all(enemies) do
      if check_collision(player, enemy) and enemy.hp > 0 then
        sfx(sounds.suffer_hit)
        player.hp -= 1
        if player.hp == 0 then
          sfx(sounds.suffer_defeat)
          lose_game()
        end

        clear_collision(player, enemy)
        break
      end
    end

    if check_collision(player, sword) then
      sfx(sounds.pickup_sword)
      player.state = "fight"
    end
  end

  if player.state == "fight" then 
    sword.x = player.x + sword.inset.x
    sword.y = player.y + sword.inset.y

    for enemy in all(enemies) do
      if check_collision(sword, enemy) and enemy.hp > 0 then
        sfx(sounds.use_sword)
        clear_collision(player, enemy)
        sword.x = min(player.x + player.width + 1, edge_right - sword.width)

        player.state = "walk"

        enemy.hp -= 1
        if enemy.hp == 0 then
          for i = 1, #enemy.sprites do 
            enemy.sprites[i] = enemy.sprite_defeat
          end
        end

        local continue = true
        for enemy in all(enemies) do
          if enemy.hp > 0 then
            continue = false
            break
          end
        end

        if continue then
          sfx(sounds.clear_room)
          player.state = "continue"
          continue_game()
        end

        break
      end
    end
  end

  if player.state == "continue" then
    local column = flr((player.x + player.width / 2) / sprite_size)
    local row = flr((player.y - 1) / sprite_size)
    if fget(mget(column, row)) == flag_continue then
      sfx(sounds.cross_threshold)
      player.state = ""
      level_up()
    end
  end

  for enemy in all(enemies) do
    if enemy.hp > 0 then 
      enemy.si = (enemy.si + enemy.sd) % #enemy.sprites

      enemy.count = enemy.count + 1
      if enemy.count >= enemy.threshold then
        enemy.count = enemy.count % enemy.threshold
        local dx = flr(rnd() * 3) - 1
        local dy = flr(rnd() * 3) - 1
        enemy.dx = dx
        enemy.dy = dy
      end
    
      enemy.x += enemy.dx * enemy.speed
      enemy.y += enemy.dy * enemy.speed
      enemy.x = mid(edge_left, enemy.x, edge_right - enemy.width)
      enemy.y = mid(edge_top, enemy.y, edge_bottom - enemy.height)
    end
  end
end

function game_draw()
  spr(player.sprite, player.x, player.y)
  spr(sword.sprite, sword.x, sword.y)

  for i = 1, player.max_hp do
    local sprite = player.hp >= i and hearts.sprites[1] or hearts.sprites[2]
    local x = edge_left + (i - 1) * (hearts.size + 1)
    spr(sprite, x, hearts.y)
  end

  for j = 1, #enemies do 
    local enemy = enemies[j]
    spr(enemy.sprites[flr(enemy.si) + 1], enemy.x, enemy.y, enemy.spr_width, enemy.spr_height)

    for i = 1, enemy.max_hp do
      local sprite = enemy.hp >= i and hearts.sprites[1] or hearts.sprites[2]
      local x = edge_right - hearts.size - (i - 1) * (hearts.size + 1) - (j - 1) * hearts.size * 2
      spr(sprite, x, hearts.y)
    end
  end
end