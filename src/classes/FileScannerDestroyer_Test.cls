@IsTest
public class FileScannerDestroyer_Test {
    @IsTest
    public static void testFilesTaggedAsShouldDeleteWereDeleted() {
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

        insert generateFileScan(attach.Id);

        Test.startTest();
        FileScannerDestroyer fileDestroy = new FileScannerDestroyer('test@example.com');
        Database.executeBatch(fileDestroy);
        Test.stopTest();

        List<Attachment> updatedAttachmentList = [SELECT Id FROM Attachment WHERE Id =: attach.Id];
        System.assertEquals(0, updatedAttachmentList.size()); //The Attachment tied to the FileScan File should have been deleted
    }

    /**
     * Returns a basic FileScan_File__c object tied to the supplied File Id
     * These are marked for deletion with the Should_Delete flag
     *
     * @param fileId
     *
     * @return
     */
    public static FileScan_File__c generateFileScan(Id fileId) {
        return new FileScan_File__c(
                File_Id__c = fileId,
                Hash__c = 'skdjvbksjfvlskfjvnlkn',
                File_Created_Date__c = System.today(),
                Should_Delete__c = true
        );
    }
}