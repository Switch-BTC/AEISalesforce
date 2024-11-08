@isTest
public class QB_EntityTrigger_Test {
    
    @testSetup
    public static void PrepareEstimateData(){

        QB_ApiDataUtils.createTEstApiToken();
        
        test.startTest();
        Account acc = new Account();
        acc.Name = 'Vendor 1';
        acc.Company__c = 'ACT';
        acc.Type = 'Prospect';
        acc.Phone = '787-352-5522';
        insert acc;

        WorkOrder__c wo = new WorkOrder__c();
        wo.Account__c = acc.Id;
        wo.Company__c = 'ACT';
        insert wo;
        
    }
    
    @isTest
    public static void TestQB_Entity_trigger(){
        WorkOrder__c wo = [select name from WorkOrder__c limit 1];
        Realm_Id__mdt re = [select Realm_Id__c from Realm_Id__mdt limit 1];
        QB_Entity__c qbe = new QB_Entity__c();
        qbe.QB_Id__c = '2';
        qbe.Last_Updated__c = '2019-10-06T22:06:49.000Z';
        qbe.Transaction_Name__c = 'invoice';
        qbe.Operation__c = 'create';
        qbe.Realm_Id__c = re.Realm_Id__c;
        test.startTest();
        Test.setMock(HttpCalloutMock.class, new QB_MockInvoiceEventCallout(wo.Name));
        insert qbe;
        test.stopTest();
    }

    @isTest
    public static void TestQB_Entity_triggerCM(){
        WorkOrder__c wo = [select name from WorkOrder__c limit 1];
        Realm_Id__mdt re = [select Realm_Id__c from Realm_Id__mdt limit 1];
        QB_Entity__c qbe = new QB_Entity__c();
        qbe.QB_Id__c = '2';
        qbe.Last_Updated__c = '2019-10-06T22:06:49.000Z';
        qbe.Transaction_Name__c = 'creditmemo';
        qbe.Operation__c = 'create';
        qbe.Realm_Id__c = re.Realm_Id__c;
        test.startTest();
        Test.setMock(HttpCalloutMock.class, new QB_MockCreditMemoEventCallout(wo.Name));
        insert qbe;
        test.stopTest();
    }

    @isTest
    public static void TestQB_Entity_triggerCMUpdate(){
        WorkOrder__c wo = [select name from WorkOrder__c limit 1];
        Realm_Id__mdt re = [select Realm_Id__c from Realm_Id__mdt limit 1];
        QB_Entity__c qbe = new QB_Entity__c();
        qbe.QB_Id__c = '2';
        qbe.Last_Updated__c = '2019-10-06T22:06:49.000Z';
        qbe.Transaction_Name__c = 'creditmemo';
        qbe.Operation__c = 'update';
        qbe.Realm_Id__c = re.Realm_Id__c;
        test.startTest();
        Test.setMock(HttpCalloutMock.class, new QB_MockCreditMemoEventCallout(wo.Name));
        insert qbe;
        test.stopTest();
    }


    @isTest
    public static void TestQB_Entity_triggerCMVoid(){
        WorkOrder__c wo = [select name from WorkOrder__c limit 1];
        Realm_Id__mdt re = [select Realm_Id__c from Realm_Id__mdt limit 1];
        QB_Entity__c qbe = new QB_Entity__c();
        qbe.QB_Id__c = '2';
        qbe.Last_Updated__c = '2019-10-06T22:06:49.000Z';
        qbe.Transaction_Name__c = 'creditmemo';
        qbe.Operation__c = 'void';
        qbe.Realm_Id__c = re.Realm_Id__c;
        test.startTest();
        Test.setMock(HttpCalloutMock.class, new QB_MockCreditMemoEventCallout(wo.Name));
        insert qbe;
        test.stopTest();
    }
    
