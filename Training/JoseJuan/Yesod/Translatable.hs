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
, translatable'
, translatableEditable
, TranslatableContentType (..)
) where

import Prelude
import Data.Maybe (isNothing, fromJust)
import Data.Text (Text)
import qualified Data.Text as T
import Training.JoseJuan.Yesod.Translatable.Routes
import Training.JoseJuan.Yesod.Translatable.Persistence
import Training.JoseJuan.Yesod.Translatable.Internal.Cached
import Yesod
import Data.Typeable
import Data.IORef

-- Subsite plugin
instance YesodTranslatable master => YesodSubDispatch Translatable (HandlerT master IO) where
  yesodSubDispatch = $(mkYesodSubDispatch resourcesTranslatable)

type TranslatableHandler a = forall master. YesodTranslatable master => HandlerT Translatable (HandlerT master IO) a

getTranslatable :: a -> Translatable
getTranslatable = const Translatable

_TRANSLATABLE_jsISO_LANG :: Text
_TRANSLATABLE_jsISO_LANG = "_TRANSLATABLE_jsISO_LANG"

_OK :: Text
_OK = "OK"

-- Helpers for sites

-- |Similar to _{MsgHello} but in realtime.
translate :: YesodTranslatable m => Text -> Text -> WidgetT m IO ()
translate termType termUID = do
  lang <- liftHandlerT $ isoCode
  (txt, msg) <- liftHandlerT $ getTranslated lang termType termUID
  let txt' = T.concat [lang, ":", termType, ":", termUID]
      msg' = if msg == _OK then Nothing else Just msg
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

newtype TranslatableLangJSIncluded = TranslatableLangJSIncluded { unTranslatableLangJSIncluded :: IORef Bool } deriving Typeable

-- |Set a translatable content (editing mode).
translatableEditable :: YesodTranslatable m => TranslatableContentType -> Text -> Text -> WidgetT m IO ()
translatableEditable mode termType termUID = do
  lang <- handlerToWidget $ isoCode
  langJs <- firstCached unTranslatableLangJSIncluded TranslatableLangJSIncluded
  if langJs
    then toWidget [julius|_TRANSLATABLE_jsISO_LANG = #{toJSON lang}|]
    else return ()
  [whamlet|
<span data-translatable=#{show mode} data-translatabletype=#{termType} data-translatableuid=#{termUID}>
  &nbsp;
|]

translatableWithMode :: YesodTranslatable m => TranslatableContentType -> Text -> Text -> WidgetT m IO ()
translatableWithMode mode termType termUID = do
  isEditingModeEnabled <- liftHandlerT $ editingModeEnabled
  if isEditingModeEnabled
    then translatableEditable mode termType termUID
    else translate            termType termUID

-- |Set a translatable content changing between "updatable on editing mode"
--  and "translating mode" autmatically using "_TRANSLATABLE_MODE" session state.
translatable :: YesodTranslatable m => Text -> Text -> WidgetT m IO ()
translatable termType termUID = translatableWithMode Updatable termType termUID

-- |Set a translatable content changing between "editable on editing mode"
--  and "translating mode" autmatically using "_TRANSLATABLE_MODE" session state.
translatable' :: YesodTranslatable m => Text -> Text -> WidgetT m IO ()
translatable' termType termUID = translatableWithMode Editable termType termUID


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
  canwrite <- lift $ canTranslate _termType
  result' <- if not canwrite
               then
                 return $ T.concat ["You do not have permission to write termType '", _termType]
               else
                 do
                   translation <- lift $ parseJsonBody_
                   result <- dbSetTranslated _isoCode _termType _termUID translation
                   return result
  jsonToRepJson $ object [("result", toJSON result')]

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

getTranslated_uncached _isoCode _termType _termUID =
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
            Just (Entity _ _translation) -> return (Just $ translatableTranslationTranslation _translation, _OK)
  where fullUID = T.concat [_termType, ":", _termUID]
        formatMessage msg = T.concat [ _isoCode, ":", fullUID, ", ", msg]

{-
dbGetTranslated :: Text -> Text -> Text -> TranslatableHandler ( Maybe Text -- translation
                                                               , Text -- OK, warning or error
                                                               )
-}
dbGetTranslated _isoCode _termType _termUID = lift $ getTranslated _isoCode _termType _termUID
getTranslated _isoCode _termType _termUID = do
  do
    txt <- getCached _isoCode _termType _termUID
    case txt of
      Just txt' -> return (Just txt', _OK)
      Nothing   -> do
                     translation <- getTranslated_uncached _isoCode _termType _termUID
                     case translation of
                       (Just txt'', _) -> setCached _isoCode _termType _termUID txt''
                       _               -> return ()
                     return translation

dbSetTranslated :: Text -> Text -> Text -> Text -> TranslatableHandler Text -- _OK or error
dbSetTranslated _isoCode _termType _termUID translation = do
  lift $ do
    setCached _isoCode _termType _termUID translation
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
              return _OK
  where fullUID = T.concat [_termType, ":", _termUID]
        formatMessage msg = T.concat [ _isoCode, ":", fullUID, ", ", msg]
