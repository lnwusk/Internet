import { ApiResponse, WeekScheduleData, CourseDetail, AddCourseRequest, CourseListData } from '../common/models/ApiModels';
import { HttpUtil } from '../common/utils/HttpUtil';
import common from '@ohos.app.ability.common';
import { Logger } from '../common/utils/Logger';

export class CourseService {

  /**
   * 获取周课程表
   * @param context 应用上下文
   * @param week 可选，指定的周次
   * @param semester 可选，指定的学期
   */
  static async getWeekSchedule(context: common.Context, week?: number, semester?: string): Promise<ApiResponse<WeekScheduleData>> {
    let url = '/courses/week-schedule?';
    if (week) {
      url += `week=${week}&`;
    }
    if (semester) {
      url += `semester=${semester}&`;
    }
    
    // Remove trailing & or ? if empty (though ? won't hurt usually, cleaner to trim)
    if (url.endsWith('&') || url.endsWith('?')) {
        url = url.slice(0, -1);
    }
    
    Logger.info(`CourseService: Fetching week schedule for week ${week || 'current'} semester ${semester || 'current'}`);
    return await HttpUtil.get<ApiResponse<WeekScheduleData>>(context, url);
  }

  /**
   * 获取所有课程列表
   * @param context 应用上下文
   */
  static async getCourseList(context: common.Context, semester?: string): Promise<ApiResponse<CourseListData>> {
    Logger.info('CourseService: Fetching all courses');
    let url = '/courses';
    if (semester) {
      url += `?semester=${semester}`;
    }
    return await HttpUtil.get<ApiResponse<CourseListData>>(context, url);
  }

  /**
   * 获取单个课程详情 (模拟接口，实际调用列表接口筛选)
   * @param context 应用上下文
   * @param courseId 课程ID
   * @param semester 学期 (可选，优化查询)
   */
  static async getCourseById(context: common.Context, courseId: string, semester?: string): Promise<ApiResponse<CourseDetail>> {
    Logger.info(`CourseService: Fetching detail for course ${courseId} via list`);
    try {
        // 由于后端不支持 GET /courses/{id}，我们需要获取列表后筛选
        let url = '/courses';
        if (semester) {
            url += `?semester=${semester}`;
        }
        
        const response = await HttpUtil.get<ApiResponse<CourseListData>>(context, url);
        
        if (response.code === 200 && response.data && response.data.courses) {
            const found = response.data.courses.find(c => c.courseId === courseId);
            if (found) {
                return {
                    code: 200,
                    message: '获取成功',
                    data: found
                };
            } else {
                return {
                    code: 404,
                    message: '未找到该课程',
                    data: new CourseDetail()
                };
            }
        }
        
        return {
            code: response.code,
            message: response.message || '获取课程列表失败',
            data: new CourseDetail()
        };
    } catch (err) {
        Logger.error('getCourseById failed', JSON.stringify(err));
        throw new Error(JSON.stringify(err));
    }
  }

  /**
   * 手动添加课程
   * @param context 应用上下文
   * @param courseReq 课程请求对象
   */
  static async addCourse(context: common.Context, courseReq: AddCourseRequest): Promise<ApiResponse<CourseDetail>> {
    Logger.info('CourseService: Adding new course');
    return await HttpUtil.post<ApiResponse<CourseDetail>>(context, '/courses', courseReq);
  }

  /**
   * 删除课程
   * @param context 应用上下文
   * @param courseId 课程ID
   */
  static async deleteCourse(context: common.Context, courseId: string): Promise<ApiResponse<null>> {
    Logger.info(`CourseService: Deleting course ${courseId}`);
    return await HttpUtil.delete<ApiResponse<null>>(context, `/courses/${courseId}`);
  }

  /**
   * 更新课程
   * @param context 应用上下文
   * @param courseId 课程ID
   * @param courseReq 更新请求对象
   */
  static async updateCourse(context: common.Context, courseId: string, courseReq: AddCourseRequest): Promise<ApiResponse<CourseDetail>> {
    Logger.info(`CourseService: Updating course ${courseId}`);
    return await HttpUtil.put<ApiResponse<CourseDetail>>(context, `/courses/${courseId}`, courseReq);
  }
}
