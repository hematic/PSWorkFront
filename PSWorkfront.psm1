Function Get-WorkfrontSessionID{
    <#
        .SYNOPSIS
        Function to retrieve a session ID for a specific workfront user
        .DESCRIPTION
        This function allows you query the workfront REST API to retrieve a session idea for impersonation.
        .EXAMPLE
        $SessionID = Get-WorkfrontSessionID -APIKey 'XXXXXXXXXXXXXXXXXX' -BaseURI 'company.my.workfront.com' -User 'smithjo'
    #>
    [CmdletBinding(SupportsShouldProcess=$False,ConfirmImpact='Low')]
    Param(
        [Parameter(Mandatory=$True)]
        [String]$APIKey,
        [Parameter(Mandatory=$True)]
        [String]$BaseURI,
        [Parameter(Mandatory=$True)]
        [String]$User
    )

    $URI = "https://$BaseURI/attask/api/v9.0/login?"
    $headers = @{
        "apiKey" = "$APIKey"
        "username" = "$User"
    }

    #region Make API Call
    $Splat = @{
        Method = 'Get'
        URI = $URI
        ContentType = 'application/x-www-form-urlencoded'
        Headers = $headers
    }
    Try{
        $Session = Invoke-WebRequest @Splat -ErrorAction Stop -Verbose
        $ID = $Session.Content | Convertfrom-json | select -ExpandProperty data | Select -ExpandProperty sessionID
        Return $ID
    }
    Catch{
        Write-error $_
    }
    #endregion
}

Function Get-WorkfrontUser {
    <#
        .SYNOPSIS
        Function to retrieve one or more Workfront users
        .DESCRIPTION
        This function allows you query the workfront REST API using various filters to retrieve one or more users.
        .EXAMPLE
        $User = Get-WorkfrontUser -emailAddr 'john.smith@whitecase.com' -apiKey 'XXXXXXXXXXXXXXXXXXXXXXXX' -baseURI 'company.my.workfront.com'
        .EXAMPLE
        $User = Get-WorkfrontUser -firstName 'John' -lastname 'Smith' -apiKey 'XXXXXXXXXXXXXXXXXXXXXXXXX' -baseURI 'company.my.workfront.com'
    #>
    [CmdletBinding(SupportsShouldProcess=$False,ConfirmImpact='Low',DefaultParameterSetName='ByEmail')]
    Param(
        [Parameter(Mandatory=$True,ParameterSetName ='ByEmail')]
        [Parameter(Mandatory=$False)]
        $emailAddr,

        [Parameter(ParameterSetName = 'ByEmail')]
        [Parameter(ParameterSetName = 'ByFirstLast')]
        [Parameter(Mandatory=$True)]
        [String]$apiKey,

        [Parameter(ParameterSetName = 'ByEmail')]
        [Parameter(ParameterSetName = 'ByFirstLast')]
        [Parameter(Mandatory=$True)]
        [String]$baseURI,

        [Parameter(Mandatory=$True,ParameterSetName = 'ByFirstLast')]
        [Parameter(Mandatory=$False)]
        $firstName,

        [Parameter(Mandatory=$True,ParameterSetName = 'ByFirstLast')]
        [Parameter(Mandatory=$False)]
        $lastName
    )

    #region Build URI
    $URI = "https://$BaseURI/attask/api/v9.0/user/search?"
    $Body = @{}
    $headers = @{
        "apiKey" = $apiKey
        '$$LIMIT' = '2000'
    }
    switch ($PsCmdlet.ParameterSetName){
        'ByEmail'{
            $Body.emailAddr = $emailAddr
            $Body.fields = "city,firstName,lastName"
        }
        'ByFirstLast'{
            $Body.firstName = $firstName
            $Body.lastName = $lastName
            $Body.fields = "city,firstName,lastName"
        }
    }
    #endregion
    #region Make API Call
    $Splat = @{
        Method = 'Get'
        Headers = $headers
        Body = $Body
        URI = $URI
        ContentType = 'application/json'
    }
    Try{
        $Users = ((Invoke-WebRequest @Splat -ErrorAction Stop -Verbose).content | ConvertFrom-JSON).data
        Return $Users
    }
    Catch{
        Write-error $_
    }
    #endregion
}

