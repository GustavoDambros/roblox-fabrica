-- Framework compartilhado (lado do servidor).
-- Uso no script principal do jogo:
--   local Framework = require(ServerScriptService.Framework)
--   Framework.start(require(ReplicatedStorage.GameConfig))
local Data = require(script.Data)
local Currency = require(script.Currency)
local Boosts = require(script.Boosts)
local Monetization = require(script.Monetization)
local AntiExploit = require(script.AntiExploit)
local Analytics = require(script.Analytics)
local Notify = require(script.Notify)

local Framework = {
	Data = Data,
	Currency = Currency,
	Boosts = Boosts,
	Monetization = Monetization,
	AntiExploit = AntiExploit,
	Analytics = Analytics,
	Notify = Notify,
}

local started = false

function Framework.start(config)
	assert(not started, "Framework.start chamado duas vezes")
	started = true

	local defaults = {
		currency = config.startingCurrency or 0,
		boosts = {},
		receipts = {},
		funnel = {},
		robuxSpent = 0,
	}
	for key, value in config.dataDefaults or {} do
		defaults[key] = value
	end

	Notify.start()
	Analytics.start(config.currencyName)
	Data.start(config.dataStoreName, defaults)
	Currency.start(config.currencyName)
	Boosts.start()
	Monetization.start(config.passes or {}, config.products or {})
	AntiExploit.start(config.antiExploit)

	Data.onLoaded(function(player, data)
		Analytics.funnel(player, data, 1, "Entrou no jogo")
	end)
end

return Framework
