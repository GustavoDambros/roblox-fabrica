-- Clientes: bonecos que andam da calçada até o balcão, pagam (gorjeta no caixa) e vão embora.
-- Quanto mais melhorias a loja tem, mais clientes aparecem.
local Players = game:GetService("Players")
local PhysicsService = game:GetService("PhysicsService")

local Customers = {}

local GROUP_CUSTOMERS = "Clientes"
local GROUP_PLAYERS = "Jogadores"
local TEMPLATE_COUNT = 6
local WALK_TIMEOUT = 10

local SKIN_TONES = {
	Color3.fromRGB(255, 220, 190),
	Color3.fromRGB(234, 184, 146),
	Color3.fromRGB(198, 134, 94),
	Color3.fromRGB(141, 85, 54),
	Color3.fromRGB(95, 60, 40),
}

local templates: { Model } = {}
local random = Random.new()

local function setupCollisionGroups()
	pcall(function()
		PhysicsService:RegisterCollisionGroup(GROUP_CUSTOMERS)
		PhysicsService:RegisterCollisionGroup(GROUP_PLAYERS)
		PhysicsService:CollisionGroupSetCollidable(GROUP_CUSTOMERS, GROUP_CUSTOMERS, false)
		PhysicsService:CollisionGroupSetCollidable(GROUP_CUSTOMERS, GROUP_PLAYERS, false)
	end)
	local function tag(character: Model)
		for _, item in character:GetDescendants() do
			if item:IsA("BasePart") then
				item.CollisionGroup = GROUP_PLAYERS
			end
		end
		character.DescendantAdded:Connect(function(item)
			if item:IsA("BasePart") then
				item.CollisionGroup = GROUP_PLAYERS
			end
		end)
	end
	local function onPlayer(player: Player)
		player.CharacterAdded:Connect(tag)
		if player.Character then
			tag(player.Character)
		end
	end
	Players.PlayerAdded:Connect(onPlayer)
	for _, player in Players:GetPlayers() do
		onPlayer(player)
	end
end

-- Cria alguns modelos de cliente com cores variadas (usa o corpo padrão do Roblox).
local function loadTemplates()
	for _ = 1, TEMPLATE_COUNT do
		local description = Instance.new("HumanoidDescription")
		local skin = SKIN_TONES[random:NextInteger(1, #SKIN_TONES)]
		local shirt = Color3.fromHSV(random:NextNumber(), 0.6, random:NextNumber(0.5, 0.95))
		local pants = Color3.fromHSV(random:NextNumber(), 0.4, random:NextNumber(0.2, 0.6))
		description.HeadColor = skin
		description.LeftArmColor = skin
		description.RightArmColor = skin
		description.TorsoColor = shirt
		description.LeftLegColor = pants
		description.RightLegColor = pants
		local ok, model = pcall(function()
			return Players:CreateHumanoidModelFromDescription(description, Enum.HumanoidRigType.R15)
		end)
		if ok and model then
			model.Name = "Cliente"
			local humanoid = model:FindFirstChildOfClass("Humanoid")
			if humanoid then
				humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
				humanoid.WalkSpeed = 11
			end
			for _, item in model:GetDescendants() do
				if item:IsA("BasePart") then
					item.CollisionGroup = GROUP_CUSTOMERS
				end
			end
			table.insert(templates, model)
		else
			warn("[Clientes] Não foi possível criar um cliente: " .. tostring(model))
		end
	end
end

local function walkTo(humanoid: Humanoid, position: Vector3): boolean
	local finished, reached = false, false
	local connection = humanoid.MoveToFinished:Connect(function(success)
		finished, reached = true, success
	end)
	humanoid:MoveTo(position)
	local started = os.clock()
	while not finished and os.clock() - started < WALK_TIMEOUT and humanoid.Parent do
		task.wait(0.1)
	end
	connection:Disconnect()
	return reached
end

-- Um cliente faz o trajeto completo. `onServed()` é chamado no balcão e retorna o valor pago.
local function visit(plot, onServed: () -> number?)
	if #templates == 0 then
		return
	end
	local npc = templates[random:NextInteger(1, #templates)]:Clone()
	local humanoid = npc:FindFirstChildOfClass("Humanoid") :: Humanoid
	local root = npc:FindFirstChild("HumanoidRootPart") :: BasePart
	if not humanoid or not root then
		npc:Destroy()
		return
	end
	local path = plot:customerPath(random:NextNumber() > 0.5)
	npc:PivotTo(CFrame.lookAt(path.start, path.door))
	npc.Parent = plot.customers
	pcall(function()
		root:SetNetworkOwner(nil)
	end)

	local function gone(): boolean
		return npc.Parent == nil or plot.owner == nil
	end

	for _, point in { path.door, path.inside, path.counter } do
		walkTo(humanoid, point)
		if gone() then
			npc:Destroy()
			return
		end
	end
	task.wait(1.5)
	if gone() then
		npc:Destroy()
		return
	end
	local paid = onServed()
	if paid and paid > 0 then
		plot:floatText(root.Position + Vector3.new(0, 3, 0), "+" .. tostring(math.floor(paid)))
	end
	task.wait(0.8)
	for _, point in { path.inside, path.door, path.exit } do
		if gone() then
			break
		end
		walkTo(humanoid, point)
	end
	npc:Destroy()
end

-- options.interval(plot) -> segundos entre clientes; options.maxActive(plot) -> limite simultâneo;
-- options.onServed(plot) -> valor pago (ou nil).
function Customers.start(plots: { any }, options)
	setupCollisionGroups()
	task.spawn(loadTemplates)

	local nextVisit: { [any]: number } = {}
	local active: { [any]: number } = {}
	task.spawn(function()
		while true do
			task.wait(1)
			local now = os.clock()
			for _, plot in plots do
				if plot.owner then
					local due = nextVisit[plot] or 0
					local count = active[plot] or 0
					if now >= due and count < options.maxActive(plot) then
						nextVisit[plot] = now + options.interval(plot)
						active[plot] = count + 1
						task.spawn(function()
							local ok, err = pcall(visit, plot, function()
								return options.onServed(plot)
							end)
							if not ok then
								warn("[Clientes] " .. tostring(err))
							end
							active[plot] = math.max(0, (active[plot] or 1) - 1)
						end)
					end
				else
					nextVisit[plot] = nil
				end
			end
		end
	end)
end

return Customers
