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
		style = "", -- estilo da pizzaria escolhido no primeiro acesso
	},

	antiExploit = {
		maxSpeed = 40, -- velocidade normal de andar é 16
	},

	passes = {
		{ key = "DoubleCash", id = 0, name = "Dinheiro 2x", description = "Toda a renda vale o dobro, para sempre." }, -- sugestão: 199 R$
		{
			key = "AutoCollect",
			id = 0,
			name = "Coleta automática",
			description = "O dinheiro vai direto para o seu saldo.",
		}, -- sugestão: 149 R$
		{ key = "VIP", id = 0, name = "VIP", description = "+50% de renda para sempre." }, -- sugestão: 299 R$
	},

	products = {
		{
			key = "CoinsSmall",
			id = 0,
			name = "Saco de moedas",
			description = "+5.000 Moedas",
			kind = "currency",
			amount = 5000,
		}, -- 25 R$
		{
			key = "CoinsMedium",
			id = 0,
			name = "Cofre de moedas",
			description = "+30.000 Moedas",
			kind = "currency",
			amount = 30000,
		}, -- 99 R$
		{
			key = "CoinsLarge",
			id = 0,
			name = "Caminhão de moedas",
			description = "+200.000 Moedas",
			kind = "currency",
			amount = 200000,
		}, -- 399 R$
		{
			key = "Boost2x",
			id = 0,
			name = "Renda 2x por 15 min",
			description = "Soma com o passe Dinheiro 2x.",
			kind = "boost",
			boostKey = "cash2x",
			durationSeconds = 900,
		}, -- 49 R$
		{
			key = "SkipUpgrade",
			id = 0,
			name = "Pular melhoria",
			description = "Ganha a próxima melhoria de graça.",
			kind = "currency",
		}, -- 79 R$
	},

	tycoon = {
		plotCount = 8, -- a cidade tem 8 pizzarias: coloque o máximo de jogadores do servidor em 8
		plotSize = 96,
		baseIncome = 2, -- moedas por segundo sem nenhuma melhoria
		rebirthCost = 500000, -- multiplicado pelo número do próximo rebirth
		rebirthBonus = 0.5, -- +50% de renda permanente por rebirth
		passMultipliers = { DoubleCash = 2, VIP = 1.5 },
		boostMultipliers = { cash2x = 2 },
		autoCollectPass = "AutoCollect",

		-- Estilos de pizzaria que o jogador escolhe no primeiro acesso (muda o prédio e as cores).
		styles = {
			{
				key = "italiana",
				name = "Cantina Italiana",
				description = "Tijolinho, madeira e toldo vermelho. Clássica.",
				wallColor = Color3.fromRGB(170, 85, 60),
				wallMaterial = Enum.Material.Brick,
				trimColor = Color3.fromRGB(110, 70, 45),
				floorColor = Color3.fromRGB(150, 100, 60),
				floorMaterial = Enum.Material.WoodPlanks,
				roofColor = Color3.fromRGB(90, 40, 30),
				accentColor = Color3.fromRGB(200, 40, 40),
				signColor = Color3.fromRGB(30, 90, 45),
				signTextColor = Color3.fromRGB(255, 255, 255),
				counterColor = Color3.fromRGB(120, 75, 45),
			},
			{
				key = "moderna",
				name = "Pizzaria Moderna",
				description = "Branca, minimalista, com detalhes em laranja.",
				wallColor = Color3.fromRGB(235, 235, 235),
				wallMaterial = Enum.Material.SmoothPlastic,
				trimColor = Color3.fromRGB(40, 40, 45),
				floorColor = Color3.fromRGB(215, 215, 215),
				floorMaterial = Enum.Material.Marble,
				roofColor = Color3.fromRGB(50, 50, 55),
				accentColor = Color3.fromRGB(255, 130, 0),
				signColor = Color3.fromRGB(25, 25, 30),
				signTextColor = Color3.fromRGB(255, 150, 30),
				counterColor = Color3.fromRGB(45, 45, 50),
			},
			{
				key = "express",
				name = "Pizza Express",
				description = "Amarela e vermelha, cara de fast-food.",
				wallColor = Color3.fromRGB(250, 200, 40),
				wallMaterial = Enum.Material.SmoothPlastic,
				trimColor = Color3.fromRGB(200, 30, 30),
				floorColor = Color3.fromRGB(240, 240, 240),
				floorMaterial = Enum.Material.SmoothPlastic,
				roofColor = Color3.fromRGB(200, 30, 30),
				accentColor = Color3.fromRGB(220, 30, 30),
				signColor = Color3.fromRGB(210, 30, 30),
				signTextColor = Color3.fromRGB(255, 220, 50),
				counterColor = Color3.fromRGB(200, 30, 30),
			},
		},

		-- Clientes: um a cada `customerInterval` segundos (diminui com as melhorias);
		-- cada um paga `customerTipSeconds` segundos da renda atual.
		customerInterval = 9,
		customerTipSeconds = 4,

		-- Melhorias em ordem de compra. income = moedas por segundo a mais; prop = objeto em src/server/Props.luau.
		upgrades = {
			{ key = "balcao", name = "Balcão de montagem", cost = 50, income = 2, prop = "counter" },
			{ key = "forno1", name = "Forno a lenha", cost = 200, income = 5, prop = "woodOven" },
			{ key = "mesas", name = "Mesas", cost = 600, income = 10, prop = "tables" },
			{ key = "massa", name = "Máquina de massa", cost = 1500, income = 20, prop = "doughMachine" },
			{ key = "forno2", name = "Forno duplo", cost = 4000, income = 45, prop = "deckOven" },
			{ key = "moto", name = "Moto de entrega", cost = 10000, income = 90, prop = "deliveryBike" },
			{ key = "vip", name = "Cabine VIP", cost = 25000, income = 180, prop = "vipLounge" },
			{ key = "esteira", name = "Esteira automática", cost = 60000, income = 350, prop = "conveyor" },
			{ key = "forno3", name = "Forno industrial", cost = 140000, income = 700, prop = "industrialOven" },
			{ key = "drone", name = "Drone de entrega", cost = 300000, income = 1300, prop = "drone" },
			{ key = "bebidas", name = "Geladeira de bebidas", cost = 650000, income = 2500, prop = "drinkFridge" },
			{ key = "pizzaGigante", name = "Pizza gigante", cost = 1500000, income = 5000, prop = "giantPizza" },
		},
	},
}
