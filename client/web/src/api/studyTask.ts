import apiClient from './client'
import { ApiResponse, StudyTask, StudyTaskListResponse } from '@/types/api'

// 学习任务管理相关API
export const studyTaskApi = {
    // 获取学习任务列表
    getStudyTasks: async (params?: {
        week?: number
        date?: string
        assignmentId?: string
    }): Promise<StudyTaskListResponse> => {
        const queryParams = new URLSearchParams()
        if (params?.week) queryParams.append('week', params.week.toString())
        if (params?.date) queryParams.append('date', params.date)
        if (params?.assignmentId) queryParams.append('assignmentId', params.assignmentId)

        const response = await apiClient.get<ApiResponse<StudyTaskListResponse>>(
            `/study-tasks?${queryParams.toString()}`
        )
        return response.data.data
    },

    // 创建学习任务
    createTask: async (data: {
        title: string
        assignmentId?: string
        scheduledDate: string
        startTime: string
        endTime: string
        estimatedHours?: number
        description?: string
    }): Promise<{
        taskId: string
        title: string
        scheduledDate: string
        startTime: string
        endTime: string
        createdAt: string
    }> => {
        const response = await apiClient.post<
            ApiResponse<{
                taskId: string
                title: string
                scheduledDate: string
                startTime: string
                endTime: string
                createdAt: string
            }>
        >('/study-tasks', data)
        return response.data.data
    },

    // 更新学习任务
    updateTask: async (
        taskId: string,
        data: Partial<{
            scheduledDate: string
            startTime: string
            endTime: string
            title: string
            description: string
        }>
    ): Promise<{
        taskId: string
        scheduledDate?: string
        startTime?: string
        endTime?: string
    }> => {
        const response = await apiClient.put<
            ApiResponse<{
                taskId: string
                scheduledDate?: string
                startTime?: string
                endTime?: string
            }>
        >(`/study-tasks/${taskId}`, data)
        return response.data.data
    },

    // 删除学习任务
    deleteTask: async (taskId: string): Promise<void> => {
        await apiClient.delete<ApiResponse>(`/study-tasks/${taskId}`)
    },

    // 标记任务完成
    completeTask: async (
        taskId: string
    ): Promise<{ taskId: string; status: string; completedAt: string }> => {
        const response = await apiClient.post<
            ApiResponse<{ taskId: string; status: string; completedAt: string }>
        >(`/study-tasks/${taskId}/complete`)
        return response.data.data
    },
}
