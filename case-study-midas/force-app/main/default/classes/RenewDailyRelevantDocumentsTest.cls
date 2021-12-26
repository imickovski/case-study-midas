/**
 * @description       : 
 * @author            : Ivan Mickovski
 * @group             : 
 * @last modified on  : 26.12.2021
 * @last modified by  : Ivan Mickovski
**/
@isTest
private class RenewDailyRelevantDocumentsTest {
    
    @testSetup
    static void setup() {
        List<Account> accounts = new List<Account>();
        List<Contact> contacts = new List<Contact>();

        ContentVersion cv=new Contentversion();
        cv.title='ABC';
        cv.PathOnClient ='test';
        Blob b=Blob.valueOf('Unit Test Attachment Body');
        cv.versiondata=EncodingUtil.base64Decode('Unit Test Attachment Body');
        insert cv;

        
        // insert 10 accounts
        for (Integer i=0;i<10;i++) {
            accounts.add(new Account(name='Account '+i,
            billingcity='New York', billingcountry='USA'));
        }
        insert accounts;
        // find the account just inserted. add contact for each
        for (Account account : [select id from account]) {
            contacts.add(new Contact(firstname='first',
            lastname='last', accountId=account.id));
        }
        insert contacts;

        Document__c doc = new Document__c(
            Name = 'Siren Real Estate Documents',
            Type__c = 'Contract',
            Notification_Status__c = 'New',
            Account__c = accounts[0].Id
        );
        insert doc;
    }

    @isTest static void test() {

        Test.startTest();
        RenewDailyRelevantDocuments batchObject = new RenewDailyRelevantDocuments();
        Id batchId = Database.executeBatch(batchObject, 4000);
        Test.stopTest();

        // after the testing stops, assert records were updated properly
        System.assertEquals(10, [select count() from contact where MailingCity = 'New York']);
    }
}