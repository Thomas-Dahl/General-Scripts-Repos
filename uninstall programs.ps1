﻿Param(

  [Parameter(Mandatory=$True,HelpMessage='Shortname of Application you wish to uninstall, Wildcars allowed')]
  [string]$Program,
  [string]$exclude='Value that will never be found in a program name',
  [Parameter(Mandatory=$True,HelpMessage='Shortname of Application Vendor, Wildcars allowed')]
  [string]$Vendor
)
function Write-Log
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [Alias("LogContent")]
        [string]$Message,

        [Parameter(Mandatory=$false)]
        [Alias('LogPath')]
        [string]$Path='C:\Logs\Uninstall.log',
        
        [Parameter(Mandatory=$false)]
        [ValidateSet("Error","Warn","Info")]
        [string]$Level="Info",
        
        [Parameter(Mandatory=$false)]
        [switch]$NoClobber
    )

    Begin
    {
        # Set VerbosePreference to Continue so that verbose messages are displayed.
        $VerbosePreference = 'Continue'
    }
    Process
    {
        
        # If the file already exists and NoClobber was specified, do not write to the log.
        if ((Test-Path $Path) -AND $NoClobber) {
            Write-Error "Log file $Path already exists, and you specified NoClobber. Either delete the file or specify a different name."
            Return
            }

        # If attempting to write to a log file in a folder/path that doesn't exist create the file including the path.
        elseif (!(Test-Path $Path)) {
            Write-Verbose "Creating $Path."
            $NewLogFile = New-Item $Path -Force -ItemType File
            }

        else {
            # Nothing to see here yet.
            }

        # Format Date for our Log File
        $FormattedDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

        # Write message to error, warning, or verbose pipeline and specify $LevelText
        switch ($Level) {
            'Error' {
                Write-Error $Message
                $LevelText = 'ERROR:'
                }
            'Warn' {
                Write-Warning $Message
                $LevelText = 'WARNING:'
                }
            'Info' {
                Write-Verbose $Message
                $LevelText = 'INFO:'
                }
            }
        
        # Write log entry to $Path
        "$FormattedDate $LevelText $Message" | Out-File -FilePath $Path -Append
    }
    End
    {
    }
}

function Application-Match
{
  param
  (
    [Parameter(Mandatory=$true, ValueFromPipeline=$true, HelpMessage="Data to filter")]
    $InputObject
  )
  process
  {
    if ($InputObject.Name -eq $app.Name)
    {
      $InputObject
    }
  }
}
Write-Log -Message ('Searching for installed product matching ProgamName like {0} and Vendor Like {1}' -f $program, $vendor)
$apps = Get-WmiObject -Class Win32_Product | Select-Object -Property Name,Vendor

foreach ($app in $apps){
    if ($app.Name -like $Program -and $app.Vendor -like $Vendor -and $app.Name -notmatch $exclude){
        Write-Log -Message ('Found installed app matching search {0}.name and Vendor {0}.Vendor' -f $app)
        $app = Get-WmiObject -Class Win32_Product | Application-Match
        Write-Log -Message "attempting to uninstall"
        Try{
            $app.Uninstall()
            }
        Catch{
            $_
            Write-Log -Message "failed to uninstall $($app.name)" -Level Error
            }
       }
    }