-- Peças de construção geradas por código: blocos, placas, árvores, postes, carros, prédios, casas.
-- Serve para qualquer gênero: um mapa inteiro pode ser montado sem modelos feitos à mão.
-- Convenção: `cf` é o centro da BASE do objeto (no chão), olhando para -Z (LookVector).
local Builder = {}

local function apply(part: BasePart, color: Color3, material: Enum.Material?)
	part.Anchored = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
end

function Builder.model(name: string, parent: Instance): Model
	local model = Instance.new("Model")
	model.Name = name
	model.Parent = parent
	return model
end

-- Bloco com centro em `cf`.
function Builder.block(parent: Instance, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material?): Part
	local part = Instance.new("Part")
	apply(part, color, material)
	part.Size = size
	part.CFrame = cf
	part.Parent = parent
	return part
end

-- Bloco apoiado no chão: `cf` é o centro da base.
function Builder.box(parent: Instance, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material?): Part
	return Builder.block(parent, size, cf * CFrame.new(0, size.Y / 2, 0), color, material)
end

function Builder.wedge(parent: Instance, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material?): WedgePart
	local part = Instance.new("WedgePart")
	apply(part, color, material)
	part.Size = size
	part.CFrame = cf
	part.Parent = parent
	return part
end

-- Cilindro em pé com centro em `cf`.
function Builder.cylinder(
	parent: Instance,
	height: number,
	diameter: number,
	cf: CFrame,
	color: Color3,
	material: Enum.Material?
): Part
	local part = Instance.new("Part")
	apply(part, color, material)
	part.Shape = Enum.PartType.Cylinder
	part.Size = Vector3.new(height, diameter, diameter)
	part.CFrame = cf * CFrame.Angles(0, 0, math.pi / 2)
	part.Parent = parent
	return part
end

function Builder.ball(parent: Instance, diameter: number, cf: CFrame, color: Color3, material: Enum.Material?): Part
	local part = Instance.new("Part")
	apply(part, color, material)
	part.Shape = Enum.PartType.Ball
	part.Size = Vector3.new(diameter, diameter, diameter)
	part.CFrame = cf
	part.Parent = parent
	return part
end

function Builder.light(part: BasePart, color: Color3, range: number, brightness: number?): PointLight
	local light = Instance.new("PointLight")
	light.Color = color
	light.Range = range
	light.Brightness = brightness or 1
	light.Parent = part
	return light
end

-- Texto flutuante sobre uma peça.
function Builder.billboard(adornee: BasePart, text: string, offsetY: number, width: number?): TextLabel
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.new(0, width or 220, 0, 60)
	gui.StudsOffset = Vector3.new(0, offsetY, 0)
	gui.MaxDistance = 120
	gui.Parent = adornee
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.3
	label.Text = text
	label.Parent = gui
	return label
end

-- Texto pintado numa face da peça (letreiros, placas).
function Builder.sign(part: BasePart, face: Enum.NormalId, text: string, textColor: Color3, font: Enum.Font?): TextLabel
	local gui = Instance.new("SurfaceGui")
	gui.Face = face
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 40
	gui.LightInfluence = 0
	gui.Parent = part
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextScaled = true
	label.Font = font or Enum.Font.FredokaOne
	label.TextColor3 = textColor
	label.Text = text
	label.Parent = gui
	return label
end

local LEAF_COLORS = {
	Color3.fromRGB(58, 125, 21),
	Color3.fromRGB(75, 151, 75),
	Color3.fromRGB(40, 110, 50),
}