    @isTest
    public static void TestQB_Entity_trigger2(){
        WorkOrder__c wo = [select name from WorkOrder__c limit 1];
        WorkOrder_Transaction__c wot = new WorkOrder_Transaction__c();
        wot.Amount__c = 10;
        wot.Job__c = wo.Id;
        wot.Transaction_Date__c = Date.today();
        wot.Transaction_Type__c = 'Invoice';   
        wot.Source_Reference__c = '1037';
        wot.Tax_Amount__c = 10;
        insert wot;
        Realm_Id__mdt re = [select Realm_Id__c from Realm_Id__mdt limit 1];
        QB_Entity__c qbe2 = new QB_Entity__c();
        qbe2.QB_Id__c = '2';
        qbe2.Last_Updated__c = '2019-10-06T22:06:49.000Z';
        qbe2.Transaction_Name__c = 'invoice';
        qbe2.Operation__c = 'update';
        qbe2.Realm_Id__c = re.Realm_Id__c;
        test.startTest();
        Test.setMock(HttpCalloutMock.class, new QB_MockInvoiceEventCallout(wo.Name));
        insert qbe2;
        test.stopTest();
        QB_Entity__c qbe3 = new QB_Entity__c();
        qbe3.QB_Id__c = '2';
        qbe3.Last_Updated__c = '2019-10-06T22:06:49.000Z';
        qbe3.Transaction_Name__c = 'invoice';
        qbe3.Operation__c = 'update';
        qbe3.Realm_Id__c = re.Realm_Id__c;
        insert qbe3;
    }

    @isTest
    public static void TestQB_Entity_trigger2CM(){
        WorkOrder__c wo = [select name from WorkOrder__c limit 1];
        WorkOrder_Transaction__c wot = new WorkOrder_Transaction__c();
        wot.Amount__c = 10;
        wot.Job__c = wo.Id;
        wot.Transaction_Date__c = Date.today();
        wot.Transaction_Type__c = 'Credit Memo';   
        wot.Source_Reference__c = '1037';
        wot.Tax_Amount__c = 10;
        insert wot;
        Realm_Id__mdt re = [select Realm_Id__c from Realm_Id__mdt limit 1];
        QB_Entity__c qbe2 = new QB_Entity__c();
        qbe2.QB_Id__c = '2';
        qbe2.Last_Updated__c = '2019-10-06T22:06:49.000Z';
        qbe2.Transaction_Name__c = 'creditmemo';
        qbe2.Operation__c = 'update';
        qbe2.Realm_Id__c = re.Realm_Id__c;
        test.startTest();
        Test.setMock(HttpCalloutMock.class, new QB_MockCreditMemoEventCallout(wo.Name));
        insert qbe2;
        test.stopTest();
        QB_Entity__c qbe3 = new QB_Entity__c();
        qbe3.QB_Id__c = '2';
        qbe3.Last_Updated__c = '2019-10-06T22:06:49.000Z';
        qbe3.Transaction_Name__c = 'creditmemo';
        qbe3.Operation__c = 'update';
        qbe3.Realm_Id__c = re.Realm_Id__c;
        insert qbe3;
    }
    
    @isTest
    public static void TestQB_Entity_trigger3(){
        WorkOrder__c wo = [select name from WorkOrder__c limit 1];
        Realm_Id__mdt re = [select Realm_Id__c from Realm_Id__mdt limit 1];
        QB_Entity__c qbe = new QB_Entity__c();
        qbe.QB_Id__c = '2';
        qbe.Last_Updated__c = '2019-10-06T22:06:49.000Z';
        qbe.Transaction_Name__c = 'bill';
        qbe.Operation__c = 'create';
        qbe.Realm_Id__c = re.Realm_Id__c;
        test.startTest();
        Test.setMock(HttpCalloutMock.class, new QB_MockBillEventCallout(wo.Name));
        insert qbe;
        test.stopTest();
    }
    
