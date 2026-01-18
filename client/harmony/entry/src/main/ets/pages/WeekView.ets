import { CourseService } from '../services/CourseService';
import { StudyTaskService } from '../services/StudyTaskService';
import { WeekScheduleData, TimeSlot, CourseBasic, CourseDetail, CourseScheduleItem, StudyTask } from '../common/models/ApiModels';
import { Logger } from '../common/utils/Logger';
import common from '@ohos.app.ability.common';
import router from '@ohos.router';
import { CourseDetailDialog } from './CourseDetailDialog';
import { StudyTaskDialog } from './StudyTaskDialog';

class ScheduleRow {
  start: string = '';
  end: string = '';
  type: number = 0;
  label: string = '';
}

class SlotInfo {
  isStart: boolean = false;
  span: number = 1;
  course: TimeSlot = new TimeSlot();
}

// 学习任务时间槽信息
class TaskSlotInfo {
  isStart: boolean = false;
  task: StudyTask = new StudyTask();
}

// 任务位置信息
class TaskPosition {
  x: number = 0;
  y: number = 0;
  rowIndex: number = -1;
}

@Component
export struct WeekView {
  @State weekData: WeekScheduleData = new WeekScheduleData();
  @State studyTasks: StudyTask[] = [];  // 学习任务列表
  @State isLoading: boolean = false;
  @State currentWeekIndex: number = 1;
  @State currentSemester: string = '2025-2026-1';
  private semesterOptions: SelectOption[] = [
    { value: '2025-2026-1' },
    { value: '2024-2025-2' },
    { value: '2024-2025-1' },
    { value: '2023-2024-2' },
    { value: '2023-2024-1' }
  ];

  @StorageLink('needRefreshSchedule') @Watch('onRefreshNeeded') refreshFlag: number = 0;
  
  // 弹窗控制器
  private selectedCourse: CourseDetail = new CourseDetail();
  private selectedSlot: TimeSlot = new TimeSlot();
  
  dialogController: CustomDialogController = new CustomDialogController({
    builder: CourseDetailDialog({
      course: this.selectedCourse,
      currentSlot: this.selectedSlot,
      onDeleteSuccess: () => {
         this.loadSchedule();
      }
    }),
    autoCancel: true,
    customStyle: true
  });

  // 学习任务弹窗数据
  @State selectedTask: StudyTask | undefined = undefined;
  @State presetDate: string = '';
  @State presetStartTime: string = '';

  taskDialogController: CustomDialogController = new CustomDialogController({
    builder: StudyTaskDialog({
      editTask: this.selectedTask,
      presetDate: this.presetDate,
      presetStartTime: this.presetStartTime,
      onSuccess: () => {
        this.loadSchedule();
      }
    }),
    autoCancel: true,
    customStyle: true
  });

  // 拖拽相关状态
  @State draggingTask: StudyTask | null = null;
  @State dragOffsetY: number = 0;
  @State dragOffsetX: number = 0;
  @State isDragging: boolean = false;

  private context: common.UIAbilityContext | null = null;
  private weekDays: string[] = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  // 打开课程详情
  showCourseDetail(course: CourseDetail, slot: TimeSlot) {
      this.selectedCourse = course;
      this.selectedSlot = slot;
      this.dialogController.open();
  }

  // 打开任务弹窗(新建)
  openNewTaskDialog(day: number, startTime: string) {
    // 计算当前周的具体日期
    const today = new Date();
    const dayOfWeek = today.getDay() || 7;
    const diff = day - dayOfWeek;
    const targetDate = new Date(today);
    targetDate.setDate(today.getDate() + diff);

    const year = targetDate.getFullYear();
    const month = (targetDate.getMonth() + 1).toString().padStart(2, '0');
    const dayStr = targetDate.getDate().toString().padStart(2, '0');

    this.selectedTask = undefined;
    this.presetDate = `${year}-${month}-${dayStr}`;
    this.presetStartTime = startTime;
    this.taskDialogController.open();
  }

