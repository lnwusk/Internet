import { AIPlanService } from '../services/AIPlanService';
import { AssignmentService } from '../services/AssignmentService';
import { Assignment, SubmitAIPlanRequest, SubmitAIPlanResponse, CompletedAIPlanResult, AIPlanPreferences, AssignmentPlan, RecommendedSchedule, ApiResponse, AIPlanStatus } from '../common/models/ApiModels';
import router from '@ohos.router';
import common from '@ohos.app.ability.common';
import { Logger } from '../common/utils/Logger';

@Entry
@Component
struct AIPlanPage {
  private context: common.Context = getContext(this) as common.Context;

  @State assignments: Assignment[] = [];
  @State selectedIds: string[] = [];
  @State isLoading: boolean = true;
  @State isSubmitting: boolean = false;
  @State errorMessage: string = '';

  @State planResult: CompletedAIPlanResult | null = null;
  @State showResult: boolean = false;
  @State showSuccessDialog: boolean = false;

  // 偏好设置
  @State preferredStudyTime: string = 'morning';
  @State dailyMaxHours: number = 6;
  @State avoidWeekend: boolean = false;

  aboutToAppear(): void {
    this.loadPendingAssignments();
  }

  async loadPendingAssignments(): Promise<void> {
    this.isLoading = true;
    try {
      const response = await AssignmentService.getPendingAssignments(this.context);
      if (response.code === 200 && response.data) {
        this.assignments = response.data.assignments;
      }
    } catch (error) {
      const err = error as Error;
      this.errorMessage = `加载失败: ${err.message}`;
    } finally {
      this.isLoading = false;
    }
  }

  toggleSelection(assignmentId: string): void {
    const index = this.selectedIds.indexOf(assignmentId);
    if (index >= 0) {
      this.selectedIds = this.selectedIds.filter(id => id !== assignmentId);
    } else {
      this.selectedIds = [...this.selectedIds, assignmentId];
    }
  }

  selectAll(): void {
    if (this.selectedIds.length === this.assignments.length) {
      this.selectedIds = [];
    } else {
      this.selectedIds = this.assignments.map(a => a.assignmentId);
    }
  }

  submitPlan(): void {
    if (this.selectedIds.length === 0) {
      this.errorMessage = '请选择至少一个作业';
      return;
    }

    this.isSubmitting = true;
    this.errorMessage = '';

    const preferences: AIPlanPreferences = new AIPlanPreferences();
    preferences.preferredStudyTime = this.preferredStudyTime;
    preferences.dailyMaxHours = this.dailyMaxHours;
    preferences.avoidWeekend = this.avoidWeekend;

    const request: SubmitAIPlanRequest = new SubmitAIPlanRequest();
    request.assignmentIds = this.selectedIds;
    request.startDate = '';
    request.endDate = '';
    request.preferences = preferences;

    AIPlanService.submitAIPlan(this.context, request)
      .then((submitResponse: ApiResponse<SubmitAIPlanResponse>) => {
        if (submitResponse.code === 200 && submitResponse.data) {
          const planId = submitResponse.data.planId;
          return AIPlanService.pollAIPlanResult(this.context, planId);
        } else {
          throw new Error(submitResponse.message || '提交失败');
        }
      })
      .then((resultResponse: ApiResponse<CompletedAIPlanResult>) => {
        this.isSubmitting = false;
        if (resultResponse.code === 200 && resultResponse.data) {
          this.planResult = resultResponse.data;
          this.showResult = true;
        }
      })
      .catch((error: Error) => {
        this.isSubmitting = false;
        this.errorMessage = `规划失败: ${error.message}`;
      });
  }

  applyPlan(): void {
    if (!this.planResult) return;

    this.isSubmitting = true;
    AIPlanService.applyAllPlan(this.context, this.planResult.planId)
      .then(() => {
        this.isSubmitting = false;
        this.showSuccessDialog = true;
      })
      .catch((error: Error) => {
        this.isSubmitting = false;
        this.errorMessage = `应用失败: ${error.message}`;
      });
  }

  handleReturnToIndex(): void {
    this.showSuccessDialog = false;
    router.back();
  }

  @Builder
  AssignmentItem(assignment: Assignment) {
    Row({ space: 12 }) {
      Checkbox({ name: assignment.assignmentId })
        .select(this.selectedIds.includes(assignment.assignmentId))
        .onChange(() => this.toggleSelection(assignment.assignmentId))

      Column({ space: 4 }) {
        Text(assignment.title).fontSize(16).fontColor('#333333').fontWeight(FontWeight.Medium)
        Text(assignment.courseName).fontSize(14).fontColor('#666666')
        Text(`截止: ${assignment.dueDate.substring(0, 10)}`).fontSize(12).fontColor('#FF9500')
      }.layoutWeight(1).alignItems(HorizontalAlign.Start)
    }
    .padding(16).backgroundColor('#FFFFFF').borderRadius(8).margin({ bottom: 8 })
    .onClick(() => this.toggleSelection(assignment.assignmentId))
  }

