SETLOCAL EnableExtensions

:: Bypass installing the agent and server monitor if locally emulating
IF "%EMULATED%" EQU "true" GOTO:EOF

FOR /F "usebackq tokens=1,2 delims==" %%i in (`wmic os get LocalDateTime /VALUE 2^>NUL`) do IF '.%%i.'=='.LocalDateTime.' SET ldt=%%j
SET ldt=%ldt:~0,4%-%ldt:~4,2%-%ldt:~6,2% %ldt:~8,2%:%ldt:~10,2%:%ldt:~12,6%

SET NR_ERROR_LEVEL=0

SET NR_IDCOUNT=0
:SET_NR_INSTALL_ID
SET NR_INSTALLID=%RANDOM%
IF EXIST "%RoleRoot%\nr-%NR_INSTALLID%.log" (
    IF %NR_IDCOUNT% LEQ 50 (
        SET /A NR_IDCOUNT=NR_IDCOUNT+1
        GOTO:SET_NR_INSTALL_ID
    ) ELSE (
        ECHO Warning: Unable to find a free ID for MSI install logs, overwriting ID %NR_INSTALLID%. 
    )
)

SET >> "%RoleRoot%\nrset-%NR_INSTALLID%.log" 2>&1

CALL:INSTALL_NEWRELIC_AGENT
CALL:INSTALL_NEWRELIC_INFRA_AGENT

IF %NR_ERROR_LEVEL% EQU 0 (
    EXIT /B 0
) ELSE (
    REM EXIT %NR_ERROR_LEVEL%
    EXIT /B 0
)

:: --------------
:: Functions
:: --------------
:INSTALL_NEWRELIC_AGENT
    ECHO %ldt% : Begin installing the New Relic .NET Agent. >> "%RoleRoot%\nr-%NR_INSTALLID%.log" 2>&1

    :: Current version of the installer
    SET NR_INSTALLER_NAME=NewRelicAgent_x64_8.22.181.0.msi
    :: Path used for custom configuration and worker role environment varibles
    SET NR_HOME=%ALLUSERSPROFILE%\New Relic\.NET Agent\

    ECHO Installing the New Relic .NET Agent. >> "%RoleRoot%\nr-%NR_INSTALLID%.log" 2>&1

    IF "%IsWorkerRole%" EQU "true" (
        msiexec.exe /i %NR_INSTALLER_NAME% /norestart /quiet NR_LICENSE_KEY=%LICENSE_KEY% INSTALLLEVEL=50 /lv* %RoleRoot%\nr_install-%NR_INSTALLID%.log
    ) ELSE (
        msiexec.exe /i %NR_INSTALLER_NAME% /norestart /quiet NR_LICENSE_KEY=%LICENSE_KEY% /lv* %RoleRoot%\nr_install-%NR_INSTALLID%.log
    )

    :: WEB ROLES : Restart the service to pick up the new environment variables
    :: 	if we are in a Worker Role then there is no need to restart W3SVC _or_
    :: 	if we are emulating locally then do not restart W3SVC
    IF "%IsWorkerRole%" EQU "false" (
        ECHO Restarting IIS and W3SVC to pick up the new environment variables. >> "%RoleRoot%\nr-%NR_INSTALLID%.log" 2>&1
        IISRESET
        NET START W3SVC
        ECHO IIS restarted >> "%RoleRoot%\nr-%NR_INSTALLID%.log" 2>&1
    )

    ECHO ERRORLEVEL %ERRORLEVEL% >> "%RoleRoot%\nr-%NR_INSTALLID%.log" 2>&1

    REM ECHO Replacing webconfig >> "%RoleRoot%\nr-%NR_INSTALLID%.log" 2>&1
    REM ECHO replacing webconfig -File "%RoleRoot%\approot\replacewebconfig.ps1" -WebConfigPath "E:\sitesroot\0\Web.config" -NRLicenseKey %LICENSE_KEY% -NRAppName "%APP_NAME%" -NREnabled %ENABLED% >> "%RoleRoot%\nr-%NR_INSTALLID%.log" 2>&1
    REM powershell -ExecutionPolicy Unrestricted -File "%RoleRoot%\approot\replacewebconfig.ps1" -WebConfigPath "E:\sitesroot\0\Web.config" -NRLicenseKey %LICENSE_KEY% -NRAppName "%APP_NAME%" -NREnabled %ENABLED%  >> "%RoleRoot%\nr-%NR_INSTALLID%.log" 2>&1
      
    IF %ERRORLEVEL% EQU 0 (
      powershell -File "%RoleRoot%\approot\ConvertNewRelicConfig.ps1" -OriginalPath "%RoleRoot%\approot\newrelic.config.template" -SavePath "%NR_HOME%\newrelic.config" -NRLicenseKey %LICENSE_KEY% -NRAppName "%APP_NAME%" -NREnabled %ENABLED%
      REM  The New Relic .NET Agent installed ok and does not need to be installed again.
      ECHO New Relic .NET Agent was installed successfully. >> "%RoleRoot%\nr-%NR_INSTALLID%.log" 2>&1

    ) ELSE (
      REM   An error occurred. Log the error to a separate log and exit with the error code.
      ECHO  An error occurred installing the New Relic .NET Agent 1. Errorlevel = %ERRORLEVEL%. >> "%RoleRoot%\nr_error-%NR_INSTALLID%.log" 2>&1

      SET NR_ERROR_LEVEL=%ERRORLEVEL%
    )

    ECHO Checking for registry keys after installation >> "%RoleRoot%\nr-%NR_INSTALLID%.log" 2>&1
    REG QUERY HKLM\SYSTEM\CurrentControlSet\Services\W3SVC /v Environment >> "%RoleRoot%\nr-%NR_INSTALLID%.log" 2>&1
    REG QUERY HKLM\SYSTEM\CurrentControlSet\Services\WAS /v Environment >> "%RoleRoot%\nr-%NR_INSTALLID%.log" 2>&1

GOTO:EOF

:INSTALL_NEWRELIC_INFRA_AGENT
    ECHO %ldt% : Begin installing the New Relic Infra Agent. >> "%RoleRoot%\nri-%NR_INSTALLID%.log" 2>&1

    :: Current version of the installer
    SET NR_INSTALLER_NAME=newrelic-infra.msi

    ECHO Installing the New Relic .NET Agent. >> "%RoleRoot%\nri-%NR_INSTALLID%.log" 2>&1

    msiexec.exe /qn /i %NR_INSTALLER_NAME% GENERATE_CONFIG=true DISPLAY_NAME=WorkerRole1 LICENSE_KEY=%LICENSE_KEY% /lv* %RoleRoot%\nri_install-%NR_INSTALLID%.log

    ECHO license_key: %LICENSE_KEY% > "%ProgramFiles%\New Relic\newrelic-infra\newrelic-infra.yml"
    REM ECHO display_name: "Worker Role" >> "%ProgramFiles%\New Relic\newrelic-infra\newrelic-infra.yml"
    NET STOP newrelic-infra
    NET START newrelic-infra

    IF %ERRORLEVEL% EQU 0 (
        ECHO New Relic Infra Agent was installed successfully. >> "%RoleRoot%\nri-%NR_INSTALLID%.log" 2>&1

    ) ELSE (
        ECHO  An error occurred installing the New Relic Infra Agent 1. Errorlevel = %ERRORLEVEL%. >> "%RoleRoot%\nri_error-%NR_INSTALLID%.log" 2>&1

        SET NR_ERROR_LEVEL=%ERRORLEVEL%
    )
GOTO:EOF