  // 打开任务弹窗(编辑)
  openEditTaskDialog(task: StudyTask) {
    this.selectedTask = task;
    this.presetDate = '';
    this.presetStartTime = '';
    this.taskDialogController.open();
  }

  private rows: ScheduleRow[] = [
    { start: '08:00', end: '08:50', type: 0, label: '1' },
    { start: '09:00', end: '09:50', type: 0, label: '2' },
    { start: '10:10', end: '11:00', type: 0, label: '3' },
    { start: '11:10', end: '12:00', type: 0, label: '4' },
    { start: '12:00', end: '14:00', type: 1, label: '午休' },
    { start: '14:00', end: '14:50', type: 0, label: '5' },
    { start: '15:00', end: '15:50', type: 0, label: '6' },
    { start: '16:10', end: '17:00', type: 0, label: '7' },
    { start: '17:10', end: '18:00', type: 0, label: '8' },
    { start: '18:00', end: '18:30', type: 1, label: '晚饭' },
    { start: '18:30', end: '19:20', type: 0, label: '9' },
    { start: '19:30', end: '20:20', type: 0, label: '10' },
    { start: '20:30', end: '21:20', type: 0, label: '11' },
    { start: '21:30', end: '22:00', type: 1, label: '晚休' }
  ];

  aboutToAppear() {
    this.context = getContext(this) as common.UIAbilityContext;
    this.loadSchedule();
  }

  onRefreshNeeded() {
    if (this.refreshFlag > 0) {
      Logger.info('WeekView: Refresh flag changed, reloading schedule');
      try {
        this.loadSchedule();
      } catch (err) {
        Logger.error('WeekView: Refresh failed, ignoring error');
      }
    }
  }

  async loadSchedule() {
    if (!this.context) return;
    this.isLoading = true;
    try {
      // 加载课程数据
      const courseResponse = await CourseService.getWeekSchedule(this.context, this.currentWeekIndex, this.currentSemester);
      if (courseResponse.code === 200 && courseResponse.data) {
        this.weekData = courseResponse.data;
        this.currentWeekIndex = courseResponse.data.requestedWeek;
        if (courseResponse.data.semester) {
             this.currentSemester = courseResponse.data.semester;
        }
      }

      // 加载学习任务（不传week参数，获取所有任务）
      const taskResponse = await StudyTaskService.getStudyTasks(this.context);
      if (taskResponse.code === 200 && taskResponse.data && taskResponse.data.tasks) {
        // 获取当前周的日期范围
        const weekDates = this.getWeekDates(this.currentWeekIndex);
        // 过滤当前周的任务
        this.studyTasks = taskResponse.data.tasks.filter(t =>
          weekDates.includes(t.scheduledDate)
        );
        Logger.info(`Loaded ${this.studyTasks.length} study tasks for week ${this.currentWeekIndex}`);
        Logger.info(`All tasks: ${taskResponse.data.tasks.length}, Week dates: ${weekDates.join(', ')}`);
      }
    } catch (err) {
      Logger.error('Failed to load schedule:', JSON.stringify(err));
    } finally {
      this.isLoading = false;
    }
  }

  private lightColors: string[] = [
    '#FFEBEE', '#FFCDD2', '#F3E5F5', '#E1BEE7',
    '#E8EAF6', '#C5CAE9', '#E3F2FD', '#BBDEFB',
    '#E0F7FA', '#B2EBF2', '#E0F2F1', '#B2DFDB',
    '#E8F5E9', '#C8E6C9', '#F1F8E9', '#DCEDC8',
    '#FFFDE7', '#FFF9C4', '#FFF3E0', '#FFE0B2'
  ];

  // 学习任务使用绿色/橙色系
  private taskColors: string[] = [
    '#C8E6C9', '#A5D6A7', '#81C784',  // 绿色系 (pending)
    '#FFE0B2', '#FFCC80', '#FFB74D'   // 橙色系 (in-progress)
  ];
  
  getSafeColor(courseName: string): string {
    let hash = 0;
    for (let i = 0; i < courseName.length; i++) {
        hash = ((hash << 5) + hash) + courseName.charCodeAt(i);
    }
    hash = Math.imul(hash, 16777619);
    
    const index = Math.abs(hash) % this.lightColors.length;
    return this.lightColors[index];
  }

