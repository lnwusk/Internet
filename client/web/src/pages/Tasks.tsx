import { useEffect, useState } from 'react'
import { studyTaskApi } from '@/api/studyTask'
import { StudyTask } from '@/types/api'

export default function Tasks() {
    const [tasks, setTasks] = useState<StudyTask[]>([])
    const [loading, setLoading] = useState(false)
    const [selectedDate, setSelectedDate] = useState(new Date().toISOString().split('T')[0])

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
                    <input
                        type="date"
                        value={selectedDate}
                        onChange={(e) => setSelectedDate(e.target.value)}
                        className="px-4 py-2 border rounded-lg"
                    />
                </div>

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
