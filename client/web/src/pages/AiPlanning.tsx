import { useEffect, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { aiPlanApi } from '@/api/aiPlan'
import { assignmentApi } from '@/api/assignment'
import { Assignment, AiPlanResponse } from '@/types/api'

export default function AiPlanning() {
    const navigate = useNavigate()
    const [step, setStep] = useState<'select' | 'generating' | 'result'>('select')
    const [assignments, setAssignments] = useState<Assignment[]>([])
    const [selectedIds, setSelectedIds] = useState<string[]>([])
    const [planId, setPlanId] = useState<string>('')
    const [planResult, setPlanResult] = useState<AiPlanResponse | null>(null)
    const [loading, setLoading] = useState(false)
    const [progress, setProgress] = useState(0)

    useEffect(() => {
        loadAssignments()
    }, [])

    const loadAssignments = async () => {
        try {
            const data = await assignmentApi.getAssignments({ status: 'pending' })
            setAssignments(data.assignments)
        } catch (err: any) {
            alert('加载作业失败: ' + (err.response?.data?.message || err.message))
        }
    }

    const handleSubmit = async () => {
        if (selectedIds.length === 0) {
            alert('请至少选择一个作业')
            return
        }

        try {
            setLoading(true)
            setStep('generating')
            const result = await aiPlanApi.submitPlan({
                assignmentIds: selectedIds,
                preferences: {
                    dailyMaxHours: 6,
                    preferredStudyTime: 'afternoon',
                },
            })

            setPlanId(result.planId)

            // 轮询查询结果
            pollPlanResult(result.planId)
        } catch (err: any) {
            alert('提交失败: ' + (err.response?.data?.message || err.message))
            setStep('select')
            setLoading(false)
        }
    }

    const pollPlanResult = async (id: string) => {
        const maxAttempts = 60 // 最多尝试60次，每次2秒
        let attempts = 0

        const poll = async () => {
            try {
                const result = await aiPlanApi.getPlanResult(id)

                if (result.progress !== undefined) {
                    setProgress(result.progress)
                }

                if (result.status === 'completed') {
                    setPlanResult(result)
                    setStep('result')
                    setLoading(false)
                    return
                }

                if (result.status === 'failed') {
                    alert('AI规划失败，请重试')
                    setStep('select')
                    setLoading(false)
                    return
                }

                attempts++
                if (attempts < maxAttempts) {
                    setTimeout(poll, 2000) // 2秒后再次查询
                } else {
                    alert('规划超时，请重试')
                    setStep('select')
                    setLoading(false)
                }
            } catch (err: any) {
                console.error('查询规划结果失败:', err)
                attempts++
                if (attempts < maxAttempts) {
                    setTimeout(poll, 2000)
                } else {
                    alert('查询失败，请重试')
                    setStep('select')
                    setLoading(false)
                }
            }
        }

        poll()
    }

    const handleApply = async () => {
        if (!planId) return

        try {
            setLoading(true)
            await aiPlanApi.applyPlan(planId, { applyAll: true })
            alert('规划已应用！学习任务已创建')
            navigate('/tasks')
        } catch (err: any) {
            alert('应用失败: ' + (err.response?.data?.message || err.message))
        } finally {
            setLoading(false)
        }
    }

    const toggleSelection = (id: string) => {
        setSelectedIds(prev =>
            prev.includes(id) ? prev.filter(i => i !== id) : [...prev, id]
        )
    }

    return (
        <div className="min-h-screen bg-gray-50 py-8">
            <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
                <h1 className="text-3xl font-bold text-gray-900 mb-8">AI智能学习规划</h1>

                {step === 'select' && (
                    <div className="bg-white rounded-lg shadow p-6">
                        <h2 className="text-xl font-semibold mb-4">选择要规划的作业</h2>
                        <p className="text-gray-600 mb-4">
                            选择您想要AI帮助规划的作业，系统将根据作业截止时间、难度等因素生成合理的学习计划
                        </p>

                        {assignments.length === 0 ? (
                            <p className="text-center text-gray-500 py-8">暂无待完成的作业</p>
                        ) : (
                            <div className="space-y-3 mb-6">
                                {assignments.map((assignment) => (
                                    <div
                                        key={assignment.assignmentId}
                                        className={`p-4 border-2 rounded-lg cursor-pointer transition ${selectedIds.includes(assignment.assignmentId)
                                                ? 'border-blue-500 bg-blue-50'
                                                : 'border-gray-200 hover:border-gray-300'
                                            }`}
                                        onClick={() => toggleSelection(assignment.assignmentId)}
                                    >
                                        <div className="flex items-center">
                                            <input
                                                type="checkbox"
                                                checked={selectedIds.includes(assignment.assignmentId)}
                                                onChange={() => { }}
                                                className="mr-3 h-4 w-4"
                                            />
                                            <div className="flex-1">
                                                <h3 className="font-medium">{assignment.title}</h3>
                                                <p className="text-sm text-gray-600">
                                                    课程：{assignment.courseName} | 截止：
                                                    {new Date(assignment.dueDate).toLocaleDateString('zh-CN')}
                                                </p>
                                            </div>
                                        </div>
                                    </div>
                                ))}
                            </div>
                        )}

                        <div className="flex space-x-3">
                            <button
                                onClick={handleSubmit}
                                disabled={selectedIds.length === 0 || loading}
                                className="px-6 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:bg-gray-400"
                            >
                                生成AI规划
                            </button>
                            <button
                                onClick={() => navigate(-1)}
                                className="px-6 py-2 bg-gray-200 text-gray-700 rounded-lg hover:bg-gray-300"
                            >
                                返回
                            </button>
                        </div>
                    </div>
                )}

                {step === 'generating' && (
                    <div className="bg-white rounded-lg shadow p-8 text-center">
                        <div className="mb-4">
                            <div className="inline-block animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
                        </div>
                        <h2 className="text-xl font-semibold mb-2">AI正在分析中...</h2>
                        <p className="text-gray-600 mb-4">
                            正在根据您的作业情况生成智能学习规划，请稍候
                        </p>
                        <div className="w-full bg-gray-200 rounded-full h-2 mb-2">
                            <div
                                className="bg-blue-600 h-2 rounded-full transition-all"
                                style={{ width: `${progress}%` }}
                            ></div>
                        </div>
                        <p className="text-sm text-gray-500">{progress}%</p>
                    </div>
                )}

                {step === 'result' && planResult && (
                    <div className="space-y-6">
                        <div className="bg-white rounded-lg shadow p-6">
                            <h2 className="text-xl font-semibold mb-4">规划摘要</h2>
                            <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
                                <div>
                                    <p className="text-sm text-gray-600">作业总数</p>
                                    <p className="text-2xl font-bold">{planResult.summary?.totalAssignments}</p>
                                </div>
                                <div>
                                    <p className="text-sm text-gray-600">预估总时长</p>
                                    <p className="text-2xl font-bold">
                                        {planResult.summary?.totalEstimatedHours.toFixed(1)}h
                                    </p>
                                </div>
                                <div>
                                    <p className="text-sm text-gray-600">规划天数</p>
                                    <p className="text-2xl font-bold">{planResult.summary?.scheduledDays}天</p>
                                </div>
                                <div>
                                    <p className="text-sm text-gray-600">日均学习</p>
                                    <p className="text-2xl font-bold">
                                        {planResult.summary?.averageDailyHours.toFixed(1)}h
                                    </p>
                                </div>
                            </div>
                        </div>

                        {planResult.assignments?.map((assignment) => (
                            <div key={assignment.assignmentId} className="bg-white rounded-lg shadow p-6">
                                <h3 className="text-lg font-semibold mb-2">{assignment.assignmentTitle}</h3>
                                <div className="flex items-center space-x-4 mb-4 text-sm text-gray-600">
                                    <span>预估时长: {assignment.estimatedHours}小时</span>
                                    <span>难度: {assignment.difficulty}</span>
                                </div>

                                <h4 className="font-medium mb-3">推荐学习计划：</h4>
                                <div className="space-y-2">
                                    {assignment.recommendedSchedule.map((slot, idx) => (
                                        <div key={idx} className="flex items-start p-3 bg-gray-50 rounded">
                                            <div className="flex-1">
                                                <p className="font-medium">
                                                    {slot.date} {slot.startTime} - {slot.endTime} ({slot.hours}小时)
                                                </p>
                                                <p className="text-sm text-gray-600 mt-1">{slot.reason}</p>
                                            </div>
                                        </div>
                                    ))}
                                </div>
                            </div>
                        ))}

                        <div className="flex space-x-3">
                            <button
                                onClick={handleApply}
                                disabled={loading}
                                className="px-6 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 disabled:bg-gray-400"
                            >
                                应用此规划
                            </button>
                            <button
                                onClick={() => {
                                    setStep('select')
                                    setSelectedIds([])
                                    setPlanResult(null)
                                }}
                                className="px-6 py-2 bg-gray-200 text-gray-700 rounded-lg hover:bg-gray-300"
                            >
                                重新规划
                            </button>
                        </div>
                    </div>
                )}
            </div>
        </div>
    )
}
