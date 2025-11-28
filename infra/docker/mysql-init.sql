-- 初始化课程表数据库

-- 确保数据库存在
CREATE DATABASE IF NOT EXISTS course_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- 使用数据库
USE course_db;

-- 创建用户表（Spring Boot JPA会自动创建，这里作为参考）
-- CREATE TABLE IF NOT EXISTS users (
--     id BIGINT AUTO_INCREMENT PRIMARY KEY,
--     username VARCHAR(50) UNIQUE NOT NULL,
--     password VARCHAR(255) NOT NULL,
--     email VARCHAR(100),
--     real_name VARCHAR(50),
--     student_id VARCHAR(20),
--     created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
--     updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
-- );

-- 创建课程表（Spring Boot JPA会自动创建，这里作为参考）
-- CREATE TABLE IF NOT EXISTS courses (
--     id BIGINT AUTO_INCREMENT PRIMARY KEY,
--     name VARCHAR(100) NOT NULL,
--     teacher VARCHAR(50),
--     classroom VARCHAR(50),
--     day_of_week INT NOT NULL CHECK (day_of_week BETWEEN 1 AND 7),
--     start_time TIME NOT NULL,
--     end_time TIME NOT NULL,
--     description TEXT,
--     color VARCHAR(20) DEFAULT '#2196F3',
--     user_id BIGINT NOT NULL,
--     created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
--     updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
--     FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
-- );

-- 插入示例数据（可选）
-- INSERT INTO users (username, password, email, real_name, student_id) VALUES
-- ('admin', '$2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iAt6Z5EHsM8lE9lBOsl7iKTVKIFi', 'admin@example.com', '管理员', '2020001'),
-- ('student1', '$2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iAt6Z5EHsM8lE9lBOsl7iKTVKIFi', 'student1@example.com', '张三', '2020002');

-- 注意：密码为 'password123' 的BCrypt加密结果
-- 实际使用时建议通过API注册用户

-- 创建索引优化查询性能
-- CREATE INDEX idx_courses_user_day ON courses(user_id, day_of_week);
-- CREATE INDEX idx_courses_user_time ON courses(user_id, start_time);

COMMIT;