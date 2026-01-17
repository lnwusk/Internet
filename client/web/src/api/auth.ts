import apiClient from './client'
import { ApiResponse, LoginRequest, LoginResponse, RegisterRequest, RegisterResponse } from '@/types/api'

// 认证相关API
export const authApi = {
  // 用户注册
  register: async (data: RegisterRequest): Promise<RegisterResponse> => {
    const response = await apiClient.post<ApiResponse<RegisterResponse>>('/auth/register', data)
    return response.data.data
  },

  // 用户登录
  login: async (data: LoginRequest): Promise<LoginResponse> => {
    const response = await apiClient.post<ApiResponse<LoginResponse>>('/auth/login', data)

    // 检查响应数据
    if (!response.data) {
      throw new Error('登录失败：服务器未返回数据')
    }

    if (response.data.code !== 200) {
      throw new Error(response.data.message || '登录失败')
    }

    if (!response.data.data) {
      throw new Error('登录失败：响应数据格式错误')
    }

    return response.data.data
  },

  // 退出登录
  logout: async (): Promise<void> => {
    await apiClient.post<ApiResponse>('/auth/logout')
  },

  // 刷新Token
  refreshToken: async (refreshToken: string): Promise<{ token: string; expiresIn: number }> => {
    const response = await apiClient.post<ApiResponse<{ token: string; expiresIn: number }>>(
      '/auth/refresh',
      {},
      {
        headers: {
          Authorization: `Bearer ${refreshToken}`,
        },
      }
    )
    return response.data.data
  },

  // 修改密码
  changePassword: async (oldPassword: string, newPassword: string): Promise<void> => {
    await apiClient.post<ApiResponse>('/auth/change-password', {
      oldPassword,
      newPassword,
    })
  },
}

