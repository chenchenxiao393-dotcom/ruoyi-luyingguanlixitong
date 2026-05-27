@echo off
chcp 65001 >nul
title 若依项目启动脚本

echo ================================================
echo         若依 RuoYi-Vue 一键启动脚本
echo ================================================
echo.

:: ------------------------------------------------
:: 1. 环境校验
:: ------------------------------------------------
echo [1/4] 检查运行环境...
echo.

:: 检查 Java
where java >nul 2>&1
if %errorlevel% neq 0 (
    echo [错误] 未检测到 Java，请安装 JDK 8 或以上版本
    pause
    exit /b 1
) else (
    echo [OK] Java 已安装
)

:: 检查 Maven
where mvn >nul 2>&1
if %errorlevel% neq 0 (
    echo [错误] 未检测到 Maven，请安装 Maven 3.x 并配置环境变量
    pause
    exit /b 1
) else (
    echo [OK] Maven 已安装
)

:: 检查 Node.js
where node >nul 2>&1
if %errorlevel% neq 0 (
    echo [错误] 未检测到 Node.js，请安装 Node.js 8.9 或以上版本
    pause
    exit /b 1
) else (
    for /f %%v in ('node -v') do echo [OK] Node.js 已安装: %%v
)

:: 检查 npm
where npm >nul 2>&1
if %errorlevel% neq 0 (
    echo [错误] 未检测到 npm
    pause
    exit /b 1
) else (
    for /f %%v in ('npm -v') do echo [OK] npm 已安装: %%v
)

:: 检查 Redis
redis-cli ping >nul 2>&1
if %errorlevel% neq 0 (
    echo [警告] Redis 未运行，后端启动后可能连接失败，请确保 Redis 已启动
) else (
    echo [OK] Redis 运行中
)

echo.

:: ------------------------------------------------
:: 2. 后端依赖校验
:: ------------------------------------------------
echo [2/4] 检查后端依赖...
echo.

set RUOYI_JAR=%~dp0ruoyi-admin\target\ruoyi-admin.jar
if exist "%RUOYI_JAR%" (
    echo [OK] 后端已编译，跳过 Maven 构建
) else (
    echo [构建] 未检测到编译产物，正在执行 mvn clean install -DskipTests ...
    call mvn clean install -DskipTests -f "%~dp0pom.xml"
    if %errorlevel% neq 0 (
        echo [错误] Maven 构建失败，请检查错误信息
        pause
        exit /b 1
    )
    echo [OK] 后端构建完成
)

echo.

:: ------------------------------------------------
:: 3. 前端依赖校验
:: ------------------------------------------------
echo [3/4] 检查前端依赖...
echo.

set UI_DIR=%~dp0ruoyi-ui
if exist "%UI_DIR%\node_modules" (
    echo [OK] node_modules 已存在，跳过 npm install
) else (
    echo [安装] 未检测到 node_modules，正在执行 npm install ...
    pushd "%UI_DIR%"
    call npm install
    if %errorlevel% neq 0 (
        echo [错误] npm install 失败，请检查错误信息
        popd
        pause
        exit /b 1
    )
    popd
    echo [OK] 前端依赖安装完成
)

echo.

:: ------------------------------------------------
:: 4. 启动项目
:: ------------------------------------------------
echo [4/4] 启动项目...
echo.

echo [启动] 后端服务 (端口 8080) ...
start "RuoYi-Backend" cmd /k "cd /d %~dp0 && mvn spring-boot:run -pl ruoyi-admin"

timeout /t 3 /nobreak >nul

echo [启动] 前端服务 (端口 80) ...
start "RuoYi-Frontend" cmd /k "cd /d %UI_DIR% && npm run dev"

echo.
echo ================================================
echo  后端: http://localhost:8080
echo  前端: http://localhost:80
echo  账号: admin / admin123
echo ================================================
echo.
echo 两个服务已在独立窗口中启动，请等待启动完成后访问前端地址。
echo 关闭对应窗口即可停止服务。
echo.
pause
