import common from '@ohos.app.ability.common';
import router from '@ohos.router';
import { Logger } from '../common/utils/Logger';
import { NotificationService } from '../services/NotificationService';
import { NotificationSettings, ReminderSetting } from '../common/models/ApiModels';

@Entry
@Component
export struct NotificationSettingsPage {
  @State isLoading: boolean = false;
  @State errorMessage: string = '';
  @State successMessage: string = '';

  // 使用独立@State变量确保UI刷新 (避免使用enabled保留名)
  @State notifyEnabled: boolean = true;
  @State pushEnabled: boolean = true;
  @State courseReminderEnabled: boolean = true;
  @State courseMinutes: number = 15;
  @State assignmentReminderEnabled: boolean = true;
  @State assignmentHours: number = 24;

  private context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;

  aboutToAppear() {
    this.loadSettings();
  }

  async loadSettings() {
    this.isLoading = true;
    try {
      const response = await NotificationService.getSettings(this.context);
      if (response.code === 200 && response.data) {
        const data = response.data;
        this.notifyEnabled = data.enabled;
        this.pushEnabled = data.pushEnabled;
        this.courseReminderEnabled = data.courseReminder.enabled;
        this.courseMinutes = data.courseReminder.minutesBefore || 15;
        this.assignmentReminderEnabled = data.assignmentReminder.enabled;
        this.assignmentHours = data.assignmentReminder.hoursBefore || 24;
        Logger.info('Settings loaded');
      }
    } catch (err) {
      Logger.error('Load settings failed:', JSON.stringify(err));
    } finally {
      this.isLoading = false;
    }
  }

  async saveSettings() {
    this.isLoading = true;
    this.errorMessage = '';
    this.successMessage = '';

    try {
      // 构建设置对象
      const settings: NotificationSettings = new NotificationSettings();
      settings.enabled = this.notifyEnabled;
      settings.pushEnabled = this.pushEnabled;
      settings.courseReminder.enabled = this.courseReminderEnabled;
      settings.courseReminder.minutesBefore = this.courseMinutes;
      settings.assignmentReminder.enabled = this.assignmentReminderEnabled;
      settings.assignmentReminder.hoursBefore = this.assignmentHours;

      const response = await NotificationService.updateSettings(this.context, settings);
      if (response.code === 200) {
        this.successMessage = '保存成功';
        Logger.info('Settings saved');
      } else {
        this.errorMessage = response.message || '保存失败';
      }
    } catch (err) {
      Logger.error('Save failed:', JSON.stringify(err));
      this.errorMessage = '保存失败';
    } finally {
      this.isLoading = false;
    }
  }

