<#
.SYNOPSIS
Builds and runs a Docker image.
.PARAMETER Compose
Runs docker-compose.
.PARAMETER Build
Builds a Docker image.
.PARAMETER Clean
Removes the image deviceapi and kills all containers based on that image.
.PARAMETER Stop
Stops all containers based on the image deviceapi.
.PARAMETER Down
Stops and removes all containers based on the image deviceapi.
.PARAMETER ComposeForDebug
Builds the image and runs docker-compose.
.PARAMETER Start
Runs docker-compose up.
.PARAMETER StartDebugging
Runs docker-compose up.
.PARAMETER Environment
The enviorment to build for (Debug or Release), defaults to Debug
.EXAMPLE
C:\PS> .\dockerTask.ps1 -Build
Build a Docker image named deviceapi
#>

Param(
    [Parameter(Mandatory=$True,ParameterSetName="Compose")]
    [switch]$Compose,
    [Parameter(Mandatory=$True,ParameterSetName="ComposeForDebug")]
    [switch]$ComposeForDebug,
    [Parameter(Mandatory=$True,ParameterSetName="Build")]
    [switch]$Build,
    [Parameter(Mandatory=$True,ParameterSetName="Clean")]
    [switch]$Clean,
    [Parameter(Mandatory=$True,ParameterSetName="Stop")]
    [switch]$Stop,
    [Parameter(Mandatory=$True,ParameterSetName="Down")]
    [switch]$Down,
    [Parameter(Mandatory=$True,ParameterSetName="Start")]
    [switch]$Start,
    [Parameter(Mandatory=$True,ParameterSetName="StartDebugging")]
    [switch]$StartDebugging,
    [parameter(ParameterSetName="Compose")]
    [Parameter(ParameterSetName="ComposeForDebug")]
    [parameter(ParameterSetName="Build")]
    [parameter(ParameterSetName="Clean")]
    [parameter(ParameterSetName="Stop")]
    [parameter(ParameterSetName="Down")]
    [parameter(ParameterSetName="Start")]
    [parameter(ParameterSetName="StartDebugging")]
    [ValidateNotNullOrEmpty()]
    [String]$Environment = "Debug"
)

$imageName="deviceapi"
$projectName="deviceapi"
$publicPort=8080
$url="http://localhost:$publicPort"

# Kills all running containers of an image and then removes them.
function CleanAll () {
    $composeFileName = "docker-compose.yml"
    if ($Environment -ne "Release") {
        $composeFileName = "docker-compose.$Environment.yml"
    }

    if (Test-Path $composeFileName) {
        docker-compose -f "$composeFileName" -p $projectName down --rmi all

        $danglingImages = $(docker images -q --filter 'dangling=true')
        if (-not [String]::IsNullOrWhiteSpace($danglingImages)) {
            docker rmi -f $danglingImages
        }
    }
    else {
        Write-Error -Message "$Environment is not a valid parameter. File '$composeFileName' does not exist." -Category InvalidArgument
    }
}

# Builds the Docker image.
function BuildImage () {
    $composeFileName = "docker-compose.yml"
    if ($Environment -ne "Release") {
        $composeFileName = "docker-compose.$Environment.yml"
    }

    if (Test-Path $composeFileName) {
        Write-Host "Building the image $imageName ($Environment)."
        docker-compose -f $composeFileName -p $projectName build
    }
    else {
        Write-Error -Message "$Environment is not a valid parameter. File '$composeFileName' does not exist." -Category InvalidArgument
    }
}

# Runs docker-compose.
function Compose () {
    $composeFileName = "docker-compose.yml"
    if ($Environment -ne "Release") {
        $composeFileName = "docker-compose.$Environment.yml"
    }

    if (Test-Path $composeFileName) {
        Write-Host "Running compose file $composeFileName"
        docker-compose -f $composeFileName -p $projectName kill
        docker-compose -f $composeFileName -p $projectName up -d
        Write-Host "Compose has completed!"
    }
    else {
        Write-Error -Message "$Environment is not a valid parameter. File '$dockerFileName' does not exist." -Category InvalidArgument
    }
}

# Runs docker-compose stop.
function Stop () {
    $composeFileName = "docker-compose.yml"
    if ($Environment -ne "Release") {
        $composeFileName = "docker-compose.$Environment.yml"
    }

    if (Test-Path $composeFileName) {
        Write-Host "Running compose file $composeFileName with stop"
        docker-compose -f $composeFileName -p $projectName stop
    }
    else {
        Write-Error -Message "$Environment is not a valid parameter. File '$dockerFileName' does not exist." -Category InvalidArgument
    }
}

# Runs docker-compose down.
function Down () {
    $composeFileName = "docker-compose.yml"
    if ($Environment -ne "Release") {
        $composeFileName = "docker-compose.$Environment.yml"
    }

    if (Test-Path $composeFileName) {
        Write-Host "Running compose file $composeFileName with down"
        docker-compose -f $composeFileName -p $projectName down
    }
    else {
        Write-Error -Message "$Environment is not a valid parameter. File '$dockerFileName' does not exist." -Category InvalidArgument
    }
}

# Opens the remote site
function OpenSite () {
    Write-Host "Opening site" -NoNewline
    $status = 0

    #Check if the site is available
    while($status -ne 200) {
        try {
            $response = Invoke-WebRequest -Uri $url -Headers @{"Cache-Control"="no-cache";"Pragma"="no-cache"} -UseBasicParsing
            $status = [int]$response.StatusCode
        }
        catch [System.Net.WebException] { }
        if($status -ne 200) {
            Write-Host "." -NoNewline
            Start-Sleep 1
        }
    }

    Write-Host
    # Open the site.
    Start-Process $url
}

$Environment = $Environment.ToLowerInvariant()

# Call the correct function for the parameter that was used
if($Compose) {
    BuildImage
    Compose
    # OpenSite
}
elseif($ComposeForDebug) {
    $env:REMOTE_DEBUGGING = 1
    BuildImage
    Compose
}
elseif($Build) {
    BuildImage
}
elseif ($Clean) {
    CleanAll
}
elseif ($Down) {
    Down
}
elseif ($Stop) {
    Stop
}
elseif ($Start) {
    Compose
}
elseif ($StartDebugging) {
    $env:REMOTE_DEBUGGING = 1
    Compose
}

Write-Host " "
Write-Host " "
Write-Host "Finished!!!!"