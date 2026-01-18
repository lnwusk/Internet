import common from '@ohos.app.ability.common';
import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { HttpUtil } from '../common/utils/HttpUtil';
import { Logger } from '../common/utils/Logger';
import { WeekView } from './WeekView';
import { AssignmentService } from '../services/AssignmentService';
import { UserService } from '../services/UserService';
import { AuthService } from '../services/AuthService';
import { Assignment, AssignmentListData, AssignmentStatus, SortBy, SortOrder, ApiResponse, UserProfile, UpdateProfileRequest } from '../common/models/ApiModels';

@Entry
@Component
struct Index {
  @State selectedIndex: number = 0;
  private context: common.Context = getContext(this) as common.Context;

  // 作业相关状态
  @State assignments: Assignment[] = [];
  @State pendingCount: number = 0;
  @State completedCount: number = 0;
  @State overdueCount: number = 0;
  @State assignmentLoading: boolean = true;
  @State assignmentTab: number = 0;

  // 用户相关状态
  @State userProfile: UserProfile | null = null;
  @State profileLoading: boolean = true;

  aboutToAppear() {
    this.checkLogin();
  }

  onPageShow() {
    // 页面重新显示时刷新当前 Tab 数据
    if (this.selectedIndex === 1) {
      this.loadAssignments();
    } else if (this.selectedIndex === 3) {
      this.loadUserProfile();
    }
  }

  async checkLogin() {
    const token = await HttpUtil.getToken(this.context);
    Logger.info('Current Token:', token);
    if (!token) {
      router.replaceUrl({ url: 'pages/LoginPage' });
    }
  }

  async loadAssignments(): Promise<void> {
    this.assignmentLoading = true;
    try {
      let response: ApiResponse<AssignmentListData>;
      switch (this.assignmentTab) {
        case 1:
          response = await AssignmentService.getPendingAssignments(this.context);
          break;
        case 2:
          response = await AssignmentService.getAssignments(this.context, { status: AssignmentStatus.COMPLETED });
          break;
        case 3:
          response = await AssignmentService.getOverdueAssignments(this.context);
          break;
        default:
          response = await AssignmentService.getAssignments(this.context, { sortBy: SortBy.DDL, order: SortOrder.ASC });
      }
      if (response.code === 200 && response.data) {
        this.assignments = response.data.assignments;
        this.pendingCount = response.data.pendingCount;
        this.completedCount = response.data.completedCount;
        this.overdueCount = response.data.overdueCount;
      }
    } catch (error) {
      Logger.error('Load assignments error:', JSON.stringify(error));
    } finally {
      this.assignmentLoading = false;
    }
  }

  async loadUserProfile(): Promise<void> {
    this.profileLoading = true;
    try {
      const response = await UserService.getUserProfile(this.context);
      if (response.code === 200 && response.data) {
        this.userProfile = response.data;
      }
    } catch (error) {
      Logger.error('Load profile error:', JSON.stringify(error));
    } finally {
      this.profileLoading = false;
    }
  }

  getStatusColor(status: string): string {
    if (status === AssignmentStatus.COMPLETED) return '#34C759';
    if (status === AssignmentStatus.OVERDUE) return '#FF3B30';
    return '#FF9500';
  }

  getStatusText(status: string): string {
    if (status === AssignmentStatus.COMPLETED) return '已完成';
    if (status === AssignmentStatus.OVERDUE) return '已逾期';
    return '待完成';
  }

  formatDate(dateString: string): string {
    try {
      const date = new Date(dateString);
      return `${date.getMonth() + 1}月${date.getDate()}日`;
    } catch {
      return dateString;
    }
  }

  build() {
    Tabs({ barPosition: BarPosition.End, index: this.selectedIndex }) {
      // Tab 1: 课表
      TabContent() {
        WeekView()
      }.tabBar('课表')

      // Tab 2: 作业
      TabContent() {
        this.AssignmentContent()
      }.tabBar('作业')

      // Tab 3: AI规划
      TabContent() {
        this.AIPlanContent()
      }.tabBar('AI规划')

      // Tab 4: 我的
      TabContent() {
        this.ProfileContent()
      }.tabBar('我的')
    }
    .width('100%')
    .height('100%')
    .onChange((index: number) => {
      this.selectedIndex = index;
      if (index === 1) {
        this.loadAssignments();
      } else if (index === 3) {
        this.loadUserProfile();
      }
    })
  }

