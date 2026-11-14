-- Objetos das melhorias da pizzaria, montados com peças. Cada função recebe:
--   parent: Model onde montar
--   cf: centro do espaço (10x10 studs) no chão, olhando para a porta (-Z)
--   style: estilo da pizzaria escolhido pelo jogador (cores)
-- Para trocar por modelos 3D da Creator Store depois: coloque o modelo em ServerStorage e clone aqui.
local ServerScriptService = game:GetService("ServerScriptService")
local TweenService = game:GetService("TweenService")

local Builder = require(ServerScriptService:WaitForChild("Framework"):WaitForChild("Builder"))

local Props = {}

local METAL = Color3.fromRGB(170, 175, 180)
local DARK = Color3.fromRGB(40, 40, 45)
local WOOD = Color3.fromRGB(150, 100, 60)
local CRUST = Color3.fromRGB(230, 165, 70)
local SAUCE = Color3.fromRGB(200, 50, 35)
local CHEESE = Color3.fromRGB(250, 215, 110)
local FIRE = Color3.fromRGB(255, 120, 30)

-- Pizza deitada com algumas fatias de calabresa.
local function pizza(parent: Instance, cf: CFrame, diameter: number)
	Builder.cylinder(parent, 0.25, diameter, cf, CRUST, Enum.Material.Sand)
	Builder.cylinder(parent, 0.27, diameter * 0.86, cf * CFrame.new(0, 0.03, 0), CHEESE, Enum.Material.SmoothPlastic)
	for i = 0, 4 do
		local angle = math.rad(i * 72)
		local offset = CFrame.new(math.cos(angle) * diameter * 0.25, 0.08, math.sin(angle) * diameter * 0.25)
		Builder.cylinder(parent, 0.27, diameter * 0.16, cf * offset, SAUCE, Enum.Material.SmoothPlastic)
	end
end

local function chair(parent: Instance, cf: CFrame, color: Color3)
	Builder.box(parent, Vector3.new(2, 2, 2), cf, color, Enum.Material.Wood)
	Builder.box(parent, Vector3.new(2, 2.4, 0.3), cf * CFrame.new(0, 2, 0.85), color, Enum.Material.Wood)
end

local function fire(parent: Instance, cf: CFrame, size: number)
	local flame = Builder.ball(parent, size, cf, FIRE, Enum.Material.Neon)
	Builder.light(flame, FIRE, 14, 2)
	local emitter = Instance.new("Fire")
	emitter.Size = size * 1.5
	emitter.Heat = 4
	emitter.Parent = flame
end

-- 1. Balcão de montagem com pizzas.
function Props.counter(parent: Instance, cf: CFrame, style)
	Builder.box(parent, Vector3.new(10, 3.6, 4), cf, style.counterColor, Enum.Material.Wood)
	Builder.box(
		parent,
		Vector3.new(10.4, 0.4, 4.4),
		cf * CFrame.new(0, 3.6, 0),
		Color3.fromRGB(240, 240, 235),
		Enum.Material.Marble
	)
	pizza(parent, cf * CFrame.new(-2.5, 4.15, 0), 3)
	pizza(parent, cf * CFrame.new(2.5, 4.15, 0), 3)
	Builder.box(parent, Vector3.new(1.2, 1.4, 1.2), cf * CFrame.new(0, 4, -0.6), SAUCE, Enum.Material.SmoothPlastic)
end

-- 2. Forno a lenha em forma de cúpula, com fogo de verdade.
function Props.woodOven(parent: Instance, cf: CFrame)
	local brick = Color3.fromRGB(170, 85, 60)
	Builder.box(parent, Vector3.new(9, 3.5, 9), cf, Color3.fromRGB(120, 115, 110), Enum.Material.Slate)
	Builder.ball(parent, 9, cf * CFrame.new(0, 4.5, 0), brick, Enum.Material.Brick)
	Builder.box(parent, Vector3.new(3.4, 2.6, 1), cf * CFrame.new(0, 3.5, -4.2), DARK, Enum.Material.Slate)
	fire(parent, cf * CFrame.new(0, 4.4, -3), 1.6)
	Builder.cylinder(parent, 5, 1.4, cf * CFrame.new(1.5, 9.5, 1.5), brick, Enum.Material.Brick)
	local smoke = Instance.new("Smoke")
	smoke.RiseVelocity = 3
	smoke.Opacity = 0.15
	smoke.Parent = Builder.block(parent, Vector3.new(1, 0.2, 1), cf * CFrame.new(1.5, 12.1, 1.5), DARK)
