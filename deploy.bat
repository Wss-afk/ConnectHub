@echo off
chcp 65001 >nul
setlocal

set ROOT=%~dp0
set FRONTEND=%ROOT%chatroom_frontend
set BACKEND=%ROOT%chatroom_backend
set STATIC=%BACKEND%\src\main\resources\static

echo ============================================
echo   ConnectHub - 一键构建部署
echo ============================================
echo.

:: Step 1: 构建前端
echo [1/4] 构建前端...
cd /d "%FRONTEND%"
call npm run build
if %ERRORLEVEL% neq 0 (
    echo [ERROR] 前端构建失败！
    pause
    exit /b 1
)
echo [OK] 前端构建完成
echo.

:: Step 2: 复制 dist 到后端 static
echo [2/4] 复制 dist/ 到后端 static/...
if exist "%STATIC%" (
    rmdir /S /Q "%STATIC%"
)
xcopy /E /Y /Q "%FRONTEND%\dist\*" "%STATIC%\"
if %ERRORLEVEL% neq 0 (
    echo [ERROR] 复制文件失败！
    pause
    exit /b 1
)
echo [OK] 文件复制完成
echo.

:: Step 3: 构建后端 JAR
echo [3/4] 构建后端 JAR...
cd /d "%BACKEND%"
call mvn package -DskipTests -q
if %ERRORLEVEL% neq 0 (
    echo [ERROR] 后端构建失败！
    pause
    exit /b 1
)
echo [OK] JAR 构建完成
echo.

:: Step 4: 启动服务
echo [4/4] 启动服务...
echo ============================================
echo   部署成功！正在启动...
echo   访问: http://localhost:8080
echo   按 Ctrl+C 停止服务
echo ============================================
echo.
cd /d "%BACKEND%"
java -jar target\chatroom-backend-1.0.0.jar
