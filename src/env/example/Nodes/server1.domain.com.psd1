@{
    NodeName = "server1.domain.com"
    Domain = "domain.com"
    Ensure = "Present"
    ConfigurationID = "603d03ac-88f6-4f61-b644-2a789cd9483b"

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

    Dns = @(
        @{
            Name = "myTestAlias1"
            Template = "DnsServerResourceRecordCNameV1"
            Ensure = "Present"
        },
        @{
            Name = "myTestAlias2"
            Template = "DnsServerResourceRecordCNameV1"
            Ensure = "Absent"
        }
    )
}
