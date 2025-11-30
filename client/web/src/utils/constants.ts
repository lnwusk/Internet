// API基础URL
// 开发环境使用相对路径，通过Vite代理转发
// 生产环境需要设置环境变量 VITE_API_BASE_URL
export const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || '/api'

// Token存储键名
export const STORAGE_KEYS = {
  ACCESS_TOKEN: 'access_token',
  REFRESH_TOKEN: 'refresh_token',
  USER_INFO: 'user_info',
} as const

// Token过期时间（秒）
export const TOKEN_EXPIRY_BUFFER = 300 // 提前5分钟刷新

