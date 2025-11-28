// HarmonyOS 课程表应用 - 课程服务API示例
// 位置: common/services/courseService.js

import HttpUtil from '../utils/httpUtil.js';

export default class CourseService {
  
  // 用户登录
  static async login(username, password) {
    try {
      const response = await HttpUtil.post('/auth/login', {
        username,
        password
      }, false);
      
      if (response.token) {
        await HttpUtil.saveToken(response.token);
      }
      
      return response;
    } catch (error) {
      console.error('Login error:', error);
      throw error;
    }
  }
  
  // 用户注册
  static async register(userInfo) {
    try {
      return await HttpUtil.post('/auth/register', userInfo, false);
    } catch (error) {
      console.error('Register error:', error);
      throw error;
    }
  }
  
  // 获取用户所有课程
  static async getUserCourses() {
    try {
      return await HttpUtil.get('/courses');
    } catch (error) {
      console.error('Get courses error:', error);
      throw error;
    }
  }
  
  // 根据星期几获取课程
  static async getCoursesByDay(dayOfWeek) {
    try {
      return await HttpUtil.get(`/courses/day/${dayOfWeek}`);
    } catch (error) {
      console.error('Get courses by day error:', error);
      throw error;
    }
  }
  
  // 创建新课程
  static async createCourse(courseData) {
    try {
      return await HttpUtil.post('/courses', courseData);
    } catch (error) {
      console.error('Create course error:', error);
      throw error;
    }
  }
  
  // 更新课程
  static async updateCourse(courseId, courseData) {
    try {
      return await HttpUtil.put(`/courses/${courseId}`, courseData);
    } catch (error) {
      console.error('Update course error:', error);
      throw error;
    }
  }
  
  // 删除课程
  static async deleteCourse(courseId) {
    try {
      return await HttpUtil.delete(`/courses/${courseId}`);
    } catch (error) {
      console.error('Delete course error:', error);
      throw error;
    }
  }
  
  // 用户登出
  static async logout() {
    try {
      await HttpUtil.clearToken();
      return { message: 'Logout successful' };
    } catch (error) {
      console.error('Logout error:', error);
      throw error;
    }
  }
  
  // 检查登录状态
  static async checkLoginStatus() {
    try {
      const token = await HttpUtil.getToken();
      return !!token;
    } catch (error) {
      console.error('Check login status error:', error);
      return false;
    }
  }
}