module PokeAPI where

import Data.Aeson
import Data.Aeson.Types (parseMaybe,Parser)

import Network.HTTP.Simple
import qualified Data.ByteString.Lazy as BL
import qualified Data.Text as T
import Game (Pokemon (..), PokemonType (..))

-- ─────────────────────────────────────────────────────────────
-- Constantes
-- ─────────────────────────────────────────────────────────────

baseUrl :: String
baseUrl = "https://pokeapi.co/api/v2/pokemon/"

-- Faixa de IDs disponíveis (geração 1 a 9)
minPokemonId :: Int
minPokemonId = 1

maxPokemonId :: Int
maxPokemonId = 1025

-- ─────────────────────────────────────────────────────────────
-- Parsing do JSON da PokeAPI
-- ─────────────────────────────────────────────────────────────

-- | Converte string de tipo (da API) para PokemonType.
parseType :: String -> Maybe PokemonType
parseType t = case t of
  "fire"     -> Just Fire
  "water"    -> Just Water
  "grass"    -> Just Grass
  "electric" -> Just Electric
  "psychic"  -> Just Psychic
  "normal"   -> Just Normal
  "rock"     -> Just Rock
  "ground"   -> Just Ground
  "flying"   -> Just Flying
  "bug"      -> Just Bug
  "poison"   -> Just Poison
  "ghost"    -> Just Ghost
  "dragon"   -> Just Dragon
  "dark"     -> Just Dark
  "steel"    -> Just Steel
  "ice"      -> Just Ice
  "fairy"    -> Just Fairy
  "fighting" -> Just Fighting
  _          -> Nothing

-- | Extrai os tipos de um objeto JSON da PokeAPI.
extractTypes :: Value -> [PokemonType]
extractTypes val =
  case parseMaybe extractTypes' val of
    Just ts -> ts
    Nothing -> []
  where
    extractTypes' = withObject "pokemon" $ \obj -> do
      types <- obj .: "types"
      mapM extractSingleType types

    extractSingleType = withObject "typeSlot" $ \slot -> do
      typeObj <- slot .: "type"
      name    <- typeObj .: "name" :: Parser String
      case parseType name of
        Just t  -> return t
        Nothing -> fail $ "Unknown type: " ++ name

-- | Extrai a URL do sprite (silhueta) do JSON da PokeAPI.
extractSprite :: Value -> String
extractSprite val =
  case parseMaybe extractSprite' val of
    Just url -> url
    Nothing  -> ""
  where
    extractSprite' = withObject "pokemon" $ \obj -> do
      sprites <- obj .: "sprites"
      other   <- sprites .: "other"
      dream   <- other .: "dream_world"
      dream .: "front_default" :: Parser String

-- ─────────────────────────────────────────────────────────────
-- IO: buscar Pokémon da API
-- ─────────────────────────────────────────────────────────────

-- | Busca um Pokémon pelo ID na PokeAPI.
--   Retorna Nothing em caso de erro (ID inválido, sem conexão etc.).
fetchPokemon :: Int -> IO (Maybe Pokemon)
fetchPokemon pid = do
  let url = baseUrl ++ show pid
  request  <- parseRequest url
  response <- httpLBS request
  let body = getResponseBody response
  case eitherDecode body of
    Left _    -> return Nothing
    Right val -> do
      let name   = extractName val
          types  = extractTypes val
          sprite = extractSprite val
      return $ Just $ Pokemon
        { pokemonId     = pid
        , pokemonName   = name
        , pokemonTypes  = types
        , pokemonSprite = sprite
        }
  where
    extractName val =
      case parseMaybe (withObject "p" (.: "name")) val of
        Just n  -> n
        Nothing -> "unknown"

-- | Busca um Pokémon pelo nome na PokeAPI.
fetchPokemonByName :: String -> IO (Maybe Pokemon)
fetchPokemonByName name = do
  let url = baseUrl ++ map toLower' name
  request  <- parseRequest url
  response <- httpLBS request
  let body = getResponseBody response
  case eitherDecode body of
    Left _    -> return Nothing
    Right val -> do
      let pid    = extractId val
          types  = extractTypes val
          sprite = extractSprite val
      return $ Just $ Pokemon
        { pokemonId     = pid
        , pokemonName   = name
        , pokemonTypes  = types
        , pokemonSprite = sprite
        }
  where
    toLower' c = if c >= 'A' && c <= 'Z'
                 then toEnum (fromEnum c + 32)
                 else c
    extractId val =
      case parseMaybe (withObject "p" (.: "id")) val of
        Just i  -> i
        Nothing -> 0
