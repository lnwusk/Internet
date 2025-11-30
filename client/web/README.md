# NjuPlan Web 前端

课表管理系统的Web前端应用，基于React + Vite + TypeScript开发。

## 技术栈

- **React 18** - UI框架
- **TypeScript** - 类型安全
- **Vite** - 构建工具
- **React Router** - 路由管理
- **Axios** - HTTP客户端
- **Zustand** - 状态管理
- **React Hook Form** - 表单处理
- **Zod** - 表单验证
- **Tailwind CSS** - 样式框架

## 功能特性

- ✅ 用户注册
- ✅ 用户登录
- ✅ Token自动刷新
- ✅ 路由守卫
- ✅ 响应式设计

## 开发

```bash
# 安装依赖
npm install

# 启动开发服务器
npm run dev

# 构建生产版本
npm run build

# 预览生产构建
npm run preview
```

## 项目结构

```
src/
├── api/           # API服务封装
├── components/    # 通用组件
├── pages/         # 页面组件
├── store/         # 状态管理
├── utils/         # 工具函数
├── types/         # TypeScript类型定义
└── styles/        # 全局样式
```

## API配置

默认API基础URL: `https://api.njuplan.edu.cn/api/v1`

开发环境可以通过Vite代理访问，生产环境需要配置环境变量。

