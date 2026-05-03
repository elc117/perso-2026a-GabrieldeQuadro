module Score where

import Data.Char (toLower)



data GuessResult
  = Correct
  | Wrong
  | TooManyAttempts
  deriving (Show, Eq)

data Badge
  = NoBadge           -- 0 acertos
  | Badge Int         -- 1–8 insígnias
  | EliteFour         -- 9–12 acertos
  | Champion          -- 13+ acertos
  deriving (Show, Eq)


initialSessionScore :: Int
initialSessionScore = 1000

maxLives :: Int
maxLives = 3

-- Custo por Pokémon acertado
-- Penalidade mínima garantida por acerto
minCostPerCorrect :: Int
minCostPerCorrect = 30

-- Penalidade por tentativa errada dentro de uma rodada
penaltyPerAttempt :: Int
penaltyPerAttempt = 20

-- Penalidade por dica usada
penaltyPerHint :: Int
penaltyPerHint = 10

-- Penalidade ao perder uma vida (errar um Pokémon inteiro)
penaltyPerLife :: Int
penaltyPerLife = 150

-- ─────────────────────────────────────────────────────────────
-- Funções de pontuação
-- ─────────────────────────────────────────────────────────────

--   Calcula o custo de uma rodada (quanto será decrementado do score).
--   Acerto: custo mínimo + penalidades por tentativas e dicas
--   Erro:   penalidade fixa por vida perdida
calcCost :: Int   
         -> Int   
         -> Bool  
         -> Int
calcCost attempts hintsUsed correct
  | correct   = minCostPerCorrect
              + (attempts - 1) * penaltyPerAttempt
              + hintsUsed * penaltyPerHint
  | otherwise = penaltyPerLife

-- Aplica o custo a pontuacao
applyRoundCost :: Int -- score atual
               -> Int -- custo da rdada
               -> Int
applyRoundCost sessionScore cost = max 0 (sessionScore - cost)

-- Normaliza string
normalize :: String -> String
normalize = map toLower . filter (/= ' ')

-- resposta correta ou nçao.
validateGuess :: String -> String -> Bool
validateGuess answer guess = normalize answer == normalize guess

-- resultado da tentativa
evalAttempt :: String -> String -> Int -> Int -> GuessResult
evalAttempt answer guess attempts maxAttempts
  | validateGuess answer guess = Correct
  | attempts >= maxAttempts    = TooManyAttempts
  | otherwise                  = Wrong

-- insignia baseada 
calcBadge :: Int -> Badge
calcBadge correct
  | correct == 0        = NoBadge
  | correct <= 8        = Badge correct
  | correct <= 12       = EliteFour
  | otherwise           = Champion

-- Texto insígnia.
badgeLabel :: Badge -> String
badgeLabel NoBadge     = "Sem insígnias"
badgeLabel (Badge n)   = show n ++ " insignias"
badgeLabel EliteFour   = "Elite dos Quatro"
badgeLabel Champion    = "Campeao Pokémon"

-- Emoji da insígnia.
badgeEmoji :: Badge -> String
badgeEmoji NoBadge     = "💀"
badgeEmoji (Badge _)   = "🥇"
badgeEmoji EliteFour   = "🏆"
badgeEmoji Champion    = "👑"

-- placar total.
totalScore :: [Int] -> Int
totalScore = sum

-- recebe scores.
playerRank :: Int -> [Int] -> Int
playerRank score scores = length (filter (> score) scores) + 1
