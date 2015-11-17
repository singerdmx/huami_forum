(function () {
    CKEDITOR.plugins.add('fileuploader', {
        icons: 'fileuploader',
        init: function (editor) {
            var command = new CKEDITOR.command(editor, {
                exec: function (editor) {
                    alert(editor.document.getBody().getHtml());
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