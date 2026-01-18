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

// --- 作业管理模型 ---

// 作业状态
export enum AssignmentStatus {
  PENDING = 'pending',
  COMPLETED = 'completed',
  OVERDUE = 'overdue'
}

// 作业来源
export enum AssignmentSource {
  MOODLE = 'moodle',
  MANUAL = 'manual'
}

// 作业难度
export enum AssignmentDifficulty {
  EASY = 'easy',
  MEDIUM = 'medium',
  HARD = 'hard'
}

// 作业类型
export enum AssignmentType {
  PROGRAMMING = 'programming',
  ESSAY = 'essay',
  REPORT = 'report',
  PRESENTATION = 'presentation'
}

// 排序方式
export enum SortBy {
  DDL = 'ddl',
  CREATED = 'created'
}

// 排序顺序
export enum SortOrder {
  ASC = 'asc',
  DESC = 'desc'
}

// 基础作业信息
export class Assignment {
  assignmentId: string = '';
  courseId: string = '';
  courseName: string = '';
  title: string = '';
  description: string = '';
  dueDate: string = '';
  status: string = 'pending';
  source: string = 'manual';
  moodleUrl: string = '';
  estimatedHours: number = 0;
  completedAt: string = '';
  createdAt: string = '';
}

// 作业详情
export class AssignmentDetail extends Assignment {
  difficulty: string = '';
  type: string = '';
  wordCount: number = 0;
}

// 作业列表数据
export class AssignmentListData {
  assignments: Assignment[] = [];
  total: number = 0;
  pendingCount: number = 0;
  completedCount: number = 0;
  overdueCount: number = 0;
}

// 创建作业请求
export class CreateAssignmentRequest {
  courseId: string = '';
  title: string = '';
  description: string = '';
  dueDate: string = '';
  type: string = '';
  wordCount: number = 0;
  difficulty: string = '';
}

// 更新作业请求
export class UpdateAssignmentRequest {
  courseId?: string;
  title?: string;
  description?: string;
  dueDate?: string;
  type?: string;
  wordCount?: number;
  difficulty?: string;
}

// 作业操作响应
export class AssignmentOperationResponse {
  assignmentId: string = '';
  title: string = '';
  source: string = '';
  createdAt: string = '';
}

// 标记完成响应
export class CompleteAssignmentResponse {
  assignmentId: string = '';
  status: string = '';
  completedAt: string = '';
}

// 作业查询参数
export class AssignmentQueryParams {
  courseId?: string;
  status?: string;
  sortBy?: string;
  order?: string;
}

// --- AI 规划模型 ---

// AI规划状态
export enum AIPlanStatus {
  PROCESSING = 'processing',
  COMPLETED = 'completed',
  FAILED = 'failed'
}

// AI规划偏好
export class AIPlanPreferences {
  preferredStudyTime: string = 'morning';
  dailyMaxHours: number = 6;
  avoidWeekend: boolean = false;
}

// 提交AI规划请求
export class SubmitAIPlanRequest {
  assignmentIds: string[] = [];
  startDate: string = '';
  endDate: string = '';
  preferences: AIPlanPreferences = new AIPlanPreferences();
}

// 提交AI规划响应
export class SubmitAIPlanResponse {
  planId: string = '';
  status: string = 'processing';
  estimatedTime: number = 30;
}

// 推荐的时间段
export class RecommendedSchedule {
  date: string = '';
  startTime: string = '';
  endTime: string = '';
  hours: number = 0;
  reason: string = '';
}

// 作业规划详情
export class AssignmentPlan {
  assignmentId: string = '';
  assignmentTitle: string = '';
  estimatedHours: number = 0;
  difficulty: string = '';
  recommendedSchedule: RecommendedSchedule[] = [];
}

// 规划总结
export class PlanSummary {
  totalAssignments: number = 0;
  totalEstimatedHours: number = 0;
  scheduledDays: number = 0;
  averageDailyHours: number = 0;
}

// 完成的AI规划结果
export class CompletedAIPlanResult {
  planId: string = '';
  status: string = '';
  assignments: AssignmentPlan[] = [];
  summary: PlanSummary = new PlanSummary();
  createdAt: string = '';
}

// 应用AI规划选中项
export class ApplyPlanSelectedItem {
  assignmentId: string = '';
  scheduleIndex: number = 0;
}

// 应用AI规划请求
export class ApplyAIPlanRequest {
  applyAll: boolean = true;
  selectedItems: ApplyPlanSelectedItem[] = [];
}

// 应用AI规划响应
export class ApplyAIPlanResponse {
  createdTasks: number = 0;
  taskIds: string[] = [];
}

// AI规划历史记录
export class AIPlanHistory {
  planId: string = '';
  status: string = '';
  assignmentCount: number = 0;
  createdAt: string = '';
}

// AI规划历史数据
export class AIPlanHistoryData {
  plans: AIPlanHistory[] = [];
  pagination: Pagination = new Pagination();
}

// AI规划历史查询参数
export class AIPlanHistoryQueryParams {
  page: number = 1;
  pageSize: number = 10;
}

// --- 用户管理模型 ---

// 用户偏好设置
export class UserPreferences {
  notificationEnabled: boolean = true;
  courseReminderMinutes: number = 15;
  assignmentReminderHours: number = 24;
  preferredStudyTime: string = 'morning';
}

// 用户信息
export class UserProfile {
  userId: string = '';
  username: string = '';
  nickname: string = '';
  studentId: string = '';
  avatar: string = '';
  createdAt: string = '';
  preferences: UserPreferences = new UserPreferences();
}

// 更新用户信息请求
export class UpdateProfileRequest {
  nickname?: string;
  studentId?: string;
  avatar?: string;
}

// 更新用户偏好请求
export class UpdatePreferencesRequest {
  notificationEnabled: boolean = true;
  courseReminderMinutes: number = 15;
  assignmentReminderHours: number = 24;
  preferredStudyTime: string = 'morning';
}

// 更新用户信息响应
export class UpdateProfileResponse {
  userId: string = '';
  nickname: string = '';
  studentId: string = '';
  avatar: string = '';
}

// 修改密码请求
export class ChangePasswordRequest {
  oldPassword: string = '';
  newPassword: string = '';
}

