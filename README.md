(working in progress)

**WARNING I'm not a Haskeller (I'm a rookie Haskeller), you must use this package carefully.

#(Training) Yesod Translatable plugin

Yesod Web Framework plugin to manage translatable content.

#How to

##Install jj-yesod-translatable package

    $ git clone https://github.com/josejuan/jj-yesod-translatable.git
    $ cd jj-yesod-translatable
    $ cabal install

##Use plugin

Use plugin into a scaffolded site is easy:

1. create scaffolded site.

2. create "static/js" folder (if not exists).

3. add [jQuery-translatable](https://raw.github.com/josejuan/jQuery-translatable "jQuery-translatable") plugin into "static/js" folder (eg. "static/js/jQuery-translatable.js"). Remember touch "Settings/StaticFiles.hs" if needed.

4. include script and jQuery scripts. Eg. adding to "templates/default-layout-wrapper.hamlet" into header:

    <script src="http://code.jquery.com/jquery-1.9.1.js" type="text/javascript"></script>
    <script src="http://code.jquery.com/ui/1.10.2/jquery-ui.js" type="text/javascript"></script>
    <script src="@{StaticR js_jQuery_translatable_js}" type="text/javascript"></script>

5. you can add too the initialization process. Eg.:

    <script type="text/javascript">
    $(function() {
        $.translatable({
          langListReaderUrl: 'translatable/languagelist',
          translatableReaderUrl: 'translatable',
          translatableWriterUrl: 'translatable'
        });
    });
    </script>

6. add jj-yesod-translatable library reference to you .cabal file:

    build-depends: base                          >= 4          && < 5
                 , yesod                         >= 1.2        && < 1.3
                 , yesod-core                    >= 1.2        && < 1.3
                     ...
                 , jj-yesod-translatable

7. create router to jj-yesod-translatable subsites to your config/routes. Eg.:

    /static StaticR Static getStatic
    /auth   AuthR   Auth   getAuth
    /translatable TranslatableR Translatable getTranslatable
    ...

8. add to your Application.hs file

    import Training.JoseJuan.Yesod.Translatable

    ....

    makeFoundation conf = do

        ...

        runLoggingT
            (Database.Persist.runPool dbconf (runMigration migrateTranslatable) p)
            (messageLoggerSource foundation logger)
    
8. add to your Foundation.hs file. Eg.:

    import Training.JoseJuan.Yesod.Translatable

    ...
    
    instance YesodTranslatable App where

9. migrate jj-yesod-translatable database (eg. running your scaffolded site).

10. insert your prefered languages into `translatable_lang` table. Eg.:

    $ sqlite3 your_project.sqlite3 "INSERT INTO translatable_lang (iso_code, name) VALUES ('en', 'English'), ('es', 'Spanish');"

11. you can insert some translatable content with some like (eg. into "templates/homepage.hamlet")

        <style>
          #sample {
            border-collapse: collapse;
            font-size: 20px;
          }
          #sample th {
            border: 1px solid black;
            text-align: left;
            padding: 10px;
            background-color: #f0f0f0;
          }
          #sample td {
            border: 1px solid black;
            padding: 10px;
          }
        <table id=sample>
          <tr>
            <th colspan=2>
              TRANSLATABLE CONTENT TYPE
          <tr>
            <th>
              Translated at server runtime
            <td>
              ^{translate "TERM_TYPE" "TERM_UID"}
          <tr>
            <th>
              Translated at client runtime
            <td>
              ^{translatable Updatable "TERM_TYPE" "TERM_UID"}
          <tr>
            <th>
              Editable at client runtime
            <td>
              ^{translatable Editable "TERM_TYPE" "TERM_UID"}
              

NOTES
-----

I followed namespace conventions from

  http://www.haskell.org/haskellwiki/Hierarchical_module_names


