# 问题修复说明

## 修复的问题

### 1. ❌ Network Error: ERR_NAME_NOT_RESOLVED

**问题**：API请求失败，显示 `net::ERR_NAME_NOT_RESOLVED`

**原因**：
- API基础URL设置为不存在的域名 `https://api.njuplan.edu.cn`
- 这是接口文档中的示例域名，实际不存在

**修复**：
- ✅ 修改 `src/utils/constants.ts`：使用相对路径 `/api`（通过Vite代理）
- ✅ 修改 `vite.config.ts`：代理配置指向本地后端 `http://localhost:8080`
- ✅ 移除了路径重写中的 `/v1`，因为后端实际路径是 `/api/auth/*`

**修改文件**：
- `src/utils/constants.ts`
- `vite.config.ts`

---

### 2. ⚠️ React Router Future Flag Warning

**问题**：控制台显示React Router警告

**原因**：React Router v7将使用 `React.startTransition`，需要提前启用

**修复**：
- ✅ 在 `src/router/index.tsx` 中添加了 `future.v7_startTransition` 标志

**修改文件**：
- `src/router/index.tsx`

---

### 3. ⚠️ Input elements should have autocomplete attributes

**问题**：浏览器警告输入框缺少autocomplete属性

**原因**：HTML5规范要求表单输入框添加autocomplete属性以改善用户体验和安全性

**修复**：
- ✅ 登录页面：用户名添加 `autoComplete="username"`，密码添加 `autoComplete="current-password"`
- ✅ 注册页面：
  - 用户名：`autoComplete="username"`
  - 密码：`autoComplete="new-password"`
  - 确认密码：`autoComplete="new-password"`
  - 学号：`autoComplete="off"`
  - 昵称：`autoComplete="nickname"`

**修改文件**：
- `src/pages/Login.tsx`
- `src/pages/Register.tsx`

---

## 当前配置

### API路径配置

```
前端请求: /api/auth/login
  ↓ (Vite代理)
后端接收: http://localhost:8080/api/auth/login
```

### 开发环境要求

1. **后端服务**必须在 `http://localhost:8080` 运行
2. **前端服务**在 `http://localhost:3000` 运行
3. 前端通过Vite代理转发API请求到后端

---

## 测试步骤

1. **确保后端运行**
   ```bash
   cd server/api
   ./mvnw spring-boot:run
   ```
   访问 `http://localhost:8080/api/auth/health` 应该返回响应

2. **启动前端**
   ```bash
   cd client/web
   npm run dev
   ```

3. **测试注册/登录**
   - 打开 `http://localhost:3000/register`
   - 填写注册表单
   - 应该能够成功注册并自动登录

---

## 如果仍然遇到问题

### 检查清单

- [ ] 后端服务是否正在运行？（检查 `http://localhost:8080/api/auth/health`）
- [ ] 浏览器控制台是否有错误信息？
- [ ] 网络请求是否正确发送？（检查浏览器开发者工具 Network 标签）
- [ ] 后端API路径是否为 `/api/auth/*`？（不是 `/api/v1/auth/*`）

### 调试步骤

1. 打开浏览器开发者工具（F12）
2. 切换到 Network 标签
3. 尝试注册/登录
4. 查看失败的请求：
   - URL是什么？
   - 状态码是什么？
   - 响应内容是什么？

### 常见问题

**Q: 仍然显示 Network Error**
A: 检查后端是否正在运行，确认端口是8080

**Q: 404 Not Found**
A: 检查后端API路径，确保是 `/api/auth/*` 而不是 `/api/v1/auth/*`

**Q: CORS错误**
A: 后端已经配置了CORS，如果还有问题，检查后端SecurityConfig

---

## 下一步

如果后端API路径与接口文档不一致（文档说 `/api/v1/*`，实际是 `/api/*`），需要：
1. 与后端同学确认实际API路径
2. 或者让后端同学修改路径以匹配文档
3. 或者前端同时支持两种路径

