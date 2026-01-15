import apiClient from './client'
import { ApiResponse, UserProfile, UserPreferences } from '@/types/api'

// 用户管理相关API
export const userApi = {
    // 获取当前用户信息
    getProfile: async (): Promise<UserProfile> => {
        const response = await apiClient.get<ApiResponse<UserProfile>>('/user/profile')
        return response.data.data
    },

    // 更新用户基本信息
    updateProfile: async (data: Partial<{
        nickname: string
        studentId: string
        avatar: string
    }>): Promise<UserProfile> => {
        const response = await apiClient.put<ApiResponse<UserProfile>>('/user/profile', data)
        return response.data.data
    },

    // 获取用户偏好设置
    getPreferences: async (): Promise<UserPreferences> => {
        const response = await apiClient.get<ApiResponse<UserPreferences>>('/user/preferences')
        return response.data.data
    },

    // 更新用户偏好设置
    updatePreferences: async (data: {
        notificationEnabled?: boolean
        courseReminderMinutes?: number
        assignmentReminderHours?: number
        preferredStudyTime?: string
    }): Promise<UserPreferences> => {
        const response = await apiClient.put<ApiResponse<UserPreferences>>(
            '/user/preferences',
            data
        )
        return response.data.data
    },
}