  // 获取指定周次的7天日期列表 (YYYY-MM-DD格式)
  getWeekDates(weekIndex: number): string[] {
    // 学期开始日期是2026-01-12（周一）
    // 第1周: 01-12(周一) 到 01-18(周日)
    // 第2周: 01-19(周一) 到 01-25(周日)
    const semesterStart = new Date('2026-01-12');
    const weekStart = new Date(semesterStart);
    weekStart.setDate(semesterStart.getDate() + (weekIndex - 1) * 7);

    const dates: string[] = [];
    for (let i = 0; i < 7; i++) {
      const d = new Date(weekStart);
      d.setDate(weekStart.getDate() + i);
      const year = d.getFullYear();
      const month = (d.getMonth() + 1).toString().padStart(2, '0');
      const day = d.getDate().toString().padStart(2, '0');
      dates.push(`${year}-${month}-${day}`);
    }

    return dates;
  }

  // 计算日期对应的星期几 (1-7)
  getDateDayOfWeek(dateStr: string): number {
    const date = new Date(dateStr);
    const day = date.getDay();
    return day === 0 ? 7 : day;
  }

  // 获取学习任务（只匹配开始时间所在时段）
  getTaskInfo(day: number, rowIndex: number): TaskSlotInfo | null {
    const rowStart = this.rows[rowIndex].start;
    const rowEnd = this.rows[rowIndex].end;

    // 只匹配任务开始时间落在该时段内
    const task = this.studyTasks.find(t => {
      const taskDay = this.getDateDayOfWeek(t.scheduledDate);
      if (taskDay !== day) return false;
      // 开始时间在该行时段内
      return t.startTime >= rowStart && t.startTime < rowEnd;
    });

    if (task) {
      const info = new TaskSlotInfo();
      info.task = task;
      info.isStart = true; // 任务只显示在开始时间所在行
      return info;
    }

    return null;
  }

  // 计算任务在格子内的垂直位置（按时间比例）
  getTaskOffset(task: StudyTask, rowStart: string): number {
    // 将时间转为分钟
    const parseTime = (t: string): number => {
      const parts = t.split(':');
      return parseInt(parts[0]) * 60 + parseInt(parts[1]);
    };

    const taskStartMin = parseTime(task.startTime);
    const rowStartMin = parseTime(rowStart);

    // 每格50像素高度，计算偏移位置
    const diffMinutes = taskStartMin - rowStartMin;
    // 假设每格约50分钟，计算比例
    const offsetRatio = diffMinutes / 50;
    return Math.max(0, Math.min(30, offsetRatio * 50)); // 限制在0-30范围
  }

  // 计算任务在整个课表中的绝对位置
  getTaskAbsolutePosition(task: StudyTask): TaskPosition {
    const taskDay = this.getDateDayOfWeek(task.scheduledDate);
    const result = new TaskPosition();

    // 找到任务所在的行
    let rowIndex = -1;
    for (let i = 0; i < this.rows.length; i++) {
      const rowStart = this.rows[i].start;
      const rowEnd = this.rows[i].end;
      if (task.startTime >= rowStart && task.startTime < rowEnd) {
        rowIndex = i;
        break;
      }
    }

    if (rowIndex === -1) return result;

    // 计算x位置：左侧时间列56像素 + (day-1) * 每列宽度
    // 每列宽度需要动态计算，假设屏幕宽度约360，7列均分: (360-56)/7 ≈ 43
    const colWidth = 43; // 近似值
    result.x = 56 + (taskDay - 1) * colWidth;

    // 计算y位置：头部高度30 + rowIndex * 50 + 格子内偏移
    const headerHeight = 30;
    const rowHeight = 50;
    const inCellOffset = this.getTaskOffset(task, this.rows[rowIndex].start);
    result.y = headerHeight + rowIndex * rowHeight + inCellOffset;
    result.rowIndex = rowIndex;

    return result;
  }

