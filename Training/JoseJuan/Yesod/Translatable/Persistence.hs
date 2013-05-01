module Training.JoseJuan.Yesod.Translatable.Persistence where

import Prelude
import Yesod
import Data.Text (Text)

-- Persistence plugin
share [mkPersist sqlOnlySettings, mkMigrate "migrateTranslatable"] [persistLowerCase|
TranslatableLang json
  isoCode Text
  name Text
  UniqueTranslatableLangIsoCode isoCode
  UniqueTranslatableLangName name

TranslatableTerm json
  termType Text
  termUID Text
  UniqueTranslatableTerm termType termUID

TranslatableTranslation json
  langId TranslatableLangId
  termId TranslatableTermId
  translation Text
  UniqueTranslatableTranslation langId termId
|] 


