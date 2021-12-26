/**
 * @description       : 
 * @author            : Ivan Mickovski
 * @group             : 
 * @last modified on  : 26.12.2021
 * @last modified by  : Ivan Mickovski
**/
public with sharing class BatchClassInvoke {

    RenewDailyRelevantDocuments batchObject = new RenewDailyRelevantDocuments();
    Id batchId = Database.executeBatch(batchObject, 4000);
}
