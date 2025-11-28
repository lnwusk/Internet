# HarmonyOS 课程表客户端

## 开发环境要求

1. **DevEco Studio** (推荐版本 3.1.1+)
2. **HarmonyOS SDK** API Level 8+
3. **Node.js** (用于依赖管理)

## 项目创建步骤

### 1. 使用DevEco Studio创建新项目

1. 打开 DevEco Studio
2. 选择 "Create HarmonyOS Project"
3. 选择 "Phone" 设备类型
4. 选择 "Empty Ability (JS)" 或 "Empty Ability (eTS)"
5. 项目配置：
   - Project Name: `CourseSchedule`
   - Bundle Name: `com.courseapp.schedule`
   - Save Location: 本目录 (`client/harmony`)

### 2. 项目结构

```
client/harmony/
├── entry/
│   ├── src/main/
│   │   ├── js/default/
│   │   │   ├── pages/
│   │   │   │   ├── index/          # 主页面(课程表)
│   │   │   │   ├── login/          # 登录页面
│   │   │   │   └── course/         # 课程详情页
│   │   │   ├── common/             # 公共模块
│   │   │   │   ├── utils/          # 工具类
│   │   │   │   └── constants/      # 常量定义
│   │   │   └── app.js              # 应用入口
│   │   ├── resources/              # 资源文件
│   │   └── config.json             # 应用配置
│   └── build-profile.json5
└── README.md
```

### 3. 主要功能模块

#### 3.1 登录模块 (pages/login/)
- 用户登录界面
- 用户注册功能
- JWT Token存储

#### 3.2 课程表模块 (pages/index/)
- 周视图课程表显示
- 课程时间冲突检查
- 课程颜色标识

#### 3.3 课程管理模块 (pages/course/)
- 添加课程
- 编辑课程信息
- 删除课程

### 4. 关键配置

#### 4.1 网络权限配置 (config.json)
```json
{
  "module": {
    "reqPermissions": [
      {
        "name": "ohos.permission.INTERNET"
      },
      {
        "name": "ohos.permission.GET_NETWORK_INFO"
      }
    ]
  }
}
```

#### 4.2 API服务配置
- 后端服务地址: `http://localhost:8080/api`
- JWT Token存储使用: `@ohos.data.preferences`

### 5. 快速开始

1. 在DevEco Studio中打开项目
2. 配置签名证书
3. 连接HarmonyOS设备或启动模拟器
4. 点击"Run"按钮运行应用

### 6. 示例代码片段

#### HTTP请求工具类 (common/utils/httpUtil.js)
```javascript
import http from '@ohos.net.http';

export default class HttpUtil {
  static async request(url, method = 'GET', data = null, headers = {}) {
    const httpRequest = http.createHttp();
    
    const options = {
      method,
      header: {
        'Content-Type': 'application/json',
        ...headers
      }
    };
    
    if (data) {
      options.extraData = JSON.stringify(data);
    }
    
    try {
      const response = await httpRequest.request(url, options);
      return JSON.parse(response.result);
    } catch (error) {
      console.error('HTTP Request Error:', error);
      throw error;
    } finally {
      httpRequest.destroy();
    }
  }
  
  static async get(url, headers = {}) {
    return this.request(url, 'GET', null, headers);
  }
  
  static async post(url, data, headers = {}) {
    return this.request(url, 'POST', data, headers);
  }
}
```

### 7. 与后端API对接

- 登录接口: `POST /api/auth/login`
- 注册接口: `POST /api/auth/register`
- 获取课程: `GET /api/courses`
- 添加课程: `POST /api/courses`
- 更新课程: `PUT /api/courses/{id}`
- 删除课程: `DELETE /api/courses/{id}`

### 8. 开发注意事项

1. **高可用性考虑**:
   - 实现离线数据缓存
   - 网络异常处理
   - 自动重连机制

2. **UI响应式设计**:
   - 适配不同屏幕尺寸
   - 深色/浅色主题切换

3. **性能优化**:
   - 懒加载课程数据
   - 图片资源优化
   - 内存管理

### 9. 构建和打包

```bash
# 在项目根目录执行
hvigorw assembleHap --mode module -p product=default
```

### 10. 部署说明

1. 生成签名HAP包
2. 通过DevEco Studio安装到设备
3. 或上传到华为应用市场

## 技术栈

- **UI框架**: ArkUI (声明式开发范式)
- **开发语言**: JavaScript/TypeScript
- **网络通信**: @ohos.net.http
- **本地存储**: @ohos.data.preferences
- **设备能力**: @ohos.deviceInfo