end

-- 3. Mesa redonda com quatro cadeiras e uma pizza.
function Props.tables(parent: Instance, cf: CFrame, style)
	Builder.cylinder(parent, 3, 0.6, cf * CFrame.new(0, 1.5, 0), DARK, Enum.Material.Metal)
	Builder.cylinder(parent, 0.3, 5.5, cf * CFrame.new(0, 3.1, 0), Color3.fromRGB(245, 245, 240), Enum.Material.Fabric)
	Builder.cylinder(parent, 0.25, 6, cf * CFrame.new(0, 2.95, 0), style.accentColor, Enum.Material.Fabric)
	pizza(parent, cf * CFrame.new(0, 3.4, 0), 2.6)
	for i = 0, 3 do
		local around = CFrame.Angles(0, math.rad(i * 90), 0) * CFrame.new(0, 0, 4)
		chair(parent, cf * around, style.counterColor)
	end
end

-- 4. Máquina de massa com rolos e bolas de massa.
function Props.doughMachine(parent: Instance, cf: CFrame)
	Builder.box(parent, Vector3.new(7, 4, 5), cf, METAL, Enum.Material.Metal)
	Builder.box(parent, Vector3.new(5, 4, 4), cf * CFrame.new(0, 4, 0.3), METAL, Enum.Material.DiamondPlate)
	local roller = Builder.block(parent, Vector3.new(5.6, 1, 1), cf * CFrame.new(0, 8.5, -1), DARK, Enum.Material.Metal)
	roller.Shape = Enum.PartType.Cylinder
	Builder.block(
		parent,
		Vector3.new(0.5, 0.5, 0.2),
		cf * CFrame.new(2.6, 6, -1.9),
		Color3.fromRGB(0, 220, 0),
		Enum.Material.Neon
	)
	for _, x in { -2, 0, 2 } do
		Builder.ball(parent, 1.3, cf * CFrame.new(x, 4.6, -3), Color3.fromRGB(250, 235, 200), Enum.Material.Sand)
	end
end

-- 5. Forno duplo de aço com portas de vidro iluminadas.
function Props.deckOven(parent: Instance, cf: CFrame)
	Builder.box(parent, Vector3.new(9, 2, 7), cf, DARK, Enum.Material.Metal)
	for level = 0, 1 do
		local y = 2 + level * 3.6
		Builder.box(parent, Vector3.new(9, 3.4, 7), cf * CFrame.new(0, y, 0), METAL, Enum.Material.Metal)
		local window = Builder.block(
			parent,
			Vector3.new(6, 1.6, 0.2),
			cf * CFrame.new(0, y + 1.7, -3.55),
			FIRE,
			Enum.Material.Neon
		)
		Builder.light(window, FIRE, 8, 1)
		Builder.block(parent, Vector3.new(6, 0.3, 0.4), cf * CFrame.new(0, y + 2.9, -3.7), DARK, Enum.Material.Metal)
	end
	Builder.cylinder(parent, 4, 1.2, cf * CFrame.new(3, 11, 2), METAL, Enum.Material.Metal)
end

