{-# LANGUAGE OverloadedStrings #-}
module Main where

import Web.Scotty
import Data.Aeson (object, (.=), Value (..))
import Data.Aeson.Key (fromString)
import qualified Data.Aeson.KeyMap as KM
import qualified Data.Text as T
import Control.Concurrent.STM
import Data.Aeson.Types (parseMaybe, Parser)
import System.Environment (lookupEnv)
import System.Random (randomRIO)

import Game
import Score
import Team
import PokeAPI

-- ─────────────────────────────────────────────────────────────
-- Estado global
-- ─────────────────────────────────────────────────────────────

data AppState = AppState
  { currentRound   :: Maybe RoundState
  , currentSession :: SessionState
  , scoreboard     :: [(String, Int, Int, String)]
  --                     nome   pts  acertos  insígnia
  , playerTeam     :: Team
  }

initialState :: AppState
initialState = AppState
  { currentRound   = Nothing
  , currentSession = newSession
  , scoreboard     = []
  , playerTeam     = emptyTeam
  }

-- ─────────────────────────────────────────────────────────────
-- Main
-- ─────────────────────────────────────────────────────────────

main :: IO ()
main = do
  port <- lookupEnv "PORT"
  let portNum = maybe 3000 read port :: Int
  stateVar <- newTVarIO initialState
  putStrLn $ "PokéGuess rodando, porta " ++ show portNum
  scotty portNum $ do

    -- ── Sessão ────────────────────────────────────────────────

    -- Inicia uma nova partida
    post "/session/new" $ do
      reqBody    <- jsonData :: ActionM Value
      let player = extractText "player" reqBody
      liftIO $ atomically $ modifyTVar stateVar $ \s ->
        s { currentRound   = Nothing
          , currentSession = newSession
          , playerTeam     = emptyTeam
          }
      json $ object
        [ "message" .= ("Sessão iniciada! Boa sorte, " ++ player ++ "!")
        , "score"   .= (1000 :: Int)
        , "lives"   .= (3    :: Int)
        ]

    -- ── Jogo ──────────────────────────────────────────────────

    get "/game/new" $ do
      appState <- liftIO $ readTVarIO stateVar
      if isSessionOver (currentSession appState)
        then do
          status $ toEnum 400
          json $ object ["error" .= ("Sessão encerrada. Use POST /session/new" :: String)]
        else do
          pid   <- liftIO $ randomRIO (minPokemonId, maxPokemonId)
          mpoke <- liftIO $ fetchPokemon pid
          case mpoke of
            Nothing   -> do
              status $ toEnum 503
              json $ object ["error" .= ("Falha ao buscar Pokémon" :: String)]
            Just poke -> do
              let round' = newRound poke
              liftIO $ atomically $ modifyTVar stateVar $ \s ->
                s { currentRound = Just round' }
              json $ object
                [ "sprite"       .= pokemonSprite poke
                , "attemptsLeft" .= attemptsLeft round'
                , "score"        .= sessionScore   (currentSession appState)
                , "lives"        .= sessionLives   (currentSession appState)
                , "correct"      .= sessionCorrect (currentSession appState)
                ]

    post "/game/guess" $ do
      reqBody  <- jsonData :: ActionM Value
      appState <- liftIO $ readTVarIO stateVar
      let guess      = extractText "guess"  reqBody
          playerName = extractText "player" reqBody
      case currentRound appState of
        Nothing -> do
          status $ toEnum 400
          json $ object ["error" .= ("Nenhuma rodada ativa. Use GET /game/new" :: String)]
        Just round' -> do
          let (round'', outcome) = makeGuess round' guess
              session            = currentSession appState
              session'           = applyOutcome session outcome
              result             = outcomeResult outcome

          -- Se acertou, adiciona Pokémon ao time
          let team' = case result of
                Correct ->
                  case addToTeam (playerTeam appState) (roundPokemon round') of
                    Right t -> t
                    Left  _ -> playerTeam appState
                _ -> playerTeam appState

          -- Atualiza estado
          liftIO $ atomically $ modifyTVar stateVar $ \s ->
            s { currentRound   = updateRound result round''
              , currentSession = session'
              , playerTeam     = team'
              }

          -- Se sessão encerrou (perdeu última vida), salva no placar
          let sessionEnded = not (sessionActive session') && sessionActive session
          liftIO $ if sessionEnded
            then atomically $ modifyTVar stateVar $ \s ->
              s { scoreboard = saveScore playerName session' (scoreboard s) }
            else return ()

          let badge     = calcBadge (sessionCorrect session')
              gameOver  = sessionEnded
              pokeName  = pokemonName (roundPokemon round')

          json $ object
            [ "result"        .= show result
            , "pokemonName"   .= (if result /= Wrong then pokeName else "")
            , "cost"          .= outcomeCost outcome
            , "score"         .= sessionScore   session'
            , "lives"         .= sessionLives   session'
            , "correct"       .= sessionCorrect session'
            , "attemptsLeft"  .= attemptsLeft round''
            , "gameOver"      .= gameOver
            , "badge"         .= (if gameOver then badgeEmoji badge ++ " " ++ badgeLabel badge else "")
            ]

    post "/game/hint" $ do
      reqBody  <- jsonData :: ActionM Value
      appState <- liftIO $ readTVarIO stateVar
      let hintType = parseHint (extractText "hint" reqBody)
      case (currentRound appState, hintType) of
        (Nothing, _) -> do
          status $ toEnum 400
          json $ object ["error" .= ("Nenhuma rodada ativa" :: String)]
        (_, Nothing) -> do
          status $ toEnum 400
          json $ object ["error" .= ("Tipo de dica inválido" :: String)]
        (Just round', Just hint) ->
          case useHint round' hint of
            Left err -> do
              status $ toEnum 400
              json $ object ["error" .= err]
            Right round'' -> do
              let hintMsg = hintText hint (roundPokemon round'')
              liftIO $ atomically $ modifyTVar stateVar $ \s ->
                s { currentRound = Just round'' }
              json $ object ["hint" .= hintMsg]

    -- ── Placar ────────────────────────────────────────────────

    get "/scoreboard" $ do
      appState <- liftIO $ readTVarIO stateVar
      let sorted = sortByCorrect (scoreboard appState)
      json $ map (\(n, pts, cor, bdg) -> object
        [ "player"  .= n
        , "score"   .= pts
        , "correct" .= cor
        , "badge"   .= bdg
        ]) sorted

    -- ── Time ──────────────────────────────────────────────────

    get "/team" $ do
      appState <- liftIO $ readTVarIO stateVar
      json $ map (\poke -> object
        [ "id"     .= pokemonId poke
        , "name"   .= pokemonName poke
        , "types"  .= map show (pokemonTypes poke)
        , "sprite" .= pokemonSprite poke
        ]) (playerTeam appState)

    -- ── Status da sessão atual ─────────────────────────────────

    get "/session/status" $ do
      appState <- liftIO $ readTVarIO stateVar
      let sess = currentSession appState
      json $ object
        [ "score"   .= sessionScore   sess
        , "lives"   .= sessionLives   sess
        , "correct" .= sessionCorrect sess
        , "active"  .= sessionActive  sess
        ]

    -- ── Frontend estático ─────────────────────────────────────

    get "/" $ do
      setHeader "Content-Type" "text/html"
      file "static/index.html"

-- ─────────────────────────────────────────────────────────────
-- Helpers
-- ─────────────────────────────────────────────────────────────

extractText :: String -> Value -> String
extractText key (Object o) =
  case KM.lookup (fromString key) o of
    Just (String t) -> T.unpack t
    _               -> ""
extractText _ _ = ""

extractInt :: String -> Value -> Int
extractInt key (Object o) =
  case KM.lookup (fromString key) o of
    Just (Number n) -> round n
    _               -> 0
extractInt _ _ = 0

parseHint :: String -> Maybe Hint
parseHint "letter"     = Just HintFirstLetter
parseHint "type"       = Just HintType
parseHint "generation" = Just HintGeneration
parseHint _            = Nothing

-- Encerra rodada ao acertar ou esgotar tentativas mantém se errou
updateRound :: GuessResult -> RoundState -> Maybe RoundState
updateRound Correct         _ = Nothing
updateRound TooManyAttempts _ = Nothing
updateRound Wrong           r = Just r

-- Salva ou atualiza placar 
saveScore :: String
          -> SessionState
          -> [(String, Int, Int, String)]
          -> [(String, Int, Int, String)]
saveScore player sess scores =
  let badge   = calcBadge (sessionCorrect sess)
      entry   = (player, sessionScore sess, sessionCorrect sess
                , badgeEmoji badge ++ " " ++ badgeLabel badge)
      already = filter (\(n,_,_,_) -> n == player) scores
  in case already of
    -- Mantém o melhor resultado
    [(_, _, oldCorrect, _)] ->
      if sessionCorrect sess > oldCorrect
        then entry : filter (\(n,_,_,_) -> n /= player) scores
        else scores
    _ -> entry : scores

-- Ordena placar por acertos 
sortByCorrect :: [(String, Int, Int, String)] -> [(String, Int, Int, String)]
sortByCorrect []     = []
sortByCorrect (x:xs) =
  let (_, _, xc, _) = x
      bigger  = filter (\(_,_,c,_) -> c > xc) xs
      smaller = filter (\(_,_,c,_) -> c <= xc) xs
  in sortByCorrect bigger ++ [x] ++ sortByCorrect smaller