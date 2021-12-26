/**
 * @description       : 
 * @author            : Ivan Mickovski
 * @group             : 
 * @last modified on  : 26.12.2021
 * @last modified by  : Ivan Mickovski
**/
public class RenewDailyRelevantDocuments implements Database.Batchable<sObject>, Database.Stateful {

    static final String NOTIFICATION_STATUS_NEW = 'New';
    static final String NOTOFICATION_STATUS_NOTIFIED = 'Customer Notified';
    static final String REPORT_DOCUMENT_TYPE = 'Report';
    static final String TRANSACTIONAL_DOCUMENT_TYPE = 'Transactional';
    static final String LEGAL_DOCUMENT_TYPE = 'Legal';
    static final String CONTRACT_DOCUMENT_TYPE = 'Contract';

    List<Document__c> reportDocuments = new List<Document__c>();
    List<Document__c> transactionalDocuments = new List<Document__c>();
    List<Document__c> legalDocuments = new List<Document__c>();
    List<Document__c> contractDocuments = new List<Document__c>();

    // instance member to retain state across transactions
    public Integer recordsProcessed = 0;
    // START
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(
            'SELECT Id, Account__c, Customer_Notified_At__c, Generation_Date__c, Notification_Status__c, Opportunity_Product__c, Type__c' + 
            'FROM Document__c' +
            'WHERE Notification_Status__c = New'
        );
    }

    // EXECUTE
    public void execute(Database.BatchableContext bc, List<Document__c> scope){
        List<ContentDocumentLink> contentDocuments = new List<ContentDocumentLink>();
        List<Document__c> allRelevantDocuments = new List<Document__c>();
        // process each batch of records
        for(Document__c document : scope) {
            allRelevantDocuments.add(document);
            document.Customer_Notified_At__c = Datetime.now();
            document.Notification_Status__c = NOTOFICATION_STATUS_NOTIFIED;
            separateDocumentsByTypes(document);
        }

        update allRelevantDocuments;      
    }

    // FINISH
    public void finish(Database.BatchableContext bc) {

        AsyncApexJob job = [SELECT Id, Status, NumberOfErrors,
            JobItemsProcessed,
            TotalJobItems, CreatedBy.Email
            FROM AsyncApexJob
            WHERE Id = :bc.getJobId()
        ];

        // call utility to send email
        EmailUtils.sendMessage(job, reportDocuments);
        EmailUtils.sendMessage(job, transactionalDocuments);
        EmailUtils.sendMessage(job, legalDocuments);
        EmailUtils.sendMessage(job, contractDocuments);
    }


    // Helper Method
    public void separateDocumentsByTypes(Document__c relevantDocument) {
        if(relevantDocument.Type__c == REPORT_DOCUMENT_TYPE) {
            reportDocuments.add(relevantDocument);
        }else if(relevantDocument.Type__c == TRANSACTIONAL_DOCUMENT_TYPE) {
            transactionalDocuments.add(relevantDocument);
        }else if(relevantDocument.Type__c == LEGAL_DOCUMENT_TYPE) {
            legalDocuments.add(relevantDocument);
        }else if(relevantDocument.Type__c == CONTRACT_DOCUMENT_TYPE) {
            contractDocuments.add(relevantDocument);
        }
    }
}


        
   