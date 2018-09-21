# HTML Code

$HTML = @"
<!DOCTYPE html>
<head>
    <meta http-equiv="X-UA-Compatible" content="IE=11">
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
    <script src="https://code.jquery.com/jquery-3.3.1.min.js" integrity="sha256-FgpCb/KJQlLNfOu91ta32o/NMZxltwRo8QtmkMRdAu8=" crossorigin="anonymous"></script>    
    <link rel="stylesheet" id="dark" title="dark" href="https://unpkg.com/@clr/ui/clr-ui-dark.min.css"/>
    <link rel="stylesheet alternate" id="light" title="light" href="https://unpkg.com/@clr/ui/clr-ui.min.css" disabled=true />
    <link rel="stylesheet" href="https://unpkg.com/@clr/icons/clr-icons.min.css" />
    <script src="https://unpkg.com/@webcomponents/custom-elements/custom-elements.min.js"></script>
    <script src="https://unpkg.com/@clr/icons/clr-icons.min.js"></script>
    <script type="text/powershell" id="PowerShellFunctions">
        Function Connect-vCenter {
            `$RESTAPIServer  = "vc3.dg3.be"
            `$username = "Administrator@vsphere.local"
            `$password = "01000000d08c9ddf0115d1118c7a00c04fc297eb01000000a8290caa2ded564fad62d5e1876871580000000002000000000003660000c0000000100000006fae33220b70c8d8e7e0166f7423e34d0000000004800000a000000010000000b88fdeaba7151d52890d5dfda1ca0861180000005ef4468184c828ad9b10bf1ba7659a66483ebca77f429ec014000000d9da75bebad5a243d5b7171f09739a181c9e1b50"
            `$Credentials = New-Object -TypeName System.Management.Automation.PSCredential -argumentlist `$username,(`$password | ConvertTo-SecureString)    
            `$RESTAPIUser = `$Credentials.UserName
            `$RESTAPIPassword = `$Credentials.GetNetworkCredential().password                  
            `$BaseAuthURL = "https://" + `$RESTAPIServer + "/rest/com/vmware/cis/"
            `$BaseURL = "https://" + `$RESTAPIServer + "/rest/vcenter/"
            `$vCenterSessionURL = `$BaseAuthURL + "session"
            `$Header = @{"Authorization" = "Basic "+[System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes(`$RESTAPIUser+":"+`$RESTAPIPassword))}
            `$Type = "application/json"

            # Authenticating with API
            Try {
                `$vCenterSessionResponse = Invoke-RestMethod -Uri `$vCenterSessionURL -Headers `$Header -Method POST -ContentType $Type
            }
            Catch {
                `$_.Exception.ToString()
                `$error[0] | Format-List -Force
            }

            # Extracting the session ID from the response
            `$vCenterSessionHeader = @{'vmware-api-session-id' = `$vCenterSessionResponse.value}

            # Getting all VMs
            `$VMListURL = `$BaseURL+"vm"

            Try {
                `$VMListJSON = Invoke-RestMethod -Method Get -Uri `$VMListURL -TimeoutSec 100 -Headers `$vCenterSessionHeader -ContentType $Type
                `$VMList = `$VMListJSON.value
            }
            Catch {
                `$_.Exception.ToString()
                `$error[0] | Format-List -Force
            }
            return `$VMList | ConvertTo-HTML
        }

        Function Get-ProcessPerformanceHTML {
            `$HTML = gwmi Win32_PerfFormattedData_PerfProc_Process | where {$_.Name -ne "_Total" -and $_.name -ne "Idle"} | select Name, 
                        @{ Name="PID"; Expression={$_.IDProcess} }, 
                        @{ Name="Memory (private working set)"; Expression={"{0:N0} K" -f ($_.WorkingSetPrivate / 1KB)} }, 
                        @{Name="CPU";Expression={$_.PercentProcessorTime}} | 
                        Sort CPU -Desc |
                        ConvertTo-HTML
            return `$HTML
        }
    </script>
</head>
<body>

<div class="main-container">
    <div id="topalert" class="alert alert-app-level alert-info">
        <div class="alert-items">
            <div class="alert-item static">
                <div class="alert-icon-wrapper">
                    <clr-icon class="alert-icon" shape="info-circle"></clr-icon>
                </div>
                <div class="alert-text">
                    $($MsgTbl.SwitchThema)
                </div>
                <div class="alert-actions">
                    <button class="btn alert-action" id="alertButton">$($MsgTbl.butSwitch)</button>
                </div>
            </div>
        </div>
        <button id="topalertclose" type="button" class="close" aria-label="Close">
            <clr-icon aria-hidden="true" shape="close"></clr-icon>
        </button>
    </div>

    <header class="header-6">
        <div class="branding">
            <div class="nav-link">
                <clr-icon shape="vm-bug"></clr-icon>
                <span class="title">vMonitor Dashboard</span>
            </div>
        </div>
        <div class="header-actions">
            <div class="dropdown bottom-left open" style="padding-right:10px">
                <button id="headermenu" type="button" class="dropdown-toggle">
                    <clr-icon shape="cog" size="24"></clr-icon>
                    <clr-icon shape="caret down"></clr-icon>
                </button>
                <div id="headersubmenu" class="dropdown-menu" style="display:none">
                    <h4 class="dropdown-header">Settings</h4>
                    <button type="button" class="dropdown-item active">Change Theme Color</button>
                    <button type="button" class="dropdown-item disabled">Disabled Action</button>
                    <div class="dropdown-divider"></div>
                    <button type="button" class="dropdown-item">Link 1</button>
                    <button type="button" class="dropdown-item">Link 2</button>
                </div>
            </div>
        </div>
    </header>

    <div class="content-container">
        <div class="content-area">
            Main Content
        </div>
        <nav class="sidenav">
            <section class="sidenav-content">
                <a href="..." class="nav-link active">
                    Nav Element 1
                </a>
                <a href="..." class="nav-link">
                    Nav Element 2
                </a>
                <section class="nav-group collapsible">
                    <input id="tabexample1" type="checkbox">
                    <label for="tabexample1">Collapsible Nav Element</label>
                    <ul class="nav-list">
                        <li><a class="nav-link">Link 1</a></li>
                        <li><a class="nav-link">Link 2</a></li>
                    </ul>
                </section>
                <section class="nav-group">
                    <input id="tabexample2" type="checkbox">
                    <label for="tabexample2">Default Nav Element</label>
                    <ul class="nav-list">
                        <li><a class="nav-link">Link 1</a></li>
                        <li><a class="nav-link">Link 2</a></li>
                        <li><a class="nav-link active">Link 3</a></li>
                        <li><a class="nav-link">Link 4</a></li>
                        <li><a class="nav-link">Link 5</a></li>
                        <li><a class="nav-link">Link 6</a></li>
                    </ul>
                </section>
            </section>
        </nav>
    </div>
</div>
<script type="text/javascript">
    // Theme Changer
    `$('#alertButton').on('click', function(e) {
        if(`$('#light').prop('disabled')==true){
            `$('#dark').prop('disabled', true);
            `$('#light').prop('disabled', false);
        }else{
            `$('#light').prop('disabled', true);
            `$('#dark').prop('disabled', false);
        }
    });

    // Button clicks
    `$('#topalertclose').on('click', function(e) {
        `$('#topalert').slideUp("slow");
    });

    `$('#headermenu').on('click', function(e){
        `$('#headersubmenu').toggle("slow");
    });

    `$('#butConnect').on('click', function(e) {
        ConnectvCenter();
    });

    `$('#butRefresh').on('click', function(e) {
        updateProcesses();
    });

    `$('#butEndTask').on('click', function(e) {
        EndTask();
    });
</script>
</body>
"@
# SIG # Begin signature block
# MIIItwYJKoZIhvcNAQcCoIIIqDCCCKQCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUSIaYVtYl1EErq/M+nm/fFoQB
# bzegggaqMIIGpjCCBI6gAwIBAgITNgAAxy77vOUmuFd2kAAHAADHLjANBgkqhkiG
# 9w0BAQUFADBAMRIwEAYKCZImiZPyLGQBGRYCYmUxEzARBgoJkiaJk/IsZAEZFgNE
# RzMxFTATBgNVBAMTDE1WRy1FV0JMLUFMVjAeFw0xODA4MDEwODE3MThaFw0xOTA4
# MDEwODE3MThaMIG8MQswCQYDVQQGEwJCRTETMBEGA1UECBMKVmxhYW5kZXJlbjEQ
# MA4GA1UEBxMHQnJ1c3NlbDEZMBcGA1UEChMQVkxBQU1TRSBPVkVSSEVJRDEpMCcG
# A1UECxMgRGVwYXJ0ZW1lbnQgTGFuZGJvdXcgZW4gVmlzc2VyaWoxHDAaBgNVBAMT
# E1dpbmRvd3MgU2VydmVyIFRlYW0xIjAgBgkqhkiG9w0BCQEWE0lUQGx2LnZsYWFu
# ZGVyZW4uYmUwgZ8wDQYJKoZIhvcNAQEBBQADgY0AMIGJAoGBANOiWWw/ZO+z25hS
# a8lc1oxKq1/HCi1hUgQZ6rKiZusV1kOsiNUQlg91YNmwRVRZXwHKOtZLA48FJrey
# YHVtVda2/X4YZCZOkHJ1RAHx80yWD5lPTwgYJLOcF3LZm/I77GcSDIljycdKmL4U
# WQUYz63irmf4+tYkqcytoW/AW/XlAgMBAAGjggKeMIICmjA+BgkrBgEEAYI3FQcE
# MTAvBicrBgEEAYI3FQiFyKsnhePIF4HJnTjq9hGoryuBO4TYuakKi+rH/QwCAWQC
# AQcwGwYJKwYBBAGCNxUKBA4wDDAKBggrBgEFBQcDAzALBgNVHQ8EBAMCB4AwEwYD
# VR0lBAwwCgYIKwYBBQUHAwMwHQYDVR0OBBYEFA9wG7Jb9KzoBioRy4oW5ld79WzN
# MB8GA1UdIwQYMBaAFKvX7hnbiraRrGg+5LTPCkMJ6wjlMIIBGwYDVR0fBIIBEjCC
# AQ4wggEKoIIBBqCCAQKGQGh0dHA6Ly9hbHYtY2EtbXZnLWV3YmwtYWx2LmRnMy5i
# ZS9DZXJ0RW5yb2xsL01WRy1FV0JMLUFMVig3KS5jcmyGgb1sZGFwOi8vL0NOPU1W
# Ry1FV0JMLUFMVig3KSxDTj1hbHYtY2EtbXZnLWV3YmwtYWx2LENOPUNEUCxDTj1Q
# dWJsaWMlMjBLZXklMjBTZXJ2aWNlcyxDTj1TZXJ2aWNlcyxDTj1Db25maWd1cmF0
# aW9uLERDPURHMyxEQz1iZT9jZXJ0aWZpY2F0ZVJldm9jYXRpb25MaXN0P2Jhc2U/
# b2JqZWN0Q2xhc3M9Y1JMRGlzdHJpYnV0aW9uUG9pbnQwgbkGCCsGAQUFBwEBBIGs
# MIGpMIGmBggrBgEFBQcwAoaBmWxkYXA6Ly8vQ049TVZHLUVXQkwtQUxWLENOPUFJ
# QSxDTj1QdWJsaWMlMjBLZXklMjBTZXJ2aWNlcyxDTj1TZXJ2aWNlcyxDTj1Db25m
# aWd1cmF0aW9uLERDPURHMyxEQz1iZT9jQUNlcnRpZmljYXRlP2Jhc2U/b2JqZWN0
# Q2xhc3M9Y2VydGlmaWNhdGlvbkF1dGhvcml0eTANBgkqhkiG9w0BAQUFAAOCAgEA
# w22DGVIbtZvLm5mR3ky44ibZFPureW1p5zzr5zdZYynDAsLM0y2fFM5TzdhfvMTd
# fpeTuKPXJI5RypbEB1tDuGpKR/A3yGLZdrYYiiVIV5gUIPcePFDV5yvAmsoDEqkX
# bH1HFDwJPMjZGduidScIEktLnkeV9LK+XIzuWDxfVYBZrtbb+ygNPYldM4VUk0uj
# ab+u525U2I9f9p7fbfN2cL5G9RzJM0hx/HLK13XnlCaPcZAK5iOK+Z3ec74K2qRA
# OpFdfsydNPK7cbrmntddhrF8PMTTnrf0ZFzRaeEWb16kKfgSQ5H7QmFoTC4yWUbV
# bMBSwqbwDScir5VAPrNjgwmpjFdJJ5SpMojVpAeELUMoRY/rliiXohZpMYRioD+e
# kzRzxA28Fr91M4FFY+2WRS9glwXXIZKLnK3uih52LxPDd68m7w10FKA8vF1MOltx
# 7GVcmnRGMYWj1lfjr02Zi5skLzUsG7CTDCOBBZM2wpVgQZZUdk8tLPemrl3WOdlx
# 0Urx4ip84pIazOjwGAaJLS2FBa+ry2opWDixmDnql/Kog3wZK1R8HDYWBMSNfEz5
# H8WC3P6RQMwkYzwqWb7Q4XVrcIPz9+mfpZLUdRVD4eeWcrIKUBjtpBhYJQflOv3g
# Pxfxb0wDnIhPF7fjCVdKDl+qRhDsX+4bgalDD1qKbRwxggF3MIIBcwIBATBXMEAx
# EjAQBgoJkiaJk/IsZAEZFgJiZTETMBEGCgmSJomT8ixkARkWA0RHMzEVMBMGA1UE
# AxMMTVZHLUVXQkwtQUxWAhM2AADHLvu85Sa4V3aQAAcAAMcuMAkGBSsOAwIaBQCg
# eDAYBgorBgEEAYI3AgEMMQowCKACgAChAoAAMBkGCSqGSIb3DQEJAzEMBgorBgEE
# AYI3AgEEMBwGCisGAQQBgjcCAQsxDjAMBgorBgEEAYI3AgEVMCMGCSqGSIb3DQEJ
# BDEWBBRf92EOAMo74oJnOh2FgfuWQxdOvzANBgkqhkiG9w0BAQEFAASBgIDjp1NY
# gLtrDxV4/cMU0N+44a0T5GhLLuVlGztM6ouWX4PoWirg+zcPgbV1KdAiJcfftF9U
# pcWjfgZSqRuVgN5v8PQbCgIYKjOYIlWbhHOAqkqY6lOec2r96T03nvtNiKyT10q8
# GWf8P7rX4a8kbA5J1lXk14Pi3mUKF3O0bqyA
# SIG # End signature block
