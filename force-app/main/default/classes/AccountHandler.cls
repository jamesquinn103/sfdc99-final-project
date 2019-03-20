public without sharing class AccountHandler {
    // Update territory assignments when Account zip code changes, or is created/deleted
    public static void checkZipCodes(List<Account> triggerNew, List<Account> triggerOld, Map<Id, Account> oldMap, Boolean isInsert, Boolean isUpdate, Boolean isDelete, Boolean isUndelete, Boolean isBefore, Boolean isAfter) {
    List<Account> acctsToProcess = new List<Account>();
    List<Account> oldAccts = new List<Account>();
        // If this is an insert, if the Account's zip code has been populated, add Account to list to be updated
        if (isInsert && isAfter) {
            for (Account a : triggerNew) {
                if (a.BillingPostalCode != null) {
                    acctsToProcess.add(a);
                }
            }
        }
        // If this is an update, if the Account's zip code is changed, add Account to list to be updated
        if (isUpdate && isAfter) {
            for (Integer i = 0; i < triggerNew.size(); i++) {
                if (triggerNew[i].BillingPostalCode != triggerOld[i].BillingPostalCode) {
                    acctsToProcess.add(triggerNew[i]);
                    oldAccts.add(triggerOld[i]);
                }
            }
        }
        // Call method to update ownership for Accounts, Contacts, and Opportunities
        if (!acctsToProcess.isEmpty()) {
            updateOwnership(acctsToProcess, oldAccts, oldMap, isInsert, null);
        }
    }
    public static void updateOwnership(List<Account> acctsToProcess, List<Account> oldAccts, Map<Id, Account> oldMap, Boolean isInsert, List<Territory__c> updatedTerrs) {
        List<Account> acctsToUpdate = new List<Account>();
        List<Contact> consToUpdate = new List<Contact>();
        List<Opportunity> oppsToUpdate = new List<Opportunity>();
        List<Assignment_History__c> lstHist = new List<Assignment_History__c>();
        List<Territory__c> newTerritories = new List<Territory__c>();
        // Query Accounts and related Contacts and Opportunities that need to be operated on
        List<Account> accts = [SELECT Id, OwnerId, BillingPostalCode, (SELECT OwnerId FROM Contacts), (SELECT OwnerId FROM Opportunities WHERE IsClosed = FALSE) FROM Account WHERE Id IN :acctsToProcess];
        if (updatedTerrs != null && !updatedTerrs.isEmpty()) {
            newTerritories = updatedTerrs;
        } else {
            // Call helper method to get List of Territory records for relevant zip codes
            newTerritories = getTerritories(accts);
        }
        System.debug(newTerritories);
        List<Territory__c> oldTerritories = new List<Territory__c>();
        if (oldAccts != null && !oldAccts.isEmpty()) {
            oldTerritories = getTerritories(oldAccts);
        }
        // For each account, update the owner to the Owner of the Territory of the new Zip Code
        for (Account a : accts) {
            String oldOwnerId;
            String newOwnerId;
            String oldTerrId;
            String newTerrId;
            if (oldMap != null && !oldMap.isEmpty()) {
                Account oldAcc = oldMap.get(a.Id);
                String oldZip = oldAcc.BillingPostalCode;
                oldOwnerId = oldAcc.OwnerId;
                for (Territory__c oldTerr : oldTerritories) {
                    if (oldZip == oldTerr.Name && oldOwnerId == oldTerr.OwnerId) {
                        oldTerrId = oldTerr.Id;
                        break;
                    }
                }
            }
            List<Territory__c> matchingTerrs = new List<Territory__c>();
            String zip = a.BillingPostalCode;
            for (Territory__c t : newTerritories) {
                if (zip == t.Name) {
                    matchingTerrs.add(t);
                }
            }
            Integer numMatches = matchingTerrs.size();
            if (numMatches == 1) {                      // Get the zip code Territory Owner
                newTerrId = matchingTerrs[0].Id;
                newOwnerId = matchingTerrs[0].OwnerId;
            } else if (numMatches > 1) {                // If the zip code has multiple owners, choose one at random
                Double rand = Math.floor(Math.random() * numMatches);
                Integer idx = rand.intValue();
                newTerrId = matchingTerrs[idx].Id;
                newOwnerId = matchingTerrs[idx].OwnerId;
            }
            // Instantiate an Assignment_History__c record for the Account Zip Code change
            if (oldAccts != null || isInsert) {
                Assignment_History__c ah = new Assignment_History__c();
                ah.Account__c = a.Id;
                ah.Changed_By__c = UserInfo.getUserId();
                ah.Previous_Owner__c = oldOwnerId;
                if (newOwnerId != null) {
                    ah.New_Owner__c = newOwnerId;
                } else {
                    ah.New_Owner__c = a.OwnerId;
                }
                ah.Previous_Territory__c = oldTerrId;
                ah.New_Territory__c = newTerrId;
                lstHist.add(ah);
            }
            
            if (newOwnerId != null) {                      // If there is a territory that matches the Account's new zip code,
                // update the OwnerId of the Account and all related Contacts and open Opportunities
                a.OwnerId = newOwnerId;
                acctsToUpdate.add(a);
                for (Contact c : a.Contacts) {
                    c.OwnerId = newOwnerId;
                    consToUpdate.add(c);
                }
                for (Opportunity o : a.Opportunities) {
                    o.OwnerId = newOwnerId;
                    oppsToUpdate.add(o);
                }
            }
        }
        if (!lstHist.isEmpty()) {
            insert lstHist;
        }
        if (!acctsToUpdate.isEmpty()) {
            update acctsToUpdate;
        }
        if (!consToUpdate.isEmpty()) {
            update consToUpdate;
        }
        if (!oppsToUpdate.isEmpty()) {
            update oppsToUpdate;
        }
    }
    private static List<Territory__c> getTerritories(List<Account> accts) {
        // Get Account Zip Codes into a list
        List<String> zipCodes = new List<String>();
        for (Account a : accts) {
            zipCodes.add(a.BillingPostalCode);
        }
        // Query Territory records for the relevant Zip Codes
        List<Territory__c> territories = [SELECT Id, Name, OwnerId FROM Territory__c WHERE Name IN :zipCodes];

        return territories;
    }
}
