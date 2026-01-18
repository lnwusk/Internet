import { useEffect, useState } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import { assignmentApi } from '@/api/assignment'
import { AssignmentDetail } from '@/types/api'

export default function AssignmentDetailPage() {
    const { id } = useParams()
    const navigate = useNavigate()
    const [detail, setDetail] = useState<AssignmentDetail | null>(null)
    const [loading, setLoading] = useState(true)
    const [error, setError] = useState<string | null>(null)

    useEffect(() => {
        const load = async () => {
            if (!id) return
            try {
                const data = await assignmentApi.getAssignment(id)
                setDetail(data)
            } catch (e: any) {
                setError(e.response?.data?.message || e.message || '加载作业详情失败')
            } finally {
                setLoading(false)
            }
        }
        load()
    }, [id])

    if (loading) {
        return <div className="min-h-screen bg-gray-50"><div className="max-w-3xl mx-auto px-4 py-8">加载中...</div></div>
    }

    if (error) {
        return (
            <div className="min-h-screen bg-gray-50">
                <div className="max-w-3xl mx-auto px-4 py-8">
                    <div className="mb-4 bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded">{error}</div>
                    <button onClick={() => navigate('/assignments')} className="px-4 py-2 bg-gray-600 text-white rounded">返回列表</button>
                </div>
            </div>
        )
    }

    if (!detail) return null

    return (
        <div className="min-h-screen bg-gray-50">
            <div className="max-w-3xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
                <h1 className="text-2xl font-bold text-gray-900 mb-6">作业详情</h1>
                <div className="bg-white rounded-lg shadow p-6 space-y-4">
                    <div className="flex justify-between items-start">
                        <div>
                            <div className="text-lg font-semibold text-gray-900">{detail.title}</div>
                            <div className="text-sm text-gray-600">课程：{detail.courseName}</div>
                        </div>
                        <button onClick={() => navigate('/assignments')} className="px-3 py-1 bg-gray-600 text-white rounded">返回</button>
                    </div>
                    {detail.description && (
                        <div>
                            <div className="text-sm font-medium text-gray-700 mb-1">描述</div>
                            <div className="text-sm text-gray-800 whitespace-pre-wrap">{detail.description}</div>
                        </div>
                    )}
                    <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                        <div className="text-sm text-gray-700">截止时间：{new Date(detail.dueDate).toLocaleString('zh-CN')}</div>
                        <div className="text-sm text-gray-700">状态：{detail.status === 'pending' ? '待完成' : detail.status === 'completed' ? '已完成' : '已逾期'}</div>
                        {detail.type && <div className="text-sm text-gray-700">类型：{detail.type}</div>}
                        {detail.wordCount !== undefined && <div className="text-sm text-gray-700">字数：{detail.wordCount}</div>}
                        {detail.difficulty && <div className="text-sm text-gray-700">难度：{detail.difficulty}</div>}
                    </div>
                </div>
            </div>
        </div>
    )
}
