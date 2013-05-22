module Training.JoseJuan.Yesod.Translatable.Internal.AppCache
( translatableGetSetCached
, translatableGetCached
, translatableSetCached
) where

import Prelude
import Control.Concurrent.STM
import Data.IORef
import qualified Data.Map as M
import qualified Data.Text as T
import System.IO.Unsafe

data TranslatableCacheKey = TranslatableCacheKey { getLang :: T.Text
                                                 , getTerm :: T.Text
                                                 , getUid  :: T.Text
                                                 } deriving (Show, Ord, Eq)

translatableGlobalCache :: IORef (TVar (M.Map k a))
{-# NOINLINE translatableGlobalCache #-}
translatableGlobalCache =
  unsafePerformIO $
  do
    cache <- atomically $ newTVar M.empty
    newIORef cache

translatableGetCached :: T.Text -> T.Text -> T.Text -> IO (Maybe T.Text)
translatableGetCached lang term uid =
  do
    tvCache <- readIORef translatableGlobalCache
    atomically $
      do
        cache <- readTVar tvCache
        return $ M.lookup (TranslatableCacheKey lang term uid) cache

translatableSetCached :: T.Text -> T.Text -> T.Text -> T.Text -> IO ()
translatableSetCached lang term uid translation =
  do
    tvCache <- readIORef translatableGlobalCache
    atomically $
      do
        cache <- readTVar tvCache
        let cache' = M.insert (TranslatableCacheKey lang term uid) translation cache
        writeTVar tvCache cache'

translatableGetSetCached :: T.Text -> T.Text -> T.Text -> T.Text -> IO T.Text
translatableGetSetCached lang term uid translation =
  do
    txt <- translatableGetCached lang term uid
    case txt of
      Just txt' -> return txt'
      Nothing   -> do
                     translatableSetCached lang term uid translation
                     return translation
