import http from '@ohos.net.http';
import preferences from '@ohos.data.preferences';
import { Logger } from './Logger';
import common from '@ohos.app.ability.common';
import { BusinessError } from '@ohos.base';

export class HttpUtil {
  private static readonly BASE_URL = 'http://localhost:8080/api/v1'; // 注意：真机或部分模拟器可能需要宿主机IP，如 192.168.x.x
  private static readonly PREF_NAME = 'njuplan_prefs';
  private static readonly KEY_TOKEN = 'jwt_token';
  private static readonly KEY_REFRESH_TOKEN = 'refresh_token';

  // 获取首选项实例
  static async getPreferences(context: common.Context): Promise<preferences.Preferences> {
    return await preferences.getPreferences(context, HttpUtil.PREF_NAME);
  }

  // 保存Token
  static async saveToken(context: common.Context, token: string): Promise<void> {
    try {
      const prefs = await HttpUtil.getPreferences(context);
      await prefs.put(HttpUtil.KEY_TOKEN, token);
      await prefs.flush();
      Logger.info('Token saved successfully');
    } catch (err) {
      const error = err as BusinessError;
      Logger.error('Failed to save token:', JSON.stringify(error));
    }
  }

  // 保存RefreshToken
  static async saveRefreshToken(context: common.Context, refreshToken: string): Promise<void> {
    try {
      const prefs = await HttpUtil.getPreferences(context);
      await prefs.put(HttpUtil.KEY_REFRESH_TOKEN, refreshToken);
      await prefs.flush();
      Logger.info('Refresh token saved successfully');
    } catch (err) {
      const error = err as BusinessError;
      Logger.error('Failed to save refresh token:', JSON.stringify(error));
    }
  }

  // 获取Token
  static async getToken(context: common.Context): Promise<string> {
    try {
      const prefs = await HttpUtil.getPreferences(context);
      const val = await prefs.get(HttpUtil.KEY_TOKEN, '');
      return val as string;
    } catch (err) {
      const error = err as BusinessError;
      Logger.error('Failed to get token:', JSON.stringify(error));
      return '';
    }
  }

  // 获取RefreshToken
  static async getRefreshToken(context: common.Context): Promise<string> {
    try {
      const prefs = await HttpUtil.getPreferences(context);
      const val = await prefs.get(HttpUtil.KEY_REFRESH_TOKEN, '');
      return val as string;
    } catch (err) {
      const error = err as BusinessError;
      Logger.error('Failed to get refresh token:', JSON.stringify(error));
      return '';
    }
  }

  // 清除Token
  static async clearToken(context: common.Context): Promise<void> {
    try {
      const prefs = await HttpUtil.getPreferences(context);
      await prefs.delete(HttpUtil.KEY_TOKEN);
      await prefs.delete(HttpUtil.KEY_REFRESH_TOKEN);
      await prefs.flush();
    } catch (err) {
      const error = err as BusinessError;
      Logger.error('Failed to clear token:', JSON.stringify(error));
    }
  }

  // 通用请求方法
  static async request<T>(context: common.Context, url: string, method: http.RequestMethod, data?: object, allowRetry: boolean = true): Promise<T> {
    const httpRequest = http.createHttp();
    const fullUrl = url.startsWith('http') ? url : `${HttpUtil.BASE_URL}${url}`;
    
    // ArkTS: 使用Record类型以允许索引访问
    let headers: Record<string, string> = {
      'Content-Type': 'application/json'
    };

    const token = await HttpUtil.getToken(context);
    if (token) {
      headers['Authorization'] = `Bearer ${token}`;
    } else {
      Logger.info('Warning: No token available for request');
    }

    Logger.info(`Request: ${method} ${fullUrl}`);

    try {
      const options: http.HttpRequestOptions = {
        method: method,
        header: headers,
        extraData: data ? JSON.stringify(data) : undefined,
        readTimeout: 10000,
        connectTimeout: 10000
      };

      const response = await httpRequest.request(fullUrl, options);

      Logger.info(`Response Code: ${response.responseCode}`);
      Logger.info(`Response Result Type: ${typeof response.result}`);
      Logger.info(`Response Result: ${JSON.stringify(response.result)}`);

      // 解析响应结果（无论成功还是失败都要解析）
      let result: T;
      if (typeof response.result === 'string') {
         Logger.info('Parsing string response');
         result = JSON.parse(response.result) as T;
      } else {
         Logger.info('Using response as is');
         result = response.result as T;
      }
      Logger.info(`Parsed Result: ${JSON.stringify(result)}`);
      
      // 尝试自动刷新token并重试（仅限401）
      const resultCode = (result as Record<string, object | string | number>).code as number | string | undefined;
      const isUnauthorized = response.responseCode === 401 || resultCode === 401 || resultCode === '401';
      if (allowRetry && isUnauthorized) {
        Logger.error('Unauthorized, attempting token refresh');
        const refreshed = await HttpUtil.refreshAccessToken(context);
        if (refreshed) {
          Logger.info('Token refreshed, retrying request');
          return await HttpUtil.request<T>(context, url, method, data, false);
        }
      }

      // 检查HTTP状态码是否为成功（200-299）
      if (response.responseCode >= 200 && response.responseCode < 300) {
        return result;
      } else {
        // HTTP错误但有响应体，直接返回结果（包含错误信息）
        Logger.error(`HTTP Error ${response.responseCode}, returning error response`);
        return result;
      }
    } catch (err) {
      const error = err as BusinessError | Error;
      Logger.error(`Request failed: ${JSON.stringify(error)}`);
      // ArkTS限制: throw语句不能抛出任意类型，必须是Error或其子类
      if (err instanceof Error) {
        throw err;
      } else {
        throw new Error(JSON.stringify(err));
      }
    } finally {
      httpRequest.destroy();
    }
  }

