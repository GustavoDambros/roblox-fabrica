-- Loja: lista Game Passes e Developer Products da configuração do jogo.
-- Itens com id = 0 (ainda não criados no Creator Dashboard) ficam escondidos.
-- A compra é só um pedido ao Roblox; quem entrega é o servidor (Monetization).
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")

local Style = require(script.Parent.Style)

local Shop = {}

local function fetchPrice(id: number, infoType: Enum.InfoType, label: TextButton, owned: boolean)
	if owned then
		label.Text = "Comprado"
		return
	end
	task.spawn(function()
		local ok, info = pcall(function()
			return MarketplaceService:GetProductInfo(id, infoType)
		end)
		if ok and info and info.PriceInRobux then
			label.Text = "R$ " .. tostring(info.PriceInRobux)
		else
			label.Text = "Comprar"
		end
	end)
end

local function addItem(list: Frame, order: number, title: string, description: string?): (Frame, TextButton)
	local item = Instance.new("Frame")
	item.Size = UDim2.new(1, 0, 0, 72)
	item.BackgroundColor3 = Style.panel
	item.LayoutOrder = order
	Style.corner(item)
	item.Parent = list

	local name = Style.label(item, title, 20, true)
	name.Position = UDim2.new(0, 14, 0, 8)
	name.Size = UDim2.new(1, -150, 0, 26)

	local info = Style.label(item, description or "", 15)
	info.TextColor3 = Style.muted
	info.Position = UDim2.new(0, 14, 0, 36)
	info.Size = UDim2.new(1, -150, 0, 30)

	local buy = Style.button(item, "...")
	buy.AnchorPoint = Vector2.new(1, 0.5)
	buy.Position = UDim2.new(1, -12, 0.5, 0)
	buy.Size = UDim2.new(0, 120, 0, 44)
	return item, buy
end

local function addHeader(list: Frame, order: number, text: string)
	local header = Style.label(list, text, 22, true)
	header.Size = UDim2.new(1, 0, 0, 30)
	header.TextColor3 = Style.gold
	header.LayoutOrder = order
end

-- Monta a loja e retorna a função que abre/fecha.
function Shop.start(gui: ScreenGui, config): () -> ()
	local player = Players.LocalPlayer

	local panel = Instance.new("Frame")
	panel.Name = "Shop"
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.new(0.5, 0, 0.5, 0)
	panel.Size = UDim2.new(0.9, 0, 0.8, 0)
	panel.BackgroundColor3 = Style.background
	panel.Visible = false
	Style.corner(panel, 14)
	local sizeLimit = Instance.new("UISizeConstraint")
	sizeLimit.MaxSize = Vector2.new(560, 600)
	sizeLimit.Parent = panel
	panel.Parent = gui

	local title = Style.label(panel, "Loja", 28, true)
	title.Position = UDim2.new(0, 18, 0, 10)
	title.Size = UDim2.new(1, -80, 0, 40)

	local close = Style.button(panel, "X", Style.error)
	close.AnchorPoint = Vector2.new(1, 0)
	close.Position = UDim2.new(1, -12, 0, 12)
	close.Size = UDim2.new(0, 40, 0, 40)
	close.Activated:Connect(function()
		panel.Visible = false
	end)

	local list = Instance.new("ScrollingFrame")
	list.Position = UDim2.new(0, 14, 0, 62)
	list.Size = UDim2.new(1, -28, 1, -76)
	list.BackgroundTransparency = 1
	list.BorderSizePixel = 0
	list.ScrollBarThickness = 6
	list.CanvasSize = UDim2.new()
	list.AutomaticCanvasSize = Enum.AutomaticSize.Y
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 8)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = list
	list.Parent = panel

	local order = 0
	local function nextOrder(): number
		order += 1
		return order
	end

	local visibleProducts = {}
	for _, product in config.products or {} do
		if product.id ~= 0 then
			table.insert(visibleProducts, product)
		end
	end
	local visiblePasses = {}
	for _, pass in config.passes or {} do
		if pass.id ~= 0 then
			table.insert(visiblePasses, pass)
		end
	end

	if #visibleProducts > 0 then
		addHeader(list, nextOrder(), "Ofertas")
		for _, product in visibleProducts do
			local _, buy = addItem(list, nextOrder(), product.name, product.description)
			fetchPrice(product.id, Enum.InfoType.Product, buy, false)
			buy.Activated:Connect(function()
				MarketplaceService:PromptProductPurchase(player, product.id)
			end)
		end
	end

	if #visiblePasses > 0 then
		addHeader(list, nextOrder(), "Passes permanentes")
		for _, pass in visiblePasses do
			local _, buy = addItem(list, nextOrder(), pass.name, pass.description)
			local attribute = "Pass_" .. pass.key
			fetchPrice(pass.id, Enum.InfoType.GamePass, buy, player:GetAttribute(attribute) == true)
			player:GetAttributeChangedSignal(attribute):Connect(function()
				if player:GetAttribute(attribute) then
					buy.Text = "Comprado"
					buy.BackgroundColor3 = Style.panel
				end
			end)
			buy.Activated:Connect(function()
				if not player:GetAttribute(attribute) then
					MarketplaceService:PromptGamePassPurchase(player, pass.id)
				end
			end)
		end
	end

	if #visibleProducts + #visiblePasses == 0 then
		local empty = Style.label(
			list,
			"Nenhum item à venda ainda. Crie os passes e produtos no Creator Dashboard e coloque os IDs no config.luau.",
			17
		)
		empty.Size = UDim2.new(1, 0, 0, 80)
		empty.TextColor3 = Style.muted
		empty.LayoutOrder = nextOrder()
	end

	return function()
		panel.Visible = not panel.Visible
	end
end

return Shop
