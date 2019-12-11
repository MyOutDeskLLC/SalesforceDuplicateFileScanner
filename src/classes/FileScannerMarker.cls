/**
 * The following batch apex will process hashes and mark Filescan_File__c "Should Delete" field to true
 * on duplicate hashed files, as well as email out some information on how many of each hash are scheduled
 * for deletion
 */
public class FileScannerMarker implements Database.Batchable<SObject>, Database.Stateful {
    List<String> knownFirstHashes = new List<String>();
    Map<String, Integer> deletionInformation = new Map<String, Integer>();
    Boolean sandbox = true;

    String emailInformation = '';
    String emailResultsTo = '';


    public FileScannerMarker(String emailResultsTo) {
        sandbox = [SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox;
        emailResultsTo = emailResultsTo;
    }

    /**
     * Start retrieving the available hashes in sets of 20 or so
     *
     * @param param1
     *
     * @return
     */
    public Iterable<SObject> start(Database.BatchableContext param1) {
        return Database.getQueryLocator('SELECT Hash__c FROM FileScan_File__c');
    }

    /**
     * There is a governor limit of 50,000 here that we can usually stay under with just 100 hashes
     * This process will get the File_Id__c and hash ordered by File_Created_Date__c ascending
     * The first seen instance of a given hash then should be the first file created for that hash
     *
     * Queue these first known instances into a set to keep and remove the rest
     *
     */
    public void execute(Database.BatchableContext param1, List<FileScan_File__c> hashesToCheck) {
        Set<String> hashesToProcess = new Set<String>();
        // FileScan_File objects to mark for deletion (checkbox)
        List<FileScan_File__c> filesToMarkForDeletion = new List<FileScan_File__c>();

        for (FileScan_File__c availableHash : hashesToCheck) {
            if(hashesToProcess.contains(String.valueOf(availableHash.get('Hash__c')))) {
                continue;
            }
            hashesToProcess.add(String.valueOf(availableHash.get('Hash__c')));
        }

        // Get all files for this list of hashes
        List<FileScan_File__c> allFiles = new List<FileScan_File__c>([SELECT File_Id__c, File_Name__c, Hash__c,File_Created_Date__c FROM FileScan_File__c WHERE Hash__c IN :hashesToProcess ORDER BY File_Created_Date__c ASC]);

        // Examine them for the first occurrence of a given file
        // If we have not seen the hash yet then we know it must be the first occurrence due to the order by File_Created_Date__c
        for (FileScan_File__c file : allFiles) {
            if (!knownFirstHashes.contains(file.Hash__c)) {
                emailInformation += 'Original File Found: ' + file.File_Name__c + ' created on ' + file.File_Created_Date__c + '\r\n';
                emailInformation += 'Original File Hash: ' + file.Hash__c + '\r\n';
                knownFirstHashes.add(file.Hash__c);
                deletionInformation.put(file.Hash__c, 0);
            } else {
                file.Should_Delete__c = true;
                filesToMarkForDeletion.add(file);
                deletionInformation.put(file.Hash__c, deletionInformation.get(file.Hash__c) + 1);
            }
        }

        for (String hashToDelete : deletionInformation.keySet()) {
            emailInformation += hashToDelete + ' (' + String.valueOf(deletionInformation.get(hashToDelete)) + ')\r\n';
        }

        Database.update(filesToMarkForDeletion, true);
    }

    /**
     * Send some help information off (phase 1)
     *
     * @param param1
     */
    public void finish(Database.BatchableContext param1) {
        // report any possible errors, email when finished
        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
        message.toAddresses = new String[]{ emailResultsTo };
        message.subject = 'FileScanner Marker Complete';
        message.plainTextBody = emailInformation;

        if (!sandbox) {
            Messaging.SingleEmailMessage[] messages =   new List<Messaging.SingleEmailMessage> {message};
            Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
        }
    }
}