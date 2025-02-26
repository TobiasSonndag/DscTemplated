@{
    NodeName = "server2.otherdomain.com"
    Domain = "otherdomain.com"
    Ensure = "Present"
    ConfigurationID = "c3e0baeb-5838-4e4f-adff-c20f292096f5"

    Databases = @(
        @{
            Name = "MyDatabase1"
            Template = "DatabaseTemplateV7"
            Ensure = "Present"
        },
        @{
            Name = "MyDatabase2"
            Template = "DatabaseTemplateV7"
            Ensure = "Absent"
        }
        
    )

    Files = @(
        @{
            Name = "myTestFile1"
            DestinationPath = "C:\temp\myTestFile1.txt"
            Contents = "This is a test file created by DSC."
            Template = "FileTemplateV1"
            Ensure = "Present"
        },
        @{
            Name = "myTestFile2"
            DestinationPath = "C:\temp\myTestFile2.txt"
            Contents = "This is a test file created by DSC."
            Template = "FileTemplateV1"
            Ensure = "Absent"
        }
    )
}
