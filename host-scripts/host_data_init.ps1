$HostDataRoot = "C:\vagrant\host-data"
$NewHost = 0

If (-not (Test-Path $HostDataRoot\$Env:MACHINE_NAME)) {
  mkdir $HostDataRoot\$Env:MACHINE_NAME\etc-salt
  $NewHost = 1
}

#
# Stop the salt-minion service to avoid any potential
# errors while moving things around such as "In Use"
# errors (or, as Windows frustratingly and ambiguously
# calls them, "Access Denied" errors)
#
Stop-Service salt-minion

if ($NewHost -eq 1) {
  #
  # Make sure we can copy over the minion keys
  #
  icacls C:\salt\conf\pki\minion /grant "everyone:(OI)(CI)(F)"
  #
  # Use copy since Move will create an impossible-to-solve trail
  # of "access denied" errors.
  #
  cp -R C:\salt\conf\* $HostDataRoot\$Env:MACHINE_NAME\etc-salt\
}

#
# Replace the minion's configuration with those copied over to the
# guest. This allows the host system to reuse a now-destroyed windows
# minion's state.
#
rm C:\salt\conf -r -Force
cmd /c mklink /d C:\salt\conf $HostDataRoot\$Env:MACHINE_NAME\etc-salt

#
# Restart the salt-minion service now that everything should be set
#
Restart-Service -Name salt-minion