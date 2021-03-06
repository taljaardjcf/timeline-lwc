public with sharing class TimelineSOQLUtils {
    public static String getSOQLForTimeline(timeline__Timeline_Configuration__c conf,String recordId,String dateFilter){
        String soqlStmt = 'select Id,';
        List<String> childSoqls = new List<String>();
        for(timeline__Timeline_Child_Object__c childObjConf: conf.timeline__Timeline_Child_Objects__r){
            if(childObjConf.timeline__Data_Provider_Type__c ==null || childObjConf.timeline__Data_Provider_Type__c != 'Apex class'){
                childSoqls.add(getSoqlForChildConfig(childObjConf,recordId,dateFilter,false));
            }
        }
        if(!childSoqls.isEmpty()){
            soqlStmt += String.join(childSoqls,',');
            soqlStmt += ' from '+conf.timeline__Object__c;
            soqlStmt += ' where Id=\''+String.escapeSingleQuotes(recordId)+'\'';
            return soqlStmt;
        }else{
            return null;
        }
    }

    public static String getSoqlForChildConfig(timeline__Timeline_Child_Object__c childObjConf,String recordId,String dateFilter,Boolean isDiagnosticMode){

        String childSoql = isDiagnosticMode?'select ':'(select ';

        childObjConf.timeline__Data_Provider_Type__c='Related Record';
        List<String> fieldsToQuery = childObjConf.timeline__Fields_to_Display__c.split(',');
        if(!fieldsToQuery.contains('Id')) fieldsToQuery.add('Id');
        if(childObjConf.Object__c.equalsIgnoreCase('ContentDocumentLink')){
            if(!fieldsToQuery.contains('ContentDocumentId'))  fieldsToQuery.add('ContentDocumentId');
            fieldsToQuery.add('ContentDocument.Title');
            fieldsToQuery.add('ContentDocument.Description');
        }
        if(childObjConf.Object__c.equalsIgnoreCase('CaseArticle')){
            fieldsToQuery.add('KnowledgeArticleVersion.Title');
            fieldsToQuery.add('KnowledgeArticleVersion.Summary');
            fieldsToQuery.add('KnowledgeArticleVersion.UrlName');
        }
        if(childObjConf.Object__c.equalsIgnoreCase('Task')){
            if(!fieldsToQuery.contains('OwnerId')) fieldsToQuery.add('OwnerId');
            if(!fieldsToQuery.contains('WhoId')) fieldsToQuery.add('WhoId');
            if(!fieldsToQuery.contains('TaskSubtype')) fieldsToQuery.add('TaskSubtype');
            if(!fieldsToQuery.contains('IsClosed')) fieldsToQuery.add('IsClosed');
            if(!fieldsToQuery.contains('ActivityDate')) fieldsToQuery.add('ActivityDate');
            fieldsToQuery.add('Owner.Name');
            fieldsToQuery.add('Who.Name');
        }
        if(childObjConf.timeline__Date_Field__c !=null && !fieldsToQuery.contains(childObjConf.timeline__Date_Field__c)){
            fieldsToQuery.add(childObjConf.timeline__Date_Field__c);
        }
        if(childObjConf.Title_Field__c !=null && !fieldsToQuery.contains(childObjConf.Title_Field__c)){
            fieldsToQuery.add(childObjConf.Title_Field__c);
        }
        childSoql += String.join(fieldsToQuery,',');
        childSoql +=' from '+(isDiagnosticMode?childObjConf.timeline__Object__c:childObjConf.timeline__Relationship_Name__c);
        String dateFilterStr;
        if(dateFilter!=null){
            System.debug('Date filter= LAST_7_DAYS');
            switch on dateFilter{
                when 'last_7_days'{
                    System.debug('Date filter= LAST_7_DAYS');
                    dateFilterStr='LAST_N_DAYS:7';
                }
                when 'last_30_days'{
                    System.debug('Date filter= LAST_30_DAYS');
                    dateFilterStr='LAST_N_DAYS:30';
                }
                when 'next_7_days'{
                    System.debug('Date filter= NEXT_7_DAYS');
                    dateFilterStr='NEXT_N_DAYS:7';
                }
            }
        }
        if(childObjConf.timeline__Date_Field__c !=null){
            if(isDiagnosticMode){
                childSoql +=' where '+childObjConf.timeline__Reference_Field_Name__c+'=\''+recordId+ '\' and ' +childObjConf.timeline__Date_Field__c+ ' !=null';
            }else{
                childSoql +=' where ' +childObjConf.timeline__Date_Field__c+ ' !=null';
            }
            if(dateFilterStr !=null){
                childSoql +=' and '+childObjConf.timeline__Date_Field__c+'='+dateFilterStr;
            } 
            if(childObjConf.timeline__Where_Clause__c !=null){
                childSoql +=' and '+ childObjConf.timeline__Where_Clause__c;
            }
            childSoql +=' order by '+childObjConf.timeline__Date_Field__c+' desc';
        }else if(!childObjConf.timeline__Object__c.endsWith('__x')){
            if(isDiagnosticMode){
                childSoql +=' where '+childObjConf.timeline__Reference_Field_Name__c+'=\''+recordId+ '\'';
                if(dateFilterStr !=null){
                    childSoql +=' and '+childObjConf.timeline__Reference_Field_Name__c+'=\''+recordId+ '\' and CreatedDate='+dateFilterStr;
                }
            }else{
                childSoql +=' where '+childObjConf.timeline__Reference_Field_Name__c+'=\''+recordId+ '\' and CreatedDate='+dateFilterStr;
            }
            if(childObjConf.timeline__Where_Clause__c !=null){
                childSoql +=' and '+ childObjConf.timeline__Where_Clause__c;
            }   
            childSoql +=' order by CreatedDate desc';
        }

        if(!isDiagnosticMode)
            childSoql +=')';
        return childSoql;
    }
}