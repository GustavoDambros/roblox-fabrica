local ReplicatedStorage = game:GetService("ReplicatedStorage")

local config = require(ReplicatedStorage:WaitForChild("GameConfig"))
local FrameworkClient = require(ReplicatedStorage:WaitForChild("FrameworkClient"))
local TycoonClient = require(ReplicatedStorage:WaitForChild("TycoonClient"))

FrameworkClient.start(config)
TycoonClient.start(config)
