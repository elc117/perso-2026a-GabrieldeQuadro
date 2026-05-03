# Backend Web com Haskell+Scotty

## 1. Identificação

- Nome: Gabriel de Quadro Schutz da Silva	
- Curso: Sistemas de informação

---

## 2. Tema/objetivo

Gostaria de fazer um mini jogo com pontuações e afins com a temática de quem é esse pokémon, podendo ser expandido para mais uma página para a montagem de um time

Explique qual é a lógica principal do serviço e como o trabalho aplica programação funcional.

---

## 3. Processo de desenvolvimento

Acredito que também seja importante pontuar que tentei treinar meu inglês durante o desenvolvimento do projeto, usei bastante o tradutor e coloquei comentarios em portugues para relembrar oque cada função faz.

Comecei com uma ideia simples, onde eu faria apenas um PokéGuess, onde teria a pontuação, então no começo da ideia, cada acerto valeria 100 pontos, e iria aumentando a pontuação de acordo com a quantidade de acertos, uma aba para mostrar a pontuação, e uma aba para o time, time o qual seria feito colocando o ID do pokemon, após o primeiro olhar percebi que não fazia muito sentido e nem ficaria divertido, então coloquei algumas outras coisas, mudei o score para algo decrementativo (começando de 1000 pontos e decremento a cada pokemon acertado, a cada tentativa errada e a cada vida perdida), os pokemons agora, são selecionados de acordo com quais você acertou, então seu time vai ser montado totalmente pelos pokemons vistos os quais foram acertados.

Os primeiros erros tiveram na sua maioria sobre compreensão do próprio haskell onde por costume colocava alguns coisas como se fossem feitas em outra linguagem e acabava não lembrando que são diferentes nesta linguagem Ex: “variavel” ++ texto para mostrar o texto, antes estava tentando usar apenas {variavel} texto ou coisas parecidas, acredito que a maior dificuldade foi a sintaxe da linguagem, onde precisei varias vezes fazer pesquisas para achar uma função que eu precisava a qual tinha um nome diferente das outras linguagens.

Passando para parte de programação, tinha muito clara em minha cabeça a estrutura do projeto, fiz um estilo de “mapa mental” de como funcionaria, não consegui tirar uma foto pois estou sem telefone porém tentei fazer algo parecido com uma ferramenta web

Então, na minha cabeça, seria muito mais simples fazer primeiro a parte de programação “pura” ou seja, as funções que pedias sem o uso da API, onde na verdade a API foi usada somente para receber a informação dos pokemons (ID, IMAGEM, NOME) Minhas funções fazem a cálculo de score, sistema decrementativo, validação de respostas, controle de tentativas, montagem automática do time, insignias/ranking,gerenciamento de jogo, regras do jogo, tratamento de acertos e erros.

Outro ponto que gerou uma grande dificuldade foi entender que o arquivo JSON esperava uma KEY e não uma string simples, fiquei por bastante tempo penando sobre este erro, então recorri a IA a qual explicou oque aconteceu, juntamente com também tive o problema com deriving (Show, Eq, Ord), usados para transformar o tipo em texto e poder imprimir, comparar e ordenar, outra dificuldade foi no .cabal, onde existiam diversas coisas desconhecidas que tive que aprender.

---

## 4. Testes

Como já fiz a matéria qualidade de software com o Professor Luis Alvaro já tinha uma pequena familiaridade com teste de software na linguagem python usando pytest então não achei muito complicado por causa da familiaridade.

Testei com o Hunit usando o arquivo spec.hs, é um pouco da ajuda da IA para criar os testes, porém compreendo totalmente que para cada teste precisamos colocar as entradas e os resultados esperados, foram testadas no total 32 funções das quais os 32 testes são feitos e um da falha (deixe uma falha casualmente por um erro de escrita para realmente testar se o arquivo estava dando certo).

exemplos do que foram verificados: 
Cálculos de pontuação, mensagem apresentada no final da “gameplay” de insignias onde é o erro deixado propositalmente


## 5. Execução
 
clonar o repertorio
git clone https://github.com/elc117/perso-2026a-GabrieldeQuadro

entrar na pasta do projeto
cd perso-2026a-GabrieldeQuadro

compilar o projeto
cabal build

executar o programa
cabal run

caso de algum erro com dependências
cabal update

O projeto foi executado com GHC e Cabal, então ambos precisam estar instalados

## 6. Deploy

Link do serviço publicado: <complete aqui>

Descreva de forma breve como você realizou o deploy a partir da base e das orientações fornecidas. Caso não tenha conseguido, explique o que tentou.

Estava pedindo pagamento para inicializar a criação do projeto então não foi possível fazê-lô.

---

## 7. Resultado final

Apresente o resultado final do trabalho, na forma de GIF animado ou vídeo curto (máximo 60s)

Você também pode acrescentar uma breve explicação sobre o que está sendo demonstrado.

---