  @Builder
  AssignmentContent() {
    Column() {
      Row({ space: 12 }) {
        Text('作业管理').fontSize(20).fontWeight(FontWeight.Bold).layoutWeight(1)
        Button('添加').fontSize(14).fontColor('#007DFF').backgroundColor(Color.Transparent)
          .onClick(() => router.pushUrl({ url: 'pages/AssignmentDetailPage', params: { mode: 'create' } }))
      }.width('100%').padding({ left: 16, right: 16, top: 12, bottom: 12 }).backgroundColor('#FFFFFF')

      // 统计卡片
      Row({ space: 12 }) {
        Column({ space: 4 }) {
          Text(this.pendingCount.toString()).fontSize(24).fontColor('#FF9500').fontWeight(FontWeight.Bold)
          Text('待完成').fontSize(12).fontColor('#666666')
        }.padding(12).backgroundColor('#FFF4E5').borderRadius(8).layoutWeight(1)
        Column({ space: 4 }) {
          Text(this.completedCount.toString()).fontSize(24).fontColor('#34C759').fontWeight(FontWeight.Bold)
          Text('已完成').fontSize(12).fontColor('#666666')
        }.padding(12).backgroundColor('#E6F4EA').borderRadius(8).layoutWeight(1)
        Column({ space: 4 }) {
          Text(this.overdueCount.toString()).fontSize(24).fontColor('#FF3B30').fontWeight(FontWeight.Bold)
          Text('已逾期').fontSize(12).fontColor('#666666')
        }.padding(12).backgroundColor('#FFEBE9').borderRadius(8).layoutWeight(1)
      }.padding({ left: 16, right: 16, top: 12, bottom: 12 })

      // Tabs
      Tabs({ barPosition: BarPosition.Start, index: this.assignmentTab }) {
        ForEach(['全部', '待完成', '已完成', '已逾期'], (tab: string, index: number) => {
          TabContent() {
            if (this.assignmentLoading) {
              Column() {
                LoadingProgress().width(50).height(50).color('#007DFF')
              }.width('100%').height('100%').justifyContent(FlexAlign.Center)
            } else if (this.assignments.length === 0) {
              Column() {
                Text('暂无作业').fontSize(18).fontColor('#8E8E93')
              }.width('100%').height('100%').justifyContent(FlexAlign.Center)
            } else {
              Scroll() {
                Column({ space: 0 }) {
                  ForEach(this.assignments, (a: Assignment) => {
                    this.AssignmentCard(a)
                  }, (a: Assignment) => a.assignmentId)
                }.padding(16)
              }.scrollable(ScrollDirection.Vertical).layoutWeight(1)
            }
          }.tabBar(tab)
        }, (tab: string) => tab)
      }
      .vertical(false).barMode(BarMode.Fixed).barHeight(48)
      .onChange((index: number) => {
        this.assignmentTab = index;
        this.loadAssignments();
      })
      .layoutWeight(1)
    }.width('100%').height('100%').backgroundColor('#F5F5F5')
  }

  @Builder
  AssignmentCard(assignment: Assignment) {
    Column({ space: 8 }) {
      Row() {
        Text(assignment.courseName).fontSize(14).fontColor('#666666').layoutWeight(1)
        Text(this.getStatusText(assignment.status))
          .fontSize(12).fontColor('#FFFFFF')
          .padding({ left: 8, right: 8, top: 2, bottom: 2 })
          .backgroundColor(this.getStatusColor(assignment.status)).borderRadius(10)
      }.width('100%')
      Text(assignment.title).fontSize(16).fontColor('#333333').fontWeight(FontWeight.Medium).width('100%').maxLines(2)

      if (assignment.description && assignment.description.length > 0) {
        Text(assignment.description).fontSize(14).fontColor('#666666').width('100%').maxLines(2)
      }

      Row() {
        Text(`截止: ${this.formatDate(assignment.dueDate)}`).fontSize(12).fontColor('#FF9500').layoutWeight(1)

        if (assignment.status === AssignmentStatus.PENDING) {
          Button('完成').width(60).height(28).backgroundColor('#007DFF').fontSize(12)
            .onClick(() => {
              this.onCompleteAssignment(assignment.assignmentId);
            })
        }
        if (assignment.source === 'manual') {
          Button('删除').width(60).height(28).margin({ left: 8 }).backgroundColor('#FF3B30').fontSize(12)
            .onClick(() => {
              this.onDeleteAssignment(assignment.assignmentId);
            })
        }
      }.width('100%').margin({ top: 8 })
    }
    .padding(16).backgroundColor('#FFFFFF').borderRadius(12)
    .shadow({ radius: 4, color: '#000000', offsetX: 0, offsetY: 2 }).margin({ bottom: 12 })
    .onClick(() => {
      router.pushUrl({ url: 'pages/AssignmentDetailPage', params: { assignmentId: assignment.assignmentId } });
    })
  }

