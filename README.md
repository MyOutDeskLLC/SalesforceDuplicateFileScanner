# Salesforce Duplicate File Scanner
Detects duplicate files regardless of name, size in Salesforce. This is not a package - please customize as you see fit. This is also not for small issues of duplicates; this is to handle a case of runaway triggers, invalid process builder, or bad workflow rules that caused a swelling of attachments.

## Usage
You can create the following objects & upload the code to your own Salesforce instance. After uploading, simply queue the process by
calling the following from either a controller or anonymous execution window. 
**Make sure to set your own key and secret first at the top of the FileScanner**

```java
// Do initial scan
Id batchJobId = Database.executeBatch(new FileScanner(2019, 'myemail@mydomain.com'), 500);
// After this is done, run the cleanup operation
Id batchJobId = Database.executeBatch(new FileScannerCleanup(10, 'myemail@mydomain.com'), 500);
```

## How It Works
The code works by reading the blob of the attachment body and using an MD5 hash to generate a unique signature for the file. If you'd like a stronger algorithm, you can consult the [Documentation Here](https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_classes_restful_crypto.htm)

```java
// src/classes/FileScanner.cls
Blob hashBlob = Crypto.generateDigest('MD5', attachment.Body);
String hash = EncodingUtil.convertToHex(hashBlob);
```

After hashing the file it will create a new object (as we cannot make fields on Notes, Attachments, etc) that contains information
on the file. After computing the hash of all files, you will want to queue a cleanup operation to remove files under a given threshold.

## Getting Results
We recommend using a report on the included object and it will automatically have "open file" so you can preview results.

![Report Results](https://user-images.githubusercontent.com/5719851/70189069-1f60ab80-16a7-11ea-9501-bc5f87f5d622.png)

## Cleaning Up
We found removing any copy of the hash after the first known version (file created date) worked best. Keep one, remove the others.

**Rememeber to take backups!**

## License
MIT