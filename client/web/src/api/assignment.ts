import apiClient from './client'
import { ApiResponse, Assignment, AssignmentDetail, AssignmentListResponse } from '@/types/api'

// 作业管理相关API
export const assignmentApi = {
    // 获取作业列表
    getAssignments: async (params?: {
        courseId?: string
        status?: 'pending' | 'completed' | 'overdue'
        sortBy?: 'ddl' | 'created'
        order?: 'asc' | 'desc'
    }): Promise<AssignmentListResponse> => {
        const queryParams = new URLSearchParams()
        if (params?.courseId) queryParams.append('courseId', params.courseId)
        if (params?.status) queryParams.append('status', params.status)
        if (params?.sortBy) queryParams.append('sortBy', params.sortBy)
        if (params?.order) queryParams.append('order', params.order)

        const response = await apiClient.get<ApiResponse<AssignmentListResponse>>(
            `/assignments?${queryParams.toString()}`
        )
        return response.data.data
    },

    // 获取作业详情
    getAssignment: async (assignmentId: string): Promise<AssignmentDetail> => {
        const response = await apiClient.get<ApiResponse<AssignmentDetail>>(
            `/assignments/${assignmentId}`
        )
        return response.data.data
    },

    // 手动添加作业
    addAssignment: async (data: {
        courseId: string
        title: string
        description?: string
        dueDate: string
        type?: string
        wordCount?: number
        difficulty?: string
    }): Promise<{ assignmentId: string; title: string; source: string }> => {
        const response = await apiClient.post<
            ApiResponse<{ assignmentId: string; title: string; source: string }>
        >('/assignments', data)
        return response.data.data
    },

    // 更新作业信息
    updateAssignment: async (
        assignmentId: string,
        data: Partial<{
            title: string
            description: string
            dueDate: string
            type: string
            wordCount: number
            difficulty: string
        }>
    ): Promise<{ assignmentId: string; title: string }> => {
        const response = await apiClient.put<
            ApiResponse<{ assignmentId: string; title: string }>
        >(`/assignments/${assignmentId}`, data)
        return response.data.data
    },

    // 标记作业完成
    completeAssignment: async (
        assignmentId: string
    ): Promise<{ assignmentId: string; status: string; completedAt: string }> => {
        const response = await apiClient.post<
            ApiResponse<{ assignmentId: string; status: string; completedAt: string }>
        >(`/assignments/${assignmentId}/complete`)
        return response.data.data
    },

    // 删除作业
    deleteAssignment: async (assignmentId: string): Promise<void> => {
        await apiClient.delete<ApiResponse>(`/assignments/${assignmentId}`)
    },
}