-- 6. Moto de entrega com baú.
function Props.deliveryBike(parent: Instance, cf: CFrame, style)
	local body = style.accentColor
	for _, z in { -2.6, 2.6 } do
		local wheel = Builder.block(parent, Vector3.new(0.7, 2.6, 2.6), cf * CFrame.new(0, 1.3, z), DARK)
		wheel.Shape = Enum.PartType.Cylinder
	end
	Builder.box(parent, Vector3.new(1.6, 1.4, 5), cf * CFrame.new(0, 1.6, 0), body, Enum.Material.SmoothPlastic)
	Builder.box(parent, Vector3.new(1.4, 0.6, 2.2), cf * CFrame.new(0, 3, 0.8), DARK, Enum.Material.Fabric)
	Builder.block(parent, Vector3.new(3, 0.3, 0.3), cf * CFrame.new(0, 4.4, -2.2), DARK, Enum.Material.Metal)
	Builder.block(parent, Vector3.new(0.3, 2, 0.3), cf * CFrame.new(0, 3.4, -2.3), DARK, Enum.Material.Metal)
	local box = Builder.box(parent, Vector3.new(3, 2.6, 2.6), cf * CFrame.new(0, 3, 2.5), Color3.fromRGB(245, 245, 240))
	Builder.sign(box, Enum.NormalId.Back, "PIZZA", body)
	Builder.block(
		parent,
		Vector3.new(0.8, 0.5, 0.2),
		cf * CFrame.new(0, 2.4, -2.6),
		Color3.fromRGB(255, 250, 210),
		Enum.Material.Neon
	)
end

-- 7. Cabine VIP: sofá em L, mesa baixa e cordão dourado.
function Props.vipLounge(parent: Instance, cf: CFrame)
	local velvet = Color3.fromRGB(120, 20, 40)
	local gold = Color3.fromRGB(230, 190, 60)
	Builder.box(parent, Vector3.new(9, 1.8, 3), cf * CFrame.new(0, 0, 3), velvet, Enum.Material.Fabric)
	Builder.box(parent, Vector3.new(9, 3, 1), cf * CFrame.new(0, 1.8, 4.3), velvet, Enum.Material.Fabric)
	Builder.box(parent, Vector3.new(3, 1.8, 6), cf * CFrame.new(-3, 0, -1.5), velvet, Enum.Material.Fabric)
	Builder.box(parent, Vector3.new(4, 1.6, 3), cf * CFrame.new(1.5, 0, -0.5), DARK, Enum.Material.Marble)
	pizza(parent, cf * CFrame.new(1.5, 1.75, -0.5), 2.2)
	for _, x in { -4, 0, 4 } do
		Builder.cylinder(parent, 3, 0.4, cf * CFrame.new(x, 1.5, -4.5), gold, Enum.Material.Metal)
		Builder.ball(parent, 0.7, cf * CFrame.new(x, 3.1, -4.5), gold, Enum.Material.Metal)
	end
	Builder.block(parent, Vector3.new(8, 0.3, 0.3), cf * CFrame.new(0, 2.6, -4.5), velvet, Enum.Material.Fabric)
	local lamp = Builder.ball(parent, 1.2, cf * CFrame.new(0, 7, 2), gold, Enum.Material.Neon)
	Builder.light(lamp, gold, 12, 1)
end

-- 8. Esteira automática levando pizzas.
function Props.conveyor(parent: Instance, cf: CFrame)
	Builder.box(parent, Vector3.new(10, 3, 3.5), cf, METAL, Enum.Material.Metal)
	local belt =
		Builder.block(parent, Vector3.new(10.2, 0.3, 3), cf * CFrame.new(0, 3.15, 0), DARK, Enum.Material.Rubber)
	belt.Name = "Esteira"
	for _, x in { -3.5, 0, 3.5 } do
		pizza(parent, cf * CFrame.new(x, 3.45, 0), 2.4)
	end
	Builder.box(parent, Vector3.new(3, 2.4, 4), cf * CFrame.new(-4, 3.3, 0), METAL, Enum.Material.DiamondPlate)
end

-- 9. Forno industrial grande com chaminé e painel.
function Props.industrialOven(parent: Instance, cf: CFrame)
	Builder.box(parent, Vector3.new(10, 10, 8), cf, METAL, Enum.Material.DiamondPlate)
	local mouth = Builder.block(parent, Vector3.new(7, 3, 0.3), cf * CFrame.new(0, 4, -4.1), FIRE, Enum.Material.Neon)
	Builder.light(mouth, FIRE, 16, 2)
	local panel =
		Builder.block(parent, Vector3.new(2, 2.5, 0.3), cf * CFrame.new(3.5, 8, -4.1), DARK, Enum.Material.Metal)
	Builder.sign(panel, Enum.NormalId.Front, "450°", Color3.fromRGB(80, 255, 120), Enum.Font.Code)
	Builder.cylinder(parent, 6, 2, cf * CFrame.new(-3, 13, 2), METAL, Enum.Material.Metal)