  static async get<T>(context: common.Context, url: string): Promise<T> {
    return HttpUtil.request<T>(context, url, http.RequestMethod.GET);
  }

  static async post<T>(context: common.Context, url: string, data: object): Promise<T> {
    return HttpUtil.request<T>(context, url, http.RequestMethod.POST, data);
  }

  static async put<T>(context: common.Context, url: string, data: object): Promise<T> {
    return HttpUtil.request<T>(context, url, http.RequestMethod.PUT, data);
  }

  static async delete<T>(context: common.Context, url: string): Promise<T> {
    return HttpUtil.request<T>(context, url, http.RequestMethod.DELETE);
  }

  // 文件上传方法 (支持 multipart/form-data)
  static async uploadFile<T>(
    context: common.Context,
    url: string,
    fileUri: string,
    fileName: string,
    formFields?: Record<string, string>
  ): Promise<T> {
    const fullUrl = url.startsWith('http') ? url : `${HttpUtil.BASE_URL}${url}`;
    const token = await HttpUtil.getToken(context);

    Logger.info(`Upload File: ${fullUrl}, fileUri: ${fileUri}`);

    // 构建FormData数据
    const formDataArray: http.MultiFormData[] = [];

    // 添加文件字段
    formDataArray.push({
      name: 'file',
      contentType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      remoteFileName: fileName,
      filePath: fileUri
    });

    // 添加其他表单字段
    if (formFields) {
      for (const key of Object.keys(formFields)) {
        formDataArray.push({
          name: key,
          contentType: 'text/plain',
          data: formFields[key]
        });
      }
    }

    const httpRequest = http.createHttp();
    const headers: Record<string, string> = {
      'Content-Type': 'multipart/form-data'
    };

    if (token) {
      headers['Authorization'] = `Bearer ${token}`;
    }

    try {
      const options: http.HttpRequestOptions = {
        method: http.RequestMethod.POST,
        header: headers,
        multiFormDataList: formDataArray,
        readTimeout: 30000,
        connectTimeout: 10000
      };

      const response = await httpRequest.request(fullUrl, options);

      Logger.info(`Upload Response Code: ${response.responseCode}`);
      Logger.info(`Upload Response: ${JSON.stringify(response.result)}`);

      let result: T;
      if (typeof response.result === 'string') {
        result = JSON.parse(response.result) as T;
      } else {
        result = response.result as T;
      }

      return result;
    } catch (err) {
      const error = err as BusinessError | Error;
      Logger.error(`Upload failed: ${JSON.stringify(error)}`);
      if (err instanceof Error) {
        throw err;
      } else {
        throw new Error(JSON.stringify(err));
      }
    } finally {
      httpRequest.destroy();
    }
  }

  private static async refreshAccessToken(context: common.Context): Promise<boolean> {
    const refreshToken = await HttpUtil.getRefreshToken(context);
    if (!refreshToken) {
      Logger.error('No refresh token available');
      return false;
    }

    const httpRequest = http.createHttp();
    const fullUrl = `${HttpUtil.BASE_URL}/auth/refresh`;
    const headers: Record<string, string> = {
      'Authorization': `Bearer ${refreshToken}`
    };

    try {
      const options: http.HttpRequestOptions = {
        method: http.RequestMethod.POST,
        header: headers,
        readTimeout: 10000,
        connectTimeout: 10000
      };
      const response = await httpRequest.request(fullUrl, options);

      let result: Record<string, object | string | number | null>;
      if (typeof response.result === 'string') {
        result = JSON.parse(response.result) as Record<string, object | string | number | null>;
      } else {
        result = response.result as Record<string, object | string | number | null>;
      }

      const code = result.code as number | string | undefined;
      if ((response.responseCode === 200 || code === 200 || code === '200') && result.data) {
        const data = result.data as Record<string, object | string | number | null>;
        const newToken = data.token as string | undefined;
        if (newToken) {
          await HttpUtil.saveToken(context, newToken);
          const newRefreshToken = data.refreshToken as string | undefined;
          if (newRefreshToken) {
             await HttpUtil.saveRefreshToken(context, newRefreshToken);
          }
          return true;
        }
      }

      Logger.error('Refresh token failed:', JSON.stringify(result));
      return false;
    } catch (err) {
      const error = err as BusinessError | Error;
      Logger.error('Refresh token request failed:', JSON.stringify(error));
      return false;
    } finally {
      httpRequest.destroy();
    }
  }
}
