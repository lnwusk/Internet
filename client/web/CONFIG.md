# 配置说明

## API 配置

### 开发环境

前端使用 Vite 代理将 `/api/*` 请求转发到后端服务器 `http://localhost:8080`。

配置位置：
- `vite.config.ts` - 代理配置
- `src/utils/constants.ts` - API基础URL

### 后端API路径

根据后端代码，实际API路径为：
- 登录：`POST http://localhost:8080/api/auth/login`
- 注册：`POST http://localhost:8080/api/auth/register`

注意：后端路径是 `/api/auth/*`，不是 `/api/v1/auth/*`（接口文档中的路径可能不同）

### 修改API地址

如果需要修改API地址，请编辑以下文件：

1. **开发环境（使用代理）**
   - 修改 `vite.config.ts` 中的 `target` 字段

2. **生产环境**
   - 设置环境变量 `VITE_API_BASE_URL`
   - 或直接修改 `src/utils/constants.ts` 中的 `API_BASE_URL`

## 常见问题

### 1. Network Error: ERR_NAME_NOT_RESOLVED

**原因**：API域名无法解析（通常是因为使用了不存在的域名）

**解决方案**：
- 确保后端服务正在运行（`http://localhost:8080`）
- 检查 `vite.config.ts` 中的代理配置
- 确保API基础URL设置为相对路径 `/api` 或正确的后端地址

### 2. 404 Not Found

**原因**：API路径不正确

**解决方案**：
- 检查后端API路径是否为 `/api/auth/*`
- 确认代理配置是否正确转发请求

### 3. CORS 错误

**原因**：跨域请求被阻止

**解决方案**：
- 后端已经配置了 CORS（`@CrossOrigin(origins = "*")`）
- 如果还有问题，检查后端 SecurityConfig 配置

## 启动步骤

1. **启动后端服务**
   ```bash
   cd server/api
   ./mvnw spring-boot:run
   ```
   后端应该在 `http://localhost:8080` 启动

2. **启动前端服务**
   ```bash
   cd client/web
   npm install
   npm run dev
   ```
   前端应该在 `http://localhost:3000` 启动

3. **测试连接**
   - 打开浏览器访问 `http://localhost:3000`
   - 尝试注册/登录
   - 检查浏览器控制台和网络请求

