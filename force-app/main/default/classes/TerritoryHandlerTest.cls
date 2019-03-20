@IsTest
public without sharing class TerritoryHandlerTest {
    static Integer loopSize = 3;
    static List<Territory__c> testTerrs = new List<Territory__c>();
    
    @TestSetup
    public static void makeData() {
        List<Territory__c> territories = new List<Territory__c>();
        for (Integer i = 0; i < loopSize; i++) {
            Territory__c t = new Territory__c(Name = '00000');
            territories.add(t);
        }
        insert territories;     // INSERTING THE MAXIMUM ALLOWED TERRITORIES WITH THE SAME ZIP CODE

        // BEGIN DATA SETUP FOR TERRITORY OWNER CHANGE TEST - ACCOUNT, CONTACT, OPP OWNER REASSIGNMENT
        List<Account> accts = new List<Account>();
        for (Integer i = 0; i < loopSize; i++) {
            Account a = new Account();
            a.Name = 'testAccount';
            if (i == 0) {
                a.BillingPostalCode = '55555';
            } else {
                a.BillingPostalCode = '00000';
            }
            accts.add(a);
        }
        insert accts;               // ONE ACCOUNT WITH DIFFERENT ZIP CODE THAN TERRITORIES, REST OF ACCOUNTS MATCH TERRITORY ZIP CODE AND SHOULD BE UPDATED BY TRIGGER
        Account nonMatchingAcct = accts[0];
        Account matchingAcct = accts[1];
        List<Contact> cons = new List<Contact>();
        for (Integer i = 0; i < loopSize; i++) {
            Contact c = new Contact();
            c.Lastname='TestContact'+i;
            if (i == 0) {
                c.AccountId=nonMatchingAcct.Id;
            } else {
                c.AccountId=matchingAcct.Id;
            }
            cons.add(c);
        }
        insert cons;               // ONE CONTACT ON ACCOUNT WITH DIFFERENT ZIP CODE THAN TERRITORIES, REST OF CONTACTS SHOULD BE UPDATED BY TRIGGER

        List<Opportunity> opps = new List<Opportunity>();
        for (Integer i = 0; i < loopSize; i++) {
            Opportunity o = new Opportunity();
            o.Name = 'testOpp' + i;
            o.StageName = 'Prospecting';
            o.CloseDate = System.Today();
            if (i == 0) {
                o.AccountId=nonMatchingAcct.Id;
            } else {
                o.AccountId=matchingAcct.Id;
            }
            opps.add(o);
        }
        insert opps;               // ONE OPP ON ACCOUNT WITH DIFFERENT ZIP CODE THAN TERRITORIES, REST OF OPPS SHOULD BE UPDATED BY TRIGGER
    }
    @IsTest
    public static void insertError() {
        for (Integer i = 0; i < loopSize; i++) {
            Territory__c t = new Territory__c(Name = '00000');
            testTerrs.add(t);
        }
        Test.startTest();
        try {
            Database.insert(testTerrs, false);         // ATTEMPTING TO INSERT TERRITORY RECORDS WITH A ZIP CODE THAT ALREADY HAS THE MAX NUMBER OF ASSIGNED SALES REPS (TERRITORY RECORDS)
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('zip code'));
        }
        Test.stopTest();
        List<Territory__c> terrs = [SELECT Name, OwnerId FROM Territory__c];
        System.assertEquals(loopSize, terrs.size());        // NO NEW TERRITORY RECORDS WERE INSERTED
    }
    @IsTest
    public static void updateError() {
        for (Integer i = 0; i < loopSize; i++) {
            Territory__c t = new Territory__c(Name = '11111');
            testTerrs.add(t);
        }
        Database.insert(testTerrs, false);

        for (Territory__c t : testTerrs) {
            t.Name = '00000';
        }
        Test.startTest();
        try {
            Database.update(testTerrs, false);         // ATTEMPTING TO UPDATE TERRITORY RECORDS TO A ZIP CODE THAT ALREADY HAS THE MAX NUMBER OF ASSIGNED SALES REPS (TERRITORY RECORDS)
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('zip code'));
        }
        Test.stopTest();
        List<Territory__c> terrs = [SELECT Name, OwnerId FROM Territory__c WHERE Name = '00000'];
        System.assertEquals(loopSize, terrs.size());        // NO TERRITORY RECORDS WERE UPDATED
    }
    @IsTest
    public static void insertNoError() {
        for (Integer i = 0; i < loopSize; i++) {
            Territory__c t = new Territory__c(Name = '11111');
            testTerrs.add(t);
        }
        Test.startTest();
        try {
            Database.insert(testTerrs, false);         // ATTEMPTING TO INSERT TERRITORY RECORDS WITH A ZIP CODE THAT HAS NO EXISTING RECORDS
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('zip code'));  // CATCH BLOCK NOT ENTERED IN THIS TESTMETHOD
        }
        Test.stopTest();
        List<Territory__c> terrs = [SELECT Name, OwnerId FROM Territory__c];
        System.assertEquals(loopSize * 2, terrs.size());        // NEW TERRITORY RECORDS WERE INSERTED SUCCESSFULLY
    }
    @IsTest
    public static void updateNoError() {
        for (Integer i = 0; i < loopSize; i++) {
            Territory__c t = new Territory__c(Name = '11111');
            testTerrs.add(t);
        }
        Database.insert(testTerrs, false);

        for (Territory__c t : testTerrs) {
            t.Name = '22222';
        }
        Test.startTest();
        try {
            Database.update(testTerrs, false);         // ATTEMPTING TO UPDATE TERRITORY RECORDS TO A ZIP CODE THAT HAS NO EXISTING RECORDS
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('zip code'));  // CATCH BLOCK NOT ENTERED IN THIS TESTMETHOD
        }
        Test.stopTest();
        List<Territory__c> terrs = [SELECT Name, OwnerId FROM Territory__c WHERE Name = '22222'];
        System.assertEquals(loopSize, terrs.size());        //  TERRITORY RECORDS WERE UPDATED SUCCESSFULLY
    }
    @IsTest
    public static void insertMixedResults() {
        for (Integer i = 0; i < loopSize; i++) {
            Territory__c t = new Territory__c(Name = '00000');
            testTerrs.add(t);
            testTerrs[0].Name = '11111';     // CHANGING ONE TERRITORY RECORD SO THAT IT WILL NOT BE CAUGHT BY VALIDATION
        }
        Test.startTest();
        try {
            Database.insert(testTerrs, false);         // ATTEMPTING TO INSERT TERRITORY RECORDS WITH A ZIP CODE THAT ALREADY HAS THE MAX NUMBER OF ASSIGNED SALES REPS (TERRITORY RECORDS)
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('zip code'));
        }
        Test.stopTest();
        List<Territory__c> terrs = [SELECT Name, OwnerId FROM Territory__c];
        System.assertEquals(loopSize + 1, terrs.size());        // ONE NEW TERRITORY RECORD WAS INSERTED
    }
    @IsTest
    public static void updateMixedResults() {
        for (Integer i = 0; i < loopSize; i++) {
            Territory__c t = new Territory__c(Name = '11111');
            testTerrs.add(t);
        }
        Database.insert(testTerrs, false);

        for (Territory__c t : testTerrs) {
            t.Name = '00000';
        }
        testTerrs[0].Name = '55555';     // CHANGING ONE TERRITORY RECORD SO THAT IT WILL NOT BE CAUGHT BY VALIDATION
        Test.startTest();
        try {
            Database.update(testTerrs, false);         // ATTEMPTING TO UPDATE TERRITORY RECORDS TO A ZIP CODE THAT ALREADY HAS THE MAX NUMBER OF ASSIGNED SALES REPS (TERRITORY RECORDS)
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('zip code'));
        }
        Test.stopTest();
        List<Territory__c> terrs = [SELECT Name, OwnerId FROM Territory__c WHERE Name = '00000'];
        System.assertEquals(loopSize, terrs.size());        // NO TERRITORY RECORDS WERE UPDATED TO '00000'
        List<Territory__c> updatedTerrs = [SELECT Name, OwnerId FROM Territory__c WHERE Name = '55555'];
        System.assertEquals(1, updatedTerrs.size());        // ONE TERRITORY RECORDS WAS UPDATED TO '55555'
    }

    // BEGIN TESTMETHODS TO TEST THAT WHEN A TERRITORY'S OWNER CHANGES, ANY ACCOUNTS IN THAT ZIP CODE GET REASSIGNED TO NEW OWNER, ALONG WITH CONTACTS AND OPPS
    @IsTest
    public static void updateOwner() {
        testTerrs = [SELECT Id, OwnerId, Name FROM Territory__c];
        /*for (Integer i = 0; i < loopSize; i++) {
            Territory__c t = new Territory__c(Name = '11111');
            testTerrs.add(t);
        }
        Database.insert(testTerrs, false);*/
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator']; 
		User usr = new User(Alias = 'standt', Email='standarduser@testorg.com', 
					EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
					LocaleSidKey='en_US', ProfileId = p.Id, 
					TimeZoneSidKey='America/Los_Angeles', UserName='standarduser@testorg.com.testing');
		insert usr;
        System.debug('myUser.Id: '+ UserInfo.getUserId() + '----- usr.Id: ' + usr.Id);
        for (Territory__c t : testTerrs) {
            t.OwnerId = usr.Id;               // OWNER EXPLICITLY SET TO OTHER USER
        }
        Test.startTest();
        update testTerrs;        // UPDATE TERRITORY RECORDS THAT WILL HAVE A NEW OWNER
        Test.stopTest();

        // TERRITORY__c
        List<Territory__c> updatedTerrs = [SELECT OwnerId FROM Territory__c WHERE OwnerId = :usr.Id];
        System.assertEquals(loopSize, updatedTerrs.size());        //  TERRITORY RECORDS WERE ALL UPDATED SUCCESSFULLY

        // ACCOUNT
        List<Account> updatedAccts =  [SELECT OwnerId FROM Account WHERE OwnerId = :usr.Id];
        System.assertEquals(loopSize - 1, updatedAccts.size());        //  ALL BUT 1 ACCOUNT RECORDS WERE UPDATED
        List<Account> nonUpdatedAccts =  [SELECT OwnerId FROM Account WHERE OwnerId = :UserInfo.getUserId()];
        System.assertEquals(1, nonUpdatedAccts.size());        //  ONE ACCOUNT RECORD DID NOT MATCH TERRITORY ZIP AND WAS NOT UPDATED

        // CONTACT
        List<Contact> updatedCons =  [SELECT OwnerId FROM Contact WHERE OwnerId = :usr.Id];
        System.assertEquals(loopSize - 1, updatedCons.size());        //  ALL BUT 1 CONTACT RECORDS WERE UPDATED
        List<Contact> nonUpdatedCons =  [SELECT OwnerId FROM Contact WHERE OwnerId = :UserInfo.getUserId()];
        System.assertEquals(1, nonUpdatedCons.size());        //  ONE CONTACT RECORD IS ON AN ACCOUNT THAT DID NOT GET UPDATED, SO CONTACT DID NOT GET UPDATED EITHER
        
        // OPPORTUNITY
        List<Opportunity> updatedOpps =  [SELECT OwnerId FROM Opportunity WHERE OwnerId = :usr.Id];
        System.assertEquals(loopSize - 1, updatedOpps.size());        //  ALL BUT 1 OPP RECORDS WERE UPDATED
        List<Opportunity> nonUpdatedOpps =  [SELECT OwnerId FROM Opportunity WHERE OwnerId = :UserInfo.getUserId()];
        System.assertEquals(1, nonUpdatedOpps.size());        //  ONE OPP RECORD IS ON AN ACCOUNT THAT DID NOT GET UPDATED, SO OPP DID NOT GET UPDATED EITHER

        // ASSIGNMENT_HISTORY__c
        List<Assignment_History__c> lstHist = [SELECT Id FROM Assignment_History__c];
        System.debug(lstHist);
        System.assertEquals(loopSize, lstHist.size());    // ASSIGNMENT HISTORY RECORDS SHOULD NOT BE CREATED SINCE ACCOUNT ZIP CODE IS NOT CHANGING (3 RECORDS SHOULD BE CREATED IN TESTSETUP METHOD WHEN ACCOUNTS ARE INSERTED)
    }
    // ADD MORE ASSERTIONS TO TEST THAT THE RELATED ACCOUNT(S), CONTACTS AND OPPS OWNER CHANGED. NEED TO MAKE MORE TEST DATA FOR THOSE     
}