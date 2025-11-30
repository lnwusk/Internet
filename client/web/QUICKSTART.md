# 快速开始指南

## 前置要求

- Node.js 18+ 
- npm 或 yarn 或 pnpm

## 安装依赖

```bash
cd client/web
npm install
```

## 启动开发服务器

```bash
npm run dev
```

应用将在 `http://localhost:3000` 启动。

## 功能说明

### 已实现的功能

1. **用户注册**
   - 用户名验证（3-20个字符，字母、数字、下划线）
   - 密码验证（至少8个字符，包含字母和数字）
   - 可选的学号和昵称字段
   - 注册成功后自动登录

2. **用户登录**
   - 用户名和密码登录
   - 表单验证
   - 错误提示

3. **Token管理**
   - 自动存储accessToken和refreshToken
   - Token过期自动刷新
   - 退出登录清除Token

4. **路由保护**
   - 未登录用户自动跳转到登录页
   - 已登录用户访问登录/注册页自动跳转到首页

## API配置

默认API地址：`https://api.njuplan.edu.cn/api/v1`

如需修改，请编辑 `src/utils/constants.ts` 中的 `API_BASE_URL`。

## 构建生产版本

```bash
npm run build
```

构建产物将输出到 `dist` 目录。

## 预览生产构建

```bash
npm run preview
```

## 项目结构说明

```
client/web/
├── src/
│   ├── api/              # API服务
│   │   ├── client.ts     # Axios实例和拦截器
│   │   └── auth.ts       # 认证相关API
│   ├── components/       # 通用组件
│   │   ├── Layout.tsx    # 布局组件
│   │   └── ProtectedRoute.tsx  # 路由保护组件
│   ├── pages/            # 页面组件
│   │   ├── Login.tsx     # 登录页
│   │   ├── Register.tsx  # 注册页
│   │   └── Home.tsx      # 首页（示例）
│   ├── router/           # 路由配置
│   │   └── index.tsx     # 路由定义
│   ├── store/            # 状态管理
│   │   └── authStore.ts  # 认证状态
│   ├── types/            # 类型定义
│   │   └── api.ts        # API类型
│   ├── utils/            # 工具函数
│   │   ├── constants.ts  # 常量
│   │   └── storage.ts    # 本地存储工具
│   ├── styles/           # 样式文件
│   │   └── index.css     # 全局样式
│   └── main.tsx          # 应用入口
├── package.json          # 项目配置
├── vite.config.ts        # Vite配置
├── tsconfig.json         # TypeScript配置
└── tailwind.config.js    # Tailwind配置
```

## 常见问题

### 1. API请求失败

- 检查API地址是否正确
- 检查网络连接
- 查看浏览器控制台错误信息

### 2. Token刷新失败

- 检查refreshToken是否过期
- 检查API接口是否正常
- 会自动跳转到登录页重新登录

### 3. 样式不生效

- 确保已安装所有依赖：`npm install`
- 检查Tailwind配置是否正确
- 重启开发服务器

## 下一步开发

- [ ] 课程表展示页面
- [ ] 课程管理功能
- [ ] 作业管理功能
- [ ] AI智能规划功能
- [ ] 用户设置页面

