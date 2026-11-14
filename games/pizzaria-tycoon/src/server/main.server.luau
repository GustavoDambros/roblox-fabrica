local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local config = require(ReplicatedStorage:WaitForChild("GameConfig"))
local Framework = require(ServerScriptService:WaitForChild("Framework"))
local Tycoon = require(ServerScriptService:WaitForChild("Tycoon"))
local Props = require(script.Parent:WaitForChild("Props"))

Framework.start(config)
Tycoon.start(config, Framework, { props = Props })
