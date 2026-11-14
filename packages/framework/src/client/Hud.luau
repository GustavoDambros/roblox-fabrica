-- HUD: saldo da moeda, botão da loja e boosts ativos com tempo restante.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Format = require(ReplicatedStorage:WaitForChild("FrameworkShared"):WaitForChild("Format"))
local Style = require(script.Parent.Style)

local Hud = {}

function Hud.start(gui: ScreenGui, config, openShop: () -> ())
	local player = Players.LocalPlayer

	local frame = Instance.new("Frame")
	frame.Name = "Hud"
	frame.AnchorPoint = Vector2.new(0, 0.5)
	frame.Position = UDim2.new(0, 12, 0.5, 0)
	frame.Size = UDim2.new(0, 210, 0, 0)
	frame.AutomaticSize = Enum.AutomaticSize.Y
	frame.BackgroundTransparency = 1
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 8)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = frame
	frame.Parent = gui

	local balance = Instance.new("Frame")
	balance.Size = UDim2.new(1, 0, 0, 48)
	balance.BackgroundColor3 = Style.background
	balance.BackgroundTransparency = 0.15
	balance.LayoutOrder = 1
	Style.corner(balance)
	balance.Parent = frame
	local balanceLabel = Style.label(balance, "", 22, true)
	balanceLabel.Size = UDim2.new(1, -24, 1, 0)
	balanceLabel.Position = UDim2.new(0, 12, 0, 0)
	balanceLabel.TextColor3 = Style.gold

	local function refreshBalance()
		local value = player:GetAttribute("Currency") or 0
		balanceLabel.Text = Format.abbreviate(value) .. " " .. config.currencyName
	end
	player:GetAttributeChangedSignal("Currency"):Connect(refreshBalance)
	refreshBalance()

	local shopButton = Style.button(frame, "LOJA", Style.gold)
	shopButton.Size = UDim2.new(1, 0, 0, 48)
	shopButton.TextColor3 = Style.background
	shopButton.TextSize = 22
	shopButton.LayoutOrder = 2
	shopButton.Activated:Connect(openShop)

	local boosts = Style.label(frame, "", 16, true)
	boosts.Size = UDim2.new(1, 0, 0, 0)
	boosts.AutomaticSize = Enum.AutomaticSize.Y
	boosts.LayoutOrder = 3
	boosts.TextColor3 = Style.accent

	task.spawn(function()
		while gui.Parent do
			local lines = {}
			local now = workspace:GetServerTimeNow()
			for name, value in player:GetAttributes() do
				local key = string.match(name, "^Boost_(.+)$")
				if key and type(value) == "number" and value > now then
					table.insert(lines, string.format("%s: %s", key, Format.duration(value - now)))
				end
			end
			boosts.Text = table.concat(lines, "\n")
			task.wait(1)
		end
	end)
end

return Hud
