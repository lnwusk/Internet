import { HttpUtil } from '../common/utils/HttpUtil';
import { ApiResponse, UserProfile, UpdateProfileRequest, UpdateProfileResponse, UpdatePreferencesRequest, UserPreferences } from '../common/models/ApiModels';
import { Logger } from '../common/utils/Logger';
import common from '@ohos.app.ability.common';

export class UserService {

  static async getUserProfile(context: common.Context): Promise<ApiResponse<UserProfile>> {
    Logger.info('UserService: Getting user profile');
    return await HttpUtil.get<ApiResponse<UserProfile>>(context, '/user/profile');
  }

  static async updateUserProfile(context: common.Context, data: UpdateProfileRequest): Promise<ApiResponse<UpdateProfileResponse>> {
    Logger.info('UserService: Updating user profile');
    return await HttpUtil.put<ApiResponse<UpdateProfileResponse>>(context, '/user/profile', data);
  }

  static async updateUserPreferences(context: common.Context, data: UpdatePreferencesRequest): Promise<ApiResponse<UserPreferences>> {
    Logger.info('UserService: Updating user preferences');
    return await HttpUtil.put<ApiResponse<UserPreferences>>(context, '/user/preferences', data);
  }

  static async updateNickname(context: common.Context, nickname: string): Promise<ApiResponse<UpdateProfileResponse>> {
    const request: UpdateProfileRequest = new UpdateProfileRequest();
    request.nickname = nickname;
    return UserService.updateUserProfile(context, request);
  }

  static async updateStudentId(context: common.Context, studentId: string): Promise<ApiResponse<UpdateProfileResponse>> {
    const request: UpdateProfileRequest = new UpdateProfileRequest();
    request.studentId = studentId;
    return UserService.updateUserProfile(context, request);
  }

  static async updateAvatar(context: common.Context, avatar: string): Promise<ApiResponse<UpdateProfileResponse>> {
    const request: UpdateProfileRequest = new UpdateProfileRequest();
    request.avatar = avatar;
    return UserService.updateUserProfile(context, request);
  }
}
