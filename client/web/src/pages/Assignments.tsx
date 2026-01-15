import { useEffect, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { assignmentApi } from '@/api/assignment'
import { Assignment, AssignmentListResponse } from '@/types/api'

export default function Assignments() {
    const navigate = useNavigate()
    const [loading, setLoading] = useState(false)
    const [assignments, setAssignments] = useState<Assignment[]>([])
    const [stats, setStats] = useState({
        total: 0,
        pendingCount: 0,
        completedCount: 0,
        overdueCount: 0,
    })
    const [filter, setFilter] = useState<'all' | 'pending' | 'completed' | 'overdue'>('all')

    useEffect(() => {
        loadAssignments()
    }, [filter])

    const loadAssignments = async () => {
        try {
            setLoading(true)
            const params = filter !== 'all' ? { status: filter as any } : {}
            const data: AssignmentListResponse = await assignmentApi.getAssignments(params)
            setAssignments(data.assignments)
            setStats({
                total: data.total,
                pendingCount: data.pendingCount,
                completedCount: data.completedCount,
                overdueCount: data.overdueCount,
            })
        } catch (err: any) {
            console.error('加载作业失败:', err)
            alert('加载作业失败: ' + (err.response?.data?.message || err.message))
        } finally {
            setLoading(false)
        }
    }

    const handleComplete = async (assignmentId: string) => {
        if (!confirm('确认标记此作业为已完成？')) return

        try {
            await assignmentApi.completeAssignment(assignmentId)
            alert('标记成功')
            loadAssignments()
        } catch (err: any) {
            alert('标记失败: ' + (err.response?.data?.message || err.message))
        }
    }

    const handleDelete = async (assignmentId: string) => {
        if (!confirm('确认删除此作业？')) return

        try {
            await assignmentApi.deleteAssignment(assignmentId)
            alert('删除成功')
            loadAssignments()
        } catch (err: any) {
            alert('删除失败: ' + (err.response?.data?.message || err.message))
        }
    }

    const formatDate = (dateStr: string) => {
        return new Date(dateStr).toLocaleString('zh-CN', {
            year: 'numeric',
            month: '2-digit',
            day: '2-digit',
            hour: '2-digit',
            minute: '2-digit',
        })
    }

    const getStatusBadge = (status: string) => {
        const styles = {
            pending: 'bg-yellow-100 text-yellow-800',
            completed: 'bg-green-100 text-green-800',
            overdue: 'bg-red-100 text-red-800',
        }
        const labels = {
            pending: '待完成',
            completed: '已完成',
            overdue: '已逾期',
        }
        return (
            <span className={`px-2 py-1 rounded-full text-xs ${styles[status as keyof typeof styles]}`}>
                {labels[status as keyof typeof labels]}
            </span>
        )
    }

    return (
        <div className="min-h-screen bg-gray-50">
            <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
                <div className="flex justify-between items-center mb-6">
                    <h1 className="text-2xl font-bold text-gray-900">作业管理</h1>
                    <button
                        onClick={() => navigate('/assignments/add')}
                        className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700"
                    >
                        添加作业
                    </button>
                </div>

                {/* 统计卡片 */}
                <div className="grid grid-cols-1 md:grid-cols-4 gap-4 mb-6">
                    <div className="bg-white p-4 rounded-lg shadow">
                        <div className="text-sm text-gray-600">全部作业</div>
                        <div className="text-2xl font-bold text-gray-900">{stats.total}</div>
                    </div>
                    <div className="bg-white p-4 rounded-lg shadow">
                        <div className="text-sm text-gray-600">待完成</div>
                        <div className="text-2xl font-bold text-yellow-600">{stats.pendingCount}</div>
                    </div>
                    <div className="bg-white p-4 rounded-lg shadow">
                        <div className="text-sm text-gray-600">已完成</div>
                        <div className="text-2xl font-bold text-green-600">{stats.completedCount}</div>
                    </div>
                    <div className="bg-white p-4 rounded-lg shadow">
                        <div className="text-sm text-gray-600">已逾期</div>
                        <div className="text-2xl font-bold text-red-600">{stats.overdueCount}</div>
                    </div>
                </div>

                {/* 筛选按钮 */}
                <div className="mb-4 flex space-x-2">
                    {(['all', 'pending', 'completed', 'overdue'] as const).map((f) => (
                        <button
                            key={f}
                            onClick={() => setFilter(f)}
                            className={`px-4 py-2 rounded-lg ${filter === f
                                    ? 'bg-blue-600 text-white'
                                    : 'bg-white text-gray-700 hover:bg-gray-100'
                                }`}
                        >
                            {f === 'all' ? '全部' : f === 'pending' ? '待完成' : f === 'completed' ? '已完成' : '已逾期'}
                        </button>
                    ))}
                </div>

                {/* 作业列表 */}
                {loading ? (
                    <div className="text-center py-8">加载中...</div>
                ) : assignments.length === 0 ? (
                    <div className="bg-white rounded-lg shadow p-8 text-center text-gray-500">
                        暂无作业
                    </div>
                ) : (
                    <div className="space-y-4">
                        {assignments.map((assignment) => (
                            <div key={assignment.assignmentId} className="bg-white rounded-lg shadow p-6">
                                <div className="flex justify-between items-start">
                                    <div className="flex-1">
                                        <div className="flex items-center space-x-2 mb-2">
                                            <h3 className="text-lg font-semibold text-gray-900">{assignment.title}</h3>
                                            {getStatusBadge(assignment.status)}
                                        </div>
                                        <div className="text-sm text-gray-600 space-y-1">
                                            <p>课程：{assignment.courseName}</p>
                                            <p>截止时间：{formatDate(assignment.dueDate)}</p>
                                            {assignment.description && (
                                                <p className="mt-2 text-gray-700">{assignment.description}</p>
                                            )}
                                            {assignment.estimatedHours && (
                                                <p>预估时长：{assignment.estimatedHours} 小时</p>
                                            )}
                                        </div>
                                    </div>
                                    <div className="flex space-x-2 ml-4">
                                        {assignment.status === 'pending' && (
                                            <button
                                                onClick={() => handleComplete(assignment.assignmentId)}
                                                className="px-3 py-1 text-sm bg-green-600 text-white rounded hover:bg-green-700"
                                            >
                                                完成
                                            </button>
                                        )}
                                        <button
                                            onClick={() => navigate(`/assignments/${assignment.assignmentId}`)}
                                            className="px-3 py-1 text-sm bg-blue-600 text-white rounded hover:bg-blue-700"
                                        >
                                            详情
                                        </button>
                                        {assignment.source === 'manual' && (
                                            <button
                                                onClick={() => handleDelete(assignment.assignmentId)}
                                                className="px-3 py-1 text-sm bg-red-600 text-white rounded hover:bg-red-700"
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
    )
}
