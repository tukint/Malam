public with sharing class ContactsBatchController {
    @AuraEnabled
    public static String processUploadedContent(String fileContent) {
    
        List<String> csvLines = new List<String>(fileContent.split('\n'));
    
      
        if (csvLines.size() > 0 && csvLines[0].contains('contact name')) {
            csvLines.remove(0);
        }
    
        ContactsCreateBatch batch = new ContactsCreateBatch(csvLines);
        String jobId = Database.executeBatch(batch, 200);
    
        return 'Batch job submitted with Job ID: ' + jobId;
    }
}
