(function () {
    CKEDITOR.plugins.add('fileuploader', {
        icons: 'fileuploader',
        init: function (editor) {
            var command = new CKEDITOR.command(editor, {
                exec: function (editor) {
                    jQuery('input#btn_file_uploader').trigger('click');
                }
            });
            editor.addCommand('fileuploader', command);
            editor.ui.addButton('FileUploader', {
                label: 'Upload File',
                command: 'fileuploader',
                toolbar: 'insert',
            });
            CKEDITOR.dialog.add('fileuploaderDialog', this.path + 'dialogs/fileuploader.js');
        }
    })
})();