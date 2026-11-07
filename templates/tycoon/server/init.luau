-- Modelo de gênero: TYCOON.
-- Cada jogador ganha um terreno. O terreno gera dinheiro por segundo; o jogador pisa no coletor
-- para pegar, e pisa nos botões para comprar melhorias que aumentam a renda.
-- Quando compra tudo, pode fazer "rebirth": recomeça com um multiplicador permanente.
--
-- Tudo vem de config.tycoon (ver games/*/config.luau). O cenário é gerado por código, então um
-- jogo novo não precisa de nada montado à mão no Studio para funcionar.
local Players = game:GetService("Players")

local Plot = require(script.Plot)

local Tycoon = {}

local INCOME_TICK = 1
local AUTO_COLLECT_EVERY = 5

function Tycoon.start(config, Framework)
	local settings = config.tycoon
	assert(settings, "config.tycoon não encontrado")
	settings.currencyLabel = config.currencyName

	local Data = Framework.Data
	local Currency = Framework.Currency
	local Monetization = Framework.Monetization
	local Boosts = Framework.Boosts
	local Notify = Framework.Notify
	local Analytics = Framework.Analytics
	local AntiExploit = Framework.AntiExploit

	local world = Plot.buildWorld(settings)
	local plots = {}
	for index = 1, settings.plotCount do
		plots[index] = Plot.new(index, settings, world)
	end
	local plotOf: { [Player]: any } = {}
	local pending: { [Player]: number } = {}

	local function incomePerSecond(player: Player): number
		local data = Data.get(player)
		if not data then
			return 0
		end
		local income = settings.baseIncome
		for _, upgrade in settings.upgrades do
			if data.upgrades[upgrade.key] then
				income += upgrade.income
			end
		end
		local multiplier = 1 + (data.rebirths or 0) * settings.rebirthBonus
		for passKey, value in settings.passMultipliers or {} do
			if Monetization.ownsPass(player, passKey) then
				multiplier *= value
			end
		end
		for boostKey, value in settings.boostMultipliers or {} do
			if Boosts.isActive(player, boostKey) then
				multiplier *= value
			end
		end
		return income * multiplier
	end

	local function nextUpgrade(data)
		for _, upgrade in settings.upgrades do
			if not data.upgrades[upgrade.key] then
				return upgrade
			end
		end
		return nil
	end

	local function rebirthCost(data): number
		return settings.rebirthCost * ((data.rebirths or 0) + 1)
	end

	local function refresh(player: Player)
		local plot = plotOf[player]
		local data = Data.get(player)
		if plot and data then
			plot:render(data, nextUpgrade(data), rebirthCost(data), incomePerSecond(player))
		end
	end

	local function collect(player: Player)
		local amount = math.floor(pending[player] or 0)
		if amount <= 0 then
			return
		end
		pending[player] -= amount
		Currency.add(player, amount, "Gameplay", "collect")
		local data = Data.get(player)
		if data then
			Analytics.funnel(player, data, 2, "Primeira coleta")
		end
	end

	local function buy(player: Player, upgrade)
		local data = Data.get(player)
		if not data or data.upgrades[upgrade.key] then
			return
		end
		local expected = nextUpgrade(data)
		if expected ~= upgrade then
			return
		end
		if not Currency.spend(player, upgrade.cost, "Shop", upgrade.key) then
			Notify.send(
				player,
				string.format("Faltam %d %s", math.ceil(upgrade.cost - Currency.get(player)), config.currencyName),
				"error"
			)
			return
		end
		data.upgrades[upgrade.key] = true
		Analytics.funnel(player, data, 3, "Primeira melhoria")
		refresh(player)
	end

	local function rebirth(player: Player)
		local data = Data.get(player)
		if not data or nextUpgrade(data) ~= nil then
			return
		end
		local cost = rebirthCost(data)
		if not Currency.spend(player, cost, "Shop", "rebirth") then
			Notify.send(player, string.format("Rebirth custa %d %s", cost, config.currencyName), "error")
			return
		end
		data.rebirths = (data.rebirths or 0) + 1
		data.upgrades = {}
		Currency.set(player, 0)
		pending[player] = 0
		Analytics.funnel(player, data, 4, "Primeiro rebirth")
		local bonus = math.floor(data.rebirths * settings.rebirthBonus * 100)
		Notify.send(player, string.format("Rebirth %d! Renda permanente +%d%%", data.rebirths, bonus), "success")
		refresh(player)
	end

	local function spawnAtPlot(player: Player, character: Model)
		local plot = plotOf[player]
		if not plot then
			return
		end
		character:WaitForChild("HumanoidRootPart", 10)
		AntiExploit.allowTeleport(player, 3)
		character:PivotTo(plot:spawnCFrame())
	end

	local function onLoaded(player: Player, data)
		data.upgrades = data.upgrades or {}
		local plot
		for _, candidate in plots do
			if not candidate.owner then
				plot = candidate
				break
			end
		end
		if not plot then
			Notify.send(player, "Todos os terrenos estão ocupados neste servidor.", "error")
			return
		end
		plotOf[player] = plot
		pending[player] = 0
		plot:claim(player, {
			onCollect = function()
				collect(player)
			end,
			onBuy = function(upgrade)
				buy(player, upgrade)
			end,
			onRebirth = function()
				rebirth(player)
			end,
		})
		refresh(player)
		player.CharacterAdded:Connect(function(character)
			spawnAtPlot(player, character)
		end)
		if player.Character then
			task.spawn(spawnAtPlot, player, player.Character)
		end
	end

	Data.onLoaded(onLoaded)

	Players.PlayerRemoving:Connect(function(player)
		local plot = plotOf[player]
		if plot then
			plot:release()
		end
		plotOf[player] = nil
		pending[player] = nil
	end)

	-- Passes e boosts mudam a renda mostrada no terreno.
	for passKey in settings.passMultipliers or {} do
		Monetization.onPass(passKey, refresh)
	end

	-- Produto "pular melhoria": entrega a próxima melhoria de graça.
	-- Se já comprou tudo, entrega o valor da melhoria mais cara em dinheiro.
	Monetization.setProductHandler("SkipUpgrade", function(player)
		local data = Data.get(player)
		if not data then
			return false
		end
		local upgrade = nextUpgrade(data)
		if upgrade then
			data.upgrades[upgrade.key] = true
			refresh(player)
			return true
		end
		local last = settings.upgrades[#settings.upgrades]
		return Currency.add(player, last.cost, "IAP", "SkipUpgrade")
	end)

	-- Renda por segundo.
	task.spawn(function()
		local ticks = 0
		while true do
			task.wait(INCOME_TICK)
			ticks += 1
			for player, plot in plotOf do
				local income = incomePerSecond(player)
				pending[player] = (pending[player] or 0) + income * INCOME_TICK
				local autoCollect = settings.autoCollectPass and Monetization.ownsPass(player, settings.autoCollectPass)
				if autoCollect and ticks % AUTO_COLLECT_EVERY == 0 then
					collect(player)
				end
				plot:showPending(pending[player], income)
			end
		end
	end)
end

return Tycoon
