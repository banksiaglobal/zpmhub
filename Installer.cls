Class ZPM.Installer
{

XData setup
{
<Manifest>
  <Default Name="APPPATH" Dir="#{$system.Process.CurrentDirectory()}" />
  <Default Name="SourceDir" Value="${APPPATH}src"/>
  <Default Name="NAMESPACE" Value="ZPMHUB"/>
  <Default Name="DBNAME" Value="ZPMHUB"/>
  <Default Name="RESOURCE" Value="%DB_${DBNAME}" /> 

  <Namespace Name="${NAMESPACE}" Code="${DBNAME}-CODE" Data="${DBNAME}-DATA" Create="yes" Ensemble="0">
    <Configuration>
      <Database Name="${DBNAME}-CODE" Dir="${APPPATH}${DBNAME}-CODE" Create="yes" Resource="${RESOURCE}"/>
      <Database Name="${DBNAME}-DATA" Dir="${APPPATH}${DBNAME}-DATA" Create="yes" Resource="${RESOURCE}"/>
    </Configuration>

    <Import File="${SourceDir}" Flags="ck" Recurse="1"/>
    
 </Namespace>
  <Invoke Class="ZPM.Installer" Method="AddSSLConfiguration"></Invoke>
</Manifest>
}

ClassMethod AddSSLConfiguration()
{
    Set host = "zpmregistry"
    New $NAMESPACE
    Set $NAMESPACE = "%SYS"
    If '##class(Security.SSLConfigs).Exists(host) {
        Do ##class(Security.SSLConfigs).Create(host)
    }
    Return host
}

}
