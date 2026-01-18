import { HttpUtil } from '../common/utils/HttpUtil';
import { ApiResponse, SubmitAIPlanRequest, SubmitAIPlanResponse, CompletedAIPlanResult, ApplyAIPlanRequest, ApplyAIPlanResponse, AIPlanHistoryData, AIPlanHistoryQueryParams, AIPlanStatus } from '../common/models/ApiModels';
import { Logger } from '../common/utils/Logger';
import common from '@ohos.app.ability.common';

function sleep(ms: number): Promise<void> {
  return new Promise<void>(resolve => setTimeout(resolve, ms));
}

export class AIPlanService {

  static async submitAIPlan(context: common.Context, request: SubmitAIPlanRequest): Promise<ApiResponse<SubmitAIPlanResponse>> {
    Logger.info('AIPlanService: Submitting AI plan');
    return await HttpUtil.post<ApiResponse<SubmitAIPlanResponse>>(context, '/ai/plan', request);
  }

  static async getAIPlanResult(context: common.Context, planId: string): Promise<ApiResponse<CompletedAIPlanResult>> {
    Logger.info(`AIPlanService: Getting plan result ${planId}`);
    return await HttpUtil.get<ApiResponse<CompletedAIPlanResult>>(context, `/ai/plan/${planId}`);
  }

  static async applyAIPlan(context: common.Context, planId: string, request: ApplyAIPlanRequest): Promise<ApiResponse<ApplyAIPlanResponse>> {
    Logger.info(`AIPlanService: Applying plan ${planId}`);
    return await HttpUtil.post<ApiResponse<ApplyAIPlanResponse>>(context, `/ai/plan/${planId}/apply`, request);
  }

  static async getAIPlanHistory(context: common.Context, params?: AIPlanHistoryQueryParams): Promise<ApiResponse<AIPlanHistoryData>> {
    let url = '/ai/plan/history?';
    if (params?.page) {
      url += `page=${params.page}&`;
    }
    if (params?.pageSize) {
      url += `pageSize=${params.pageSize}&`;
    }
    if (url.endsWith('&') || url.endsWith('?')) {
      url = url.slice(0, -1);
    }
    Logger.info('AIPlanService: Getting plan history');
    return await HttpUtil.get<ApiResponse<AIPlanHistoryData>>(context, url);
  }

  static async applyAllPlan(context: common.Context, planId: string): Promise<ApiResponse<ApplyAIPlanResponse>> {
    const request: ApplyAIPlanRequest = new ApplyAIPlanRequest();
    request.applyAll = true;
    request.selectedItems = [];
    return AIPlanService.applyAIPlan(context, planId, request);
  }

  static async pollAIPlanResult(
    context: common.Context,
    planId: string,
    interval: number = 2000,
    maxAttempts: number = 60  // 增加到60次，总超时120秒
  ): Promise<ApiResponse<CompletedAIPlanResult>> {
    let attempts = 0;
    while (attempts < maxAttempts) {
      try {
        const response = await AIPlanService.getAIPlanResult(context, planId);
        if (response.code === 200 && response.data) {
          if (response.data.status === AIPlanStatus.COMPLETED) {
            return response;
          } else if (response.data.status === AIPlanStatus.FAILED) {
            throw new Error('AI规划处理失败');
          }
        }
        await sleep(interval);
        attempts++;
      } catch (err) {
        Logger.error('Poll AI plan error:', JSON.stringify(err));
        attempts++;
        if (attempts >= maxAttempts) {
          throw new Error('AI规划处理超时');
        }
        await sleep(interval);
      }
    }
    throw new Error('AI规划处理超时');
  }
}
