-- Terreno de um jogador no tycoon: piso, placa do dono, coletor, botões de compra e prédios.
-- Os prédios são blocos simples por enquanto; depois dá para trocar por modelos da Creator Store.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Format = require(ReplicatedStorage:WaitForChild("FrameworkShared"):WaitForChild("Format"))

local Plot = {}
Plot.__index = Plot

local GRID_COLUMNS = 4
local GRID_SPACING = 20
local BUILDING_FOOTPRINT = 12
local TOUCH_COOLDOWN = 0.75

local function part(props: { [string]: any }): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Material = Enum.Material.SmoothPlastic
	for key, value in props do
		(p :: any)[key] = value
	end
	return p
end

local function billboard(adornee: BasePart, height: number, width: number): TextLabel
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.new(0, width, 0, 60)
	gui.StudsOffset = Vector3.new(0, height, 0)
	gui.AlwaysOnTop = false
	gui.MaxDistance = 120
	gui.Parent = adornee
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.3
	label.Parent = gui
	return label
end

-- Chão do mapa e pasta onde ficam os terrenos.
function Plot.buildWorld(settings): Folder
	local folder = Instance.new("Folder")
	folder.Name = "Tycoon"
	folder.Parent = workspace

	local span = settings.plotCount * (settings.plotSize + 24) + 200
	part({
		Name = "Ground",
		Size = Vector3.new(span, 1, settings.plotSize + 240),
		Position = Vector3.new(0, -0.5, 0),
		Color = settings.groundColor,
		Material = Enum.Material.Grass,
		Parent = folder,
	})
	local spawn = Instance.new("SpawnLocation")
	spawn.Anchored = true
	spawn.Size = Vector3.new(12, 1, 12)
	spawn.Position = Vector3.new(0, 0.5, settings.plotSize / 2 + 60)
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Parent = folder
	return folder
end

function Plot.new(index: number, settings, world: Folder)
	local self = setmetatable({}, Plot)
	self.settings = settings
	self.owner = nil :: Player?
	self.callbacks = nil
	self.lastTouch = 0

	local offset = (index - 1 - (settings.plotCount - 1) / 2) * (settings.plotSize + 24)
	self.origin = CFrame.new(offset, 0, 0)

	local model = Instance.new("Model")
	model.Name = "Plot" .. index
	model.Parent = world
	self.model = model

	local size = settings.plotSize
	self.floor = part({
		Name = "Floor",
		Size = Vector3.new(size, 1, size),
		CFrame = self.origin,
		Color = settings.floorColor,
		Parent = model,
	})
	self.sign = billboard(self.floor, 14, 400)
	self.sign.Text = "Terreno livre"

	self.collector = part({
		Name = "Collector",
		Size = Vector3.new(8, 0.4, 8),
		CFrame = self.origin * CFrame.new(-size / 2 + 10, 0.7, size / 2 - 10),
		Color = Color3.fromRGB(255, 196, 0),
		Material = Enum.Material.Neon,
		Parent = model,
	})
	self.collectorLabel = billboard(self.collector, 4, 220)
	self.collectorLabel.Text = ""

	self.rebirthPad = part({
		Name = "Rebirth",
		Size = Vector3.new(8, 0.4, 8),
		CFrame = self.origin * CFrame.new(size / 2 - 10, 0.7, size / 2 - 10),
		Color = Color3.fromRGB(150, 70, 255),
		Material = Enum.Material.Neon,
		Transparency = 1,
		CanTouch = false,
		Parent = model,
	})
	self.rebirthLabel = billboard(self.rebirthPad, 4, 220)

	self.buildings = Instance.new("Folder")
	self.buildings.Name = "Buildings"
	self.buildings.Parent = model

	self.pad = part({
		Name = "BuyPad",
		Size = Vector3.new(BUILDING_FOOTPRINT, 0.4, BUILDING_FOOTPRINT),
		Color = Color3.fromRGB(0, 200, 90),
		Material = Enum.Material.Neon,
		Transparency = 1,
		CanTouch = false,
		Parent = model,
	})
	self.padLabel = billboard(self.pad, 5, 260)
	self.padUpgrade = nil

	local function touchedBy(hit: BasePart): Player?
		local character = hit:FindFirstAncestorOfClass("Model")
		local player = character and Players:GetPlayerFromCharacter(character)
		if player and player == self.owner and self.callbacks then
			local now = os.clock()
			if now - self.lastTouch < TOUCH_COOLDOWN then
				return nil
			end
			self.lastTouch = now
			return player
		end
		return nil
	end

	self.collector.Touched:Connect(function(hit)
		if touchedBy(hit) then
			self.callbacks.onCollect()
		end
	end)
	self.pad.Touched:Connect(function(hit)
		if self.padUpgrade and touchedBy(hit) then
			self.callbacks.onBuy(self.padUpgrade)
		end
	end)
	self.rebirthPad.Touched:Connect(function(hit)
		if self.rebirthPad.CanTouch and touchedBy(hit) then
			self.callbacks.onRebirth()
		end
	end)

	return self
