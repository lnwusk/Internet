export default function NotFound() {
    return (
        <div className="min-h-screen flex items-center justify-center bg-gray-50">
            <div className="text-center">
                <div className="text-6xl font-bold text-gray-300">404</div>
                <div className="mt-2 text-lg text-gray-700">页面未找到</div>
                <div className="mt-4 text-sm text-gray-500">请检查地址是否正确，或从菜单进入对应页面。</div>
                <a href="/" className="mt-6 inline-block px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700">返回首页</a>
            </div>
        </div>
    )
}
