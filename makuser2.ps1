#$fileinput = Get-Childitem -Path (read-host "Please enter file path")

$xml = [xml](Get-Content .\user.xml)

$users = $xml.root.user

foreach ($user in $users) {
    # create OU if it does not exist
    $ou = $user.ou

    Write-Host "Testing '$ou'"
    $ouexist = Get-ADOrganizationalUnit -Filter "name -eq '$ou'"

    if ($ouexist -eq $null) {
        New-ADOrganizationalUnit -Name $ou -Path "DC=esage2,DC=US"
        Write-Host "OU '$ou' has been created"
    } else {
        Write-Host "OU '$ou' already exists"
    }

    $username = $user.account
    $fname = $user.firstname
    $lname = $user.lastname
    $desc = $user.description
    $password = $user.password

    Write-Host "Testing user '$fname'"

    # check to see if the user exists
    $userexist = Get-ADUser -Filter "SamAccountName -eq '$username'"

    if ($userexist -eq $null) {
        New-ADUser -Name $username -SamAccountName $username -GivenName $fname -Surname $lname -Description $desc -AccountPassword (ConvertTo-SecureString $password -AsPlainText -Force) -Path "DC=esage2,DC=US"
        Write-Host "User '$username' has been created"
    } else {
        Write-Host "User '$username' already exists"
    }

    # check to see if the member of group exists
    foreach ($group in $user.memberOf) {

        $group = $user.memberOf.group
        # set current group name (should loop through names)
        $groupexist = Get-ADGroup -Filter "Name -eq '$group'"
        
        if ($groupexist -eq $null) {
            New-ADGroup -Name $group -SamAccountName $group -GroupScope DomainLocal -Path "DC=esage2,DC=US"
            Write-Host "Group '$group' has been created"
        } else {
            Write-Host "Group '$group' already exists"
        }

        # check to see if the user is a member of listed groups and add to them if not already there
        if ((Get-ADGroupMember -Identity $group -Recursive | Select-Object -ExpandProperty SamAccountName) -contains $username) {
            Write-Host "User '$username' is already a member of '$group'"
        } else { 
            Add-ADGroupMember -Identity $group -Members $username
            Write-Host "User '$username' added to group '$group'"
        }
    }
}
