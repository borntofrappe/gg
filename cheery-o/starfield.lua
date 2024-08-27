--[[ starfield
_init(number: +number, colors: {c1, c2}, speeds: {s1, s2})
]]
local screen_size = 128
local star_size = 0.5 
local starfield = {}

function starfield_init(number, colors, speeds)
	starfield = {}
	
	local n = number or 50
	local cs = colors or { 7, 5 }
	local ss = colors or { 1, 0.5 }

	for i = 1, 2 do
		local stars = {}
		for i = 1, n do 
			local x = flr(rnd(screen_size))
			local y = flr(rnd(screen_size))
			add(stars, { x = x, y = y })
			add(stars, { x = x, y = y - screen_size })
		end
		add(starfield, {
			r = star_size,
			color = cs[i],
			speed = ss[i],
			y = 0,
			stars = stars
		})
	end
end

function starfield_update()
	for field in all(starfield) do 
		field.y = (field.y + field.speed) % screen_size
	end
end

function starfield_draw()
	for field in all(starfield) do 
		for star in all(field.stars) do 
			circfill(star.x, star.y + field.y, field.r, field.color)
		end
	end
end