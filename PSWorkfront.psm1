Function Get-WorkfrontSessionID{
        <#
        .SYNOPSIS
        Function to retrieve a session ID for a specific workfront user
        .DESCRIPTION
        This function allows you query the workfront REST API to retrieve a sessionID for impersonation.
        .EXAMPLE
        $Splat = @{
            apiKey = 'XXXXXXXXXXXXXXXXXXXXXXXXXXXXX'
            baseURL = company.my.workfront.com
            user = 'marshph'
        }
        $SessionID = Get-WorkfrontSessionID @Splat
    #>
    [CmdletBinding(SupportsShouldProcess=$False,ConfirmImpact='Low')]
    Param(
        [Parameter(Mandatory=$True)]
        [ValidateNotNullOrEmpty()]
        [String]$apiKey,
        [Parameter(Mandatory=$True)]
        [ValidateNotNullOrEmpty()]
        [String]$baseURL,
        [Parameter(Mandatory=$True)]
        [ValidateNotNullOrEmpty()]
        [String]$User
    )

    $URI = "https://$baseURL/attask/api/v9.0/login?"
    $headers = @{
        "apiKey" = "$apiKey"
        "username" = "$User"
    }

    #region Make API Call
    $Splat = @{
        Method = 'get'
        URI = $URI
        ContentType = 'application/x-www-form-urlencoded'
        Headers = $headers
    }
    Try{
        $Session = Invoke-WebRequest @Splat -ErrorAction Stop -Verbose
        $ID = $Session.Content | Convertfrom-json | Select-Object -ExpandProperty data | Select-Object -ExpandProperty sessionID
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
        $Splat = @{
            emailAddr = 'john.smith@company.com'
            baseURL = company.my.workfront.com
            apiKey = 'XXXXXXXXXXXXXXXXXXXXX'
        }
        $User = Get-WorkfrontUser @Splat
        .EXAMPLE
        $Splat = @{
            firstName = 'John' #Case Sensitive
            lastName = "Smith" #Case Sensitive
            baseURL = company.my.workfront.com
            apiKey = 'XXXXXXXXXXXXXXXXXXXXX'
        }
        $User = Get-WorkfrontUser @Splat
    #>
    [CmdletBinding(SupportsShouldProcess=$False,ConfirmImpact='Low',DefaultParameterSetName='ByEmail')]
    Param(
        [Parameter(Mandatory=$True,ParameterSetName = 'ByEmail')]
        [Parameter(Mandatory=$False)]
        $emailAddr,

        [Parameter(Mandatory=$True,ParameterSetName = 'ByFirstLast')]
        [Parameter(Mandatory=$False)]
        $firstName,

        [Parameter(Mandatory=$True,ParameterSetName = 'ByFirstLast')]
        [Parameter(Mandatory=$False)]
        $lastName,

        [Parameter(Mandatory=$True)]
        [ValidateNotNullOrEmpty()]
        [String]$apiKey,

        [Parameter(Mandatory=$True)]
        [ValidateNotNullOrEmpty()]
        [String]$baseURL
    )

    #region Build URI
    $URI = "https://$baseURL/attask/api/v9.0/user/search?"
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
        $User = ((Invoke-WebRequest @Splat -ErrorAction Stop -Verbose).content | ConvertFrom-JSON).data
        Return $user
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
        $Splat = @{
            assignedtoEmail = 'john.smith@outlook.com'
            apiKey = 'XXXXXXXXXXXXXXXXXX'
            baseURL = 'company.my.workfront.com'
        }
        $Tasks = Get-WorkfrontTasks @Splat
        .EXAMPLE
        $Splat = @{
            status = 'INP'
            name  = 'Install ansible' #Case Sensitive
            apiKey = 'XXXXXXXXXXXXXXXXXX'
            baseURL = 'company.my.workfront.com'
        }
        $Tasks = Get-WorkfrontTasks @Splat
    #>
    [CmdletBinding(SupportsShouldProcess=$False,ConfirmImpact='Low',DefaultParameterSetName='ByAssignedTo')]
    Param(
        [Parameter(Mandatory=$True,ParameterSetName = 'ByAssignedTo')]
        [Parameter(Mandatory=$False)]
        [String]$AssignedToEmail,

        [Parameter(Mandatory=$False,ParameterSetName = 'ByFilters')]
        [Parameter(Mandatory=$False)]
        [String]$ID,

        [Parameter(Mandatory=$False,ParameterSetName = 'ByFilters')]
        [Parameter(Mandatory=$False)]
        [String]$description,

        [Parameter(Mandatory=$False,ParameterSetName = 'ByFilters')]
        [Parameter(Mandatory=$False)]
        [String]$iterationID,

        [Parameter(Mandatory=$False,ParameterSetName = 'ByFilters')]
        [Parameter(Mandatory=$False)]
        [String]$name,

        [Parameter(Mandatory=$False,ParameterSetName = 'ByFilters')]
        [Parameter(Mandatory=$False)]
        [ValidateSet('NEW','INP','CPL','CPA','CPI')]
        [String]$status,

        [Parameter(Mandatory=$False,ParameterSetName = 'ByFilters')]
        [Parameter(Mandatory=$False)]
        [Int]$taskNumber,

        [Parameter(Mandatory=$False,ParameterSetName = 'ByFilters')]
        [Parameter(Mandatory=$False)]
        [String]$teamID,

        [Parameter(Mandatory=$True)]
        [ValidateNotNullOrEmpty()]
        [String]$apiKey,

        [Parameter(Mandatory=$True)]
        [ValidateNotNullOrEmpty()]
        [String]$baseURL
    )

    $headers = @{
        "apiKey" = $apiKey
        '$$LIMIT' = '2000'
    }
    $URI = "https://$baseURL/attask/api/v9.0/task/search?"

    switch ($PsCmdlet.ParameterSetName){
        'ByAssignedTo'{
            Try{
                $Splat = @{
                    emailAddr = $AssignedToEmail
                    apiKey = $apiKey
                    baseURL = $baseURL
                }
                $User = Get-WorkfrontUser @Splat -ErrorAction Stop
            }
            Catch{
                Write-Error $_
            }

            $Body = @{}
            $Body."assignedTo:ID" = $User.ID
        }

        'ByFilters'{
            $Body = @{}
            Foreach($Item in $($PSBoundParameters.keys | Where-Object {$_ -ne 'apikey' -and $_ -ne 'baseURL'})){
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
        $Splat = @{
            name = 'Oct - 2018'
            apiKey = 'XXXXXXXXXXXXXXXXXX'
            baseURL = 'company.my.workfront.com'
        }
        $Tasks = Get-WorkfrontIteration @Splat
        .EXAMPLE
        $Splat = @{
            teamID  = '5476515d003f132072e56a42a76ba6e9' 
            name  = 'Oct - 2018'
            apiKey = 'XXXXXXXXXXXXXXXXXX'
            baseURL = 'company.my.workfront.com'
        }
        $Tasks = Get-WorkfrontIteration @Splat
        .EXAMPLE
        $Splat = @{
            teamID = '5476515d003f132072e56a42a76ba6e9'
            apiKey = 'XXXXXXXXXXXXXXXXXX'
            baseURL = 'company.my.workfront.com'
        }
        $Tasks = Get-WorkfrontIteration @Splat
        .EXAMPLE
        $Splat = @{
            teamName 'Automation and Monitoring Team (Agile)' #Case Sensitive
            name  = 'Oct - 2018'
            apiKey = 'XXXXXXXXXXXXXXXXXX'
            baseURL = 'company.my.workfront.com'
        }
        $Tasks = Get-WorkfrontIteration @Splat
    #>
    [CmdletBinding(SupportsShouldProcess=$False,ConfirmImpact='Low',DefaultParameterSetName='ByName')]
    Param(
        [Parameter(Mandatory=$True,ParameterSetName = 'ByName')]
        [Parameter(Mandatory=$False,ParameterSetName = 'ByTeam')]
        [Parameter(Mandatory=$False)]
        $name,

        [Parameter(Mandatory=$False,ParameterSetName = 'ByTeam')]
        [Parameter(Mandatory=$False)]
        $TeamName,

        [Parameter(Mandatory=$False,ParameterSetName = 'ByTeam')]
        [Parameter(Mandatory=$False)]
        $teamID,

        [Parameter(Mandatory=$True)]
        [ValidateNotNullOrEmpty()]
        [String]$apiKey,

        [Parameter(Mandatory=$True)]
        [ValidateNotNullOrEmpty()]
        [String]$baseURL
    )
    $headers = @{
        "apiKey" = $apiKey
        '$$LIMIT' = '2000'
    }
    $Body = @{}
    $Body.fields = 'teamID'
    $URI = "https://$baseURL/attask/api/v9.0/iteration/search?"

    switch ($PsCmdlet.ParameterSetName){
        'ByName'{
            $Body.name = $name
        }
        'ByTeam'{
            If($TeamID){
                Foreach($Item in $PSBoundParameters.keys | Where-object {$_ -ne 'TeamName' -and -$_ -ne 'apiKey' -and $_ -ne 'baseURL'}){
                    $Body.$Item = $PSBoundParameters.Item($Item)
                }
            }
            Else{
                Try{
                    $Team = Get-WorkfrontTeam -name $TeamName -ErrorAction Stop
                    If($TeamName){
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
        $Splat = @{
            name = 'Automation and Monitoring Team (Agile)' #Case Sensitive
            apiKey = 'XXXXXXXXXXXXXXXXXX'
            baseURL = 'company.my.workfront.com'
        }
        $Tasks = Get-WorkfrontTeam @Splat        
    #>
    [CmdletBinding(SupportsShouldProcess=$False,ConfirmImpact='Low')]
    Param(
        [Parameter(Mandatory=$False)]
        [String]$name,

        [Parameter(Mandatory=$True)]
        [ValidateNotNullOrEmpty()]
        [String]$apiKey,

        [Parameter(Mandatory=$True)]
        [ValidateNotNullOrEmpty()]
        [String]$baseURL
    )

    $URI = "https://$baseURL/attask/api/v9.0/team/search?"
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
        $Splat = @{
            ID = '5bcc1686009f5e785b4829a0c80f8190'
            apiKey = 'XXXXXXXXXXXXXXXXXXXXXXX'
            baseURL = 'company.my.workfront.com'
        }
        Get-WorkfrontTimeSheet @Splat
        .EXAMPLE
        $Splat = @{
            ID = '5bcc1686009f5e785b4829a0c80f8190'
            Hours = $True
            apiKey = 'XXXXXXXXXXXXXXXXXXXXXXX'
            baseURL = 'company.my.workfront.com'
        }
        Get-WorkfrontTimeSheet @Splat
        .EXAMPLE
        $Splat = @{
            userID = '5731f646002798c3bdd7f83761f4c95a'
            apiKey = 'XXXXXXXXXXXXXXXXXXXXXXX'
            baseURL = 'company.my.workfront.com'
        }
        Get-WorkfrontTimeSheet @Splat
        .EXAMPLE
        $Splat = @{
            startDate = '2018-10-21'
            endDate = '2018-10-27'
            apiKey = 'XXXXXXXXXXXXXXXXXXXXXXX'
            baseURL = 'company.my.workfront.com'
        }
        Get-WorkfrontTimeSheet @Splat
    #>
    [CmdletBinding(SupportsShouldProcess=$False,ConfirmImpact='Low',DefaultParameterSetName='ByID')]
    Param(
        [Parameter(Mandatory=$True,ParameterSetName = 'ByID')]
        [Parameter(Mandatory=$False)]
        [String]$ID,

        [Parameter(Mandatory=$False)]
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
        [ValidateNotNullOrEmpty()]
        [String]$apiKey,

        [Parameter(Mandatory=$True)]
        [ValidateNotNullOrEmpty()]
        [String]$baseURL
    )

    #region Build URI
    $URI = "https://$baseURL/attask/api/v9.0/timesheet/search?"
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
        $Splat = @{
            sessionID = $SessionID
            description = 'This is a description of the time entry.'
            hours = 1.5
            entryDate = '2018-10-30'
            taskID = '5a8c7a2b0538b78fc76198501a2bf751'
        }
        $TimeEntry = New-WorkfrontTimeEntry @Splat
    #>
    [CmdletBinding(SupportsShouldProcess=$False,ConfirmImpact='Low')]
    Param(
        [Parameter(Mandatory=$True)]
        [String]$sessionID,

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
        [string]$timesheetID,

        [Parameter(Mandatory=$True)]
        [ValidateNotNullOrEmpty()]
        [String]$baseURL
    )

    #region Build URI
    $baseURI = "https://$baseURL/attask/api/v9.0/hour?"
    $SessionString = "&sessionID=$sessionID"
    [String]$Script:FieldBody = ''
    Foreach($Item in $($PSBoundParameters.keys | Where-Object {$_ -ne 'sessionID' -and $_ -ne 'baseURL'})){
        If($Script:FieldBody -eq ''){
            $Script:FieldBody = $Script:FieldBody + $Item + '=' + $($PSBoundParameters.Item($Item))
        }
        Else{
            $Script:FieldBody = $Script:FieldBody + '&' + $Item + '=' + $($PSBoundParameters.Item($Item))
        }
    }

    $URI = $baseURI + $Script:FieldBody + $SessionString
    #endregion

    #region Make API Call

    $Splat = @{
        Method = 'Post'
        URI = $URI
        ContentType = 'application/x-www-form-urlencoded'
    }
    Try{
        $TimeEntry = ((Invoke-WebRequest @Splat -ErrorAction Stop -Verbose).content | ConvertFrom-JSON).data
        Return $TimeEntry
    }
    Catch{
        Write-error $_
    }
    #endregion

}
