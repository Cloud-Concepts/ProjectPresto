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
    Requires   : PowerShell v5.0 - VMware Hackathlon Barcelona 2018


    Code snippets used from:
        Micah Rairdon        (http://tiberriver256.github.io/powershell/gui/html/PowerShell-HTML-GUI-Pt4)
        VIRAL PATEL          (https://viralpatel.net/blogs/jquery-trigger-custom-event-show-hide-element)
.LINK  
    Website    : https://www.cloudconcepts.be
	Git        : <coming>
#>
#Requires -Version 5.0

# Startup Runpath and Culture
    $RunPath = (Split-Path ((Get-Variable MyInvocation).Value).MyCommand.Path)
    #$RunPath = "C:\Users\Jurgen Van de Perre\Desktop\Hackathon 2018 Barcelona"
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

# Load HTML Code file
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
function Close-Application {
	
    Write-Host "Shutting down application..." -ForegroundColor Green
}

function new-PowershellWebGUI ($Htmlcode,$Title,$Runspace) {
    [xml]$xaml = @"
    <Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml" Title="$Title" WindowStartupLocation = "CenterScreen" Height="768" Width="1024" ResizeMode="NoResize" ShowInTaskbar = "True" Background = "DarkGray" WindowStyle="ThreeDBorderWindow">
        <Grid>
            <DockPanel>
                <WebBrowser Name="WebBrowser" DockPanel.Dock="Top" Margin="0"></WebBrowser>
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
    $Form=[Windows.Markup.XamlReader]::Load($reader)
    
    # Close Button actions
    $form.Add_Closing({ Close-Application }) 
    

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

    $WebBrowser.NavigateToString($htmlcode)

    write-host $MsgTbl.Loading -ForegroundColor Green
    $Form.ShowDialog() | out-null

}


# Show PowerShell Web GUI
New-PowershellWebGUI -Htmlcode $HTML -Title $MsgTbl.WindowTitle