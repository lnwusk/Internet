export class ApiResponse<T> {
  code: number = 0;
  message: string = '';
  data?: T | null = null;
}

export class LoginData {
  token: string = '';
  refreshToken?: string = '';
}

export class RegisterData {
  userId: string = '';
}

// 登录请求参数模型
export class LoginRequest {
  username: string = '';
  password: string = '';
}

// 注册请求参数模型
export class RegisterRequest {
  username: string = '';
  password: string = '';
  nickname?: string = '';
  studentId?: string = '';
}

// --- 课程管理模型 ---

// 课程简要信息 (嵌入在周视图中)
export class CourseBasic {
  courseId: string = '';
  courseName: string = '';
  location: string = '';
}

// 时间槽 (关联具体课程)
export class TimeSlot {
  startTime: string = '';
  endTime: string = '';
  course: CourseBasic = new CourseBasic();
}

// 每日课程安排
export class DailySchedule {
  dayOfWeek: number = 0;
  timeSlots: TimeSlot[] = [];
}

// 周视图响应数据
export class WeekScheduleData {
  semester: string = '';
  currentWeek: number = 1;
  requestedWeek: number = 1;
  schedule: DailySchedule[] = [];
}

// 完整课程信息 (用于课程列表或详情)
export class CourseDetail {
  courseId: string = '';
  courseName: string = '';
  courseCode: string = '';
  teacher: string = '';
  credits: number = 0;
  source: string = '';
  semester: string = '2025-2026-1'; // Default semester
  schedule: CourseScheduleItem[] = [];
}

// 课程的时间安排项
export class CourseScheduleItem {
  dayOfWeek: number = 0;
  startTime: string = '';
  endTime: string = '';
  location: string = '';
  weeks: number[] = [];
}

// 手动添加课程请求
export class AddCourseRequest {
  courseName: string = '';
  teacher?: string = '';
  courseCode?: string = '';
  credits?: number = 0;
  semester?: string = '2025-2026-1';
  schedule?: CourseScheduleItem[] = [];
}

// 课程列表响应数据
export class CourseListData {
  semester: string = '';
  courses: CourseDetail[] = [];
}

// --- 课表导入模型 ---

// 解析后的课程数据 (用于导入预览)
export class ImportedCourse {
  courseId: string = '';
  courseName: string = '';
  courseCode: string = '';
  teacher: string = '';
  credits: number = 0;
  source: string = 'official';
  schedule: CourseScheduleItem[] = [];
}

// 导入摘要
export class ImportSummary {
  totalCourses: number = 0;
  totalSchedules: number = 0;
}

// 上传解析响应
export class ImportUploadData {
  courses: ImportedCourse[] = [];
  summary: ImportSummary = new ImportSummary();
}

// 确认保存响应
export class ImportConfirmData {
  savedCount: number = 0;
  updatedCount: number = 0;
  failedCount: number = 0;
}

// 确认保存请求
export class ImportConfirmRequest {
  courses: ImportedCourse[] = [];
  semester: string = '';
}

// --- 学习任务模型 ---

// 学习任务
export class StudyTask {
  taskId: string = '';
  title: string = '';
  assignmentId: string = '';
  assignmentTitle: string = '';
  courseId: string = '';
  courseName: string = '';
  scheduledDate: string = '';  // YYYY-MM-DD
  startTime: string = '';       // HH:mm
  endTime: string = '';         // HH:mm
  estimatedHours: number = 0;
  status: string = 'pending';   // pending | in-progress | completed
  description: string = '';
  createdAt: string = '';
}

// 创建任务请求
export class CreateStudyTaskRequest {
  title: string = '';
  assignmentId: string = '';
  scheduledDate: string = '';
  startTime: string = '';
  endTime: string = '';
  estimatedHours: number = 0;
  description: string = '';
}

// 实际发送的任务请求体（可选字段不发送空值）
export class TaskRequestBody {
  title: string = '';
  scheduledDate: string = '';
  startTime: string = '';
  endTime: string = '';
  estimatedHours?: number;
  description?: string;
  assignmentId?: string;
}

// 学习任务列表响应
export class StudyTaskListData {
  tasks: StudyTask[] = [];
}

// --- 通知管理模型 ---

// 提醒设置
export class ReminderSetting {
  enabled: boolean = true;
  minutesBefore: number = 0;
  hoursBefore: number = 0;
}

// 通知设置
export class NotificationSettings {
  enabled: boolean = true;
  courseReminder: ReminderSetting = new ReminderSetting();
  assignmentReminder: ReminderSetting = new ReminderSetting();
  pushEnabled: boolean = true;
}

// 通知历史项
export class NotificationItem {
  notificationId: string = '';
  type: string = '';      // course | assignment
  title: string = '';
  content: string = '';
  relatedId: string = '';
  read: boolean = false;
  createdAt: string = '';
}

// 分页信息
export class Pagination {
  page: number = 1;
  pageSize: number = 20;
  total: number = 0;
  totalPages: number = 0;
}

// 通知历史响应
export class NotificationHistoryData {
  notifications: NotificationItem[] = [];
  pagination: Pagination = new Pagination();
}
