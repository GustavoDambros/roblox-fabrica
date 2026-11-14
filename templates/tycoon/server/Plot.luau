-- Terreno de um jogador: a loja já construída (paredes, vitrine, toldo, letreiro, balcão), o caixa
-- onde o dinheiro acumula, os botões de compra e as melhorias (objetos montados por `settings.props`).
--
-- Coordenadas locais do terreno: frente = -Z (rua), fundo = +Z. A loja ocupa o fundo; a frente é o pátio.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local TweenService = game:GetService("TweenService")

local Format = require(ReplicatedStorage:WaitForChild("FrameworkShared"):WaitForChild("Format"))
local Builder = require(ServerScriptService:WaitForChild("Framework"):WaitForChild("Builder"))

local Plot = {}
Plot.__index = Plot

local TOUCH_COOLDOWN = 0.75
local WALL_HEIGHT = 20
local WALL = 1.2
local FLOOR_TOP = 0.8
local SLOT_X = { -24, -8, 8, 24 }
local SLOT_Z = { 8, 21, 34 }
local WHITE = Color3.fromRGB(245, 245, 240)

local function playerFromHit(hit: BasePart): Player?
	local character = hit:FindFirstAncestorOfClass("Model")
	return character and Players:GetPlayerFromCharacter(character)
end

function Plot.new(index: number, origin: CFrame, settings, parent: Instance)
	local self = setmetatable({}, Plot)
	self.index = index
	self.settings = settings
	self.origin = origin
	self.owner = nil :: Player?
	self.callbacks = nil
	self.lastTouch = 0
	self.style = settings.styles[1]

	local model = Builder.model("Pizzaria" .. index, parent)
	self.model = model

	local size = settings.plotSize
	Builder.block(
		model,
		Vector3.new(size, 0.4, size),
		origin * CFrame.new(0, 0.2, 0),
		Color3.fromRGB(200, 198, 192),
		Enum.Material.Concrete
	)

	self.shell = Builder.model("Loja", model)
	self.props = Builder.model("Melhorias", model)
	self.customers = Builder.model("Clientes", model)

	local collector = Builder.block(
		model,
		Vector3.new(6, 0.3, 5),
		self:at(-26, FLOOR_TOP + 0.15, -2.5),
		Color3.fromRGB(255, 196, 0),
		Enum.Material.Neon
	)
	collector.Name = "Caixa"
	self.collector = collector
	self.collectorLabel = Builder.billboard(collector, "", 4.5, 240)

	local rebirth = Builder.block(
		model,
		Vector3.new(7, 0.3, 7),
		self:at(27, FLOOR_TOP + 0.15, -9),
		Color3.fromRGB(150, 70, 255),
		Enum.Material.Neon
	)
	rebirth.Name = "Rebirth"
	rebirth.Transparency = 1
	rebirth.CanTouch = false
	self.rebirthPad = rebirth
	self.rebirthLabel = Builder.billboard(rebirth, "", 4.5, 240)

	local pad = Builder.block(
		model,
		Vector3.new(10, 0.3, 10),
		self:at(0, FLOOR_TOP + 0.15, 0),
		Color3.fromRGB(0, 210, 100),
		Enum.Material.Neon
	)
	pad.Name = "Comprar"
	pad.Transparency = 1
	pad.CanTouch = false
	self.pad = pad
	self.padLabel = Builder.billboard(pad, "", 6, 280)
	self.padUpgrade = nil

	local plazaPad = Builder.block(
		model,
		Vector3.new(8, 0.3, 8),
		self:at(36, 0.55, -40),
		Color3.fromRGB(40, 140, 255),
		Enum.Material.Neon
	)
	plazaPad.Name = "IrParaPraca"
	self.plazaPad = plazaPad
	Builder.billboard(plazaPad, "Ir para a praça", 4.5, 220)

	self:buildShell()

	collector.Touched:Connect(function(hit)
		if self:ownerTouch(hit) then
			self.callbacks.onCollect()
		end
	end)
	pad.Touched:Connect(function(hit)
		if self.padUpgrade and self:ownerTouch(hit) then
			self.callbacks.onBuy(self.padUpgrade)
		end
	end)
	rebirth.Touched:Connect(function(hit)
		if rebirth.CanTouch and self:ownerTouch(hit) then
			self.callbacks.onRebirth()
		end
	end)

	return self
