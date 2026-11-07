-- Configuração do jogo "Pizzaria Tycoon".
-- Para criar um jogo novo do mesmo gênero: copie esta pasta, troque nomes, cores, melhorias e preços.
--
-- IDs de passes e produtos: crie em create.roblox.com > seu jogo > Monetização, e cole o número em `id`.
-- Enquanto o id for 0, o item fica escondido na loja.
-- Preços em Robux são definidos no Creator Dashboard; os sugeridos estão nos comentários.

return {
	gameName = "Pizzaria Tycoon",
	currencyName = "Moedas",
	startingCurrency = 0,
	dataStoreName = "PizzariaTycoon_v1",

	-- Campos extras salvos para cada jogador (além de moeda, boosts e compras, que o framework já guarda).
	dataDefaults = {
		upgrades = {},
		rebirths = 0,
	},

	antiExploit = {
		maxSpeed = 40, -- velocidade normal de andar é 16
	},

	passes = {
		{ key = "DoubleCash", id = 0, name = "Dinheiro 2x", description = "Toda a renda vale o dobro, para sempre." }, -- sugestão: 199 R$
		{ key = "AutoCollect", id = 0, name = "Coleta automática", description = "O dinheiro vai direto para o seu saldo." }, -- sugestão: 149 R$
		{ key = "VIP", id = 0, name = "VIP", description = "+50% de renda para sempre." }, -- sugestão: 299 R$
	},

	products = {
		{ key = "CoinsSmall", id = 0, name = "Saco de moedas", description = "+5.000 Moedas", kind = "currency", amount = 5000 }, -- 25 R$
		{ key = "CoinsMedium", id = 0, name = "Cofre de moedas", description = "+30.000 Moedas", kind = "currency", amount = 30000 }, -- 99 R$
		{ key = "CoinsLarge", id = 0, name = "Caminhão de moedas", description = "+200.000 Moedas", kind = "currency", amount = 200000 }, -- 399 R$
		{
			key = "Boost2x",
			id = 0,
			name = "Renda 2x por 15 min",
			description = "Soma com o passe Dinheiro 2x.",
			kind = "boost",
			boostKey = "cash2x",
			durationSeconds = 900,
		}, -- 49 R$
		{ key = "SkipUpgrade", id = 0, name = "Pular melhoria", description = "Ganha a próxima melhoria de graça.", kind = "currency" }, -- 79 R$
	},

	tycoon = {
		plotCount = 8, -- coloque o máximo de jogadores do servidor igual a este número
		plotSize = 96,
		groundColor = Color3.fromRGB(86, 150, 70),
		floorColor = Color3.fromRGB(230, 220, 200),
		baseIncome = 2, -- moedas por segundo sem nenhuma melhoria
		rebirthCost = 500000, -- multiplicado pelo número do próximo rebirth
		rebirthBonus = 0.5, -- +50% de renda permanente por rebirth
		passMultipliers = { DoubleCash = 2, VIP = 1.5 },
		boostMultipliers = { cash2x = 2 },
		autoCollectPass = "AutoCollect",

		-- Melhorias em ordem de compra. income = moedas por segundo a mais.
		upgrades = {
			{ key = "balcao", name = "Balcão", cost = 50, income = 2, height = 4, color = Color3.fromRGB(160, 110, 70) },
			{ key = "forno1", name = "Forno a lenha", cost = 200, income = 5, height = 8, color = Color3.fromRGB(170, 60, 40) },
			{ key = "mesa1", name = "Mesas", cost = 600, income = 10, height = 3, color = Color3.fromRGB(210, 180, 140) },
			{ key = "massa", name = "Máquina de massa", cost = 1500, income = 20, height = 7, color = Color3.fromRGB(200, 200, 210) },
			{ key = "forno2", name = "Forno duplo", cost = 4000, income = 45, height = 10, color = Color3.fromRGB(190, 70, 40) },
			{ key = "delivery", name = "Moto delivery", cost = 10000, income = 90, height = 5, color = Color3.fromRGB(220, 40, 40) },
			{ key = "salao", name = "Salão VIP", cost = 25000, income = 180, height = 12, color = Color3.fromRGB(240, 200, 60) },
			{ key = "esteira", name = "Esteira automática", cost = 60000, income = 350, height = 6, color = Color3.fromRGB(90, 90, 100) },
			{ key = "forno3", name = "Forno industrial", cost = 140000, income = 700, height = 16, color = Color3.fromRGB(150, 40, 30) },
			{ key = "drone", name = "Drone de entrega", cost = 300000, income = 1300, height = 9, color = Color3.fromRGB(60, 120, 220) },
			{ key = "franquia", name = "Franquia", cost = 650000, income = 2500, height = 20, color = Color3.fromRGB(230, 120, 30) },
			{ key = "torre", name = "Torre da Pizza", cost = 1500000, income = 5000, height = 30, color = Color3.fromRGB(250, 230, 120) },
		},
	},
}
