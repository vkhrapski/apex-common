public without sharing virtual class DynamicSelector extends fflib_SObjectSelector {

    private final Set<Schema.sObjectField> excludeFields;
    private final sObjectType sObjectTypeVar;
    private String orderBy;

    public DynamicSelector(sObjectType sObjectTypeVar){
        this(sObjectTypeVar, new Set<Schema.sObjectField>());
    }

    public DynamicSelector(sObjectType sObjectTypeVar, Set<Schema.sObjectField> excludeFields){
        super(false, false, false, false);
        this.sObjectTypeVar = sObjectTypeVar;
        this.excludeFields = excludeFields;
    }

    private List<Schema.SObjectField> FIELDS {
        get {
            if (FIELDS == null) {

                List<Schema.SObjectField> allFields = DescribeCache.getSObjectDescribe(this.sObjectTypeVar).fields.getMap().values();

                FIELDS = new List<Schema.SObjectField>();
                for(Schema.SObjectField field : allFields){
                    if(!this.excludeFields.contains(field) && (field.getDescribe().isAccessible() || 'PowerCustomerSuccess'.equalsIgnoreCase(UserInfo.getUserType()))){
                        FIELDS.add(field);
                    }
                }
            }
            return FIELDS;
        }
        private set;
    }

    public Schema.SObjectType getSObjectType() {
        return this.sObjectTypeVar;
    }

    public DynamicSelector setOrderBy(String orderBy) {
        this.orderBy = orderBy;
        return this;
    }

    public override String getOrderBy() {
        return String.isNotBlank(this.orderBy) ? this.orderBy : super.getOrderBy();
    }

    public List<Schema.SObjectField> getSObjectFieldList() {
        return FIELDS;
    }

    public sObject selectSingle(Id id){

        List<sObject> records = this.selectSObjectsById(new Set<Id>{id});

        if (records.isEmpty()){
            throw new Exceptions.MissingDataException('No record with Id: ' + id);
        }

        return records.get(0);

    }

    public List<sObject> selectByName(String name, Integer limitVar){

        name = String.format('%{0}%', new List<String>{String.isBlank(name) ? '' : name});

        fflib_QueryFactory queryFactory = newQueryFactory()
                .setCondition('Name LIKE :name')
                .setLimit(limitVar);

        String soql = queryFactory.toSOQL();

        return Database.query(soql);

    }

    public List<sObject> selectByCondition(String conditionString, Integer limitVar) {
        fflib_QueryFactory queryFactory = newQueryFactory()
                .setCondition(conditionString)
                .setLimit(limitVar);

        String soql = queryFactory.toSOQL();

        return Database.query(soql);
    }


    public fflib_QueryFactory queryFactoryByAndConditions(List<String> conditions, Integer limitVar){
        return queryFactoryByCondition(
                String.join(conditions, ' AND '),
                limitVar
        );
    }

    public fflib_QueryFactory queryFactoryByCondition(String conditionString, Integer limitVar){
        return newQueryFactory()
                .setCondition(conditionString)
                .setLimit(limitVar);
    }

    public static String allOrLikeStringCondition(String name){
        return String.format('%{0}%', new List<String>{String.isBlank(name) ? '' : name});
    }

    public Map<Id, SObject> selectByIdsForParentField(Set<Id> recordsIds, String parentSObject, Set<String> fieldNames) {
        Map<Id, SObject> result = new Map<Id, SObject>();
        if (String.isNotBlank(parentSObject)) {
            Set<String> selectFieldsSet = new Set<String> {
                    parentSObject + '.Id'
            };
            for (String fieldName : fieldNames) {
                selectFieldsSet.add(parentSObject + '.' + fieldName);
            }
            fflib_QueryFactory queryFactory = newQueryFactory().setCondition('Id IN :recordsIds').selectFields(selectFieldsSet);

            List<SObject> records = Database.query(queryFactory.toSOQL());
            for (SObject record : records) {
                SObject parentObj = (SObject)record.getSObject(parentSObject);
                if (parentObj != null) {
                    result.put((Id)record.get('Id'), parentObj);
                }
            }
        }

        return result;

    }

    public SObject selectByIdForParentField(Id recordsId, String parentSObject, Set<String> fieldNames) {
        Map<Id, SObject> records = selectByIdsForParentField(new Set<Id>{recordsId}, parentSObject, fieldNames);
        return records.size() > 0 ? records.values().get(0) : null;
    }

    public List<Structs.LookupOption> selectLookupOptions(Structs.LookupOptionRequest lookupOptionRequest, String parentSObject){
        return selectLookupOptionsAdditionalConditions(lookupOptionRequest, null, parentSObject);
    }
    public List<Structs.LookupOption> selectLookupOptionsAdditionalConditions(Structs.LookupOptionRequest lookupOptionRequest, List<String> additionalConditions, String parentSObject){
        return selectLookupOptionsAdditionalConditions(lookupOptionRequest, additionalConditions, parentSObject, new Set<String>{'Name'});
    }
    public List<Structs.LookupOption> selectLookupOptionsAdditionalConditions(Structs.LookupOptionRequest lookupOptionRequest, List<String> additionalConditions, String parentSObject, Set<String> fieldNames){

        String name = allOrLikeStringCondition(lookupOptionRequest.searchTerm);
        String parentId = lookupOptionRequest.parentId;

        List<String> conditions = new List<String>{
                'Name LIKE :name'
        };

        if (additionalConditions != null) {
            conditions.addAll(additionalConditions);
        }

        if(parentSObject != null && lookupOptionRequest.parentId != null){
            conditions.add(parentSObject + ' = :parentId');
        }

        fflib_QueryFactory queryFactory = this.queryFactoryByAndConditions(
                conditions,
                Constants.DEFAULT_LOOKUP_QUERY_LIMIT
        );

        List<sObject> options = Database.query(queryFactory.toSOQL());

        return Structs.convertSObjectsToLookupOptions(options, 'Id', fieldNames);
    }

    public List<Structs.LookupOption> selectLookupOptions(Structs.LookupOptionRequest lookupOptionRequest) {
        return selectLookupOptions(lookupOptionRequest, null);
    }

    public List<Structs.LookupOption> selectLookupOptions(String searchTerm) {
        return selectLookupOptions(new Structs.LookupOptionRequest(searchTerm));
    }

    public Structs.LookupOption selectLookupOptionForParentField(Id recordId, String parentSObject, Set<String> fieldNames, String separator) {
        Map<Id, Structs.LookupOption> result = selectLookupOptionsForParentField(new Set<Id> {recordId}, parentSObject, fieldNames, separator);
        return result.get(recordId);
    }

    public Structs.LookupOption selectLookupOptionForParentField(Id recordId, String parentSObject) {
        Map<Id, Structs.LookupOption> result = selectLookupOptionsForParentField(new Set<Id> {recordId}, parentSObject);
        return result.get(recordId);
    }

    public Map<Id, Structs.LookupOption> selectLookupOptionsForParentField(Set<Id> recordsIds, String parentSObject, Set<String> fieldNames, String separator) {
        Map<Id, Structs.LookupOption> result = new Map<Id, Structs.LookupOption>();

        if (String.isNotBlank(parentSObject)) {
            Map<Id, SObject> records = selectByIdsForParentField(recordsIds, parentSObject, fieldNames);
            for (Id recordId : records.keySet()) {
                SObject record = records.get(recordId);
                result.put(recordId, Structs.convertSObjectToLookupOption(record, 'Id', fieldNames, separator));
            }
        }

        return result;

    }

    public Map<Id, Structs.LookupOption> selectLookupOptionsForParentField(Set<Id> recordsIds, String parentSObject) {
        return selectLookupOptionsForParentField(recordsIds, parentSObject, new Set<String> {'Name'}, '');
    }
}