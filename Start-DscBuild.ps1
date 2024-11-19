param (
    [string]$Environment = 'Production',                      #Environment to build (Examples, Production, etc)  
    [string]$OutputPath = "$PSScriptRoot\$Environment\DSC", #Output path for MOF files
    $ErrorActionPreference = 'Stop'                         #Set global error action
)

#Delete Pre-existing MOFS in our DSC base folder
Get-ChildItem $OutputPath -Recurse -Include '*.mof', '*.mof.error', '*.mof.checksum' | Remove-Item -Force

#Build Configuration Data and MOF files
. $PSScriptRoot\Generate-ConfigurationData.ps1 -Environment $Environment
. $PSScriptRoot\DSC.ps1
. DSC -ConfigurationData $ConfigurationData -OutputPath $OutputPath -Environment $Environment

#Rename MOF files to ConfigurationID for SMB Pull Server (Mandatory)
foreach ($Node in $ConfigurationData.AllNodes.Where({$_.ConfigurationID})) {
        $source = "$OutputPath\$($Node.NodeName).mof"
        $dest = "$OutputPath\$($Node.ConfigurationID).mof"
        Move-Item -Path $source -Destination $dest -Force
        New-DSCCheckSum $dest -Force
}