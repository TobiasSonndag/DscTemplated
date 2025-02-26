param (
    [string]$NodeName,
    [string]$Name,
    [string]$OtherNode = $NodeName,
    [string]$Domain,
    [string]$Ensure,
    [int]$EstimatedTimeSaved = 15,
    [ValidateSet('isDomainControllerMainNode')]
    [string]$runOnOtherNode,
    [string]$DatabaseHost = $(switch ($OtherNode) {
                "server1.domain.com" {
                    'sqlcluster.domain.com'
                }
                "server2.otherdomain.com" {
                    'sqlcluster.otherdomain.com'
                }
                Default {
                    $OtherNode
                }
            }
        ),
    [string]$OuPath = $(switch ($Domain) {
                "domain.com" {
                    'OU=Database,OU=Unit,OU=Test,OU=My,DC=domain,DC=com'
                }
                "otherdomain.com" {
                    'OU=Database,OU=Unit,OU=Test,OU=My,DC=otherdomain,DC=com'
                }
                Default {
                    Write-Error "Current domain is not covered"
                }
            }
        ),
    [string]$SqlLoginDomainName = $(switch ($Domain) {
                "domain.com" {
                    'DOMAIN'
                }
                "otherdomain.com" {
                    'OTHERDOMAIN'
                }
                Default {
                    Write-Error "Current domain is not covered"
                }
            }
        ),
    [string]$AdGroupPrefix = "DB_${Name}_"
)

$params = @{
    NodeName = $NodeName
    Name = $Name
    OtherNode = $OtherNode
    DatabaseHost = $DatabaseHost
    Ensure = $Ensure
    Domain = $Domain
    runOnOtherNode = $runOnOtherNode
    OuPath = $OuPath
    SqlLoginDomainName = $SqlLoginDomainName
    EstimatedTimeSaved = $EstimatedTimeSaved
    AdGroupPrefix = $AdGroupPrefix
}

return $params