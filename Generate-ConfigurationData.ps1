param (
    [string]$Environment
)

# Instantiate the Configuration Hashtable
$ConfigurationData = @{
    AllNodes =@()
}

# Import the Node Data
foreach ($Datafile in (Get-ChildItem -Path "$PSScriptRoot\$Environment\Nodes" -Filter "*.psd1" -Recurse)) {
    $ConfigurationData.AllNodes += Import-PowerShellDataFile -Path $DataFile.FullName
}