{-# LANGUAGE QuasiQuotes
           , TemplateHaskell
           , TypeFamilies
           , FlexibleInstances
           , MultiParamTypeClasses
           , FlexibleContexts
           , GADTs
           , RankNTypes
           , DeriveDataTypeable #-}
{-|
  (Forgive the mess, I must refactor, and doc, ...)

  http://www.haskell.org/haddock/doc/html/ch03s03.html
-}
module Training.JoseJuan.Yesod.Translatable
( module Training.JoseJuan.Yesod.Translatable.Routes
, module Training.JoseJuan.Yesod.Translatable.Persistence
, getTranslatable
, getListLanguagesR
, getTranslationR
, postTranslationR
, getTranslated
, translate
, translatable
, TranslatableContentType (..)
) where

import Prelude
import Data.Maybe (isNothing, fromJust)
import Data.Text (Text)
import qualified Data.Text as T
import Training.JoseJuan.Yesod.Translatable.Routes
import Training.JoseJuan.Yesod.Translatable.Persistence
import Yesod

-- Subsite plugin
instance YesodTranslatable master => YesodSubDispatch Translatable (HandlerT master IO) where
  yesodSubDispatch = $(mkYesodSubDispatch resourcesTranslatable)

type TranslatableHandler a = forall master. YesodTranslatable master => HandlerT Translatable (HandlerT master IO) a

getTranslatable :: a -> Translatable
getTranslatable = const Translatable


_DEFAULT_ISOCODE :: Text
_DEFAULT_ISOCODE = "en"


-- Helpers for sites

-- |Similar to _{MsgHello} but in realtime.
translate termType termUID = do
  (txt, msg) <- handlerToWidget $ getTranslated _DEFAULT_ISOCODE termType termUID
  let txt' = T.concat [_DEFAULT_ISOCODE, ":", termType, ":", termUID]
      msg' = if msg == "OK" then Nothing else Just msg
  [whamlet|
$maybe t <- txt
  #{t}
$nothing
  $maybe m <- msg'
    <span title=#{m}>
      #{txt'}
  $nothing
    #{txt'}
|]

data TranslatableContentType = Editable | Updatable

instance Show TranslatableContentType where
  show Editable = "translatable"
  show Updatable = "updatable"

-- |Set a translatable content (editing mode).
-- translatable :: (MonadWidget m, ToWidget (HandlerSite m) a) => TranslatableContentType -> Text -> Text -> m ()
translatable :: TranslatableContentType -> Text -> Text -> WidgetT m IO ()
translatable mode termType termUID = [whamlet|
<span data-translatable=#{show mode} data-translatabletype=#{termType} data-translatableuid=#{termUID}>
  &nbsp;
|]

-- Helpers

entityKeyToJson :: Entity a -> Value
entityKeyToJson e = toJSON $ k
  where PersistInt64 k = unKey $ entityKey e

translatableLangToJson :: Entity TranslatableLang -> Value
translatableLangToJson _langData = object values
  where values = [("id"     , entityKeyToJson _langData)
                 ,("isoCode", toJSON $ translatableLangIsoCode   $ entityVal _langData)
                 ,("name"   , toJSON $ translatableLangName      $ entityVal _langData)
                 ]

-- REST
getListLanguagesR :: TranslatableHandler Value
getListLanguagesR = dbGetLanguageList >>= jsonToRepJson . map translatableLangToJson

getTranslationR :: Text -> Text -> Text -> TranslatableHandler Value
getTranslationR _isoCode _termType _termUID = do
  (translation, status) <- dbGetTranslated _isoCode _termType _termUID
  jsonToRepJson $ object [("translation", toJSON translation)
                         ,("status", toJSON status)
                         ]

postTranslationR :: Text -> Text -> Text -> TranslatableHandler Value
postTranslationR _isoCode _termType _termUID = do
  translation <- lift $ parseJsonBody_
  result <- dbSetTranslated _isoCode _termType _termUID translation
  jsonToRepJson $ object [("result", toJSON result)]

-- Persistence

dbGetLanguageList :: TranslatableHandler [Entity TranslatableLang]
dbGetLanguageList = lift $ runDB (selectList [] [])

dbGetLanguageId _isoCode = do
  _langData <- selectFirst [TranslatableLangIsoCode ==. _isoCode] []
  case _langData of
    Nothing                 -> return Nothing
    Just (Entity _langId _) -> return $ Just _langId


dbGetTermId _termType _termUID = do
  _termData <- selectFirst [TranslatableTermTermType ==. _termType, TranslatableTermTermUID  ==. _termUID] []
  case _termData of
    Nothing                 -> return Nothing
    Just (Entity _termId _) -> return $ Just _termId

dbGetTranslated' _langId _termId = selectFirst [TranslatableTranslationLangId ==. _langId
                                               ,TranslatableTranslationTermId ==. _termId] []

getTranslated _isoCode _termType _termUID =
  runDB $
  do
    _langId <- dbGetLanguageId _isoCode
    _termId <- dbGetTermId _termType _termUID
    case (_langId, _termId) of
      (Nothing, _) -> return (Nothing, formatMessage "language not found!")
      (_, Nothing) -> return (Nothing, formatMessage "term not found!")
      (Just _langId', Just _termId') ->
        do
          _translationData <- dbGetTranslated' _langId' _termId'
          case _translationData of
            Nothing                      -> return (Just fullUID, formatMessage "translation not found!")
            Just (Entity _ _translation) -> return (Just $ translatableTranslationTranslation _translation, "OK")
  where fullUID = T.concat [_termType, ":", _termUID]
        formatMessage msg = T.concat [ _isoCode, ":", fullUID, ", ", msg]

{-
dbGetTranslated :: Text -> Text -> Text -> TranslatableHandler ( Maybe Text -- translation
                                                               , Text -- OK, warning or error
                                                               )
-}
dbGetTranslated _isoCode _termType _termUID = lift $ getTranslated _isoCode _termType _termUID


dbSetTranslated :: Text -> Text -> Text -> Text -> TranslatableHandler Text -- "OK" or error
dbSetTranslated _isoCode _termType _termUID translation =
  lift $
  runDB $
  do
    _langId <- dbGetLanguageId _isoCode
    _termId <- dbGetTermId _termType _termUID
    if isNothing _langId
      then return $ formatMessage "language not found!"
      else
        do
          let _langId' = fromJust _langId
          _termId' <- if isNothing _termId then insert $ TranslatableTerm _termType _termUID
                                           else return $ fromJust _termId
          _translation <- dbGetTranslated' _langId' _termId'
          if not (isNothing _translation) then delete $ entityKey $ fromJust $ _translation
                                          else return ()
          insert $ TranslatableTranslation _langId' _termId' translation
          return "OK"
  where fullUID = T.concat [_termType, ":", _termUID]
        formatMessage msg = T.concat [ _isoCode, ":", fullUID, ", ", msg]