  onCompleteAssignment(assignmentId: string): void {
    AssignmentService.completeAssignment(this.context, assignmentId)
      .then(() => {
        Logger.info('Assignment completed:', assignmentId);
        this.loadAssignments();
      })
      .catch((error: Error) => {
        Logger.error('Complete assignment error:', error.message);
      });
  }

  onDeleteAssignment(assignmentId: string): void {
    AssignmentService.deleteAssignment(this.context, assignmentId)
      .then(() => {
        Logger.info('Assignment deleted:', assignmentId);
        this.loadAssignments();
      })
      .catch((error: Error) => {
        Logger.error('Delete assignment error:', error.message);
      });
  }

  @Builder
  AIPlanContent() {
    Column() {
      Row({ space: 12 }) {
        Text('AI智能规划').fontSize(20).fontWeight(FontWeight.Bold).layoutWeight(1)
        Button('历史').fontSize(14).fontColor('#007DFF').backgroundColor(Color.Transparent)
          .onClick(() => router.pushUrl({ url: 'pages/AIPlanHistoryPage' }))
      }.width('100%').padding({ left: 16, right: 16, top: 12, bottom: 12 }).backgroundColor('#FFFFFF')

      Column({ space: 20 }) {
        Text('让AI帮你安排学习计划').fontSize(16).fontColor('#666666')
        Text('选择待完成作业，AI将根据截止日期和难度自动生成学习计划').fontSize(14).fontColor('#999999').textAlign(TextAlign.Center).padding({ left: 20, right: 20 })
        Button('开始规划')
          .width('80%').height(48).backgroundColor('#007DFF')
          .onClick(() => router.pushUrl({ url: 'pages/AIPlanPage' }))
      }.width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
    }.width('100%').height('100%').backgroundColor('#F5F5F5')
  }

  @Builder
  ProfileContent() {
    Column() {
      Row() {
        Text('个人中心').fontSize(20).fontWeight(FontWeight.Bold).layoutWeight(1)
      }.width('100%').padding({ left: 16, right: 16, top: 12, bottom: 12 }).backgroundColor('#FFFFFF')

      if (this.profileLoading) {
        Column() {
          LoadingProgress().width(50).height(50).color('#007DFF')
        }.width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
      } else {
        Scroll() {
          Column({ space: 0 }) {
            // 基本信息
            Column({ space: 12 }) {
              Text(this.userProfile?.nickname || '用户').fontSize(18).fontWeight(FontWeight.Medium)
              Text(`学号: ${this.userProfile?.studentId || '-'}`).fontSize(14).fontColor('#666666')
            }.padding(24).backgroundColor('#FFFFFF').width('100%').alignItems(HorizontalAlign.Center)

            // 功能入口
            Column({ space: 0 }) {
              this.MenuRow('通知设置', () => router.pushUrl({ url: 'pages/NotificationSettingsPage' }))
              Divider().color('#E5E5E5')
              this.MenuRow('通知历史', () => router.pushUrl({ url: 'pages/NotificationHistoryPage' }))
              Divider().color('#E5E5E5')
              this.MenuRow('AI规划历史', () => router.pushUrl({ url: 'pages/AIPlanHistoryPage' }))
              Divider().color('#E5E5E5')
              this.MenuRow('修改密码', () => router.pushUrl({ url: 'pages/ChangePasswordPage' }))
              Divider().color('#E5E5E5')
              this.MenuRow('编辑资料', () => router.pushUrl({ url: 'pages/UserProfilePage' }))
            }.margin({ top: 12, left: 12, right: 12 }).borderRadius(8).clip(true).backgroundColor('#FFFFFF')

            // 退出登录
            Button('退出登录')
              .width('90%').height(48).backgroundColor('#FF3B30').fontColor('#FFFFFF')
              .fontSize(16).margin({ top: 32 })
              .onClick(() => this.logout())
          }
        }.scrollable(ScrollDirection.Vertical).layoutWeight(1)
      }
    }.width('100%').height('100%').backgroundColor('#F5F5F5')
  }

  @Builder
  MenuRow(title: string, onClick: () => void) {
    Row() {
      Text(title).fontSize(16).fontColor('#333333').layoutWeight(1)
      Text('>').fontSize(16).fontColor('#C7C7CC')
    }.padding(16).width('100%').onClick(onClick)
  }

  async logout(): Promise<void> {
    await AuthService.logout(this.context);
    router.replaceUrl({ url: 'pages/LoginPage' });
  }
}