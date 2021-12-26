/**
 * @description       : 
 * @author            : Ivan Mickovski
 * @group             : 
 * @last modified on  : 26.12.2021
 * @last modified by  : Ivan Mickovski
**/
public with sharing class EmailUtils {

    public static void sendMessage(AsyncApexJob job, List<Document__c> documents) {
        // Filter only Document Object Ids for preparingFileAttachments
        Set<Id> documentIds = new Set<Id>();
        Set<Id> accountIds = new Set<Id>();
        String documentType;

        for(Document__c doc : documents) {
            documentIds.add(doc.Id); 
            accountIds.add(doc.Account__c); 
            documentType = doc.Type__c;
        }
    
        // All Files on Related Document__c Object
        List<ContentDocumentLink> conDocLinks = [
            SELECT Id, LinkedEntityId, ContentDocumentId, ContentDocument.Title,ContentDocument.createdDate, ContentDocument.FileType 
            FROM ContentDocumentLink 
            WHERE LinkedEntityId IN :documentIds
        ];

        // Getting All ContentDocuments Ids from Parent Document__c Object
        Set<Id> contentDocumentIds = new Set<Id>();

        for (Id docId : documentIds) {

            for(ContentDocumentLink conLink : conDocLinks) {
                
                if(conLink.LinkedEntityId == docId) {

                    contentDocumentIds.add(conLink.ContentDocumentId);
                }

            }
        }

        // Getting ContentVersion for VersionData Email Attachment
        List<ContentVersion> docsContentVersion = [
            SELECT Id, Title, FileType, VersionData, isLatest, ContentDocumentId
            FROM ContentVersion
            WHERE ContentDocumentId 
            IN :contentDocumentIds
        ];


        for(Contact con : [ SELECT Id, Name, Email, AccountId FROM Contact WHERE AccountId IN :accountIds]) {
            // Create the Email
            for(Document__c doc : documents) { 
                sendEmail(con, doc, documentType, docsContentVersion);
            }
        }
    }

    public static void sendEmail(Contact con, Document__c doc, String documentType, List<ContentVersion> docsContentVersion) {
        
        if(con.AccountId == doc.Account__c) {
            Messaging.SingleEmailMessage singleEmail = new Messaging.SingleEmailMessage();
            String[] sendingTo = new String[]{con.Email};
            singleEmail.setToAddresses(sendingTo);    
            singleEmail.setSubject('Email Subject ' + documentType);
            singleEmail.setPlainTextBody('Lorem Ipsum is simply dummy text of the printing and typesetting industry');
            singleEmail.setFileAttachments(prepareFileAttachments(docsContentVersion));
            // singleEmail.setPlainTextBody('The Batch Apex job processed '+ job.TotalJobItems + 
            // 'batches with '+ job.NumberOfErrors + 'failures '+'Job Itemprocessed are '+ job.JobItemsProcessed);
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] {singleEmail});
        }
    }

    public static List<Messaging.Emailfileattachment> prepareFileAttachments(List<ContentVersion> docsContentVersion) {

        List<Messaging.Emailfileattachment> fileAttachments = new List<Messaging.Emailfileattachment>();
        for(ContentVersion singleContentVersion : docsContentVersion ) {

            // Creating the Email Attachment
            Messaging.EmailFileAttachment emailAttachment = new Messaging.EmailFileAttachment();
            String titel = singleContentVersion.Title + '.' + singleContentVersion.FileType;
            emailAttachment.setBody(singleContentVersion.VersionData);
            emailAttachment.setFileName(titel);
            fileAttachments.add(emailAttachment);
        }
        
        return fileAttachments;
    }
}

