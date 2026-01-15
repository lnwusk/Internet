import apiClient from './client'
import {
    ApiResponse,
    NotificationSettings,
    NotificationHistoryResponse,
} from '@/types/api'

// 通知管理相关API
export const notificationApi = {
    // 获取通知设置
    getSettings: async (): Promise<NotificationSettings> => {
        const response = await apiClient.get<ApiResponse<NotificationSettings>>(
            '/notifications/settings'
        )
        return response.data.data
    },

    // 更新通知设置
    updateSettings: async (data: {
        enabled?: boolean
        courseReminder?: {
            enabled: boolean
            minutesBefore: number
        }
        assignmentReminder?: {
            enabled: boolean
            hoursBefore: number
        }
        pushEnabled?: boolean
    }): Promise<NotificationSettings> => {
        const response = await apiClient.put<ApiResponse<NotificationSettings>>(
            '/notifications/settings',
            data
        )
        return response.data.data
    },

    // 获取通知历史
    getHistory: async (params?: {
        type?: 'course' | 'assignment' | 'all'
        page?: number
        pageSize?: number
    }): Promise<NotificationHistoryResponse> => {
        const queryParams = new URLSearchParams()
        if (params?.type) queryParams.append('type', params.type)
        if (params?.page) queryParams.append('page', params.page.toString())
        if (params?.pageSize) queryParams.append('pageSize', params.pageSize.toString())

        const response = await apiClient.get<ApiResponse<NotificationHistoryResponse>>(
            `/notifications/history?${queryParams.toString()}`
        )
        return response.data.data
    },

    // 标记通知已读
    markAsRead: async (
        notificationId: string
    ): Promise<{ notificationId: string; read: boolean }> => {
        const response = await apiClient.post<
            ApiResponse<{ notificationId: string; read: boolean }>
        >(`/notifications/${notificationId}/read`)
        return response.data.data
    },
}
