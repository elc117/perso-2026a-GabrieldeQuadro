module Main where

import Test.HUnit
import Score
import Game
import Team

-- ─────────────────────────────────────────────────────────────
-- Helper
-- ─────────────────────────────────────────────────────────────

assertRight :: Show e => Either e a -> IO a
assertRight (Right x) = return x
assertRight (Left e)  = assertFailure ("Esperado Right, obteve Left: " ++ show e)
                        >> return (error "unreachable")

-- ─────────────────────────────────────────────────────────────
-- Testes de Score
-- ─────────────────────────────────────────────────────────────

-- custo mínimo: acerto na 1ª tentativa, sem dicas
testCostMinimal :: Test
testCostMinimal = TestCase $
  assertEqual "custo mínimo = 30"
    30 (calcCost 1 0 True)

-- penalidade por tentativa: +20 por tentativa extra
testCostAttemptPenalty :: Test
testCostAttemptPenalty = TestCase $
  assertEqual "custo na 3ª tentativa = 30 + 2*20 = 70"
    70 (calcCost 3 0 True)

-- penalidade por dica: +10 por dica
testCostHintPenalty :: Test
testCostHintPenalty = TestCase $
  assertEqual "custo com 2 dicas = 30 + 2*10 = 50"
    50 (calcCost 1 2 True)

-- ao errar (perder vida): custo fixo de 150
testCostWrong :: Test
testCostWrong = TestCase $
  assertEqual "custo ao errar = 150"
    150 (calcCost 1 0 False)

-- applyRoundCost nunca vai abaixo de 0
testApplyFloor :: Test
testApplyFloor = TestCase $
  assertEqual "score não fica negativo"
    0 (applyRoundCost 50 200)

-- applyRoundCost descrementa corretamente
testApplyCost :: Test
testApplyCost = TestCase $
  assertEqual "1000 - 30 = 970"
    970 (applyRoundCost 1000 30)

-- validateGuess: case-insensitive
testValidateCase :: Test
testValidateCase = TestCase $
  assertBool "Pikachu == PIKACHU"
    (validateGuess "pikachu" "PIKACHU")

-- validateGuess: ignora espaços
testValidateSpaces :: Test
testValidateSpaces = TestCase $
  assertBool "mr mime == mrmime"
    (validateGuess "mr mime" "mrmime")

-- validateGuess: errado
testValidateWrong :: Test
testValidateWrong = TestCase $
  assertBool "bulbasaur /= charmander"
    (not $ validateGuess "bulbasaur" "charmander")

-- calcBadge: sem acertos
testBadgeNone :: Test
testBadgeNone = TestCase $
  assertEqual "0 acertos = NoBadge" NoBadge (calcBadge 0)

-- calcBadge: insígnias individuais
testBadgeN :: Test
testBadgeN = TestCase $ do
  assertEqual "3 acertos = Badge 3" (Badge 3) (calcBadge 3)
  assertEqual "8 acertos = Badge 8" (Badge 8) (calcBadge 8)

-- calcBadge: Elite dos Quatro
testBadgeElite :: Test
testBadgeElite = TestCase $ do
  assertEqual "9 acertos = EliteFour"  EliteFour (calcBadge 9)
  assertEqual "12 acertos = EliteFour" EliteFour (calcBadge 12)

-- calcBadge: Campeão
testBadgeChampion :: Test
testBadgeChampion = TestCase $
  assertEqual "13 acertos = Champion" Champion (calcBadge 13)

-- badgeLabel
testBadgeLabel :: Test
testBadgeLabel = TestCase $ do
  assertEqual "label NoBadge"   "Sem insígnias"    (badgeLabel NoBadge)
  assertEqual "label Badge 1"   "1 Insígnia"        (badgeLabel (Badge 1))
  assertEqual "label Badge 5"   "5 Insígnias"       (badgeLabel (Badge 5))
  assertEqual "label EliteFour" "Elite dos Quatro"  (badgeLabel EliteFour)
  assertEqual "label Champion"  "Campeão Pokémon"   (badgeLabel Champion)

-- totalScore / playerRank
testTotalScore :: Test
testTotalScore = TestCase $
  assertEqual "soma" 250 (totalScore [100, 80, 70])

testPlayerRank :: Test
testPlayerRank = TestCase $
  assertEqual "rank 2" 2 (playerRank 80 [100, 80, 60])

