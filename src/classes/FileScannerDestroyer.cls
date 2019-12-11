/**
 * Removes files marked for deletion from the FileScan_File__c object
 */
public class FileScannerDestroyer implements Database.Batchable<SObject>, Database.Stateful  {
    Integer filesRemoved = 0;
    String emailResultsTo = '';
    Boolean sandbox = true;

    public FileScannerDestroyer(String emailResultsTo) {
        sandbox = [SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox;
        emailResultsTo = emailResultsTo;
    }

    public Iterable<SObject> start(Database.BatchableContext param1) {
        return Database.getQueryLocator('SELECT File_Id__c from FileScan_File__c where Should_Delete__c = TRUE');
    }

    /**
     * Add all the original file id's from the FileScanner results into a set and proceed to query
     * the original attachments and delete them
     */
    public void execute(Database.BatchableContext param1, List<FileScan_File__c> files) {
        Set<Id> filesToRemove = new Set<Id>();
        for (FileScan_File__c file : files) {
            filesToRemove.add(Id.valueOf(file.File_Id__c));
        }
        List<Attachment> attachments = new List<Attachment>([SELECT Id FROM Attachment WHERE Id IN :filesToRemove]);
        filesRemoved += attachments.size();
        Database.delete(attachments, true);
    }

    /**
     * Email when finished
     */
    public void finish(Database.BatchableContext param1) {
        // report any possible errors, email when finished
        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
        message.toAddresses = new String[]{ emailResultsTo };
        message.subject = 'FileScanner Deletion Complete';
        message.plainTextBody = 'Deleted: ' + filesRemoved + ' files from salesforce that were marked for deletion';

        if (!sandbox) {
            Messaging.SingleEmailMessage[] messages = new List<Messaging.SingleEmailMessage> {message};
            Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
        }
    }
}