{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE RankNTypes #-}
{-# LANGUAGE DeriveDataTypeable #-}
module Training.JoseJuan.Yesod.Translatable
( module Training.JoseJuan.Yesod.Translatable.Routes
, getTranslatable
, getListLanguagesR
, getTranslationR
, postTranslationR
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



dbGetTranslated :: Text -> Text -> Text -> TranslatableHandler ( Maybe Text -- translation
                                                               , Text)      -- status: OK, warning or error
dbGetTranslated _isoCode _termType _termUID =
  lift $
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
