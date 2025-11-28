# 快速启动脚本 - Windows PowerShell

Write-Host "Course Schedule Management System - 快速启动" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Green

# 检查Docker是否安装
try {
    $dockerVersion = docker --version
    Write-Host "✅ Docker已安装: $dockerVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ 请先安装Docker Desktop" -ForegroundColor Red
    exit 1
}

# 检查Docker Compose是否可用
try {
    $composeVersion = docker-compose --version
    Write-Host "✅ Docker Compose已安装: $composeVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ 请先安装Docker Compose" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "选择启动方式:" -ForegroundColor Yellow
Write-Host "1. 完整容器化启动（推荐）" -ForegroundColor Cyan
Write-Host "2. 仅启动数据库服务" -ForegroundColor Cyan
Write-Host "3. 仅构建后端项目" -ForegroundColor Cyan
Write-Host "4. 停止所有服务" -ForegroundColor Cyan
Write-Host ""

$choice = Read-Host "请输入选择 (1-4)"

switch ($choice) {
    "1" {
        Write-Host "🚀 启动完整系统..." -ForegroundColor Green
        
        # 构建并启动所有服务
        Write-Host "📦 构建Maven项目..." -ForegroundColor Yellow
        cd server/api
        ./mvnw clean package -DskipTests
        cd ../..
        
        Write-Host "🐳 启动Docker服务..." -ForegroundColor Yellow
        docker-compose up -d --build
        
        Write-Host ""
        Write-Host "✅ 系统启动完成！" -ForegroundColor Green
        Write-Host "🌐 访问地址:" -ForegroundColor Cyan
        Write-Host "   - 系统首页: http://localhost" -ForegroundColor White
        Write-Host "   - API文档: http://localhost/swagger-ui/" -ForegroundColor White
        Write-Host "   - API服务: http://localhost:8080" -ForegroundColor White
        Write-Host "   - 健康检查: http://localhost/actuator/health" -ForegroundColor White
        
        Write-Host ""
        Write-Host "📊 查看服务状态:" -ForegroundColor Yellow
        docker-compose ps
        
        Write-Host ""
        Write-Host "📋 查看日志命令:" -ForegroundColor Yellow
        Write-Host "   docker-compose logs -f course-api" -ForegroundColor White
    }
    
    "2" {
        Write-Host "🗄️ 仅启动数据库服务..." -ForegroundColor Green
        docker-compose up -d mysql redis
        
        Write-Host ""
        Write-Host "✅ 数据库服务已启动！" -ForegroundColor Green
        Write-Host "🔗 连接信息:" -ForegroundColor Cyan
        Write-Host "   - MySQL: localhost:3306 (course_user/course_pass)" -ForegroundColor White
        Write-Host "   - Redis: localhost:6379" -ForegroundColor White
        
        Write-Host ""
        Write-Host "▶️ 启动Spring Boot应用:" -ForegroundColor Yellow
        Write-Host "   cd server/api && ./mvnw spring-boot:run" -ForegroundColor White
    }
    
    "3" {
        Write-Host "🔨 构建后端项目..." -ForegroundColor Green
        cd server/api
        ./mvnw clean package
        cd ../..
        
        Write-Host "✅ 构建完成！" -ForegroundColor Green
        Write-Host "📦 JAR文件位置: server/api/target/" -ForegroundColor Cyan
    }
    
    "4" {
        Write-Host "🛑 停止所有服务..." -ForegroundColor Yellow
        docker-compose down
        
        Write-Host "✅ 所有服务已停止！" -ForegroundColor Green
    }
    
    default {
        Write-Host "❌ 无效选择" -ForegroundColor Red
        exit 1
    }
}

Write-Host ""
Write-Host "📚 更多信息请查看 README.md" -ForegroundColor Cyan