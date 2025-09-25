@echo off
REM S M Fahim Alam's Personal Web App - Windows Deployment Script

setlocal enabledelayedexpansion

set PROJECT_NAME=fahim-personal-app
set DEVELOPER_NAME=S M Fahim Alam
set NAMESPACE=

echo [INFO] CSC Rahti Deployment Script for Windows
echo [INFO] Developer: %DEVELOPER_NAME%
echo.

where oc >nul 2>nul
if %errorlevel% neq 0 (
    echo [ERROR] OpenShift CLI not installed
    pause
    exit /b 1
)

oc whoami >nul 2>nul
if %errorlevel% neq 0 (
    echo [ERROR] Not logged in to OpenShift
    echo [INFO] Please login using: oc login https://api.2.rahti.csc.fi:6443
    pause
    exit /b 1
)

echo [SUCCESS] Prerequisites check passed
echo.

set COMMAND=%1
if not defined COMMAND set COMMAND=deploy

if "%COMMAND%"=="deploy" goto :deploy
if "%COMMAND%"=="build" goto :build
if "%COMMAND%"=="status" goto :status
if "%COMMAND%"=="logs" goto :logs
if "%COMMAND%"=="cleanup" goto :cleanup
if "%COMMAND%"=="help" goto :help

:deploy
echo [INFO] Starting deployment for %DEVELOPER_NAME%'s app...
call :build_image
call :deploy_application
call :wait_for_deployment
call :show_access_info
goto :end

:build_image
echo [INFO] Building Docker image...
if not exist "Dockerfile" (
    echo [ERROR] Dockerfile not found
    exit /b 1
)

oc get imagestream %PROJECT_NAME% >nul 2>nul
if %errorlevel% neq 0 (
    echo [INFO] Creating ImageStream...
    oc create imagestream %PROJECT_NAME%
)

oc get buildconfig %PROJECT_NAME% >nul 2>nul
if %errorlevel% neq 0 (
    echo [INFO] Creating BuildConfig...
    oc new-build --name=%PROJECT_NAME% --binary --strategy=docker
)

echo [INFO] Starting build...
oc start-build %PROJECT_NAME% --from-dir=. --follow
echo [SUCCESS] Image built successfully
goto :eof

:deploy_application
echo [INFO] Deploying application...
powershell -Command "(gc k8s\deployment.yaml) -replace 'NAMESPACE', '%NAMESPACE%' | sc k8s\deployment-updated.yaml"
oc apply -f k8s/configmap.yaml
oc apply -f k8s/deployment-updated.yaml
oc apply -f k8s/service.yaml
oc apply -f k8s/hpa.yaml 2>nul
oc apply -f k8s/storage-and-network.yaml 2>nul
del k8s\deployment-updated.yaml 2>nul
echo [SUCCESS] Application deployed
goto :eof

:wait_for_deployment
echo [INFO] Waiting for deployment...
oc rollout status deployment/%PROJECT_NAME% --timeout=300s
goto :eof

:show_access_info
echo [INFO] Getting access information...
for /f "tokens=*" %%i in ('oc get route %PROJECT_NAME%-route -o jsonpath^="{.spec.host}" 2^>nul') do set ROUTE_URL=%%i

if defined ROUTE_URL (
    echo [SUCCESS] Application accessible at: https://!ROUTE_URL!
    echo [INFO] Name API: https://!ROUTE_URL!/api/name
    echo [INFO] Health check: https://!ROUTE_URL!/health
)
goto :eof

:show_status
echo [INFO] Deployment status:
oc get pods -l app=%PROJECT_NAME%
oc get svc -l app=%PROJECT_NAME%
oc get routes -l app=%PROJECT_NAME%
goto :eof

:logs
echo [INFO] Application logs:
oc logs -l app=%PROJECT_NAME% --tail=100 -f
goto :eof

:cleanup
echo [WARNING] This will delete all resources!
set /p CONFIRM="Continue? (y/N): "
if /i "%CONFIRM%"=="y" (
    oc delete all,configmap,secret,pvc,networkpolicy,hpa -l app=%PROJECT_NAME%
    oc delete imagestream,buildconfig %PROJECT_NAME% 2>nul
)
goto :eof

:help
echo S M Fahim Alam's Personal Web App - Windows Deployment Script
echo Usage: %0 [deploy^|build^|status^|logs^|cleanup^|help]
goto :eof

:end
echo [SUCCESS] Script completed
pause