@IsTest
public class FileScannerMarkerRollback_Test {
    @IsTest
    public static void testShouldDeleteIsReverted() {
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

        FileScan_File__c file = new FileScan_File__c(
                File_Id__c = attach.Id,
                Hash__c = 'skdjvbksjfvlskfjvnlkn',
                File_Created_Date__c = System.today(),
                Should_Delete__c = true
        );
        insert file;

        Test.startTest();
        FileScannerMarkerRollback rb = new FileScannerMarkerRollback('test@example.com');
        Database.executeBatch(rb);
        Test.stopTest();

        List<FileScan_File__c> updatedFiles = [SELECT Id, Should_Delete__c FROM FileScan_File__c WHERE Id =: file.Id];
        System.assertEquals(false, updatedFiles[0].Should_Delete__c);
    }
}