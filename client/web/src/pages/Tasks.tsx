import { useEffect, useState } from 'react'
import { studyTaskApi } from '@/api/studyTask'
import { StudyTask } from '@/types/api'

export default function Tasks() {
    const [tasks, setTasks] = useState<StudyTask[]>([])
    const [loading, setLoading] = useState(false)
    const [selectedDate, setSelectedDate] = useState(new Date().toISOString().split('T')[0])
    const [showAddForm, setShowAddForm] = useState(false)
    const [formData, setFormData] = useState({
        title: '',
        scheduledDate: new Date().toISOString().split('T')[0],
        startTime: '14:00',
        endTime: '16:00',
        estimatedHours: 2,
        description: '',
    })

    useEffect(() => {
        loadTasks()
    }, [selectedDate])

    const loadTasks = async () => {
        try {
            setLoading(true)
            const data = await studyTaskApi.getStudyTasks({ date: selectedDate })
            setTasks(data.tasks)
        } catch (err: any) {
            console.error('加载任务失败:', err)
        } finally {
            setLoading(false)
        }
    }

    const handleAddTask = async (e: React.FormEvent) => {
        e.preventDefault()
        if (!formData.title || !formData.scheduledDate || !formData.startTime || !formData.endTime) {
            alert('请填写必填项')
            return
        }

        try {
            await studyTaskApi.createTask({
                title: formData.title,
                scheduledDate: formData.scheduledDate,
                startTime: formData.startTime,
                endTime: formData.endTime,
                estimatedHours: formData.estimatedHours || undefined,
                description: formData.description || undefined,
            })
            alert('任务创建成功')
            setShowAddForm(false)
            setFormData({
                title: '',
                scheduledDate: new Date().toISOString().split('T')[0],
                startTime: '14:00',
                endTime: '16:00',
                estimatedHours: 2,
                description: '',
            })
            loadTasks()
        } catch (err: any) {
            alert('创建失败: ' + (err.response?.data?.message || err.message))
        }
    }

    const handleComplete = async (taskId: string) => {
        try {
            await studyTaskApi.completeTask(taskId)
            alert('任务已完成')
            loadTasks()
        } catch (err: any) {
            alert('操作失败: ' + (err.response?.data?.message || err.message))
        }
    }

    const handleDelete = async (taskId: string) => {
        if (!confirm('确认删除此任务？')) return

        try {
            await studyTaskApi.deleteTask(taskId)
            alert('删除成功')
            loadTasks()
        } catch (err: any) {
            alert('删除失败: ' + (err.response?.data?.message || err.message))
        }
    }

    return (
        <div className="min-h-screen bg-gray-50 py-8">
            <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
                <div className="flex justify-between items-center mb-6">
                    <h1 className="text-2xl font-bold text-gray-900">学习任务</h1>
                    <div className="flex items-center space-x-3">
                        <input
                            type="date"
                            value={selectedDate}
                            onChange={(e) => setSelectedDate(e.target.value)}
                            className="px-4 py-2 border rounded-lg"
                        />
                        <button
                            onClick={() => setShowAddForm(true)}
                            className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700"
                        >
                            添加任务
                        </button>
                    </div>
                </div>

                {/* 添加任务表单弹窗 */}
                {showAddForm && (
                    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
                        <div className="bg-white rounded-lg p-6 w-full max-w-md">
                            <h2 className="text-xl font-bold mb-4">添加学习任务</h2>
                            <form onSubmit={handleAddTask} className="space-y-4">
                                <div>
                                    <label className="block text-sm font-medium mb-1">任务标题 *</label>
                                    <input
                                        type="text"
                                        value={formData.title}
                                        onChange={(e) => setFormData({ ...formData, title: e.target.value })}
                                        className="w-full border rounded px-3 py-2"
                                        placeholder="请输入任务标题"
                                        required
                                    />
                                </div>
                                <div>
                                    <label className="block text-sm font-medium mb-1">计划日期 *</label>
                                    <input
                                        type="date"
                                        value={formData.scheduledDate}
                                        onChange={(e) => setFormData({ ...formData, scheduledDate: e.target.value })}
                                        className="w-full border rounded px-3 py-2"
                                        required
                                    />
                                </div>
                                <div className="grid grid-cols-2 gap-3">
                                    <div>
                                        <label className="block text-sm font-medium mb-1">开始时间 *</label>
                                        <input
                                            type="time"
                                            value={formData.startTime}
                                            onChange={(e) => setFormData({ ...formData, startTime: e.target.value })}
                                            className="w-full border rounded px-3 py-2"
                                            required
                                        />
                                    </div>
                                    <div>
                                        <label className="block text-sm font-medium mb-1">结束时间 *</label>
                                        <input
                                            type="time"
                                            value={formData.endTime}
                                            onChange={(e) => setFormData({ ...formData, endTime: e.target.value })}
                                            className="w-full border rounded px-3 py-2"
                                            required
                                        />
                                    </div>
                                </div>
                                <div>
                                    <label className="block text-sm font-medium mb-1">预估时长（小时）</label>
                                    <input
                                        type="number"
                                        step="0.5"
                                        value={formData.estimatedHours}
                                        onChange={(e) => setFormData({ ...formData, estimatedHours: Number(e.target.value) })}
                                        className="w-full border rounded px-3 py-2"
                                        min="0.5"
                                        max="12"
                                    />
                                </div>
                                <div>
                                    <label className="block text-sm font-medium mb-1">描述</label>
                                    <textarea
                                        value={formData.description}
                                        onChange={(e) => setFormData({ ...formData, description: e.target.value })}
                                        className="w-full border rounded px-3 py-2"
                                        rows={3}
                                        placeholder="可选"
                                    />
                                </div>
                                <div className="flex space-x-3 pt-2">
                                    <button
                                        type="submit"
                                        className="flex-1 px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700"
                                    >
                                        创建
                                    </button>
                                    <button
                                        type="button"
                                        onClick={() => setShowAddForm(false)}
                                        className="flex-1 px-4 py-2 bg-gray-200 text-gray-700 rounded hover:bg-gray-300"
                                    >
                                        取消
                                    </button>
                                </div>
                            </form>
                        </div>
                    </div>
                )}

                {loading ? (
                    <div className="text-center py-8">加载中...</div>
                ) : tasks.length === 0 ? (
                    <div className="bg-white rounded-lg shadow p-8 text-center text-gray-500">
                        该日期暂无学习任务
                    </div>
                ) : (
                    <div className="space-y-4">
                        {tasks.map((task) => (
                            <div key={task.taskId} className="bg-white rounded-lg shadow p-6">
                                <div className="flex justify-between items-start">
                                    <div className="flex-1">
                                        <h3 className="text-lg font-semibold mb-2">{task.title}</h3>
                                        <div className="text-sm text-gray-600 space-y-1">
                                            {task.courseName && <p>课程：{task.courseName}</p>}
                                            <p>
                                                时间：{task.startTime} - {task.endTime}
                                            </p>
                                            {task.estimatedHours && <p>预估时长：{task.estimatedHours}小时</p>}
                                            <p>
                                                状态：
                                                <span
                                                    className={`ml-2 px-2 py-1 rounded text-xs ${task.status === 'completed'
                                                        ? 'bg-green-100 text-green-800'
                                                        : 'bg-yellow-100 text-yellow-800'
                                                        }`}
                                                >
                                                    {task.status === 'completed' ? '已完成' : '待完成'}
                                                </span>
                                            </p>
                                        </div>
                                    </div>
                                    <div className="flex space-x-2">
                                        {task.status !== 'completed' && (
                                            <button
                                                onClick={() => handleComplete(task.taskId)}
                                                className="px-3 py-1 text-sm bg-green-600 text-white rounded hover:bg-green-700"
                                            >
                                                完成
                                            </button>
                                        )}
                                        <button
                                            onClick={() => handleDelete(task.taskId)}
                                            className="px-3 py-1 text-sm bg-red-600 text-white rounded hover:bg-red-700"
                                        >
                                            删除
                                        </button>
                                    </div>
                                </div>
                            </div>
                        ))}
                    </div>
                )}
            </div>
        </div>
    )
}
