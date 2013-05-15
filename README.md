(working in progress)

**WARNING I'm not a Haskeller (I'm a rookie Haskeller), you must use this package carefully**

#(Training) Yesod Translatable plugin

Yesod Web Framework plugin to manage translatable content.

To get one application internationalized in many languages (English, Spanish, ...) frameworks provide explicit mechanism to translate translatable content.

Most common way is to define a resource with translated content but is not commonly provide a comfortable way that users can translate that content.

The most important thing when a user translate some text is `the context` where there is it.

I hope this plugin provides to Yesod Web Framework a possible way to do it.

#How to

##Install `jj-yesod-translatable` package

    $ git clone https://github.com/josejuan/jj-yesod-translatable.git
    $ cd jj-yesod-translatable
    $ cabal install

##Use plugin

Use plugin into a scaffolded site is easy (looks like verbose but is very detailed):

1.  create scaffolded site (eg. `yesod init && cd myProject`).

1.  create "static/js" folder (if not exists, eg. `mkdir static/js`).

1.  add [jQuery-translatable](https://github.com/josejuan/jQuery-translatable "jQuery-translatable") plugin into "static/js" folder. Eg.

        wget \
          https://github.com/josejuan/jQuery-translatable/raw/master/jQuery-translatable.js \
          -O static/js/jQuery-translatable.js

    Remember touch "Settings/StaticFiles.hs" if needed.

1.  add two resource files to your "static/css" directory:
    1.  [edit button image](https://github.com/josejuan/jQuery-translatable/raw/master/css/edit.png "Edit button"). Eg.

            wget \
              https://github.com/josejuan/jQuery-translatable/raw/master/css/edit.png \
              -O static/css/edit.png

    1.  [adapted css](https://github.com/josejuan/jQuery-translatable/raw/master/css/style.css "Adapted css"). Eg.

            wget \
              https://github.com/josejuan/jQuery-translatable/raw/master/css/style.css \
              -O static/css/style.css

1.  include styles and jQuery scripts. Eg. adding to "templates/default-layout-wrapper.hamlet" into header:

        <script src="http://code.jquery.com/jquery-1.9.1.js" type="text/javascript">
        <script src="http://code.jquery.com/ui/1.10.2/jquery-ui.js" type="text/javascript">
        <script src="@{StaticR js_jQuery_translatable_js}" type="text/javascript">
        <link href="@{StaticR css_style_css}" media="all" rel="stylesheet" type="text/css">
        <link href="http://code.jquery.com/ui/1.10.2/themes/smoothness/jquery-ui.css" media="all" rel="stylesheet" type="text/css">

1.  you can add too the initialization process (in that hamlet file). Eg.:

        <script src="@{StaticR js_jQuery_translatable_haskell_js}" type="text/javascript">
    
    these file is on `jj-yesod-translatable` project. Eg.

        wget \
          https://github.com/josejuan/jj-yesod-translatable/raw/master/js/jQuery-translatable-haskell.js \
          -O static/js/jQuery-translatable-haskell.js

1.  for testing purposes you can include a complete handler showing translatable widgets in action. Eg.

        wget \
          https://github.com/josejuan/jj-yesod-translatable/raw/master/test/TranslatableTest.hs \
          -O Handler/TranslatableTest.hs

1.  add `jj-yesod-translatable` library reference to your `.cabal` file:

        build-depends: base                          >= 4          && < 5
                     , yesod                         >= 1.2        && < 1.3
                     , yesod-core                    >= 1.2        && < 1.3
                         ...
                     , jj-yesod-translatable

1.  if has included `TranslatableTest.hs` expose that module too 

        exposed-modules: Application
                         Foundation
                         ...
                         Handler.Home
                         ...
                         Handler.TranslatableTest

1.  create route to `jj-yesod-translatable` subsites to your config/routes. Eg.:

        /static StaticR Static getStatic
        /auth   AuthR   Auth   getAuth
        /translatable TranslatableR Translatable getTranslatable
        ...

1.  if has included `TranslatableTest.hs` set testing router too

        / HomeR GET POST
        ...
        /test TranslatableTestR GET
        /enableEdit EnableEditingModeR GET
        /disableEdit DisableEditingModeR GET
        /lang/#Text SetlanguageR GET

1.  add to your Application.hs file

        import Training.JoseJuan.Yesod.Translatable
        ....
        makeFoundation conf = do
            ...
            runLoggingT
                (Database.Persist.runPool dbconf (runMigration migrateTranslatable) p)
                (messageLoggerSource foundation logger)

1.  if has included `TranslatableTest.hs` include testing handler too

        import Handler.Home
        ...
        import Handler.TranslatableTest
    
1.  add to your Foundation.hs file the minimal `YesodTranslatable` instance. Eg.:

        import Training.JoseJuan.Yesod.Translatable
        ...
        instance YesodTranslatable App where
          canTranslate termType = return $ termType == "TERM_TYPE"

1.  if has included `TranslatableTest.hs` include `Data.Text` reference too

        import Data.Text

1.  migrate `jj-yesod-translatable` database (eg. running your scaffolded site doing `yesod devel --port 8181`).

1.  insert your prefered languages into `translatable_lang` table. Eg.:

        $ sqlite3 your_project.sqlite3 "INSERT INTO translatable_lang (iso_code, name) VALUES ('en', 'English'), ('es', 'Spanish');"

1.  now, if has included `TranslatableTest.hs`, you can see a demo page at [http://localhost:8181/test](http://localhost:8181/test "Test page").

    Note three translatable methods:
    
    1.  Translating text in server runtime using `^{translate "ERM_TYPE" "TERM_UID"}`.
    1.  Enable updates on a translatable content in client runtime (editing mode) using `^{translatable Updatable "TERM_TYPE" "TERM_UID"}`.
    1.  Enable editions on a translatable content in client runtime (editing mode) using `^{translatable Editable "TERM_TYPE" "TERM_UID"}`.

    You can run and test.

#Work in progress

This package is <del>not</del> usable <del>satisfactorily, you can</del>, but some behaviors will be added (I hope so):

1. <del>Set a properly way to get/select current language at server runtime (user session level)</del>. Now supported using `languages`.

1. <del>Set a properly way to grant access (and activate/deactivate) editing (translating) mode managing automaticaly client content representation (actually you must to switch between `translate` and `translatable` to set current mode, "viewing translation" or "editing translations")</del>. Now supported using `enableEditingMode`, `disableEditingMode` and `editingModeEnabled`.

1. <del>Cache translations at server runtime.</del> Now supported internally using `IORef (TVar (M.Map k a))`, we must wait to a better solution. You can override that behavior overloading `getCached` and `setCached` (`YesodTranslatable` methods).

1. <del>Remove public access on writable (POST) REST method and set some privilege role.</del> Now supported using `canTranslate`.

Others non critical tasks could be:

1. Refactor, clarify, ... the chaos.
    
1. Reduce todo list to install and use plugin.

1. Populate automaticaly `TranslatableLang` entity using `message/en.msg` files using a compliant way.

NOTES
-----

I followed namespace conventions from

  http://www.haskell.org/haskellwiki/Hierarchical_module_names


