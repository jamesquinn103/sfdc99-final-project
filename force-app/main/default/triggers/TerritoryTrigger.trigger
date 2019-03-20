trigger TerritoryTrigger on Territory__c (before insert, before update) {
    TerritoryHandler.checkZipCodes(Trigger.new, Trigger.old, Trigger.isInsert, Trigger.isUpdate, Trigger.isBefore);
}