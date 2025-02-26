function New-ConfigurationData {
    [CmdletBinding()]
    param (
        [string]$Environment,
        [string]$Path

    )

    # Instantiate the Configuration Hashtable
    $ConfigurationData = @{
        AllNodes =@()
    }

    # Import the Node Data
    foreach ($Datafile in (Get-ChildItem -Path $Path -Filter "*.psd1" -Recurse)) {
        $ConfigurationData.AllNodes += Import-PowerShellDataFile -Path $DataFile.FullName
    }

    return $ConfigurationData
}