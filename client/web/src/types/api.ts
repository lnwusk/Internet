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

// 作业相关类型
export interface Assignment {
  assignmentId: string
  courseId: string
  courseName: string
  title: string
  description?: string
  dueDate: string
  status: 'pending' | 'completed' | 'overdue'
  source: 'moodle' | 'manual'
  moodleUrl?: string
  estimatedHours?: number
  difficulty?: 'easy' | 'medium' | 'hard'
  type?: string
  wordCount?: number
  completedAt?: string
  createdAt: string
}

export interface AssignmentDetail extends Assignment {
  // 扩展字段可在这里添加
}

export interface AssignmentListResponse {
  assignments: Assignment[]
  total: number
  pendingCount: number
  completedCount: number
  overdueCount: number
}

// 学习任务相关类型
export interface StudyTask {
  taskId: string
  title: string
  assignmentId?: string
  assignmentTitle?: string
  courseId?: string
  courseName?: string
  scheduledDate: string
  startTime: string
  endTime: string
  estimatedHours?: number
  status: 'pending' | 'in-progress' | 'completed'
  createdAt: string
  completedAt?: string
}

export interface StudyTaskListResponse {
  tasks: StudyTask[]
}

// AI规划相关类型
export interface AiPlanResponse {
  planId: string
  status: 'processing' | 'completed' | 'failed'
  progress?: number
  assignments?: AssignmentPlan[]
  summary?: PlanSummary
  createdAt: string
}

export interface AssignmentPlan {
  assignmentId: string
  assignmentTitle: string
  estimatedHours: number
  difficulty: string
  recommendedSchedule: ScheduleSlot[]
}

export interface ScheduleSlot {
  date: string
  startTime: string
  endTime: string
  hours: number
  reason: string
}

export interface PlanSummary {
  totalAssignments: number
  totalEstimatedHours: number
  scheduledDays: number
  averageDailyHours: number
}

export interface AiPlanHistoryResponse {
  plans: Array<{
    planId: string
    status: string
    assignmentCount: number
    createdAt: string
  }>
  pagination: {
    page: number
    pageSize: number
    total: number
    totalPages: number
  }
}

// 用户管理相关类型
export interface UserProfile {
  userId: string
  username: string
  nickname: string
  studentId?: string
  avatar?: string
  createdAt: string
  preferences?: UserPreferences
}

export interface UserPreferences {
  notificationEnabled: boolean
  courseReminderMinutes: number
  assignmentReminderHours: number
  preferredStudyTime?: 'morning' | 'afternoon' | 'evening'
}

// 通知相关类型
export interface NotificationSettings {
  enabled: boolean
  courseReminder: {
    enabled: boolean
    minutesBefore: number
  }
  assignmentReminder: {
    enabled: boolean
    hoursBefore: number
  }
  pushEnabled: boolean
}

export interface Notification {
  notificationId: string
  type: 'course' | 'assignment'
  title: string
  content: string
  relatedId: string
  read: boolean
  createdAt: string
}

export interface NotificationHistoryResponse {
  notifications: Notification[]
  pagination: {
    page: number
    pageSize: number
    total: number
    totalPages: number
  }
}

