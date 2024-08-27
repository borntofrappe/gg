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