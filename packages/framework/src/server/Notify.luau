-- Mensagens rápidas na tela do jogador (toast).
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("FrameworkShared")
local Remotes = require(Shared:WaitForChild("Remotes"))

local Notify = {}

local remote: RemoteEvent? = nil

function Notify.start()
	remote = Remotes.event("Notify")
end

-- kind: "info" | "success" | "error"
function Notify.send(player: Player, text: string, kind: string?)
	if remote then
		remote:FireClient(player, text, kind or "info")
	end
end

function Notify.all(text: string, kind: string?)
	if remote then
		remote:FireAllClients(text, kind or "info")
	end
end

return Notify
