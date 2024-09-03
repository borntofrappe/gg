screen_size = 128
sprite_size = 8
flag_continue = 1

edge_top = sprite_size * 2
edge_left = sprite_size 
edge_right = screen_size - sprite_size 
edge_bottom = screen_size - sprite_size

-- graphics: sprites, tilemap, get_tilemap_key, spr, print, map, clip
local spritesheet = love.graphics.newImage("res/sprites.png")
spritesheet:setFilter("nearest", "nearest") 
local spritesheet_width = spritesheet:getWidth()
local spritesheet_height = spritesheet:getHeight()

local sprites = {
  [1] = love.graphics.newQuad(0, 0, sprite_size, sprite_size, spritesheet_width, spritesheet_height),
  [17] = love.graphics.newQuad(0, sprite_size, sprite_size, sprite_size, spritesheet_width, spritesheet_height),
  [2] = love.graphics.newQuad(sprite_size, 0, sprite_size, sprite_size, spritesheet_width, spritesheet_height),
  [3] = love.graphics.newQuad(sprite_size * 2, 0, sprite_size, sprite_size, spritesheet_width, spritesheet_height),
  [4] = love.graphics.newQuad(sprite_size * 3, 0, sprite_size, sprite_size, spritesheet_width, spritesheet_height),
  [18] = love.graphics.newQuad(sprite_size, sprite_size, sprite_size, sprite_size, spritesheet_width, spritesheet_height),
  [19] = love.graphics.newQuad(sprite_size * 2, sprite_size, sprite_size, sprite_size, spritesheet_width, spritesheet_height),
  [20] = love.graphics.newQuad(sprite_size * 3, sprite_size, sprite_size, sprite_size, spritesheet_width, spritesheet_height),
  [5] = love.graphics.newQuad(sprite_size * 4, 0, sprite_size * 2, sprite_size * 3, spritesheet_width, spritesheet_height),
  [7] = love.graphics.newQuad(sprite_size * 6, 0, sprite_size * 2, sprite_size * 3, spritesheet_width, spritesheet_height),
  [9] = love.graphics.newQuad(sprite_size * 8, 0, sprite_size * 2, sprite_size * 3, spritesheet_width, spritesheet_height),
  [33] = love.graphics.newQuad(0, sprite_size * 2, sprite_size, sprite_size, spritesheet_width, spritesheet_height),
  [49] = love.graphics.newQuad(0, sprite_size * 3, sprite_size, sprite_size, spritesheet_width, spritesheet_height),
  [50] = love.graphics.newQuad(sprite_size, sprite_size * 3, sprite_size, sprite_size, spritesheet_width, spritesheet_height),
  [30] = love.graphics.newQuad(sprite_size * 13, sprite_size, sprite_size, sprite_size, spritesheet_width, spritesheet_height),
  [31] = love.graphics.newQuad(sprite_size * 14, sprite_size, sprite_size, sprite_size, spritesheet_width, spritesheet_height),
  [11] = love.graphics.newQuad(sprite_size * 10, 0, sprite_size, sprite_size, spritesheet_width, spritesheet_height),
  [12] = love.graphics.newQuad(sprite_size * 11, 0, sprite_size, sprite_size, spritesheet_width, spritesheet_height),
  [13] = love.graphics.newQuad(sprite_size * 12, 0, sprite_size, sprite_size, spritesheet_width, spritesheet_height),
  [27] = love.graphics.newQuad(sprite_size * 10, sprite_size, sprite_size, sprite_size, spritesheet_width, spritesheet_height),
  [29] = love.graphics.newQuad(sprite_size * 12, sprite_size, sprite_size, sprite_size, spritesheet_width, spritesheet_height),
  [43] = love.graphics.newQuad(sprite_size * 10, sprite_size * 2, sprite_size, sprite_size, spritesheet_width, spritesheet_height),
  [44] = love.graphics.newQuad(sprite_size * 11, sprite_size * 2, sprite_size, sprite_size, spritesheet_width, spritesheet_height),
  [45] = love.graphics.newQuad(sprite_size * 12, sprite_size * 2, sprite_size, sprite_size, spritesheet_width, spritesheet_height),
  [14] = love.graphics.newQuad(sprite_size * 13, 0, sprite_size, sprite_size, spritesheet_width, spritesheet_height),
  [15] = love.graphics.newQuad(sprite_size * 14, 0, sprite_size, sprite_size, spritesheet_width, spritesheet_height),
  [30] = love.graphics.newQuad(sprite_size * 13, sprite_size, sprite_size, sprite_size, spritesheet_width, spritesheet_height),
  [31] = love.graphics.newQuad(sprite_size * 14, sprite_size, sprite_size, sprite_size, spritesheet_width, spritesheet_height)
}

