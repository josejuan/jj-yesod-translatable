{-# LANGUAGE QuasiQuotes, TemplateHaskell, TypeFamilies, FlexibleContexts, GADTs, ConstraintKinds #-}
module Training.JoseJuan.Yesod.Translatable.Routes where

import Prelude (IO)
import Yesod
import Data.Text (Text)
import Training.JoseJuan.Yesod.Translatable.Persistence

data Translatable = Translatable

type YesodTranslatablePersist master =
    ( PersistStore (YesodPersistBackend master (HandlerT master IO))
    , PersistQuery (YesodPersistBackend master (HandlerT master IO))
    , PersistMonadBackend (YesodPersistBackend master (HandlerT master IO)) ~ PersistEntityBackend TranslatableLang
    , PersistEntity TranslatableLang
    , YesodPersist master
    )

class (Yesod master, YesodTranslatablePersist master)
         => YesodTranslatable master where

mkYesodSubData "Translatable" [parseRoutes|
/languagelist ListLanguagesR GET
/#Text/#Text/#Text TranslationR GET POST
|]
