import { useState, useEffect } from 'react'
import { useNavigate, Link } from 'react-router-dom'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import { useAuthStore } from '@/store/authStore'
import Layout from '@/components/Layout'

// 表单验证schema
const registerSchema = z.object({
  username: z
    .string()
    .min(3, '用户名至少3个字符')
    .max(20, '用户名最多20个字符')
    .regex(/^[a-zA-Z0-9_]+$/, '用户名只能包含字母、数字和下划线'),
  password: z
    .string()
    .min(8, '密码至少8个字符')
    .regex(/^(?=.*[A-Za-z])(?=.*\d)/, '密码必须包含字母和数字'),
  confirmPassword: z.string(),
  studentId: z.string().optional(),
  nickname: z.string().optional(),
}).refine((data) => data.password === data.confirmPassword, {
  message: '两次输入的密码不一致',
  path: ['confirmPassword'],
})

type RegisterFormData = z.infer<typeof registerSchema>

export default function Register() {
  const navigate = useNavigate()
  const { register: registerUser, isAuthenticated } = useAuthStore()
  const [isLoading, setIsLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const {
    register,
    handleSubmit,
    formState: { errors },
  } = useForm<RegisterFormData>({
    resolver: zodResolver(registerSchema),
  })

  useEffect(() => {
    // 如果已登录，重定向到首页
    if (isAuthenticated) {
      navigate('/')
    }
  }, [isAuthenticated, navigate])

  const onSubmit = async (data: RegisterFormData) => {
    setIsLoading(true)
    setError(null)

    try {
      await registerUser(
        data.username,
        data.password,
        data.studentId || undefined,
        data.nickname || undefined
      )
      // 注册成功，提示用户并跳转到登录页
      alert('注册成功！请使用刚才的账号密码登录')
      navigate('/login')
    } catch (err: any) {
      setError(
        err.response?.data?.message ||
        err.message ||
        '注册失败，请检查输入信息'
      )
    } finally {
      setIsLoading(false)
    }
  }

  return (
    <Layout>
      <div className="bg-white rounded-xl shadow-lg p-8">
        <div className="text-center mb-8">
          <h1 className="text-3xl font-bold text-gray-900 mb-2">注册账号</h1>
          <p className="text-gray-600">创建你的NjuPlan账号</p>
        </div>

        <form onSubmit={handleSubmit(onSubmit)} className="space-y-6">
          <div>
            <label htmlFor="username" className="label">
              用户名 <span className="text-red-500">*</span>
            </label>
            <input
              id="username"
              type="text"
              {...register('username')}
              className={`input ${errors.username ? 'input-error' : ''}`}
              placeholder="3-20个字符，只能包含字母、数字、下划线"
              disabled={isLoading}
              autoComplete="username"
            />
            {errors.username && (
              <p className="error-message">{errors.username.message}</p>
            )}
          </div>

          <div>
            <label htmlFor="password" className="label">
              密码 <span className="text-red-500">*</span>
            </label>
            <input
              id="password"
              type="password"
              {...register('password')}
              className={`input ${errors.password ? 'input-error' : ''}`}
              placeholder="至少8个字符，包含字母和数字"
              disabled={isLoading}
              autoComplete="new-password"
            />
            {errors.password && (
              <p className="error-message">{errors.password.message}</p>
            )}
          </div>

          <div>
            <label htmlFor="confirmPassword" className="label">
              确认密码 <span className="text-red-500">*</span>
            </label>
            <input
              id="confirmPassword"
              type="password"
              {...register('confirmPassword')}
              className={`input ${errors.confirmPassword ? 'input-error' : ''}`}
              placeholder="请再次输入密码"
              disabled={isLoading}
              autoComplete="new-password"
            />
            {errors.confirmPassword && (
              <p className="error-message">{errors.confirmPassword.message}</p>
            )}
          </div>

          <div>
            <label htmlFor="studentId" className="label">
              学号 <span className="text-gray-500 text-xs">(可选)</span>
            </label>
            <input
              id="studentId"
              type="text"
              {...register('studentId')}
              className="input"
              placeholder="请输入学号"
              disabled={isLoading}
              autoComplete="off"
            />
          </div>

          <div>
            <label htmlFor="nickname" className="label">
              昵称 <span className="text-gray-500 text-xs">(可选)</span>
            </label>
            <input
              id="nickname"
              type="text"
              {...register('nickname')}
              className="input"
              placeholder="请输入昵称，默认使用用户名"
              disabled={isLoading}
              autoComplete="nickname"
            />
          </div>

          {error && (
            <div className="bg-red-50 border border-red-200 rounded-lg p-3">
              <p className="error-message">{error}</p>
            </div>
          )}

          <button
            type="submit"
            className="btn btn-primary w-full"
            disabled={isLoading}
          >
            {isLoading ? '注册中...' : '注册'}
          </button>
        </form>

        <div className="mt-6 text-center">
          <p className="text-sm text-gray-600">
            已有账号？{' '}
            <Link
              to="/login"
              className="text-primary-600 hover:text-primary-700 font-medium"
            >
              立即登录
            </Link>
          </p>
        </div>
      </div>
    </Layout>
  )
}

