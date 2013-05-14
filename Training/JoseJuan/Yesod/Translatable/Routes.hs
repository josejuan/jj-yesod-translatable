{-# LANGUAGE QuasiQuotes, TemplateHaskell, TypeFamilies, FlexibleContexts, GADTs, ConstraintKinds #-}
module Training.JoseJuan.Yesod.Translatable.Routes where

import Prelude
import Yesod
import Data.Text (Text)
import qualified Data.Text as T
import Training.JoseJuan.Yesod.Translatable.Persistence
import qualified Data.Map as M
import Data.Maybe (isNothing)

data Translatable = Translatable

type YesodTranslatablePersist master =
    ( PersistStore (YesodPersistBackend master (HandlerT master IO))
    , PersistQuery (YesodPersistBackend master (HandlerT master IO))
    , PersistMonadBackend (YesodPersistBackend master (HandlerT master IO)) ~ PersistEntityBackend TranslatableLang
    , PersistEntity TranslatableLang
    , YesodPersist master
    )

_EDITING_MODE_SESSION :: Text
_EDITING_MODE_SESSION = "_TRANSLATABLE_MODE"

class (Yesod master, YesodTranslatablePersist master) => YesodTranslatable master where

    -- |Editing mode enabled?
    editingModeEnabled :: HandlerT master IO Bool
    editingModeEnabled = getSession >>= return . not . isNothing . M.lookup _EDITING_MODE_SESSION

    -- |Enable editing mode
    enableEditingMode :: HandlerT master IO ()
    enableEditingMode = setSession _EDITING_MODE_SESSION "1"

    -- |Disable editing mode
    disableEditingMode :: HandlerT master IO ()
    disableEditingMode = deleteSession _EDITING_MODE_SESSION

    -- |Prefered default language
    isoCode :: HandlerT master IO Text
    isoCode = languages >>= return . T.take 2 . head
    
    -- |User can translate some content under certain termType
    canTranslate :: Text -> HandlerT master IO Bool

mkYesodSubData "Translatable" [parseRoutes|
/languagelist ListLanguagesR GET
/#Text/#Text/#Text TranslationR GET POST
|]