  // 根据拖拽距离计算新的开始时间
  calculateNewTimeFromDrag(originalTime: string, dragDeltaY: number): string {
    const parseTime = (t: string): number => {
      const parts = t.split(':');
      return parseInt(parts[0]) * 60 + parseInt(parts[1]);
    };

    const formatTime = (minutes: number): string => {
      const h = Math.floor(minutes / 60);
      const m = minutes % 60;
      return `${h.toString().padStart(2, '0')}:${m.toString().padStart(2, '0')}`;
    };

    // 计算时间变化（每50像素 ≈ 50分钟，按5分钟取整）
    const deltaMinutes = Math.round(dragDeltaY / 50 * 50 / 5) * 5;
    const originalMinutes = parseTime(originalTime);
    let newMinutes = originalMinutes + deltaMinutes;

    // 限制时间范围 (6:00 - 22:00)
    newMinutes = Math.max(6 * 60, Math.min(22 * 60, newMinutes));

    return formatTime(newMinutes);
  }

  // 处理拖拽结束（只支持上下拖动改变时间）
  async handleDragEnd(task: StudyTask, totalOffsetY: number, totalOffsetX: number) {
    if (Math.abs(totalOffsetY) < 10) {
      // 偏移太小，视为点击而非拖拽
      this.isDragging = false;
      this.draggingTask = null;
      this.dragOffsetY = 0;
      this.dragOffsetX = 0;
      return;
    }

    const newStartTime = this.calculateNewTimeFromDrag(task.startTime, totalOffsetY);

    if (newStartTime === task.startTime) {
      // 时间没变
      this.isDragging = false;
      this.draggingTask = null;
      this.dragOffsetY = 0;
      this.dragOffsetX = 0;
      return;
    }

    Logger.info(`Dragging task ${task.title}: ${task.startTime} -> ${newStartTime}`);

    try {
      const response = await StudyTaskService.updateStudyTask(this.context!, task.taskId, {
        title: task.title,
        scheduledDate: task.scheduledDate,
        startTime: newStartTime,
        endTime: newStartTime,
        assignmentId: '',
        estimatedHours: 0,
        description: ''
      });

      if (response.code === 200) {
        Logger.info('Task time updated via drag');
        this.loadSchedule();
      } else {
        Logger.error('Failed to update task:', response.message);
      }
    } catch (err) {
      Logger.error('Drag update failed:', JSON.stringify(err));
    } finally {
      this.isDragging = false;
      this.draggingTask = null;
      this.dragOffsetY = 0;
      this.dragOffsetX = 0;
    }
  }

  getSlotInfo(day: number, rowIndex: number): SlotInfo | null {
    const rowStart = this.rows[rowIndex].start;
    const rowEnd = this.rows[rowIndex].end;
    
    // 查找该天是否有课程
    const daily = this.weekData.schedule.find(d => d.dayOfWeek === day);
    if (!daily) return null;

    // 逻辑修正：寻找是否有课程覆盖当前行
    // 并且：如果是该课程覆盖的第一个行，则标记为 isStart (显示文字)
    const course = daily.timeSlots.find(slot => {
       // 检查课程时间段是否包含当前行时间段 (哪怕一部分)
       // 简单判断: !(courseEnd <= rowStart || courseStart >= rowEnd)
       return slot.endTime > rowStart && slot.startTime < rowEnd;
    });

    if (course) {
       const info = new SlotInfo();
       info.course = course;
       
       // 判断是否是该课程的“首行”
       // 方法：在 rows 数组中找到第一个与该课程重叠的行
       // 如果 rowIndex 就是那个首行的 index，则是 isStart
       const firstOverlapRowIndex = this.rows.findIndex(r => 
           course.endTime > r.start && course.startTime < r.end
       );
       
       if (firstOverlapRowIndex === rowIndex) {
         info.isStart = true;
       } else {
         info.isStart = false; 
       }
       return info;
    }

    return null;
  }

