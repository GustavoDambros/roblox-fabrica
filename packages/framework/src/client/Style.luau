-- Cores e helpers de interface usados pelo framework.
local Style = {
	background = Color3.fromRGB(24, 26, 32),
	panel = Color3.fromRGB(36, 39, 48),
	accent = Color3.fromRGB(0, 170, 90),
	gold = Color3.fromRGB(255, 196, 0),
	text = Color3.fromRGB(240, 240, 240),
	muted = Color3.fromRGB(170, 175, 185),
	error = Color3.fromRGB(220, 70, 70),
	font = Enum.Font.GothamBold,
	fontRegular = Enum.Font.Gotham,
}

function Style.corner(parent: Instance, radius: number?)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius or 10)
	corner.Parent = parent
end

function Style.label(parent: Instance, text: string, size: number, bold: boolean?): TextLabel
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextSize = size
	label.Font = if bold then Style.font else Style.fontRegular
	label.TextColor3 = Style.text
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextWrapped = true
	label.Parent = parent
	return label
end

function Style.button(parent: Instance, text: string, color: Color3?): TextButton
	local button = Instance.new("TextButton")
	button.AutoButtonColor = true
	button.BackgroundColor3 = color or Style.accent
	button.Text = text
	button.TextSize = 18
	button.Font = Style.font
	button.TextColor3 = Style.text
	Style.corner(button, 8)
	button.Parent = parent
	return button
end

return Style
