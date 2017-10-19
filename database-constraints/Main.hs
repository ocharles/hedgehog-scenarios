{-# LANGUAGE PolyKinds #-}

module Main where

import Control.Monad.IO.Class
import Control.Monad
import System.IO.Unsafe
import Data.IORef
import Hedgehog
import qualified Hedgehog.Gen as Gen
import qualified Hedgehog.Range as Range

data User = User
  { userName :: String }

data State v = State
  { stateUsers :: [ Var User v ] }

data CreateUser v = CreateUser String
  deriving (Show)

instance HTraversable CreateUser where
  htraverse _ (CreateUser a) = pure (CreateUser a)

createUserCommand =
  Command
    { commandGen = \_ ->
        Just (CreateUser <$> Gen.string (Range.linear 1 1) Gen.ascii)
    , commandExecute = \(CreateUser name) ->
        liftIO (doCreateUser name)
    , commandCallbacks =
        [ Update $ \before _input output ->
            before { stateUsers = stateUsers before ++ [ output ] }
        ]
    }

main :: IO ()
main = do
  check $ property $ do
    commands <- forAll $
      Gen.sequential (Range.linear 1 100) (State []) [ createUserCommand ]

    executeSequential (State []) commands

  return ()

knownUsers :: IORef [User]
knownUsers = unsafePerformIO (newIORef [])
{-# NOINLINE knownUsers #-}

doCreateUser :: String -> IO User
doCreateUser name = do
  known <- readIORef knownUsers
  when (any (\u -> userName u == name) known) $ do
    error "User already exists!"
  modifyIORef knownUsers (\us -> us ++ [ User name ])
  return (User name)
