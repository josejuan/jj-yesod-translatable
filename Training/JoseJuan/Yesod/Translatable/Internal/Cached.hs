module Training.JoseJuan.Yesod.Translatable.Internal.Cached
( firstCached
) where

import Prelude
import Yesod
import Data.Typeable
import Data.IORef

{-|

  Provider tools cached related.

-}

{-|

  You must define a custom `newtype` to hold cached information.
  
  Currently must be a Boolean:
  
    newtype MyOwnIsCached = MyOwnIsCached { unMyOwnIsCached :: IORef Bool } deriving Typeable

  Example usage:

    renderWidget :: Widget
    renderWidget = do
      firstRender <- firstCached unMyOwnIsCached MyOwnIsCached
      if rendered
        then [whamlet| WAS RENDERED |]
        else [whamlet| RENDERING... |]

-}

firstCached :: (MonadHandler f, Typeable a) => (a -> IORef Bool) -> (IORef Bool -> a) -> f Bool
firstCached toRef fromRef = do
  ioFlag <- fmap toRef $ cached $ liftIO $ fmap fromRef $ newIORef True
  flag <- liftIO $ readIORef ioFlag
  if flag
    then liftIO $ writeIORef ioFlag False
    else return ()
  return flag

