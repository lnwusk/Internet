package com.courseapp.service;

import com.courseapp.dto.CourseRequest;
import com.courseapp.entity.Course;
import com.courseapp.entity.User;
import com.courseapp.repository.CourseRepository;
import com.courseapp.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
@RequiredArgsConstructor
public class CourseService {
    private final CourseRepository courseRepository;
    private final UserRepository userRepository;
    
    public List<Course> getUserCourses(Long userId) {
        return courseRepository.findByUserIdOrderByDayAndTime(userId);
    }
    
    public List<Course> getUserCoursesByDay(Long userId, Integer dayOfWeek) {
        return courseRepository.findByUserIdAndDayOfWeek(userId, dayOfWeek);
    }
    
    public Course createCourse(Long userId, CourseRequest request) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found"));
        
        Course course = new Course();
        course.setName(request.getName());
        course.setTeacher(request.getTeacher());
        course.setClassroom(request.getClassroom());
        course.setDayOfWeek(request.getDayOfWeek());
        course.setStartTime(request.getStartTime());
        course.setEndTime(request.getEndTime());
        course.setDescription(request.getDescription());
        course.setColor(request.getColor());
        course.setUser(user);
        
        return courseRepository.save(course);
    }
    
    public Course updateCourse(Long courseId, Long userId, CourseRequest request) {
        Course course = courseRepository.findById(courseId)
                .orElseThrow(() -> new RuntimeException("Course not found"));
        
        if (!course.getUser().getId().equals(userId)) {
            throw new RuntimeException("Access denied");
        }
        
        course.setName(request.getName());
        course.setTeacher(request.getTeacher());
        course.setClassroom(request.getClassroom());
        course.setDayOfWeek(request.getDayOfWeek());
        course.setStartTime(request.getStartTime());
        course.setEndTime(request.getEndTime());
        course.setDescription(request.getDescription());
        course.setColor(request.getColor());
        
        return courseRepository.save(course);
    }
    
    public void deleteCourse(Long courseId, Long userId) {
        Course course = courseRepository.findById(courseId)
                .orElseThrow(() -> new RuntimeException("Course not found"));
        
        if (!course.getUser().getId().equals(userId)) {
            throw new RuntimeException("Access denied");
        }
        
        courseRepository.delete(course);
    }
}