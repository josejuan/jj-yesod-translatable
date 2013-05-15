module Handler.TranslatableTest where

import Import
import Training.JoseJuan.Yesod.Translatable

getSetlanguageR :: Text -> Handler RepHtml
getSetlanguageR lang = do
    setLanguage lang
    redirect TranslatableTestR

getEnableEditingModeR :: Handler RepHtml
getEnableEditingModeR = do
    enableEditingMode
    redirect TranslatableTestR

getDisableEditingModeR :: Handler RepHtml
getDisableEditingModeR = do
    disableEditingMode
    redirect TranslatableTestR

getTranslatableTestR :: Handler RepHtml
getTranslatableTestR = do
    languageList <- languages
    isEditingModeEnabled <- editingModeEnabled
    defaultLayout $ do
        setTitle "Translatable test"
        toWidget [cassius|
.body
  margin: 10px
.container
  width: auto !important
table
  font-size: 14px
  border-collapse: collapse
  width: auto
td
  vertical-align: top
  border: 1px solid black
  padding: 4px
th
  vertical-align: top
  border: 1px solid black
  background-color: lightgray
  padding: 4px
.translatable-updatable
  background-color: orange
.translatable-translatable
  background-color: green
|]
        [whamlet|
<table>
  <tr>
    <th rowspan=2>
      Language priority
    <th rowspan=2>
      Translatable mode
    <th colspan=3>
      Some translatable content
  <tr>
    <th>
      Content description
    <th>
      Hamlet definition
    <th>
      Result
  <tr>
    <td rowspan=6>
      <ul>
        $forall lang <- languageList
          <li>
            <a href=@{SetlanguageR lang}>
              #{lang}
    <td rowspan=6>
      $if isEditingModeEnabled
        <b>
          Editing Mode
        <br>
        <a href=@{DisableEditingModeR}>
          (set only translate)
      $else
        <b>
          Only Translating
        <br>
        (at server runtime)
        <br>
        <a href=@{EnableEditingModeR}>
          (set editable at client runtime)
    <td>
      Ever translated at server runtime
    <td>
      ^<span></span>{translate "TERM_TYPE" "TERM_UID"}
    <td>
      ^{translate "TERM_TYPE" "TERM_UID"}
  <tr>
    <td>
      Translated at client runtime
      <br>
      (if editing mode)
    <td>
      ^<span></span>{translatable "TERM_TYPE" "TERM_UID"}
    <td>
      ^{translatable "TERM_TYPE" "TERM_UID"}
  <tr>
    <td>
      Ever translated at client runtime
    <td>
      ^<span></span>{translatableEditable Updatable "TERM_TYPE" "TERM_UID"}
    <td>
      ^{translatableEditable Updatable "TERM_TYPE" "TERM_UID"}
  <tr>
    <td>
      Editable at client runtime
      <br>
      (if editing mode)
    <td>
      ^<span></span>{translatable' "TERM_TYPE" "TERM_UID"}
    <td>
      ^{translatable' "TERM_TYPE" "TERM_UID"}
  <tr>
    <td>
      Ever editable at client runtime
    <td>
      ^<span></span>{translatableEditable Editable "TERM_TYPE" "TERM_UID"}
    <td>
      ^{translatableEditable Editable "TERM_TYPE" "TERM_UID"}
  <tr>
    <td>
      Can not translate (`canTranslate` only grant "TERM_TYPE")
    <td>
      ^<span></span>{translatableEditable Editable "TERM_TYPE2" "TERM_UID"}
    <td>
      ^{translatableEditable Editable "TERM_TYPE2" "TERM_UID"}
|]