    @isTest
    public static void TestQB_Entity_trigger4(){
        WorkOrder__c wo = [select name from WorkOrder__c limit 1];
        WorkOrder_Transaction__c wot = new WorkOrder_Transaction__c();
        wot.Amount__c = 10;
        wot.Job__c = wo.Id;
        wot.Transaction_Date__c = Date.today();
        wot.Transaction_Type__c = 'Invoice';   
        wot.Source_Reference__c = '1037';
        wot.Tax_Amount__c = 10;
        insert wot;
        Realm_Id__mdt re = [select Realm_Id__c from Realm_Id__mdt limit 1];
        QB_Entity__c qbe2 = new QB_Entity__c();
        qbe2.QB_Id__c = '2';
        qbe2.Last_Updated__c = '2019-10-06T22:06:49.000Z';
        qbe2.Transaction_Name__c = 'invoice';
        qbe2.Operation__c = 'update';
        qbe2.Realm_Id__c = re.Realm_Id__c;
        test.startTest();
        Test.setMock(HttpCalloutMock.class, new QB_MockInvoiceEventCallout(wo.Name));
        insert qbe2;
        test.stopTest();
        QB_Entity__c qbe3 = new QB_Entity__c();
        qbe3.QB_Id__c = '212';
        qbe3.Last_Updated__c = '2019-10-06T22:06:49.000Z';
        qbe3.Transaction_Name__c = 'payment';
        qbe3.Operation__c = 'create';
        qbe3.Realm_Id__c = re.Realm_Id__c;
        Test.setMock(HttpCalloutMock.class, new QB_MockPaymentEventCallout(wo.Name));
        //insert qbe3;
    }
    
    @isTest
    public static void TestQB_Entity_trigger5(){
        WorkOrder__c wo = [select name from WorkOrder__c limit 1];
        WorkOrder_Transaction__c wot = new WorkOrder_Transaction__c();
        wot.Amount__c = 10;
        wot.Job__c = wo.Id;
        wot.Transaction_Date__c = Date.today();
        wot.Transaction_Type__c = 'Invoice';   
        wot.Source_Reference__c = '1037';
        wot.Tax_Amount__c = 10;
        insert wot;
        Realm_Id__mdt re = [select Realm_Id__c from Realm_Id__mdt limit 1];
        QB_Entity__c qbe2 = new QB_Entity__c();
        qbe2.QB_Id__c = '2';
        qbe2.Last_Updated__c = '2019-10-06T22:06:49.000Z';
        qbe2.Transaction_Name__c = 'invoice';
        qbe2.Operation__c = 'update';
        qbe2.Realm_Id__c = re.Realm_Id__c;
        test.startTest();
        Test.setMock(HttpCalloutMock.class, new QB_MockInvoiceEventCallout(wo.Name));
        insert qbe2;
        test.stopTest();
        QB_Entity__c qbe3 = new QB_Entity__c();
        qbe3.QB_Id__c = '2';
        qbe3.Last_Updated__c = '2019-10-06T22:06:49.000Z';
        qbe3.Transaction_Name__c = 'invoice';
        qbe3.Operation__c = 'void';
        qbe3.Realm_Id__c = re.Realm_Id__c;
        insert qbe3;
    }

    @isTest
    public static void TestQB_Entity_trigger5CMVoid(){
        WorkOrder__c wo = [select name from WorkOrder__c limit 1];
        WorkOrder_Transaction__c wot = new WorkOrder_Transaction__c();
        wot.Amount__c = 10;
        wot.Job__c = wo.Id;
        wot.Transaction_Date__c = Date.today();
        wot.Transaction_Type__c = 'Credit Memo';   
        wot.Source_Reference__c = '1037';
        wot.Tax_Amount__c = 10;
        insert wot;
        Realm_Id__mdt re = [select Realm_Id__c from Realm_Id__mdt limit 1];
        QB_Entity__c qbe2 = new QB_Entity__c();
        qbe2.QB_Id__c = '2';
        qbe2.Last_Updated__c = '2019-10-06T22:06:49.000Z';
        qbe2.Transaction_Name__c = 'creditmemo';
        qbe2.Operation__c = 'update';
        qbe2.Realm_Id__c = re.Realm_Id__c;
        test.startTest();
        Test.setMock(HttpCalloutMock.class, new QB_MockCreditMemoEventCallout(wo.Name));
        insert qbe2;
        test.stopTest();
        QB_Entity__c qbe3 = new QB_Entity__c();
        qbe3.QB_Id__c = '2';
        qbe3.Last_Updated__c = '2019-10-06T22:06:49.000Z';
        qbe3.Transaction_Name__c = 'creditmemo';
        qbe3.Operation__c = 'void';
        qbe3.Realm_Id__c = re.Realm_Id__c;
        insert qbe3;
    }
    