end

-- 10. Drone de entrega pairando com uma caixa de pizza.
function Props.drone(parent: Instance, cf: CFrame, style)
	Builder.box(parent, Vector3.new(4, 0.6, 4), cf, DARK, Enum.Material.Metal)
	Builder.box(
		parent,
		Vector3.new(4, 0.4, 4),
		cf * CFrame.new(0, 0.6, 0),
		style.accentColor,
		Enum.Material.SmoothPlastic
	)
	local hover = cf * CFrame.new(0, 7, 0)
	local flying = Builder.model("Voando", parent)
	local white = Color3.fromRGB(235, 235, 235)
	local body = Builder.block(flying, Vector3.new(3, 1, 3), hover, white, Enum.Material.SmoothPlastic)
	for _, x in { -2.4, 2.4 } do
		for _, z in { -2.4, 2.4 } do
			Builder.block(flying, Vector3.new(0.3, 0.3, 0.3), hover * CFrame.new(x / 2, 0, z / 2), DARK)
			Builder.cylinder(flying, 0.1, 2.4, hover * CFrame.new(x, 0.4, z), DARK, Enum.Material.Metal)
		end
	end
	Builder.block(flying, Vector3.new(2.6, 0.6, 2.6), hover * CFrame.new(0, -1, 0), Color3.fromRGB(245, 245, 240))
	Builder.light(body, Color3.fromRGB(120, 200, 255), 8, 1)
	-- Sobe e desce devagar.
	for _, part in flying:GetChildren() do
		local goal = { CFrame = (part :: BasePart).CFrame * CFrame.new(0, 1, 0) }
		local info = TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
		TweenService:Create(part, info, goal):Play()
	end
end

-- 11. Geladeira de bebidas iluminada.
function Props.drinkFridge(parent: Instance, cf: CFrame)
	Builder.box(
		parent,
		Vector3.new(8, 9, 3.5),
		cf * CFrame.new(0, 0, 2),
		Color3.fromRGB(230, 230, 230),
		Enum.Material.Metal
	)
	local glass = Builder.block(
		parent,
		Vector3.new(7, 8, 0.2),
		cf * CFrame.new(0, 4.6, 0.15),
		Color3.fromRGB(180, 220, 240),
		Enum.Material.Glass
	)
	glass.Transparency = 0.5
	local colors = {
		Color3.fromRGB(220, 30, 30),
		Color3.fromRGB(40, 160, 60),
		Color3.fromRGB(255, 140, 0),
		Color3.fromRGB(60, 90, 220),
	}
	for shelf = 0, 2 do
		for i = 0, 5 do
			local color = colors[(i + shelf) % #colors + 1]
			Builder.cylinder(
				parent,
				1.4,
				0.8,
				cf * CFrame.new(-2.9 + i * 1.15, 2.1 + shelf * 2.5, 1.2),
				color,
				Enum.Material.Neon
			)
		end
	end
	Builder.light(glass, Color3.fromRGB(200, 230, 255), 10, 1)
end

-- 12. Pizza gigante girando num pedestal (atração da loja).
function Props.giantPizza(parent: Instance, cf: CFrame)
	Builder.cylinder(parent, 3, 4, cf * CFrame.new(0, 1.5, 0), DARK, Enum.Material.Marble)
	local spin = Builder.model("PizzaGigante", parent)
	local center = cf * CFrame.new(0, 7, 0) * CFrame.Angles(math.rad(-70), 0, 0)
	pizza(spin, center, 9)
	spin.WorldPivot = center
	local glow = Builder.ball(parent, 1, cf * CFrame.new(0, 3.2, 0), CHEESE, Enum.Material.Neon)
	Builder.light(glow, CHEESE, 14, 1.5)
	task.spawn(function()
		local step = 0
		while spin.Parent do
			step += 1
			spin:PivotTo(center * CFrame.Angles(0, math.rad(step * 3), 0))
			task.wait(0.05)
		end
	end)
end

return Props
