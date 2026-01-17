import { ReactNode } from 'react'
import { useNavigate, useLocation } from 'react-router-dom'
import { useAuthStore } from '@/store/authStore'

interface LayoutProps {
  children: ReactNode
}

export default function Layout({ children }: LayoutProps) {
  const navigate = useNavigate()
  const location = useLocation()
  const { user, logout } = useAuthStore()

  const handleLogout = async () => {
    await logout()
    navigate('/login')
  }

  const navItems = [
    { path: '/', label: '课表' },
    { path: '/assignments', label: '作业' },
    { path: '/tasks', label: '任务' },
    { path: '/ai-planning', label: 'AI规划' },
    { path: '/profile', label: '个人中心' },
  ]

  return (
    <div className="min-h-screen bg-gray-50">
      {/* 顶部导航栏 */}
      <nav className="bg-white shadow-sm">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between h-16">
            <div className="flex items-center space-x-8">
              <h1 className="text-xl font-bold text-blue-600">NjuPlan</h1>
              <div className="flex space-x-4">
                {navItems.map((item) => (
                  <button
                    key={item.path}
                    onClick={() => navigate(item.path)}
                    className={`px-3 py-2 rounded-md text-sm font-medium ${location.pathname === item.path
                        ? 'bg-blue-100 text-blue-700'
                        : 'text-gray-700 hover:bg-gray-100'
                      }`}
                  >
                    {item.label}
                  </button>
                ))}
              </div>
            </div>
            <div className="flex items-center space-x-4">
              <span className="text-gray-700">欢迎，{user?.nickname || user?.username}</span>
              <button
                onClick={handleLogout}
                className="px-4 py-2 text-sm font-medium text-gray-700 hover:text-gray-900"
              >
                退出登录
              </button>
            </div>
          </div>
        </div>
      </nav>

      {/* 页面内容 */}
      <main>{children}</main>
    </div>
  )
}

