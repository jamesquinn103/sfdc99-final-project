trigger AccountTrigger on Account (after insert, after update) {
    AccountHandler.checkZipCodes(Trigger.new, Trigger.old, Trigger.oldMap, Trigger.isInsert, Trigger.isUpdate, Trigger.isDelete, Trigger.isUndelete, Trigger.isBefore, Trigger.isAfter);
}