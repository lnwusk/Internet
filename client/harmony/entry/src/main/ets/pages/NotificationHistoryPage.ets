import common from '@ohos.app.ability.common';
import router from '@ohos.router';
import { Logger } from '../common/utils/Logger';
import { NotificationService } from '../services/NotificationService';
import { NotificationItem, Pagination } from '../common/models/ApiModels';

@Entry
@Component
export struct NotificationHistoryPage {
  @State isLoading: boolean = false;
  @State notifications: NotificationItem[] = [];
  @State pagination: Pagination = new Pagination();
  @State selectedType: string = 'all';
  @State errorMessage: string = '';

  private context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
  private typeOptions: SelectOption[] = [
    { value: 'all' },
    { value: 'course' },
    { value: 'assignment' }
  ];

  aboutToAppear() {
    this.loadHistory();
  }

  async loadHistory() {
    this.isLoading = true;
    this.errorMessage = '';

    try {
      const typeParam = this.selectedType === 'all' ? undefined : this.selectedType;
      const response = await NotificationService.getHistory(
        this.context,
        typeParam,
        this.pagination.page,
        20
      );

      if (response.code === 200 && response.data) {
        this.notifications = response.data.notifications;
        this.pagination = response.data.pagination;
        Logger.info(`Loaded ${this.notifications.length} notifications`);
      } else {
        this.errorMessage = response.message || '加载失败';
      }
    } catch (err) {
      Logger.error('Load history failed:', JSON.stringify(err));
      this.errorMessage = '加载失败';
    } finally {
      this.isLoading = false;
    }
  }

  async markAsRead(notification: NotificationItem) {
    if (notification.read) return;

    try {
      const response = await NotificationService.markAsRead(this.context, notification.notificationId);
      if (response.code === 200) {
        // 更新本地状态
        const index = this.notifications.findIndex(n => n.notificationId === notification.notificationId);
        if (index >= 0) {
          this.notifications[index].read = true;
          // 触发UI刷新
          this.notifications = [...this.notifications];
        }
      }
    } catch (err) {
      Logger.error('Mark as read failed:', JSON.stringify(err));
    }
  }

  getTypeLabel(type: string): string {
    if (type === 'course') return '📚 课程';
    if (type === 'assignment') return '📝 作业';
    return '📢 通知';
  }

  getTypeColor(type: string): string {
    if (type === 'course') return '#E3F2FD';
    if (type === 'assignment') return '#FFF3E0';
    return '#F5F5F5';
  }

  formatTime(dateStr: string): string {
    const date = new Date(dateStr);
    const now = new Date();
    const diff = now.getTime() - date.getTime();

    const minutes = Math.floor(diff / 60000);
    const hours = Math.floor(diff / 3600000);
    const days = Math.floor(diff / 86400000);

    if (minutes < 60) return `${minutes}分钟前`;
    if (hours < 24) return `${hours}小时前`;
    if (days < 7) return `${days}天前`;

    return `${date.getMonth() + 1}/${date.getDate()}`;
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

        Text('通知历史')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        // 类型筛选
        Select(this.typeOptions)
          .value(this.selectedType)
          .font({ size: 12 })
          .backgroundColor('#f0f0f0')
          .borderRadius(8)
          .onSelect((index, value) => {
            this.selectedType = value;
            this.pagination.page = 1;
            this.loadHistory();
          })
      }
      .padding(12)
      .width('100%')
      .backgroundColor(Color.White)

      // 通知列表
      if (this.isLoading && this.notifications.length === 0) {
        Column() {
          LoadingProgress().width(40).height(40)
          Text('加载中...').fontSize(14).fontColor('#999').margin({ top: 12 })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else if (this.notifications.length === 0) {
        Column() {
          Text('📭').fontSize(48)
          Text('暂无通知').fontSize(16).fontColor('#999').margin({ top: 12 })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        List({ space: 8 }) {
          ForEach(this.notifications, (item: NotificationItem) => {
            ListItem() {
              Column() {
                Row() {
                  Text(this.getTypeLabel(item.type))
                    .fontSize(12)
                    .fontColor('#666')
                    .padding({ left: 8, right: 8, top: 4, bottom: 4 })
                    .backgroundColor(this.getTypeColor(item.type))
                    .borderRadius(4)

                  Blank()

                  if (!item.read) {
                    Circle()
                      .width(8)
                      .height(8)
                      .fill('#007DFF')
                  }

                  Text(this.formatTime(item.createdAt))
                    .fontSize(12)
                    .fontColor('#999')
                    .margin({ left: 8 })
                }
                .width('100%')
                .margin({ bottom: 8 })

                Text(item.title)
                  .fontSize(16)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(item.read ? '#666' : '#333')

                Text(item.content)
                  .fontSize(14)
                  .fontColor('#999')
                  .margin({ top: 4 })
                  .maxLines(2)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
              }
              .alignItems(HorizontalAlign.Start)
              .padding(16)
              .backgroundColor(Color.White)
              .borderRadius(12)
              .onClick(() => this.markAsRead(item))
            }
          })

          // 加载更多
          if (this.pagination.page < this.pagination.totalPages) {
            ListItem() {
              Button('加载更多')
                .width('100%')
                .height(44)
                .backgroundColor('#f0f0f0')
                .fontColor('#666')
                .onClick(() => {
                  this.pagination.page += 1;
                  this.loadHistory();
                })
            }
          }
        }
        .padding(12)
        .layoutWeight(1)
        .backgroundColor('#f5f5f5')
      }

      // 错误消息
      if (this.errorMessage) {
        Text(this.errorMessage)
          .fontSize(14)
          .fontColor('#dc3545')
          .padding(12)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#f5f5f5')
  }
}
