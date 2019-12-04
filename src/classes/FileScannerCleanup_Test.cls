@IsTest
public class FileScannerCleanup_Test {

    @IsTest
    public static void testFileScannerWillCleanupFilesWithoutDuplicateResults() {
        Account account = new Account(
                Name = 'test1'
        );
        insert account;

        Attachment attach = new Attachment(
                ParentId = account.Id,
                Body= Blob.valueOf('testinggggggggg'),
                Name='test.pdf'
        );
        insert attach;

        FileScan_File__c file = new FileScan_File__c(
                Hash__c = 'lkjdfnkdjfngkdf',
                File_Id__c = attach.Id,
                Attached_To__c = attach.ParentId
        );
        insert file;

        Test.startTest();
        FileScannerCleanup fileClean = new FileScannerCleanup();
        Database.executeBatch(fileClean);
        Test.stopTest();

        List<FileScan_File__c> fileScans = [SELECT Id FROM FileScan_File__c WHERE File_Id__c =: attach.Id];
        System.assertEquals(0, fileScans.size());
    }
}