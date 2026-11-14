-- Cidade gerada por código em volta dos terrenos do tycoon.
--
--   Norte (z < 0):   Centro com prédios altos
--                    rua de trás
--                    4 terrenos de frente para a avenida
--   Avenida (z = 0): praça central com fonte e spawn no meio
--                    4 terrenos de frente para a avenida
--                    rua de trás
--   Sul (z > 0):     Bairro residencial com casas e um parque com lago
--
-- Retorna os CFrames dos terrenos (frente = LookVector, virada para a avenida) e os pontos da praça.
local ServerScriptService = game:GetService("ServerScriptService")
local Lighting = game:GetService("Lighting")

local Builder = require(ServerScriptService:WaitForChild("Framework"):WaitForChild("Builder"))

local City = {}

local AVENUE_WIDTH = 36
local PLAZA_HALF = 112
local LOT_X = { 180, -180, 300, -300 }
local END_X = 400
local BACK_Z = 140

local TOWER_COLORS = {
	Color3.fromRGB(205, 200, 190),
	Color3.fromRGB(150, 160, 175),
	Color3.fromRGB(190, 170, 150),
	Color3.fromRGB(120, 130, 145),
	Color3.fromRGB(225, 220, 210),
}
local HOUSE_COLORS = {
	Color3.fromRGB(240, 230, 200),
	Color3.fromRGB(200, 225, 240),
	Color3.fromRGB(245, 205, 180),
	Color3.fromRGB(210, 235, 200),
	Color3.fromRGB(235, 215, 235),
}
local ROOF_COLORS = {
	Color3.fromRGB(150, 60, 45),
	Color3.fromRGB(80, 80, 90),
	Color3.fromRGB(110, 70, 50),
}
local CAR_COLORS = {
	Color3.fromRGB(200, 40, 40),
	Color3.fromRGB(40, 90, 200),
	Color3.fromRGB(240, 240, 240),
	Color3.fromRGB(30, 30, 35),
	Color3.fromRGB(250, 200, 40),
}

local function at(x: number, z: number, y: number?): CFrame
	return CFrame.new(x, y or 0, z)
end

local function facing(x: number, z: number, dx: number, dz: number, y: number?): CFrame
	local position = Vector3.new(x, y or 0, z)
	return CFrame.lookAt(position, position + Vector3.new(dx, 0, dz))
end

local function setupLighting()
	Lighting.ClockTime = 14.5
	Lighting.Brightness = 2.2
	Lighting.OutdoorAmbient = Color3.fromRGB(140, 140, 150)
	Lighting.EnvironmentDiffuseScale = 0.5
	Lighting.EnvironmentSpecularScale = 0.5
	if not Lighting:FindFirstChildOfClass("Atmosphere") then
		local atmosphere = Instance.new("Atmosphere")
		atmosphere.Density = 0.28
		atmosphere.Haze = 1.2
		atmosphere.Color = Color3.fromRGB(200, 215, 235)
		atmosphere.Parent = Lighting
	end
	if not Lighting:FindFirstChildOfClass("Sky") then
		Instance.new("Sky").Parent = Lighting
	end
	local color = Instance.new("ColorCorrectionEffect")
	color.Saturation = 0.12
	color.Contrast = 0.05
	color.Parent = Lighting
	local rays = Instance.new("SunRaysEffect")
	rays.Intensity = 0.04
	rays.Parent = Lighting
end

