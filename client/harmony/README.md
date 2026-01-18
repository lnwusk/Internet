# NjuPlan (南大学业规划助手) - HarmonyOS Client

本项目是 **NjuPlan** 的 HarmonyOS 客户端，旨在为南京大学学生提供一站式的学业日程管理工具。

## 项目简介

NjuPlan 是一个集成了课表管理、作业/学习任务规划、AI 智能辅助的时间管理应用。本客户端采用 ArkTS + ArkUI 开发，适配 HarmonyOS 系统。

## 已实现功能 (Features)

### 1. 用户认证 (Authentication)
*   **注册 & 登录**：支持普通账号注册登录。
*   **Token 管理**：实现了自动 Token 刷新机制 (401 自动重试)，提升用户体验。
*   **修改密码**：登录状态下可修改账户密码。
*   对应服务：`AuthService`

### 2. 智能课表 (Smart Schedule)
*   **周视图**：清晰展示的一周课表，支持左右滑动切换周次。
*   **课程详情**：点击课程块查看详细信息（教室、教师、周次等）。
*   **手动管理**：支持手动添加、编辑、删除课程（用于手动添加的课程）。
*   **课表导入**：支持从 **XLSX 文件** 导入官方课表。
    *   **注意**：由于预览器文件系统限制，**文件选择功能需在真机或模拟器上测试**，预览器可能无法正常打开文件选择器。
    *   流程：上传解析 -> 预览确认 -> 保存入库。
*   对应服务：`CourseService`, `SyncService`

### 3. 学习任务 (Study Tasks)
*   **快速创建**：在课表空白处 **长按** 即可快速创建学习任务。
*   **关联作业**：创建任务时可选择关联待完成的作业，自动填充任务标题。
*   **任务管理**：支持编辑任务详情、标记完成状态。
*   **拖拽规划**：
    *   支持 **上下拖拽** 任务块来调整任务的具体时间。
    *   *注：为防止误操作和日期错乱，目前限制仅支持垂直方向拖拽（调整时间），不支持水平跨天拖拽。*
*   对应服务：`StudyTaskService`

### 4. 作业管理 (Assignment Management)
*   **作业列表**：按状态分类展示作业（全部/待完成/已完成/已逾期）。
*   **统计卡片**：实时显示待完成、已完成、已逾期作业数量。
*   **添加作业**：手动添加作业，支持关联课程、设置截止日期、类型、难度。
*   **标记完成**：一键标记作业为已完成。
*   **删除作业**：支持删除手动添加的作业。
*   对应服务：`AssignmentService`

### 5. AI 智能规划 (AI Planning)
*   **智能分析**：选择待完成作业，AI 根据截止日期和难度自动生成学习计划。
*   **偏好设置**：可配置偏好学习时间、每日最大学习时长、是否避开周末。
*   **规划详情**：展示每个作业的预估时长、难度、推荐学习时间和理由。
*   **应用规划**：一键将规划应用到课表，自动创建对应的学习任务。
*   **历史记录**：查看过往的 AI 规划记录和详情。
*   对应服务：`AIPlanService`

### 6. 个人中心 (User Profile)
*   **资料展示**：显示用户昵称、学号等基本信息。
*   **资料编辑**：支持修改昵称和学号。
*   **修改密码**：安全修改账户密码。
*   **退出登录**：清除登录状态并返回登录页。
*   对应服务：`UserService`

### 7. 通知与设置 (Notifications)
*   **通知设置**：可配置课程提醒（如课前 15 分钟）和作业截止提醒。
*   **通知历史**：查看过往的推送通知记录。
*   对应服务：`NotificationService`

## 项目结构 (Directory Structure)

