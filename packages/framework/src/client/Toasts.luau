-- Avisos rápidos no topo da tela, enviados pelo servidor (Notify) ou pelo próprio cliente.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Remotes = require(ReplicatedStorage:WaitForChild("FrameworkShared"):WaitForChild("Remotes"))
local Style = require(script.Parent.Style)

local Toasts = {}

local container: Frame? = nil

local COLORS = {
	info = Style.panel,
	success = Style.accent,
	error = Style.error,
}

function Toasts.show(text: string, kind: string?)
	if not container then
		return
	end
	local toast = Instance.new("TextLabel")
	toast.Size = UDim2.new(1, 0, 0, 40)
	toast.BackgroundColor3 = COLORS[kind or "info"] or Style.panel
	toast.Text = text
	toast.TextSize = 18
	toast.Font = Style.font
	toast.TextColor3 = Style.text
	Style.corner(toast, 8)
	toast.Parent = container
	task.delay(3, function()
		local tween =
			TweenService:Create(toast, TweenInfo.new(0.4), { BackgroundTransparency = 1, TextTransparency = 1 })
		tween:Play()
		tween.Completed:Wait()
		toast:Destroy()
	end)
end

function Toasts.start(gui: ScreenGui)
	local frame = Instance.new("Frame")
	frame.Name = "Toasts"
	frame.AnchorPoint = Vector2.new(0.5, 0)
	frame.Position = UDim2.new(0.5, 0, 0, 12)
	frame.Size = UDim2.new(0, 360, 0, 200)
	frame.BackgroundTransparency = 1
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 6)
	layout.Parent = frame
	frame.Parent = gui
	container = frame

	Remotes.event("Notify").OnClientEvent:Connect(Toasts.show)
end

return Toasts