## 8. Uso de IA 

### 8.1 Ferramentas de IA utilizadas

ChatGPT Free com GPT-5.3 
Claude Sonnet 4.6

---

### 8.2 Interações relevantes com IA

Inclua **de 3 a 5 interações relevantes** com ferramentas de IA.


#### Interação 1

- **Objetivo da consulta: Entender por que estava acontecendo um erro para mostrar o nome ou tipo do pokemon**  
- **Trecho do prompt ou resumo fiel: 
src/Team.hs:59:47: error: [GHC-39999] • No instance for ‘Ord PokemonType’ arising from a use of ‘sort’ • In the second argument of ‘(.)’, namely ‘sort’ In the second argument of ‘(.)’, namely ‘group . sort’ In the first argument of ‘($)’, namely ‘map (\ ts -> (head ts, length ts)) . group . sort’ | 59 | map (\ts -> (head ts, length ts)) . group . sort $ teamTypes team | ^^^^ Error: [Cabal-7125] Failed to build pokeguess-0.1.0.0 (which is required by exe:pokeguess from pokeguess-0.1.0.0). 
Oque pode ser?**  
(Admito que foi mais por preguiça de ler oque estava escrito, pois agora quando fui fazer o relatorio li o promp que mandei e na primeira linha já havia sido explicado)
- **O que foi aproveitado:**Foi aproveitado a fica de como adicionar e onde para resolver o problemas especificado acima  
- **O que foi modificado ou descartado:** 
Foi adicionado ord alem de eq e show.

#### Interação 2

- **Objetivo da consulta:**Resolver um problema de dependência pois não sabia oque estava acontecendo  
- **Trecho do prompt ou resumo fiel:** O tipo parser não esta sendo lido, qual pode ser o problema ?
- **O que foi aproveitado: foi aproveitado a dica que ele deu de adicionar o tipo parser para ser lido, usando aeson usando import Data.Aeson.Types (Parser)**  
- **O que foi modificado ou descartado: modifiquei para incluir o parser no meu projeto, deixando import Data.Aeson.Types (parseMaybe, Parser)**  

#### Interação 3 

- **Objetivo da consulta:*  Gerar o frontend
- **Trecho do prompt ou resumo fiel: **   usando o .zip que lhe foi enviado crie um front end de 3 telas, uma para o jogo, pontuação e montagem de time.
- **O que foi aproveitado:** Toda a parte do front end 
- **O que foi modificado ou descartado:** Após o front ser feito ainda ocorreram algumas mudanças no projeto, então tive que fazer pequenas alterações para ficar consistente com o’que foi feito  

#### Interação 4 (opcional)

- **Objetivo da consulta:**  Diminuir o tempo de pesquisa que eu precisaria para fazer todas as funções (ter um jeito mais rápido de pesquisa, ler antes e conhecer um pouco melhor a linguagem)
- **Trecho do prompt ou resumo fiel:**  Estou fazendo uma pagina web em Haskell de um jogo de adivinhar o pokemon, ele consiste em 3 telas, o jogo, pontuação e montagem do time me de quais são as principais funcionalidades  que irei usar,
Ex em python: if (i > 3)  
 tendo em vista que farei toda a parte de logica sem auxilio de IA me dê apenas a sintaxe de como seria feito.
- **O que foi aproveitado:**  Foi aproveitado um mini dicionário criado pela IA, onde fazia pesquisas quando havia duvida de qual ferramenta usar
- **O que foi modificado ou descartado:**  Não se aplica


### 8.3 Exemplo de erro, limitação ou sugestão inadequada da IA

Eu havia mandando um trecho da Main juntamente de um erro o qual eu já estava a muito tempo tentando resolver, ela me disse para adicionar uma dependencia na pagina main.

Após algum tempo teimando com a IA que a dependencia utilizada não iria mudar percebi que ela deveria ser adicionada na PokeAPI e não na main, após adiciona-lá lá o projeto funcionou

### 8.4 Comentário pessoal sobre o processo envolvendo IA

Acredito que consegui superar em grande parte a barreira de linguagem em haskell que não era muito explorada por mim, acredito que com pesquisa também seria possivel fazer, mas com a IA foi feito de jeito muito mais rapido.

## 9. Referências e créditos

Haskell Documentation
https://www.haskell.org/documentation/
GHC User Guide
https://downloads.haskell.org/ghc/latest/docs/users_guide/
Cabal Documentation
https://cabal.readthedocs.io/
Learn You a Haskell
https://learnyouahaskell.github.io/
PokeAPI
https://pokeapi.co/
Stackoverflow
https://stackoverflow.com/questions/56986372/haskell-servant-client-get-request-with-headers

Também foram usados os materiais da aula 19 para fazer o deploy na rede

Como o meu trabalho e do Diogo Rocha eram um pouco similares na ideia, no começo tivemos algumas discussões sobre como fazer a montagem dos arquivos, oque usar e como usar.
