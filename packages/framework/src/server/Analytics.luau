-- Métricas no painel "Analytics" do Creator Dashboard (economia e funil de entrada).
local AnalyticsService = game:GetService("AnalyticsService")

local Analytics = {}

local currencyName = "Coins"

function Analytics.start(name: string)
	currencyName = name
end

-- transactionType: nome de Enum.AnalyticsEconomyTransactionType ("IAP", "Gameplay", "Shop", "ContextualPurchase", ...)
function Analytics.economy(
	player: Player,
	isSource: boolean,
	amount: number,
	balance: number,
	transactionType: string,
	sku: string?
)
	if amount <= 0 then
		return
	end
	local flow = if isSource then Enum.AnalyticsEconomyFlowType.Source else Enum.AnalyticsEconomyFlowType.Sink
	local ok, err = pcall(function()
		AnalyticsService:LogEconomyEvent(player, flow, currencyName, amount, balance, transactionType, sku)
	end)
	if not ok then
		warn("[Analytics] economy: " .. tostring(err))
	end
end

-- Passo do funil de entrada (1 = entrou, 2 = primeira ação, ...). Registra cada passo uma vez por jogador.
function Analytics.funnel(player: Player, data: { [string]: any }, step: number, stepName: string)
	data.funnel = data.funnel or {}
	local key = tostring(step)
	if data.funnel[key] then
		return
	end
	data.funnel[key] = true
	local ok, err = pcall(function()
		AnalyticsService:LogOnboardingFunnelStepEvent(player, step, stepName)
	end)
	if not ok then
		warn("[Analytics] funnel: " .. tostring(err))
	end
end

function Analytics.custom(player: Player, eventName: string, value: number?)
	pcall(function()
		AnalyticsService:LogCustomEvent(player, eventName, value or 1)
	end)
end

return Analytics
