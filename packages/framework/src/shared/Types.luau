-- Formato da configuração de cada jogo (config.luau).

-- Developer Product: compra que pode ser repetida.
-- kind = "currency": dá `amount` de moeda.
-- kind = "boost": ativa o boost `boostKey` por `durationSeconds`.
export type Product = {
	key: string,
	id: number, -- ID do produto no Creator Dashboard (0 = ainda não criado, fica escondido na loja)
	name: string,
	description: string?,
	kind: "currency" | "boost",
	amount: number?,
	boostKey: string?,
	durationSeconds: number?,
}

-- Game Pass: compra única e permanente.
export type Pass = {
	key: string,
	id: number, -- ID do passe no Creator Dashboard (0 = ainda não criado)
	name: string,
	description: string?,
}

export type Config = {
	gameName: string,
	currencyName: string,
	startingCurrency: number,
	dataStoreName: string,
	dataDefaults: { [string]: any },
	passes: { Pass },
	products: { Product },
	antiExploit: {
		maxSpeed: number,
	}?,
	[string]: any,
}

return {}
