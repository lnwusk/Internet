import apiClient from './client'
import { ApiResponse, UploadCoursesResponse, ConfirmCoursesRequest } from '@/types/api'

// 同步相关API
export const syncApi = {
    // 上传课表文件
    uploadCourses: async (file: File, semester?: string): Promise<UploadCoursesResponse> => {
        const formData = new FormData()
        formData.append('file', file)
        if (semester) formData.append('semester', semester)

        const response = await apiClient.post<ApiResponse<UploadCoursesResponse>>(
            '/sync/courses/upload',
            formData,
            {
                headers: {
                    'Content-Type': 'multipart/form-data',
                },
            }
        )
        return response.data.data
    },

    // 确认保存课程
    confirmCourses: async (data: ConfirmCoursesRequest): Promise<{
        savedCount: number
        updatedCount: number
        failedCount: number
    }> => {
        const response = await apiClient.post<ApiResponse<{
            savedCount: number
            updatedCount: number
            failedCount: number
        }>>(
            '/sync/courses/confirm',
            data
        )
        return response.data.data
    },

    // 同步Moodle作业
    syncMoodle: async (options?: {
        moodleUsername?: string
        moodlePassword?: string
        force?: boolean
    }): Promise<{
        syncId: string
        status: string
        type: string
        estimatedTime: number
    }> => {
        const response = await apiClient.post<ApiResponse<{
            syncId: string
            status: string
            type: string
            estimatedTime: number
        }>>(
            '/sync/moodle',
            options || {}
        )
        return response.data.data
    },

    // 查询同步状态
    getSyncStatus: async (syncId: string): Promise<{
        syncId: string
        status: string
        type: string
        progress?: number
        message?: string
        result?: any
        completedAt?: string
    }> => {
        const response = await apiClient.get<ApiResponse<{
            syncId: string
            status: string
            type: string
            progress?: number
            message?: string
            result?: any
            completedAt?: string
        }>>(
            `/sync/${syncId}`
        )
        return response.data.data
    },

    // 绑定Moodle账户
    bindMoodle: async (moodleUsername: string, moodlePassword: string): Promise<{
        moodleUsername: string
        boundAt: string
    }> => {
        const response = await apiClient.post<ApiResponse<{
            moodleUsername: string
            boundAt: string
        }>>(
            '/sync/moodle/bind',
            {
                moodleUsername,
                moodlePassword,
            }
        )
        return response.data.data
    },
}
