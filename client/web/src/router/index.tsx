import { createBrowserRouter, RouterProvider } from 'react-router-dom'
import { useEffect } from 'react'
import { useAuthStore } from '@/store/authStore'
import Login from '@/pages/Login'
import Register from '@/pages/Register'
import Home from '@/pages/Home'
import ProtectedRoute from '@/components/ProtectedRoute'

function Router() {
  const { initAuth } = useAuthStore()

  useEffect(() => {
    // 初始化时检查认证状态
    initAuth()
  }, [initAuth])

  const router = createBrowserRouter([
    {
      path: '/login',
      element: <Login />,
    },
    {
      path: '/register',
      element: <Register />,
    },
    {
      path: '/',
      element: (
        <ProtectedRoute>
          <Home />
        </ProtectedRoute>
      ),
    },
  ], {
    future: {
      v7_startTransition: true,
    },
  })

  return <RouterProvider router={router} />
}

export default Router

