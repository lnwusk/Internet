import { AssignmentService } from '../services/AssignmentService';
import { Assignment, AssignmentListData, AssignmentStatus, SortBy, SortOrder, ApiResponse } from '../common/models/ApiModels';
import promptAction from '@ohos.promptAction';
import router from '@ohos.router';
import common from '@ohos.app.ability.common';

@Entry
@Component
struct AssignmentListPage {
  private context: common.Context = getContext(this) as common.Context;

  @State assignments: Assignment[] = [];
  @State total: number = 0;
  @State pendingCount: number = 0;
  @State completedCount: number = 0;
  @State overdueCount: number = 0;

  @State isLoading: boolean = true;
  @State errorMessage: string = '';
  @State activeTab: number = 0;
  @State sortOrder: string = SortOrder.ASC;

  private readonly tabs: string[] = ['全部', '待完成', '已完成', '已逾期'];

  aboutToAppear(): void {
    this.loadAssignments();
  }

  async loadAssignments(): Promise<void> {
    this.isLoading = true;
    this.errorMessage = '';

    try {
      let response: ApiResponse<AssignmentListData>;
      switch (this.activeTab) {
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
          response = await AssignmentService.getAssignments(this.context, { sortBy: SortBy.DDL, order: this.sortOrder });
      }

      if (response.code === 200 && response.data) {
        this.assignments = response.data.assignments;
        this.total = response.data.total;
        this.pendingCount = response.data.pendingCount;
        this.completedCount = response.data.completedCount;
        this.overdueCount = response.data.overdueCount;
      }
    } catch (error) {
      const err = error as Error;
      this.errorMessage = `加载失败: ${err.message}`;
    } finally {
      this.isLoading = false;
    }
  }

  onTabChange(index: number): void {
    if (this.activeTab !== index) {
      this.activeTab = index;
      this.loadAssignments();
    }
  }

  formatDate(dateString: string): string {
    try {
      const date = new Date(dateString);
      return `${date.getMonth() + 1}月${date.getDate()}日`;
    } catch {
      return dateString;
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

  async onCompleteAssignment(assignmentId: string): Promise<void> {
    try {
      await AssignmentService.completeAssignment(this.context, assignmentId);
      const index = this.assignments.findIndex(item => item.assignmentId === assignmentId);
      if (index !== -1) {
        this.assignments[index].status = AssignmentStatus.COMPLETED;
        this.assignments = [...this.assignments];
      }
      promptAction.showToast({ message: '标记完成成功', duration: 2000 });
    } catch (error) {
      const err = error as Error;
      promptAction.showToast({ message: `标记失败: ${err.message}`, duration: 3000 });
    }
  }

  async onDeleteAssignment(assignmentId: string): Promise<void> {
    try {
      await AssignmentService.deleteAssignment(this.context, assignmentId);
      this.assignments = this.assignments.filter(item => item.assignmentId !== assignmentId);
      this.total -= 1;
      promptAction.showToast({ message: '删除成功', duration: 2000 });
    } catch (error) {
      const err = error as Error;
      promptAction.showToast({ message: `删除失败: ${err.message}`, duration: 3000 });
    }
  }

  @Builder
  LoadingState() {
    Column() {
      LoadingProgress().width(50).height(50).color('#007DFF')
      Text('加载中...').fontSize(16).fontColor('#666666').margin({ top: 12 })
    }.width('100%').height('100%').justifyContent(FlexAlign.Center)
  }

  @Builder
  ErrorState() {
    Column({ space: 20 }) {
      Text('加载失败').fontSize(18).fontColor('#FF3B30')
      Text(this.errorMessage).fontSize(14).fontColor('#666666').textAlign(TextAlign.Center)
      Button('重试').width(120).height(40).backgroundColor('#007DFF').onClick(() => this.loadAssignments())
    }.width('100%').height('100%').justifyContent(FlexAlign.Center).padding(40)
  }

  @Builder
  EmptyState() {
    Column({ space: 20 }) {
      Text('暂无作业').fontSize(18).fontColor('#8E8E93').fontWeight(FontWeight.Medium)
      Text('添加你的第一个作业').fontSize(14).fontColor('#C7C7CC')
    }.width('100%').height('100%').justifyContent(FlexAlign.Center)
  }

  @Builder
  StatsCard() {
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
            .onClick(() => this.onCompleteAssignment(assignment.assignmentId))
        }
        if (assignment.source === 'manual') {
          Button('删除').width(60).height(28).margin({ left: 8 }).backgroundColor('#FF3B30').fontSize(12)
            .onClick(() => this.onDeleteAssignment(assignment.assignmentId))
        }
      }.width('100%').margin({ top: 8 })
    }
    .padding(16).backgroundColor('#FFFFFF').borderRadius(12)
    .shadow({ radius: 4, color: '#000000', offsetX: 0, offsetY: 2 }).margin({ bottom: 12 })
    .onClick(() => {
      router.pushUrl({ url: 'pages/AssignmentDetailPage', params: { assignmentId: assignment.assignmentId } });
    })
  }

  build() {
    Column() {
      Row({ space: 12 }) {
        Text('作业管理').fontSize(20).fontWeight(FontWeight.Bold).layoutWeight(1)
        Button('添加').fontSize(14).fontColor('#007DFF').backgroundColor(Color.Transparent)
          .onClick(() => router.pushUrl({ url: 'pages/AssignmentDetailPage', params: { mode: 'create' } }))
      }.width('100%').padding({ left: 16, right: 16, top: 12, bottom: 12 }).backgroundColor('#FFFFFF')

      this.StatsCard()

      Tabs({ barPosition: BarPosition.Start, index: this.activeTab }) {
        ForEach(this.tabs, (tab: string, index: number) => {
          TabContent() {
            if (this.isLoading) {
              this.LoadingState()
            } else if (this.errorMessage) {
              this.ErrorState()
            } else if (this.assignments.length === 0) {
              this.EmptyState()
            } else {
              Scroll() {
                Column({ space: 0 }) {
                  ForEach(this.assignments, (assignment: Assignment) => {
                    this.AssignmentCard(assignment)
                  }, (assignment: Assignment) => assignment.assignmentId)
                }.padding(16)
              }.scrollable(ScrollDirection.Vertical).layoutWeight(1)
            }
          }.tabBar(tab)
        }, (tab: string) => tab)
      }
      .vertical(false).barMode(BarMode.Fixed).barWidth('100%').barHeight(48)
      .onChange((index: number) => this.onTabChange(index))
      .layoutWeight(1)
    }.width('100%').height('100%').backgroundColor('#F5F5F5')
  }
}