Function Get-WorkfrontTasks {
    <#
        .SYNOPSIS
        Function to retrieve one or more Workfront tasks
        .DESCRIPTION
        This function allows you query the workfront REST API using various filters to retrieve one or more tasks.
        .EXAMPLE
        $Tasks = Get-WorkfrontTasks -status 'INP' -name 'Install ansible' -APIKey 'XXXXXXXXXXXXXXXXXXXXXXXXXX'
        .EXAMPLE
        $Tasks = Get-WorkfrontTasks -AssignedToEmail 'john.smith@company.com' -apiKey 'XXXXXXXXXXXXXXXXXXXXXXXXXX' -baseURI 'company.my.workfront.com'

    #>
    [CmdletBinding(SupportsShouldProcess=$False,ConfirmImpact='Low',DefaultParameterSetName='ByAssignedTo')]
    Param(
        [Parameter(Mandatory=$True,ParameterSetName = 'ByAssignedTo')]
        [String]$AssignedToEmail,

        [Parameter(Mandatory=$True,ParameterSetName = 'ByAssignedTo')]
        [Parameter(Mandatory=$True,ParameterSetName = 'ByFilters')]
        [String]$apiKey,

        [Parameter(Mandatory=$True,ParameterSetName = 'ByAssignedTo')]
        [Parameter(Mandatory=$True,ParameterSetName = 'ByFilters')]
        [String]$baseURI,

        [Parameter(Mandatory=$False,ParameterSetName = 'ByFilters')]
        [String]$ID,

        [Parameter(Mandatory=$False,ParameterSetName = 'ByFilters')]
        [String]$description,

        [Parameter(Mandatory=$False,ParameterSetName = 'ByFilters')]
        [String]$iterationID,

        [Parameter(Mandatory=$False,ParameterSetName = 'ByFilters')]
        [String]$name,

        [Parameter(Mandatory=$False,ParameterSetName = 'ByFilters')]
        [ValidateSet('NEW','INP','CPL','CPA','CPI')]
        [String]$status,

        [Parameter(Mandatory=$False,ParameterSetName = 'ByFilters')]
        [Int]$taskNumber,

        [Parameter(Mandatory=$False,ParameterSetName = 'ByFilters')]
        [String]$teamID
    )

    $headers = @{
        "apiKey" = $apiKey
        '$$LIMIT' = '2000'
    }
    $URI = "https://$BaseURI/attask/api/v9.0/task/search?"

    switch ($PsCmdlet.ParameterSetName){
        'ByAssignedTo'{
            Try{
                $User = Get-WorkfrontUser -emailAddr 'phillip.marshall@whitecase.com' -apiKey $apiKey -baseURI $BaseURI -ErrorAction Stop
            }
            Catch{
                Write-Error $_
            }
            $Body = @{}
            $Body."assignedTo:ID" = $User.ID
        }
        'ByFilters'{
            $Body = @{}
            Foreach($Item in $PSBoundParameters.keys | where-object {$_ -ne "apiKey" -and $_ -ne "baseURI"}){
                $Body.$Item = $PSBoundParameters.Item($Item)
            }
        }
    }
    #region Make API Call
    $Splat = @{
        Method = 'Get'
        Headers = $headers
        Body = $Body
        URI = $URI
        ContentType = 'application/json'
    }
    Try{
        $Tasks = ((Invoke-WebRequest @Splat -ErrorAction Stop -Verbose).content | ConvertFrom-JSON).data
        Return $Tasks
    }
    Catch{
        Write-error $_
    }
    #endregion
}

