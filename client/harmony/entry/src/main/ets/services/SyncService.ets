import { ApiResponse, ImportUploadData, ImportConfirmData, ImportedCourse, ImportConfirmRequest } from '../common/models/ApiModels';
import { HttpUtil } from '../common/utils/HttpUtil';
import common from '@ohos.app.ability.common';
import { Logger } from '../common/utils/Logger';

// 数据同步服务 - 处理课表导入
export class SyncService {

  /**
   * 上传xlsx文件并获取解析预览
   * @param context 应用上下文
   * @param fileUri 文件URI
   * @param fileName 文件名
   * @param semester 学期 (可选)
   */
  static async uploadCourseFile(
    context: common.Context,
    fileUri: string,
    fileName: string,
    semester?: string
  ): Promise<ApiResponse<ImportUploadData>> {
    Logger.info(`SyncService: Uploading course file ${fileName}`);

    const formFields: Record<string, string> = {};
    if (semester) {
      formFields['semester'] = semester;
    }

    return await HttpUtil.uploadFile<ApiResponse<ImportUploadData>>(
      context,
      '/sync/courses/upload',
      fileUri,
      fileName,
      formFields
    );
  }

  /**
   * 确认保存解析的课程数据
   * @param context 应用上下文
   * @param courses 课程列表
   * @param semester 学期
   */
  static async confirmCourses(
    context: common.Context,
    courses: ImportedCourse[],
    semester: string
  ): Promise<ApiResponse<ImportConfirmData>> {
    Logger.info(`SyncService: Confirming ${courses.length} courses for semester ${semester}`);

    const requestData: ImportConfirmRequest = new ImportConfirmRequest();
    requestData.courses = courses;
    requestData.semester = semester;

    return await HttpUtil.post<ApiResponse<ImportConfirmData>>(
      context,
      '/sync/courses/confirm',
      requestData
    );
  }
}
