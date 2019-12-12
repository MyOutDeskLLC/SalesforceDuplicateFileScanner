@IsTest
public class FileScannerMarker_Test {
    @IsTest
    public static void testCorrectNumberOfFilesAreTaggedForDeleted() {
        Account account = new Account(
            Name = 'test1',
        );
        insert account;

        Attachment attach = new Attachment(
                ParentId = account.Id,
                Body= Blob.valueOf('testinggggggggg'),
                Name='test.pdf'
        );
        insert attach;

        List<FileScan_File__c> fileScanFiles = new List<FileScan_File__c>();
        Integer count = 0;

        // Insert 12 duplicate items
        while (count < 12) {
            fileScanFiles.add(generateFileScan(attach.Id));
            count++;
        }
        insert fileScanFiles;

        Test.startTest();
        FileScannerMarker fileDestroy = new FileScannerMarker('test@example.com');
        Database.executeBatch(fileDestroy);
        Test.stopTest();

        System.assertEquals(1, [SELECT Id FROM FileScan_File__c WHERE Should_Delete__c != TRUE].size()); // 1 record should be left per each unique hash
        System.assertEquals(11, [SELECT Id FROM FileScan_File__c WHERE Should_Delete__c = TRUE].size()); // 11 records should be tagged for deletion
    }

    /**
     * Returns a basic FileScan_File__c object tied to the supplied File Id
     *
     * @param fileId
     *
     * @return
     */
    public static FileScan_File__c generateFileScan(Id fileId) {
        return new FileScan_File__c(
                File_Id__c = fileId,
                Hash__c = 'skdjvbksjfvlskfjvnlkn',
                File_Created_Date__c = System.today()
        );
    }
}