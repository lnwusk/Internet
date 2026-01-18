import common from '@ohos.app.ability.common';
import router from '@ohos.router';
import { HttpUtil } from '../common/utils/HttpUtil';
import { Logger } from '../common/utils/Logger';
import { WeekView } from './WeekView';

@Entry
@Component
struct Index {
  @State selectedIndex: number = 0;

  aboutToAppear() {
    this.checkLogin();
  }

  async checkLogin() {
    const context = getContext(this) as common.UIAbilityContext;
    const token = await HttpUtil.getToken(context);
    Logger.info('Current Token:', token);
    
    if (!token) {
      router.replaceUrl({ url: 'pages/LoginPage' });
    }
  }

  build() {
    Tabs({ barPosition: BarPosition.End, index: this.selectedIndex }) {
      // Tab 1: 课表
      TabContent() {
        WeekView()
      }
      .tabBar('课表')

      // Tab 2: 作业 (占位)
      TabContent() {
        Column() {
          Text('作业管理 (开发中...)')
            .fontSize(20)
        }
        .justifyContent(FlexAlign.Center)
        .width('100%')
        .height('100%')
      }
      .tabBar('作业')

      // Tab 3: 我的
      TabContent() {
        Scroll() {
          Column() {
            // 用户头像区域
            Column() {
              Text('👤')
                .fontSize(48)
                .margin({ top: 30, bottom: 8 })
              Text('用户')
                .fontSize(18)
                .fontWeight(FontWeight.Medium)
            }
            .width('100%')
            .padding({ bottom: 20 })

            // 功能列表
            Column() {
              // 通知设置
              Row() {
                Text('🔔').fontSize(20)
                Text('通知设置')
                  .fontSize(16)
                  .margin({ left: 12 })
                  .layoutWeight(1)
                Text('>').fontSize(16).fontColor('#999')
              }
              .padding(16)
              .width('100%')
              .backgroundColor(Color.White)
              .borderRadius({ topLeft: 12, topRight: 12 })
              .onClick(() => router.pushUrl({ url: 'pages/NotificationSettingsPage' }))

              Divider().color('#f0f0f0')

              // 通知历史
              Row() {
                Text('📋').fontSize(20)
                Text('通知历史')
                  .fontSize(16)
                  .margin({ left: 12 })
                  .layoutWeight(1)
                Text('>').fontSize(16).fontColor('#999')
              }
              .padding(16)
              .width('100%')
              .backgroundColor(Color.White)
              .borderRadius({ bottomLeft: 12, bottomRight: 12 })
              .onClick(() => router.pushUrl({ url: 'pages/NotificationHistoryPage' }))
            }
            .margin({ top: 20, left: 16, right: 16 })

            // 退出登录
            Button('退出登录')
              .width('90%')
              .height(48)
              .backgroundColor('#dc3545')
              .margin({ top: 40 })
              .onClick(async () => {
                const context = getContext(this) as common.UIAbilityContext;
                await HttpUtil.clearToken(context);
                router.replaceUrl({ url: 'pages/LoginPage' });
              })
          }
          .width('100%')
        }
        .width('100%')
        .height('100%')
        .backgroundColor('#f5f5f5')
      }
      .tabBar('我的')
    }
    .width('100%')
    .height('100%')
    .onChange((index: number) => {
      this.selectedIndex = index;
    })
  }
}