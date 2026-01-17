import { ApiResponse, StudyTask, StudyTaskListData, CreateStudyTaskRequest, TaskRequestBody } from '../common/models/ApiModels';
import { HttpUtil } from '../common/utils/HttpUtil';
import common from '@ohos.app.ability.common';
import { Logger } from '../common/utils/Logger';

// 学习任务服务
export class StudyTaskService {

  /**
   * 获取学习任务列表
   * @param context 应用上下文
   * @param week 周次 (可选)
   * @param date 日期 YYYY-MM-DD (可选)
   * @param assignmentId 关联作业ID (可选)
   */
  static async getStudyTasks(
    context: common.Context,
    week?: number,
    date?: string,
    assignmentId?: string
  ): Promise<ApiResponse<StudyTaskListData>> {
    Logger.info('StudyTaskService: Fetching study tasks');

    let url = '/study-tasks?';
    if (week) {
      url += `week=${week}&`;
    }
    if (date) {
      url += `date=${date}&`;
    }
    if (assignmentId) {
      url += `assignmentId=${assignmentId}&`;
    }

    // 移除末尾的 & 或 ?
    if (url.endsWith('&') || url.endsWith('?')) {
      url = url.slice(0, -1);
    }

    return await HttpUtil.get<ApiResponse<StudyTaskListData>>(context, url);
  }

  /**
   * 创建学习任务
   * @param context 应用上下文
   * @param task 任务请求对象
   */
  static async createStudyTask(
    context: common.Context,
    task: CreateStudyTaskRequest
  ): Promise<ApiResponse<StudyTask>> {
    Logger.info(`StudyTaskService: Creating study task: ${task.title}`);

    // 构建请求体，过滤空的assignmentId（后端不接受空字符串）
    const requestBody: TaskRequestBody = new TaskRequestBody();
    requestBody.title = task.title;
    requestBody.scheduledDate = task.scheduledDate;
    requestBody.startTime = task.startTime;
    requestBody.endTime = task.endTime;
    if (task.estimatedHours > 0) {
      requestBody.estimatedHours = task.estimatedHours;
    }
    if (task.description && task.description.length > 0) {
      requestBody.description = task.description;
    }
    // 只有当assignmentId有值时才添加
    if (task.assignmentId && task.assignmentId.length > 0) {
      requestBody.assignmentId = task.assignmentId;
    }

    return await HttpUtil.post<ApiResponse<StudyTask>>(context, '/study-tasks', requestBody);
  }

  /**
   * 更新学习任务
   * @param context 应用上下文
   * @param taskId 任务ID
   * @param updates 更新内容
   */
  static async updateStudyTask(
    context: common.Context,
    taskId: string,
    updates: Partial<CreateStudyTaskRequest>
  ): Promise<ApiResponse<StudyTask>> {
    Logger.info(`StudyTaskService: Updating study task: ${taskId}`);
    return await HttpUtil.put<ApiResponse<StudyTask>>(context, `/study-tasks/${taskId}`, updates);
  }

  /**
   * 删除学习任务
   * @param context 应用上下文
   * @param taskId 任务ID
   */
  static async deleteStudyTask(
    context: common.Context,
    taskId: string
  ): Promise<ApiResponse<null>> {
    Logger.info(`StudyTaskService: Deleting study task: ${taskId}`);
    return await HttpUtil.delete<ApiResponse<null>>(context, `/study-tasks/${taskId}`);
  }

  /**
   * 标记任务完成
   * @param context 应用上下文
   * @param taskId 任务ID
   */
  static async completeStudyTask(
    context: common.Context,
    taskId: string
  ): Promise<ApiResponse<StudyTask>> {
    Logger.info(`StudyTaskService: Completing study task: ${taskId}`);
    const emptyBody: object = new Object();
    return await HttpUtil.post<ApiResponse<StudyTask>>(context, `/study-tasks/${taskId}/complete`, emptyBody);
  }
}
