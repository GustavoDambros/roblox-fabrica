-- Dados do jogador salvos no DataStore.
-- * Trava de sessão: o mesmo jogador não é carregado em dois servidores ao mesmo tempo
--   (evita duplicar itens trocando de servidor).
-- * Salvamento automático a cada 60 s, ao sair e quando o servidor fecha.
-- * No Studio sem "Enable Studio Access to API Services", roda só em memória.
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local AUTOSAVE_INTERVAL = 60
local LOCK_EXPIRES_AFTER = 300 -- trava abandonada (servidor caiu) expira após 5 min
local LOAD_ATTEMPTS = 5
local RETRY_DELAY = 4

local Data = {}

local store: DataStore? = nil
local defaults: { [string]: any } = {}
local profiles: { [Player]: { [string]: any } } = {}
local memoryOnly: { [Player]: boolean } = {}
local loadedEvent = Instance.new("BindableEvent")
local started = false

local function deepCopy(value: any): any
	if type(value) ~= "table" then
		return value
	end
	local copy = {}
	for k, v in value do
		copy[k] = deepCopy(v)
	end
	return copy
end

-- Preenche campos novos que foram adicionados à configuração depois que o jogador já tinha dados.
local function reconcile(target: { [string]: any }, template: { [string]: any })
	for k, v in template do
		if target[k] == nil then
			target[k] = deepCopy(v)
		elseif type(v) == "table" and type(target[k]) == "table" then
			reconcile(target[k], v)
		end
	end
end

local function keyFor(player: Player): string
	return "player_" .. player.UserId
end

local function loadAsync(player: Player): ({ [string]: any }?, boolean)
	if not store then
		return deepCopy(defaults), true
	end
	local now
	for attempt = 1, LOAD_ATTEMPTS do
		local lockedByOther = false
		local ok, result = pcall(function()
			return (store :: DataStore):UpdateAsync(keyFor(player), function(old)
				lockedByOther = false
				now = os.time()
				local record = old or { data = deepCopy(defaults) }
				local lock = record.lock
				local isLastAttempt = attempt == LOAD_ATTEMPTS
				if lock and lock.jobId ~= game.JobId and now - lock.time < LOCK_EXPIRES_AFTER and not isLastAttempt then
					lockedByOther = true
					return nil -- cancela a escrita e tenta de novo
				end
				record.lock = { jobId = game.JobId, time = now }
				return record
			end)
		end)
		if ok and result and not lockedByOther then
			local data = result.data or deepCopy(defaults)
			reconcile(data, defaults)
			return data, false
		end
		if not ok then
			warn(
				string.format("[Data] Falha ao carregar %s (tentativa %d): %s", player.Name, attempt, tostring(result))
			)
			if RunService:IsStudio() and string.find(tostring(result), "API", 1, true) then
				warn("[Data] Studio sem acesso a API: usando dados só em memória.")
				return deepCopy(defaults), true
			end
		end
		if not player.Parent then
			return nil, false
		end
		task.wait(RETRY_DELAY)
	end
	return nil, false
end

local function saveAsync(player: Player, release: boolean): boolean
	local data = profiles[player]
	if not data or not store or memoryOnly[player] then
		return true
	end
	local ok, err = pcall(function()
		(store :: DataStore):UpdateAsync(keyFor(player), function(old)
			local record = old or {}
			if record.lock and record.lock.jobId ~= game.JobId then
				return nil -- outro servidor assumiu; não sobrescreve
			end
			record.data = data
			record.lock = if release then nil else { jobId = game.JobId, time = os.time() }
			return record
		end)
	end)
	if not ok then
		warn(string.format("[Data] Falha ao salvar %s: %s", player.Name, tostring(err)))
	end
	return ok
end

local function onPlayerAdded(player: Player)
	local data, inMemory = loadAsync(player)
	if not player.Parent then
		return
	end
	if not data then
		player:Kick("Não foi possível carregar seus dados. Tente entrar de novo em alguns instantes.")
		return
	end
	profiles[player] = data
	memoryOnly[player] = inMemory
	loadedEvent:Fire(player, data)
end

local function onPlayerRemoving(player: Player)
	if profiles[player] then
		saveAsync(player, true)
	end
	profiles[player] = nil
	memoryOnly[player] = nil
end

function Data.start(dataStoreName: string, dataDefaults: { [string]: any })
	assert(not started, "Data.start chamado duas vezes")
	started = true
	defaults = dataDefaults
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore(dataStoreName)
	end)
	if ok then
		store = result
	else
		warn("[Data] DataStore indisponível, dados só em memória: " .. tostring(result))
	end

	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerAdded, player)
	end

	task.spawn(function()
		while true do
			task.wait(AUTOSAVE_INTERVAL)
			for player in profiles do
				task.spawn(saveAsync, player, false)
			end
		end
	end)

	game:BindToClose(function()
		if RunService:IsStudio() and not store then
			return
		end
		local pending = 0
		for player in profiles do
			pending += 1
			task.spawn(function()
				saveAsync(player, true)
				pending -= 1
			end)
		end
		local deadline = os.clock() + 25
		while pending > 0 and os.clock() < deadline do
			task.wait(0.1)
		end
	end)
end

-- Dados já carregados do jogador, ou nil.
function Data.get(player: Player): { [string]: any }?
	return profiles[player]
end

-- Espera os dados carregarem. Retorna nil se o jogador sair antes.
function Data.waitFor(player: Player): { [string]: any }?
	while player.Parent and not profiles[player] do
		task.wait(0.1)
	end
	return profiles[player]
end

-- Chama `callback(player, data)` para cada jogador quando os dados carregam (inclusive os já carregados).
function Data.onLoaded(callback: (Player, { [string]: any }) -> ())
	for player, data in profiles do
		task.spawn(callback, player, data)
	end
	loadedEvent.Event:Connect(callback)
end

-- Salva agora (usado depois de compras com Robux).
function Data.saveNow(player: Player): boolean
	return saveAsync(player, false)
end

return Data
