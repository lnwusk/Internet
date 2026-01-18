import { HttpUtil } from '../common/utils/HttpUtil';
import { ApiResponse, Assignment, AssignmentDetail, AssignmentListData, CreateAssignmentRequest, UpdateAssignmentRequest, AssignmentOperationResponse, CompleteAssignmentResponse, AssignmentQueryParams, AssignmentStatus, SortBy, SortOrder } from '../common/models/ApiModels';
import { Logger } from '../common/utils/Logger';
import common from '@ohos.app.ability.common';

export class AssignmentService {

  static async getAssignments(context: common.Context, params?: AssignmentQueryParams): Promise<ApiResponse<AssignmentListData>> {
    let url = '/assignments?';
    if (params?.courseId) {
      url += `courseId=${params.courseId}&`;
    }
    if (params?.status) {
      url += `status=${params.status}&`;
    }
    if (params?.sortBy) {
      url += `sortBy=${params.sortBy}&`;
    }
    if (params?.order) {
      url += `order=${params.order}&`;
    }
    if (url.endsWith('&') || url.endsWith('?')) {
      url = url.slice(0, -1);
    }
    Logger.info('AssignmentService: Fetching assignments');
    return await HttpUtil.get<ApiResponse<AssignmentListData>>(context, url);
  }

  static async getAssignmentDetail(context: common.Context, assignmentId: string): Promise<ApiResponse<AssignmentDetail>> {
    Logger.info(`AssignmentService: Fetching assignment detail ${assignmentId}`);
    return await HttpUtil.get<ApiResponse<AssignmentDetail>>(context, `/assignments/${assignmentId}`);
  }

  static async createAssignment(context: common.Context, data: CreateAssignmentRequest): Promise<ApiResponse<AssignmentOperationResponse>> {
    Logger.info('AssignmentService: Creating assignment');
    return await HttpUtil.post<ApiResponse<AssignmentOperationResponse>>(context, '/assignments', data);
  }

  static async updateAssignment(context: common.Context, assignmentId: string, data: UpdateAssignmentRequest): Promise<ApiResponse<AssignmentOperationResponse>> {
    Logger.info(`AssignmentService: Updating assignment ${assignmentId}`);
    return await HttpUtil.put<ApiResponse<AssignmentOperationResponse>>(context, `/assignments/${assignmentId}`, data);
  }

  static async deleteAssignment(context: common.Context, assignmentId: string): Promise<ApiResponse<null>> {
    Logger.info(`AssignmentService: Deleting assignment ${assignmentId}`);
    return await HttpUtil.delete<ApiResponse<null>>(context, `/assignments/${assignmentId}`);
  }

  static async completeAssignment(context: common.Context, assignmentId: string): Promise<ApiResponse<CompleteAssignmentResponse>> {
    Logger.info(`AssignmentService: Completing assignment ${assignmentId}`);
    const emptyBody: Record<string, string> = {};
    return await HttpUtil.post<ApiResponse<CompleteAssignmentResponse>>(context, `/assignments/${assignmentId}/complete`, emptyBody);
  }

  static async getPendingAssignments(context: common.Context): Promise<ApiResponse<AssignmentListData>> {
    const params: AssignmentQueryParams = new AssignmentQueryParams();
    params.status = AssignmentStatus.PENDING;
    params.sortBy = SortBy.DDL;
    params.order = SortOrder.ASC;
    return AssignmentService.getAssignments(context, params);
  }

  static async getOverdueAssignments(context: common.Context): Promise<ApiResponse<AssignmentListData>> {
    const params: AssignmentQueryParams = new AssignmentQueryParams();
    params.status = AssignmentStatus.OVERDUE;
    params.sortBy = SortBy.DDL;
    params.order = SortOrder.ASC;
    return AssignmentService.getAssignments(context, params);
  }
}
