-- Game Passes e Developer Products.
-- * Toda compra com Robux é confirmada no servidor (ProcessReceipt) e registrada nos dados,
--   então o jogador nunca recebe duas vezes nem perde o que pagou.
-- * Passes possuídos viram o atributo "Pass_<chave>" no jogador, para a interface.
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")

local Data = require(script.Parent.Data)
local Currency = require(script.Parent.Currency)
local Boosts = require(script.Parent.Boosts)
local Notify = require(script.Parent.Notify)
local Analytics = require(script.Parent.Analytics)

local MAX_RECEIPTS_KEPT = 100

local Monetization = {}

type Product = {
	key: string,
	id: number,
	name: string,
	kind: string,
	amount: number?,
	boostKey: string?,
	durationSeconds: number?,
}
type Pass = { key: string, id: number, name: string }

local productsById: { [number]: Product } = {}
local passesByKey: { [string]: Pass } = {}
local passesById: { [number]: Pass } = {}
local ownedCache: { [Player]: { [string]: boolean } } = {}
local passCallbacks: { [string]: { (Player) -> () } } = {}
local productHandlers: { [string]: (Player, Product) -> boolean } = {}

local function setOwned(player: Player, pass: Pass)
	ownedCache[player] = ownedCache[player] or {}
	if ownedCache[player][pass.key] then
		return
	end
	ownedCache[player][pass.key] = true
	player:SetAttribute("Pass_" .. pass.key, true)
	for _, callback in passCallbacks[pass.key] or {} do
		task.spawn(callback, player)
	end
end

local function checkPasses(player: Player)
	for _, pass in passesByKey do
		if pass.id ~= 0 then
			local ok, owns = pcall(function()
				return MarketplaceService:UserOwnsGamePassAsync(player.UserId, pass.id)
			end)
			if ok and owns then
				setOwned(player, pass)
			end
		end
	end
end

local function grant(player: Player, product: Product): boolean
	local custom = productHandlers[product.key]
	if custom then
		return custom(player, product)
	end
	if product.kind == "currency" then
		return Currency.add(player, product.amount or 0, "IAP", product.key)
	elseif product.kind == "boost" then
		return Boosts.activate(player, product.boostKey or product.key, product.durationSeconds or 900)
	end
	warn("[Monetization] Produto sem tratamento: " .. product.key)
	return false
end

local function processReceipt(receipt): Enum.ProductPurchaseDecision
	local player = Players:GetPlayerByUserId(receipt.PlayerId)
	if not player then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local data = Data.waitFor(player)
	if not data then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	data.receipts = data.receipts or {}
	for _, id in data.receipts do
		if id == receipt.PurchaseId then
			return Enum.ProductPurchaseDecision.PurchaseGranted -- já entregue antes
		end
	end

	local product = productsById[receipt.ProductId]
	if not product then
		warn("[Monetization] Produto desconhecido: " .. tostring(receipt.ProductId))
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local ok, granted = pcall(grant, player, product)
	if not ok or not granted then
		warn("[Monetization] Falha ao entregar " .. product.key .. ": " .. tostring(granted))
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	table.insert(data.receipts, receipt.PurchaseId)
	while #data.receipts > MAX_RECEIPTS_KEPT do
		table.remove(data.receipts, 1)
	end
	data.robuxSpent = (data.robuxSpent or 0) + (receipt.CurrencySpent or 0)

	-- Salva já. Se falhar, o recibo continua na memória e o salvamento automático tenta de novo;
	-- o Roblox reenviaria o recibo, mas ele já está na lista e não é entregue duas vezes.
	Data.saveNow(player)
	Analytics.custom(player, "RobuxPurchase_" .. product.key, receipt.CurrencySpent)
	Notify.send(player, "Compra recebida: " .. product.name, "success")
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

function Monetization.start(passes: { Pass }, products: { Product })
	for _, pass in passes do
		passesByKey[pass.key] = pass
		if pass.id ~= 0 then
			passesById[pass.id] = pass
		end
	end
	for _, product in products do
		if product.id ~= 0 then
			productsById[product.id] = product
		end
	end

	MarketplaceService.ProcessReceipt = processReceipt

	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, purchased)
		local pass = passesById[passId]
		if purchased and pass then
			setOwned(player, pass)
			Analytics.custom(player, "GamePass_" .. pass.key)
			Notify.send(player, "Passe ativado: " .. pass.name, "success")
		end
	end)

	Players.PlayerAdded:Connect(checkPasses)
	for _, player in Players:GetPlayers() do
		task.spawn(checkPasses, player)
	end
	Players.PlayerRemoving:Connect(function(player)
		ownedCache[player] = nil
	end)
end

function Monetization.ownsPass(player: Player, key: string): boolean
	local owned = ownedCache[player]
	return owned ~= nil and owned[key] == true
end

-- Chama `callback(player)` quando o jogador tem o passe (ao entrar ou ao comprar na hora).
function Monetization.onPass(key: string, callback: (Player) -> ())
	passCallbacks[key] = passCallbacks[key] or {}
	table.insert(passCallbacks[key], callback)
	for player, owned in ownedCache do
		if owned[key] then
			task.spawn(callback, player)
		end
	end
end

-- Substitui a entrega padrão de um produto (ex.: "pular etapa" específico do jogo).
-- O handler deve retornar true se entregou.
function Monetization.setProductHandler(key: string, handler: (Player, Product) -> boolean)
	productHandlers[key] = handler
end

return Monetization
