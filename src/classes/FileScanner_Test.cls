@IsTest
public class FileScanner_Test {
    @IsTest
    public static void testFileScannerRunCreatesFileScanObject() {
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
        Test.setCreatedDate(attach.Id, Datetime.newInstance(2018, 06, 06));

        Test.startTest();
        FileScanner fileScan = new FileScanner(2018);
        Database.executeBatch(fileScan);
        Test.stopTest();
        
        // Query available fileScan results
        List<FileScan_File__c> fileScans = [SELECT Id FROM FileScan_File__c WHERE File_Id__c =: attach.Id];
        // A new object should have been created for the attachment we initially created
        System.assertEquals(1, fileScans.size());
    }
}