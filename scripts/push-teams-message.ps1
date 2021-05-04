Param
(
    [object]$WebhookData,
    [string]$WebhookUrl
)

$monitorCondtion = $x.essentials.monitorCondition
if($monitorCondtion -eq 'Resolved') {
    Write-Host "Ignoring $monitorCondtion condition"
    return
}

$x = ($WebhookData.RequestBody | ConvertFrom-Json).data

if($x.essentials.signalType -eq 'Metric') {
    $facts = @(
        @{
            "name"= "Severity:"
            "value"= "$($x.essentials.severity)"
        }
    )
} else {
    $facts = @(
        @{
            "name"= "Severity:"
            "value"= "$($x.essentials.severity)"
        },
        @{
            "name"= "Query:"
            "value"= "$($x.alertContext.SearchQuery)"
        },
        @{
            "name"= "Result Count:"
            "value"= "$($x.alertContext.ResultCount)"
        }
    )
}

$request = @{
    "@context"= "http://schema.org/extensions"
    "@type"= "MessageCard"
    "themeColor"= "CC4216"
    "title"= "$($monitorCondtion) $($x.essentials.severity) - $($x.essentials.alertRule)"
    "text"= ($x.essentials.configurationItems -join ',')
    "summary"= "$($monitorCondtion) $($x.essentials.severity), $($x.essentials.alertRule), "
    "potentialAction"= @(
        @{
            "@type"= "OpenUri"
            "name"= "See details in Log Analytics"
            "targets"= @(
                @{
                    "os"= "default"
                    "uri"= "$($x.alertContext.LinkToFilteredSearchResultsUI)"
                }
            )
        },
        @{
            "@type"= "OpenUri"
            "name"= "Open Alert"
            "targets"= @(
                @{
                    "os"= "default"
                    "uri"= "https://ms.portal.azure.com/#blade/Microsoft_Azure_Monitoring/AlertDetailsTemplateBlade/alertId/$([System.Web.HTTPUtility]::UrlEncode($x.essentials.alertId))"
                }
            )
        }
    )
    "sections"= @(
        @{
            "facts"= $facts
        }
    )
}

Write-Host "Sending webhook to $WebhookUrl"

$serializedRequest = $request | ConvertTo-Json -Depth 55
Invoke-WebRequest -Uri $WebhookUrl -Body $serializedRequest -Method Post -UseBasicParsing 
