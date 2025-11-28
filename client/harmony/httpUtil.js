// HarmonyOS 课程表应用 - HTTP 工具类示例
// 位置: common/utils/httpUtil.js

import http from '@ohos.net.http';
import preferences from '@ohos.data.preferences';

const BASE_URL = 'http://localhost:8080/api';

export default class HttpUtil {
  // 通用HTTP请求方法
  static async request(url, method = 'GET', data = null, needAuth = true) {
    const httpRequest = http.createHttp();
    
    const headers = {
      'Content-Type': 'application/json',
    };
    
    // 添加JWT Token认证
    if (needAuth) {
      const token = await this.getToken();
      if (token) {
        headers['Authorization'] = `Bearer ${token}`;
      }
    }
    
    const options = {
      method,
      header: headers,
      readTimeout: 10000,
      connectTimeout: 10000
    };
    
    if (data && (method === 'POST' || method === 'PUT')) {
      options.extraData = JSON.stringify(data);
    }
    
    try {
      const fullUrl = url.startsWith('http') ? url : `${BASE_URL}${url}`;
      const response = await httpRequest.request(fullUrl, options);
      
      if (response.responseCode === 200) {
        return JSON.parse(response.result);
      } else {
        throw new Error(`HTTP ${response.responseCode}: ${response.result}`);
      }
    } catch (error) {
      console.error('HTTP Request Error:', error);
      throw error;
    } finally {
      httpRequest.destroy();
    }
  }
  
  // GET请求
  static async get(url, needAuth = true) {
    return this.request(url, 'GET', null, needAuth);
  }
  
  // POST请求
  static async post(url, data, needAuth = true) {
    return this.request(url, 'POST', data, needAuth);
  }
  
  // PUT请求
  static async put(url, data, needAuth = true) {
    return this.request(url, 'PUT', data, needAuth);
  }
  
  // DELETE请求
  static async delete(url, needAuth = true) {
    return this.request(url, 'DELETE', null, needAuth);
  }
  
  // 保存JWT Token
  static async saveToken(token) {
    try {
      const dataPreferences = await preferences.getPreferences(globalThis.abilityContext, 'course_app');
      await dataPreferences.put('jwt_token', token);
      await dataPreferences.flush();
    } catch (error) {
      console.error('Save token error:', error);
    }
  }
  
  // 获取JWT Token
  static async getToken() {
    try {
      const dataPreferences = await preferences.getPreferences(globalThis.abilityContext, 'course_app');
      return await dataPreferences.get('jwt_token', '');
    } catch (error) {
      console.error('Get token error:', error);
      return '';
    }
  }
  
  // 清除Token
  static async clearToken() {
    try {
      const dataPreferences = await preferences.getPreferences(globalThis.abilityContext, 'course_app');
      await dataPreferences.delete('jwt_token');
      await dataPreferences.flush();
    } catch (error) {
      console.error('Clear token error:', error);
    }
  }
}