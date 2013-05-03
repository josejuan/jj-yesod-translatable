$(function() {
    
    $.translatable({
      langListReaderUrl: 'translatable/languagelist',
      translatableReaderUrl: 'translatable',
      translatableWriterUrl: 'translatable'
    });
    
    $.translatable('initControls');

});

