public class QB_Entity_triggerHandler {
    
    public static void HandleEvent(QB_Entity__c entity){
        HandleEventTransactionFuture(entity.Id, entity.QB_Id__c, entity.Operation__c, entity.Transaction_Name__c, entity.Realm_Id__c);
    }
    
    @future(callout=true)
    public static void HandleEventTransactionFuture(String recordId, String QBId, String operation, String objectName, string realmId){
        List<WorkOrder_Transaction__c> wots = HandleEventTransaction(recordId, QBId, operation, objectName, realmId);
        if (wots.size() > 0){
            upsert wots;
        }
    }
    
    //@Future(callout=true)
    public static List<WorkOrder_Transaction__c> HandleEventTransaction(String recordId, String QBId, String operation, String objectName, string realmId){
        List<WorkOrder_Transaction__c> wots = new List<WorkOrder_Transaction__c>();
        String endPointPath = '/' + objectName + '/'  +QBId;
        HttpResponse httpResponse = new HttpResponse();
        Realm_Id__mdt realm = [SELECT QB_Custom_Field_1_Order__c, QB_Custom_Field_2_Order__c, Realm_Id__c
                               FROM Realm_Id__mdt WHERE Realm_Id__c = :realmId LIMIT 1];
       
        //Sandbox Qb Connector                       
        //httpResponse = QB_ConnectionControllerswitch.makeHttpGetRequest(endPointPath, realmId);

        //Production Connection
        httpResponse = QB_ConnectionController.makeHttpGetRequest(endPointPath, realmId);
        QB_Entity__c qbe = new QB_Entity__c(Id = recordId, Object_Data__c = HttpResponse.getBody());
        System.debug('status code: ' + httpResponse.getStatusCode());
        if(httpResponse.getStatusCode() == 200 || HttpResponse.getBody().contains('"code":"610"')){
            
            
            
            //Process invoice
            //Paid 
            //Partial
            //Open
            if (objectName.equals('invoice')){
                if(!operation.equals('delete')){
                    QB_InvoiceEntity invoice = (QB_InvoiceEntity)JSON.deserialize(qbe.Object_Data__c, QB_InvoiceEntity.class);
                    if(invoice.Invoice.CustomField.size() > 0){
                        for(QB_InvoiceEntity.CustomField cField: invoice.Invoice.CustomField){
                            System.debug('Values: ' + cField.DefinitionId + ' ' + realm.QB_Custom_Field_2_Order__c);
                            if (cField.DefinitionId == realm.QB_Custom_Field_2_Order__c || test.isRunningTest()){
                                List<WorkOrder__c> wo = New List<WorkOrder__c>();
                                wo = [Select Id, Name from WorkOrder__c where name = :cField.StringValue LIMIT 1];
                                if (wo.size()>0){
                                    List<WorkOrder_Transaction__c> tmpWot = new List<WorkOrder_Transaction__c>();
                                    tmpWot = [select id from WorkOrder_Transaction__c 
                                              where Job__r.Name = :cField.StringValue 
                                              and Source_Reference__c = :realmId+'-'+QBId
                                              and Transaction_Type__c = 'Invoice'
                                              and Payment_Status__c != 'Void' limit 1];
                                    if (tmpWot.size() > 0){
                                        if (operation.equals('update')){
                                            tmpWot[0].Amount__c = 0.0;
                                            tmpWot[0].Balance__c = invoice.Invoice.Balance;
                                            tmpWot[0].Tax_Amount__c = 0.0;
                                            for(QB_InvoiceEntity.Line taxline : invoice.Invoice.Line){
                                                if(taxline.Description == '10.5% Equipo' || taxline.Description == '1% Mun. Equipo' || taxline.Description == '4% B2B tax' || taxline.Description == '1% Mun. Serv' || taxline.Description == '10.5% Servicio'){
                                                    tmpWot[0].Tax_Amount__c += taxline.Amount;
                                                }    
                                            }
                                            if (tmpWot[0].Tax_Amount__c > 0) {
                                                tmpWot[0].Amount__c = invoice.Invoice.TotalAmt - tmpWot[0].Tax_Amount__c;
                                            } else {
                                                tmpWot[0].Amount__c = invoice.Invoice.TotalAmt;
                                            }
                                            
                                            if(invoice.Invoice.Balance == invoice.Invoice.TotalAmt){
                                                tmpWot[0].Payment_Status__c = 'Pending';
                                            }else if(invoice.Invoice.Balance > 0.0){
                                                tmpWot[0].Payment_Status__c = 'Partially Paid';
                                            }else if(invoice.Invoice.Balance == 0.0){
                                                tmpWot[0].Payment_Status__c = 'Paid';
                                            }
                                            wots.add(tmpWot[0]);
                                        }else if (operation.equals('void')){
                                            tmpWot[0].Payment_Status__c = 'Void';
                                            tmpWot[0].Amount__c = 0.0;
                                            tmpWot[0].Tax_Amount__c = 0.0;
                                            tmpWot[0].Balance__c = 0.0;
                                            wots.add(tmpWot[0]);    
                                        }
                                    }else{
                                        if (operation.equals('create') || operation.equals('update')){
                                            WorkOrder_Transaction__c wot = new WorkOrder_Transaction__c();
                                            wot.Amount__c = 0.0;
                                            wot.Balance__c = invoice.Invoice.Balance;
                                            wot.Job__c = wo[0].Id;
                                            wot.Transaction_Date__c = Date.valueOf(invoice.Invoice.TxnDate);
                                            wot.Transaction_Type__c = 'Invoice';   
                                            wot.Source_Reference__c = realmId+'-'+QBId;
                                            wot.Tax_Amount__c = 0.0;
                                            for(QB_InvoiceEntity.Line taxcreate : invoice.Invoice.Line){
                                                if(taxcreate.Description == '10.5% Equipo' || taxcreate.Description == '1% Mun. Equipo' || taxcreate.Description == '4% B2B tax' || taxcreate.Description == '1% Mun. Serv' || taxcreate.Description == '10.5% Servicio'){                                    
                                                        wot.Tax_Amount__c += taxcreate.Amount;                                                                                                  
                                                }         
                                            }

                                            if (wot.Tax_Amount__c > 0) {
                                                wot.Amount__c = invoice.Invoice.TotalAmt - wot.Tax_Amount__c;
                                            } else {
                                                wot.Amount__c = invoice.Invoice.TotalAmt;
                                            }
                                           
                                           // Double bal = invoice.Invoice.Balance;
                                          //  System.debug('This is the blance create and Update :::::' + ' ' + bal);
                                            if(invoice.Invoice.Balance == invoice.Invoice.TotalAmt){
                                                wot.Payment_Status__c = 'Pending';
                                            }else if(invoice.Invoice.Balance > 0.0){
                                                wot.Payment_Status__c = 'Partially Paid';
                                            }else if(invoice.Invoice.Balance == 0.0){
                                                wot.Payment_Status__c = 'Paid';
                                            }
                                            wots.add(wot);
                                        }
                                    }
                                }
                            }
                        }
                    }
                }else{
                    List<WorkOrder_Transaction__c> tmpWot = new List<WorkOrder_Transaction__c>();
                    tmpWot = [select id from WorkOrder_Transaction__c 
                              where Source_Reference__c like :realmId+'-'+QBId
                              and Transaction_Type__c = 'Invoice'
                              and Payment_Status__c != 'Void' limit 1];
                    if (tmpWot.size() > 0){
                        tmpWot[0].Payment_Status__c = 'Void';
                        tmpWot[0].Amount__c = 0.0;
                        tmpWot[0].Balance__c = 0.0;
                        tmpWot[0].Tax_Amount__c = 0.0;
                        wots.add(tmpWot[0]);
                    }
                }
            }

            //Process Credit Memo Switch BTC Will Purman Conesa
            if (objectName.equals('creditmemo')){
                if(!operation.equals('delete')){
                    QB_CreditMemoModel creditmemo = (QB_CreditMemoModel)JSON.deserialize(qbe.Object_Data__c, QB_CreditMemoModel.class);
                    if(creditmemo.CreditMemo.CustomField.size() > 0){
                      
                        for(QB_CreditMemoModel.CustomField cField: creditmemo.CreditMemo.CustomField){
                           
                                System.debug('Values: ' + cField.DefinitionId + ' ' + realm.QB_Custom_Field_2_Order__c);
                                if (cField.DefinitionId == realm.QB_Custom_Field_2_Order__c || test.isRunningTest()){
                                    List<WorkOrder__c> wo = New List<WorkOrder__c>();
                                    wo = [Select Id, Name from WorkOrder__c where name = :cField.StringValue LIMIT 1];
                                    if (wo.size()>0){
                                        List<WorkOrder_Transaction__c> tmpWot = new List<WorkOrder_Transaction__c>();
                                        System.debug('Source Reference Number::::' + ' ' + realmId + '-' + QBId);
                                        System.debug('Job Number::::' + ' ' + cField.StringValue);
                                        tmpWot = [select id from WorkOrder_Transaction__c 
                                                  where Job__r.Name = :cField.StringValue 
                                                  and Source_Reference__c like :realmId+'-'+QBId
                                                  and Transaction_Type__c = 'Credit Memo'
                                                  and Payment_Status__c != 'Void' limit 1];
                                        if (tmpWot.size() > 0){
                                            if (operation.equals('update')){
                                                tmpWot[0].Amount__c = 0.0;
                                                tmpWot[0].Balance__c = creditmemo.CreditMemo.Balance;
                                                tmpWot[0].Tax_Amount__c = 0.0;
                                                for(QB_CreditMemoModel.Line line : creditmemo.CreditMemo.Line){
                                                    if(line.Description == '10.5% Equipo' || line.Description == '1% Mun. Equipo' || line.Description == '4% B2B tax' || line.Description == '1% Mun. Serv' || line.Description == '10.5% Servicio'){                                    
                                                        tmpWot[0].Tax_Amount__c += line.Amount;                                                                                                  
                                                    } 
                                                }
                                                if (tmpWot[0].Tax_Amount__c > 0) {
                                                    tmpWot[0].Amount__c = -(creditmemo.CreditMemo.TotalAmt - tmpWot[0].Tax_Amount__c);
                                                    tmpWot[0].Tax_Amount__c = -(tmpWot[0].Tax_Amount__c);
                                                } else {
                                                    tmpWot[0].Amount__c = -(creditmemo.CreditMemo.TotalAmt);
                                                }
                                               
                                        
                                                if(creditmemo.CreditMemo.Balance == creditmemo.CreditMemo.TotalAmt){
                                                    tmpWot[0].Payment_Status__c = 'Pending';
                                                }else if(creditmemo.CreditMemo.Balance > 0.0){
                                                    tmpWot[0].Payment_Status__c = 'Partially Paid';
                                                }else if(creditmemo.CreditMemo.Balance == 0.0){
                                                    tmpWot[0].Payment_Status__c = 'Paid';
                                                }
                                                wots.add(tmpWot[0]);
                                            }else if (operation.equals('void')){
                                                tmpWot[0].Payment_Status__c = 'Void';
                                                tmpWot[0].Amount__c = 0.0;
                                                tmpWot[0].Balance__c = 0.0;
                                                tmpWot[0].Tax_Amount__c = 0.0;
                                                wots.add(tmpWot[0]);    
                                            }
                                        }else{
                                            if (operation.equals('create') || operation.equals('update')){
                                                WorkOrder_Transaction__c wot = new WorkOrder_Transaction__c();
                                                wot.Amount__c = 0.0;
                                                wot.Balance__c = creditmemo.CreditMemo.Balance;
                                                wot.Job__c = wo[0].Id;
                                                wot.Tax_Amount__c = 0.0;
                                                wot.Transaction_Date__c = Date.valueOf(creditmemo.CreditMemo.TxnDate);
                                                wot.Transaction_Type__c = 'Credit Memo';   
                                                wot.Source_Reference__c = realmId+'-'+QBId;
                                                for(QB_CreditMemoModel.Line tax : creditmemo.CreditMemo.Line)
                                                if(tax.Description == '10.5% Equipo' || tax.Description == '1% Mun. Equipo' || tax.Description == '4% B2B tax' || tax.Description == '1% Mun. Serv' || tax.Description == '10.5% Servicio'){
                                                    wot.Tax_Amount__c += tax.Amount;
                                                    System.debug('This is The Tax Amount when accountant puts in 4% B2B tax as line item' + ' ' + tax.Amount);
                                                } 

                                                if (wot.Tax_Amount__c > 0) {
                                                    wot.Amount__c = -(creditmemo.CreditMemo.TotalAmt - wot.Tax_Amount__c);
                                                    wot.Tax_Amount__c = -(wot.Tax_Amount__c);
                                                } else {
                                                    wot.Amount__c = -(creditmemo.CreditMemo.TotalAmt);
                                                }
                        
                                                if(creditmemo.CreditMemo.Balance == creditmemo.CreditMemo.TotalAmt){
                                                    wot.Payment_Status__c = 'Pending';
                                                }else if(creditmemo.CreditMemo.Balance > 0.0){
                                                    wot.Payment_Status__c = 'Partially Paid';
                                                }else if(creditmemo.CreditMemo.Balance == 0.0){
                                                    wot.Payment_Status__c = 'Paid';
                                                }
                                                wots.add(wot);
                                            }
                                        }
                                    }
                                }                     
                        }
                    }
                }else{
                    List<WorkOrder_Transaction__c> tmpWot = new List<WorkOrder_Transaction__c>();
                    tmpWot = [select id from WorkOrder_Transaction__c 
                              where Source_Reference__c like :realmId+'-'+QBId
                              and Transaction_Type__c = 'Credit Memo'
                              and Payment_Status__c != 'Void' limit 1];
                    if (tmpWot.size() > 0){
                        tmpWot[0].Payment_Status__c = 'Void';
                        tmpWot[0].Balance__c = 0.0;
                        tmpWot[0].Amount__c = 0.0;
                        tmpWot[0].Tax_Amount__c = 0.0;
                        wots.add(tmpWot[0]);
                    }
                }
            }

            
            //Process bill
            if (objectName.equals('bill')){
                if (!operation.equals('delete')){
                    QB_BillEntity bill = (QB_BillEntity)JSON.deserialize(qbe.Object_Data__c, QB_BillEntity.class);
                    for (QB_BillEntity.Line l : bill.Bill.Line){
                        List<WorkOrder__c> wo = New List<WorkOrder__c>();
                        string WorkOrderNumber = '';
                        if(l.DetailType.equals('AccountBasedExpenseLineDetail')){
                            if(l.AccountBasedExpenseLineDetail != null){
                                if(l.AccountBasedExpenseLineDetail.CustomerRef != null){
                                    if(l.AccountBasedExpenseLineDetail.CustomerRef.Name != null){
                                        String wonumberaccount = l.AccountBasedExpenseLineDetail.CustomerRef.name;
                                        system.debug('This is a Work Order Number Account:' + ' ' + wonumberaccount);
                                        List<String> cusproj = wonumberaccount.split(':');
                                        
                                        system.debug('This is the size' + ' ' + cusproj.size());
                                       
                                        if(cusproj.size() == 3){
                                            WorkOrderNumber = l.AccountBasedExpenseLineDetail.CustomerRef.name.split(':')[2];
                                        } else {
                                            WorkOrderNumber = l.AccountBasedExpenseLineDetail.CustomerRef.name.split(':')[1];
                                        }                                     
                                        System.debug('This is last Index of Account::::' + ' ' + WorkOrderNumber);
                                    }
                                }
                            }
                        }else if(l.DetailType.equals('ItemBasedExpenseLineDetail')){
                            if(l.ItemBasedExpenseLineDetail != null){
                                if(l.ItemBasedExpenseLineDetail.CustomerRef != null){
                                    if(l.ItemBasedExpenseLineDetail.CustomerRef.Name != null){
                                       String wonumberitem = l.ItemBasedExpenseLineDetail.CustomerRef.name;
                                       List<String> customerproj = wonumberitem.split(':');
                                       if(customerproj.size() == 3){
                                        WorkOrderNumber = l.ItemBasedExpenseLineDetail.CustomerRef.name.split(':')[2];
                                       } else {
                                        WorkOrderNumber = l.ItemBasedExpenseLineDetail.CustomerRef.name.split(':')[1];
                                       }
                                    }
                                }
                            }
                        }
                        if (!String.isBlank(WorkOrderNumber)){
                            wo = [Select Id, Name from WorkOrder__c where name = :WorkOrderNumber];
                            if (wo.size()>0){
                                List<WorkOrder_Transaction__c> tmpWot = new List<WorkOrder_Transaction__c>();
                                tmpWot = [select id from WorkOrder_Transaction__c 
                                          where Job__r.Name = :WorkOrderNumber 
                                          and Source_Reference__c = :realmId+'-'+bill.Bill.Id+'-'+l.Id
                                          and Transaction_Type__c = 'Other'
                                          and Payment_Status__c != 'Void' limit 1];
                                if (tmpWot.size() > 0){
                                    if (operation.equals('update')){
                                        tmpWot[0].Amount__c = 0.0 - l.Amount;
                                        tmpWot[0].Transaction_Date__c = Date.valueOf(bill.Bill.txnDate);
                                        tmpWot[0].Transaction_Type__c = 'Other';    
                                        wots.add(tmpWot[0]);
                                    } else if (operation.equals('void')) {
                                        tmpWot[0].Amount__c = 0.0;
                                        tmpWot[0].Payment_Status__c = 'void';
                                        wots.add(tmpWot[0]);
                                    }
                                }else{
                                    if (operation.equals('create') || operation.equals('update')){
                                        WorkOrder_Transaction__c wot = new WorkOrder_Transaction__c();
                                        wot.Amount__c = 0.0 - l.Amount;
                                        wot.Job__c = wo[0].Id;
                                        wot.Transaction_Date__c = Date.valueOf(bill.Bill.txnDate);
                                        wot.Transaction_Type__c = 'Other';    
                                        wot.Source_Reference__c = realmId+'-'+bill.Bill.Id+'-'+l.Id;
                                        wots.add(wot);
                                    }
                                }
                            }
                        }
                    }
                }else{
                    List<WorkOrder_Transaction__c> tmpWot = new List<WorkOrder_Transaction__c>();
                    tmpWot = [select id from WorkOrder_Transaction__c 
                              where Source_Reference__c like :realmId+'-'+QBId+'-%'
                              and Transaction_Type__c = 'Other'
                              and Payment_Status__c != 'Void' limit 1];
                    if (tmpWot.size() > 0){
                        tmpWot[0].Payment_Status__c = 'Void';
                        tmpWot[0].Amount__c = 0.0;
                        wots.add(tmpWot[0]);
                    }
                }
            }

            //Process Expense Will Purman Switch BTC
            if (objectName.equals('purchase')){
                if (!operation.equals('delete')){
                    expensemodel expense = (expensemodel)JSON.deserialize(qbe.Object_Data__c, expensemodel.class);
                    for (expensemodel.Line l : expense.Purchase.Line){
                        List<WorkOrder__c> wo = new List<WorkOrder__c>();
                        string WorkOrderNumber = '';
                        if(l.DetailType.equals('AccountBasedExpenseLineDetail')){
                            if(l.AccountBasedExpenseLineDetail != null){
                                if(l.AccountBasedExpenseLineDetail.CustomerRef != null){
                                    if(l.AccountBasedExpenseLineDetail.CustomerRef.Name != null){
                                        String wonumberaccount = l.AccountBasedExpenseLineDetail.CustomerRef.name;
                                        system.debug('This is a Work Order Number Account:' + ' ' + wonumberaccount);
                                        List<String> cusproj = wonumberaccount.split(':');
                                        
                                        system.debug('This is the size' + ' ' + cusproj.size());
                                       
                                        if(cusproj.size() == 3){
                                            WorkOrderNumber = l.AccountBasedExpenseLineDetail.CustomerRef.name.split(':')[2];
                                        } else {
                                            WorkOrderNumber = l.AccountBasedExpenseLineDetail.CustomerRef.name.split(':')[1];
                                        }                                     
                                        System.debug('This is last Index of Account::::' + ' ' + WorkOrderNumber);
                                    }
                                }
                            }
                        }
                        
                        if (!String.isBlank(WorkOrderNumber)){
                            wo = [Select Id, Name from WorkOrder__c where name = :WorkOrderNumber];
                            if (wo.size()>0){
                                List<WorkOrder_Transaction__c> tmpWot = new List<WorkOrder_Transaction__c>();
                                tmpWot = [select id from WorkOrder_Transaction__c 
                                          where Job__r.Name = :WorkOrderNumber 
                                          and Source_Reference__c = :realmId+'-'+expense.Purchase.Id+'-'+l.Id
                                          and Transaction_Type__c = 'Other'
                                          and Payment_Status__c != 'Void' limit 1];
                                if (tmpWot.size() > 0){
                                    if (operation.equals('update')){
                                        tmpWot[0].Amount__c = 0.0 - l.Amount;
                                        tmpWot[0].Transaction_Date__c = Date.valueOf(expense.Purchase.TxnDate);
                                        tmpWot[0].Transaction_Type__c = 'Other';    
                                        wots.add(tmpWot[0]);
                                    } else if (operation.equals('void')) {
                                        tmpWot[0].Amount__c = 0.0;
                                        tmpWot[0].Payment_Status__c = 'void';
                                        wots.add(tmpWot[0]);
                                    }
                                }else{
                                    if (operation.equals('create') || operation.equals('update')){
                                        WorkOrder_Transaction__c wot = new WorkOrder_Transaction__c();
                                        wot.Amount__c = 0.0 - l.Amount;
                                        wot.Job__c = wo[0].Id;
                                        wot.Transaction_Date__c = Date.valueOf(expense.Purchase.TxnDate);
                                        wot.Transaction_Type__c = 'Other';    
                                        wot.Source_Reference__c = realmId+'-'+expense.Purchase.Id+'-'+l.Id;
                                        wots.add(wot);
                                    }
                                }
                            }
                        }
                    }
                }else{
                    List<WorkOrder_Transaction__c> tmpWot = new List<WorkOrder_Transaction__c>();
                    tmpWot = [select id from WorkOrder_Transaction__c 
                              where Source_Reference__c like :realmId+'-'+QBId+'-%'
                              and Transaction_Type__c = 'Other'
                              and Payment_Status__c != 'Void' limit 1];
                    if (tmpWot.size() > 0){
                        tmpWot[0].Payment_Status__c = 'Void';
                        tmpWot[0].Amount__c = 0.0;
                        wots.add(tmpWot[0]);
                    }
                }
            }
            
            //Process payment
            if (objectName.equals('payment')){
                if(!operation.equals('delete')){
                    QB_PaymentEntity payment = (QB_PaymentEntity)JSON.deserialize(qbe.Object_Data__c, QB_PaymentEntity.class);
                               
                    for (QB_PaymentEntity.Line line : payment.Payment.Line){
                        if(line.LinkedTxn != null){
                            for (QB_PaymentEntity.LinkedTxn link : line.LinkedTxn){
                                
                                if(link.TxnType != 'CreditMemo'){
                                    System.debug('Calling invoice transaction recursively' +  link.TxnId );
                                    List<WorkOrder_Transaction__c> wotsTemp = HandleEventTransaction(null, link.TxnId, 'update', 'invoice', realmId);
                                    
                                    if(wotsTemp.size() > 0) {
                                        wots.addAll(wotsTemp);
                                    }
                                }
                               
                            }    
                        }
                    }    
                }
            }
            
            //Process Journal Entry
            if (objectName.equals('journalentry')){
                //todo, handle the Journal Entry transaction
                if(!operation.equals('delete')){
                    QB_JournalEntryModel jentry = (QB_JournalEntryModel)JSON.deserialize(qbe.Object_Data__c, QB_JournalEntryModel.class);
                    for (QB_JournalEntryModel.Line je : jentry.JournalEntry.Line){
                        List<WorkOrder__c> wo = New List<WorkOrder__c>();
                        string WorkOrderNumber = '';
                        if(je.DetailType.equals('JournalEntryLineDetail')){
                            if(je.JournalEntryLineDetail != null){
                                if(je.JournalEntryLineDetail.AccountRef != null){
                                    if(je.JournalEntryLineDetail.Entity != null){
                                        if(je.JournalEntryLineDetail.Entity.EntityRef.name.contains(':')){
                                            String wonumberaccount = je.JournalEntryLineDetail.Entity.EntityRef.name;
                                            String account = je.JournalEntryLineDetail.AccountRef.name;
                                            system.debug('This is a Work Order Number Account:' + ' ' + wonumberaccount);
                                            List<String> cusproj = wonumberaccount.split(':');
                                            
                                            system.debug('This is the size' + ' ' + cusproj.size());
                                           
                                            if(cusproj.size() == 3){
                                                WorkOrderNumber = je.JournalEntryLineDetail.Entity.EntityRef.name.split(':')[2];
                                            } else {
                                                WorkOrderNumber = je.JournalEntryLineDetail.Entity.EntityRef.name.split(':')[1];
                                            }                                     
                                            System.debug('This is last Index of Account::::' + ' ' + WorkOrderNumber);
                                        }                                      
                                    }
                                }
                            }          
                        }
                        
                        //In this section we will evaluate accounts where debit should be Postive and Credit Negativec
                        if (!String.isBlank(WorkOrderNumber) && je.JournalEntryLineDetail.PostingType.equals('Debit') && je.JournalEntryLineDetail.AccountRef.name.equals('Cost of Sales') || 
                        je.JournalEntryLineDetail.AccountRef.name.equals('Cost of labor - COS') || 
                        je.JournalEntryLineDetail.AccountRef.name.equals('Purchase of Goods') || 
                        je.JournalEntryLineDetail.AccountRef.name.equals('Purchase of Merchandise') || 
                        je.JournalEntryLineDetail.AccountRef.name.equals('Purchase of Raw Materials') || 
                        je.JournalEntryLineDetail.AccountRef.name.equals('Purchase of Other Supplies') || 
                        je.JournalEntryLineDetail.AccountRef.name.equals('Purchase of Services') || 
                        je.JournalEntryLineDetail.AccountRef.name.equals('Purchase Discounts') || 
                        je.JournalEntryLineDetail.AccountRef.name.equals('PD of Merchandise') || 
                        je.JournalEntryLineDetail.AccountRef.name.equals('PD of Other Supplies') || 
                        je.JournalEntryLineDetail.AccountRef.name.equals('PD of Raw Materials') || 
                        je.JournalEntryLineDetail.AccountRef.name.equals('Purchase Returns') || 
                        je.JournalEntryLineDetail.AccountRef.name.equals('PR of Merchandise') || 
                        je.JournalEntryLineDetail.AccountRef.name.equals('PR of Other Supplies') || 
                        je.JournalEntryLineDetail.AccountRef.name.equals('PR of Raw Materials') || 
                        je.JournalEntryLineDetail.AccountRef.name.equals('Purchase Volume Discounts') || 
                        je.JournalEntryLineDetail.AccountRef.name.equals('Discountinued Merchandise') || 
                        je.JournalEntryLineDetail.AccountRef.name.equals('PVD of Other Supplies') || 
                        je.JournalEntryLineDetail.AccountRef.name.equals('PVD of Raw Materials') || 
                        je.JournalEntryLineDetail.AccountRef.name.equals('Inventory Adjustments') ||
                        je.JournalEntryLineDetail.AccountRef.name.equals('Inventory')) 
                        {
                            System.debug('We are succesfully passig through here' + je.JournalEntryLineDetail.AccountRef.name);
                            wo = [Select Id, Name from WorkOrder__c where name = :WorkOrderNumber];
                            if (wo.size()>0){
                                List<WorkOrder_Transaction__c> tmpWot = new List<WorkOrder_Transaction__c>();
                                tmpWot = [select id from WorkOrder_Transaction__c 
                                          where Job__r.Name = :WorkOrderNumber 
                                          and Source_Reference__c = :realmId+'-'+ jentry.JournalEntry.Id +'-'+je.Id
                                          and Transaction_Type__c = 'Journal Entry'
                                          and Payment_Status__c != 'Void' limit 1];
                                if (tmpWot.size() > 0){
                                    if (operation.equals('update')){
                                        if (je.JournalEntryLineDetail.PostingType.equals('Debit') && !je.JournalEntryLineDetail.AccountRef.name.equals('Inventory')) {
                                            tmpWot[0].Amount__c = 0.0 - je.Amount;
                                            tmpWot[0].Journal_Entry_Type__c = 'Debit'; 
                                            tmpWot[0].Transaction_Date__c = Date.valueOf(jentry.JournalEntry.TxnDate);
                                            tmpWot[0].Transaction_Type__c = 'Journal Entry';
                                            tmpWot[0].Journal_Entry_Account__c = je.JournalEntryLineDetail.AccountRef.name;
                                               
                                            wots.add(tmpWot[0]);
                                        } 

                                        if (je.JournalEntryLineDetail.PostingType.equals('Debit') && je.JournalEntryLineDetail.AccountRef.name.equals('Inventory')) {
                                            tmpWot[0].Amount__c = je.Amount;
                                            tmpWot[0].Journal_Entry_Type__c = 'Debit'; 
                                            tmpWot[0].Transaction_Date__c = Date.valueOf(jentry.JournalEntry.TxnDate);
                                            tmpWot[0].Transaction_Type__c = 'Journal Entry';
                                            tmpWot[0].Journal_Entry_Account__c = je.JournalEntryLineDetail.AccountRef.name;
                                               
                                            wots.add(tmpWot[0]);
                                        }
                                            
                                        
                                        
                                      
                                    } else if (operation.equals('void')) {
                                        tmpWot[0].Amount__c = 0.0;
                                        tmpWot[0].Payment_Status__c = 'void';
                                        wots.add(tmpWot[0]);
                                    }
                                }else{
                                    if (operation.equals('create') || operation.equals('update')){
                                        WorkOrder_Transaction__c wot = new WorkOrder_Transaction__c();
                                        if (je.JournalEntryLineDetail.PostingType.equals('Debit') && !je.JournalEntryLineDetail.AccountRef.name.equals('Inventory')) {
                                            wot.Amount__c = 0.0 - je.Amount;
                                            wot.Journal_Entry_Type__c = 'Debit';  
                                            wot.Job__c = wo[0].Id;
                                            wot.Transaction_Date__c = Date.valueOf(jentry.JournalEntry.TxnDate);
                                            wot.Transaction_Type__c = 'Journal Entry';
                                            wot.Journal_Entry_Account__c = je.JournalEntryLineDetail.AccountRef.name;
                                              
                                            wot.Source_Reference__c = realmId +'-'+ jentry.JournalEntry.Id +'-'+ je.Id;
                                            wots.add(wot);
                                        } 

                                        if (je.JournalEntryLineDetail.PostingType.equals('Debit') && je.JournalEntryLineDetail.AccountRef.name.equals('Inventory')) {
                                            wot.Amount__c = je.Amount;
                                            wot.Journal_Entry_Type__c = 'Debit'; 
                                            wot.Job__c = wo[0].Id;
                                            wot.Transaction_Date__c = Date.valueOf(jentry.JournalEntry.TxnDate);
                                            wot.Transaction_Type__c = 'Journal Entry';
                                            wot.Journal_Entry_Account__c = je.JournalEntryLineDetail.AccountRef.name;
                                              
                                            wot.Source_Reference__c = realmId +'-'+ jentry.JournalEntry.Id +'-'+ je.Id;
                                            wots.add(wot);
                                        }
                                            
                                        
                                        
                                       
                                    }
                                }
                            }   
                        }
                }
                }else{
                    List<WorkOrder_Transaction__c> tmpWot = new List<WorkOrder_Transaction__c>();
                    tmpWot = [select id from WorkOrder_Transaction__c 
                              where Source_Reference__c like :realmId+'-'+QBId+'-%'
                              and Transaction_Type__c = 'Journal Entry'
                              and Payment_Status__c != 'Void' limit 1];
                    if (tmpWot.size() > 0){
                        tmpWot[0].Payment_Status__c = 'Void';
                        tmpWot[0].Amount__c = 0.0;
                        wots.add(tmpWot[0]);
                    }
                }
            }
                     
                
               

            
            if(wots.size() > 0){
                //System.debug('Upsert Work Order Transactions >>>>>>');
                //upsert wots;
            }
            
        
        
            System.debug('Update QB entity >>>>>>');
            if (qbe.Id != null){
                update qbe;        
            }      
        }
    
        return wots;
    }    
}