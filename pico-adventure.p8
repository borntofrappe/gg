pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
screen_size = 128
sprite_size = 8
flag_continue = 1

edge_top = sprite_size * 2
edge_left = sprite_size 
edge_right = screen_size - sprite_size 
edge_bottom = screen_size - sprite_size

local state = nil
local level = nil
local levels = {
  {
    title = "pico adventure",
    instruction = "press ❎ to play",
    enemies = {
      { 
        max_hp = 1, 
        threshold = 12, 
        width = 5, 
        height = 5,
        speed = 1,
        sprites = { 2, 3 }, 
        sprite_defeat = 4,
        sd = 0.2,
        spr_width = 1, 
        spr_height = 1
      },
    }
  },
  {
    title = "one down",
    instruction = "press ❎ to continue",
    enemies = {
      { 
        max_hp = 1, 
        threshold = 8, 
        width = 8, 
        height = 5,
        speed = 1,
        sprites = { 18, 19 }, 
        sprite_defeat = 20,
        sd = 0.2,
        spr_width = 1, 
        spr_height = 1
      },
      { 
        max_hp = 1, 
        threshold = 10, 
        width = 8, 
        height = 5,
        speed = 1,
        sprites = { 19, 18 }, 
        sprite_defeat = 20,
        sd = 0.2,
        spr_width = 1, 
        spr_height = 1
      }
    }
  },
  {
    title = "two to go",
    instruction = "press ❎ to continue",
    enemies = {
      { 
        max_hp = 3, 
        threshold = 10, 
        width = 8, 
        height = 18,
        speed = 1,
        sprites = { 5, 7 }, 
        sprite_defeat = 9,
        sd = 0.2,
        spr_width = 2, 
        spr_height = 3
      }
    }
  },
  {
    title = "three is a set",
    instruction = "go out and celbrate!",
    enemies = {}
  }
}

local defeat = {
  title = "down for the count...",
  instruction = "press 🅾️ to reset",
}

local gate = { 
  doors = { 
    { 
      x = sprite_size * 2, 
      sprite = 30 
    }, 
    { 
      x = sprite_size * 13, 
      sprite = 31 
    } 
  }, 
  y = sprite_size, 
  ys = { sprite_size, 0 } 
}

local trophy = { 
  sprite = 33, 
  x = flr(screen_size / 2 - sprite_size / 2), 
  y = 9 * sprite_size 
}

local clp = { 
  x1 = gate.doors[1].x, 
  y1 = gate.y + 3, 
  x2 = gate.doors[2].x + sprite_size, 
  y2 = gate.y + sprite_size 
}

function _init()
  start_game()
end

function _update()
  if state == "start" then
    screen_update()

    if btnp(5) then
      music(1, 1200)
      game_init(levels[level].enemies)
      state = "play"
    end
  elseif state == "play" then
    game_update()
  elseif state == "continue" then
    gate.y = max(gate.y - 0.5, gate.ys[2])
    if(gate.y == gate.ys[2]) then 
      game_update()
    end
  elseif state == "progress" then
    screen_update()

    if btnp(5) then
      gate.y = gate.ys[1]
      game_init(levels[level].enemies)
      state = "play"
    end
  elseif state == "win" then
    music(-1, 1200)
    screen_update()
  elseif state == "lose" then
    music(-1, 1200)
    screen_init(defeat.title, defeat.instruction)
    state = "end"
  elseif state == "end" then
    if btnp(4) then 
      start_game()
    end
  end
end

function _draw()
  cls()
  map()

  clip(clp.x1, clp.y1, clp.x2, clp.y2)
  for door in all(gate.doors) do
    spr(door.sprite, door.x, gate.y)
  end
  clip()

  if state == "start" then 
    screen_draw()
  elseif state == "play" then
    game_draw()
  elseif state == "continue" then
    game_draw()
  elseif state == "progress" then
    game_draw()
    screen_draw()
  elseif state == "win" then
    game_draw()
    screen_draw()
    spr(trophy.sprite, trophy.x, trophy.y)
  elseif state == "lose" then
    game_draw()
  elseif state == "end" then
    game_draw()
    screen_draw()
  end
end

function start_game()
  level = 1
  screen_init(levels[level].title, levels[level].instruction)
  state = "start"
end

function lose_game()
  state = "lose"
end

function continue_game()
  state = "continue"
end

function level_up()
  level += 1
  screen_init(levels[level].title, levels[level].instruction)
  state = level == #levels and "win" or "progress"
end
-->8
-- screen_init(title: string, instruction: string, colors: { { colors_letters }, color_text })
local enter = {}
local exit = {}
local char_width = 4