end

function Plot:slotCFrame(slot: number): CFrame
	local size = self.settings.plotSize
	local column = (slot - 1) % GRID_COLUMNS
	local row = (slot - 1) // GRID_COLUMNS
	local x = (column - (GRID_COLUMNS - 1) / 2) * GRID_SPACING
	local z = -size / 2 + 14 + row * (GRID_SPACING + 2)
	return self.origin * CFrame.new(x, 0.5, z)
end

function Plot:spawnCFrame(): CFrame
	local size = self.settings.plotSize
	return self.origin * CFrame.new(0, 4, size / 2 - 8)
end

function Plot:claim(player: Player, callbacks)
	self.owner = player
	self.callbacks = callbacks
	self.sign.Text = "Terreno de " .. player.DisplayName
end

function Plot:release()
	self.owner = nil
	self.callbacks = nil
	self.sign.Text = "Terreno livre"
	self.collectorLabel.Text = ""
	self.buildings:ClearAllChildren()
	self.padUpgrade = nil
	self.pad.Transparency = 1
	self.pad.CanTouch = false
	self.padLabel.Text = ""
	self.rebirthPad.Transparency = 1
	self.rebirthPad.CanTouch = false
	self.rebirthLabel.Text = ""
end

-- Desenha o estado atual: prédios comprados, próximo botão e rebirth.
function Plot:render(data, nextUpgrade, rebirthCost: number, income: number)
	local currencyName = self.settings.currencyLabel or ""
	self.buildings:ClearAllChildren()
	for slot, upgrade in self.settings.upgrades do
		if data.upgrades[upgrade.key] then
			local height = upgrade.height or 8
			local building = part({
				Name = upgrade.key,
				Size = Vector3.new(BUILDING_FOOTPRINT, height, BUILDING_FOOTPRINT),
				CFrame = self:slotCFrame(slot) * CFrame.new(0, height / 2, 0),
				Color = upgrade.color or Color3.fromRGB(200, 200, 200),
				Parent = self.buildings,
			})
			local label = billboard(building, height / 2 + 2, 200)
			label.Text = string.format("%s\n+%s/s", upgrade.name, Format.abbreviate(upgrade.income))
		end
	end

	self.padUpgrade = nextUpgrade
	if nextUpgrade then
		local slot = table.find(self.settings.upgrades, nextUpgrade) :: number
		self.pad.CFrame = self:slotCFrame(slot) * CFrame.new(0, 0.2, 0)
		self.pad.Transparency = 0.2
		self.pad.CanTouch = true
		self.padLabel.Text = string.format("%s\n%s %s", nextUpgrade.name, Format.abbreviate(nextUpgrade.cost), currencyName)
	else
		self.pad.Transparency = 1
		self.pad.CanTouch = false
		self.padLabel.Text = ""
	end

	local canRebirth = nextUpgrade == nil
	self.rebirthPad.Transparency = if canRebirth then 0.2 else 1
	self.rebirthPad.CanTouch = canRebirth
	self.rebirthLabel.Text = if canRebirth
		then string.format("REBIRTH\n%s %s", Format.abbreviate(rebirthCost), currencyName)
		else ""

	self:showPending(0, income)
end

function Plot:showPending(amount: number, income: number)
	self.collectorLabel.Text = string.format("Coletar: %s\n+%s/s", Format.abbreviate(amount), Format.abbreviate(income))
end

return Plot
