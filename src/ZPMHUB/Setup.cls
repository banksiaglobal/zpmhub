Class ZPMHUB.Setup Extends %Persistent
{

Parameter SSLCONFIGNAME = "zpmhub";

Property Namespace As %String [ InitialExpression = {$ZNspace} ];

Index NamespaceIdKey On Namespace [ IdKey, Unique ];

/// ZpmHub server address
Property Server As %String [ InitialExpression = "https://zpmhub.com/" ];

Property Email As %String;

Property Token As %String;

Property EnvironmentName As %String;

Property ServerName As %String;

Property IsMonitoringEnabled As %Boolean;

ClassMethod Setup(token As %String = "", verbose As %Boolean = 0) As %Status
{
    if '##class(%Dictionary.ClassDefinition).%ExistsId("%ZPM.PackageManager") {
        quit $$$ERROR($$$GeneralError,"You need to install ZPM Package Manager for ZpmHub to work")
    }
    if ..%ExistsId($ZNspace) set Setup=..%OpenId($ZNspace)
    else  set Setup=..%New()
    set existingSetup=Setup
    if ('existingSetup) && $data(^%ZPMHUB) set existingSetup=..%OpenId($order(^%ZPMHUB("")))
    write !,!,"Welcome to ZpmHub! We need to ask you a few questions to get going.",!
    write "Enter new values or press Enter to use defaults provided in []",!

    set Setup.Server=..ReadValue("Enter ZpmHub server address",existingSetup.Server)
    set Setup.Email=..ReadValue("Enter ZpmHub email",existingSetup.Email)
    set Setup.Token=..ReadValue("Enter ZpmHub password","")
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
    $$$QuitOnError(Setup.%Save(0))
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