     @isTest
    public static void TestQB_Entity_trigger6(){
        WorkOrder__c wo = [select name from WorkOrder__c limit 1];
        WorkOrder_Transaction__c wot = new WorkOrder_Transaction__c();
        wot.Amount__c = 10;
        wot.Job__c = wo.Id;
        wot.Transaction_Date__c = Date.today();
        wot.Transaction_Type__c = 'Invoice';   
        wot.Source_Reference__c = '1037';
        wot.Tax_Amount__c = 10;
        insert wot;
        Realm_Id__mdt re = [select Realm_Id__c from Realm_Id__mdt limit 1];
        QB_Entity__c qbe2 = new QB_Entity__c();
        qbe2.QB_Id__c = '2';
        qbe2.Last_Updated__c = '2019-10-06T22:06:49.000Z';
        qbe2.Transaction_Name__c = 'invoice';
        qbe2.Operation__c = 'update';
        qbe2.Realm_Id__c = re.Realm_Id__c;
        test.startTest();
        Test.setMock(HttpCalloutMock.class, new QB_MockInvoiceEventCallout(wo.Name));
        insert qbe2;
        test.stopTest();
        QB_Entity__c qbe3 = new QB_Entity__c();
        qbe3.QB_Id__c = '2';
        qbe3.Last_Updated__c = '2019-10-06T22:06:49.000Z';
        qbe3.Transaction_Name__c = 'invoice';
        qbe3.Operation__c = 'delete';
        qbe3.Realm_Id__c = re.Realm_Id__c;
        insert qbe3;
    }
    
    @isTest
    public static void TestQB_Entity_trigger7(){
        WorkOrder__c wo = [select name from WorkOrder__c limit 1];
        Realm_Id__mdt re = [select Realm_Id__c from Realm_Id__mdt limit 1];
        QB_Entity__c qbe = new QB_Entity__c();
        qbe.QB_Id__c = '2';
        qbe.Last_Updated__c = '2019-10-06T22:06:49.000Z';
        qbe.Transaction_Name__c = 'bill';
        qbe.Operation__c = 'create';
        qbe.Realm_Id__c = re.Realm_Id__c;
        test.startTest();
        Test.setMock(HttpCalloutMock.class, new QB_MockBillEventCallout(wo.Name));
        insert qbe;
        test.stopTest();
        QB_Entity__c qbe2 = new QB_Entity__c();
        qbe2.QB_Id__c = '2';
        qbe2.Last_Updated__c = '2019-10-06T22:06:49.000Z';
        qbe2.Transaction_Name__c = 'bill';
        qbe2.Operation__c = 'delete';
        qbe2.Realm_Id__c = re.Realm_Id__c;
        insert qbe2;
    }

    @isTest
    public static void TestQB_Entity_PurchaseCreate(){
        WorkOrder__c wo = [select name from WorkOrder__c limit 1];
        Realm_Id__mdt re = [select Realm_Id__c from Realm_Id__mdt limit 1];
        QB_Entity__c qbe = new QB_Entity__c();
        qbe.QB_Id__c = '2';
        qbe.Last_Updated__c = '2019-10-06T22:06:49.000Z';
        qbe.Transaction_Name__c = 'purchase';
        qbe.Operation__c = 'create';
        qbe.Realm_Id__c = re.Realm_Id__c;
        test.startTest();
        Test.setMock(HttpCalloutMock.class, new QB_MockPurchaseEventCallout(wo.Name));
        insert qbe;
        test.stopTest();
        QB_Entity__c qbe2 = new QB_Entity__c();
        qbe2.QB_Id__c = '2';
        qbe2.Last_Updated__c = '2019-10-06T22:06:49.000Z';
        qbe2.Transaction_Name__c = 'purchase';
        qbe2.Operation__c = 'delete';
        qbe2.Realm_Id__c = re.Realm_Id__c;
        insert qbe2;
    }
    
