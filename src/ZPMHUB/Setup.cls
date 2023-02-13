Class ZPMHUB.Setup Extends %Persistent
{

Parameter SSLCONFIGNAME = "zpmhub";

Property Namespace As %String [ InitialExpression = {$ZNspace} ];

Index NamespaceIdKey On Namespace [ IdKey, Unique ];

/// ZpmHub server address
Property Server As %String [ InitialExpression = "https://zpmhub.com/" ];

Property Email As %String;

Property Token As %String(MAXLEN = 100);

Property EnvironmentName As %String;

Property ServerName As %String;

Property IsMonitoringEnabled As %Boolean;

ClassMethod Setup(token As %String = "null", verbose As %Boolean = 0) As %Status
{
    if '##class(%Dictionary.ClassDefinition).%ExistsId("%ZPM.PackageManager") {
        quit $$$ERROR($$$GeneralError,"You need to install ZPM Package Manager for ZpmHub to work")
    }
    if ..%ExistsId($ZNspace) set Setup=..%OpenId($ZNspace)
    else  set Setup=..%New()
    set existingSetup=Setup
    if ('existingSetup) && $data(^%ZPMHUB) set existingSetup=..%OpenId($order(^%ZPMHUB("")))
    if (token="null") {
        write !,!,"Welcome to ZpmHub! We need to ask you a few questions to get going.",!
        write "Enter new values or press Enter to use defaults provided in []",!
        set Setup.Server=..ReadValue("Enter ZpmHub server address",existingSetup.Server)
        set email=..ReadValue("Enter ZpmHub email or token", existingSetup.Email)
    } else {
        set email=token
    }
    if ..CheckToken(Setup.Server,email) { 
        set Setup.Email=email
        set Setup.Token=email
    } else {
        if '..CheckEmail(Setup.Server,email) {
            set create=..ReadValue("This email is not registered on "_Setup.Server_"."_$c(13,10)_"Do you want to register a new user?", "Y")
            if $e($zcvt(create,"U"))="N" quit $$$ERROR($$$GeneralError,"This email is not registered on "_Setup.Server)
            set name=..ReadValue("Enter your full name", "")
            use 0:(:"+S" ) //Secret mode for Read https://docs.intersystems.com/irislatest/csp/docbook/DocBook.UI.Page.cls?KEY=GIOD_termio#GIOD_termio_lettercodes
            set password=..ReadValue("Enter your password", "")
            use 0:(:"-S" ) 
            set orgName=..ReadValue("Enter your company name", "")
            set org=..ReadValue("Enter your company short name. This name will be used in URL like https://zpmhub.com/browse/yourorg and should only contain lowercase letters.", "")
            $$$QuitOnError(..Register(Setup.Server,email,password,name,orgName,org))
            write !,!,"Registered  "_email_" successfully.",!
        }
        set emailChanged=existingSetup.Email'=email
        set Setup.Email=email
        if existingSetup.Token'="",'emailChanged,..CheckToken(Setup.Server,existingSetup.Token) {
            set Setup.Token=existingSetup.Token
        } else {
            use 0:(:"+S" ) //Secret mode for Read https://docs.intersystems.com/irislatest/csp/docbook/DocBook.UI.Page.cls?KEY=GIOD_termio#GIOD_termio_lettercodes
            if $g(password)="" set password=..ReadValue("Enter ZpmHub password","")
            use 0:(:"-S" ) 
            set token=..GetToken(Setup.Server,Setup.Email,password)
            if token="" {
                quit $$$ERROR($$$GeneralError,"This password is invalid. Please try again.")
            }
            set Setup.Token=token
            write !,!,"We created a new token for this environment:",!,token
        }
    }
    set monitoring=..ReadValue("Do you want to enable ZpmHub monitoring of this namespace? (Y/N)","Y")
    set Setup.IsMonitoringEnabled=$e($zcvt(monitoring,"U"))'="N"
    if Setup.IsMonitoringEnabled {
        write !,"You need to choose an environment name. It has to be unique across the whole organisation."
        set Setup.EnvironmentName=..ReadValue("Enter a name for this environment",$ZNspace)
        set serverName=existingSetup.ServerName
        if serverName="" set serverName=##class(%SYS.System).GetUniqueInstanceName()
        set Setup.ServerName=..ReadValue("Enter a name for this IRIS instance",serverName)
        $$$QuitOnError(..AddMonitorTask())
    }
    set repoCommand="repo -r -n registry -url "_Setup.Server_"/api/ -user ""Token"" -pass """_Setup.Token_""""
    $$$QuitOnError(##class(%ZPM.PackageManager).Shell(repoCommand))
    $$$QuitOnError(Setup.%Save(0))
    $$$QuitOnError(##class(ZPMHUB.Task).SendSingleEnvironment($znspace))
    quit $$$OK
}

ClassMethod ReadValue(desc As %String, default As %String) As %String
{
    write !,desc_": ["_default_"] "
    read val
    if val="" set val=default
    quit val
}

ClassMethod AddMonitorTask() As %Status
{
    #dim Task As %SYS.Task
    set taskId=##class(%SYS.Task).FindId("ZpmHub Monitor")
    if taskId'="" set Task=##class(%SYS.Task).%OpenId(taskId)
    else  set Task=##class(%SYS.Task).%New()
    set Task.Name="ZpmHub Monitor"
    set Task.Description="Sends monitoring data for enabled namespaces to ZpmHub every hour"
    set Task.NameSpace=$ZNspace
    set Task.RunAsUser="_SYSTEM"
    set Task.TaskClass="ZPMHUB.Task"
    set Task.Type=2
    // Schedule: every hour
    set Task.StartDate=$h-1
    set Task.DailyEndTime = 86340
    set Task.DailyFrequency = 1
    set Task.DailyFrequencyTime = 0
    set Task.DailyIncrement = 60
    set Task.DailyStartTime = 0
    set Task.TimePeriodEvery = 1
    $$$QuitOnError(Task.%Save())
    quit $$$OK
}

ClassMethod GetSSLConfiguration() As %String
{
    Set host = ..#SSLCONFIGNAME
    New $NAMESPACE
    Set $NAMESPACE = "%SYS"
    If '##class(Security.SSLConfigs).Exists(host) {
        Do ##class(Security.SSLConfigs).Create(host)
    }
    Return host
}

ClassMethod CheckEmail(server As %String, email As %String) As %Boolean
{
    set config=##class(%ZPM.PackageManager.Client.REST.PackageManagerClient).%New()
    set location=server_"api/auth/checkEmail/"_email
    Set tRequest = config.GetHttpRequest(location)
    
    Set tSC = tRequest.Get(location)


    Quit tRequest.HttpResponse.StatusCode=200
}

ClassMethod CheckToken(server As %String, token As %String) As %Numeric
{
    set config=##class(%ZPM.PackageManager.Client.REST.PackageManagerClient).%New()
    set config.Location=server_"api/auth/check"
    set config.Username="token"
    set config.Password=token

    Set tRequest = config.GetHttpRequest()
    
    Set tSC = tRequest.Get($$$URLENCODE(tRequest.Location))
    Quit tRequest.HttpResponse.StatusCode=200
}

ClassMethod GetToken(server As %String, email As %String, password As %String) As %String
{
    set config=##class(%ZPM.PackageManager.Client.REST.PackageManagerClient).%New()
    set config.Location=server_"api/auth/token"
    set config.Username=$tr(email,"@","%")
    set config.Password=password

    Set tRequest = config.GetHttpRequest()
    
    Set tSC = tRequest.Post($$$URLENCODE(tRequest.Location))
    If ($$$ISERR(tSC) || (tRequest.HttpResponse.StatusCode'=200)) {
        quit ""
    }
    set jsonResponse={}.%FromJSON(tRequest.HttpResponse.Data)
    quit jsonResponse.token
}

ClassMethod Register(server As %String, email As %String, password As %String, name, orgName, org) As %Status
{
    set config=##class(%ZPM.PackageManager.Client.REST.PackageManagerClient).%New()
    set config.Location=server_"api/auth/sign-up"

    Set tRequest = config.GetHttpRequest()

    set body={
        "name":(name),
        "email":(email),
        "password":(password),
        "company":(orgName),
        "companyCode":(org),
        "agreements":true
    }

    Do tRequest.EntityBody.Write(body.%ToJSON())
    
    Set tSC = tRequest.Post($$$URLENCODE(tRequest.Location))
    If ($$$ISERR(tSC) || (tRequest.HttpResponse.StatusCode'=200)) {
        set jsonResponse={}.%FromJSON(tRequest.HttpResponse.Data)
        quit $$$ERROR(5001,jsonResponse.summary)
    }
    quit $$$OK
}

Storage Default
{
<Data name="SetupDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Server</Value>
</Value>
<Value name="3">
<Value>Email</Value>
</Value>
<Value name="4">
<Value>Token</Value>
</Value>
<Value name="5">
<Value>IsMonitoringEnabled</Value>
</Value>
<Value name="6">
<Value>EnvironmentName</Value>
</Value>
<Value name="7">
<Value>ServerName</Value>
</Value>
</Data>
<DataLocation>^%ZPMHUB</DataLocation>
<DefaultData>SetupDefaultData</DefaultData>
<IdLocation>^%ZPMHUB</IdLocation>
<IndexLocation>^%ZPMHUB</IndexLocation>
<StreamLocation>^%ZPMHUB</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
