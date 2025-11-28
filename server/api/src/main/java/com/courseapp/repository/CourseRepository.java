package com.courseapp.repository;

import com.courseapp.entity.Course;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface CourseRepository extends JpaRepository<Course, Long> {
    List<Course> findByUserId(Long userId);
    
    @Query("SELECT c FROM Course c WHERE c.user.id = :userId AND c.dayOfWeek = :dayOfWeek ORDER BY c.startTime")
    List<Course> findByUserIdAndDayOfWeek(@Param("userId") Long userId, @Param("dayOfWeek") Integer dayOfWeek);
    
    @Query("SELECT c FROM Course c WHERE c.user.id = :userId ORDER BY c.dayOfWeek, c.startTime")
    List<Course> findByUserIdOrderByDayAndTime(@Param("userId") Long userId);
}