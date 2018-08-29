global class Structs {

    /* --------------------------------------- */
    /*  COMMON */
    /* --------------------------------------- */
    public class SelectOption{
        @AuraEnabled public String value {get; set;}
        @AuraEnabled public String label {get; set;}
        
        public SelectOption(String value, String label){
            this.value = value;
            this.label = label;
        }
    }

    public class LookupOption {
        @AuraEnabled public String id {get; set;}
        @AuraEnabled public String label {get; set;}
        @AuraEnabled public Object data {get; set;}

        public LookupOption(String id, String label) {
            this.id = id;
            this.label = label;
        }
        public LookupOption(String id, String label, Object data) {
            this(id, label);
            this.data = data;
        }
    }

    public virtual class LookupOptionRequest{
        public String searchTerm;
        public String parentId;

        public LookupOptionRequest(String searchTerm) {
            this.searchTerm = searchTerm;
        }
        public LookupOptionRequest(String searchTerm, String parentId) {
            this.searchTerm = searchTerm;
            this.parentId = parentId;
        }
    }

    public static LookupOption convertSObjectToLookupOption(sObject obj, String idFieldName, Set<String> labelFieldnames, String separator){
        String value = '';
        List<String> values = new List<String>();
        for (String labelFieldname : labelFieldnames) {
            String val = (String)obj.get(labelFieldname);
            if (String.isNotBlank(val)) {
                values.add(val);
            }
        }
        return new LookupOption(
                (String)obj.get(idFieldName),
                String.join(values, separator)
        );
    }

    public static LookupOption convertSObjectToLookupOption(SObject obj) {
        return convertSObjectToLookupOption(obj, 'Id', new Set<String>{'Name'}, '');
    }

    public static List<LookupOption> convertSObjectsToLookupOptions(List<sObject> sObjects, String idFieldName, Set<String> labelFieldnames, String separator){
        List<LookupOption> options = new List<LookupOption>();

        for (SObject obj : sObjects) {
            try {
                options.add(convertSObjectToLookupOption(obj, idFieldName, labelFieldnames, separator));
            } catch(Exception ex) {
                System.debug(obj);
                System.debug(ex.getMessage());
                System.debug(ex.getStackTraceString());
            }
        }

        return options;
    }

    public static List<LookupOption> convertSObjectsToLookupOptions(List<sObject> sObjects, Set<String> labelFieldnames, String separator){
        return convertSObjectsToLookupOptions(sObjects, 'Id', labelFieldnames, separator);
    }

    public static List<LookupOption> convertSObjectsToLookupOptions(List<sObject> sObjects, String idFieldName, Set<String> labelFieldnames){
        return convertSObjectsToLookupOptions(sObjects, idFieldName, labelFieldnames, ' - ');
    }

    public static List<LookupOption> convertSObjectsToLookupOptions(List<sObject> sObjects, Set<String> labelFieldnames){
        return convertSObjectsToLookupOptions(sObjects, 'Id', labelFieldnames, ' - ');
    }

    public static List<LookupOption> convertSObjectsToLookupOptions(List<sObject> sObjects, String idFieldName, String labelFieldname){
        return convertSObjectsToLookupOptions(sObjects, idFieldName, new Set<String>{labelFieldname});
    }

    public static List<LookupOption> convertSObjectsToLookupOptions(List<sObject> sObjects, String labelFieldname){
        return convertSObjectsToLookupOptions(sObjects, new Set<String>{labelFieldname});
    }

    public static List<LookupOption> convertSObjectsToLookupOptions(List<sObject> sObjects){
        return convertSObjectsToLookupOptions(sObjects, new Set<String>{'Name'});
    }

    public class BasicResponse {
        public Boolean isValid {get; set;}
        public ExceptionResponse error {get; set;}

        public BasicResponse() {
            this.isValid = true;
        }

        public BasicResponse(Exception ex) {
            this.isValid = (ex == null);

            if (ex != null)
                this.error = new ExceptionResponse(ex);
        }
    }

    public class RedirectResponse {
        public String redirectUrl {get; set;}
        public Boolean isValid { get; set; }
        public ExceptionResponse error { get; set; }

        public RedirectResponse(String redirectUrl){
            this.isValid = true;
            this.redirectUrl = redirectUrl;
        }

        public RedirectResponse(Exception ex) {
            this.isValid = (ex == null);

            if (ex != null)
                this.error = new ExceptionResponse(ex);
        }

    }

    public class ExceptionResponse {
        public Integer lineNumber {get; set;}
        public String message {get; set;}
        public String stackTraceString {get; set;}
        public String typeName {get; set;}

        public ExceptionResponse(Exception ex) {
            this.lineNumber = ex.getLineNumber();
            this.message = ex.getMessage();
            this.stackTraceString = ex.getStackTraceString();
            this.typeName = ex.getTypeName();
        }
    }

}