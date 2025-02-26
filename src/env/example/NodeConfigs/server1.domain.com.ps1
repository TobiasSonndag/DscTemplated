Configuration SpecialConfig
{
    param (
        [string]$NodeName,
        [string]$Ensure = 'Present'
    )

    # Import the module that contains the File resource.
    Import-DscResource -Module PsDesiredStateConfiguration
    Import-DscResource -Module ActiveDirectoryDsc
    Import-DscResource -Module SqlServerDsc

    Node $NodeName
    {
        File CreateTestFile2 {
            DestinationPath = 'C:\temp\test2.txt'
            Contents = 'This is a test file for special config agl'
            Ensure = $Ensure
            Type = 'File'
        }
    }
}