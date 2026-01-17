import { useEffect, useState } from 'react'
import { userApi } from '@/api/user'
import { UserProfile, UserPreferences } from '@/types/api'

export default function Profile() {
    const [profile, setProfile] = useState<UserProfile | null>(null)
    const [preferences, setPreferences] = useState<UserPreferences | null>(null)
    const [loading, setLoading] = useState(false)
    const [editing, setEditing] = useState(false)
    const [formData, setFormData] = useState({
        nickname: '',
        studentId: '',
    })

    useEffect(() => {
        loadProfile()
        loadPreferences()
    }, [])

    const loadProfile = async () => {
        try {
            const data = await userApi.getProfile()
            setProfile(data)
            setFormData({
                nickname: data.nickname,
                studentId: data.studentId || '',
            })
        } catch (err: any) {
            alert('加载用户信息失败')
        }
    }

    const loadPreferences = async () => {
        try {
            const data = await userApi.getPreferences()
            setPreferences(data)
        } catch (err: any) {
            console.error('加载偏好设置失败:', err)
        }
    }

    const handleSaveProfile = async () => {
        try {
            setLoading(true)
            await userApi.updateProfile(formData)
            alert('保存成功')
            setEditing(false)
            loadProfile()
        } catch (err: any) {
            alert('保存失败: ' + (err.response?.data?.message || err.message))
        } finally {
            setLoading(false)
        }
    }

    const handleSavePreferences = async () => {
        if (!preferences) return
        try {
            setLoading(true)
            await userApi.updatePreferences(preferences)
            alert('保存成功')
        } catch (err: any) {
            alert('保存失败: ' + (err.response?.data?.message || err.message))
        } finally {
            setLoading(false)
        }
    }

    if (!profile) {
        return <div className="text-center py-8">加载中...</div>
    }

    return (
        <div className="min-h-screen bg-gray-50 py-8">
            <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8">
                <h1 className="text-2xl font-bold text-gray-900 mb-6">个人中心</h1>

                {/* 基本信息 */}
                <div className="bg-white rounded-lg shadow p-6 mb-6">
                    <div className="flex justify-between items-center mb-4">
                        <h2 className="text-xl font-semibold">基本信息</h2>
                        {!editing && (
                            <button
                                onClick={() => setEditing(true)}
                                className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700"
                            >
                                编辑
                            </button>
                        )}
                    </div>

                    {editing ? (
                        <div className="space-y-4">
                            <div>
                                <label className="block text-sm font-medium text-gray-700 mb-1">用户名</label>
                                <input
                                    type="text"
                                    value={profile.username}
                                    disabled
                                    className="w-full px-3 py-2 border rounded-lg bg-gray-100"
                                />
                            </div>
                            <div>
                                <label className="block text-sm font-medium text-gray-700 mb-1">昵称</label>
                                <input
                                    type="text"
                                    value={formData.nickname}
                                    onChange={(e) => setFormData({ ...formData, nickname: e.target.value })}
                                    className="w-full px-3 py-2 border rounded-lg"
                                />
                            </div>
                            <div>
                                <label className="block text-sm font-medium text-gray-700 mb-1">学号</label>
                                <input
                                    type="text"
                                    value={formData.studentId}
                                    onChange={(e) => setFormData({ ...formData, studentId: e.target.value })}
                                    className="w-full px-3 py-2 border rounded-lg"
                                />
                            </div>
                            <div className="flex space-x-3">
                                <button
                                    onClick={handleSaveProfile}
                                    disabled={loading}
                                    className="px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700"
                                >
                                    保存
                                </button>
                                <button
                                    onClick={() => {
                                        setEditing(false)
                                        setFormData({
                                            nickname: profile.nickname,
                                            studentId: profile.studentId || '',
                                        })
                                    }}
                                    className="px-4 py-2 bg-gray-200 text-gray-700 rounded-lg hover:bg-gray-300"
                                >
                                    取消
                                </button>
                            </div>
                        </div>
                    ) : (
                        <div className="space-y-3">
                            <div>
                                <span className="text-sm text-gray-600">用户名：</span>
                                <span className="ml-2">{profile.username}</span>
                            </div>
                            <div>
                                <span className="text-sm text-gray-600">昵称：</span>
                                <span className="ml-2">{profile.nickname}</span>
                            </div>
                            <div>
                                <span className="text-sm text-gray-600">学号：</span>
                                <span className="ml-2">{profile.studentId || '未设置'}</span>
                            </div>
                            <div>
                                <span className="text-sm text-gray-600">注册时间：</span>
                                <span className="ml-2">
                                    {new Date(profile.createdAt).toLocaleDateString('zh-CN')}
                                </span>
                            </div>
                        </div>
                    )}
                </div>

                {/* 偏好设置 */}
                {preferences && (
                    <div className="bg-white rounded-lg shadow p-6">
                        <h2 className="text-xl font-semibold mb-4">偏好设置</h2>
                        <div className="space-y-4">
                            <div className="flex items-center justify-between">
                                <span>启用通知</span>
                                <input
                                    type="checkbox"
                                    checked={preferences.notificationEnabled}
                                    onChange={(e) =>
                                        setPreferences({ ...preferences, notificationEnabled: e.target.checked })
                                    }
                                    className="h-4 w-4"
                                />
                            </div>
                            <div>
                                <label className="block text-sm font-medium text-gray-700 mb-1">
                                    课程提醒提前分钟数
                                </label>
                                <input
                                    type="number"
                                    value={preferences.courseReminderMinutes}
                                    onChange={(e) =>
                                        setPreferences({
                                            ...preferences,
                                            courseReminderMinutes: parseInt(e.target.value),
                                        })
                                    }
                                    className="w-full px-3 py-2 border rounded-lg"
                                />
                            </div>
                            <div>
                                <label className="block text-sm font-medium text-gray-700 mb-1">
                                    作业提醒提前小时数
                                </label>
                                <input
                                    type="number"
                                    value={preferences.assignmentReminderHours}
                                    onChange={(e) =>
                                        setPreferences({
                                            ...preferences,
                                            assignmentReminderHours: parseInt(e.target.value),
                                        })
                                    }
                                    className="w-full px-3 py-2 border rounded-lg"
                                />
                            </div>
                            <div>
                                <label className="block text-sm font-medium text-gray-700 mb-1">
                                    偏好学习时间
                                </label>
                                <select
                                    value={preferences.preferredStudyTime || ''}
                                    onChange={(e) =>
                                        setPreferences({
                                            ...preferences,
                                            preferredStudyTime: e.target.value as any,
                                        })
                                    }
                                    className="w-full px-3 py-2 border rounded-lg"
                                >
                                    <option value="">未设置</option>
                                    <option value="morning">上午</option>
                                    <option value="afternoon">下午</option>
                                    <option value="evening">晚上</option>
                                </select>
                            </div>
                            <button
                                onClick={handleSavePreferences}
                                disabled={loading}
                                className="w-full px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700"
                            >
                                保存偏好设置
                            </button>
                        </div>
                    </div>
                )}
            </div>
        </div>
    )
}
