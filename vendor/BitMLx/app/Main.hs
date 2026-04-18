module Main where

import ExampleRunner (runExample)
import System.Environment (getArgs)
import System.Exit (exitFailure)
import Control.Monad (forM_)
import qualified Examples.Escrow as Escrow
import qualified Examples.MutualTC as MutualTC
import qualified Examples.NaiveExchangeLottery as NaiveExchangeLottery
import qualified Examples.SimpleExchange as SimpleExchange
import qualified Examples.ReceiverChosenDenomination as ReceiverChosenDenomination
import qualified Examples.TwoPartyAgreement as TwoPartyAgreement
import qualified Examples.MultichainPaymentExchange as MultichainPaymentExchange
import qualified Examples.MultichainLoanMediator as MultichainLoanMediator

main :: IO ()
main = do
    args <- getArgs
    let allExamples =
            [ ("Escrow", Escrow.example)
            , ("MutualTC", MutualTC.example)
            , ("NaiveExchangeLottery", NaiveExchangeLottery.example)
            , ("SimpleExchange", SimpleExchange.example)
            , ("ReceiverChosenDenomination", ReceiverChosenDenomination.example)
            , ("TwoPartyAgreement", TwoPartyAgreement.example)
            , ("MultichainPaymentExchange", MultichainPaymentExchange.example)
            , ("MultichainLoanMediator", MultichainLoanMediator.example)
            ]

    case args of
        [] -> mapM_ (runExample . snd) allExamples
        names -> forM_ names $ \n ->
            case lookup n allExamples of
                Just ex -> runExample ex
                Nothing -> do
                    putStrLn ("Unknown example: " ++ n)
                    putStrLn "Valid examples:"
                    mapM_ (putStrLn . ("- " ++) . fst) allExamples
                    exitFailure