  build() {
    Stack() {
      Column() {
        // 顶部导航栏: 学期选择 + title + 添加
        Row() {
          Select(this.semesterOptions)
            .value(this.currentSemester)
            .selected(0) // 默认选中第一个或匹配逻辑
            .onSelect((index, value) => {
               this.currentSemester = value; 
               this.loadSchedule();
            })
            .font({ size: 14 })
            .height(32)
            .backgroundColor('#f0f0f0')
            .borderRadius(8)
            .margin({ right: 10 })
  
          Button({ type: ButtonType.Circle, stateEffect: true }) {
             Text('<').fontColor(Color.Black).fontSize(20)
          }
          .width(32).height(32).backgroundColor('#f0f0f0')
          .onClick(() => { if (this.currentWeekIndex > 1) { this.currentWeekIndex--; this.loadSchedule(); } })
          
          Text(`第 ${this.currentWeekIndex} 周`).fontSize(18).fontWeight(FontWeight.Bold).layoutWeight(1).textAlign(TextAlign.Center)
          
          Button({ type: ButtonType.Circle, stateEffect: true }) {
             Text('>').fontColor(Color.Black).fontSize(20)
          }
          .width(32).height(32).backgroundColor('#f0f0f0')
          .onClick(() => { this.currentWeekIndex++; this.loadSchedule(); })

          // 导入按钮
          Button({ type: ButtonType.Circle, stateEffect: true }) {
             Text('📥').fontSize(16)
          }
          .width(32).height(32).margin({ left: 10 }).backgroundColor('#f0f0f0')
          .onClick(() => router.pushUrl({ url: 'pages/CourseImportPage' }))
          
          Button({ type: ButtonType.Circle, stateEffect: true }) {
             Text('+').fontColor(Color.White).fontSize(24).margin({ bottom: 2 })
          }
          .width(32).height(32).margin({ left: 6 }).backgroundColor('#007DFF')
          .onClick(() => router.pushUrl({ url: 'pages/CourseAddPage' }))
        }
        .padding(10).backgroundColor(Color.White)
        .width('100%')
  
        Row() {
          Text('').width(56)
          ForEach(this.weekDays, (day: string) => {
            Text(day).layoutWeight(1).textAlign(TextAlign.Center).fontSize(12).fontColor(Color.Gray)
          })
        }.height(30).backgroundColor('#fafafa')
  
        // 滚动区域
        Scroll() {
          // 使用Stack包裹课表和任务，确保任务随课表滚动并在最上层
          Stack({ alignContent: Alignment.TopStart }) {
            // 底层：课表内容（背景+课程）
            Column() {
              ForEach(this.rows, (row: ScheduleRow, rowIndex: number) => {
                Row() {
                  Column() {
                    Text(row.label)
                        .fontSize(12)
                        .fontWeight(FontWeight.Bold)
                        .fontColor(row.type === 1 ? Color.Gray : Color.Black)
                    
                    if (row.label !== '晚饭' && row.label !== '晚休' && row.label !== '午休') {
                        Text(`${row.start}-${row.end}`)
                            .fontSize(9)
                            .fontColor(Color.Gray)
                            .margin({ top: 2 })
                    }
                  }
                  .width(56).height(50).justifyContent(FlexAlign.Center).backgroundColor('#fafafa')
                  .border({ width: { bottom: 1 }, color: '#f0f0f0' })
    
                  ForEach([1,2,3,4,5,6,7], (day: number) => {
                    // 内层Stack用于格子背景和课程
                    Stack() {
                      if (row.type === 1) {
                         Rect().width('100%').height('100%').fill('#f5f5f5')
                      } else {
                         Rect().width('100%').height('100%').fill(Color.White).stroke('#f0f0f0').strokeWidth(0.5)
                      }
    
                      // 显示课程
                      if (this.getSlotInfo(day, rowIndex)) {
                        Column() {
                          if (this.getSlotInfo(day, rowIndex)?.isStart) {
                            Text(this.getSlotInfo(day, rowIndex)?.course.course.courseName)
                              .fontSize(10).fontColor(Color.Black).fontWeight(FontWeight.Bold)
                              .maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis })
                            Text(this.getSlotInfo(day, rowIndex)?.course.course.location)
                              .fontSize(9).fontColor(Color.Black)
                          }
                        }
                        .width('100%').height('100%')
                        .backgroundColor(this.getSafeColor(this.getSlotInfo(day, rowIndex)?.course.course.courseName || ''))
                        .padding(2)
                        .onClick(async () => {
                            const info = this.getSlotInfo(day, rowIndex);
                            if (info && info.course && info.course.course) {
                                this.isLoading = true;
                                try {
                                    const res = await CourseService.getCourseById(this.context!, info.course.course.courseId, this.currentSemester);
                                    if (res.code === 200 && res.data) {
                                        this.showCourseDetail(res.data, info.course);
                                    } else {
                                        Logger.error('Get details failed:', res.message);
                                    }
                                } catch (e) {
                                    Logger.error('Get details failed', JSON.stringify(e));
                                } finally {
                                    this.isLoading = false;
                                }
                            }
                        })
                      }
                    }
                    .layoutWeight(1)
                    .height(50)
                    // 所有格子长按事件
                    .gesture(
                      LongPressGesture({ repeat: false })
                        .onAction(() => {
                          // 无任务时可创建（课程上也可以创建任务）
                          if (!this.getTaskInfo(day, rowIndex)) {
                            this.openNewTaskDialog(day, row.start);
                          }
                        })
                    )
                  })
                }
              })
            }
            .width('100%') // Column宽度充满

            // 顶层：统一渲染所有任务，使用绝对定位，随Stack一起滚动
            ForEach(this.studyTasks, (task: StudyTask) => {
              Row() {
                Circle()
                  .width(10)
                  .height(10)
                  .fill(task.status === 'completed' ? '#28a745' : Color.Transparent)
                  .stroke('#28a745')
                  .strokeWidth(2)
                  .margin({ left: 1, right: 2 })
                Text(task.title)
                  .fontSize(8)
                  .fontColor('#333')
                  .fontWeight(FontWeight.Medium)
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .layoutWeight(1)
              }
              .width(40)
              .height(16)
              .backgroundColor(this.isDragging && this.draggingTask?.taskId === task.taskId ? '#e3f2fd' : Color.White)
              .border({ width: 1.5, color: this.isDragging && this.draggingTask?.taskId === task.taskId ? '#007DFF' : '#333' })
              .borderRadius(3)
              .padding({ left: 1, right: 2 })
              .alignItems(VerticalAlign.Center)
              .position({
                x: this.getTaskAbsolutePosition(task).x,
                y: this.getTaskAbsolutePosition(task).y + (this.draggingTask?.taskId === task.taskId ? this.dragOffsetY : 0)
              })
              .gesture(
                GestureGroup(GestureMode.Parallel,
                  PanGesture({ direction: PanDirection.Vertical })
                    .onActionStart(() => {
                      this.isDragging = true;
                      this.draggingTask = task;
                      this.dragOffsetY = 0;
                    })
                    .onActionUpdate((event: GestureEvent) => {
                      if (this.isDragging && event) {
                        this.dragOffsetY = event.offsetY;
                      }
                    })
                    .onActionEnd(() => {
                      if (this.draggingTask) {
                        this.handleDragEnd(this.draggingTask, this.dragOffsetY, 0);
                      }
                    }),
                  TapGesture()
                    .onAction(() => {
                      if (!this.isDragging) {
                        this.openEditTaskDialog(task);
                      }
                    })
                )
              )
            })
          }
          .width('100%') // Stack宽度充满Scroll
        }
        .layoutWeight(1) // Scroll高度充满剩余空间
        .align(Alignment.TopStart) // 内容顶部对齐
        .width('100%').height('100%').backgroundColor(Color.White)
      }

      
      if (this.isLoading) {
          // Loading Mask
          Stack() {
              LoadingProgress().color(Color.Blue).width(50).height(50)
          }
          .width('100%').height('100%')
          .backgroundColor('rgba(255,255,255,0.5)')
          .position({ x: 0, y: 0 })
      }
    }
  }
}
