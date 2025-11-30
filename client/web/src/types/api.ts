// API响应格式
export interface ApiResponse<T = any> {
  code: number
  message: string
  data: T
  error?: {
    code: string
    details: string
  }
}

// 用户相关类型
export interface User {
  userId: string
  username: string
  nickname: string
  studentId?: string
  avatar?: string
  createdAt: string
}

export interface LoginRequest {
  username: string
  password: string
}

export interface LoginResponse {
  token: string
  refreshToken: string
  expiresIn: number
  user: User
}

export interface RegisterRequest {
  username: string
  password: string
  studentId?: string
  nickname?: string
}

export interface RegisterResponse {
  userId: string
  username: string
  nickname: string
  studentId?: string
  createdAt: string
}

export interface RefreshTokenResponse {
  token: string
  expiresIn: number
}

