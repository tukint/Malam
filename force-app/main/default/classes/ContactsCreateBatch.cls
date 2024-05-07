global class ContactsCreateBatch implements Database.Batchable<String>, Database.Stateful {
    private final List<String> csvFileLines;
    private final Integer NO_OF_FIELDS = 4;

    public ContactsCreateBatch(List<String> csvFileLines) {
        this.csvFileLines = csvFileLines; 
    }

    public Iterable<String> start(Database.BatchableContext bc) {
        return this.csvFileLines; 
    }
   
    public void execute(Database.BatchableContext bc, List<String> batch) {
        List<Contact> contactsToUpsert = new List<Contact>();
        Map<String, Account> accountMap = new Map<String, Account>();
    

        Set<String> accountExternalIds = new Set<String>();
        for (String line : batch) {
            String[] fields = line.split(',');
            if (fields.size() == NO_OF_FIELDS) {
                accountExternalIds.add(fields[0].trim());
            } else {
                System.debug('Skipping line : ' + line);
            }
        }
    

        for (Account acc : [
            SELECT Id, Ref_Id__c, Account_Amount__c
            FROM Account
            WHERE Ref_Id__c IN :accountExternalIds
        ]) {
            accountMap.put(acc.Ref_Id__c, acc);
        }
    

        for (String line : batch) {
            String[] fields = line.split(',');
            if (fields.size() == NO_OF_FIELDS) {
                String accountExtId = fields[0].trim();
                String contactExtId = fields[1].trim();
                String lastName = fields[2].trim();
                String contactAmountStr = fields[3].trim();
    
              
                if (!accountMap.containsKey(accountExtId)) {
                    System.debug('No matching account found for external ID: ' + accountExtId);
                    continue; 
                }
    
                
                if (String.isBlank(contactExtId) || String.isBlank(lastName) || String.isBlank(contactAmountStr)) {
                    System.debug('Skipping line : ' + line);
                    continue; 
                }
    
                Decimal contactAmount;
                try {
                    contactAmount = Decimal.valueOf(contactAmountStr);
                } catch (Exception e) {
                    System.debug('Skipping line : ' + line);
                    continue; 
                }
    
                Account relatedAccount = accountMap.get(accountExtId);
                if (relatedAccount == null) {
                    System.debug('Account not found for external ID: ' + accountExtId);
                    continue; 
                }
    
                Contact contact = new Contact(
                    Ref_contact_Id__c = contactExtId,
                    LastName = lastName,
                    Contact_Amount__c = contactAmount,
                    AccountId = relatedAccount.Id
                );
    
               
                if (relatedAccount.Account_Amount__c == null) {
                    relatedAccount.Account_Amount__c = 0;
                }
                relatedAccount.Account_Amount__c += contactAmount;
                contactsToUpsert.add(contact);
            } else {
                System.debug('Skipping line incorrect data: ' + line);
            }
        }
    
        upsert accountMap.values() Account.Ref_Id__c;
        upsert contactsToUpsert Contact.Ref_contact_Id__c;
    }
    
    
    
    

    public void finish(Database.BatchableContext bc) {
        System.debug('All Batch Process Is Done');
    }


}
