-- Modelo de gênero: TYCOON.
-- Cada jogador recebe uma loja já construída numa cidade. A loja gera dinheiro por segundo e cada
-- cliente que entra deixa uma gorjeta; o jogador recolhe no caixa e compra melhorias que viram objetos
-- na loja. Quando compra tudo, pode fazer "rebirth": recomeça com um multiplicador permanente.
--
-- Tudo vem de config.tycoon (ver games/*/config.luau). Os objetos das melhorias vêm de `options.props`.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local City = require(script.City)
local Plot = require(script.Plot)
local Customers = require(script.Customers)

local Remotes = require(ReplicatedStorage:WaitForChild("FrameworkShared"):WaitForChild("Remotes"))

local Tycoon = {}

local INCOME_TICK = 1
local AUTO_COLLECT_EVERY = 5

function Tycoon.start(config, Framework, options)
	local settings = config.tycoon
	assert(settings, "config.tycoon não encontrado")
	settings.currencyLabel = config.currencyName
	settings.props = options and options.props or {}

	local Data = Framework.Data
	local Currency = Framework.Currency
	local Monetization = Framework.Monetization
	local Boosts = Framework.Boosts
	local Notify = Framework.Notify
	local Analytics = Framework.Analytics
	local AntiExploit = Framework.AntiExploit

	local stylesByKey = {}
	for _, style in settings.styles do
		stylesByKey[style.key] = style
	end

	local city = City.build(settings)
	local plots = {}
	for index = 1, settings.plotCount do
		plots[index] = Plot.new(index, city.lots[index], settings, city.folder)
	end
	local plotOf: { [Player]: any } = {}
	local pending: { [Player]: number } = {}

	local function ownedCount(data): number
		local count = 0
		for _, upgrade in settings.upgrades do
			if data.upgrades[upgrade.key] then
				count += 1
			end
		end
		return count
	end

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
			Analytics.funnel(player, data, 3, "Primeira coleta")
		end
	end

	local function buy(player: Player, upgrade)
		local data = Data.get(player)
		if not data or data.upgrades[upgrade.key] or nextUpgrade(data) ~= upgrade then
			return
		end
		if not Currency.spend(player, upgrade.cost, "Shop", upgrade.key) then
			local missing = math.ceil(upgrade.cost - Currency.get(player))
			Notify.send(player, string.format("Faltam %d %s", missing, config.currencyName), "error")
			return
		end
		data.upgrades[upgrade.key] = true
		Analytics.funnel(player, data, 4, "Primeira melhoria")
		Notify.send(player, "Nova melhoria: " .. upgrade.name, "success")
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
		Analytics.funnel(player, data, 5, "Primeiro rebirth")
		local bonus = math.floor(data.rebirths * settings.rebirthBonus * 100)
		Notify.send(player, string.format("Rebirth %d! Renda permanente +%d%%", data.rebirths, bonus), "success")
		refresh(player)
	end

	local function teleport(player: Player, cf: CFrame)
		local character = player.Character
		if character and character:FindFirstChild("HumanoidRootPart") then
			AntiExploit.allowTeleport(player, 3)
			character:PivotTo(cf)
		end
	end

	local function spawnAtPlot(player: Player, character: Model)
		if not character:WaitForChild("HumanoidRootPart", 10) then
			return
		end
		-- Espera o Roblox terminar de posicionar o personagem no SpawnLocation, senão ele sobrescreve o nosso.
		if not character.Parent then
			character.AncestryChanged:Wait()
		end
		task.wait(0.1)
		local plot = plotOf[player]
		if plot then
			teleport(player, plot:spawnCFrame())
		end
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
			Notify.send(player, "Todas as pizzarias estão ocupadas neste servidor.", "error")
			return
		end
		plotOf[player] = plot
		pending[player] = 0
		local chosen = stylesByKey[data.style or ""]
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
		}, chosen)
		player:SetAttribute("TycoonPlot", plot.index)
		player:SetAttribute("TycoonNeedsStyle", chosen == nil)
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

	-- Escolha do estilo da pizzaria (uma vez, no primeiro acesso).
	AntiExploit.guard(Remotes.event("TycoonChooseStyle"), {
		perSecond = 2,
		validate = function(key)
			return type(key) == "string" and stylesByKey[key] ~= nil
		end,
	}, function(player, key)
		local data = Data.get(player)
		local plot = plotOf[player]
		if not data or not plot or stylesByKey[data.style or ""] then
			return
		end
		data.style = key
		plot:setStyle(stylesByKey[key])
		player:SetAttribute("TycoonNeedsStyle", false)
		Analytics.funnel(player, data, 2, "Escolheu a pizzaria")
		Notify.send(player, "Bem-vindo à sua " .. stylesByKey[key].name .. "!", "success")
		refresh(player)
	end)

	-- Teleporte: "home" (minha loja), "plaza" (praça) ou o número do terreno de outro jogador.
	AntiExploit.guard(Remotes.event("TycoonTeleport"), {
		perSecond = 1,
		validate = function(target)
			return target == "home" or target == "plaza" or (type(target) == "number" and plots[target] ~= nil)
		end,
	}, function(player, target)
		if target == "plaza" then
			teleport(player, city.plazaSpawn)
		elseif target == "home" then
			local plot = plotOf[player]
			if plot then
				teleport(player, plot:spawnCFrame())
			end
		else
			teleport(player, plots[target]:spawnCFrame())
		end
	end)

	-- Blocos de teleporte no mapa (qualquer jogador pode usar).
	local lastPadUse: { [Player]: number } = {}
	local function padTouched(hit: BasePart, action: (Player) -> ())
		local character = hit:FindFirstAncestorOfClass("Model")
		local player = character and Players:GetPlayerFromCharacter(character)
		if player and os.clock() - (lastPadUse[player] or 0) > 2 then
			lastPadUse[player] = os.clock()
			action(player)
		end
	end
	city.homePad.Touched:Connect(function(hit)
		padTouched(hit, function(player)
			local plot = plotOf[player]
			if plot then
				teleport(player, plot:spawnCFrame())
			end
		end)
	end)
	for _, plot in plots do
		plot.plazaPad.Touched:Connect(function(hit)
			padTouched(hit, function(player)
				teleport(player, city.plazaSpawn)
			end)
		end)
	end
	Players.PlayerRemoving:Connect(function(player)
		lastPadUse[player] = nil
	end)

	-- Passes e boosts mudam a renda mostrada no caixa.
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

	-- Clientes: mais melhorias = mais clientes. Cada um paga alguns segundos da renda.
	Customers.start(plots, {
		interval = function(plot)
			local data = plot.owner and Data.get(plot.owner)
			local owned = if data then ownedCount(data) else 0
			return math.max(3, settings.customerInterval - owned * 0.6)
		end,
		maxActive = function(plot)
			local data = plot.owner and Data.get(plot.owner)
			local owned = if data then ownedCount(data) else 0
			return 2 + owned // 3
		end,
		onServed = function(plot)
			local player = plot.owner
			if not player or not pending[player] then
				return nil
			end
			local tip = math.max(1, math.floor(incomePerSecond(player) * settings.customerTipSeconds))
			pending[player] += tip
			return tip
		end,
	})

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