function screen_init(title, instruction, colors)
  local cs = colors or { { 7, 6 }, 6 }

  enter.text = title or "hello"
  enter.count = 0
  enter.dcount = 0.45
  enter.y = 56
  enter.y_offset = -1
  enter.colors = cs[1]
  enter.letters = {}
  local len = #enter.text
  for i = 1, len do 
    local x = flr(screen_size / 2 - len / 2 * char_width + (i - 1) * char_width)
    add(enter.letters, {
      char = enter.text[i],
      x = x,
      y = enter.y,
      color = enter.colors[1]
    })
  end

  exit.text = instruction or "goodbye"
  exit.x = flr(screen_size / 2 - #exit.text / 2 * char_width)
  exit.y = 110
  exit.color = cs[2]
end

function screen_update()
  local len = #enter.letters
  enter.count = (enter.count + enter.dcount) % len
  
  local letter_up = enter.letters[(flr(enter.count) + 1) % len + 1]
  local letter_down = enter.letters[flr(enter.count) + 1]

  letter_up.y = enter.y + enter.y_offset
  letter_up.color = enter.colors[2]
  letter_down.y = enter.y
  letter_down.color = enter.colors[1]
end

function screen_draw()
  for letter in all(enter.letters) do
    print(letter.char, letter.x, letter.y, letter.color)
  end
  print(exit.text, exit.x, exit.y, exit.color)
end
-->8
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
__gfx__
00000000777700000777700007777000000000000000000000000000700000000000000000000000000000000777777777777777777777707777777777777777
00000000777700007070770070707700000000000000007700000000070000000000000000000000000000007777777777777777777777777777777777777777
00700700777700007777770077777700000000000000077700000000007007700000000000000770000000007700000000000000000000770000000000000000
00077000777700000777700007777000777770007777700770000000000777770000000000000770000000007707777777777777777770777777777777777777
00077000000000000777007007770700707070007777777770000000000070770000000000000770000000007707777777777777777770777700000770000077
00700700000000000077770000777700077777000000077700000000000077700000000000000770000000007707777777777777777770777000000000000007
00000000000000000000000000000000000000000000007000000000000777700000000000000777000000007707777777777777777770777000000000000007
00000000000000000000000000000000000000000000007000000000007007000000000000077707700000007707777777777777777770777000000000000007
00000000000770007000000700000000000000000000777700000000070007000000000007777777700000007707777700000000777770770000000000000000
00000000707770007000000707777770000000000007777770000000700077700000000077007777000000007707777700000000777770770000000000000000
00000000077700007700007777077077000000000077777770000000000777770000000070000000000000007707777700000000777770770000000000000000
00000000707000007777777777700777007777000777777770000000007777777000000077777770000000007707777700000000777770770000000000000000
00000000770700007707707777000077070770700777777770000000077777777000000077777777000000007707777700000000777770770707070770707070
00000000000000000770077070000007707777070777777770000000077777777000000077777777000000007707777700000000777770770070707007070700
00000000000000000000000000000000000000000777777770000000077777777000000077777777000000007707777700000000777770770707070770707070
00000000000000000000000000000000000000000077777700000000077777777000000007777770000000007707777700000000777770770070707007070700
00000000000000000000000000000000000000000007777000000000007777770000000000700000000000007707777777777777777770770000000000000000
00000000070000700000000000000000000000000000070000000000000777700000000007707777000000007707777777777777777770770000000000000000
00000000077007700000000000000000000000000700077770000000000070000000000007000007000000007707777777777777777770770000000000000000
00000000077777700000000000000000000000000777000070000000000070000000000007777777000000007707777777777777777770770000000000000000
00000000007777000000000000000000000000000007777770000000777770000000000000000000000000007707777777777777777770770000000000000000
00000000000770000000000000000000000000000000000000000000700000000000000000000000000000007700000000000000000000770000000000000000
00000000007777000000000000000000000000000000000000000000777000000000000000000000000000007777777777777777777777770000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000777777777777777777777700000000000000000
00000000070700000707000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000777770007070700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000777770007000700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000077700000707000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000007000000070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__gff__
0000000000000000000000000000010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0b0c0e0c0c0c0c0c0c0c0c0c0c0f0c0d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1b00000000000000000000000000001d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1b00000000000000000000000000001d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1b00000000000000000000000000001d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1b00000000000000000000000000001d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1b00000000000000000000000000001d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1b00000000000000000000000000001d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1b00000000000000000000000000001d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1b00000000000000000000000000001d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1b00000000000000000000000000001d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1b00000000000000000000000000001d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1b00000000000000000000000000001d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1b00000000000000000000000000001d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1b00000000000000000000000000001d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2b2c2c2c2c2c2c2c2c2c2c2c2c2c2c2d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000200002b035300451f0001f0041f0041f0011f0011f0011f0011f0011f0011f0011f0011f0011f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0002000033041350313302135011330113501131001340043700439001390011f0011f0011f0011f0011f0011f0011f0011f0041f0041f0011f0011f0011f0011f0011f0011f0011f0011f0011f0000000000000
000b0000240002402426025290352e0353004532045350453a0453a0003a0002e000300002400026000290002e0003000032000350003a0001f0041f0011f0011f0011f0011f0011f0011f0011f0011f0011f000
000400001403333004300052e0052b00529005100332400522005220003a0002e0000b0332400026000290002e0003000006023350003a0001f0041f0011f001030231f0001f0011f0011f0011f001010131f000
0008000016053070000000114001110010e0010a001080010500403004000011f0011f00122001240011f001220012400124001290042900424001290012b0012b0012a00127001290012b0012e0013000000000
0009000016053070001100011000110430e000110000f0000f033030040f0001f0001f00122001240011f001220012400124001290042900424001290012b0012b0012a00127001290012b0012e0013000000000
001000001f0041f0011f0011f0011f0011f0011f0011f0011f0011f0041f0041f0011f0011f0011f0011f0011f0011f0011f0011f0011f0041f0041f0011f0011f0011f0011f0011f0011f0011f0011f0011f000
000e00001f7241f0351b7221b035167221603514722140351f7221f0351b7221b0351672216035147221403514722130351b7221b0350c7250c03514722140351f7221f0351b7221b0350c7250c0351472214035
000e00001f7241f0351b7221b0351672218035147221b0351f7221f0351b7221b0351672216035147221803514722180351b7221b0351672216032147221b0351f7221f0351b7221b03516722180321472214035
000e000000000000001f7141f0150000000000167141601500000000001f7141f015000000000016714160150000000000147141301500000000000c7140c0150000000000147141301500000000000c7140c015
__music__
01 07094344
02 08094344

