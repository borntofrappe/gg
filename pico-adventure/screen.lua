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