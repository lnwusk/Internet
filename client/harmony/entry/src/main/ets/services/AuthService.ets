import { HttpUtil } from '../common/utils/HttpUtil';
import { ApiResponse, LoginData, RegisterData, LoginRequest, RegisterRequest, ChangePasswordRequest } from '../common/models/ApiModels';
import { Logger } from '../common/utils/Logger';
import common from '@ohos.app.ability.common';

export class AuthService {

  static async login(context: common.Context, username: string, password: string): Promise<ApiResponse<LoginData>> {
    const requestData: LoginRequest = new LoginRequest();
    requestData.username = username;
    requestData.password = password;

    Logger.info('AuthService: Sending login request');
    const response = await HttpUtil.post<ApiResponse<LoginData>>(context, '/auth/login', requestData);
    Logger.info('AuthService: Received response:', JSON.stringify(response));

    if (response.code === 200 && response.data && response.data.token) {
      Logger.info('AuthService: Saving token');
      await HttpUtil.saveToken(context, response.data.token);
      if (response.data.refreshToken) {
        await HttpUtil.saveRefreshToken(context, response.data.refreshToken);
      }
      Logger.info('AuthService: Token saved successfully');
    } else {
      Logger.error('AuthService: Login failed or no token in response');
    }
    return response;
  }

  static async register(context: common.Context, userInfo: RegisterRequest): Promise<ApiResponse<RegisterData>> {
    return await HttpUtil.post<ApiResponse<RegisterData>>(context, '/auth/register', userInfo);
  }

  static async logout(context: common.Context): Promise<void> {
    await HttpUtil.clearToken(context);
  }

  static async getUserProfile(context: common.Context): Promise<ApiResponse<object>> {
    return await HttpUtil.get<ApiResponse<object>>(context, '/user/profile');
  }

  static async changePassword(context: common.Context, oldPassword: string, newPassword: string): Promise<ApiResponse<null>> {
    Logger.info('AuthService: Changing password');
    const request: ChangePasswordRequest = new ChangePasswordRequest();
    request.oldPassword = oldPassword;
    request.newPassword = newPassword;
    return await HttpUtil.post<ApiResponse<null>>(context, '/auth/change-password', request);
  }
}
