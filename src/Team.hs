module Team where

import Game (Pokemon (..), PokemonType)
import Data.List (nub, group, sort)

-- ─────────────────────────────────────────────────────────────
-- Tipos
-- ─────────────────────────────────────────────────────────────

type Team = [Pokemon]

data TeamError
  = TeamFull              -- time já tem 6 Pokémon
  | AlreadyOnTeam         -- Pokémon já está no time
  | InvalidTeamSize Int   -- tamanho inválido ao validar
  deriving (Show, Eq)

-- ─────────────────────────────────────────────────────────────
-- Constantes
-- ─────────────────────────────────────────────────────────────

maxTeamSize :: Int
maxTeamSize = 6

-- ─────────────────────────────────────────────────────────────
-- Funções puras de time
-- ─────────────────────────────────────────────────────────────

-- | Cria um time vazio.
emptyTeam :: Team
emptyTeam = []

-- | Tenta adicionar um Pokémon ao time.
addToTeam :: Team -> Pokemon -> Either TeamError Team
addToTeam team poke
  | length team >= maxTeamSize          = Left TeamFull
  | pokemonId poke `elem` map pokemonId team = Left AlreadyOnTeam
  | otherwise                           = Right (team ++ [poke])

-- | Remove um Pokémon do time pelo ID.
removeFromTeam :: Team -> Int -> Team
removeFromTeam team pid = filter (\p -> pokemonId p /= pid) team

-- | Verifica se o time está completo (6 Pokémon).
isTeamFull :: Team -> Bool
isTeamFull team = length team == maxTeamSize

-- | Retorna quantas vagas restam no time.
teamSlotsFree :: Team -> Int
teamSlotsFree team = maxTeamSize - length team

-- | Lista todos os tipos presentes no time.
teamTypes :: Team -> [PokemonType]
teamTypes = concatMap pokemonTypes

-- | Conta quantos Pokémon de cada tipo há no time.
typeCoverage :: Team -> [(PokemonType, Int)]
typeCoverage team =
  map (\ts -> (head ts, length ts)) . group . sort $ teamTypes team

-- | Verifica se há Pokémon duplicado no time (por ID).
hasDuplicate :: Team -> Bool
hasDuplicate team =
  let ids = map pokemonId team
  in length ids /= length (nub ids)

-- | Valida um time completo, retornando erros se houver.
validateTeam :: Team -> [TeamError]
validateTeam team = concat
  [ [ InvalidTeamSize (length team)
    | length team /= maxTeamSize ]
  , [ AlreadyOnTeam
    | hasDuplicate team ]
  ]
