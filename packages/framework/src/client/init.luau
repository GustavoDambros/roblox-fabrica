-- Framework compartilhado (lado do cliente): HUD de moeda, loja e avisos.
-- Uso num LocalScript do jogo:
--   require(ReplicatedStorage.FrameworkClient).start(require(ReplicatedStorage.GameConfig))
local Players = game:GetService("Players")

local Hud = require(script.Hud)
local Shop = require(script.Shop)
local Toasts = require(script.Toasts)

local FrameworkClient = {
	Toasts = Toasts,
}

function FrameworkClient.start(config)
	local player = Players.LocalPlayer
	local gui = Instance.new("ScreenGui")
	gui.Name = "Framework"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = player:WaitForChild("PlayerGui")

	Toasts.start(gui)
	local openShop = Shop.start(gui, config)
	Hud.start(gui, config, openShop)
end

return FrameworkClient
