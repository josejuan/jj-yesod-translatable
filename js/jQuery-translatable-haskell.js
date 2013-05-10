$(function() {
    
    $.translatable({
      currentLanguage: _TRANSLATABLE_jsISO_LANG || "en",
      langListReaderUrl: 'translatable/languagelist',
      translatableReaderUrl: 'translatable',
      translatableWriterUrl: 'translatable'
    });
    
    $.translatable('initControls');

});