end

-- CFrame de um ponto em coordenadas locais do terreno.
function Plot:at(x: number, y: number, z: number): CFrame
	return self.origin * CFrame.new(x, y, z)
end

function Plot:ownerTouch(hit: BasePart): boolean
	local player = playerFromHit(hit)
	if not player or player ~= self.owner or not self.callbacks then
		return false
	end
	local now = os.clock()
	if now - self.lastTouch < TOUCH_COOLDOWN then
		return false
	end
	self.lastTouch = now
	return true
end

-- Prédio da pizzaria no estilo escolhido. Refeito quando o estilo muda.
function Plot:buildShell()
	local shell = self.shell
	shell:ClearAllChildren()
	local style = self.style
	local wallColor, wallMaterial = style.wallColor, style.wallMaterial
	local h = WALL_HEIGHT
	local glass = Color3.fromRGB(170, 210, 235)

	-- Piso e paredes (fundo e laterais).
	local floorSize = Vector3.new(74.6, 0.4, 58.6)
	Builder.block(shell, floorSize, self:at(0, 0.6, 12), style.floorColor, style.floorMaterial)
	Builder.box(shell, Vector3.new(76, h, WALL), self:at(0, 0.4, 41.4), wallColor, wallMaterial)
	Builder.box(shell, Vector3.new(WALL, h, 60), self:at(-37.4, 0.4, 12), wallColor, wallMaterial)
	Builder.box(shell, Vector3.new(WALL, h, 60), self:at(37.4, 0.4, 12), wallColor, wallMaterial)

	-- Fachada: vitrines dos dois lados da porta e toldo listrado.
	for _, side in { -1, 1 } do
		local x = side * 21.5
		Builder.box(shell, Vector3.new(33, 3, WALL), self:at(x, 0.4, -17.4), style.trimColor, wallMaterial)
		local window = Builder.box(shell, Vector3.new(33, 10, 0.5), self:at(x, 3.4, -17.4), glass, Enum.Material.Glass)
		window.Transparency = 0.45
		Builder.box(shell, Vector3.new(33, h - 13, WALL), self:at(x, 13.4, -17.4), wallColor, wallMaterial)
		for stripe = 0, 5 do
			local color = if stripe % 2 == 0 then style.accentColor else WHITE
			local stripeX = x - 16.5 + 2.75 + stripe * 5.5
			Builder.wedge(shell, Vector3.new(5.5, 2.5, 4), self:at(stripeX, 14.6, -20), color, Enum.Material.Fabric)
		end
	end
	Builder.box(shell, Vector3.new(10, h - 12, WALL), self:at(0, 12.4, -17.4), wallColor, wallMaterial)

	-- Teto, luzes e letreiro.
	Builder.block(shell, Vector3.new(78, 1, 62), self:at(0, h + 0.9, 12), style.roofColor, Enum.Material.Concrete)
	for _, x in { -20, 0, 20 } do
		local panel = Builder.block(shell, Vector3.new(8, 0.3, 8), self:at(x, h + 0.25, 16), WHITE, Enum.Material.Neon)
		Builder.light(panel, Color3.fromRGB(255, 235, 200), 32, 1.2)
	end
	local board = Builder.block(
		shell,
		Vector3.new(46, 8, 1),
		self:at(0, h + 5.5, -18.2),
		style.signColor,
		Enum.Material.SmoothPlastic
	)
	self.signLabel = Builder.sign(board, Enum.NormalId.Front, "", style.signTextColor)
	local glow = Builder.block(
		shell,
		Vector3.new(47, 0.5, 1.2),
		self:at(0, h + 1.3, -18.2),
		style.accentColor,
		Enum.Material.Neon
	)
	Builder.light(glow, style.accentColor, 16, 1)

	-- Cardápio na parede do fundo.
	local menu = Builder.block(
		shell,
		Vector3.new(22, 9, 0.4),
		self:at(0, 11, 40.6),
		Color3.fromRGB(30, 30, 30),
		Enum.Material.SmoothPlastic
	)
	local menuText = "CARDÁPIO\nMarguerita · Calabresa\nQuatro Queijos · Portuguesa"
	Builder.sign(menu, Enum.NormalId.Front, menuText, Color3.fromRGB(255, 230, 160), Enum.Font.GothamBold)

	-- Balcão com caixa registradora (o jogador fica atrás, no tapete amarelo).
	Builder.box(shell, Vector3.new(16, 3.8, 4), self:at(-26, FLOOR_TOP, -8), style.counterColor, Enum.Material.Wood)
	Builder.box(shell, Vector3.new(16.6, 0.4, 4.6), self:at(-26, FLOOR_TOP + 3.8, -8), WHITE, Enum.Material.Marble)
	local register =
		Builder.box(shell, Vector3.new(3, 2, 2.4), self:at(-22, FLOOR_TOP + 4.2, -8), Color3.fromRGB(40, 40, 45))
	register.Material = Enum.Material.Metal
	local pizza = Builder.cylinder(shell, 0.3, 3.2, self:at(-29, FLOOR_TOP + 4.4, -8), Color3.fromRGB(235, 170, 70))
	pizza.Material = Enum.Material.Sand

	-- Pátio: árvores, poste e mesas com guarda-sol.
	for _, side in { -1, 1 } do
		Builder.tree(shell, self:at(side * 42, 0.4, -42), 0.9, side + 2)
		local patio = Builder.model("MesaExterna", shell)
		local base = self:at(side * 24, 0.4, -30)
		Builder.cylinder(patio, 3, 0.4, base * CFrame.new(0, 1.5, 0), Color3.fromRGB(60, 60, 60), Enum.Material.Metal)
		Builder.cylinder(patio, 0.3, 5, base * CFrame.new(0, 3.1, 0), WHITE, Enum.Material.SmoothPlastic)
		Builder.cylinder(patio, 7, 0.3, base * CFrame.new(0, 6.5, 0), Color3.fromRGB(60, 60, 60), Enum.Material.Metal)
		Builder.cylinder(patio, 0.6, 11, base * CFrame.new(0, 10, 0), style.accentColor, Enum.Material.Fabric)
	end
	Builder.lamp(shell, self:at(-44, 0.4, -24) * CFrame.Angles(0, math.pi / 2, 0))

	self:updateSign()
