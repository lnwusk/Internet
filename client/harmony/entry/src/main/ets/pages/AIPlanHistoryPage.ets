import { AIPlanService } from '../services/AIPlanService';
import { AIPlanHistoryData, AIPlanHistory, AIPlanStatus, ApiResponse, Pagination, AIPlanHistoryQueryParams } from '../common/models/ApiModels';
import promptAction from '@ohos.promptAction';
import router from '@ohos.router';
import common from '@ohos.app.ability.common';

// 状态信息类型定义
class StatusInfo {
  text: string = '';
  color: string = '';
}

@Entry
@Component
struct AIPlanHistoryPage {
  private context: common.Context = getContext(this) as common.Context;

  @State plans: AIPlanHistory[] = [];
  @State pagination: Pagination = new Pagination();
  @State isLoading: boolean = true;
  @State errorMessage: string = '';

  aboutToAppear(): void {
    this.loadHistory();
  }

  async loadHistory(page: number = 1): Promise<void> {
    this.isLoading = true;
    this.errorMessage = '';
    try {
      const params: AIPlanHistoryQueryParams = new AIPlanHistoryQueryParams();
      params.page = page;
      params.pageSize = 10;
      const response: ApiResponse<AIPlanHistoryData> = await AIPlanService.getAIPlanHistory(this.context, params);
      if (response.code === 200 && response.data) {
        this.plans = response.data.plans;
        this.pagination = response.data.pagination;
      }
    } catch (error) {
      const err = error as Error;
      this.errorMessage = `加载失败: ${err.message}`;
    } finally {
      this.isLoading = false;
    }
  }

  getStatusInfo(status: string): StatusInfo {
    const info: StatusInfo = new StatusInfo();
    if (status === AIPlanStatus.COMPLETED) {
      info.text = '已完成';
      info.color = '#34C759';
    } else if (status === AIPlanStatus.FAILED) {
      info.text = '失败';
      info.color = '#FF3B30';
    } else {
      info.text = '处理中';
      info.color = '#FF9500';
    }
    return info;
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
  PlanCard(plan: AIPlanHistory) {
    Column({ space: 8 }) {
      Row() {
        Text(`规划 ${plan.planId.substring(0, 8)}...`).fontSize(16).fontColor('#333333').fontWeight(FontWeight.Medium).layoutWeight(1)
        Text(this.getStatusInfo(plan.status).text)
          .fontSize(12).fontColor('#FFFFFF')
          .padding({ left: 8, right: 8, top: 2, bottom: 2 })
          .backgroundColor(this.getStatusInfo(plan.status).color).borderRadius(10)
      }.width('100%')

      Row({ space: 16 }) {
        Text(`${plan.assignmentCount} 个作业`).fontSize(14).fontColor('#666666')
        Text(this.formatDate(plan.createdAt)).fontSize(14).fontColor('#999999')
      }.width('100%')
    }
    .padding(16).backgroundColor('#FFFFFF').borderRadius(12)
    .shadow({ radius: 4, color: '#000000', offsetX: 0, offsetY: 2 }).margin({ bottom: 12 })
    .onClick(() => {
      if (plan.status === AIPlanStatus.COMPLETED) {
        router.pushUrl({ url: 'pages/AIPlanDetailPage', params: { planId: plan.planId } });
      }
    })
  }

  build() {
    Column() {
      Row({ space: 12 }) {
        Button('返回').fontSize(16).fontColor('#007DFF').backgroundColor(Color.Transparent)
          .onClick(() => router.back())
        Text('规划历史').fontSize(20).fontWeight(FontWeight.Bold).layoutWeight(1).textAlign(TextAlign.Center)
        Text('').width(60)
      }.width('100%').padding({ left: 16, right: 16, top: 12, bottom: 12 }).backgroundColor('#FFFFFF')

      if (this.isLoading) {
        Column() {
          LoadingProgress().width(50).height(50).color('#007DFF')
          Text('加载中...').fontSize(16).fontColor('#666666').margin({ top: 12 })
        }.width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
      } else if (this.errorMessage) {
        Column({ space: 20 }) {
          Text('加载失败').fontSize(18).fontColor('#FF3B30')
          Text(this.errorMessage).fontSize(14).fontColor('#666666')
          Button('重试').width(120).height(40).backgroundColor('#007DFF').onClick(() => this.loadHistory())
        }.width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
      } else if (this.plans.length === 0) {
        Column() {
          Text('暂无规划历史').fontSize(18).fontColor('#8E8E93')
          Text('使用AI智能规划来管理你的作业').fontSize(14).fontColor('#C7C7CC').margin({ top: 8 })
        }.width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
      } else {
        Scroll() {
          Column({ space: 0 }) {
            ForEach(this.plans, (plan: AIPlanHistory) => {
              this.PlanCard(plan)
            }, (plan: AIPlanHistory) => plan.planId)

            if (this.pagination.page < this.pagination.totalPages) {
              Button('加载更多').width('100%').height(48).backgroundColor('#F5F5F5').fontColor('#007DFF')
                .onClick(() => this.loadHistory(this.pagination.page + 1))
            }
          }.padding(16)
        }.scrollable(ScrollDirection.Vertical).layoutWeight(1)
      }
    }.width('100%').height('100%').backgroundColor('#F5F5F5')
  }
}