  build() {
    Column() {
      // 顶部导航
      Row() {
        Button({ type: ButtonType.Circle }) {
          Text('←').fontSize(20).fontColor('#333')
        }
        .width(36).height(36).backgroundColor('#f5f5f5')
        .onClick(() => router.back())

        Text('通知设置')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        Blank().width(36)
      }
      .padding(12)
      .width('100%')
      .backgroundColor(Color.White)

      // 设置列表
      Scroll() {
        Column() {
          // 总开关区域
          Column() {
            Text('通知').fontSize(14).fontColor('#999').margin({ bottom: 8 })

            // 启用通知
            Row() {
              Column() {
                Text('启用通知').fontSize(16).fontColor('#333')
                Text('开启后可接收课程和作业提醒').fontSize(13).fontColor('#999').margin({ top: 2 })
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)

              Toggle({ type: ToggleType.Switch, isOn: this.notifyEnabled })
                .onChange((isOn: boolean) => { this.notifyEnabled = isOn; })
            }
            .width('100%')
            .padding({ top: 14, bottom: 14 })
            .border({ width: { bottom: 1 }, color: '#f0f0f0' })

            // 推送通知
            Row() {
              Column() {
                Text('推送通知').fontSize(16).fontColor('#333')
                Text('允许应用发送推送消息').fontSize(13).fontColor('#999').margin({ top: 2 })
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)

              Toggle({ type: ToggleType.Switch, isOn: this.pushEnabled })
                .onChange((isOn: boolean) => { this.pushEnabled = isOn; })
            }
            .width('100%')
            .padding({ top: 14, bottom: 14 })
          }
          .padding(16)
          .backgroundColor(Color.White)
          .borderRadius(12)
          .margin({ bottom: 12 })

          // 课程提醒区域
          Column() {
            Text('课程提醒').fontSize(14).fontColor('#999').margin({ bottom: 8 })

            Row() {
              Column() {
                Text('课前提醒').fontSize(16).fontColor('#333')
                Text('上课前收到提醒通知').fontSize(13).fontColor('#999').margin({ top: 2 })
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)

              Toggle({ type: ToggleType.Switch, isOn: this.courseReminderEnabled })
                .onChange((isOn: boolean) => { this.courseReminderEnabled = isOn; })
            }
            .width('100%')
            .padding({ top: 14, bottom: 14 })
            .border({ width: { bottom: 1 }, color: '#f0f0f0' })

            // 提前时间设置
            if (this.courseReminderEnabled) {
              Row() {
                Text('提前时间')
                  .fontSize(16)
                  .fontColor('#333')
                  .layoutWeight(1)

                Row() {
                  Button('−')
                    .width(44).height(44)
                    .fontSize(24)
                    .fontColor('#333')
                    .backgroundColor('#e0e0e0')
                    .borderRadius(22)
                    .onClick(() => {
                      if (this.courseMinutes > 5) {
                        this.courseMinutes -= 5;
                        Logger.info(`Course: ${this.courseMinutes} min`);
                      }
                    })

                  Text(`${this.courseMinutes} 分钟`)
                    .fontSize(16)
                    .fontColor('#333')
                    .fontWeight(FontWeight.Medium)
                    .margin({ left: 16, right: 16 })
                    .width(100)
                    .textAlign(TextAlign.Center)

                  Button('+')
                    .width(44).height(44)
                    .fontSize(24)
                    .fontColor('#333')
                    .backgroundColor('#e0e0e0')
                    .borderRadius(22)
                    .onClick(() => {
                      this.courseMinutes += 5;
                      Logger.info(`Course: ${this.courseMinutes} min`);
                    })
                }
              }
              .width('100%')
              .padding({ top: 14, bottom: 14 })
            }
          }
          .padding(16)
          .backgroundColor(Color.White)
          .borderRadius(12)
          .margin({ bottom: 12 })

          // 作业提醒区域
          Column() {
            Text('作业提醒').fontSize(14).fontColor('#999').margin({ bottom: 8 })

            Row() {
              Column() {
                Text('截止日期提醒').fontSize(16).fontColor('#333')
                Text('作业截止前收到提醒').fontSize(13).fontColor('#999').margin({ top: 2 })
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)

              Toggle({ type: ToggleType.Switch, isOn: this.assignmentReminderEnabled })
                .onChange((isOn: boolean) => { this.assignmentReminderEnabled = isOn; })
            }
            .width('100%')
            .padding({ top: 14, bottom: 14 })
            .border({ width: { bottom: 1 }, color: '#f0f0f0' })

            // 提前时间设置
            if (this.assignmentReminderEnabled) {
              Row() {
                Text('提前时间')
                  .fontSize(16)
                  .fontColor('#333')
                  .layoutWeight(1)

                Row() {
                  Button('−')
                    .width(44).height(44)
                    .fontSize(24)
                    .fontColor('#333')
                    .backgroundColor('#e0e0e0')
                    .borderRadius(22)
                    .onClick(() => {
                      if (this.assignmentHours > 1) {
                        this.assignmentHours -= 1;
                        Logger.info(`Assignment: ${this.assignmentHours} hours`);
                      }
                    })

                  Text(`${this.assignmentHours} 小时`)
                    .fontSize(16)
                    .fontColor('#333')
                    .fontWeight(FontWeight.Medium)
                    .margin({ left: 16, right: 16 })
                    .width(100)
                    .textAlign(TextAlign.Center)

                  Button('+')
                    .width(44).height(44)
                    .fontSize(24)
                    .fontColor('#333')
                    .backgroundColor('#e0e0e0')
                    .borderRadius(22)
                    .onClick(() => {
                      this.assignmentHours += 1;
                      Logger.info(`Assignment: ${this.assignmentHours} hours`);
                    })
                }
              }
              .width('100%')
              .padding({ top: 14, bottom: 14 })
            }
          }
          .padding(16)
          .backgroundColor(Color.White)
          .borderRadius(12)

          // 消息提示
          if (this.errorMessage) {
            Text(this.errorMessage).fontSize(14).fontColor('#dc3545').margin({ top: 16 })
          }
          if (this.successMessage) {
            Text(this.successMessage).fontSize(14).fontColor('#28a745').margin({ top: 16 })
          }
        }
        .padding(12)
      }
      .layoutWeight(1)
      .backgroundColor('#f5f5f5')

      // 保存按钮
      Column() {
        Button('保存设置')
          .width('100%')
          .height(48)
          .backgroundColor('#007DFF')
          .onClick(() => this.saveSettings())
      }
      .padding(16)
      .backgroundColor(Color.White)

      // 加载遮罩
      if (this.isLoading) {
        Column() {
          LoadingProgress().width(40).height(40)
        }
        .width('100%')
        .height('100%')
        .position({ x: 0, y: 0 })
        .backgroundColor('rgba(255,255,255,0.7)')
        .justifyContent(FlexAlign.Center)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#f5f5f5')
  }
}
