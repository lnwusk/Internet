import { create } from 'zustand'
import { User } from '@/types/api'
import { storage } from '@/utils/storage'
import { authApi } from '@/api/auth'

interface AuthState {
  user: User | null
  isAuthenticated: boolean
  isLoading: boolean
  login: (username: string, password: string) => Promise<void>
  register: (username: string, password: string, studentId?: string, nickname?: string) => Promise<void>
  logout: () => Promise<void>
  initAuth: () => void
}

export const useAuthStore = create<AuthState>((set) => ({
  user: null,
  isAuthenticated: false,
  isLoading: true,

  // 初始化认证状态
  initAuth: () => {
    const userInfo = storage.getUserInfo()
    const token = storage.getAccessToken()
    
    if (userInfo && token) {
      set({
        user: userInfo,
        isAuthenticated: true,
        isLoading: false,
      })
    } else {
      set({
        user: null,
        isAuthenticated: false,
        isLoading: false,
      })
    }
  },

  // 登录
  login: async (username: string, password: string) => {
    try {
      const response = await authApi.login({ username, password })
      
      // 存储token和用户信息
      storage.setAccessToken(response.token)
      storage.setRefreshToken(response.refreshToken)
      storage.setUserInfo(response.user)

      set({
        user: response.user,
        isAuthenticated: true,
      })
    } catch (error) {
      throw error
    }
  },

  // 注册
  register: async (username: string, password: string, studentId?: string, nickname?: string) => {
    try {
      // 先注册
      await authApi.register({
        username,
        password,
        studentId,
        nickname,
      })

      // 注册成功后自动登录
      await login(username, password)
    } catch (error) {
      throw error
    }
  },

  // 退出登录
  logout: async () => {
    try {
      await authApi.logout()
    } catch (error) {
      console.error('退出登录失败:', error)
    } finally {
      // 无论API调用是否成功，都清除本地存储
      storage.clear()
      set({
        user: null,
        isAuthenticated: false,
      })
    }
  },
}))