function Builder.tree(parent: Instance, cf: CFrame, scale: number?, variant: number?)
	local s = scale or 1
	local model = Builder.model("Arvore", parent)
	local trunkHeight = 8 * s
	Builder.cylinder(
		model,
		trunkHeight,
		1.6 * s,
		cf * CFrame.new(0, trunkHeight / 2, 0),
		Color3.fromRGB(105, 64, 40),
		Enum.Material.Wood
	)
	local leaves = LEAF_COLORS[((variant or 1) - 1) % #LEAF_COLORS + 1]
	Builder.ball(model, 9 * s, cf * CFrame.new(0, trunkHeight + 2 * s, 0), leaves, Enum.Material.Grass)
	Builder.ball(model, 6 * s, cf * CFrame.new(2.5 * s, trunkHeight + 4.5 * s, 1 * s), leaves, Enum.Material.Grass)
	Builder.ball(model, 6 * s, cf * CFrame.new(-2 * s, trunkHeight + 4 * s, -1.5 * s), leaves, Enum.Material.Grass)
	return model
end

function Builder.bush(parent: Instance, cf: CFrame, scale: number?)
	local s = scale or 1
	return Builder.ball(parent, 4 * s, cf * CFrame.new(0, 1.2 * s, 0), Color3.fromRGB(52, 120, 40), Enum.Material.Grass)
end

-- Poste de luz (acende de verdade).
function Builder.lamp(parent: Instance, cf: CFrame)
	local model = Builder.model("Poste", parent)
	local metal = Color3.fromRGB(45, 45, 50)
	Builder.cylinder(model, 14, 0.6, cf * CFrame.new(0, 7, 0), metal, Enum.Material.Metal)
	Builder.block(model, Vector3.new(0.5, 0.5, 3), cf * CFrame.new(0, 13.8, -1.3), metal, Enum.Material.Metal)
	local bulb = Builder.block(
		model,
		Vector3.new(1.4, 0.6, 1.4),
		cf * CFrame.new(0, 13.4, -2.6),
		Color3.fromRGB(255, 240, 200),
		Enum.Material.Neon
	)
	Builder.light(bulb, Color3.fromRGB(255, 220, 170), 22, 1.5)
	return model
end

function Builder.bench(parent: Instance, cf: CFrame)
	local model = Builder.model("Banco", parent)
	local wood = Color3.fromRGB(140, 90, 55)
	local metal = Color3.fromRGB(40, 40, 45)
	Builder.box(model, Vector3.new(0.4, 1.6, 2), cf * CFrame.new(-2.6, 0, 0), metal, Enum.Material.Metal)
	Builder.box(model, Vector3.new(0.4, 1.6, 2), cf * CFrame.new(2.6, 0, 0), metal, Enum.Material.Metal)
	Builder.box(model, Vector3.new(6, 0.3, 2.2), cf * CFrame.new(0, 1.6, 0), wood, Enum.Material.WoodPlanks)
	Builder.box(model, Vector3.new(6, 1.6, 0.3), cf * CFrame.new(0, 1.9, 1), wood, Enum.Material.WoodPlanks)
	return model
end

function Builder.car(parent: Instance, cf: CFrame, color: Color3)
	local model = Builder.model("Carro", parent)
	local glass = Color3.fromRGB(150, 190, 220)
	local tire = Color3.fromRGB(25, 25, 25)
	Builder.box(model, Vector3.new(6, 2, 12), cf * CFrame.new(0, 1, 0), color, Enum.Material.SmoothPlastic)
	Builder.box(model, Vector3.new(5.4, 1.8, 6), cf * CFrame.new(0, 3, 0.5), glass, Enum.Material.Glass)
	Builder.box(model, Vector3.new(5.6, 0.3, 6.2), cf * CFrame.new(0, 4.8, 0.5), color, Enum.Material.SmoothPlastic)
	for _, x in { -3, 3 } do
		for _, z in { -3.8, 3.8 } do
			local wheel = Builder.block(model, Vector3.new(0.8, 2.4, 2.4), cf * CFrame.new(x, 1.2, z), tire)
			wheel.Shape = Enum.PartType.Cylinder
		end
	end
	Builder.block(
		model,
		Vector3.new(1.2, 0.6, 0.2),
		cf * CFrame.new(-2, 1.6, -6.05),
		Color3.fromRGB(255, 250, 220),
		Enum.Material.Neon
	)
	Builder.block(
		model,
		Vector3.new(1.2, 0.6, 0.2),
		cf * CFrame.new(2, 1.6, -6.05),
		Color3.fromRGB(255, 250, 220),
		Enum.Material.Neon
	)
	return model
end

-- Prédio com faixas de janelas por andar.
function Builder.tower(parent: Instance, cf: CFrame, size: Vector3, color: Color3, material: Enum.Material?)
	local model = Builder.model("Predio", parent)
	Builder.box(model, size, cf, color, material or Enum.Material.Concrete)
	local glass = Color3.fromRGB(120, 170, 210)
	local floors = math.floor((size.Y - 4) / 8)
	for floor = 1, floors do
		local y = floor * 8
		Builder.block(
			model,
			Vector3.new(size.X + 0.3, 3.2, size.Z - 4),
			cf * CFrame.new(0, y, 0),
			glass,
			Enum.Material.Glass
		)
		Builder.block(
			model,
			Vector3.new(size.X - 4, 3.2, size.Z + 0.3),
			cf * CFrame.new(0, y, 0),
			glass,
			Enum.Material.Glass
		)
	end
	Builder.box(
		model,
		Vector3.new(size.X + 1, 1, size.Z + 1),
		cf * CFrame.new(0, size.Y, 0),
		Color3.fromRGB(70, 70, 75),
		Enum.Material.Concrete
	)
	Builder.box(
		model,
		Vector3.new(8, 3, 8),
		cf * CFrame.new(size.X / 4, size.Y + 1, size.Z / 4),
		Color3.fromRGB(120, 120, 125),
		Enum.Material.Metal
	)
	return model
end

-- Casa com telhado de duas águas, porta e janelas. Frente = -Z.
function Builder.house(parent: Instance, cf: CFrame, size: Vector3, wall: Color3, roof: Color3)
	local model = Builder.model("Casa", parent)
	Builder.box(model, size, cf, wall, Enum.Material.Plaster)
	local roofHeight = size.Y * 0.6
	local roofSize = Vector3.new(size.X + 2, roofHeight, size.Z / 2 + 1)
	local y = size.Y + roofHeight / 2
	Builder.wedge(model, roofSize, cf * CFrame.new(0, y, -size.Z / 4 - 0.5), roof, Enum.Material.Slate)
	Builder.wedge(
		model,
		roofSize,
		cf * CFrame.new(0, y, size.Z / 4 + 0.5) * CFrame.Angles(0, math.pi, 0),
		roof,
		Enum.Material.Slate
	)
	local front = -size.Z / 2 - 0.1
	Builder.box(
		model,
		Vector3.new(3.5, 7, 0.4),
		cf * CFrame.new(0, 0, front),
		Color3.fromRGB(110, 70, 45),
		Enum.Material.Wood
	)
	local glass = Color3.fromRGB(160, 200, 230)
	for _, x in { -size.X / 3, size.X / 3 } do
		Builder.block(
			model,
			Vector3.new(4, 3.5, 0.4),
			cf * CFrame.new(x, size.Y * 0.55, front),
			glass,
			Enum.Material.Glass
		)
	end
	Builder.box(
		model,
		Vector3.new(3, 0.4, 3),
		cf * CFrame.new(0, 0, front - 1.6),
		Color3.fromRGB(170, 170, 170),
		Enum.Material.Concrete
	)
	return model
end

function Builder.fountain(parent: Instance, cf: CFrame)
	local model = Builder.model("Fonte", parent)
	local stone = Color3.fromRGB(200, 195, 185)
	Builder.cylinder(model, 2.4, 30, cf * CFrame.new(0, 1.2, 0), stone, Enum.Material.Marble)
	Builder.cylinder(model, 0.4, 27, cf * CFrame.new(0, 2.3, 0), Color3.fromRGB(70, 150, 210), Enum.Material.Glass)
	Builder.cylinder(model, 8, 3, cf * CFrame.new(0, 6, 0), stone, Enum.Material.Marble)
	Builder.cylinder(model, 1, 12, cf * CFrame.new(0, 10, 0), stone, Enum.Material.Marble)
	local water = Builder.cylinder(
		model,
		0.3,
		10.5,
		cf * CFrame.new(0, 10.6, 0),
		Color3.fromRGB(90, 170, 230),
		Enum.Material.Glass
	)
	local spout = Builder.ball(model, 3, cf * CFrame.new(0, 12, 0), Color3.fromRGB(150, 210, 250), Enum.Material.Glass)
	spout.Transparency = 0.3
	water.Transparency = 0.2
	return model
end

-- Rua ao longo do X local, com faixa central tracejada.
function Builder.road(parent: Instance, cf: CFrame, length: number, width: number)
	local model = Builder.model("Rua", parent)
	Builder.block(
		model,
		Vector3.new(length, 0.2, width),
		cf * CFrame.new(0, 0.1, 0),
		Color3.fromRGB(55, 55, 60),
		Enum.Material.Asphalt
	)
	local dashes = math.floor(length / 14)
	for i = 0, dashes - 1 do
		local x = -length / 2 + 7 + i * 14
		Builder.block(
			model,
			Vector3.new(6, 0.05, 0.6),
			cf * CFrame.new(x, 0.22, 0),
			Color3.fromRGB(240, 220, 90),
			Enum.Material.SmoothPlastic
		)
	end
	return model
end

function Builder.sidewalk(parent: Instance, cf: CFrame, length: number, width: number)
	return Builder.block(
		parent,
		Vector3.new(length, 0.6, width),
		cf * CFrame.new(0, 0.3, 0),
		Color3.fromRGB(180, 178, 172),
		Enum.Material.Concrete
	)
end

return Builder
