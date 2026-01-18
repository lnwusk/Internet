import { createBrowserRouter, RouterProvider } from 'react-router-dom'
import { useEffect } from 'react'
import { useAuthStore } from '@/store/authStore'
import Login from '@/pages/Login'
import Register from '@/pages/Register'
import Home from '@/pages/Home'
import Assignments from '@/pages/Assignments'
import AssignmentAdd from '@/pages/AssignmentAdd'
import AssignmentDetail from '@/pages/AssignmentDetail'
import Tasks from '@/pages/Tasks'
import AiPlanning from '@/pages/AiPlanning'
import Profile from '@/pages/Profile'
import ProtectedRoute from '@/components/ProtectedRoute'
import Layout from '@/components/Layout'
import NotFound from '@/pages/NotFound'

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
          <Layout>
            <Home />
          </Layout>
        </ProtectedRoute>
      ),
    },
    {
      path: '/assignments',
      element: (
        <ProtectedRoute>
          <Layout>
            <Assignments />
          </Layout>
        </ProtectedRoute>
      ),
    },
    {
      path: '/assignments/add',
      element: (
        <ProtectedRoute>
          <Layout>
            <AssignmentAdd />
          </Layout>
        </ProtectedRoute>
      ),
    },
    {
      path: '/assignments/:id',
      element: (
        <ProtectedRoute>
          <Layout>
            <AssignmentDetail />
          </Layout>
        </ProtectedRoute>
      ),
    },
    {
      path: '/tasks',
      element: (
        <ProtectedRoute>
          <Layout>
            <Tasks />
          </Layout>
        </ProtectedRoute>
      ),
    },
    {
      path: '/ai-planning',
      element: (
        <ProtectedRoute>
          <Layout>
            <AiPlanning />
          </Layout>
        </ProtectedRoute>
      ),
    },
    {
      path: '/profile',
      element: (
        <ProtectedRoute>
          <Layout>
            <Profile />
          </Layout>
        </ProtectedRoute>
      ),
    },
    {
      path: '*',
      element: <NotFound />,
    },
  ], {
    future: {
      v7_startTransition: true,
    },
  })

  return <RouterProvider router={router} />
}

export default Router

