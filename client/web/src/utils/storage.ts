import { STORAGE_KEYS } from './constants'

// Token存储工具
export const storage = {
  // 存储访问令牌
  setAccessToken: (token: string) => {
    localStorage.setItem(STORAGE_KEYS.ACCESS_TOKEN, token)
  },

  // 获取访问令牌
  getAccessToken: (): string | null => {
    return localStorage.getItem(STORAGE_KEYS.ACCESS_TOKEN)
  },

  // 存储刷新令牌
  setRefreshToken: (token: string) => {
    localStorage.setItem(STORAGE_KEYS.REFRESH_TOKEN, token)
  },

  // 获取刷新令牌
  getRefreshToken: (): string | null => {
    return localStorage.getItem(STORAGE_KEYS.REFRESH_TOKEN)
  },

  // 存储用户信息
  setUserInfo: (user: any) => {
    localStorage.setItem(STORAGE_KEYS.USER_INFO, JSON.stringify(user))
  },

  // 获取用户信息
  getUserInfo: () => {
    const userStr = localStorage.getItem(STORAGE_KEYS.USER_INFO)
    return userStr ? JSON.parse(userStr) : null
  },

  // 清除所有存储
  clear: () => {
    localStorage.removeItem(STORAGE_KEYS.ACCESS_TOKEN)
    localStorage.removeItem(STORAGE_KEYS.REFRESH_TOKEN)
    localStorage.removeItem(STORAGE_KEYS.USER_INFO)
  },
}