-- ─────────────────────────────────────────────────────────────
-- Testes de Game
-- ─────────────────────────────────────────────────────────────

mockPokemon :: Pokemon
mockPokemon = Pokemon
  { pokemonId    = 25
  , pokemonName  = "pikachu"
  , pokemonTypes = [Electric]
  , pokemonSprite = "https://example.com/pikachu.png"
  }

-- newSession
testNewSession :: Test
testNewSession = TestCase $ do
  let s = newSession
  assertEqual "score inicial 1000" 1000 (sessionScore s)
  assertEqual "vidas iniciais 3"   3    (sessionLives s)
  assertEqual "acertos iniciais 0" 0    (sessionCorrect s)
  assertBool  "sessão ativa"            (sessionActive s)

-- newRound
testNewRound :: Test
testNewRound = TestCase $ do
  let r = newRound mockPokemon
  assertEqual "0 tentativas" 0  (roundAttempts r)
  assertEqual "0 dicas"      [] (roundHints r)

-- makeGuess correto
testMakeGuessCorrect :: Test
testMakeGuessCorrect = TestCase $ do
  let r = newRound mockPokemon
      (_, outcome) = makeGuess r "pikachu"
  assertEqual "resultado Correct" Correct (outcomeResult outcome)
  assertEqual "custo mínimo 30"   30      (outcomeCost outcome)

