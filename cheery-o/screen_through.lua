--[[ screen_through
_init(text: string, callback: function, delay: +number, colors: {number})
]]
local screen_size = 128
local char_width = 4
local char_height = 6
local title = {}

function screen_through_init(text, callback, delay, colors)
	title = {}
	title.text = text or "fading title"
	title.callback = callback or function() end
	title.delay = delay or 3
	title.colors = colors or { 0, 1, 6, 6, 7, 7, 7, 7, 6, 6, 1, 0 }
	title.colors_i = 1

	title.x = flr(screen_size / 2 - #title.text / 2 * char_width)
	title.y = flr(screen_size / 2 - char_height)
	title.start = time()
	title.finish = time() + title.delay
	title.update = true
end

function screen_through_update()
	if title.update then
		title.start = time()
		title.color_i = ceil((1 - (title.finish - title.start) % 1) * #title.colors)
		if title.start >= title.finish then 
			title.callback()
			title.update = false
		end
	end
end

function screen_through_draw()
	print(title.text, title.x, title.y, title.colors[title.color_i])
end