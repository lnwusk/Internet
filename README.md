# Course Schedule Management System

## 项目概述

这是一个基于HarmonyOS客户端和Spring Boot后端的课程表管理系统，采用高可用架构设计。

## 技术栈

### 客户端
- **HarmonyOS**: DevEco Studio + ArkUI
- **开发语言**: JavaScript/TypeScript
- **UI框架**: 声明式开发范式

### 后端
- **框架**: Spring Boot 2.7.18
- **数据库**: MySQL 8.0 + Redis
- **认证**: JWT Token
- **API文档**: Swagger UI

### 基础设施
- **容器化**: Docker + Docker Compose
- **高可用**: 多实例部署 + 负载均衡
- **监控**: Spring Boot Actuator

## 项目结构

```
Internet/
├── client/harmony/          # HarmonyOS客户端
│   ├── README.md           # 客户端开发指南
│   ├── httpUtil.js         # HTTP工具类示例
│   └── courseService.js    # API服务示例
├── server/api/             # Spring Boot后端
│   ├── src/main/java/      # Java源码
│   ├── src/main/resources/ # 配置文件
│   └── pom.xml            # Maven依赖
├── infra/                  # 基础设施配置
│   ├── docker/            # Docker配置
│   └── docker-compose.yml # 服务编排
├── docs/                   # 项目文档
└── scripts/               # 脚本文件
```

## 快速开始

### 1. 环境准备

#### 开发环境
- JDK 8+
- Maven 3.6+
- MySQL 8.0
- Redis 6.0+
- DevEco Studio 3.1+

#### 容器环境（推荐）
- Docker 20.10+
- Docker Compose 2.0+

### 2. 后端启动

#### 方式一：直接运行
```bash
# 克隆项目
git clone https://github.com/lnwusk/Internet.git
cd Internet/server/api

# 启动MySQL和Redis（如果没有容器化环境）
# 确保MySQL创建了course_db数据库和course_user用户

# 运行Spring Boot应用
./mvnw spring-boot:run
```

#### 方式二：Docker运行（推荐）
```bash
cd Internet
docker-compose up -d
```

### 3. API文档访问

启动后访问：`http://localhost:8080/swagger-ui/`

### 4. 客户端开发

参考 `client/harmony/README.md` 使用DevEco Studio开发HarmonyOS应用。

## 主要功能

### 用户管理
- [x] 用户注册
- [x] 用户登录
- [x] JWT认证

### 课程管理
- [x] 创建课程
- [x] 查看课程列表
- [x] 按日期筛选课程
- [x] 更新课程信息
- [x] 删除课程

### 系统特性（高可用）
- [x] 健康检查接口
- [x] 数据库连接池
- [x] Redis缓存
- [x] 跨域支持
- [x] 容器化部署

## API接口

### 认证接口
- `POST /api/auth/login` - 用户登录
- `POST /api/auth/register` - 用户注册
- `GET /api/auth/health` - 服务健康检查

### 课程接口
- `GET /api/courses` - 获取用户课程
- `GET /api/courses/day/{dayOfWeek}` - 按星期获取课程
- `POST /api/courses` - 创建课程
- `PUT /api/courses/{id}` - 更新课程
- `DELETE /api/courses/{id}` - 删除课程

## 部署说明

### 开发环境
1. 启动MySQL和Redis服务
2. 修改 `application.yml` 中的数据库连接配置
3. 运行 `./mvnw spring-boot:run`

### 生产环境（Docker）
```bash
# 构建并启动所有服务
docker-compose up -d

# 查看服务状态
docker-compose ps

# 查看日志
docker-compose logs -f course-api
```

## 开发指南

### 后端扩展
- 在 `entity` 包中添加新的实体类
- 在 `repository` 包中创建对应的Repository接口
- 在 `service` 包中实现业务逻辑
- 在 `controller` 包中添加REST接口

### 客户端开发
- 参考 `client/harmony/README.md`
- 使用提供的 `httpUtil.js` 和 `courseService.js` 示例

### 数据库迁移
- JPA会自动创建和更新表结构
- 生产环境建议使用Flyway或Liquibase

## 高可用特性

1. **服务健康检查**: `/actuator/health`
2. **多实例部署**: 支持水平扩展
3. **数据库连接池**: HikariCP高性能连接池
4. **Redis缓存**: 减少数据库压力
5. **异常处理**: 完善的异常处理机制
6. **CORS支持**: 跨域访问支持

## 贡献指南

1. Fork项目
2. 创建功能分支
3. 提交更改
4. 推送到分支
5. 创建Pull Request

## 许可证

MIT License