Configuration FileTemplateV1
{
    param (
        [string]$NodeName,
        [string]$Name,
        [string]$OtherNode = $NodeName,
        [string]$Domain,
        [string]$Ensure,
        [int]$EstimatedTimeSaved = 1,
        [string]$DestinationPath,
        [string]$Contents
    )

    # Import the module that contains the File resource.
    Import-DscResource -Module PsDesiredStateConfiguration
    Import-DscResource -Module ActiveDirectoryDsc
    Import-DscResource -Module SqlServerDsc

    Node $NodeName
    {
        File "File_${Name}" {
            DestinationPath = $DestinationPath
            Contents = $Contents
            Ensure = $Ensure
            Type = 'File'
        }
    }
}