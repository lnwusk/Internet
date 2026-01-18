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

  // 获取当前学期（格式：YYYY-YYYY-N）
  const getCurrentSemester = () => {
    const now = new Date()
    const year = now.getFullYear()
    const month = now.getMonth() + 1 // 0-11 -> 1-12

    // 9月-次年1月为秋季学期(第一学期)
    // 2月-7月为春季学期(第二学期)
    if (month >= 9 || month <= 1) {
      // 秋季学期
      if (month >= 9) {
        // 9-12月，当前学年
        return `${year}-${year + 1}-1`
      } else {
        // 1月，上一学年
        return `${year - 1}-${year}-1`
      }
    } else {
      // 春季学期
      return `${year - 1}-${year}-2`
    }
  }

  // 添加/编辑课程相关状态
  const [showAddCourseForm, setShowAddCourseForm] = useState(false)
  const [editingCourse, setEditingCourse] = useState<Course | null>(null)
  const [courseForm, setCourseForm] = useState({
    courseName: '',
    courseCode: '',
    teacher: '',
    credits: 0,
    semester: getCurrentSemester(),
  })

  // 课程时间表状态
  const [schedules, setSchedules] = useState<Array<{
    dayOfWeek: number
    startTime: string
    endTime: string
    location: string
    weeks: string
  }>>([{
    dayOfWeek: 1,
    startTime: '08:00',
    endTime: '09:40',
    location: '',
    weeks: '1-16'
  }])

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
      console.log('开始加载课程列表...')
      const data = await courseApi.getCourses()
      console.log('课程列表数据:', data)
      setCourses(data.courses)
      console.log('课程列表状态已更新，共', data.courses.length, '门课程')
    } catch (err: any) {
      console.error('加载课程失败:', err)
      setError('加载课程失败: ' + (err.response?.data?.message || err.message))
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

  // 打开添加课程表单
  const handleOpenAddForm = () => {
    setCourseForm({
      courseName: '',
      courseCode: '',
      teacher: '',
      credits: 0,
      semester: getCurrentSemester(),
    })
    setSchedules([{
      dayOfWeek: 1,
      startTime: '08:00',
      endTime: '09:40',
      location: '',
      weeks: '1-16'
    }])
    setEditingCourse(null)
    setShowAddCourseForm(true)
  }

  // 打开编辑课程表单
  const handleEditCourse = (course: Course) => {
    setCourseForm({
      courseName: course.courseName,
      courseCode: course.courseCode || '',
      teacher: course.teacher || '',
      credits: course.credits || 0,
      semester: course.semester || getCurrentSemester(),
    })

    // 将数字数组转换为字符串格式
    const formatWeeks = (weeks?: number[]): string => {
      if (!weeks || weeks.length === 0) return '1-16'

      const sorted = [...weeks].sort((a, b) => a - b)
      const ranges: string[] = []
      let start = sorted[0]
      let end = sorted[0]

      for (let i = 1; i < sorted.length; i++) {
        if (sorted[i] === end + 1) {
          end = sorted[i]
        } else {
          ranges.push(start === end ? `${start}` : `${start}-${end}`)
          start = sorted[i]
          end = sorted[i]
        }
      }
      ranges.push(start === end ? `${start}` : `${start}-${end}`)

      return ranges.join(',')
    }

    // 加载课程的时间表
    if (course.schedule && course.schedule.length > 0) {
      setSchedules(course.schedule.map(s => ({
        dayOfWeek: s.dayOfWeek,
        startTime: s.startTime,
        endTime: s.endTime,
        location: s.location || '',
        weeks: formatWeeks(s.weeks)
      })))
    } else {
      setSchedules([{
        dayOfWeek: 1,
        startTime: '08:00',
        endTime: '09:40',
        location: '',
        weeks: '1-16'
      }])
    }

    setEditingCourse(course)
    setShowAddCourseForm(true)
  }

  // 添加时间段
  const handleAddSchedule = () => {
    setSchedules([...schedules, {
      dayOfWeek: 1,
      startTime: '08:00',
      endTime: '09:40',
      location: '',
      weeks: '1-16'
    }])
  }

  // 删除时间段
  const handleRemoveSchedule = (index: number) => {
    setSchedules(schedules.filter((_, i) => i !== index))
  }

  // 更新时间段
  const handleUpdateSchedule = (index: number, field: string, value: any) => {
    const newSchedules = [...schedules]
    newSchedules[index] = { ...newSchedules[index], [field]: value }
    setSchedules(newSchedules)
  }

  // 提交课程表单
  const handleSubmitCourse = async () => {
    // 验证
    if (!courseForm.courseName.trim()) {
      setError('请输入课程名称')
      return
    }

    if (schedules.length === 0) {
      setError('请至少添加一个上课时间')
      return
    }

    try {
      setLoading(true)
      setError(null)
      setSuccess(null)

      // 转换weeks字符串为数组
      const parseWeeks = (weeksStr: string): number[] => {
        if (!weeksStr) return []
        const ranges = weeksStr.split(',').map(s => s.trim())
        const weeks: number[] = []

        for (const range of ranges) {
          if (range.includes('-')) {
            const [start, end] = range.split('-').map(n => parseInt(n.trim()))
            if (!isNaN(start) && !isNaN(end)) {
              for (let i = start; i <= end; i++) {
                weeks.push(i)
              }
            }
          } else {
            const week = parseInt(range)
            if (!isNaN(week)) {
              weeks.push(week)
            }
          }
        }

        return [...new Set(weeks)].sort((a, b) => a - b)
      }

      const courseData = {
        ...courseForm,
        schedule: schedules.map(s => ({
          ...s,
          weeks: parseWeeks(s.weeks)
        }))
      }

      console.log('准备提交的课程数据:', JSON.stringify(courseData, null, 2))

      if (editingCourse) {
        // 编辑模式
        const result = await courseApi.updateCourse(editingCourse.courseId, courseData)
        console.log('更新课程成功:', result)
        setSuccess('课程更新成功')
      } else {
        // 添加模式
        const result = await courseApi.addCourse(courseData)
        console.log('添加课程成功:', result)
        setSuccess('课程添加成功')
      }

      // 关闭表单
      setShowAddCourseForm(false)

      // 重新加载数据
      console.log('重新加载课程列表...')
      await loadCourses()
      console.log('重新加载周课表...')
      await loadWeekSchedule()
      console.log('刷新完成')
    } catch (err: any) {
      console.error('操作失败:', err)
      setError(err.response?.data?.message || '操作失败')
    } finally {
      setLoading(false)
    }
  }

  // 删除课程
  const handleDeleteCourse = async (courseId: string, courseName: string) => {
    if (!confirm(`确认删除课程"${courseName}"？此操作不可恢复。`)) {
      return
    }

    try {
      setLoading(true)
      setError(null)
      setSuccess(null)

      await courseApi.deleteCourse(courseId)
      setSuccess('课程删除成功')

      // 重新加载数据
      await loadCourses()
      await loadWeekSchedule()
    } catch (err: any) {
      console.error('删除失败:', err)
      setError(err.response?.data?.message || '删除失败')
    } finally {
      setLoading(false)
    }
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
      <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <h1 className="text-2xl font-bold text-gray-900 mb-6">课表管理</h1>

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
              <div className="flex-1" />
              {activeTab === 'view' && (
                <button
                  onClick={handleOpenAddForm}
                  className="py-2 px-4 bg-blue-600 text-white rounded hover:bg-blue-700 transition-colors"
                >
                  ➕ 添加课程
                </button>
              )}
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
                {/* 统一时间段行 × 7天列的网格，列间竖线分隔 */}
                {(() => {
                  // 固定时间网格：按小时行，覆盖最早到最晚时间；无数据则默认 08:00-22:00
                  const toMinutes = (t: string) => {
                    const [h, m] = t.split(':').map(Number)
                    return h * 60 + m
                  }
                  const toHHMM = (m: number) => {
                    const h = Math.floor(m / 60)
                    const mm = m % 60
                    return `${String(h).padStart(2, '0')}:${String(mm).padStart(2, '0')}`
                  }

                  let minStart = Infinity
                  let maxEnd = -Infinity
                  weekSchedule.schedule.forEach((day) => {
                    day.timeSlots.forEach((slot) => {
                      minStart = Math.min(minStart, toMinutes(slot.startTime))
                      maxEnd = Math.max(maxEnd, toMinutes(slot.endTime))
                    })
                  })

                  // 默认范围
                  if (!isFinite(minStart) || !isFinite(maxEnd)) {
                    minStart = 8 * 60
                    maxEnd = 22 * 60
                  }

                  // 将起止时间对齐到整点
                  const roundDownToHour = (m: number) => Math.floor(m / 60) * 60
                  const roundUpToHour = (m: number) => Math.ceil(m / 60) * 60
                  const startMinutes = roundDownToHour(minStart)
                  const endMinutes = roundUpToHour(maxEnd)
                  const interval = 60 // 每小时一行

                  const rows: Array<{ start: number; end: number }> = []
                  for (let t = startMinutes; t < endMinutes; t += interval) {
                    rows.push({ start: t, end: t + interval })
                  }

                  const dayIndices = [0, 1, 2, 3, 4, 5, 6] // 周日到周六

                  return (
                    <div className="overflow-x-auto">
                      {/* 表头：时间 + 7天 */}
                      <div className="grid grid-cols-8 text-xs font-medium text-gray-700 border-b">
                        <div className="px-3 py-2">时间</div>
                        {dayIndices.map((d) => (
                          <div key={d} className="px-3 py-2 border-l border-gray-200">{formatDayOfWeek(d)}</div>
                        ))}
                      </div>
                      {/* 每个固定时间段一行 */}
                      {rows.map((row, rowIdx) => (
                        <div key={rowIdx} className="grid grid-cols-8 border-b">
                          {/* 时间列 */}
                          <div className="px-3 py-3 text-sm text-gray-600">
                            {toHHMM(row.start)} - {toHHMM(row.end)}
                          </div>
                          {/* 7天列 */}
                          {dayIndices.map((d) => {
                            const day = weekSchedule.schedule.find((x) => x.dayOfWeek === d)
                            // 找到该小时内开始的课程（将课程显示在开始所在的小时格）
                            const match = day?.timeSlots.find((s) => {
                              const sStart = toMinutes(s.startTime)
                              return sStart >= row.start && sStart < row.end
                            })
                            return (
                              <div key={`${rowIdx}-${d}`} className="px-3 py-3 border-l border-gray-200">
                                {match ? (
                                  <div className="rounded-md p-2 bg-blue-50 border border-blue-200">
                                    <div className="text-sm font-medium text-gray-900">{match.course.courseName}</div>
                                    <div className="text-xs text-gray-600 mt-0.5">
                                      {match.startTime} - {match.endTime}
                                      {match.course.location ? ` · ${match.course.location}` : ''}
                                    </div>
                                  </div>
                                ) : (
                                  <div className="text-xs text-gray-400">—</div>
                                )}
                              </div>
                            )
                          })}
                        </div>
                      ))}
                    </div>
                  )
                })()}
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
                        <div className="ml-4 flex space-x-2">
                          <button
                            onClick={() => handleEditCourse(course)}
                            className="px-3 py-1 bg-blue-600 text-white text-sm rounded hover:bg-blue-700 transition-colors"
                          >
                            编辑
                          </button>
                          {course.source === 'manual' && (
                            <button
                              onClick={() => handleDeleteCourse(course.courseId, course.courseName)}
                              className="px-3 py-1 bg-red-600 text-white text-sm rounded hover:bg-red-700 transition-colors"
                            >
                              删除
                            </button>
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

      {/* 添加/编辑课程模态框 */}
      {showAddCourseForm && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-lg max-w-3xl w-full max-h-[90vh] overflow-y-auto p-6">
            <div className="flex justify-between items-center mb-6">
              <h2 className="text-xl font-bold text-gray-900">
                {editingCourse ? '编辑课程' : '添加课程'}
              </h2>
              <button
                onClick={() => setShowAddCourseForm(false)}
                className="text-gray-500 hover:text-gray-700 text-2xl"
              >
                ×
              </button>
            </div>

            {/* 课程基本信息 */}
            <div className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  课程名称 <span className="text-red-500">*</span>
                </label>
                <input
                  type="text"
                  value={courseForm.courseName}
                  onChange={(e) => setCourseForm({ ...courseForm, courseName: e.target.value })}
                  className="w-full px-3 py-2 border border-gray-300 rounded focus:outline-none focus:ring-2 focus:ring-blue-500"
                  placeholder="请输入课程名称"
                />
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">课程代码</label>
                  <input
                    type="text"
                    value={courseForm.courseCode}
                    onChange={(e) => setCourseForm({ ...courseForm, courseCode: e.target.value })}
                    className="w-full px-3 py-2 border border-gray-300 rounded focus:outline-none focus:ring-2 focus:ring-blue-500"
                    placeholder="如: CS101"
                  />
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">教师</label>
                  <input
                    type="text"
                    value={courseForm.teacher}
                    onChange={(e) => setCourseForm({ ...courseForm, teacher: e.target.value })}
                    className="w-full px-3 py-2 border border-gray-300 rounded focus:outline-none focus:ring-2 focus:ring-blue-500"
                    placeholder="任课教师"
                  />
                </div>
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">学分</label>
                  <input
                    type="number"
                    step="0.5"
                    value={courseForm.credits}
                    onChange={(e) => setCourseForm({ ...courseForm, credits: parseFloat(e.target.value) || 0 })}
                    className="w-full px-3 py-2 border border-gray-300 rounded focus:outline-none focus:ring-2 focus:ring-blue-500"
                    placeholder="如: 3"
                  />
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">学期</label>
                  <input
                    type="text"
                    value={courseForm.semester}
                    onChange={(e) => setCourseForm({ ...courseForm, semester: e.target.value })}
                    className="w-full px-3 py-2 border border-gray-300 rounded focus:outline-none focus:ring-2 focus:ring-blue-500"
                    placeholder="如: 2025-1"
                  />
                </div>
              </div>

              {/* 上课时间表 */}
              <div className="border-t pt-4">
                <div className="flex justify-between items-center mb-3">
                  <h3 className="text-lg font-semibold text-gray-900">上课时间安排</h3>
                  <button
                    onClick={handleAddSchedule}
                    className="px-3 py-1 bg-green-600 text-white text-sm rounded hover:bg-green-700 transition-colors"
                  >
                    ➕ 添加时间段
                  </button>
                </div>

                <div className="space-y-3">
                  {schedules.map((schedule, index) => (
                    <div key={index} className="border rounded-lg p-3 bg-gray-50">
                      <div className="grid grid-cols-2 gap-3 mb-3">
                        <div>
                          <label className="block text-sm font-medium text-gray-700 mb-1">星期</label>
                          <select
                            value={schedule.dayOfWeek}
                            onChange={(e) => handleUpdateSchedule(index, 'dayOfWeek', parseInt(e.target.value))}
                            className="w-full px-3 py-2 border border-gray-300 rounded focus:outline-none focus:ring-2 focus:ring-blue-500"
                          >
                            <option value={1}>周一</option>
                            <option value={2}>周二</option>
                            <option value={3}>周三</option>
                            <option value={4}>周四</option>
                            <option value={5}>周五</option>
                            <option value={6}>周六</option>
                            <option value={0}>周日</option>
                          </select>
                        </div>

                        <div>
                          <label className="block text-sm font-medium text-gray-700 mb-1">地点</label>
                          <input
                            type="text"
                            value={schedule.location}
                            onChange={(e) => handleUpdateSchedule(index, 'location', e.target.value)}
                            className="w-full px-3 py-2 border border-gray-300 rounded focus:outline-none focus:ring-2 focus:ring-blue-500"
                            placeholder="如: 教学楼A101"
                          />
                        </div>
                      </div>

                      <div className="grid grid-cols-3 gap-3">
                        <div>
                          <label className="block text-sm font-medium text-gray-700 mb-1">开始时间</label>
                          <input
                            type="time"
                            value={schedule.startTime}
                            onChange={(e) => handleUpdateSchedule(index, 'startTime', e.target.value)}
                            className="w-full px-3 py-2 border border-gray-300 rounded focus:outline-none focus:ring-2 focus:ring-blue-500"
                          />
                        </div>

                        <div>
                          <label className="block text-sm font-medium text-gray-700 mb-1">结束时间</label>
                          <input
                            type="time"
                            value={schedule.endTime}
                            onChange={(e) => handleUpdateSchedule(index, 'endTime', e.target.value)}
                            className="w-full px-3 py-2 border border-gray-300 rounded focus:outline-none focus:ring-2 focus:ring-blue-500"
                          />
                        </div>

                        <div>
                          <label className="block text-sm font-medium text-gray-700 mb-1">周次</label>
                          <input
                            type="text"
                            value={schedule.weeks}
                            onChange={(e) => handleUpdateSchedule(index, 'weeks', e.target.value)}
                            className="w-full px-3 py-2 border border-gray-300 rounded focus:outline-none focus:ring-2 focus:ring-blue-500"
                            placeholder="如: 1-16"
                          />
                        </div>
                      </div>

                      {schedules.length > 1 && (
                        <button
                          onClick={() => handleRemoveSchedule(index)}
                          className="mt-2 text-sm text-red-600 hover:text-red-800"
                        >
                          ✕ 删除此时间段
                        </button>
                      )}
                    </div>
                  ))}
                </div>
              </div>
            </div>

            {/* 操作按钮 */}
            <div className="mt-6 flex justify-end space-x-3">
              <button
                onClick={() => setShowAddCourseForm(false)}
                className="px-4 py-2 border border-gray-300 text-gray-700 rounded hover:bg-gray-50 transition-colors"
                disabled={loading}
              >
                取消
              </button>
              <button
                onClick={handleSubmitCourse}
                className="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700 transition-colors disabled:bg-gray-400"
                disabled={loading}
              >
                {loading ? '保存中...' : editingCourse ? '更新课程' : '添加课程'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}

