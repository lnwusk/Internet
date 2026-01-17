import common from '@ohos.app.ability.common';
import { NotificationService } from '../services/NotificationService';
import { CourseService } from '../services/CourseService';
import { StudyTaskService } from '../services/StudyTaskService';
import { NotificationSettings } from '../models/ApiModels';
import { Logger } from './Logger';

// 通知检查器 - 定时检查并触发通知
export class NotificationChecker {
  private static instance: NotificationChecker | null = null;
  private intervalId: number = -1;
  private settings: NotificationSettings = new NotificationSettings();
  private checkIntervalMs: number = 60000; // 每分钟检查一次
  private notifiedCourses: Set<string> = new Set(); // 已通知的课程
  private notifiedTasks: Set<string> = new Set();   // 已通知的任务

  private constructor() {}

  static getInstance(): NotificationChecker {
    if (!NotificationChecker.instance) {
      NotificationChecker.instance = new NotificationChecker();
    }
    return NotificationChecker.instance;
  }

  // 获取今天的日期 (YYYY-MM-DD)
  getTodayDate(): string {
    const now = new Date();
    const year = now.getFullYear();
    const month = (now.getMonth() + 1).toString().padStart(2, '0');
    const day = now.getDate().toString().padStart(2, '0');
    return `${year}-${month}-${day}`;
  }

  // 获取今天是周几 (1-7)
  getTodayDayOfWeek(): number {
    const day = new Date().getDay();
    return day === 0 ? 7 : day;
  }

  // 获取当前时间 (HH:mm)
  getCurrentTime(): string {
    const now = new Date();
    const hours = now.getHours().toString().padStart(2, '0');
    const minutes = now.getMinutes().toString().padStart(2, '0');
    return `${hours}:${minutes}`;
  }

  // 时间差计算 (分钟)
  getTimeDiffMinutes(time1: string, time2: string): number {
    const [h1, m1] = time1.split(':').map(Number);
    const [h2, m2] = time2.split(':').map(Number);
    return (h1 * 60 + m1) - (h2 * 60 + m2);
  }

  // 启动检查器
  async start(context: common.Context) {
    Logger.info('NotificationChecker: Starting...');
    await this.loadSettings(context);

    if (this.intervalId === -1) {
      this.intervalId = setInterval(() => {
        this.checkNotifications(context);
      }, this.checkIntervalMs);

      // 立即执行一次检查
      this.checkNotifications(context);
      Logger.info('NotificationChecker: Timer started');
    }
  }

  // 停止检查器
  stop() {
    if (this.intervalId !== -1) {
      clearInterval(this.intervalId);
      this.intervalId = -1;
      Logger.info('NotificationChecker: Stopped');
    }
  }

  // 每天重置已通知记录
  resetDailyNotifications() {
    this.notifiedCourses.clear();
    this.notifiedTasks.clear();
    Logger.info('NotificationChecker: Daily notifications reset');
  }

  // 加载通知设置
  async loadSettings(context: common.Context) {
    try {
      const response = await NotificationService.getSettings(context);
      if (response.code === 200 && response.data) {
        this.settings = response.data;
        Logger.info('NotificationChecker: Settings loaded');
      }
    } catch (err) {
      Logger.error('NotificationChecker: Failed to load settings', JSON.stringify(err));
    }
  }

  // 检查通知
  private async checkNotifications(context: common.Context) {
    if (!this.settings.enabled) {
      return;
    }

    const now = this.getCurrentTime();
    const today = this.getTodayDate();
    const todayDayOfWeek = this.getTodayDayOfWeek();

    Logger.info(`NotificationChecker: Checking at ${now} on ${today} (day ${todayDayOfWeek})`);

    // 检查课程提醒
    if (this.settings.courseReminder.enabled) {
      await this.checkCourseReminders(context, todayDayOfWeek, now);
    }

    // 检查任务提醒
    if (this.settings.assignmentReminder.enabled) {
      await this.checkTaskReminders(context, today, now);
    }
  }

  // 检查课程提醒
  private async checkCourseReminders(context: common.Context, todayDayOfWeek: number, currentTime: string) {
    const minutesBefore = this.settings.courseReminder.minutesBefore || 15;

    try {
      const response = await CourseService.getWeekSchedule(context);
      if (response.code === 200 && response.data && response.data.schedule) {
        // 找到今天的课程
        const todaySchedule = response.data.schedule.find(d => d.dayOfWeek === todayDayOfWeek);
        if (todaySchedule && todaySchedule.timeSlots) {
          for (const slot of todaySchedule.timeSlots) {
            const courseKey = `${todayDayOfWeek}-${slot.startTime}-${slot.course.courseId}`;

            // 跳过已通知的
            if (this.notifiedCourses.has(courseKey)) continue;

            // 计算距上课时间差
            const diffMinutes = this.getTimeDiffMinutes(slot.startTime, currentTime);

            // 在指定时间范围内提醒 (提前minutesBefore到提前0分钟)
            if (diffMinutes > 0 && diffMinutes <= minutesBefore) {
              this.notifiedCourses.add(courseKey);
              this.sendNotification(
                `📚 ${slot.course.courseName}`,
                `${diffMinutes}分钟后上课，地点：${slot.course.location || '未知'}`
              );
              Logger.info(`NotificationChecker: Course reminder sent for ${slot.course.courseName}`);
            }
          }
        }
      }
    } catch (err) {
      Logger.error('NotificationChecker: Failed to check courses', JSON.stringify(err));
    }
  }

  // 检查任务提醒
  private async checkTaskReminders(context: common.Context, today: string, currentTime: string) {
    try {
      const response = await StudyTaskService.getStudyTasks(context, undefined, today);
      if (response.code === 200 && response.data && response.data.tasks) {
        for (const task of response.data.tasks) {
          const taskKey = `${task.taskId}-${task.startTime}`;

          // 跳过已完成或已通知的
          if (task.status === 'completed' || this.notifiedTasks.has(taskKey)) continue;

          // 计算距任务开始时间差
          const diffMinutes = this.getTimeDiffMinutes(task.startTime, currentTime);

          // 提前15分钟提醒任务
          if (diffMinutes > 0 && diffMinutes <= 15) {
            this.notifiedTasks.add(taskKey);
            this.sendNotification(
              `⏰ ${task.title}`,
              `${diffMinutes}分钟后开始`
            );
            Logger.info(`NotificationChecker: Task reminder sent for ${task.title}`);
          }
        }
      }
    } catch (err) {
      Logger.error('NotificationChecker: Failed to check tasks', JSON.stringify(err));
    }
  }

  // 发送本地通知
  private sendNotification(title: string, content: string) {
    Logger.info(`🔔 NOTIFICATION: ${title} - ${content}`);

    // 完整实现需要使用 @ohos.notificationManager API
    // import notificationManager from '@ohos.notificationManager';
    // const request: notificationManager.NotificationRequest = {
    //   id: Date.now(),
    //   content: {
    //     contentType: notificationManager.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
    //     normal: { title: title, text: content }
    //   }
    // };
    // await notificationManager.publish(request);
  }
}