```
entry/src/main/ets
├── common          # 公共模块
│   ├── models      # 数据模型定义 (ApiResponse, User, Course, Assignment...)
│   └── utils       # 工具类 (HttpUtil, Logger...)
├── components      # 可复用组件
├── pages           # 页面视图
│   ├── Index.ets               # 主页 (Tabs: 课表/作业/AI规划/我的)
│   ├── LoginPage.ets           # 登录页
│   ├── RegisterPage.ets        # 注册页
│   ├── WeekView.ets            # 课表周视图 (核心页面)
│   ├── CourseAddPage.ets       # 课程添加/编辑页
│   ├── CourseImportPage.ets    # 课表导入页
│   ├── AssignmentListPage.ets  # 作业列表页
│   ├── AssignmentDetailPage.ets # 作业详情/添加页
│   ├── AIPlanPage.ets          # AI 规划页
│   ├── AIPlanDetailPage.ets    # AI 规划详情页
│   ├── AIPlanHistoryPage.ets   # AI 规划历史页
│   ├── UserProfilePage.ets     # 编辑资料页
│   ├── ChangePasswordPage.ets  # 修改密码页
│   ├── NotificationSettingsPage.ets # 通知设置页
│   ├── NotificationHistoryPage.ets  # 通知历史页
│   ├── StudyTaskDialog.ets     # 学习任务弹窗
│   └── CourseDetailDialog.ets  # 课程详情弹窗
└── services        # 业务逻辑服务 (API 调用封装)
    ├── AuthService.ets         # 认证服务
    ├── CourseService.ets       # 课程服务
    ├── StudyTaskService.ets    # 任务服务
    ├── AssignmentService.ets   # 作业服务
    ├── AIPlanService.ets       # AI 规划服务
    ├── UserService.ets         # 用户服务
    ├── SyncService.ets         # 数据同步(导入)服务
    └── NotificationService.ets # 通知服务
```

## 后端接口说明 (Backend APIs)

客户端通过 RESTful API 与后端交互，主要接口如下：

### 认证模块
*   `POST /auth/login`: 用户登录
*   `POST /auth/register`: 用户注册
*   `POST /auth/refresh`: 刷新 Token
*   `POST /auth/change-password`: 修改密码

### 课程模块
*   `GET /courses/week-schedule`: 获取周视图数据
*   `GET /courses`: 获取课程列表
*   `POST /courses`: 手动添加课程
*   `PUT /courses/{id}`: 更新课程
*   `DELETE /courses/{id}`: 删除课程

### 学习任务模块
*   `GET /study-tasks`: 获取任务列表
*   `POST /study-tasks`: 创建任务
*   `PUT /study-tasks/{id}`: 更新任务 (支持拖拽更新时间)
*   `POST /study-tasks/{id}/complete`: 标记完成

### 作业管理模块
*   `GET /assignments`: 获取作业列表
*   `GET /assignments/pending`: 获取待完成作业
*   `GET /assignments/overdue`: 获取已逾期作业
*   `GET /assignments/{id}`: 获取作业详情
*   `POST /assignments`: 手动添加作业
*   `PUT /assignments/{id}`: 更新作业
*   `POST /assignments/{id}/complete`: 标记完成
*   `DELETE /assignments/{id}`: 删除作业

### AI 规划模块
*   `POST /ai/plan`: 提交 AI 规划请求
*   `GET /ai/plan/{id}`: 查询规划结果
*   `POST /ai/plan/{id}/apply`: 应用规划
*   `GET /ai/plan/history`: 获取规划历史

### 用户管理模块
*   `GET /user/profile`: 获取用户信息
*   `PUT /user/profile`: 更新用户信息
*   `PUT /user/preferences`: 更新偏好设置

### 数据同步 (导入)
*   `POST /sync/courses/upload`: 上传 XLSX 课表文件 (multipart/form-data)
*   `POST /sync/courses/confirm`: 确认保存解析结果

### 通知模块
*   `GET /notifications/settings`: 获取设置
*   `PUT /notifications/settings`: 更新设置
*   `GET /notifications/history`: 获取通知历史

## 技术栈 (Tech Stack)

*   **OS**: HarmonyOS (API 9+)
*   **Language**: ArkTS
*   **Framework**: ArkUI (Declarative Paradigm)
*   **Network**: @ohos.net.http
*   **Persistence**: @ohos.data.preferences

## 快速开始 (Getting Started)

1.  **环境准备**：安装 DevEco Studio 3.1+。
2.  **后端服务**：确保 NjuPlan 后端服务已启动并在本地运行 (默认 `localhost:8080`)。
    *   *注：真机调试需修改 `HttpUtil.ets` 中的 `BASE_URL` 为宿主机 IP。*
3.  **运行项目**：
    *   打开项目，Sync Gradle。
    *   选择 `entry` 模块，点击 Run。
    *   推荐使用 **API 9+ 模拟器** 或 **真机** 以获得完整体验（特别是文件导入功能）。
