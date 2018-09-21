<#  
.SYNOPSIS  
    Project Presto - PowerShell REST Operations
.DESCRIPTION  
    This script uses REST API's to connect to vCenter
    and to display statistics, run the most common
    maintenance jobs and much more.
.NOTES  
    File Name  : Project Presto.ps1
    Author     : Jurgen Van de Perre - jurgen@cloudconcepts.be
    Version    : 0.1
    Requires   : PowerShell v5.0
.LINK  
    Website    : https://www.cloudconcepts.be
	Git        : <coming>
#>
#Requires -Version 5.0

# Startup Runpath and Culture
    #$RunPath = (Split-Path ((Get-Variable MyInvocation).Value).MyCommand.Path)
    $RunPath = "H:\PowerShell\ProjectPresto"
    $LocalUICulture = Get-Culture

# Internationalization
    #region Internationalization
        # Default language en-US
        if (Test-Path ($RunPath + "\en-US.psd1")) {
            Import-LocalizedData -BindingVariable "MsgTbl" -UICulture "en-US" -FileName "en-US.psd1" -BaseDirectory $RunPath -ErrorAction SilentlyContinue
        }else{
            Write-Host "File: 'en-US.psd1' localized datafile is not available in directory $RunPath. Cannot continue!" -ForegroundColor Red
            exit
        }

        # Override if localized datafile is available
        Import-LocalizedData -BindingVariable "MsgTbl" -UICulture $LocalUICulture.Name -FileName ($LocalUICulture.Name + ".psd1") -BaseDirectory $RunPath -ErrorAction SilentlyContinue
    #endregion Internationalization


# Load GlobalVariables
    $GlobalVariables = $RunPath + "\GlobalVariables.ps1"
    if (Test-Path $GlobalVariables) {
        Write-Host $MsgTbl.FoundVars -ForegroundColor Green
    }else{
        Write-Host $MsgTbl.VarsMissing -ForegroundColor Red
        exit
    }
    . $GlobalVariables
    Write-Host $MsgTbl.LoadVars -ForegroundColor Green

# Load HTML Code
    $HTMLCode = $RunPath + "\HTMLCode.ps1"
    if (Test-Path $HTMLCode) {
        Write-Host $MsgTbl.FoundHTML -ForegroundColor Green
    }else{
        Write-Host $MsgTbl.HTMLMissing -ForegroundColor Red
        exit
    }
    . $HTMLCode
    Write-Host $MsgTbl.LoadHTML -ForegroundColor Green

# Load Modules
# - PowerCLI (Optional)
#if (!(Get-module | where {$_.Name -eq "VMware.VimAutomation.Core"})) {Import-Module VMware.VimAutomation.Core}

# Functions
function new-PowershellWebGUI ($HTMLRaw,$Title,$Runspace) {
    [xml]$xaml = @"
    <Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml" Title="$Title" WindowStartupLocation = "CenterScreen" Height="768" Width="1024" ResizeMode="NoResize" ShowInTaskbar = "True" Background = "DarkGray" WindowStyle="ThreeDBorderWindow">
        <Grid>
            <DockPanel>
                <WebBrowser Name="WebBrowser" DockPanel.Dock="Top" Margin="0">
                </WebBrowser>
            </DockPanel>
        </Grid>
    </Window>
"@

Add-Type -TypeDefinition @"
    using System.Text;
    using System.Runtime.InteropServices;
    using System.Threading.Tasks;

    //Add For PowerShell Invocation
    using System.Collections.ObjectModel;
    using System.Management.Automation;
    using System.Management.Automation.Runspaces;

    [ComVisible(true)]
    public class PowerShellHelper
    {

        Runspace runspace;

        public PowerShellHelper()
        {
            
            runspace = RunspaceFactory.CreateRunspace();
            runspace.Open();

        }

        public PowerShellHelper(Runspace remoteRunspace)
        {
            
           runspace = remoteRunspace;

        }

        void InvokePowerShell(string cmd, dynamic callbackFunc)
	    {
		    //Initialization of Pipeline
		    RunspaceInvoke scriptInvoker = new RunspaceInvoke(runspace);
            Pipeline pipeline;

            if(runspace.RunspaceAvailability != RunspaceAvailability.Available) {
                callbackFunc("PowerShell is busy.");
                return;
            }

		    pipeline = runspace.CreatePipeline();

		    //Add commands
		    pipeline.Commands.AddScript(cmd);
            
		    Collection<PSObject> results = pipeline.Invoke();

		    //Convert records to strings
		    StringBuilder stringBuilder = new StringBuilder();
		    foreach (PSObject obj in results)
		    {
			    stringBuilder.Append(obj);
		    }

        
            callbackFunc(stringBuilder.ToString());

	    }

        public void runPowerShell(string cmd, dynamic callbackFunc)
        {
            new Task(() => { InvokePowerShell(cmd, callbackFunc);}).Start();
        }

        public void resetRunspace()
        {
            runspace.Close();
            runspace = RunspaceFactory.CreateRunspace();
		    runspace.Open();
        }

    }
"@ -ReferencedAssemblies @("System.Management.Automation","Microsoft.CSharp","System.Web.Extensions")
 
    [void][System.Reflection.Assembly]::LoadWithPartialName('presentationframework')

    #Read XAML
    $reader=(New-Object System.Xml.XmlNodeReader $xaml) 
    $Form=[Windows.Markup.XamlReader]::Load( $reader )

    # Store Form Objects In PowerShell
    $WebBrowser = $Form.FindName("WebBrowser")
 
    if($Runspace)
    {
        $WebBrowser.ObjectForScripting = [PowerShellHelper]::new($Runspace)
    }
    else
    {
        $WebBrowser.ObjectForScripting = [PowerShellHelper]::new()
    }

    $WebBrowser.NavigateToString($HTMLRaw)

    write-host $MsgTbl.Loading -ForegroundColor Green
    $Form.ShowDialog() | out-null

}


# Show PowerShell Web GUI
New-PowershellWebGUI -HTMLRaw $HTML -Title $WindowTitle
# SIG # Begin signature block
# MIIItwYJKoZIhvcNAQcCoIIIqDCCCKQCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUFX4//zyX65xga1evqUTzUTw4
# kiygggaqMIIGpjCCBI6gAwIBAgITNgAAxy77vOUmuFd2kAAHAADHLjANBgkqhkiG
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
# BDEWBBQ8s77TAzMfuGaiwc3DiNLcow5LvDANBgkqhkiG9w0BAQEFAASBgEO062EA
# t/SmvVsVowVzbodjJHqDnrIt2GXIvKs6zoiWklDUD9UXaY+Up0JYstk78dYk9BnX
# NZj4/Wk3ZFWcbYNvBVCmeJ8sdp/sZEpddbHQrdzc9fvDLSytRQNMJW/qQOS6gF3h
# DwPYB3dZjShps1uqptAV0ir2TYIFfrOzm9uh
# SIG # End signature block
