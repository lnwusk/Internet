// API响应格式
export interface ApiResponse<T = any> {
  code: number
  message: string
  data: T
  error?: {
    code: string
    details: string
  }
}

// 用户相关类型
export interface User {
  userId: string
  username: string
  nickname: string
  studentId?: string
  avatar?: string
  createdAt: string
}

export interface LoginRequest {
  username: string
  password: string
}

export interface LoginResponse {
  token: string
  refreshToken: string
  expiresIn: number
  user: User
}

export interface RegisterRequest {
  username: string
  password: string
  studentId?: string
  nickname?: string
}

export interface RegisterResponse {
  userId: string
  username: string
  nickname: string
  studentId?: string
  createdAt: string
}

export interface RefreshTokenResponse {
  token: string
  expiresIn: number
}

// 课程相关类型
export interface CourseSchedule {
  dayOfWeek: number
  startTime: string
  endTime: string
  location: string
  weeks: number[]
}

export interface Course {
  courseId: string
  courseName: string
  courseCode?: string
  teacher?: string
  credits?: number
  source: 'official' | 'manual' | 'moodle'
  semester?: string
  schedule?: CourseSchedule[]
  createdAt?: string
  updatedAt?: string
}

export interface CourseListResponse {
  semester: string
  courses: Course[]
}

export interface WeekScheduleResponse {
  semester: string
  currentWeek: number
  requestedWeek: number
  schedule: DaySchedule[]
}

export interface DaySchedule {
  dayOfWeek: number
  timeSlots: TimeSlot[]
}

export interface TimeSlot {
  startTime: string
  endTime: string
  course: {
    courseId: string
    courseName: string
    location: string
  }
}

// 上传课表相关
export interface UploadCoursesResponse {
  courses: Course[]
  summary: {
    totalCourses: number
    totalSchedules: number
  }
}

export interface ConfirmCoursesRequest {
  courses: {
    courseId?: string
    courseName: string
    courseCode?: string
    teacher?: string
    credits?: number
    schedule?: CourseSchedule[]
  }[]
  semester: string
}

