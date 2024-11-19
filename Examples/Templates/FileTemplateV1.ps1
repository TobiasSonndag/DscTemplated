Configuration FileTemplateV1
{
    param (
        [string]$NodeName,
        [string]$Domain,
        [string]$Name,
        [string]$DestinationPath,
        [string]$Contents,
        [string]$Ensure
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