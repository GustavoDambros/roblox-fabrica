local ReplicatedStorage = game:GetService("ReplicatedStorage")

local config = require(ReplicatedStorage:WaitForChild("GameConfig"))
local FrameworkClient = require(ReplicatedStorage:WaitForChild("FrameworkClient"))

FrameworkClient.start(config)
