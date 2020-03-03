param(
    [string]$Path,
    [string]$NRAppName
)

[xml]$doc = Get-Content $Path -Encoding UTF8
if(($addKey = $doc.SelectSingleNode("//configuration/appSettings/add[@key = 'NewRelic.AppName']")))
{
    Write-Host "Found key: NewRelic.AppName in XML, updating value from $($addKey.GetAttribute('value')) to $($NRAppName)"
    $addKey.SetAttribute('value',$NRAppName)
} else {
    $newAppSetting = $doc.CreateElement("add")
    $doc.configuration.appSettings.AppendChild($newAppSetting)
    $newAppSetting.SetAttribute("key","NewRelic.AppName");
    $newAppSetting.SetAttribute("value",$NRAppName);
}
$doc.Save($Path)
