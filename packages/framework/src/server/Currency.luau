-- Moeda do jogo: saldo nos dados, placar (leaderstats) e atributo "Currency" para a interface.
local Data = require(script.Parent.Data)
local Analytics = require(script.Parent.Analytics)

local Currency = {}

local currencyName = "Coins"

local function refresh(player: Player, balance: number)
	player:SetAttribute("Currency", balance)
	local stats = player:FindFirstChild("leaderstats")
	local value = stats and stats:FindFirstChild(currencyName)
	if value then
		(value :: NumberValue).Value = balance
	end
end

function Currency.start(name: string)
	currencyName = name
	Data.onLoaded(function(player, data)
		local stats = Instance.new("Folder")
		stats.Name = "leaderstats"
		local value = Instance.new("NumberValue")
		value.Name = currencyName
		value.Parent = stats
		stats.Parent = player
		refresh(player, data.currency or 0)
	end)
end

function Currency.get(player: Player): number
	local data = Data.get(player)
	return if data then data.currency or 0 else 0
end

-- Adiciona moeda. transactionType: ver Analytics.economy.
function Currency.add(player: Player, amount: number, transactionType: string?, sku: string?): boolean
	local data = Data.get(player)
	if not data or amount ~= amount or amount <= 0 or amount == math.huge then
		return false
	end
	data.currency = (data.currency or 0) + amount
	refresh(player, data.currency)
	Analytics.economy(player, true, amount, data.currency, transactionType or "Gameplay", sku)
	return true
end

-- Gasta moeda se houver saldo. Retorna true se gastou.
function Currency.spend(player: Player, amount: number, transactionType: string?, sku: string?): boolean
	local data = Data.get(player)
	if not data or amount ~= amount or amount < 0 then
		return false
	end
	local balance = data.currency or 0
	if balance < amount then
		return false
	end
	data.currency = balance - amount
	refresh(player, data.currency)
	Analytics.economy(player, false, amount, data.currency, transactionType or "Shop", sku)
	return true
end

-- Define o saldo diretamente (ex.: reset no rebirth). Não gera evento de métrica.
function Currency.set(player: Player, amount: number)
	local data = Data.get(player)
	if not data then
		return
	end
	data.currency = math.max(0, amount)
	refresh(player, data.currency)
end

return Currency