end

function Plot:updateSign()
	if not self.signLabel then
		return
	end
	if self.owner then
		self.signLabel.Text = string.format("%s\n%s", self.style.name, self.owner.DisplayName)
	else
		self.signLabel.Text = "À VENDA"
	end
end

function Plot:slotCFrame(slot: number): CFrame
	local column = (slot - 1) % #SLOT_X + 1
	local row = (slot - 1) // #SLOT_X + 1
	return self:at(SLOT_X[column], FLOOR_TOP, SLOT_Z[row])
end

-- Onde o jogador aparece: no pátio, olhando para a porta.
function Plot:spawnCFrame(): CFrame
	return self:at(0, 4, -30) * CFrame.Angles(0, math.pi, 0)
end

-- Caminho dos clientes: entrada pela calçada, porta, balcão, e saída pelo outro lado.
function Plot:customerPath(fromLeft: boolean)
	local side = if fromLeft then -1 else 1
	return {
		start = self:at(side * 40, 3, -46).Position,
		door = self:at(0, 3, -24).Position,
		inside = self:at(0, 3, -13).Position,
		counter = self:at(-26, 3, -13).Position,
		exit = self:at(-side * 40, 3, -46).Position,
	}
end

function Plot:claim(player: Player, callbacks, style)
	self.owner = player
	self.callbacks = callbacks
	self:setStyle(style)
