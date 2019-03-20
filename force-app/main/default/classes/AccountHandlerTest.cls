@IsTest
public without sharing class AccountHandlerTest {
    static Integer loopSize = 9;
    @TestSetup
    static void makeData() {
        List<Territory__c> terrs = new List<Territory__c>();
        for (Integer i = 0; i < loopSize; i++) {
            Territory__c t = new Territory__c();
            if (i == 0) {
                t.Name = '55555';
            } else if (i == 1) {
                t.Name = '00000';
            } else {
                t.Name = '11111';
            }
            terrs.add(t);
        }
        insert terrs;

        Account a = new Account();
        a.Name = 'factoryAccount';
        a.BillingPostalCode = '55555';
        insert a;

        List<Contact> cons = new List<Contact>();
        for (Integer i = 0; i < loopSize; i++) {
            Contact c = new Contact(Lastname='TestContact'+i, AccountId=a.Id);
            cons.add(c);
        }
        insert cons;

        List<Opportunity> opps = new List<Opportunity>();
        for (Integer i = 0; i < loopSize; i++) {
            Opportunity o = new Opportunity();
            o.Name = 'testOpp' + i;
            o.StageName = 'Prospecting';
            o.CloseDate = System.Today();
            o.AccountId = a.Id;
            opps.add(o);
        }
        insert opps;
    }
    @IsTest
    public static void insertSingleTerrMatch() {
        List<Account> acctList = new List<Account>();
        for (Integer i = 0; i < loopSize; i++) {
            Account a = new Account();
            a.Name = 'testAccount'+i;
            a.BillingPostalCode = '00000';    // ONE MATCHING TERRITORY FOR THIS ZIP CODE
            acctList.add(a);
        }
        Test.startTest();
            Profile p = [SELECT Id FROM Profile WHERE Name='Standard User']; 
			User usr = new User(Alias = 'standt', Email='standarduser@testorg.com', 
						EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
						LocaleSidKey='en_US', ProfileId = p.Id, 
						TimeZoneSidKey='America/Los_Angeles', UserName='standarduser@testorg.com.testing');
			insert usr;
            System.debug('myUser.Id: '+ UserInfo.getUserId() + '----- usr.Id: ' + usr.Id);
			System.runAs(usr)
			{
                for (Account a : acctList) {
                    a.OwnerId = usr.Id;               // OWNER EXPLICITLY SET TO OTHER USER
                }
				insert acctList;
			}
        Test.stopTest();
        List<Account> updatedAccts = [SELECT OwnerId FROM Account WHERE Name != 'factoryAccount'];
        System.assertEquals(loopSize, updatedAccts.size());
        for (Account a : updatedAccts) {
            System.assertEquals(UserInfo.getUserId(), a.OwnerId);  // OWNER UPDATED TO TERRITORY OWNER
        }
        List<Assignment_History__c> lstHist = [SELECT Account__c, Changed_By__c, Previous_Owner__c, New_Owner__c, Previous_Territory__c, New_Territory__c FROM Assignment_History__c WHERE Account__r.Name != 'factoryAccount'];
        System.assertEquals(loopSize, lstHist.size());          // A HISTORY RECORD WAS ADDED FOR EACH ACCOUNT IN THE TRIGGER
    }
    @IsTest
    public static void insertMultiTerrMatch() {
        List<Account> acctList = new List<Account>();
        for (Integer i = 0; i < loopSize; i++) {
            Account a = new Account();
            a.Name = 'testAccount'+i;
            a.BillingPostalCode = '11111';    // MANY MATCHING TERRITORIES FOR THIS ZIP CODE
            acctList.add(a);
        }
        Test.startTest();
            Profile p = [SELECT Id FROM Profile WHERE Name='Standard User']; 
			User usr = new User(Alias = 'standt', Email='standarduser@testorg.com', 
						EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
						LocaleSidKey='en_US', ProfileId = p.Id, 
						TimeZoneSidKey='America/Los_Angeles', UserName='standarduser@testorg.com.testing');
			insert usr;
            System.debug('myUser.Id: '+ UserInfo.getUserId() + '----- usr.Id: ' + usr.Id);
			System.runAs(usr)
			{
                for (Account a : acctList) {
                    a.OwnerId = usr.Id;               // OWNER EXPLICITLY SET TO OTHER USER
                }
				insert acctList;
			}
        Test.stopTest();
        List<Account> updatedAccts = [SELECT OwnerId FROM Account WHERE Name != 'factoryAccount'];
        System.assertEquals(loopSize, updatedAccts.size());
        for (Account a : updatedAccts) {
            System.assertEquals(UserInfo.getUserId(), a.OwnerId);  // OWNER UPDATED TO TERRITORY OWNER
        }
        List<Assignment_History__c> lstHist = [SELECT Account__c, Changed_By__c, Previous_Owner__c, New_Owner__c, Previous_Territory__c, New_Territory__c FROM Assignment_History__c WHERE Account__r.Name != 'factoryAccount'];
        System.assertEquals(loopSize, lstHist.size());          // A HISTORY RECORD WAS ADDED FOR EACH ACCOUNT IN THE TRIGGER
    }
    @IsTest
    public static void insertNoTerrMatch() {
        List<Account> acctList = new List<Account>();
        for (Integer i = 0; i < loopSize; i++) {
            Account a = new Account();
            a.Name = 'testAccount'+i;
            a.BillingPostalCode = '22222';    // NO MATCHING TERRITORY FOR THIS ZIP CODE (CRITERIA TO UPDATE OWNER NOT MET)
            acctList.add(a);
        }
        Test.startTest();
            Profile p = [SELECT Id FROM Profile WHERE Name='Standard User']; 
			User usr = new User(Alias = 'standt', Email='standarduser@testorg.com', 
						EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
						LocaleSidKey='en_US', ProfileId = p.Id, 
						TimeZoneSidKey='America/Los_Angeles', UserName='standarduser@testorg.com.testing');
			insert usr;
            System.debug('myUser.Id: '+ UserInfo.getUserId() + '----- usr.Id: ' + usr.Id);
			System.runAs(usr)
			{
                for (Account a : acctList) {
                    a.OwnerId = usr.Id;               // OWNER EXPLICITLY SET TO OTHER USER
                }
				insert acctList;
			}
        Test.stopTest();
        List<Account> updatedAccts = [SELECT OwnerId FROM Account WHERE Name != 'factoryAccount'];
        System.assertEquals(loopSize, updatedAccts.size());
        for (Account a : updatedAccts) {
            System.assertEquals(usr.Id, a.OwnerId);  // OWNER HAS NOT CHANGED 
        }
        List<Assignment_History__c> lstHist = [SELECT Account__c, Changed_By__c, Previous_Owner__c, New_Owner__c, Previous_Territory__c, New_Territory__c FROM Assignment_History__c WHERE Account__r.Name != 'factoryAccount'];
        System.assertEquals(loopSize, lstHist.size());          // A HISTORY RECORD WAS ADDED FOR EACH ACCOUNT IN THE TRIGGER
    }
    @IsTest
    public static void updateSingleTerrMatch() {
        List<Account> acctList = new List<Account>();
        List<Account> accts = [SELECT Name, OwnerId, BillingPostalCode FROM Account];
        for (Account a : accts) {
            a.Name = 'testAccount';
            a.BillingPostalCode = '00000';    // ONE MATCHING TERRITORY FOR THIS ZIP CODE
            acctList.add(a);
        }
        Test.startTest();
            Profile p = [SELECT Id FROM Profile WHERE Name='Standard User']; 
			User usr = new User(Alias = 'standt', Email='standarduser@testorg.com', 
						EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
						LocaleSidKey='en_US', ProfileId = p.Id, 
						TimeZoneSidKey='America/Los_Angeles', UserName='standarduser@testorg.com.testing');
			insert usr;
            System.debug('myUser.Id: '+ UserInfo.getUserId() + '----- usr.Id: ' + usr.Id);
			System.runAs(usr)
			{
                acctList[0].OwnerId = usr.Id;               // OWNER EXPLICITLY SET TO OTHER USER
                List<Contact> cons = new List<Contact>();
                for (Contact c : [SELECT OwnerId FROM Contact]) {
                    c.OwnerId = usr.Id;               // OWNER EXPLICITLY SET TO OTHER USER
                    cons.add(c);
                }
                update cons;
                List<Opportunity> opps = new List<Opportunity>();
                for (Opportunity o : [SELECT OwnerId FROM Opportunity]) {
                    o.OwnerId = usr.Id;               // OWNER EXPLICITLY SET TO OTHER USER
                    opps.add(o);
                }
                update opps;
				update acctList;
			}
        Test.stopTest();
        List<Account> updatedAccts = [SELECT OwnerId FROM Account];
        System.assertEquals(1, updatedAccts.size());
        for (Account a : updatedAccts) {
            System.assertEquals(UserInfo.getUserId(), a.OwnerId);  // OWNER UPDATED TO TERRITORY OWNER
        }
        List<Contact> updatedCons = [SELECT OwnerId FROM Contact];
        System.assertEquals(loopSize, updatedCons.size());
        for (Contact c : updatedCons) {
            System.assertEquals(UserInfo.getUserId(), c.OwnerId);  // OWNER UPDATED TO TERRITORY OWNER
        }
        List<Opportunity> updatedOpps = [SELECT OwnerId FROM Opportunity];
        System.assertEquals(loopSize, updatedOpps.size());
        for (Opportunity o : updatedOpps) {
            System.assertEquals(UserInfo.getUserId(), o.OwnerId);  // OWNER UPDATED TO TERRITORY OWNER
        }
        List<Assignment_History__c> lstHist = [SELECT Account__c, Changed_By__c, Previous_Owner__c, New_Owner__c, Previous_Territory__c, New_Territory__c FROM Assignment_History__c WHERE Previous_Owner__c != null];
        System.assertEquals(updatedAccts.size(), lstHist.size());          // A HISTORY RECORD WAS ADDED FOR EACH ACCOUNT IN THE TRIGGER
    }
    @IsTest
    public static void updateMultiTerrMatch() {
        List<Account> acctList = new List<Account>();
        List<Account> accts = [SELECT Name, OwnerId, BillingPostalCode FROM Account];
        for (Account a : accts) {
            a.Name = 'testAccount';
            a.BillingPostalCode = '11111';    // MANY MATCHING TERRITORIES FOR THIS ZIP CODE
            acctList.add(a);
        }
        Test.startTest();
            Profile p = [SELECT Id FROM Profile WHERE Name='Standard User']; 
			User usr = new User(Alias = 'standt', Email='standarduser@testorg.com', 
						EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
						LocaleSidKey='en_US', ProfileId = p.Id, 
						TimeZoneSidKey='America/Los_Angeles', UserName='standarduser@testorg.com.testing');
			insert usr;
            System.debug('myUser.Id: '+ UserInfo.getUserId() + '----- usr.Id: ' + usr.Id);
			System.runAs(usr)
			{
                acctList[0].OwnerId = usr.Id;               // OWNER EXPLICITLY SET TO OTHER USER
                List<Contact> cons = new List<Contact>();
                for (Contact c : [SELECT OwnerId FROM Contact]) {
                    c.OwnerId = usr.Id;               // OWNER EXPLICITLY SET TO OTHER USER
                    cons.add(c);
                }
                update cons;
                List<Opportunity> opps = new List<Opportunity>();
                for (Opportunity o : [SELECT OwnerId FROM Opportunity]) {
                    o.OwnerId = usr.Id;               // OWNER EXPLICITLY SET TO OTHER USER
                    opps.add(o);
                }
                update opps;
				update acctList;
			}
        Test.stopTest();
        List<Account> updatedAccts = [SELECT OwnerId FROM Account];
        System.assertEquals(1, updatedAccts.size());
        for (Account a : updatedAccts) {
            System.assertEquals(UserInfo.getUserId(), a.OwnerId);  // OWNER UPDATED TO TERRITORY OWNER
        }
        List<Contact> updatedCons = [SELECT OwnerId FROM Contact];
        System.assertEquals(loopSize, updatedCons.size());
        for (Contact c : updatedCons) {
            System.assertEquals(UserInfo.getUserId(), c.OwnerId);  // OWNER UPDATED TO TERRITORY OWNER
        }
        List<Opportunity> updatedOpps = [SELECT OwnerId FROM Opportunity];
        System.assertEquals(loopSize, updatedOpps.size());
        for (Opportunity o : updatedOpps) {
            System.assertEquals(UserInfo.getUserId(), o.OwnerId);  // OWNER UPDATED TO TERRITORY OWNER
        }
        List<Assignment_History__c> lstHist = [SELECT Account__c, Changed_By__c, Previous_Owner__c, New_Owner__c, Previous_Territory__c, New_Territory__c FROM Assignment_History__c WHERE Previous_Owner__c != null];
        System.assertEquals(updatedAccts.size(), lstHist.size());          // A HISTORY RECORD WAS ADDED FOR EACH ACCOUNT IN THE TRIGGER
    }
    @IsTest
    public static void updateNoTerrMatch() {
        List<Account> acctList = new List<Account>();
        List<Account> accts = [SELECT Name, OwnerId, BillingPostalCode FROM Account];
        for (Account a : accts) {
            a.Name = 'testAccount';
            a.BillingPostalCode = '33333';    // NO MATCHING TERRITORY FOR THIS ZIP CODE (CRITERIA TO UPDATE OWNER NOT MET)
            acctList.add(a);
        }
        Test.startTest();
            Profile p = [SELECT Id FROM Profile WHERE Name='Standard User']; 
			User usr = new User(Alias = 'standt', Email='standarduser@testorg.com', 
						EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
						LocaleSidKey='en_US', ProfileId = p.Id, 
						TimeZoneSidKey='America/Los_Angeles', UserName='standarduser@testorg.com.testing');
			insert usr;
            System.debug('myUser.Id: '+ UserInfo.getUserId() + '----- usr.Id: ' + usr.Id);
			System.runAs(usr)
			{
                acctList[0].OwnerId = usr.Id;               // OWNER EXPLICITLY SET TO OTHER USER
                List<Contact> cons = new List<Contact>();
                for (Contact c : [SELECT OwnerId FROM Contact]) {
                    c.OwnerId = usr.Id;               // OWNER EXPLICITLY SET TO OTHER USER
                    cons.add(c);
                }
                update cons;
                List<Opportunity> opps = new List<Opportunity>();
                for (Opportunity o : [SELECT OwnerId FROM Opportunity]) {
                    o.OwnerId = usr.Id;               // OWNER EXPLICITLY SET TO OTHER USER
                    opps.add(o);
                }
                update opps;
				update acctList;
			}
        Test.stopTest();
        List<Account> updatedAccts = [SELECT OwnerId FROM Account];
        System.assertEquals(1, updatedAccts.size());
        for (Account a : updatedAccts) {
            System.assertEquals(usr.Id, a.OwnerId);  // OWNER HAS NOT CHANGED 
        }
        List<Contact> updatedCons = [SELECT OwnerId FROM Contact];
        System.assertEquals(loopSize, updatedCons.size());
        for (Contact c : updatedCons) {
            System.assertEquals(usr.Id, c.OwnerId);  // OWNER HAS NOT CHANGED 
        }
        List<Opportunity> updatedOpps = [SELECT OwnerId FROM Opportunity];
        System.assertEquals(loopSize, updatedOpps.size());
        for (Opportunity o : updatedOpps) {
            System.assertEquals(usr.Id, o.OwnerId);  // OWNER HAS NOT CHANGED 
        }
        List<Assignment_History__c> lstHist = [SELECT Account__c, Changed_By__c, Previous_Owner__c, New_Owner__c, Previous_Territory__c, New_Territory__c FROM Assignment_History__c WHERE Previous_Owner__c != null];
        System.assertEquals(updatedAccts.size(), lstHist.size());          // A HISTORY RECORD WAS ADDED FOR EACH ACCOUNT IN THE TRIGGER
    }
}