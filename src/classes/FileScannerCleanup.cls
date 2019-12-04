global class FileScannerCleanup implements Database.Batchable<SObject>, Database.Stateful {
    List<String> knownDuplicateHashes = new List<String>();
    Integer deletedFileCount = 0;
    Integer threshold = 10;
    String emailResultsTo = '';
    Boolean sandbox = true;

    global FileScannerCleanup(Integer threshold, String emailResultsTo) {
        sandbox = [SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox;
        threshold = threshold;
        emailResultsTo = emailResultsTo;
        AggregateResult[] knownHashes = [SELECT COUNT(Id), Hash__c Hash FROM FileScan_File__c GROUP BY Hash__c HAVING COUNT(Id) > :threshold];
        if (knownHashes.size() > 0) {
            for(AggregateResult knownHash : knownHashes) {
                knownDuplicateHashes.add(String.valueOf(knownHash.get('Hash')));
            }
        }
    }

    /**
     * Get files, 500 at a time, that do not have the same hash occuring over the amount of times given (threshold)
     */
    global Iterable<SObject> start(Database.BatchableContext batchContext) {
        return Database.getQueryLocator([SELECT Id, Hash__c FROM FileScan_File__c WHERE Hash__c NOT IN :knownDuplicateHashes]);
    }

    /**
     * Processes files for deletion
     */
    global void execute(Database.BatchableContext bc, List<FileScan_File__c> files)
    {
        List<Id> filesToDelete = new List<Id>();
        for(FileScan_File__c file : files) {
            filesToDelete.add(file.Id);
        }
        Database.DeleteResult[] deleteItems = Database.delete(filesToDelete);

        for (Database.DeleteResult result : deleteItems) {
            if (result.isSuccess()) {
                deletedFileCount++;
                continue;
            }
        }
    }

    /**
     * Email results
     */
    global void finish(Database.BatchableContext bc) {
        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
        message.toAddresses = new String[]{emailResultsTo};
        message.subject = 'Duplicate File Scanner Cleanup Complete';
        message.plainTextBody = 'FileScanner has finished removing non-duplicate file hashes. \r\n';
        message.plainTextBody += 'Number of deleted FileScan_File__c objects: \r\n';
        message.plainTextBody += deletedFileCount;

        if(!sandbox) {
            Messaging.SingleEmailMessage[] messages =   new List<Messaging.SingleEmailMessage> {message};
            Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
        }
    }
}