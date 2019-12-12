/**
 * Rolls back the FileScannerMarker results and recomputes the first instance of a file
 */
public class FileScannerMarkerRollback implements Database.Batchable<SObject>, Database.Stateful {
    Boolean sandbox = true;
    String emailResultsTo = '';
    
    public FileScannerMarkerRollback(String emailResultsTo) {
        sandbox = [SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox;
        emailResultsTo = emailResultsTo;
    }

    public Iterable<SObject> start(Database.BatchableContext param1) {
        return Database.getQueryLocator('SELECT Id, Should_Delete__c from FileScan_File__c where Should_Delete__c = true');
    }

    public void execute(Database.BatchableContext param1, List<FileScan_File__c> files) {
        List<FileScan_File__c> filesToUpdate = new List<FileScan_File__c>();
        for(FileScan_File__c file : files) {
            file.Deleted__c = false;
            file.Should_Delete__c = false;
            filesToUpdate.add(file);
        }
        Database.update(filesToUpdate, true);
    }

    public void finish(Database.BatchableContext param1) {
        // report any possible errors, email when finished
        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
        message.toAddresses = new String[]{ emailResultsTo };
        message.subject = 'FileScanner Marker Rollback Complete';
        message.plainTextBody = 'Successfully reset marker status on files';
        if (!sandbox()) {
            Messaging.SingleEmailMessage[] messages = new List<Messaging.SingleEmailMessage> {message};
            Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
        }
    }
}