--[[ fxs
_particles(n: +number, x: +number, y: +number, colors: { number })
_shockwave(x: +number, y: +number, r: +number, color: number)
_sparks(n: +number, x: +number, y: +number, color: number)
_float(text: string, x: +number, y: +number, colors: { number, number })
]]
local particles = {}
local particle_spec = { times = { 14, 20 }, speeds = { 3, 6 }, frictions = { 0.6, 0.8 }, radii = { 1, 6 }, colors = { 7, 10, 10, 9, 8, 3, 1 } }
local shockwaves = {}
local shockwave_spec = { color = 7, expansion = 2.2, expansion_rate = 0.35 }
local sparks = {}
local spark_spec = { times = { 6, 14 }, speeds = { 0.4, 1 }, r = 0.5, color = 7 }
local floats = {}
local float_spec = { time = 22, skip = 4, speed = 0.5, dy = -1, colors = { 7, 10 } }

function fxs_particles(n, x, y, colors)
	local times, speeds, frictions, radii = particle_spec.times, particle_spec.speeds, particle_spec.frictions, particle_spec.radii, particle_spec.colors

	for i = 1, n do 
		local angle = rnd()
		local speed = speeds[1] + ceil((rnd() * (speeds[2] - speeds[1])) * 10) / 10
		local sx = cos(angle) * speed
		local sy = sin(angle) * speed
		local time_max = times[1] + ceil(rnd() * (times[2] - times[1]))
		local radii = {radii[1], radii[1] + ceil(rnd() * (radii[2] - radii[1]))}
		local friction = frictions[1] + ceil((rnd() * (frictions[2] - frictions[1])) * 10) / 10
		local particle = { time_max = time_max, time = 0, x = x, y = y, sx = sx, sy = sy, friction = friction, r = radii[1], radii = radii, colors = colors or particle_spec.colors, ci = 1 }
		add(particles, particle)
	end
end

function fxs_shockwave(x, y, r, color)
	local expansion, expansion_rate = shockwave_spec.expansion, shockwave_spec.expansion_rate
	local r_max = r * expansion
	local shockwave = { x = x, y = y, r = r, r_max = r_max, dr = (r_max - r) ^ expansion_rate, color = color or shockwave_spec.color }
	add(shockwaves, shockwave)
end

function fxs_sparks(n, x, y, color)
	local times, speeds = spark_spec.times, spark_spec.speeds

	for i = 1, n do 
		local angle = rnd()
		local speed = speeds[1] + ceil((rnd() * (speeds[2] - speeds[1])) * 10) / 10
		local sx = cos(angle) * speed
		local sy = sin(angle) * speed
		local time_max = times[1] + ceil(rnd() * (times[2] - times[1]))
		local spark = { time_max = time_max, time = 0, x = x, y = y, sx = sx, sy = sy, r = spark_spec.r, color = color or spark_spec.color }
		add(sparks, spark)
	end
end

function fxs_float(text, x, y, colors)
	local char_width = 4
	local time_max, skip, speed, dy = float_spec.time, float_spec.skip, float_spec.speed, float_spec.dy

	local float = { time_max = time_max, time = 0, skip = skip, x = x - (char_width * #text) / 2, y = y, sy = dy * speed, text = text, colors = colors or float_spec.dy.colors, ci = 1 }
	add(floats, float)
end

function fxs_init()
	particles = {}
	shockwaves = {}
	sparks = {}
	floats = {}
end

function fxs_update()
	for particle in all(particles) do
		particle.time += 1
		
		particle.x += particle.sx
		particle.y += particle.sy
		particle.sx *= particle.friction
		particle.sy *= particle.friction

		local t = particle.time / particle.time_max
		local r1, r2 = particle.radii[1], particle.radii[2]
		particle.r = r1 + (1 - t) * (r2 - r1)
		particle.ci = ceil(t * #particle.colors)

		if particle.time >= particle.time_max then
			del(particles, particle)
		end
	end

	for shockwave in all(shockwaves) do
		shockwave.r += shockwave.dr

		if shockwave.r >= shockwave.r_max then
			del(shockwaves, shockwave)
		end
	end

	for spark in all(sparks) do
		spark.time += 1
		
		spark.x += spark.sx
		spark.y += spark.sy

		if spark.time >= spark.time_max then
			del(sparks, spark)
		end
	end

	for float in all(floats) do 
		float.time += 1
		float.y += float.sy
		float.ci = float.time % float.skip == 0 and 1 or 2

		if float.time >= float.time_max then
			del(floats, float)
		end
	end
end

function fxs_draw()
	for particle in all(particles) do
		circfill(particle.x, particle.y, particle.r, particle.colors[particle.ci])
	end
	for shockwave in all(shockwaves) do
		circ(shockwave.x, shockwave.y, shockwave.r, shockwave.color)
	end
	for spark in all(sparks) do
		circ(spark.x, spark.y, spark.r, spark.color)
	end
	for float in all(floats) do
		print(float.text, float.x, float.y, float.colors[float.ci])
	end
end

function fxs_none()
	return #particles == 0 and #shockwaves == 0 and #sparks == 0 and #floats == 0
end