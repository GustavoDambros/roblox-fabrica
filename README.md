# roblox-fabrica

Monorepo para produzir jogos Roblox em série: um framework compartilhado, modelos por gênero e uma pasta por jogo.

```
packages/framework/   código comum a todos os jogos
  src/server/         dados (DataStore com trava de sessão), moeda, boosts, Game Passes e
                      Developer Products (ProcessReceipt), anti-exploit, métricas, avisos
  src/client/         HUD de moeda, loja, avisos na tela
  src/shared/         remotes, formatação de números, tipos da configuração
templates/            mecânica de cada gênero, controlada pela configuração
  tycoon/
games/                um jogo por pasta: só configuração e o que for único dele
  pizzaria-tycoon/
    config.luau         nome, moeda, passes, produtos, melhorias, preços
    default.project.json  diz ao Rojo como montar o jogo
```

## Testar um jogo no Studio

1. Instale o [Rokit](https://github.com/rojo-rbx/rokit) e, nesta pasta, rode `rokit install` (instala Rojo, Selene e StyLua).
2. No Studio, instale o plugin do Rojo: `rojo plugin install`.
3. Rode `rojo serve games/pizzaria-tycoon/default.project.json`.
4. Abra um lugar vazio (Baseplate) no Studio, apague a Baseplate, clique em **Rojo > Connect** e depois em **Play**.

Alternativa sem instalar nada: cada pull request gera os arquivos `.rbxl` dos jogos no GitHub Actions (aba Actions > execução > Artifacts > `jogos`). Baixe e abra no Studio.

Para os dados salvarem no Studio: Game Settings > Security > **Enable Studio Access to API Services** (o jogo precisa estar publicado). Sem isso, o jogo roda com dados só em memória.

## Criar um jogo novo do mesmo gênero

1. Copie `games/pizzaria-tycoon` para `games/<nome-do-jogo>`.
2. Em `config.luau`, troque `gameName`, `currencyName`, `dataStoreName` (único por jogo), cores e melhorias.
3. Troque o `name` em `default.project.json`.

## Monetização

Passes e produtos ficam em `config.luau`. Crie cada um no Creator Dashboard (seu jogo > Monetização) e cole o ID no campo `id`; com `id = 0` o item fica escondido na loja. A entrega é sempre feita no servidor e registrada nos dados, então o jogador não recebe duas vezes nem perde a compra.