  @Builder
  PreferencesSection() {
    Column({ space: 16 }) {
      Text('偏好设置').fontSize(18).fontWeight(FontWeight.Bold).fontColor('#333333')

      Row() {
        Text('偏好学习时间').fontSize(16).fontColor('#333333').layoutWeight(1)
        Row({ space: 8 }) {
          ForEach(['morning', 'afternoon', 'evening'], (time: string) => {
            Button(time === 'morning' ? '上午' : time === 'afternoon' ? '下午' : '晚上')
              .fontSize(12).height(32)
              .fontColor(this.preferredStudyTime === time ? '#FFFFFF' : '#007DFF')
              .backgroundColor(this.preferredStudyTime === time ? '#007DFF' : '#E3F2FD')
              .onClick(() => { this.preferredStudyTime = time; })
          })
        }
      }

      Row() {
        Text('每日最大学习时长').fontSize(16).fontColor('#333333').layoutWeight(1)
        Text(`${this.dailyMaxHours}小时`).fontSize(16).fontColor('#007DFF')
      }
      Slider({ value: this.dailyMaxHours, min: 2, max: 10, step: 1 })
        .onChange((value: number) => { this.dailyMaxHours = value; })

      Row() {
        Text('避开周末').fontSize(16).fontColor('#333333').layoutWeight(1)
        Toggle({ type: ToggleType.Switch, isOn: this.avoidWeekend })
          .onChange((isOn: boolean) => { this.avoidWeekend = isOn; })
      }
    }.padding(16).backgroundColor('#FFFFFF').borderRadius(8).margin({ top: 12 })
  }

  @Builder
  ScheduleItem(schedule: RecommendedSchedule) {
    Row({ space: 12 }) {
      Column({ space: 4 }) {
        Text(schedule.date).fontSize(14).fontColor('#007DFF').fontWeight(FontWeight.Medium)
        Text(`${schedule.startTime} - ${schedule.endTime}`).fontSize(12).fontColor('#666666')
      }.width(100)

      Column({ space: 4 }) {
        Text(`${schedule.hours} 小时`).fontSize(14).fontColor('#FF9500')
        if (schedule.reason) {
          Text(schedule.reason).fontSize(12).fontColor('#999999').maxLines(2)
        }
      }.layoutWeight(1).alignItems(HorizontalAlign.Start)
    }
    .padding(12).backgroundColor('#F8F8F8').borderRadius(6).margin({ top: 8 })
  }

  @Builder
  PlanResultView() {
    Column({ space: 16 }) {
      Text('规划结果').fontSize(20).fontWeight(FontWeight.Bold).fontColor('#333333')

      if (this.planResult && this.planResult.summary) {
        // 总结卡片
        Row({ space: 12 }) {
          Column({ space: 4 }) {
            Text(this.planResult.summary.totalAssignments.toString()).fontSize(24).fontColor('#007DFF').fontWeight(FontWeight.Bold)
            Text('作业数').fontSize(12).fontColor('#666666')
          }.layoutWeight(1)

          Column({ space: 4 }) {
            Text(this.planResult.summary.totalEstimatedHours.toFixed(1)).fontSize(24).fontColor('#FF9500').fontWeight(FontWeight.Bold)
            Text('预估小时').fontSize(12).fontColor('#666666')
          }.layoutWeight(1)

          Column({ space: 4 }) {
            Text(this.planResult.summary.scheduledDays.toString()).fontSize(24).fontColor('#34C759').fontWeight(FontWeight.Bold)
            Text('安排天数').fontSize(12).fontColor('#666666')
          }.layoutWeight(1)
        }.padding(16).backgroundColor('#FFFFFF').borderRadius(8)

        Text('详细规划').fontSize(18).fontWeight(FontWeight.Bold).fontColor('#333333').margin({ top: 16 })

        // 每个作业的详细规划
        ForEach(this.planResult.assignments, (plan: AssignmentPlan) => {
          Column({ space: 8 }) {
            Row() {
              Text(plan.assignmentTitle).fontSize(16).fontColor('#333333').fontWeight(FontWeight.Medium).layoutWeight(1)
              Text(`${plan.difficulty}`).fontSize(12).fontColor('#007DFF')
            }.width('100%')

            Text(`预估 ${plan.estimatedHours} 小时`).fontSize(14).fontColor('#666666')

            // 推荐的时间安排
            if (plan.recommendedSchedule && plan.recommendedSchedule.length > 0) {
              Text('推荐学习时间:').fontSize(14).fontColor('#333333').margin({ top: 8 })
              ForEach(plan.recommendedSchedule, (schedule: RecommendedSchedule, index: number) => {
                this.ScheduleItem(schedule)
              })
            }
          }
          .padding(16).backgroundColor('#FFFFFF').borderRadius(8).width('100%').alignItems(HorizontalAlign.Start).margin({ top: 8 })
        })

        Text('应用规划后，系统将自动在课表中创建对应的学习任务').fontSize(12).fontColor('#999999').margin({ top: 12 })
      }

      Row({ space: 16 }) {
        Button('返回修改').layoutWeight(1).height(48).backgroundColor('#E5E5E5').fontColor('#333333')
          .onClick(() => { this.showResult = false; })
        Button('应用规划').layoutWeight(1).height(48).backgroundColor('#007DFF').fontColor('#FFFFFF')
          .onClick(() => this.applyPlan())
      }.margin({ top: 16 })
    }.padding(16)
  }