end

function Plot:setStyle(style)
	if style and style ~= self.style then
		self.style = style
		self:buildShell()
	end
	self:updateSign()
end

function Plot:release()
	self.owner = nil
	self.callbacks = nil
	self.collectorLabel.Text = ""
	self.props:ClearAllChildren()
	self.customers:ClearAllChildren()
	self.padUpgrade = nil
	self.pad.Transparency = 1
	self.pad.CanTouch = false
	self.padLabel.Text = ""
	self.rebirthPad.Transparency = 1
	self.rebirthPad.CanTouch = false
	self.rebirthLabel.Text = ""
	self.style = self.settings.styles[1]
	self:buildShell()
end

-- Desenha o estado atual: melhorias compradas, próximo botão e rebirth.
function Plot:render(data, nextUpgrade, rebirthCost: number, income: number)
	local currencyName = self.settings.currencyLabel or ""
	local props = self.settings.props or {}
	self.props:ClearAllChildren()
	for slot, upgrade in self.settings.upgrades do
		if data.upgrades[upgrade.key] then
			local item = Builder.model(upgrade.key, self.props)
			local build = props[upgrade.prop or ""]
			if build then
				build(item, self:slotCFrame(slot), self.style)
			else
				local height = upgrade.height or 6
				local color = upgrade.color or Color3.fromRGB(200, 200, 200)
				Builder.box(item, Vector3.new(10, height, 10), self:slotCFrame(slot), color)
			end
		end
	end

	self.padUpgrade = nextUpgrade
	if nextUpgrade then
		local slot = table.find(self.settings.upgrades, nextUpgrade) :: number
		self.pad.CFrame = self:slotCFrame(slot) * CFrame.new(0, 0.15, 0)
		self.pad.Transparency = 0.25
		self.pad.CanTouch = true
		local cost = Format.abbreviate(nextUpgrade.cost)
		self.padLabel.Text = string.format("%s\n%s %s", nextUpgrade.name, cost, currencyName)
	else
		self.pad.Transparency = 1
		self.pad.CanTouch = false
		self.padLabel.Text = ""
	end

	local canRebirth = nextUpgrade == nil
	self.rebirthPad.Transparency = if canRebirth then 0.2 else 1
	self.rebirthPad.CanTouch = canRebirth
	local rebirthText = string.format("REBIRTH\n%s %s", Format.abbreviate(rebirthCost), currencyName)
	self.rebirthLabel.Text = if canRebirth then rebirthText else ""

	self:showPending(0, income)
end

function Plot:showPending(amount: number, income: number)
	local pending, perSecond = Format.abbreviate(amount), Format.abbreviate(income)
	self.collectorLabel.Text = string.format("Caixa: %s\n+%s/s", pending, perSecond)
end

-- Texto que sobe e some (ex.: "+120" quando um cliente paga).
function Plot:floatText(position: Vector3, text: string, color: Color3?)
	local anchor = Instance.new("Part")
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.CanTouch = false
	anchor.Transparency = 1
	anchor.Size = Vector3.new(0.2, 0.2, 0.2)
	anchor.Position = position
	anchor.Parent = self.customers
	local label = Builder.billboard(anchor, text, 0, 160)
	label.TextColor3 = color or Color3.fromRGB(255, 220, 60)
	local tween = TweenService:Create(anchor, TweenInfo.new(1.5), { Position = position + Vector3.new(0, 6, 0) })
	tween:Play()
	TweenService:Create(label, TweenInfo.new(1.5), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	task.delay(1.6, function()
		anchor:Destroy()
	end)
end

return Plot
