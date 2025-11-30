import { useEffect, useState, useRef } from 'react'
import { useNavigate } from 'react-router-dom'
import { useAuthStore } from '@/store/authStore'
import { syncApi } from '@/api/sync'
import { courseApi } from '@/api/course'
import { Course, UploadCoursesResponse, WeekScheduleResponse } from '@/types/api'

export default function Home() {
  const navigate = useNavigate()
  const { user, isAuthenticated, logout } = useAuthStore()
  const fileInputRef = useRef<HTMLInputElement>(null)

  // 状态管理
  const [activeTab, setActiveTab] = useState<'upload' | 'view'>('view')
  const [uploading, setUploading] = useState(false)
  const [uploadResult, setUploadResult] = useState<UploadCoursesResponse | null>(null)
  const [courses, setCourses] = useState<Course[]>([])
  const [weekSchedule, setWeekSchedule] = useState<WeekScheduleResponse | null>(null)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [success, setSuccess] = useState<string | null>(null)

  useEffect(() => {
    if (!isAuthenticated) {
      navigate('/login')
    } else {
      loadCourses()
      loadWeekSchedule()
    }
  }, [isAuthenticated, navigate])

  // 加载课程列表
  const loadCourses = async () => {
    try {
      setLoading(true)
      const data = await courseApi.getCourses()
      setCourses(data.courses)
    } catch (err: any) {
      console.error('加载课程失败:', err)
    } finally {
      setLoading(false)
    }
  }

  // 加载周视图课表
  const loadWeekSchedule = async () => {
    try {
      const data = await courseApi.getWeekSchedule()
      setWeekSchedule(data)
    } catch (err: any) {
      console.error('加载周课表失败:', err)
    }
  }

  const handleLogout = async () => {
    await logout()
    navigate('/login')
  }

  // 处理文件选择
  const handleFileSelect = () => {
    fileInputRef.current?.click()
  }

  // 处理文件上传
  const handleFileChange = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0]
    if (!file) return

    // 验证文件格式
    if (!file.name.endsWith('.xlsx') && !file.name.endsWith('.xls')) {
      setError('请上传 .xlsx 或 .xls 格式的文件')
      return
    }

    // 验证文件大小（10MB）
    if (file.size > 10 * 1024 * 1024) {
      setError('文件大小不能超过 10MB')
      return
    }

    try {
      setUploading(true)
      setError(null)
      setSuccess(null)

      const result = await syncApi.uploadCourses(file)
      setUploadResult(result)
      setSuccess(`成功解析 ${result.summary.totalCourses} 门课程，共 ${result.summary.totalSchedules} 个时间段`)
    } catch (err: any) {
      console.error('上传失败:', err)
      const errorMessage = err.response?.data?.message || err.message || '上传失败，请检查文件格式'
      setError(`上传失败: ${errorMessage}`)
      setUploadResult(null)
    } finally {
      setUploading(false)
      if (fileInputRef.current) {
        fileInputRef.current.value = ''
      }
    }
  }

  // 确认保存课程
  const handleConfirmCourses = async () => {
    if (!uploadResult) return

    try {
      setUploading(true)
      setError(null)

      await syncApi.confirmCourses({
        courses: uploadResult.courses.map(course => ({
          courseId: course.courseId,
          courseName: course.courseName,
          courseCode: course.courseCode,
          teacher: course.teacher,
          credits: course.credits,
          schedule: course.schedule,
        })),
        semester: uploadResult.courses[0]?.semester || new Date().getFullYear() + '-' + (new Date().getMonth() < 6 ? '2' : '1'),
      })

      setSuccess('课程保存成功！')
      setUploadResult(null)
      // 重新加载课程列表
      await loadCourses()
      await loadWeekSchedule()
      setActiveTab('view')
    } catch (err: any) {
      setError(err.response?.data?.message || '保存失败')
    } finally {
      setUploading(false)
    }
  }

  // 取消上传
  const handleCancelUpload = () => {
    setUploadResult(null)
    setError(null)
    setSuccess(null)
  }

  // 格式化星期
  const formatDayOfWeek = (day: number) => {
    const days = ['周日', '周一', '周二', '周三', '周四', '周五', '周六']
    return days[day] || '未知'
  }

  if (!isAuthenticated || !user) {
    return null
  }

  return (
    <div className="min-h-screen bg-gray-50">
      <nav className="bg-white shadow-sm">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between h-16">
            <div className="flex items-center">
              <h1 className="text-xl font-bold text-gray-900">NjuPlan - 课表管理</h1>
            </div>
            <div className="flex items-center space-x-4">
              <span className="text-gray-700">欢迎，{user.nickname || user.username}</span>
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

      <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* Tab切换 */}
        <div className="mb-6">
          <div className="border-b border-gray-200">
            <nav className="-mb-px flex space-x-8">
              <button
                onClick={() => setActiveTab('view')}
                className={`py-4 px-1 border-b-2 font-medium text-sm ${activeTab === 'view'
                  ? 'border-blue-500 text-blue-600'
                  : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
                  }`}
              >
                查看课表
              </button>
              <button
                onClick={() => setActiveTab('upload')}
                className={`py-4 px-1 border-b-2 font-medium text-sm ${activeTab === 'upload'
                  ? 'border-blue-500 text-blue-600'
                  : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
                  }`}
              >
                上传课表
              </button>
            </nav>
          </div>
        </div>

        {/* 提示信息 */}
        {error && (
          <div className="mb-4 bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded">
            {error}
          </div>
        )}
        {success && (
          <div className="mb-4 bg-green-50 border border-green-200 text-green-700 px-4 py-3 rounded">
            {success}
          </div>
        )}

        {/* 上传课表 Tab */}
        {activeTab === 'upload' && (
          <div className="bg-white rounded-lg shadow p-6">
            <h2 className="text-xl font-bold text-gray-900 mb-4">上传课表文件</h2>

            {!uploadResult ? (
              <div>
                <p className="text-gray-600 mb-4">
                  请上传从教务系统导出的课表 Excel 文件（.xlsx 或 .xls 格式，最大 10MB）
                </p>
                <input
                  ref={fileInputRef}
                  type="file"
                  accept=".xlsx,.xls"
                  onChange={handleFileChange}
                  className="hidden"
                />
                <button
                  onClick={handleFileSelect}
                  disabled={uploading}
                  className="px-6 py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:bg-gray-400 disabled:cursor-not-allowed"
                >
                  {uploading ? '上传中...' : '选择文件'}
                </button>
              </div>
            ) : (
              <div>
                <h3 className="text-lg font-semibold mb-4">解析结果预览</h3>
                <div className="mb-4 p-4 bg-blue-50 rounded">
                  <p className="text-sm text-gray-700">
                    共解析出 <span className="font-bold">{uploadResult.summary.totalCourses}</span> 门课程，
                    <span className="font-bold">{uploadResult.summary.totalSchedules}</span> 个时间段
                  </p>
                </div>

                <div className="max-h-96 overflow-y-auto mb-4">
                  {uploadResult.courses.map((course, index) => (
                    <div key={index} className="mb-4 p-4 border rounded">
                      <div className="font-semibold text-lg mb-2">{course.courseName}</div>
                      {course.courseCode && (
                        <div className="text-sm text-gray-600">课程代码: {course.courseCode}</div>
                      )}
                      {course.teacher && (
                        <div className="text-sm text-gray-600">教师: {course.teacher}</div>
                      )}
                      {course.credits && (
                        <div className="text-sm text-gray-600">学分: {course.credits}</div>
                      )}
                      {course.schedule && course.schedule.length > 0 && (
                        <div className="mt-2">
                          <div className="text-sm font-medium text-gray-700">时间安排:</div>
                          {course.schedule.map((sch, idx) => (
                            <div key={idx} className="text-sm text-gray-600 ml-4">
                              • {formatDayOfWeek(sch.dayOfWeek)} {sch.startTime}-{sch.endTime}
                              {sch.location && ` @ ${sch.location}`}
                              {sch.weeks && sch.weeks.length > 0 && ` (第${sch.weeks[0]}-${sch.weeks[sch.weeks.length - 1]}周)`}
                            </div>
                          ))}
                        </div>
                      )}
                    </div>
                  ))}
                </div>

                <div className="flex space-x-4">
                  <button
                    onClick={handleConfirmCourses}
                    disabled={uploading}
                    className="px-6 py-2 bg-green-600 text-white rounded hover:bg-green-700 disabled:bg-gray-400"
                  >
                    {uploading ? '保存中...' : '确认保存'}
                  </button>
                  <button
                    onClick={handleCancelUpload}
                    disabled={uploading}
                    className="px-6 py-2 bg-gray-600 text-white rounded hover:bg-gray-700 disabled:bg-gray-400"
                  >
                    取消
                  </button>
                </div>
              </div>
            )}
          </div>
        )}

        {/* 查看课表 Tab */}
        {activeTab === 'view' && (
          <div>
            {/* 周视图课表 */}
            {weekSchedule && (
              <div className="bg-white rounded-lg shadow p-6 mb-6">
                <h2 className="text-xl font-bold text-gray-900 mb-4">
                  周课表 - 第 {weekSchedule.currentWeek} 周 ({weekSchedule.semester})
                </h2>
                <div className="overflow-x-auto">
                  <table className="min-w-full divide-y divide-gray-200">
                    <thead className="bg-gray-50">
                      <tr>
                        <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">时间</th>
                        {weekSchedule.schedule.map((day) => (
                          <th key={day.dayOfWeek} className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">
                            {formatDayOfWeek(day.dayOfWeek)}
                          </th>
                        ))}
                      </tr>
                    </thead>
                    <tbody className="bg-white divide-y divide-gray-200">
                      {/* 这里简化展示，实际需要按时间段分组 */}
                      {weekSchedule.schedule.some(d => d.timeSlots.length > 0) ? (
                        weekSchedule.schedule.map((day) =>
                          day.timeSlots.map((slot, idx) => (
                            <tr key={`${day.dayOfWeek}-${idx}`}>
                              <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                                {slot.startTime}-{slot.endTime}
                              </td>
                              <td colSpan={7} className="px-6 py-4 text-sm text-gray-900">
                                <div className="font-medium">{slot.course.courseName}</div>
                                <div className="text-gray-500">{slot.course.location}</div>
                              </td>
                            </tr>
                          ))
                        )
                      ) : (
                        <tr>
                          <td colSpan={8} className="px-6 py-4 text-center text-gray-500">
                            本周暂无课程
                          </td>
                        </tr>
                      )}
                    </tbody>
                  </table>
                </div>
              </div>
            )}

            {/* 课程列表 */}
            <div className="bg-white rounded-lg shadow p-6">
              <h2 className="text-xl font-bold text-gray-900 mb-4">我的课程</h2>
              {loading ? (
                <p className="text-gray-500">加载中...</p>
              ) : courses.length === 0 ? (
                <p className="text-gray-500">暂无课程，请先上传课表</p>
              ) : (
                <div className="grid gap-4">
                  {courses.map((course) => (
                    <div key={course.courseId} className="border rounded-lg p-4 hover:shadow-md transition-shadow">
                      <div className="flex justify-between items-start">
                        <div className="flex-1">
                          <h3 className="text-lg font-semibold text-gray-900">{course.courseName}</h3>
                          <div className="mt-2 text-sm text-gray-600 space-y-1">
                            {course.courseCode && <div>课程代码: {course.courseCode}</div>}
                            {course.teacher && <div>教师: {course.teacher}</div>}
                            {course.credits && <div>学分: {course.credits}</div>}
                            <div>来源: {course.source === 'official' ? '官方' : course.source === 'manual' ? '手动添加' : 'Moodle'}</div>
                          </div>
                          {course.schedule && course.schedule.length > 0 && (
                            <div className="mt-3">
                              <div className="text-sm font-medium text-gray-700">上课时间:</div>
                              <div className="mt-1 space-y-1">
                                {course.schedule.map((sch, idx) => (
                                  <div key={idx} className="text-sm text-gray-600">
                                    • {formatDayOfWeek(sch.dayOfWeek)} {sch.startTime}-{sch.endTime}
                                    {sch.location && ` @ ${sch.location}`}
                                  </div>
                                ))}
                              </div>
                            </div>
                          )}
                        </div>
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </div>
          </div>
        )}
      </main>
    </div>
  )
}

