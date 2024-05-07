import { LightningElement, track } from 'lwc';
import processUploadedContent from '@salesforce/apex/ContactsBatchController.processUploadedContent';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class UploadContactsFile extends LightningElement {
    @track fileContent = '';
    @track fileName = '';
    @track isUploadButtonDisabled = true;
    @track status = ''

    handleFileChange(event) {
        const file = event.target.files[0];
        if (file) {
            const reader = new FileReader();
            reader.onload = () => {
                this.fileContent = reader.result;
                this.fileName = file.name;
                this.isUploadButtonDisabled = false;
            };
            reader.readAsText(file);
        }
    }

    handleUpload() {
        this.status = 'Processing'
        processUploadedContent({ fileContent: this.fileContent })
            .then(result => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'File processed successfully: ' + result,
                        variant: 'success',
                    }),
                );
                this.status = 'Done'
                this.clearFile();
            })
            .catch(error => {
                this.status = 'Error'
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error processing file',
                        message: 'Error: ' + error.body.message,
                        variant: 'error',
                    }),
                );
            });
    }

    clearFile() {
        this.fileContent = '';
        this.fileName = '';
        this.isUploadButtonDisabled = true;
        this.status = ''
    }
}
