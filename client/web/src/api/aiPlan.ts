import apiClient from './client'
import { ApiResponse, AiPlanResponse, AiPlanHistoryResponse } from '@/types/api'

// AI智能规划相关API
export const aiPlanApi = {
    // 提交AI规划请求
    submitPlan: async (data: {
        assignmentIds: string[]
        startDate?: string
        endDate?: string
        preferences?: {
            preferredStudyTime?: string
            dailyMaxHours?: number
            avoidWeekend?: boolean
        }
    }): Promise<{
        planId: string
        status: string
        estimatedTime: number
    }> => {
        const response = await apiClient.post<
            ApiResponse<{
                planId: string
                status: string
                estimatedTime: number
            }>
        >('/ai/plan', data)
        return response.data.data
    },

    // 查询AI规划结果
    getPlanResult: async (planId: string): Promise<AiPlanResponse> => {
        const response = await apiClient.get<ApiResponse<AiPlanResponse>>(`/ai/plan/${planId}`)
        return response.data.data
    },

    // 确认并应用AI规划
    applyPlan: async (
        planId: string,
        data: {
            applyAll: boolean
            selectedItems?: Array<{
                assignmentId: string
                scheduleIndex: number
            }>
        }
    ): Promise<{
        createdTasks: number
        taskIds: string[]
    }> => {
        const response = await apiClient.post<
            ApiResponse<{
                createdTasks: number
                taskIds: string[]
            }>
        >(`/ai/plan/${planId}/apply`, data)
        return response.data.data
    },

    // 获取AI分析历史
    getPlanHistory: async (params?: {
        page?: number
        pageSize?: number
    }): Promise<AiPlanHistoryResponse> => {
        const queryParams = new URLSearchParams()
        if (params?.page) queryParams.append('page', params.page.toString())
        if (params?.pageSize) queryParams.append('pageSize', params.pageSize.toString())

        const response = await apiClient.get<ApiResponse<AiPlanHistoryResponse>>(
            `/ai/plan/history?${queryParams.toString()}`
        )
        return response.data.data
    },
}
