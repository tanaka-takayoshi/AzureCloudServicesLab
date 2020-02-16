param(
    [string]$WebConfigPath = "./Web.config",
    [string]$NRLicenseKey = "",
    [string]$NRAppName = "",
    [string]$NREnabled = "true"
)

function AddOrReplace {
    param (
        [string]$key,
        [string]$value
    )

    $xpath = "/configuration/appSettings/add[@key='$key']/@value"
    $nodes = $x.SelectNodes($xpath)

    foreach ($n in $nodes) {
        $n.value = $value
    }

    if ($nodes.Count -eq 0) {
        [System.Xml.XmlElement]$child=$x.CreateElement("add")
        $x.configuration.appSettings.AppendChild($child)
        $child.SetAttribute("key", $key)
        $child.SetAttribute("value", $value)
    }
}

[xml]$x = Get-Content $WebConfigPath -Encoding UTF8
AddOrReplace -key "NewRelic.LicenseKey" -value $NRLicenseKey
AddOrReplace -key "NewRelic.AppName" -value $NRAppName
AddOrReplace -key "NewRelic.AgentEnabled" -value $NREnabled
$x.Save($WebConfigPath)

