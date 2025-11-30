import apiClient from './client'
import { ApiResponse, Course, CourseListResponse, WeekScheduleResponse } from '@/types/api'

// 课程相关API
export const courseApi = {
    // 获取课程列表
    getCourses: async (semester?: string, includeSchedule: boolean = true): Promise<CourseListResponse> => {
        const params = new URLSearchParams()
        if (semester) params.append('semester', semester)
        params.append('includeSchedule', includeSchedule.toString())

        const response = await apiClient.get<ApiResponse<CourseListResponse>>(
            `/courses?${params.toString()}`
        )
        return response.data.data
    },

    // 获取周视图课表
    getWeekSchedule: async (week?: number, semester?: string): Promise<WeekScheduleResponse> => {
        const params = new URLSearchParams()
        if (week) params.append('week', week.toString())
        if (semester) params.append('semester', semester)

        const response = await apiClient.get<ApiResponse<WeekScheduleResponse>>(
            `/courses/week-schedule?${params.toString()}`
        )
        return response.data.data
    },

    // 手动添加课程
    addCourse: async (courseData: {
        courseName: string
        courseCode?: string
        teacher?: string
        credits?: number
        semester?: string
        schedule?: {
            dayOfWeek: number
            startTime: string
            endTime: string
            location: string
            weeks: number[]
        }[]
    }): Promise<Course> => {
        const response = await apiClient.post<ApiResponse<Course>>('/courses', courseData)
        return response.data.data
    },

    // 更新课程信息
    updateCourse: async (courseId: string, courseData: Partial<{
        courseName: string
        courseCode: string
        teacher: string
        credits: number
        schedule: {
            dayOfWeek: number
            startTime: string
            endTime: string
            location: string
            weeks: number[]
        }[]
    }>): Promise<Course> => {
        const response = await apiClient.put<ApiResponse<Course>>(
            `/courses/${courseId}`,
            courseData
        )
        return response.data.data
    },

    // 删除课程
    deleteCourse: async (courseId: string): Promise<void> => {
        await apiClient.delete<ApiResponse>(`/courses/${courseId}`)
    },
}
