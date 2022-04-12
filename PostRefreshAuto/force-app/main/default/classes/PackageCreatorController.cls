global with sharing class PackageCreatorController {
    public Map<String, List<String>> packageComponents{get;set;}
    global PackageCreatorController()
    {
        String uniqueKey = ApexPages.currentPage().getParameters().get('uniqueKey');
        System.debug(Cache.Org.contains('local.PackageXMLStorage.'+uniqueKey));

        if (String.isNotBlank(uniqueKey) && Cache.Org.contains('local.PackageXMLStorage.'+uniqueKey)) 
        {
            String base64str = (String)Cache.Org.get('local.PackageXMLStorage.'+uniqueKey);
            System.debug(base64str);
            System.debug(EncodingUtil.base64Decode(base64Str).toString());
            Map<String, List<String>> selectedComps =   (Map<String, List<String>>)
                JSON.deserialize(EncodingUtil.base64Decode(base64Str).toString(), Map<String, List<String>>.class);
            System.debug(selectedComps);
            packageComponents = selectedComps;
        }
    }

    @RemoteAction
    global static ResponseWrapper savePackageInCache(String jsonString, String uniqueKey)
    {
        ResponseWrapper wrap = new ResponseWrapper();
        try 
        {
            String base64Str = EncodingUtil.base64Encode(Blob.valueOf(jsonString));
            Datetime currentTime = System.now();
            String timeStr = ''+currentTime.Year()+currentTime.Month()+currentTime.Day()+currentTime.Hour()+currentTime.Minute()+currentTime.Second();
            if(String.isBlank(uniqueKey))
            {
                uniqueKey = UserInfo.getUserId()+timeStr;
            }
            System.debug('base64Str'+base64Str);
            Cache.Org.put('local.PackageXMLStorage.'+uniqueKey, base64Str);
            wrap.uniqueKey = uniqueKey;
            wrap.isSuccess = true;
        }
        catch (Exception e) {
            wrap.isSuccess = false;
            wrap.errorMsg = e.getMessage();
        }
        return wrap;
    }

    global class ResponseWrapper
    {
        global String errorMsg;
        global String uniqueKey;
        global Boolean isSuccess;
    }
}