import { AIPlanService } from '../services/AIPlanService';
import { CompletedAIPlanResult, AssignmentPlan, RecommendedSchedule, ApiResponse, AIPlanStatus } from '../common/models/ApiModels';
import router from '@ohos.router';
import common from '@ohos.app.ability.common';
import { Logger } from '../common/utils/Logger';

interface RouterParams {
  planId?: string;
}

@Entry
@Component
struct AIPlanDetailPage {
  private context: common.Context = getContext(this) as common.Context;

  @State planId: string = '';
  @State planResult: CompletedAIPlanResult | null = null;
  @State isLoading: boolean = true;
  @State errorMessage: string = '';
  @State showApplyDialog: boolean = false;

  aboutToAppear(): void {
    const params = router.getParams() as RouterParams;
    if (params?.planId) {
      this.planId = params.planId;
      this.loadPlanDetail();
    }
  }

  loadPlanDetail(): void {
    this.isLoading = true;
    this.errorMessage = '';

    AIPlanService.getAIPlanResult(this.context, this.planId)
      .then((response: ApiResponse<CompletedAIPlanResult>) => {
        this.isLoading = false;
        if (response.code === 200 && response.data) {
          this.planResult = response.data;
          Logger.info('Plan detail loaded:', JSON.stringify(response.data));
        } else {
          this.errorMessage = response.message || '加载失败';
        }
      })
      .catch((error: Error) => {
        this.isLoading = false;
        this.errorMessage = `加载失败: ${error.message}`;
      });
  }

  applyPlan(): void {
    if (!this.planResult) return;

    this.isLoading = true;
    AIPlanService.applyAllPlan(this.context, this.planResult.planId)
      .then(() => {
        this.isLoading = false;
        this.showApplyDialog = true;
      })
      .catch((error: Error) => {
        this.isLoading = false;
        this.errorMessage = `应用失败: ${error.message}`;
      });
  }

  handleReturn(): void {
    this.showApplyDialog = false;
    router.back();
  }

  formatDate(dateString: string): string {
    try {
      const date = new Date(dateString);
      return `${date.getFullYear()}-${(date.getMonth() + 1).toString().padStart(2, '0')}-${date.getDate().toString().padStart(2, '0')}`;
    } catch {
      return dateString;
    }
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

  build() {
    Column() {
      // 顶部导航
      Row({ space: 12 }) {
        Button('返回').fontSize(16).fontColor('#007DFF').backgroundColor(Color.Transparent)
          .onClick(() => router.back())
        Text('规划详情').fontSize(20).fontWeight(FontWeight.Bold).layoutWeight(1).textAlign(TextAlign.Center)
        Text('').width(60)
      }.width('100%').padding({ left: 16, right: 16, top: 12, bottom: 12 }).backgroundColor('#FFFFFF')

      if (this.errorMessage) {
        Text(this.errorMessage).fontSize(14).fontColor('#FF3B30').padding(16)
      }

      if (this.isLoading) {
        Column() {
          LoadingProgress().width(50).height(50).color('#007DFF')
          Text('加载中...').fontSize(16).fontColor('#666666').margin({ top: 12 })
        }.width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
      } else if (this.planResult) {
        Scroll() {
          Column({ space: 16 }) {
            // 总结卡片
            if (this.planResult.summary) {
              Column({ space: 12 }) {
                Text('规划总结').fontSize(18).fontWeight(FontWeight.Bold).fontColor('#333333')
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
                }
              }.padding(16).backgroundColor('#FFFFFF').borderRadius(8)
            }

            Text('详细规划').fontSize(18).fontWeight(FontWeight.Bold).fontColor('#333333')

            // 每个作业的详细规划
            ForEach(this.planResult.assignments, (plan: AssignmentPlan) => {
              Column({ space: 8 }) {
                Row() {
                  Text(plan.assignmentTitle).fontSize(16).fontColor('#333333').fontWeight(FontWeight.Medium).layoutWeight(1)
                  Text(plan.difficulty).fontSize(12).fontColor('#007DFF')
                }.width('100%')

                Text(`预估 ${plan.estimatedHours} 小时`).fontSize(14).fontColor('#666666')

                if (plan.recommendedSchedule && plan.recommendedSchedule.length > 0) {
                  Text('推荐学习时间:').fontSize(14).fontColor('#333333').margin({ top: 8 })
                  ForEach(plan.recommendedSchedule, (schedule: RecommendedSchedule, index: number) => {
                    this.ScheduleItem(schedule)
                  })
                }
              }
              .padding(16).backgroundColor('#FFFFFF').borderRadius(8).width('100%').alignItems(HorizontalAlign.Start)
            })

            Text(`创建时间: ${this.formatDate(this.planResult.createdAt)}`).fontSize(12).fontColor('#999999')

            Button('应用此规划')
              .width('100%').height(48).backgroundColor('#007DFF').fontColor('#FFFFFF')
              .onClick(() => this.applyPlan())
          }.padding(16)
        }.layoutWeight(1)
      }

      // 成功弹窗
      if (this.showApplyDialog) {
        Column() {
          Column({ space: 20 }) {
            Text('✓').fontSize(48).fontColor('#34C759')
            Text('规划已应用成功！').fontSize(18).fontWeight(FontWeight.Bold)
            Text('学习任务已自动创建到课表中').fontSize(14).fontColor('#666666')
            Button('返回')
              .width('100%').height(45).backgroundColor('#007DFF').fontColor(Color.White)
              .onClick(() => this.handleReturn())
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
