-- Boosts temporários (ex.: dinheiro 2x por 15 min). A validade é salva nos dados,
-- então continua valendo se o jogador trocar de servidor.
-- O cliente lê o atributo "Boost_<chave>" (horário Unix de expiração) para mostrar o tempo restante.
local Data = require(script.Parent.Data)

local Boosts = {}

local function setAttribute(player: Player, key: string, expiresAt: number?)
	player:SetAttribute("Boost_" .. key, expiresAt)
end

function Boosts.start()
	Data.onLoaded(function(player, data)
		data.boosts = data.boosts or {}
		local now = os.time()
		for key, expiresAt in data.boosts do
			if expiresAt > now then
				setAttribute(player, key, expiresAt)
			else
				data.boosts[key] = nil
			end
		end
	end)
end

-- Ativa ou estende um boost.
function Boosts.activate(player: Player, key: string, durationSeconds: number): boolean
	local data = Data.get(player)
	if not data then
		return false
	end
	data.boosts = data.boosts or {}
	local now = os.time()
	local current = data.boosts[key]
	local base = if current and current > now then current else now
	data.boosts[key] = base + durationSeconds
	setAttribute(player, key, data.boosts[key])
	return true
end

function Boosts.isActive(player: Player, key: string): boolean
	local data = Data.get(player)
	local expiresAt = data and data.boosts and data.boosts[key]
	return expiresAt ~= nil and expiresAt > os.time()
end

return Boosts