Function Get-WorkfrontIteration {
    <#
        .SYNOPSIS
        Function to retrieve one or more Workfront iterations
        .DESCRIPTION
        This function allows you query the workfront REST API using various filters to retrieve one or more iterations.
        .EXAMPLE
        $Iterations = Get-WorkfrontIteration -teamName 'team name' -apiKey 'XXXXXXXXXXXXXXXXXXXXXXXXXXXX' -BaseURI 'company.my.workfront.com'
        .EXAMPLE
        $Iterations = Get-WorkfrontIteration -teamName 'team name' -name 'iteration name' -apiKey 'XXXXXXXXXXXXXXXXXXXXXXXXXXXX' -BaseURI 'company.my.workfront.com'
        .EXAMPLE
        $Iterations = Get-WorkfrontIteration -name 'iteration name' -apiKey 'XXXXXXXXXXXXXXXXXXXXXXXXXXXX' -BaseURI 'company.my.workfront.com'

    #>
    [CmdletBinding(SupportsShouldProcess=$False,ConfirmImpact='Low',DefaultParameterSetName='ByName')]
    Param(
        [Parameter(Mandatory=$True,ParameterSetName = 'ByName')]
        [Parameter(Mandatory=$False,ParameterSetName = 'ByTeam')]
        [Parameter(Mandatory=$False)]
        $name,

        [Parameter(Mandatory=$True,ParameterSetName = 'ByTeam')]
        [Parameter(Mandatory=$False)]
        $TeamName,

        [Parameter(Mandatory=$True)]
        [String]$apiKey,

        [Parameter(Mandatory=$True)]
        [String]$baseURI

    )
    $headers = @{
        "apiKey" = $apiKey
        '$$LIMIT' = '2000'
    }
    $Body = @{}
    $Body.fields = 'teamID'
    $URI = "https://$BaseURI/attask/api/v9.0/iteration/search?"

    switch ($PsCmdlet.ParameterSetName){
        'ByName'{
            $Body.name = $name
        }
        'ByTeam'{
            Try{
                $Team = Get-WorkfrontTeam -name $TeamName -apiKey $apiKey -baseURI $baseURI -ErrorAction Stop
                If($Name){
                    $Body.teamID = $Team.ID
                    $Body.name = $name
                }
                Else{
                    $Body.teamID = $Team.ID
                }
            }
            Catch{
                Write-Error $_
            }

        }
    }

    #region Make API Call
    $Splat = @{
        Method = 'Get'
        Body = $Body
        headers = $Headers
        URI = $URI
        ContentType = 'application/json'
    }
    Try{
        $User = ((Invoke-WebRequest @Splat -ErrorAction Stop -Verbose).content | ConvertFrom-JSON).data
        Return $user
    }
    Catch{
        Write-error $_
    }
    #endregion
}

Function Get-WorkfrontTeam {
    <#
        .SYNOPSIS
        Function to retrieve one or more Workfront teams
        .DESCRIPTION
        This function allows you query the workfront REST API using various filters to retrieve one or more teams.
        .EXAMPLE
        $Team = Get-WorkfrontTeam -name 'team Name' -APIKey 'XXXXXXXXXXXXXXXXX' -baseURI 'company.my.workfront.com'

    #>
    [CmdletBinding(SupportsShouldProcess=$False,ConfirmImpact='Low')]
    Param(
        [Parameter(Mandatory=$False)]
        [String]$name,
        [Parameter(Mandatory=$True)]
        [String]$apiKey,
        [Parameter(Mandatory=$True)]
        [String]$baseURI
    )

    $URI = "https://$BaseURI/attask/api/v9.0/team/search?"
    $headers = @{
        "apiKey" = $apiKey
        '$$LIMIT' = '2000'
    }
    $Body = @{
        name = $name
    }

    #region Make API Call
    $Splat = @{
        Method = 'Get'
        Headers = $headers
        Body = $Body
        URI = $URI
        ContentType = 'application/json'
    }
    Try{
        $Team = ((Invoke-WebRequest @Splat -ErrorAction Stop -Verbose).content | ConvertFrom-JSON).data
        Return $Team
    }
    Catch{
        Write-error $_
    }
    #endregion
}