    @isTest
    public static void TestQB_Entity_trigger8(){
        WorkOrder__c wo = [select name from WorkOrder__c limit 1];
        Realm_Id__mdt re = [select Realm_Id__c from Realm_Id__mdt limit 1];
        QB_Entity__c qbe = new QB_Entity__c();
        qbe.QB_Id__c = '2';
        qbe.Last_Updated__c = '2019-10-06T22:06:49.000Z';
        qbe.Transaction_Name__c = 'bill';
        qbe.Operation__c = 'create';
        qbe.Realm_Id__c = re.Realm_Id__c;
        test.startTest();
        Test.setMock(HttpCalloutMock.class, new QB_MockBillEventCallout(wo.Name));
        insert qbe;
        test.stopTest();
        QB_Entity__c qbe2 = new QB_Entity__c();
        qbe2.QB_Id__c = '2';
        qbe2.Last_Updated__c = '2019-10-06T22:06:49.000Z';
        qbe2.Transaction_Name__c = 'bill';
        qbe2.Operation__c = 'update';
        qbe2.Realm_Id__c = re.Realm_Id__c;
        insert qbe2;
    }

    @isTest
    public static void TestQB_Entity_Purchase2(){
        WorkOrder__c wo = [select name from WorkOrder__c limit 1];
        Realm_Id__mdt re = [select Realm_Id__c from Realm_Id__mdt limit 1];
        QB_Entity__c qbe = new QB_Entity__c();
        qbe.QB_Id__c = '2';
        qbe.Last_Updated__c = '2019-10-06T22:06:49.000Z';
        qbe.Transaction_Name__c = 'purchase';
        qbe.Operation__c = 'create';
        qbe.Realm_Id__c = re.Realm_Id__c;
        test.startTest();
        Test.setMock(HttpCalloutMock.class, new QB_MockPurchaseEventCallout(wo.Name));
        insert qbe;
        test.stopTest();
        QB_Entity__c qbe2 = new QB_Entity__c();
        qbe2.QB_Id__c = '2';
        qbe2.Last_Updated__c = '2019-10-06T22:06:49.000Z';
        qbe2.Transaction_Name__c = 'purchase';
        qbe2.Operation__c = 'update';
        qbe2.Realm_Id__c = re.Realm_Id__c;
        insert qbe2;
    }

    @isTest
    public static void TestQB_Entity_trigger9(){
        WorkOrder__c wo = [select name from WorkOrder__c limit 1];
        Realm_Id__mdt re = [select Realm_Id__c from Realm_Id__mdt limit 1];
        QB_Entity__c qbe = new QB_Entity__c();
        qbe.QB_Id__c = '2';
        qbe.Last_Updated__c = '2019-10-06T22:06:49.000Z';
        qbe.Transaction_Name__c = 'journalentry';
        qbe.Operation__c = 'create';
        qbe.Realm_Id__c = re.Realm_Id__c;
        test.startTest();
        Test.setMock(HttpCalloutMock.class, new QB_MockJournalEntry(wo.Name));
        insert qbe;
        test.stopTest();
        QB_Entity__c qbe2 = new QB_Entity__c();
        qbe2.QB_Id__c = '2';
        qbe2.Last_Updated__c = '2019-10-06T22:06:49.000Z';
        qbe2.Transaction_Name__c = 'journalentry';
        qbe2.Operation__c = 'delete';
        qbe2.Realm_Id__c = re.Realm_Id__c;
        insert qbe2;
    }
    
    @isTest
    public static void TestQB_Entity_trigger10(){
        WorkOrder__c wo = [select name from WorkOrder__c limit 1];
        Realm_Id__mdt re = [select Realm_Id__c from Realm_Id__mdt limit 1];
        QB_Entity__c qbe = new QB_Entity__c();
        qbe.QB_Id__c = '2';
        qbe.Last_Updated__c = '2019-10-06T22:06:49.000Z';
        qbe.Transaction_Name__c = 'journalentry';
        qbe.Operation__c = 'create';
        qbe.Realm_Id__c = re.Realm_Id__c;
        test.startTest();
        Test.setMock(HttpCalloutMock.class, new QB_MockJournalEntry(wo.Name));
        insert qbe;
        test.stopTest();
        QB_Entity__c qbe2 = new QB_Entity__c();
        qbe2.QB_Id__c = '2';
        qbe2.Last_Updated__c = '2019-10-06T22:06:49.000Z';
        qbe2.Transaction_Name__c = 'journalentry';
        qbe2.Operation__c = 'update';
        qbe2.Realm_Id__c = re.Realm_Id__c;
        insert qbe2;
    }

}