require "global"
require "screen"  
require "game"

local state = nil
local level = nil
local levels = {
  {
    title = "fleeting love",
    instruction = "press X to play",
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
      },
    }
  },
  {
    title = "one down",
    instruction = "press X to continue",
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
      }
    }
  },
  {
    title = "two to go",
    instruction = "press X to continue",
    enemies = {
      { 
        max_hp = 3, 
        threshold = 10, 
        width = 9, 
        height = 21,
        speed = 1,
        sprites = { 5, 7 }, 
        sprite_defeat = 9,
        sd = 0.2,
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
  instruction = "press O to reset",
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
  ys = { sprite_size, 0 },
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

local update_speed = 30
local screen_scale = 4
local window_size = screen_size * screen_scale

function love.load()
  love.window.setMode(window_size, window_size)
  love.window.setTitle("Fleeting love")
  
  love.graphics.setBackgroundColor(0, 0, 0)

  local font = love.graphics.newFont("res/font.ttf", 6)
  font:setFilter("nearest", "nearest")
  love.graphics.setFont(font)

  start_game()
end

function love.update(dt)
  if state == "start" then
    screen_update(dt * update_speed)

    if btnp(5) then
      music(1)
      game_init(levels[level].enemies)
      state = "play"
    end
  elseif state == "play" then
    game_update(dt * update_speed)
  elseif state == "continue" then
    gate.y = math.max(gate.y - 0.5 * dt * update_speed, gate.ys[2])
    if(gate.y == gate.ys[2]) then 
      game_update(dt * update_speed)
    end
  elseif state == "progress" then
    screen_update(dt * update_speed)

    if btnp(5) then
      gate.y = gate.ys[1]
      game_init(levels[level].enemies)
      state = "play"
    end
  elseif state == "win" then
    music(-1)
    screen_update(dt * update_speed)
  elseif state == "lose" then
    music(-1)
    screen_init(defeat.title, defeat.instruction)
    state = "end"
  elseif state == "end" then
    if btnp(4) then 
      start_game()
    end
  end

  -- follow btns instruction to clear input fields
  btns = {}
end

function love.draw()
  love.graphics.scale(screen_scale, screen_scale)
  
  map()

  -- world coordinates
  clip(clp.x1 * screen_scale, clp.y1 * screen_scale, clp.x2 * screen_scale, clp.y2 * screen_scale)
  for _, door in pairs(gate.doors) do
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
  level = level + 1
  screen_init(levels[level].title, levels[level].instruction)
  state = level == #levels and "win" or "progress"
end