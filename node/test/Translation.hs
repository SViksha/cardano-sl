-- | Test that we can translate from UTxO to the abstract chain.
module Translation
    ( spec
    -- , addrs
    -- , oDsl0
    -- , trDsl0
    -- , inDsl1
    -- , oDsl1
    -- , trDsl1
    -- , blDsl
    -- , chDsl
    -- , oAbs
    -- , trAbs1
    -- , blAbs
    -- , chAbs
    ) where

import           Chain.Abstract
import qualified Chain.Abstract as Abs
import           Chain.Abstract.Translate.FromUTxO
import           Control.Exception as E
import           Data.List.NonEmpty hiding (reverse)
import qualified Data.Map.Strict as Map
import qualified Data.Set as Set
import           GHC.Stack.Types (SrcLoc)
import           Pos.Core.Chrono (OldestFirst (..))
import           Test.Hspec hiding (shouldBe)
import           Test.HUnit.Lang (Assertion, FailureReason (..), HUnitFailure (..))
import           Universum
import qualified UTxO.DSL as DSL


shouldBe
    :: (HasCallStack, Eq a)
    => a      -- ^ The expected value
    -> a      -- ^ The actual value
    -> Assertion
shouldBe expected actual =
    unless (actual == expected) $ do
        (E.throwIO (HUnitFailure location $ ExpectedButGot Nothing "*no-show*" "*no-show*"))
  where
    location :: HasCallStack => Maybe SrcLoc
    location = case reverse (getCallStack callStack) of
        (_, loc) : _ -> Just loc
        []           -> Nothing


addrs = (Addr 1024) :| [Addr 2048] -- from Chain.Abstract
oDsl0 = DSL.Output
        { outAddr = head addrs
        , outVal  = 10 :: DSL.Value
        } :: DSL.Output DSL.GivenHash Addr
oAbs0 = Abs.Output
        { outAddr        = head addrs
        , outVal         = 10 :: DSL.Value
        , outRepartition = Repartition (Map.empty :: Map.Map Addr (Sum Int))
        }
trDsl0 = DSL.Transaction
        { trFresh = 2 :: DSL.Value
        , trIns   = Set.empty
        , trOuts  = [oDsl0]
        , trFee   = 3 :: DSL.Value
        , trHash  = 123120 :: Int
        , trExtra = [] }
inDsl1 = DSL.Input
        { inpTrans = DSL.givenHash trDsl0
        , inpIndex = 0 }
oAbs1 = Abs.Output
        { outAddr        = addrs !! 1
        , outVal         = 5 :: DSL.Value
        , outRepartition = Repartition (Map.empty :: Map.Map Addr (Sum Int))
        }
oDsl1 = DSL.Output
        { outAddr = addrs !! 1
        , outVal  = 5 :: DSL.Value
        } :: DSL.Output DSL.GivenHash Addr
trDsl1 = DSL.Transaction
        { trFresh = 2 :: DSL.Value
        , trIns   = Set.fromList [inDsl1]
        , trOuts  = [oDsl1]
        , trFee   = 3 :: DSL.Value
        , trHash  = 54209842 :: Int
        , trExtra = [] }
trAbs1 = Abs.Transaction
        { trFresh   = 2 :: DSL.Value
        , trIns     = inDsl1 :| []
        , trOuts    = oAbs1 :| []
        , trFee     = 3 :: DSL.Value
        , trHash    = DSL.trHash trDsl1
        , trExtra   = []
        , trWitness = addrs !! 0 :| [addrs !! 1]
        }
blDsl = OldestFirst { getOldestFirst = [trDsl1] }
chDsl = OldestFirst { getOldestFirst = [blDsl] }

blAbs = Abs.Block
        { blockPred         = BlockHash 0 -- this is the genesis block so not sure what to put here
        , blockSlot         = SlotId 0
        , blockIssuer       = addrs !! 0
        , blockTransactions = OldestFirst { getOldestFirst = [trAbs1] }
        , blockDlg          = []
        }
chAbs = OldestFirst { getOldestFirst = [blAbs] }

spec :: Spec
spec = do
    describe "Chain translation verification" $ do
      it "A DSL output should match an abstract output" $ do
        -- TODO(md): see about Show instances for types when using `shouldBe`
        outDSL oAbs0 `shouldBe` oDsl0
      it "The 'translate' function should convert a DSL chain to an abstract chain" $ do
        -- translate @DSL.GivenHash @Identity @IntException addrs chDsl [] `shouldBe` (Identity $ Right chAbs)
        pending
