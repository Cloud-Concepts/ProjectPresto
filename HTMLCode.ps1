[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
# Ignore Self Signed Certificates
if (-not ([System.Management.Automation.PSTypeName]'ServerCertificateValidationCallback').Type) {
  $certCallback = @"
    using System;
    using System.Net;
    using System.Net.Security;
    using System.Security.Cryptography.X509Certificates;
    public class ServerCertificateValidationCallback
    {
        public static void Ignore()
        {
            if(ServicePointManager.ServerCertificateValidationCallback ==null)
            {
                ServicePointManager.ServerCertificateValidationCallback +=
                    delegate
                    (
                        Object obj,
                        X509Certificate certificate,
                        X509Chain chain,
                        SslPolicyErrors errors
                    )
                    {
                        return true;
                    };
            }
        }
    }
"@
  Add-Type $certCallback
}
[ServerCertificateValidationCallback]::Ignore()

# HTML Code

$HTML = @"
<!DOCTYPE html>
<head>
    <meta http-equiv="X-UA-Compatible" content="IE=11">
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
    <script src="https://code.jquery.com/jquery-3.3.1.min.js" integrity="sha256-FgpCb/KJQlLNfOu91ta32o/NMZxltwRo8QtmkMRdAu8=" crossorigin="anonymous"></script>
    <link rel="stylesheet" id="dark" title="dark" href="https://unpkg.com/@clr/ui/clr-ui.min.css"/>
    <link rel="stylesheet alternate" id="light" title="light" href="https://unpkg.com/@clr/ui/clr-ui-dark.min.css" disabled=true />
    <link rel="stylesheet" href="https://unpkg.com/@clr/icons/clr-icons.min.css" />
    <script src="https://unpkg.com/@webcomponents/custom-elements/custom-elements.min.js"></script>
    <script src="https://unpkg.com/@clr/icons/clr-icons.min.js"></script>
    <script type="text/powershell" id="PowerShellFunctions">
        # Global Variables

        `$global:vCenterSessionHeader = ""
        `$global:Credentials
        `$global:vCenterSessionURL
        `$global:BaseURL
        `$global:VCSAURL

        Function Connect-vCenter([string]`$PSvCenterName, [string]`$PSUserName, [string]`$PSPassword) {
            # Set parameters for REST API Session Credentials - with 256-key and save to global variables
            `$KeyFile = `$RunPath  + "\Presto.key"
            `$Key = Get-Content `$KeyFile
            `$SecurePassword = `$PSPassword | ConvertTo-SecureString -AsPlainText -Force
            `$SecurePassword = `$SecurePassword | ConvertFrom-SecureString -key `$Key
            `$global:Credentials = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList `$PSUserName, (`$SecurePassword | ConvertTo-SecureString -Key `$Key)

            # Prepare REST connection
            `$BaseAuthURL = "https://" + `$PSvCenterName + "/rest/com/vmware/cis/"
            `$global:BaseURL = "https://" + `$PSvCenterName + "/rest/vcenter/"
            `$global:VCSAURL = "https://" + `$PSvCenterName + "/rest/appliance/"
            `$global:vCenterSessionURL = `$BaseAuthURL + "session"
            `$Header = @{"Authorization" = "Basic "+[System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes(`$global:Credentials.UserName+":"+`$global:Credentials.GetNetworkCredential().password))}

            # Check vCenter URL availability
            Try{
                `$vCenterReq = [System.Net.WebRequest]::Create("https://" + `$PSvCenterName)
                `$vCenterRes = `$vCenterReq.GetResponse()
                if(`$vCenterRes.StatusCode -ne "OK"){
                    `$vCenterRes.Close()
                    return "Invalid vCenter"
                }
                `$vCenterRes.Close()
            }
            Catch {
                return "Unknown Error"
            }

            # Authenticating with API
            Try {
                `$vCenterSessionResponse = Invoke-RestMethod -Uri `$global:vCenterSessionURL -Headers `$Header -Method POST -ContentType "application/json"
            }
            Catch {
                # Return the Error code
                return "Invalid Credentials"
            }

            # Create the vCenter Session Header with the Session ID and save it to global variable
            `$global:vCenterSessionHeader = @{'vmware-api-session-id' = `$vCenterSessionResponse.value}

            # Close REST API Session
            Try {
                `$CloseSession = Invoke-RestMethod -Method DELETE -Uri `$global:vCenterSessionURL -TimeoutSec 100 -Headers `$global:vCenterSessionHeader -ContentType "application/json"
                `$global:vCenterSessionHeader = ""
            }
            Catch {
                return "Close Session Failed"
            }

            return `$vCenterSessionResponse.value
        }

        Function Dashboard_Initialize() {
            # Get all datacenters in this vCenter instance
            `$Header = @{"Authorization" = "Basic "+[System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes(`$global:Credentials.UserName+":"+`$global:Credentials.GetNetworkCredential().password))}

            # Authenticating with API
            Try {
                `$vCenterSessionResponse = Invoke-RestMethod -Uri `$global:vCenterSessionURL -Headers `$Header -Method POST -ContentType "application/json"
            }
            Catch {
                # Return the Error code
                return "Invalid Credentials"
            }

            # Create the vCenter Session Header with the Session ID and save it to global variable
            `$global:vCenterSessionHeader = @{'vmware-api-session-id' = `$vCenterSessionResponse.value}

            # Get the number of datacenters
            `$DCListURL = `$global:BaseURL + "/datacenter"
            Try {
                `$DCList = Invoke-RestMethod -Method Get -Uri `$DCListURL -TimeoutSec 100 -Headers `$global:vCenterSessionHeader -ContentType "application/json"
            }
            Catch {
                return "DC Get Failed"
            }
            `$DCListJSON = convertto-json `$DCList
            `$totalDCs = `$DCListJSON.Count

            # Get the number of clusters
            `$ClusterListURL = `$global:BaseURL + "/cluster"
            Try {
                `$ClusterList = Invoke-RestMethod -Method Get -Uri `$ClusterListURL -TimeoutSec 100 -Headers `$global:vCenterSessionHeader -ContentType "application/json"
            }
            Catch {
                return "Cluster Get Failed"
            }
            `$totalClusters = `$ClusterList.value.Count

            # Get the number of hosts
            `$HostListURL = `$global:BaseURL + "/host"
            Try {
                `$HostList = Invoke-RestMethod -Method Get -Uri `$HostListURL -TimeoutSec 100 -Headers `$global:vCenterSessionHeader -ContentType "application/json"
            }
            Catch {
                return "Host Get Failed"
            }
            `$totalHosts = `$HostList.value.host.Count

            # Get the number of VMs
            `$VMListURL = `$global:BaseURL + "/vm"
            Try {
                `$VMList = Invoke-RestMethod -Method Get -Uri `$VMListURL -TimeoutSec 100 -Headers `$global:vCenterSessionHeader -ContentType "application/json"
            }
            Catch {
                return "VM Get Failed"
            }
            `$totalVMs = `$VMList.value.Count

            # Get vCenter version information
            `$VCSAInfoURL = `$global:VCSAURL + "/system/version"
            Try {
                `$VCSAInfo = Invoke-RestMethod -Method Get -Uri `$VCSAInfoURL -TimeoutSec 100 -Headers `$global:vCenterSessionHeader -ContentType "application/json"
            }
            Catch {
                return "VCSA Get Failed"
            }

            `$VCSABuild = `$VCSAInfo.value.Build
            `$VCSAType = `$VCSAInfo.value.Type
            `$VCSAInstall = `$VCSAInfo.value.install_time.split("UTC")
            `$VCSAVersion = `$VCSAInfo.value.version

            # Get Appliance Access state
            `$ConsoleCliURL = `$global:VCSAURL + "/access/consolecli"
            Try {
                `$ConsoleCliInfo = Invoke-RestMethod -Method Get -Uri `$ConsoleCliURL -TimeoutSec 100 -Headers `$global:vCenterSessionHeader -ContentType "application/json"
            }
            Catch {
                return "ConsoleCLI Get Failed"
            }
            `$ConsoleCLI = `$ConsoleCliInfo.value

            `$DCUIURL = `$global:VCSAURL + "/access/dcui"
            Try {
                `$DCUIInfo = Invoke-RestMethod -Method Get -Uri `$DCUIURL -TimeoutSec 100 -Headers `$global:vCenterSessionHeader -ContentType "application/json"
            }
            Catch {
                return "DCUI Get Failed"
            }
            `$DCUICLI = `$DCUIInfo.value

            `$ShellURL = `$global:VCSAURL + "/access/shell"
            Try {
                `$ShellInfo = Invoke-RestMethod -Method Get -Uri `$ShellURL -TimeoutSec 100 -Headers `$global:vCenterSessionHeader -ContentType "application/json"
            }
            Catch {
                return "Shell Get Failed"
            }
            `$ShellCLI = `$ShellInfo.value.enabled

            `$SshURL = `$global:VCSAURL + "/access/ssh"
            Try {
                `$SshInfo = Invoke-RestMethod -Method Get -Uri `$SshURL -TimeoutSec 100 -Headers `$global:vCenterSessionHeader -ContentType "application/json"
            }
            Catch {
                return "SSH Get Failed"
            }
            `$SshCCLI = `$SshInfo.value

            #Get Appliance Health State
            `$OverallHealth = `$global:VCSAURL + "/health/system"
            Try {
                `$OverallHealthInfo = Invoke-RestMethod -Method Get -Uri `$OverallHealth -TimeoutSec 100 -Headers `$global:vCenterSessionHeader -ContentType "application/json"
            }
            Catch {
                return "Overall Health Get Failed"
            }
            `$OverallHealthStatus = `$OverallHealthInfo.value
            `$CPUHealth = `$global:VCSAURL + "/health/load"
            Try {
                `$CPUHealthInfo = Invoke-RestMethod -Method Get -Uri `$CPUHealth -TimeoutSec 100 -Headers `$global:vCenterSessionHeader -ContentType "application/json"
            }
            Catch {
                return "CPU Health Get Failed"
            }
            `$CPUHealthStatus = `$CPUHealthInfo.value
            `$MemHealth = `$global:VCSAURL + "/health/mem"
            Try {
                `$MemHealthInfo = Invoke-RestMethod -Method Get -Uri `$MemHealth -TimeoutSec 100 -Headers `$global:vCenterSessionHeader -ContentType "application/json"
            }
            Catch {
                return "CPU Health Get Failed"
            }
            `$MemHealthStatus = `$MemHealthInfo.value
            `$DBHealth = `$global:VCSAURL + "/health/database-storage"
            Try {
                `$DBHealthInfo = Invoke-RestMethod -Method Get -Uri `$DBHealth -TimeoutSec 100 -Headers `$global:vCenterSessionHeader -ContentType "application/json"
            }
            Catch {
                return "CPU Health Get Failed"
            }
            `$DBHealthStatus = `$DBHealthInfo.value


            # Close REST API Session
            Try {
                `$CloseSession = Invoke-RestMethod -Method DELETE -Uri `$global:vCenterSessionURL -TimeoutSec 100 -Headers `$global:vCenterSessionHeader -ContentType "application/json"
                `$global:vCenterSessionHeader = ""
            }
            Catch {
                return "Close Session Failed"
            }

            # Return all data to the javascript window (# Datacenters, # Clusters, # Hosts, # VMs)
            `$DashboardData = `$totalDCs.ToString() + "/" + `$totalClusters.ToString() + "/" + `$totalHosts.ToString() + "/" + `$totalVMs.ToString() + "/" + `$VCSAType + "/" + `$VCSAVersion + "/" + `$VCSABuild + "/" + `$VCSAInstall + "/" + `$ConsoleCLI + "/" + `$DCUICLI + "/" + `$ShellCLI + "/" + `$SshCCLI + "/" + `$OverallHealthStatus + "/" + `$CPUHealthStatus + "/" + `$MemHealthStatus + "/" + `$DBHealthStatus
            return `$DashboardData

        }
    </script>

    <script type="text/javascript">

        // Variables
        // ----------------------------------------------------------------------------------------------------

        // General Functions
        // ----------------------------------------------------------------------------------------------------
        // - Throw top bar errors
            function throwTopWarning(type, text){
                switch(type){
                    case "info":
                        `$('#topinfotext').text(text);
                        `$('#topinfo').slideDown("slow");
                        break;

                    case "warning":
                        `$('#topwarningtext').text(text);
                        `$('#topwarning').slideDown("slow");
                        break;
                }
            }


        // Page load functions
        // ----------------------------------------------------------------------------------------------------
        // - Load Dashboard Page
        function loadDashboard(){
            `$("#page_dashboard").show(0, function(){
                // - Run the powershell to connect to REST api and get data
                   window.external.runPowerShell("Dashboard_Initialize",parseDashboard);
              });
        }


        // Javascript return functions for PowerCLI functions
        // ----------------------------------------------------------------------------------------------------
        // - Return function after PowerShell Initialization
        //
            returnStartup = function(result) {
                  if (result != "PowerShell is busy.") {
                    `$('#loginpage').show();
                  }
            }

        // - Fill dashboard values after REST call
            parseDashboard = function(parseresult) {
                if (parseresult == "Datacenter Query Failed") {
                    throwTopWarning("warning","****Could not retrieve Datacenters from vCenter****");
                    return false;
                }
                if (parseresult != "PowerShell is busy.") {
                    // - Fill VCSA information
                    var dashboardvalues = parseresult.split("/");
                    `$('#nDatacenters').html(dashboardvalues[0]);
                    `$('#nClusters').html(dashboardvalues[1]);
                    `$('#nHosts').html(dashboardvalues[2]);
                    `$('#nVMs').html(dashboardvalues[3]);
                    `$('#vcenter_info').html(dashboardvalues[4]);
                    `$('#vcenter_version').html("$($MsgTbl.Version)&nbsp;" + dashboardvalues[5] + " (" + dashboardvalues[6] +")");
                    `$('#vcenter_date').html("$($MsgTbl.InstallDate)&nbsp;" + dashboardvalues[7]);
                    if (dashboardvalues[8] == "True"){
                        `$('#CLI_icon').html("<clr-icon shape='shield-check'></clr-icon></span>");
                    }else{
                        `$('#CLI_icon').html("<clr-icon shape='shield-x'></clr-icon></span>");
                    }
                    if (dashboardvalues[9] == "True"){
                        `$('#DCUI_icon').html("<clr-icon shape='shield-check'></clr-icon></span>");
                    }else{
                        `$('#DCUI_icon').html("<clr-icon shape='shield-x'></clr-icon></span>");
                    }
                    if (dashboardvalues[10] == "True"){
                        `$('#Bash_icon').html("<clr-icon shape='shield-check'></clr-icon></span>");
                    }else{
                        `$('#Bash_icon').html("<clr-icon shape='shield-x'></clr-icon></span>");
                    }
                    if (dashboardvalues[11] == "True"){
                        `$('#Ssh_icon').html("<clr-icon shape='shield-check'></clr-icon></span>");
                    }else{
                        `$('#Ssh_icon').html("<clr-icon shape='shield-x'></clr-icon></span>");
                    }
                    if (dashboardvalues[12] == "green"){
                        `$('#GenHealth_icon').html("<clr-icon shape='success-standard'></clr-icon></span>");
                    }
                    if (dashboardvalues[12] == "yellow"){
                        `$('#GenHealth_icon').html("<clr-icon shape='warning-standard'></clr-icon></span>");
                    }
                    if (dashboardvalues[12] == "red"){
                        `$('#GenHealth_icon').html("<clr-icon shape='times'></clr-icon></span>");
                    }
                    `$('#GenHealth_text').html("$($MsgTbl.OverallHealth)");
                    if (dashboardvalues[13] == "green"){
                        `$('#CPUHealth_icon').html("<clr-icon shape='success-standard'></clr-icon></span>");
                    }
                    if (dashboardvalues[13] == "yellow"){
                        `$('#CPUHealth_icon').html("<clr-icon shape='warning-standard'></clr-icon></span>");
                    }
                    if (dashboardvalues[13] == "red"){
                        `$('#CPUHealth_icon').html("<clr-icon shape='times'></clr-icon></span>");
                    }
                    `$('#CPUHealth_text').html("$($MsgTbl.CPUHealth)");
                    if (dashboardvalues[14] == "green"){
                        `$('#MemHealth_icon').html("<clr-icon shape='success-standard'></clr-icon></span>");
                    }
                    if (dashboardvalues[14] == "yellow"){
                        `$('#MemHealth_icon').html("<clr-icon shape='warning-standard'></clr-icon></span>");
                    }
                    if (dashboardvalues[14] == "red"){
                        `$('#MemHealth_icon').html("<clr-icon shape='times'></clr-icon></span>");
                    }
                    `$('#MemHealth_text').html("$($MsgTbl.MemHealth)");
                    if (dashboardvalues[15] == "green"){
                        `$('#DBHealth_icon').html("<clr-icon shape='success-standard'></clr-icon></span>");
                    }
                    if (dashboardvalues[15] == "yellow"){
                        `$('#DBmHealth_icon').html("<clr-icon shape='warning-standard'></clr-icon></span>");
                    }
                    if (dashboardvalues[15] == "red"){
                        `$('#DBHealth_icon').html("<clr-icon shape='times'></clr-icon></span>");
                    }
                    `$('#DBHealth_text').html("$($MsgTbl.DBHealth)");
                    `$('#GeneralProgressBar').hide();
                    `$('#VCSAProgressBar').hide();
                }

            }

        // -----------------------------------------------------------------------------------------------
        //
        // - Return function after login button is pressed
        //
            verifyLogin = function(logintoken) {
              // Verify Initial Connection to vCenter
              if (logintoken == "Invalid vCenter") {
                // Show warning vCenter REST not available
                `$('#loginerror').text("$($MsgTbl.LoginNotResponding)");
                `$('#loginerror').show();
                return false;
              }
              if (logintoken == "Unknown Error") {
                // Show warning vCenter URL invalid
                `$('#loginerror').text("$($MsgTbl.LoginUnreachable)");
                `$('#loginerror').show();
                return false;
              }
              if (logintoken == "Invalid Credentials") {
                // Show warning vCenter Credentials error
                `$('#loginerror').text("$($MsgTbl.LoginInvalid)");
                `$('#loginerror').show();
                return false;
              }

              // Hide Login Page
              `$('#loginerror').hide();
              `$('#loginpage').hide();

              // Show Main Page
              `$("#mainpage").show(0, function(){
                  // When loaded, show the dashoard page
                  loadDashboard();
              });
            }
        // --------------------------------------------------------------------------------------------------------



        // Startup Routine
        `$(document).ready(function () {
            // - Load Powershell script into external PowerShell window
            // ----------------------------------------------------------------------------------------------------
               var script = `$('#PowerShellFunctions').html();

               // - Return to javascript function after preloading PowerShell Functions - Show Login Form

               window.external.runPowerShell(script, returnStartup);

            // ----------------------------------------------------------------------------------------------------
            // - Prevent the use of the F5 key to avoid blank page
            // ----------------------------------------------------------------------------------------------------
            `$(function()
            {
                `$(document).keydown(function (e) {
                    return (e.which || e.keyCode) != 116;
                });
            });

            // ----------------------------------------------------------------------------------------------------
            // - Bind button actions
            // ----------------------------------------------------------------------------------------------------
            //   - Submit button
            `$('#loginsubmit').on('click', function(e) {
                // ------------------------------------------------------------------------------------------------
                // Check form inputs not empty
                // ------------------------------------------------------------------------------------------------
                if(`$('#login_vcenter').val() == ''){
                    `$('#loginerror').text("$($MsgTbl.vCenterEmpty)");
                    `$('#loginerror').show();
                    return false;
                }
                if(`$('#login_username').val() == ''){
                    `$('#loginerror').text("$($MsgTbl.UserEmpty)");
                    `$('#loginerror').show();
                    return false;
                }
                if(`$('#login_password').val() == ''){
                    `$('#loginerror').text("$($MsgTbl.PassEmpty)");
                    `$('#loginerror').show();
                    return false;
                }

                // Form validation ok, try to log in
                `$('#loginerror').hide();
                window.external.runPowerShell("Connect-vCenter('" + document.getElementById('login_vcenter').value + "') ('" + document.getElementById('login_username').value + "') ('" + document.getElementById('login_password').value + "')",verifyLogin);
            });
            // --------------------------------------------------------------------------------------------------------
            //   - User button submenu
            `$('#headermenu').on('click', function(e){
                `$('#headersubmenu').toggle("slow");
            });


            // --------------------------------------------------------------------------------------------------------
            //   - Change theme color
            `$('#themeButton').on('click', function(e) {
                if(`$('#light').prop('disabled')==true){
                    `$('#dark').prop('disabled', true);
                    `$('#light').prop('disabled', false);
                    `$('#headersubmenu').toggle("slow");
                }else{
                    `$('#light').prop('disabled', true);
                    `$('#dark').prop('disabled', false);
                    `$('#headersubmenu').toggle("slow");
                }
            });

            // --------------------------------------------------------------------------------------------------------
            //   - Close Warning Buttons
            `$('#topwarningclose').on('click', function(e) {
                `$('#topwarning').slideUp("slow");
            });

            `$('#topinfoclose').on('click', function(e) {
                `$('#topinfo').slideUp("slow");
            });

        });
    </script>
</head>
<body>
<div class="login-wrapper" id="loginpage" style="display:none">
    <form class="login">
        <section class="title">
            <h3 class="welcome">$($MsgTbl.LoginWelcome1)</h3>
            $($MsgTbl.LoginWelcome2)
            <h5 class="hint">$($MsgTbl.LoginCopyright)</h5>
            <h5 class="hint"><i>$($MsgTbl.LoginBanner)</i></h5>
        </section>
        <div class="login-group">
            <input class="username" type="text" id="login_vcenter" placeholder="$($MsgTbl.LoginvCenter)">
            <input class="username" type="text" id="login_username" placeholder="$($MsgTbl.LoginUser)">
            <input class="password" type="password" id="login_password" placeholder="$($MsgTbl.LoginPass)">
            <div class="error active" id="loginerror" style="display:none">
                $($MsgTbl.LoginError)
            </div>
            <button type="button" id="loginsubmit" class="btn btn-primary">$($MsgTbl.butNext)</button>
            <a href="https://github.com/Cloud-Concepts/ProjectPresto" class="signup" target="_new">Project Presto GitHub page</a>
        </div>
    </form>
</div>


<div class="main-container" id="mainpage" style="display:none">
    <div class="alert alert-app-level alert-warning" id="topwarning" style="display:none">
        <div class="alert-items">
            <div class="alert-item static">
                <div class="alert-icon-wrapper">
                    <clr-icon class="alert-icon" shape="exclamation-triangle"></clr-icon>
                </div>
                <div class="alert-text" id="topwarningtext">
                    &nbsp;
                </div>
            </div>
        </div>
        <button type="button" class="close" id="topwarningclose" aria-label="Close">
            <clr-icon aria-hidden="true" shape="close"></clr-icon>
        </button>
    </div>
    <div class="alert alert-app-level alert-info" id="topinfo" style="display:none">
        <div class="alert-items">
            <div class="alert-item static">
                <div class="alert-icon-wrapper">
                    <clr-icon class="alert-icon" shape="info-circle"></clr-icon>
                </div>
                <div class="alert-text" id="topinfotext">
                    &nbsp;
                </div>
            </div>
        </div>
        <button type="button" class="close" id="topinfoclose" aria-label="Close">
            <clr-icon aria-hidden="true" shape="close"></clr-icon>
        </button>
    </div>

    <header class="header-6">
        <div class="branding">
            <div class="nav-link">
                <clr-icon shape="vm-bug"></clr-icon>
                <span class="title">$($MsgTbl.AppTitle)</span>
            </div>
        </div>
        <div class="header-nav">
            <a href="javascript://" class="active nav-link nav-text">Dashboard</a>
            <a href="javascript://" class="nav-link nav-text">Datacenter</a>
            <a href="javascript://" class="nav-link nav-text">Cluster</a>
            <a href="javascript://" class="nav-link nav-text">Host</a>
            <a href="javascript://" class="nav-link nav-text">VM</a>
        </div>
        <div class="header-actions">
            <div class="dropdown bottom-left open" style="padding-right:10px">
                <button id="headermenu" type="button" class="dropdown-toggle">
                    <clr-icon shape="user" size="24"></clr-icon>
                    <clr-icon shape="caret down"></clr-icon>
                </button>
                <div id="headersubmenu" class="dropdown-menu" style="display:none">
                    <h4 class="dropdown-header">$($MsgTbl.Settings)</h4>
                    <button type="button" id="themeButton" class="dropdown-item">$($MsgTbl.butSwitch)</button>
                    <div class="dropdown-divider"></div>
                    <button type="button" class="dropdown-item">$($MsgTbl.butSignOut)</button>
                </div>
            </div>
        </div>
    </header>

    <div class="content-container" id="page_dashboard" style="display:none">
        <div class="content-area">
            <!-- Columns -->
            <div class="clr-row">
                <div class="clr-col-8">
                    <span>
                        <div class="row">
                            <div class="col-lg-6 col-md-12 col-sm-12 col-xs-12">
                                <div class="card">
                                    <div class="card-block">
                                        <div class="progress top" id="GeneralProgressBar">
                                            <progress></progress>
                                        </div>
                                        <h5 class="card-title"><b>General Information</b></h5>
                                        <p class="p7">
                                        <i>General details on the infrastructure.</i>
                                        </p>
                                    </div>
                                    <ul class="list">
                                        <li>Datacenters: <span id="nDatacenters"><i>$($MsgTbl.Retrieving)</i></span></li>
                                        <li>Clusters: <span id="nClusters"><i>$($MsgTbl.Retrieving)</i></span></li>
                                        <li>Hosts: <span id="nHosts"><i>$($MsgTbl.Retrieving)</i></span></li>
                                        <li>VMs: <span id="nVMs"><i>$($MsgTbl.Retrieving)</i></span></li>
                                    </ul>
                                </div>
                            </div>
                            <div class="col-lg-6 col-md-12 col-sm-12 col-xs-12">
                                <div class="card">
                                    <div class="card-block">
                                        <h5 class="card-title"><b>Datastore Information</b></h5>
                                        <p class="p7">
                                        <i>The following gives brief capacity information for each datastore.</i>
                                        </p>
                                    </div>
                                    <ul class="list">
                                        <li>Number of Hosts: 25</li>
                                        <li>Number of VMs: 368</li>
                                        <li>Number of Templates: 53</li>
                                    </ul>
                                </div>
                            </div>
                        </div>
                    </span>
                </div>
                <div class="clr-col-4">
                    <span>
                        <div class="row">
                            <div class="col-lg-12 col-md-12 col-sm-12 col-xs-12">
                                <div class="card">
                                    <div class="card-block">
                                        <div class="progress top" id="VCSAProgressBar">
                                            <progress></progress>
                                        </div>
                                        <div class="card-text">
                                            <h5 class="card-title"><b>$($MsgTbl.VCSAInfo)</b></h5>
                                            <table class="table table-compact table-noborder">
                                                <tbody>
                                                    <tr>
                                                        <td><clr-icon shape="bundle"></clr-icon></td>
                                                        <td class="left"><span id="vcenter_info"><i>$($MsgTbl.Retrieving)</i></span></td>
                                                    </tr>
                                                    <tr>
                                                        <td><clr-icon shape="blocks-group"></clr-icon></td>
                                                        <td class="left"><span id="vcenter_version"><i>$($MsgTbl.Retrieving)</i></span></td>
                                                    </tr>
                                                    <tr>
                                                        <td><clr-icon shape="deploy"></clr-icon></td>
                                                        <td class="left"><span id="vcenter_date"><i>$($MsgTbl.Retrieving)</i></span></td>
                                                    </tr>
                                                    <tr>
                                                        <td colspan="2" class="left"><b><u>$($MsgTbl.ApplianceAccess)</u></b></td>
                                                    <tr>
                                                        <td><span id="CLI_icon"><i>...</i></span></td>
                                                        <td class="left">Console-based controlled CLI</td>
                                                    </tr>
                                                    <tr>
                                                        <td><span id="DCUI_icon"><i>...</i></span></td>
                                                        <td class="left">Direct Console User Interface</td>
                                                    </tr>
                                                    <tr>
                                                        <td><span id="Bash_icon"><i>...</i></span></td>
                                                        <td class="left">BASH Shell CLI</td>
                                                    </tr>
                                                    <tr>
                                                        <td><span id="Ssh_icon"><i>...</i></span></td>
                                                        <td class="left">SSH CLI</td>
                                                    </tr>
                                                    <tr>
                                                        <td colspan="2" class="left"><b><u>$($MsgTbl.ApplianceHealth)</u></b></td>
                                                    <tr>
                                                    <tr>
                                                        <td><span id="GenHealth_icon"><i>...</i></span></td>
                                                        <td class="left"><span id="GenHealth_text"><i>$($MsgTbl.Retrieving)</i></span></td>
                                                    </tr>
                                                    <tr>
                                                        <td><span id="CPUHealth_icon"><i>...</i></span></td>
                                                        <td class="left"><span id="CPUHealth_text"><i>$($MsgTbl.Retrieving)</i></span></td>
                                                    </tr>
                                                    <tr>
                                                        <td><span id="MemHealth_icon"><i>...</i></span></td>
                                                        <td class="left"><span id="MemHealth_text"><i>$($MsgTbl.Retrieving)</i></span></td>
                                                    </tr>
                                                    <tr>
                                                        <td><span id="DBHealth_icon"><i>...</i></span></td>
                                                        <td class="left"><span id="DBHealth_text"><i>$($MsgTbl.Retrieving)</i></span></td>
                                                    </tr>
                                                </tbody>
                                            </table>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </span>
                </div>
            </div>
        </div>
    </div>

</div>
</body>
"@