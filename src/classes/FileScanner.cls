global class FileScanner implements Database.Batchable<SObject>, Database.Stateful {
    String key = 'PUT_YOUR_OWN_KEY_HERE';
    String secret = 'PUT_YOUR_OWN_SECRET_HERE';
    Integer createdFileCount = 0;
    Integer yearToGetFilesFor;
    Boolean sandbox = true;
    String emailResultsTo = '';

    /**
     * Detect sanbox and queue up the year to process
     */
    global FileScanner(Integer year, String emailResultsTo) {
        sandbox = [SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox;
        yearToGetFilesFor = year;
        emailResultsTo = emailResultsTo;
    }

    /**
     * Get all attachments from the given year, 500 at a time
     *
     * @param paraml
     *
     * @return
     */
    global Iterable<SObject> start(Database.BatchableContext bachContext) {
        String queryToExecute = 'SELECT Id, Body, BodyLength, Name, ContentType, ParentId, Parent.Type, CreatedDate FROM Attachment WHERE CALENDAR_YEAR(CreatedDate) = :yearToGetFilesFor';
        return Database.getQueryLocator(queryToExecute);
    }

    /**
     * Compute hashes and generate new objects
     *
     * @param bc
     * @param attachments
     */
    global void execute(Database.BatchableContext bc, List<Attachment> attachments) {
        List<FileScan_File__c> filesToInsert = new List<FileScan_File__c>();

        // Calculate hashes for the files processed
        for(Attachment attachment : attachments) {
            String accountId = null;

            // TODO: Attempt to locate any account related to this attachment in some way

            Blob hashBlob = Crypto.generateDigest('MD5', attachment.Body);
            String hash = EncodingUtil.convertToHex(hashBlob);
            //create object
            filesToInsert.add(new FileScan_File__c (
                Hash__c = hash,
                File_Id__c = attachment.Id,
                File_Name__c = attachment.Name,
                File_Size__c = attachment.BodyLength,
                File_Created_Date__c = attachment.CreatedDate,
                Attached_To__c = attachment.ParentId,
                Attached_To_Type__c = attachment.Parent.Type,
                Attached_To_Account__c = accountId
            ));
        }

        Database.SaveResult[] createdFiles = Database.insert(filesToInsert, false);

        for (Database.SaveResult result : createdFiles) {
            if (result.isSuccess()) {
                createdFileCount++;
                continue;
            }
        }
    }

    /**
     * Send an email containing some basic information about the run
     *
     * @param bc
     */
    global void finish(Database.BatchableContext bc) {
        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
        message.toAddresses = new String[]{emailResultsTo};
        message.subject = 'Duplicate File Scanner Run Complete';
        message.plainTextBody = 'Batchable class has finished. \r\n';
        message.plainTextBody += 'Number of created FileScan_File__c objects: \r\n';
        message.plainTextBody += createdFileCount;

        if(!sandbox) {
            Messaging.SingleEmailMessage[] messages =   new List<Messaging.SingleEmailMessage> {message};
            Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
        }
    }
}