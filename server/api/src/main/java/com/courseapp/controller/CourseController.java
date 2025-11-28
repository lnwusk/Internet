package com.courseapp.controller;

import com.courseapp.dto.CourseRequest;
import com.courseapp.entity.Course;
import com.courseapp.security.JwtTokenUtil;
import com.courseapp.service.CourseService;
import io.swagger.annotations.Api;
import io.swagger.annotations.ApiOperation;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import javax.servlet.http.HttpServletRequest;
import javax.validation.Valid;
import java.util.List;

@RestController
@RequestMapping("/api/courses")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
@Api(tags = "Course Management")
public class CourseController {
    private final CourseService courseService;
    private final JwtTokenUtil jwtTokenUtil;
    
    @GetMapping
    @ApiOperation("Get user courses")
    public ResponseEntity<List<Course>> getUserCourses(HttpServletRequest request) {
        try {
            Long userId = getUserIdFromToken(request);
            List<Course> courses = courseService.getUserCourses(userId);
            return ResponseEntity.ok(courses);
        } catch (Exception e) {
            return ResponseEntity.badRequest().build();
        }
    }
    
    @GetMapping("/day/{dayOfWeek}")
    @ApiOperation("Get courses by day of week")
    public ResponseEntity<List<Course>> getUserCoursesByDay(
            @PathVariable Integer dayOfWeek, 
            HttpServletRequest request) {
        try {
            Long userId = getUserIdFromToken(request);
            List<Course> courses = courseService.getUserCoursesByDay(userId, dayOfWeek);
            return ResponseEntity.ok(courses);
        } catch (Exception e) {
            return ResponseEntity.badRequest().build();
        }
    }
    
    @PostMapping
    @ApiOperation("Create a new course")
    public ResponseEntity<Course> createCourse(
            @Valid @RequestBody CourseRequest courseRequest,
            HttpServletRequest request) {
        try {
            Long userId = getUserIdFromToken(request);
            Course course = courseService.createCourse(userId, courseRequest);
            return ResponseEntity.ok(course);
        } catch (Exception e) {
            return ResponseEntity.badRequest().build();
        }
    }
    
    @PutMapping("/{courseId}")
    @ApiOperation("Update a course")
    public ResponseEntity<Course> updateCourse(
            @PathVariable Long courseId,
            @Valid @RequestBody CourseRequest courseRequest,
            HttpServletRequest request) {
        try {
            Long userId = getUserIdFromToken(request);
            Course course = courseService.updateCourse(courseId, userId, courseRequest);
            return ResponseEntity.ok(course);
        } catch (Exception e) {
            return ResponseEntity.badRequest().build();
        }
    }
    
    @DeleteMapping("/{courseId}")
    @ApiOperation("Delete a course")
    public ResponseEntity<String> deleteCourse(
            @PathVariable Long courseId,
            HttpServletRequest request) {
        try {
            Long userId = getUserIdFromToken(request);
            courseService.deleteCourse(courseId, userId);
            return ResponseEntity.ok("Course deleted successfully");
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }
    
    private Long getUserIdFromToken(HttpServletRequest request) {
        String token = request.getHeader("Authorization");
        if (token != null && token.startsWith("Bearer ")) {
            token = token.substring(7);
            return jwtTokenUtil.getUserIdFromToken(token);
        }
        throw new RuntimeException("Invalid token");
    }
}