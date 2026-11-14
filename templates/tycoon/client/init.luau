-- Interface do tycoon: escolha do estilo da loja no primeiro acesso e menu de teleporte
-- (minha loja, praça e visitar a loja de outros jogadores).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage:WaitForChild("FrameworkShared"):WaitForChild("Remotes"))
local Style = require(ReplicatedStorage:WaitForChild("FrameworkClient"):WaitForChild("Style"))

local TycoonClient = {}

local player = Players.LocalPlayer

local function buildStylePicker(gui: ScreenGui, config)
	local chooseRemote = Remotes.event("TycoonChooseStyle")
	local styles = config.tycoon.styles

	local overlay = Instance.new("Frame")
	overlay.Name = "EscolhaDeEstilo"
	overlay.Size = UDim2.fromScale(1, 1)
	overlay.BackgroundColor3 = Color3.new(0, 0, 0)
	overlay.BackgroundTransparency = 0.35
	overlay.Visible = false
	overlay.ZIndex = 10
	overlay.Parent = gui

	local title = Style.label(overlay, "Escolha sua pizzaria", 34, true)
	title.AnchorPoint = Vector2.new(0.5, 0)
	title.Position = UDim2.new(0.5, 0, 0.12, 0)
	title.Size = UDim2.new(0.9, 0, 0, 44)
	title.TextXAlignment = Enum.TextXAlignment.Center
	title.ZIndex = 11

	local row = Instance.new("Frame")
	row.AnchorPoint = Vector2.new(0.5, 0.5)
	row.Position = UDim2.fromScale(0.5, 0.55)
	row.Size = UDim2.new(0.92, 0, 0, 300)
	row.BackgroundTransparency = 1
	row.ZIndex = 11
	row.Parent = overlay
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.Padding = UDim.new(0, 16)
	layout.Parent = row

	for index, style in styles do
		local card = Instance.new("Frame")
		card.Size = UDim2.new(0, 240, 1, 0)
		card.BackgroundColor3 = Style.background
		card.LayoutOrder = index
		card.ZIndex = 11
		Style.corner(card, 14)
		card.Parent = row

		local preview = Instance.new("Frame")
		preview.Position = UDim2.new(0, 12, 0, 12)
		preview.Size = UDim2.new(1, -24, 0, 110)
		preview.BackgroundColor3 = style.wallColor
		preview.ZIndex = 12
		Style.corner(preview, 10)
		preview.Parent = card
		local awning = Instance.new("Frame")
		awning.Position = UDim2.new(0, 0, 0, 0)
		awning.Size = UDim2.new(1, 0, 0, 26)
		awning.BackgroundColor3 = style.accentColor
		awning.ZIndex = 13
		Style.corner(awning, 10)
		awning.Parent = preview
		local sign = Style.label(preview, style.name, 18, true)
		sign.AnchorPoint = Vector2.new(0.5, 0.5)
		sign.Position = UDim2.fromScale(0.5, 0.62)
		sign.Size = UDim2.new(0.9, 0, 0, 34)
		sign.BackgroundTransparency = 0
		sign.BackgroundColor3 = style.signColor
		sign.TextColor3 = style.signTextColor
		sign.TextXAlignment = Enum.TextXAlignment.Center
		sign.ZIndex = 13
		Style.corner(sign, 6)

		local name = Style.label(card, style.name, 22, true)
		name.Position = UDim2.new(0, 14, 0, 132)
		name.Size = UDim2.new(1, -28, 0, 28)
		name.ZIndex = 12
		local description = Style.label(card, style.description or "", 16)
		description.Position = UDim2.new(0, 14, 0, 164)
		description.Size = UDim2.new(1, -28, 0, 60)
		description.TextColor3 = Style.muted
		description.TextYAlignment = Enum.TextYAlignment.Top
		description.ZIndex = 12

		local choose = Style.button(card, "ESCOLHER")
		choose.AnchorPoint = Vector2.new(0.5, 1)
		choose.Position = UDim2.new(0.5, 0, 1, -12)
		choose.Size = UDim2.new(1, -24, 0, 48)
		choose.ZIndex = 12
		choose.Activated:Connect(function()
			chooseRemote:FireServer(style.key)
		end)
	end

	local function refresh()
		overlay.Visible = player:GetAttribute("TycoonNeedsStyle") == true
	end
	player:GetAttributeChangedSignal("TycoonNeedsStyle"):Connect(refresh)
	refresh()
end

local function buildTeleportMenu(gui: ScreenGui)
	local teleportRemote = Remotes.event("TycoonTeleport")

	local frame = Instance.new("Frame")
	frame.Name = "Teleporte"
	frame.AnchorPoint = Vector2.new(1, 0.5)
	frame.Position = UDim2.new(1, -12, 0.5, 0)
	frame.Size = UDim2.new(0, 190, 0, 0)
	frame.AutomaticSize = Enum.AutomaticSize.Y
	frame.BackgroundTransparency = 1
	frame.Parent = gui
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 8)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = frame

	local function menuButton(text: string, order: number, color: Color3?): TextButton
		local button = Style.button(frame, text, color or Style.panel)
		button.Size = UDim2.new(1, 0, 0, 44)
		button.LayoutOrder = order
		return button
	end

	menuButton("Minha pizzaria", 1, Style.accent).Activated:Connect(function()
		teleportRemote:FireServer("home")
	end)
	menuButton("Praça", 2).Activated:Connect(function()
		teleportRemote:FireServer("plaza")
	end)
	local visit = menuButton("Visitar", 3)

	local list = Instance.new("Frame")
	list.Size = UDim2.new(1, 0, 0, 0)
	list.AutomaticSize = Enum.AutomaticSize.Y
	list.BackgroundTransparency = 1
	list.LayoutOrder = 4
	list.Visible = false
	list.Parent = frame
	local listLayout = Instance.new("UIListLayout")
	listLayout.Padding = UDim.new(0, 6)
	listLayout.Parent = list

	local function rebuildList()
		for _, child in list:GetChildren() do
			if child:IsA("TextButton") or child:IsA("TextLabel") then
				child:Destroy()
			end
		end
		local count = 0
		for _, other in Players:GetPlayers() do
			local plotIndex = other:GetAttribute("TycoonPlot")
			if other ~= player and type(plotIndex) == "number" then
				count += 1
				local button = Style.button(list, other.DisplayName, Style.background)
				button.Size = UDim2.new(1, 0, 0, 38)
				button.TextSize = 16
				button.Activated:Connect(function()
					teleportRemote:FireServer(plotIndex)
					list.Visible = false
				end)
			end
		end
		if count == 0 then
			local empty = Style.label(list, "Ninguém mais no servidor", 15)
			empty.Size = UDim2.new(1, 0, 0, 30)
			empty.TextXAlignment = Enum.TextXAlignment.Center
			empty.TextColor3 = Style.muted
		end
	end

	visit.Activated:Connect(function()
		list.Visible = not list.Visible
		if list.Visible then
			rebuildList()
		end
	end)
end

function TycoonClient.start(config)
	local gui = Instance.new("ScreenGui")
	gui.Name = "Tycoon"
	gui.DisplayOrder = 5
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = player:WaitForChild("PlayerGui")

	buildTeleportMenu(gui)
	buildStylePicker(gui, config)
end

return TycoonClient
