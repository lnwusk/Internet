import { ApiResponse, NotificationSettings, NotificationHistoryData, NotificationItem } from '../common/models/ApiModels';
import { HttpUtil } from '../common/utils/HttpUtil';
import common from '@ohos.app.ability.common';
import { Logger } from '../common/utils/Logger';

// 通知服务
export class NotificationService {

  /**
   * 获取通知设置
   * @param context 应用上下文
   */
  static async getSettings(context: common.Context): Promise<ApiResponse<NotificationSettings>> {
    Logger.info('NotificationService: Fetching notification settings');
    return await HttpUtil.get<ApiResponse<NotificationSettings>>(context, '/notifications/settings');
  }

  /**
   * 更新通知设置
   * @param context 应用上下文
   * @param settings 新的设置
   */
  static async updateSettings(
    context: common.Context,
    settings: NotificationSettings
  ): Promise<ApiResponse<NotificationSettings>> {
    Logger.info('NotificationService: Updating notification settings');
    return await HttpUtil.put<ApiResponse<NotificationSettings>>(context, '/notifications/settings', settings);
  }

  /**
   * 获取通知历史
   * @param context 应用上下文
   * @param type 通知类型 (可选): course | assignment | all
   * @param page 页码 (可选)
   * @param pageSize 每页数量 (可选)
   */
  static async getHistory(
    context: common.Context,
    type?: string,
    page?: number,
    pageSize?: number
  ): Promise<ApiResponse<NotificationHistoryData>> {
    Logger.info('NotificationService: Fetching notification history');

    let url = '/notifications/history?';
    if (type) {
      url += `type=${type}&`;
    }
    if (page) {
      url += `page=${page}&`;
    }
    if (pageSize) {
      url += `pageSize=${pageSize}&`;
    }

    // 移除末尾的 & 或 ?
    if (url.endsWith('&') || url.endsWith('?')) {
      url = url.slice(0, -1);
    }

    return await HttpUtil.get<ApiResponse<NotificationHistoryData>>(context, url);
  }

  /**
   * 标记通知为已读
   * @param context 应用上下文
   * @param notificationId 通知ID
   */
  static async markAsRead(
    context: common.Context,
    notificationId: string
  ): Promise<ApiResponse<NotificationItem>> {
    Logger.info(`NotificationService: Marking notification ${notificationId} as read`);
    const emptyBody: object = new Object();
    return await HttpUtil.post<ApiResponse<NotificationItem>>(
      context,
      `/notifications/${notificationId}/read`,
      emptyBody
    );
  }
}