tilemap = {}
function get_tilemap_key(column, row)
  return "c" .. column .. "r" .. row
end

local tilemapEdit = 
           "                " 
.. "\n" .. "0181111111111912" 
.. "\n" .. "3              4" 
.. "\n" .. "3              4" 
.. "\n" .. "3              4" 
.. "\n" .. "3              4" 
.. "\n" .. "3              4" 
.. "\n" .. "3              4" 
.. "\n" .. "3              4" 
.. "\n" .. "3              4" 
.. "\n" .. "3              4" 
.. "\n" .. "3              4" 
.. "\n" .. "3              4" 
.. "\n" .. "3              4" 
.. "\n" .. "3              4" 
.. "\n" .. "5666666666666667"

local tilemapSprites = {
  ["0"] = 11,
  ["1"] = 12,
  ["2"] = 13,
  ["3"] = 27,
  ["4"] = 29,
  ["5"] = 43,
  ["6"] = 44,
  ["7"] = 45,
  ["8"] = 14,
  ["9"] = 15
}

local spritesFlag = {
  [14] = flag_continue,
  [15] = flag_continue
}

local columns = tilemapEdit:find("\n")
local _, rows = tilemapEdit:gsub("\n", "")

for row = 1, rows + 1 do
  for column = 1, columns do 
    local i = column + (row * columns)
    local sprite = tilemapSprites[tilemapEdit:sub(i, i)]
    if sprite then 
      local tile = {
        sprite = sprite,
        x = (column - 1) * sprite_size,
        y = sprite_size + (row - 1) * sprite_size,
        flag = spritesFlag[sprite] or 0
      }
      local key = get_tilemap_key(column, row)
      tilemap[key] = tile
    end
  end
end

function spr(n, x, y)
  love.graphics.setColor(1, 1, 1)
  love.graphics.draw(spritesheet, sprites[n], x, y)
end

function print(text, x, y, color)
  love.graphics.setColor(color)
  love.graphics.print(text, x, y)
end

function map()
  love.graphics.setColor(1, 1, 1)
  for _, tile in pairs(tilemap) do 
    spr(tile.sprite, tile.x, tile.y)
  end
end

-- requires world coordinates
function clip(x1, y1, x2, y2) 
  if x1 and y1 and x2 and y2 then
    love.graphics.setScissor(x1, y1, x2 - x1, y2 - y1)
  else
    love.graphics.setScissor()
  end
end

-- sound: sfx, music
local sfxs = {
  [0] = love.audio.newSource("res/sounds/pickup_sword.wav", "static"),
  [1] = love.audio.newSource("res/sounds/use_sword.wav", "static"),
  [2] = love.audio.newSource("res/sounds/clear_room.wav", "static"),
  [3] = love.audio.newSource("res/sounds/cross_threshold.wav", "static"),
  [4] = love.audio.newSource("res/sounds/suffer_hit.wav", "static"),
  [5] = love.audio.newSource("res/sounds/suffer_defeat.wav", "static")
}

local musics = {
  [1] = love.audio.newSource("res/sounds/music.wav", "stream"),
}

function sfx(i)
  if sfxs[i] then
    sfxs[i]:play()
  end
end

function music(i)
  if i == -1 then
    for _, audio in pairs(musics) do
      audio:stop()
    end
  else
    if musics[i] then
      musics[i]:play()
      musics[i]:setLooping(true)
    end
  end
end

-- interaction: btn, btnp
-- ! empty btns at the end of the game loop
btns = {}
function btnp(i)
  if i == 4 then return btns["z"] end
  if i == 5 then return btns["x"] end

  return false
end

function btn(i)
  if i == 0 then return love.keyboard.isDown("left") end
  if i == 1 then return love.keyboard.isDown("right") end
  if i == 2 then return love.keyboard.isDown("up") end
  if i == 3 then return love.keyboard.isDown("down") end

  return false
end

function love.keypressed(key)
  if key == "escape" then
    love.event.quit()
  end
  btns[key] = true
end

-- utils
function min(...)
  return math.min(...)
end

function mid(min, value, max)
  return math.max(min, math.min(max, value))
end

function flr(value)
  return math.floor(value)
end

function rnd()
  return love.math.random()
end

function add(t, v)
  table.insert(t, v)
end