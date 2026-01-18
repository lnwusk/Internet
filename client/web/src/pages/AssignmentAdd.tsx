import { useEffect, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { assignmentApi } from '@/api/assignment'
import { courseApi } from '@/api/course'
import { Course } from '@/types/api'

export default function AssignmentAdd() {
    const navigate = useNavigate()
    const [courses, setCourses] = useState<Course[]>([])
    const [saving, setSaving] = useState(false)
    const [error, setError] = useState<string | null>(null)

    const [form, setForm] = useState({
        courseId: '',
        title: '',
        description: '',
        dueDate: '',
        type: '',
        wordCount: '',
        difficulty: 'medium',
    })

    useEffect(() => {
        const load = async () => {
            try {
                const data = await courseApi.getCourses()
                setCourses(data.courses)
            } catch (e: any) {
                setError(e.response?.data?.message || e.message || '加载课程失败')
            }
        }
        load()
    }, [])

    const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement | HTMLSelectElement>) => {
        const { name, value } = e.target
        setForm((prev) => ({ ...prev, [name]: value }))
    }

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault()
        if (!form.title || !form.dueDate || !form.courseId) {
            setError('请填写课程、标题与截止时间')
            return
        }
        try {
            setSaving(true)
            setError(null)
            await assignmentApi.addAssignment({
                courseId: form.courseId,
                title: form.title,
                description: form.description || undefined,
                dueDate: form.dueDate,
                type: form.type || undefined,
                wordCount: form.wordCount ? Number(form.wordCount) : undefined,
                difficulty: form.difficulty as any,
            })
            navigate('/assignments')
        } catch (e: any) {
            setError(e.response?.data?.message || e.message || '添加作业失败')
        } finally {
            setSaving(false)
        }
    }

    return (
        <div className="min-h-screen bg-gray-50">
            <div className="max-w-3xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
                <h1 className="text-2xl font-bold text-gray-900 mb-6">添加作业</h1>
                {error && (
                    <div className="mb-4 bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded">{error}</div>
                )}
                <form onSubmit={handleSubmit} className="bg-white rounded-lg shadow p-6 space-y-4">
                    <div>
                        <label className="block text-sm font-medium text-gray-700 mb-1">课程</label>
                        <select
                            name="courseId"
                            value={form.courseId}
                            onChange={handleChange}
                            className="w-full border rounded p-2"
                            required
                        >
                            <option value="">请选择课程</option>
                            {courses.map((c) => (
                                <option key={c.courseId} value={c.courseId}>{c.courseName}</option>
                            ))}
                        </select>
                    </div>
                    <div>
                        <label className="block text-sm font-medium text-gray-700 mb-1">标题</label>
                        <input
                            name="title"
                            value={form.title}
                            onChange={handleChange}
                            className="w-full border rounded p-2"
                            placeholder="请输入作业标题"
                            required
                        />
                    </div>
                    <div>
                        <label className="block text-sm font-medium text-gray-700 mb-1">描述</label>
                        <textarea
                            name="description"
                            value={form.description}
                            onChange={handleChange}
                            className="w-full border rounded p-2"
                            rows={3}
                            placeholder="可选"
                        />
                    </div>
                    <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                        <div>
                            <label className="block text-sm font-medium text-gray-700 mb-1">截止时间</label>
                            <input
                                type="datetime-local"
                                name="dueDate"
                                value={form.dueDate}
                                onChange={handleChange}
                                className="w-full border rounded p-2"
                                required
                            />
                        </div>
                        <div>
                            <label className="block text-sm font-medium text-gray-700 mb-1">难度</label>
                            <select
                                name="difficulty"
                                value={form.difficulty}
                                onChange={handleChange}
                                className="w-full border rounded p-2"
                            >
                                <option value="easy">简单</option>
                                <option value="medium">中等</option>
                                <option value="hard">困难</option>
                            </select>
                        </div>
                    </div>
                    <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                        <div>
                            <label className="block text-sm font-medium text-gray-700 mb-1">类型</label>
                            <input
                                name="type"
                                value={form.type}
                                onChange={handleChange}
                                className="w-full border rounded p-2"
                                placeholder="例如：论文/项目/实验"
                            />
                        </div>
                        <div>
                            <label className="block text-sm font-medium text-gray-700 mb-1">字数</label>
                            <input
                                type="number"
                                name="wordCount"
                                value={form.wordCount}
                                onChange={handleChange}
                                className="w-full border rounded p-2"
                                placeholder="可选"
                            />
                        </div>
                    </div>
                    <div className="flex space-x-3">
                        <button type="submit" disabled={saving} className="px-6 py-2 bg-blue-600 text-white rounded hover:bg-blue-700 disabled:bg-gray-400">
                            {saving ? '提交中...' : '提交'}
                        </button>
                        <button type="button" onClick={() => navigate('/assignments')} className="px-6 py-2 bg-gray-600 text-white rounded hover:bg-gray-700">
                            取消
                        </button>
                    </div>
                </form>
            </div>
        </div>
    )
}