-- makeGuess errado
testMakeGuessWrong :: Test
testMakeGuessWrong = TestCase $ do
  let r = newRound mockPokemon
      (r', outcome) = makeGuess r "bulbasaur"
  assertEqual "resultado Wrong" Wrong (outcomeResult outcome)
  assertEqual "tentativas = 1"  1     (roundAttempts r')

-- applyOutcome: acerto incrementa correct e decrementa score
testApplyOutcomeCorrect :: Test
testApplyOutcomeCorrect = TestCase $ do
  let s = newSession
      outcome = RoundOutcome Correct 30
      s' = applyOutcome s outcome
  assertEqual "score 970"    970 (sessionScore s')
  assertEqual "correct 1"    1   (sessionCorrect s')
  assertEqual "vidas 3"      3   (sessionLives s')
  assertBool  "sessão ativa"     (sessionActive s')

-- applyOutcome: erro perde vida
testApplyOutcomeLoseLife :: Test
testApplyOutcomeLoseLife = TestCase $ do
  let s = newSession
      outcome = RoundOutcome TooManyAttempts 150
      s' = applyOutcome s outcome
  assertEqual "score 850" 850 (sessionScore s')
  assertEqual "vidas 2"   2   (sessionLives s')
  assertBool  "ainda ativa"   (sessionActive s')

-- applyOutcome: última vida encerra sessão
testApplyOutcomeGameOver :: Test
testApplyOutcomeGameOver = TestCase $ do
  let s = newSession { sessionLives = 1 }
      outcome = RoundOutcome TooManyAttempts 150
      s' = applyOutcome s outcome
  assertEqual "vidas 0"       0     (sessionLives s')
  assertBool  "sessão inativa" (not (sessionActive s'))

-- generationOf
testGenerationOf :: Test
testGenerationOf = TestCase $ do
  assertEqual "gen 1" 1 (generationOf 25)
  assertEqual "gen 2" 2 (generationOf 249)
  assertEqual "gen 3" 3 (generationOf 384)

-- useHint duplicado
testUseHintDuplicate :: Test
testUseHintDuplicate = TestCase $ do
  let r = newRound mockPokemon
  r' <- assertRight (useHint r HintType)
  case useHint r' HintType of
    Left err -> assertEqual "erro duplicado" "Dica já utilizada." err
    Right _  -> assertFailure "deveria falhar"

-- hintText
testHintFirstLetter :: Test
testHintFirstLetter = TestCase $
  assertEqual "primeira letra"
    "A primeira letra é: p" (hintText HintFirstLetter mockPokemon)

-- ─────────────────────────────────────────────────────────────
-- Testes de Team
-- ─────────────────────────────────────────────────────────────

makePoke :: Int -> String -> Pokemon
makePoke pid name = Pokemon pid name [Normal] ""

testAddToTeam :: Test
testAddToTeam = TestCase $ do
  team <- assertRight (addToTeam emptyTeam (makePoke 1 "bulbasaur"))
  assertEqual "1 Pokémon" 1 (length team)

testTeamFull :: Test
testTeamFull = TestCase $ do
  let pokes = map (\i -> makePoke i (show i)) [1..6]
  team <- assertRight $ foldl (\acc p -> acc >>= (`addToTeam` p)) (Right emptyTeam) pokes
  case addToTeam team (makePoke 99 "extra") of
    Left TeamFull -> return ()
    _             -> assertFailure "deveria ser TeamFull"

testAlreadyOnTeam :: Test
testAlreadyOnTeam = TestCase $ do
  team <- assertRight (addToTeam emptyTeam (makePoke 1 "bulbasaur"))
  case addToTeam team (makePoke 1 "bulbasaur") of
    Left AlreadyOnTeam -> return ()
    _                  -> assertFailure "deveria ser AlreadyOnTeam"

testRemoveFromTeam :: Test
testRemoveFromTeam = TestCase $ do
  team <- assertRight (addToTeam emptyTeam (makePoke 1 "bulbasaur"))
  assertEqual "vazio após remoção" 0 (length (removeFromTeam team 1))

testTeamSlotsFree :: Test
testTeamSlotsFree = TestCase $ do
  team <- assertRight (addToTeam emptyTeam (makePoke 1 "bulbasaur"))
  assertEqual "5 vagas livres" 5 (teamSlotsFree team)

testHasDuplicate :: Test
testHasDuplicate = TestCase $ do
  let poke = makePoke 1 "bulbasaur"
  assertBool "duplicata detectada" (hasDuplicate [poke, poke])

-- ─────────────────────────────────────────────────────────────
-- Agrupamento
-- ─────────────────────────────────────────────────────────────

scoreTests :: Test
scoreTests = TestList
  [ TestLabel "custo mínimo"        testCostMinimal
  , TestLabel "custo tentativas"    testCostAttemptPenalty
  , TestLabel "custo dicas"         testCostHintPenalty
  , TestLabel "custo erro"          testCostWrong
  , TestLabel "apply floor"         testApplyFloor
  , TestLabel "apply cost"          testApplyCost
  , TestLabel "validate case"       testValidateCase
  , TestLabel "validate espaços"    testValidateSpaces
  , TestLabel "validate errado"     testValidateWrong
  , TestLabel "badge none"          testBadgeNone
  , TestLabel "badge n"             testBadgeN
  , TestLabel "badge elite"         testBadgeElite
  , TestLabel "badge champion"      testBadgeChampion
  , TestLabel "badge label"         testBadgeLabel
  , TestLabel "totalScore"          testTotalScore
  , TestLabel "playerRank"          testPlayerRank
  ]

gameTests :: Test
gameTests = TestList
  [ TestLabel "newSession"           testNewSession
  , TestLabel "newRound"             testNewRound
  , TestLabel "makeGuess correto"    testMakeGuessCorrect
  , TestLabel "makeGuess errado"     testMakeGuessWrong
  , TestLabel "applyOutcome acerto"  testApplyOutcomeCorrect
  , TestLabel "applyOutcome vida"    testApplyOutcomeLoseLife
  , TestLabel "applyOutcome gameover" testApplyOutcomeGameOver
  , TestLabel "generationOf"         testGenerationOf
  , TestLabel "useHint duplicado"    testUseHintDuplicate
  , TestLabel "hintFirstLetter"      testHintFirstLetter
  ]

teamTests :: Test
teamTests = TestList
  [ TestLabel "addToTeam"      testAddToTeam
  , TestLabel "time cheio"     testTeamFull
  , TestLabel "duplicado"      testAlreadyOnTeam
  , TestLabel "removeFromTeam" testRemoveFromTeam
  , TestLabel "slotsFree"      testTeamSlotsFree
  , TestLabel "hasDuplicate"   testHasDuplicate
  ]

allTests :: Test
allTests = TestList
  [ TestLabel "Score" scoreTests
  , TestLabel "Game"  gameTests
  , TestLabel "Team"  teamTests
  ]

main :: IO ()
main = do
  result <- runTestTT allTests
  putStrLn $ "\n✅ Testes: " ++ show (cases result) ++
             " casos, " ++ show (failures result) ++ " falhas, " ++
             show (errors result) ++ " erros."