local function buildPlaza(folder: Folder, random: Random)
	local plaza = Builder.model("Praca", folder)
	local paving = Vector3.new(PLAZA_HALF * 2, 0.4, PLAZA_HALF * 2)
	Builder.block(plaza, paving, at(0, 0, 0.2), Color3.fromRGB(190, 175, 150), Enum.Material.Cobblestone)
	Builder.fountain(plaza, at(0, 0, 0.4))

	for i = 0, 5 do
		local angle = math.rad(i * 60 + 30)
		local x, z = math.cos(angle) * 32, math.sin(angle) * 32
		Builder.bench(plaza, CFrame.lookAt(Vector3.new(x, 0.4, z), Vector3.new(0, 0.4, 0)))
	end
	for i = 0, 11 do
		local degrees = i * 30
		local nearAvenue = degrees % 180 == 0
		if not nearAvenue then
			local angle = math.rad(degrees)
			local cf = at(math.cos(angle) * 82, math.sin(angle) * 82, 0.4)
			Builder.tree(plaza, cf, 1.1, i)
			Builder.bush(plaza, cf * CFrame.new(5, 0, 3), 1)
		end
	end
	for _, x in { -96, 96 } do
		for _, z in { -96, 96 } do
			Builder.lamp(plaza, facing(x, z, -x, -z, 0.4))
		end
	end

	-- Portais com o nome da cidade nas duas entradas da avenida.
	for _, x in { -PLAZA_HALF, PLAZA_HALF } do
		local gate = Builder.model("Portal", plaza)
		local pillar = Color3.fromRGB(170, 60, 40)
		Builder.box(gate, Vector3.new(4, 26, 4), at(x, -AVENUE_WIDTH / 2 - 4), pillar, Enum.Material.Brick)
		Builder.box(gate, Vector3.new(4, 26, 4), at(x, AVENUE_WIDTH / 2 + 4), pillar, Enum.Material.Brick)
		local beam =
			Builder.block(gate, Vector3.new(4, 6, AVENUE_WIDTH + 12), at(x, 0, 25), pillar, Enum.Material.Brick)
		local face = if x > 0 then Enum.NormalId.Right else Enum.NormalId.Left
		Builder.sign(beam, face, "PIZZA CITY", Color3.fromRGB(255, 220, 120))
	end

	local spawn = Instance.new("SpawnLocation")
	spawn.Anchored = true
	spawn.Size = Vector3.new(10, 1, 10)
	spawn.CFrame = at(0, 70, 0.5)
	spawn.Color = Color3.fromRGB(255, 196, 0)
	spawn.Material = Enum.Material.Neon
	spawn.Transparency = 0.6
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Parent = plaza

	local homePad =
		Builder.block(plaza, Vector3.new(10, 0.4, 10), at(0, 46, 0.6), Color3.fromRGB(0, 200, 90), Enum.Material.Neon)
	homePad.Name = "IrParaPizzaria"
	Builder.billboard(homePad, "Ir para minha pizzaria", 5, 260)

	-- Um pouco de vida na praça: canteiros com flores.
	for _ = 1, 10 do
		local angle = random:NextNumber(0, math.pi * 2)
		local radius = random:NextNumber(50, 70)
		local cf = at(math.cos(angle) * radius, math.sin(angle) * radius, 0.4)
		local flower = Color3.fromHSV(random:NextNumber(), 0.7, 1)
		Builder.ball(plaza, 1.2, cf * CFrame.new(0, 1.4, 0), flower, Enum.Material.SmoothPlastic)
		Builder.bush(plaza, cf, 0.7)
	end

	return at(0, 70, 4), homePad
end

