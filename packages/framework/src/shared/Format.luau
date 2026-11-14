-- Formatação de números para a interface (1.2K, 3.4M, ...).
local Format = {}

local SUFFIXES = { "", "K", "M", "B", "T", "Qa", "Qi" }

function Format.abbreviate(value: number): string
	local negative = value < 0
	local n = math.abs(value)
	local index = 1
	while n >= 1000 and index < #SUFFIXES do
		n /= 1000
		index += 1
	end
	local text
	if index == 1 then
		text = tostring(math.floor(n))
	elseif n >= 100 then
		text = string.format("%d%s", math.floor(n), SUFFIXES[index])
	else
		text = string.format("%.1f%s", math.floor(n * 10) / 10, SUFFIXES[index])
	end
	if negative then
		return "-" .. text
	end
	return text
end

function Format.duration(seconds: number): string
	local s = math.max(0, math.floor(seconds))
	return string.format("%d:%02d", s // 60, s % 60)
end

return Format
