Configuration VirtualMachineTemplateV1
{
    param (
        [string]$NodeName,
        [string]$Domain,
        [string]$Name,
        [string]$DestinationPath,
        [string]$Contents,
        [string]$Ensure,
        [int]$EstimatedTimeSaved = 5
    )

    # Import the module that contains the File resource.
    Import-DscResource -Module PsDesiredStateConfiguration
    Import-DscResource -Module ActiveDirectoryDsc
    Import-DscResource -Module SqlServerDsc

    Node $NodeName
    {
        File "File_$NodeName" {
            DestinationPath = "C:\temp\dsctestvm.txt"
            Contents = "test of VirtualMachineTemplateV1"
            Ensure = $Ensure
            Type = 'File'
        }
    }
}