local function buildStreets(folder: Folder, random: Random)
	local streets = Builder.model("Ruas", folder)
	local avenueLength = END_X - 12 - PLAZA_HALF
	local avenueCenter = PLAZA_HALF + avenueLength / 2
	for _, side in { -1, 1 } do
		Builder.road(streets, at(side * avenueCenter, 0), avenueLength, AVENUE_WIDTH)
		for _, z in { -AVENUE_WIDTH / 2 - 4, AVENUE_WIDTH / 2 + 4 } do
			Builder.sidewalk(streets, at(side * avenueCenter, z), avenueLength, 8)
		end
		-- Ruas transversais nas bordas da praça e no fim da avenida.
		for _, z in { -1, 1 } do
			local length = BACK_Z - 12 - AVENUE_WIDTH / 2
			local center = z * (AVENUE_WIDTH / 2 + length / 2)
			local cross = CFrame.new(side * (PLAZA_HALF + 9), 0, center) * CFrame.Angles(0, math.pi / 2, 0)
			Builder.road(streets, cross, length, 18)
		end
		local endRoad = CFrame.new(side * END_X, 0, 0) * CFrame.Angles(0, math.pi / 2, 0)
		Builder.road(streets, endRoad, (BACK_Z - 12) * 2, 24)

		-- Postes e carros estacionados ao longo da avenida.
		for x = PLAZA_HALF + 14, END_X - 20, 46 do
			Builder.lamp(streets, facing(side * x, -AVENUE_WIDTH / 2 - 5, 0, 1, 0.6))
			Builder.lamp(streets, facing(side * (x + 23), AVENUE_WIDTH / 2 + 5, 0, -1, 0.6))
		end
		for _ = 1, 3 do
			local x = side * random:NextNumber(PLAZA_HALF + 20, END_X - 30)
			local z = if random:NextNumber() > 0.5 then 13 else -13
			local color = CAR_COLORS[random:NextInteger(1, #CAR_COLORS)]
			Builder.car(streets, facing(x, z, side, 0), color)
		end
	end
	for _, z in { -BACK_Z, BACK_Z } do
		Builder.road(streets, at(0, z), (END_X + 12) * 2, 24)
	end
end

local function buildDowntown(folder: Folder, random: Random)
	local downtown = Builder.model("Centro", folder)
	for _, z in { -245, -335 } do
		Builder.road(downtown, at(0, z), (END_X + 12) * 2, 20)
	end
	for _, z in { -200, -290, -380 } do
		for x = -380, 380, 95 do
			local width = random:NextInteger(36, 52)
			local height = random:NextInteger(40, 150)
			local color = TOWER_COLORS[random:NextInteger(1, #TOWER_COLORS)]
			Builder.tower(downtown, at(x, z), Vector3.new(width, height, width), color)
		end
	end
end

local function buildSuburb(folder: Folder, random: Random)
	local suburb = Builder.model("Bairro", folder)
	Builder.road(suburb, at(0, 225), (END_X + 12) * 2, 20)
	for x = -380, 380, 38 do
		local inPark = math.abs(x) < 95
		if not inPark then
			for _, row in { { z = 190, dz = 1 }, { z = 262, dz = -1 } } do
				local wall = HOUSE_COLORS[random:NextInteger(1, #HOUSE_COLORS)]
				local roof = ROOF_COLORS[random:NextInteger(1, #ROOF_COLORS)]
				Builder.house(suburb, facing(x, row.z, 0, row.dz), Vector3.new(22, 12, 20), wall, roof)
				Builder.tree(suburb, at(x + 19, row.z - row.dz * 6), 0.8, x)
			end
		end
	end

	-- Parque com lago no meio do bairro.
	local park = Builder.model("Parque", folder)
	local lake = Builder.block(
		park,
		Vector3.new(70, 0.3, 40),
		at(0, 300, 0.15),
		Color3.fromRGB(60, 140, 200),
		Enum.Material.Glass
	)
	lake.Transparency = 0.15
	for _ = 1, 22 do
		local x = random:NextNumber(-88, 88)
		local z = random:NextNumber(160, 340)
		local awayFromLake = math.abs(x) > 42 or math.abs(z - 300) > 26
		local awayFromRoad = math.abs(z - 225) > 14
		if awayFromLake and awayFromRoad then
			Builder.tree(park, at(x, z), random:NextNumber(0.9, 1.4), random:NextInteger(1, 3))
		end
	end
	for _, x in { -30, 0, 30 } do
		Builder.bench(park, facing(x, 274, 0, 1))
	end

	-- Floresta em volta da cidade, para o mapa não acabar no vazio.
	for _ = 1, 70 do
		local angle = random:NextNumber(0, math.pi * 2)
		local radius = random:NextNumber(470, 620)
		Builder.tree(folder, at(math.cos(angle) * radius, math.sin(angle) * radius), random:NextNumber(1, 1.8), 1)
	end
end

local function decorateGaps(folder: Folder)
	-- Canteiros entre os terrenos e nos cantos.
	local decor = Builder.model("Canteiros", folder)
	for _, x in { -240, 240 } do
		for _, z in { -74, 74 } do
			Builder.block(
				decor,
				Vector3.new(20, 0.5, 90),
				at(x, z, 0.25),
				Color3.fromRGB(110, 85, 60),
				Enum.Material.Ground
			)
			for dz = -36, 36, 18 do
				Builder.tree(decor, at(x, z + dz, 0.5), 0.9, dz)
			end
		end
	end
end

-- Constrói a cidade. Retorna:
--   lots: CFrames dos terrenos (centro, LookVector apontando para a avenida)
--   plazaSpawn: onde o jogador aparece ao ir para a praça
--   homePad: bloco na praça que leva o jogador para a pizzaria dele
function City.build(settings)
	assert(settings.plotCount <= #LOT_X * 2, "A cidade tem espaço para no máximo 8 terrenos")
	local random = Random.new(settings.citySeed or 7)
	local folder = Instance.new("Folder")
	folder.Name = "Cidade"
	folder.Parent = workspace

	setupLighting()
	local ground = Vector3.new(1600, 1, 1600)
	Builder.block(folder, ground, at(0, 0, -0.5), Color3.fromRGB(86, 150, 70), Enum.Material.Grass)

	local plazaSpawn, homePad = buildPlaza(folder, random)
	buildStreets(folder, random)
	buildDowntown(folder, random)
	buildSuburb(folder, random)
	decorateGaps(folder)

	local lotZ = AVENUE_WIDTH / 2 + 8 + settings.plotSize / 2
	local lots = {}
	for _, x in LOT_X do
		table.insert(lots, facing(x, -lotZ, 0, 1))
		table.insert(lots, facing(x, lotZ, 0, -1))
	end
	return {
		folder = folder,
		lots = lots,
		plazaSpawn = plazaSpawn,
		homePad = homePad,
	}
end

return City