  build() {
    Column() {
      Row({ space: 12 }) {
        Button('返回').fontSize(16).fontColor('#007DFF').backgroundColor(Color.Transparent)
          .onClick(() => router.back())
        Text('AI智能规划').fontSize(20).fontWeight(FontWeight.Bold).layoutWeight(1).textAlign(TextAlign.Center)
        Button('历史').fontSize(16).fontColor('#007DFF').backgroundColor(Color.Transparent)
          .onClick(() => router.pushUrl({ url: 'pages/AIPlanHistoryPage' }))
      }.width('100%').padding({ left: 16, right: 16, top: 12, bottom: 12 }).backgroundColor('#FFFFFF')

      if (this.errorMessage) {
        Text(this.errorMessage).fontSize(14).fontColor('#FF3B30').padding(16)
      }

      if (this.showResult && this.planResult) {
        Scroll() {
          this.PlanResultView()
        }.layoutWeight(1)
      } else if (this.isLoading || this.isSubmitting) {
        Column() {
          LoadingProgress().width(50).height(50).color('#007DFF')
          Text(this.isSubmitting ? 'AI分析中...' : '加载中...').fontSize(16).fontColor('#666666').margin({ top: 12 })
        }.width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
      } else if (this.assignments.length === 0) {
        Column() {
          Text('暂无待完成作业').fontSize(18).fontColor('#8E8E93')
        }.width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
      } else {
        Scroll() {
          Column({ space: 0 }) {
            Row() {
              Text(`选择作业 (${this.selectedIds.length}/${this.assignments.length})`).fontSize(16).fontColor('#333333').layoutWeight(1)
              Button(this.selectedIds.length === this.assignments.length ? '取消全选' : '全选')
                .fontSize(14).fontColor('#007DFF').backgroundColor(Color.Transparent)
                .onClick(() => this.selectAll())
            }.padding({ left: 16, right: 16, top: 12, bottom: 12 })

            Column() {
              ForEach(this.assignments, (assignment: Assignment) => {
                this.AssignmentItem(assignment)
              }, (a: Assignment) => a.assignmentId)
            }.padding({ left: 16, right: 16 })

            this.PreferencesSection()
          }
        }.layoutWeight(1)

        Button('开始规划')
          .width('90%').height(48).backgroundColor('#007DFF').fontColor('#FFFFFF')
          .margin({ bottom: 24 })
          .onClick(() => this.submitPlan())
      }

      // 成功弹窗
      if (this.showSuccessDialog) {
        Column() {
          Column({ space: 20 }) {
            Text('✓').fontSize(48).fontColor('#34C759')
            Text('规划已应用成功！').fontSize(18).fontWeight(FontWeight.Bold)
            Text('学习任务已自动创建到课表中').fontSize(14).fontColor('#666666')
            Button('返回首页')
              .width('100%').height(45).backgroundColor('#007DFF').fontColor(Color.White)
              .onClick(() => this.handleReturnToIndex())
          }
          .width('80%').padding(24).backgroundColor(Color.White).borderRadius(12)
        }
        .width('100%').height('100%')
        .backgroundColor('rgba(0,0,0,0.5)')
        .justifyContent(FlexAlign.Center)
        .position({ x: 0, y: 0 }).zIndex(999)
      }
    }.width('100%').height('100%').backgroundColor('#F5F5F5')
  }
}