Function Get-WorkfrontTimeSheet {
    <#
        .SYNOPSIS
        Function to retrieve one or more Workfront timesheets
        .DESCRIPTION
        This function allows you query the workfront REST API using various filters to retrieve one or more timesheets.
        .EXAMPLE
        Get-WorkfrontTimeSheet -ID '5bcc1686009f5e785b4829a0c80f8190' -APIKey 'XXXXXXXXXXXXXXXXXXXXX'
        .EXAMPLE
        $TimeSheet = Get-WorkfrontTimeSheet -ID '5bcc1686009f5e785b4829a0c80f8190' -APIKey 'XXXXXXXXXXXXXXXXXXXXX' -baseURI 'company.my.workfront.com' -Hours
        .EXAMPLE
        $TimeSheets = Get-WorkfrontTimeSheet -userID '5731f646002798c3bdd7f83761f4c95a' -APIKey 'XXXXXXXXXXXXXXXXXXXXX' -baseURI 'company.my.workfront.com'
        .EXAMPLE
        $TimeSheets = Get-WorkfrontTimeSheet -startDate '2018-10-21' -endDate '2018-10-27' -APIKey 'XXXXXXXXXXXXXXXXXXXXX' -baseURI 'company.my.workfront.com'
    #>
    [CmdletBinding(SupportsShouldProcess=$False,ConfirmImpact='Low',DefaultParameterSetName='ByID')]
    Param(
        [Parameter(Mandatory=$True,ParameterSetName = 'ByID')]
        [Parameter(Mandatory=$False)]
        [String]$ID,

        [Parameter(Mandatory=$False,ParameterSetName = 'ByID')]
        [Switch]$Hours,

        [Parameter(Mandatory=$True,ParameterSetName = 'ByUserID')]
        [Parameter(Mandatory=$False)]
        [String]$userID,

        [Parameter(Mandatory=$True,ParameterSetName = 'ByDate')]
        [Parameter(Mandatory=$False)]
        [DateTime]$endDate,
        [Parameter(Mandatory=$False)]
        [datetime]$startDate,

        [Parameter(Mandatory=$True)]
        [String]$apiKey,

        [Parameter(Mandatory=$True)]
        [String]$baseURI
    )

    #region Build URI
    $URI = "https://$baseURI/attask/api/v9.0/timesheet/search?"
    $headers = @{
        "apiKey" = $apiKey
        '$$LIMIT' = '2000'
    }
    $Body = @{}
    switch ($PsCmdlet.ParameterSetName){
        'ByID'{
            if($Hours){
                $Body.fields = 'hours'
                $Body.ID = $ID
            }
            Else{
                $Body.ID = $ID
            }
        }
        'ByUserID'{
            $Body.userID = $userID
        }
        'ByDate'{
            $Body.startDate = $startDate
            $Body.endDate = $endDate
        }
    }
    #endregion
    #region Make API Call
    $Splat = @{
        Method = 'Get'
        Headers = $headers
        Body = $Body
        URI = $URI
        ContentType = 'application/json'
    }
    Try{
        $User = ((Invoke-WebRequest @Splat -ErrorAction Stop -Verbose).content | ConvertFrom-JSON).data
        Return $user
    }
    Catch{
        Write-error $_
    }
    #endregion
}

Function New-WorkfrontTimeEntry {
    <#
        .SYNOPSIS
        Function to post a WorkFront Time Entry
        .DESCRIPTION
        This function allows you post to the workfront REST API to create a new time entry.
        .EXAMPLE
        $TimeSheets = New-WorkfrontTimeEntry -sessionID $SessionID -baseURI 'company.my.workfront.com' -description 'Test Automated Entry' -hours 1.5 -entryDate '2018-10-30' -taskID '5a8c7a2b0538b78fc76198501a2bf751'
    #>
    [CmdletBinding(SupportsShouldProcess=$False,ConfirmImpact='Low')]
    Param(
        [Parameter(Mandatory=$True)]
        [String]$sessionID,
        [Parameter(Mandatory=$True)]
        [String]$baseURI,
        [Parameter(Mandatory=$False)]
        [String]$description,
        [Parameter(Mandatory=$False)]
        [String]$entryDate,
        [Parameter(Mandatory=$False)]
        [Double]$hours,
        [Parameter(Mandatory=$False)]
        [String]$projectID,
        [Parameter(Mandatory=$False)]
        [string]$taskID,
        [Parameter(Mandatory=$False)]
        [string]$timesheetID
    )

    $URI = "https://$baseURI/attask/api/v9.0/hour?"
    $headers = @{
        sessionID = $sessionID
    }
    $Body = @{}
    Foreach($Item in $PSBoundParameters.keys | Where-Object {$_ -ne 'baseuri' -and $_ -ne 'sessionID'}){
        $Body.$Item = $PSBoundParameters.Item($Item)
    }

    $Splat = @{
        Method = 'Post'
        Headers = $headers
        Body = $Body
        URI = $URI
    }
    Try{
        $TimeEntry = ((Invoke-WebRequest @Splat -ErrorAction Stop -Verbose).content | ConvertFrom-JSON).data
        Return $TimeEntry
    }
    Catch{
        Write-error $_
    }

}