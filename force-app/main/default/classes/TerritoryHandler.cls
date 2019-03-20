public without sharing class TerritoryHandler {
    public static void checkZipCodes(List<Territory__c> triggerNew, List<Territory__c> triggerOld, Boolean isInsert, Boolean isUpdate, Boolean isBefore) {
        List<Territory__c> territories = new List<Territory__c>();
        List<Territory__c> terrsWithOwnerChanges = new List<Territory__c>();
        List<Territory__c> terrsWithOwnerChangesOld = new List<Territory__c>();
        if (isInsert && isBefore) {
            territories.addAll(triggerNew);
        }
        if (isUpdate && isBefore) {
            for (Integer i = 0; i < triggerNew.size(); i++) {
                if (triggerNew[i].Name != triggerOld[i].Name) {
                    territories.add(triggerNew[i]);
                }
                if (triggerNew[i].OwnerId != triggerOld[i].OwnerId) {
                    terrsWithOwnerChanges.add(triggerNew[i]);
                    terrsWithOwnerChangesOld.add(triggerOld[i]);
                }
            }
        }
        if (!territories.isEmpty()) {
            checkExistingTerritories(territories);
        }
        if (!terrsWithOwnerChanges.isEmpty()) {
            System.debug(terrsWithOwnerChanges[0].OwnerId);
            List<Account> accts = getAccountsInTerritoryZip(terrsWithOwnerChangesOld);
            AccountHandler.updateOwnership(accts, null, null, isInsert, terrsWithOwnerChanges);
        }
    }
        private static void checkExistingTerritories(List<Territory__c> territories) {
            // Get all the existing territories for zip codes that match those in the trigger
            List<Territory__c> existingTerrs = getExistingTerritories(territories);
            // Loop through trigger records and for each, determine whether the insert should be prevented
            for (Territory__c t : territories) {
                String zipCode = t.Name;
                Integer matchCounter = 0;
                for (Territory__c existingTerr : existingTerrs) {
                    if (existingTerr.Name == zipCode) {
                        matchCounter++;
                        if (matchCounter >= 3) {
                            break;
                        }
                    }
                }
                if (matchCounter >= 3) {
                    t.addError('A maximum of 3 sales representatives can be assigned to a single zip code');
                }
            }
        }
    private static List<Territory__c> getExistingTerritories (List<Territory__c> territories) {
        // Build a list of zip codes in the trigger
        List<String> zipCodes = new List<String>();
        for (Territory__c t : territories) {
            zipCodes.add(t.Name);
        }
        // Get all the existing territories for zip codes that match those in the trigger
        return [SELECT Name, OwnerId FROM Territory__c WHERE Name IN :zipCodes];
    }
    private static List<Account> getAccountsInTerritoryZip(List<Territory__c> terrs) {
        // Get Territory Zip Codes and OwnerIds into a list
        List<String> zipCodes = new List<String>();
        List<String> ownerIds = new List<String>();
            for (Territory__c t : terrs) {
                zipCodes.add(t.Name);
                ownerIds.add(t.OwnerId);
            }
        // Query Account records for the relevant Zip Codes
        List<Account> accts = [SELECT Id FROM Account WHERE BillingPostalCode IN :zipCodes AND OwnerId IN :ownerIds];

        return accts;
    }
}