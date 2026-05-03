module Game where

import Score (GuessResult (..), calcCost, evalAttempt)

-- ─────────────────────────────────────────────────────────────
-- Tipos
-- ─────────────────────────────────────────────────────────────

data PokemonType
  = Fire | Water | Grass | Electric | Psychic | Normal
  | Rock | Ground | Flying | Bug | Poison | Ghost
  | Dragon | Dark | Steel | Ice | Fairy | Fighting
  deriving (Show, Eq, Ord)

data Pokemon = Pokemon
  { pokemonId     :: Int
  , pokemonName   :: String
  , pokemonTypes  :: [PokemonType]
  , pokemonSprite :: String
  } deriving (Show, Eq)

data Hint
  = HintFirstLetter
  | HintType
  | HintGeneration
  deriving (Show, Eq, Ord)

-- Estado de uma rodada individual (um Pokémon)
data RoundState = RoundState
  { roundPokemon  :: Pokemon
  , roundAttempts :: Int
  , roundHints    :: [Hint]
  , maxAttempts   :: Int
  } deriving (Show)

-- Resultado de uma tentativa de palpite
data RoundOutcome = RoundOutcome
  { outcomeResult :: GuessResult
  , outcomeCost   :: Int       -- quanto será decrementado da sessão
  } deriving (Show)

-- Estado da sessão completa do jogador
data SessionState = SessionState
  { sessionScore       :: Int      -- pontos restantes (começa em 1000)
  , sessionLives       :: Int      -- vidas restantes (começa em 3)
  , sessionCorrect     :: Int      -- Pokémon acertados
  , sessionActive      :: Bool     -- sessão ainda em andamento
  } deriving (Show)

-- ─────────────────────────────────────────────────────────────
-- Funções puras do jogo
-- ─────────────────────────────────────────────────────────────

-- | Cria uma sessão nova.
newSession :: SessionState
newSession = SessionState
  { sessionScore   = 1000
  , sessionLives   = 3
  , sessionCorrect = 0
  , sessionActive  = True
  }

-- | Verifica se a sessão ainda está ativa.
isSessionOver :: SessionState -> Bool
isSessionOver s = not (sessionActive s)

-- | Cria um novo estado de rodada para um Pokémon.
newRound :: Pokemon -> RoundState
newRound poke = RoundState
  { roundPokemon  = poke
  , roundAttempts = 0
  , roundHints    = []
  , maxAttempts   = 5
  }

-- | Processa um palpite, retornando novo estado de rodada e o resultado.
makeGuess :: RoundState -> String -> (RoundState, RoundOutcome)
makeGuess state guess =
  let attempts' = roundAttempts state + 1
      answer    = pokemonName (roundPokemon state)
      result    = evalAttempt answer guess attempts' (maxAttempts state)
      cost      = calcCost attempts' (length (roundHints state)) (result == Correct)
      state'    = state { roundAttempts = attempts' }
  in (state', RoundOutcome result cost)

-- | Aplica o resultado de uma rodada na sessão.
--   Acerto: decrementa custo, incrementa acertos.
--   Erro (TooManyAttempts): decrementa custo, perde 1 vida.
--   Se vidas chegam a 0, encerra a sessão.
applyOutcome :: SessionState -> RoundOutcome -> SessionState
applyOutcome session outcome =
  case outcomeResult outcome of
    Correct ->
      session
        { sessionScore   = max 0 (sessionScore session - outcomeCost outcome)
        , sessionCorrect = sessionCorrect session + 1
        }
    TooManyAttempts ->
      let lives' = sessionLives session - 1
          score' = max 0 (sessionScore session - outcomeCost outcome)
      in session
        { sessionScore  = score'
        , sessionLives  = lives'
        , sessionActive = lives' > 0
        }
    Wrong -> session  -- Wrong não encerra rodada, só muda RoundState

-- | Adiciona uma dica ao estado da rodada, se ainda não foi usada.
useHint :: RoundState -> Hint -> Either String RoundState
useHint state hint
  | hint `elem` roundHints state = Left "Dica já utilizada."
  | otherwise = Right $ state { roundHints = hint : roundHints state }

-- | Gera o texto da dica com base no tipo e no Pokémon.
hintText :: Hint -> Pokemon -> String
hintText HintFirstLetter poke =
  case pokemonName poke of
    []    -> "Sem nome disponível."
    (c:_) -> "A primeira letra é: " ++ [c]
hintText HintType poke =
  "Tipo(s): " ++ unwords (map show (pokemonTypes poke))
hintText HintGeneration poke =
  "Geração: " ++ show (generationOf (pokemonId poke))

-- | Determina a geração de um Pokémon pelo ID nacional.
generationOf :: Int -> Int
generationOf pid
  | pid <=  151 = 1
  | pid <=  251 = 2
  | pid <=  386 = 3
  | pid <=  493 = 4
  | pid <=  649 = 5
  | pid <=  721 = 6
  | pid <=  809 = 7
  | pid <=  905 = 8
  | otherwise   = 9

-- | Quantas tentativas restam na rodada atual.
attemptsLeft :: RoundState -> Int
attemptsLeft state = maxAttempts state - roundAttempts state

-- | Verifica se a rodada ainda está ativa.
isRoundActive :: RoundState -> Bool
isRoundActive state = roundAttempts state < maxAttempts state
