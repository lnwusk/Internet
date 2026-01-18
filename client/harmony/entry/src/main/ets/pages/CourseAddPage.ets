import router from '@ohos.router';
import { CourseService } from '../services/CourseService';
import { AddCourseRequest, CourseScheduleItem, CourseDetail, ApiResponse } from '../common/models/ApiModels';
import { Logger } from '../common/utils/Logger';
import common from '@ohos.app.ability.common';

@Entry
@Component
struct CourseAddPage {
  @State courseName: string = '';
  @State teacher: string = '';
  @State courseCode: string = '';
  @State credits: number = 0;
  @State semester: string = '2025-2026-1';
  @State currentLocation: string = ''; 

  @State currentDayIndex: number = 0;
  @State currentSelectedWeeks: boolean[] = new Array(16).fill(true);
  @State weekMode: number = 1;
  @State startTimeIndex: number = 0;
  @State duration: number = 2;
  @State endTimeStr: string = '09:50';
  @State scheduleList: CourseScheduleItem[] = [];

  private weekDayLabels: string[] = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
  private semesterOptions: SelectOption[] = [
    { value: '2025-2026-1' },
    { value: '2024-2025-2' },
    { value: '2024-2025-1' },
    { value: '2023-2024-2' },
    { value: '2023-2024-1' }
  ];
  private timeStartOptions: SelectOption[] = [
    { value: '08:00' }, { value: '09:00' }, { value: '10:10' }, 
    { value: '14:00' }, { value: '15:00' }, { value: '16:10' }, 
    { value: '18:30' }, { value: '19:30' }
  ];
  private durationOptions: SelectOption[] = [{ value: '2节' }, { value: '3节' }];

  @State isLoading: boolean = false;
  @State successMessage: string = '';
  @State errorMessage: string = '';
  @State showSuccessDialog: boolean = false;
  @State isEditMode: boolean = false;
  @State editingCourseId: string = '';

  private context: common.UIAbilityContext | null = null;

  aboutToAppear() {
    this.context = getContext(this) as common.UIAbilityContext;
    this.calculateEndTime();
    
    const params = router.getParams() as Record<string, Object>;
    if (params && params['isEditMode'] && params['courseDetail']) {
      this.isEditMode = true;
      try {
        const detailStr = params['courseDetail'] as string;
        const detail = JSON.parse(detailStr) as CourseDetail;
        
        this.editingCourseId = detail.courseId;
        this.courseName = detail.courseName || '';
        this.teacher = detail.teacher || '';
        this.courseCode = detail.courseCode || '';
        this.credits = detail.credits || 0;
        this.semester = detail.semester || '2025-2026-1';
        
        if (detail.schedule && detail.schedule.length > 0) {
            this.scheduleList = JSON.parse(JSON.stringify(detail.schedule)) as CourseScheduleItem[];
        }
      } catch (e) {
        Logger.error('Failed to parse course detail for edit', JSON.stringify(e));
      }
    }
  }

  setWeekMode(mode: number) {
    this.weekMode = mode;
    if (mode === 1) {
      this.currentSelectedWeeks = new Array(16).fill(true);
    } else if (mode === 2) {
      this.currentSelectedWeeks = this.currentSelectedWeeks.map((_, i) => (i + 1) % 2 !== 0);
    } else if (mode === 3) {
      this.currentSelectedWeeks = this.currentSelectedWeeks.map((_, i) => (i + 1) % 2 === 0);
    }
  }

  toggleWeek(index: number) {
    this.currentSelectedWeeks[index] = !this.currentSelectedWeeks[index];
    this.currentSelectedWeeks = [...this.currentSelectedWeeks];
    this.weekMode = 0;
  }

  calculateEndTime() {
    const startStr = this.timeStartOptions[this.startTimeIndex].value as string;
    let endStr = '';
    
    if (startStr === '08:00') { this.duration = 2; endStr = '09:50'; }
    else if (startStr === '09:00') { this.duration = 3; endStr = '12:00'; }
    else if (startStr === '10:10') { this.duration = 2; endStr = '12:00'; }
    else if (startStr === '14:00') { this.duration = 2; endStr = '15:50'; }
    else if (startStr === '15:00') { this.duration = 3; endStr = '18:00'; }
    else if (startStr === '16:10') { this.duration = 2; endStr = '18:00'; }
    else if (startStr === '19:30') { this.duration = 2; endStr = '21:20'; }
    else if (startStr === '18:30') {
      if (this.duration === 2) endStr = '20:20';
      else endStr = '21:20';
    }
    this.endTimeStr = endStr;
  }

  addScheduleItem() {
    const weeks: number[] = [];
    this.currentSelectedWeeks.forEach((isSel, idx) => {
      if (isSel) weeks.push(idx + 1);
    });
    if (weeks.length === 0) {
      this.errorMessage = '请选择上课周次';
      setTimeout(() => { this.errorMessage = ''; }, 3000);
      return;
    }
    
    // 校验地点
    if (this.currentLocation.trim() === '') {
      this.errorMessage = '请输入该时间段的上课地点';
      setTimeout(() => { this.errorMessage = ''; }, 3000);
      return;
    }

    const newItem: CourseScheduleItem = {
      dayOfWeek: this.currentDayIndex + 1,
      startTime: this.timeStartOptions[this.startTimeIndex].value as string,
      endTime: this.endTimeStr,
      location: this.currentLocation,
      weeks: weeks
    };

    this.scheduleList.push(newItem);
    
    this.successMessage = '已添加该时间段，可继续添加或点击保存';
    this.errorMessage = '';
    
    setTimeout(() => {
      this.successMessage = '';
    }, 3000);
  }

  // Edit Schedule Item Logic
  editScheduleItem(index: number) {
    const item = this.scheduleList[index];
    this.currentDayIndex = item.dayOfWeek - 1;
    this.currentLocation = item.location;
    
    const stIdx = this.timeStartOptions.findIndex(o => o.value === item.startTime);
    if (stIdx >= 0) {
        this.startTimeIndex = stIdx;
    }
    
    this.endTimeStr = item.endTime;
    
    const flags: boolean[] = new Array(16).fill(false);
    item.weeks.forEach(w => {
        if (w >= 1 && w <= 16) flags[w-1] = true;
    });
    this.currentSelectedWeeks = flags;
    
    this.scheduleList.splice(index, 1);
    
    this.successMessage = '已加载该时段信息至上方编辑区';
    setTimeout(() => {
      this.successMessage = '';
    }, 3000);
  }

  removeScheduleItem(index: number) {
    this.scheduleList.splice(index, 1);
  }

  getWeeksDescription(weeks: number[]): string {
    if (weeks.length === 16) return '1-16周';
    return `共${weeks.length}周`;
  }
  resetForm() {
    this.courseName = '';
    this.teacher = '';
    this.courseCode = '';
    this.credits = 0;
    this.currentLocation = '';
    this.scheduleList = [];
    this.currentSelectedWeeks = new Array(16).fill(true);
    this.weekMode = 1;
    this.currentDayIndex = 0;
    this.startTimeIndex = 0;
    this.calculateEndTime();
    this.successMessage = '';
    this.errorMessage = '';
  }

  async handleSave() {
    if (!this.context) return;
    
    if (this.courseName === '') {
      this.errorMessage = '请输入课程名称';
      setTimeout(() => { this.errorMessage = ''; }, 3000);
      return;
    }
    if (this.scheduleList.length === 0) {
      this.errorMessage = '请至少配置一个上课时间段';
      setTimeout(() => { this.errorMessage = ''; }, 3000);
      return;
    }

    this.isLoading = true;
    this.errorMessage = '';
    this.successMessage = '';
    
    try {
      const request: AddCourseRequest = {
        courseName: this.courseName,
        teacher: this.teacher,
        courseCode: this.courseCode,
        credits: this.credits > 0 ? this.credits : undefined,
        semester: this.semester,
        schedule: this.scheduleList
      };

      let result: ApiResponse<CourseDetail>;
      if (this.isEditMode) {
         Logger.info('Updating course:', this.editingCourseId);
         result = await CourseService.updateCourse(this.context, this.editingCourseId, request);
      } else {
         Logger.info('Submitting new course');
         result = await CourseService.addCourse(this.context, request);
      }
      
      Logger.info('Save result:', JSON.stringify(result));
      
      if (result.code === 200) {
        Logger.info('Save successful');
        this.isLoading = false;
        // 无论新建还是编辑，都显示成功弹窗
        this.showSuccessDialog = true;
      } else {
        this.errorMessage = `${this.isEditMode ? '更新' : '添加'}失败: ${result.message}`;
        setTimeout(() => { this.errorMessage = ''; }, 3000);
        this.isLoading = false;
      }
    } catch (err) {
      Logger.error('Save course failed:', JSON.stringify(err));
      this.errorMessage = '网络请求失败，请检查网络';
      setTimeout(() => { this.errorMessage = ''; }, 3000);
      this.isLoading = false;
    }
  }

  handleContinueAdding() {
    Logger.info('User chose to continue adding');
    this.showSuccessDialog = false;
    this.resetForm();
  }

  handleReturnToSchedule() {
    Logger.info('User chose to return to schedule');
    this.showSuccessDialog = false;
    router.back();
    setTimeout(() => {
      AppStorage.setOrCreate('needRefreshSchedule', Date.now());
    }, 300);
  }

  build() {
    Column() {
      // 导航
      Row() {
        Text(this.isEditMode ? '编辑课程' : '添加课程').fontSize(20).fontWeight(FontWeight.Bold).layoutWeight(1).textAlign(TextAlign.Center)
        Text('取消').fontSize(16).fontColor(Color.Gray).onClick(() => {
          router.back();
          setTimeout(() => {
            AppStorage.setOrCreate('needRefreshSchedule', Date.now());
          }, 300);
        })
      }
      .width('100%').height(56).padding({ left: 16, right: 16 }).backgroundColor('#f5f5f5')

      Scroll() {
        Column({ space: 20 }) {
          if (this.successMessage !== '') {
            Text(this.successMessage)
              .fontSize(14)
              .fontColor('#28a745')
              .width('100%')
              .textAlign(TextAlign.Center)
              .padding(12)
              .backgroundColor('#d4edda')
              .borderRadius(8)
          }
          
          if (this.errorMessage !== '') {
            Text(this.errorMessage)
              .fontSize(14)
              .fontColor('#dc3545')
              .width('100%')
              .textAlign(TextAlign.Center)
              .padding(12)
              .backgroundColor('#f8d7da')
              .borderRadius(8)
          }

           Column({ space: 12 }) {
             TextInput({ placeholder: '课程名称 (必填)', text: this.courseName })
               .height(48).width('100%').onChange((val) => this.courseName = val)
             
             Row({ space: 10 }) {
                 TextInput({ placeholder: '课程代码', text: this.courseCode })
                   .height(48).layoutWeight(1).onChange((val) => this.courseCode = val)
                 TextInput({ placeholder: '学分', text: this.credits > 0 ? this.credits.toString() : '' })
                   .type(InputType.Number)
                   .height(48).width(80).onChange((val) => {
                       const num = parseFloat(val);
                       this.credits = isNaN(num) ? 0 : num;
                   })
             }

             TextInput({ placeholder: '授课教师', text: this.teacher })
               .height(48).width('100%').onChange((val) => this.teacher = val)
           }
           .padding(16).backgroundColor(Color.White).borderRadius(12).width('100%')

           Column({ space: 15 }) {
             Text('新增上课时间 & 地点').fontSize(14).fontColor('#007DFF').fontWeight(FontWeight.Bold)
             
             Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.SpaceBetween }) {
               ForEach(this.weekDayLabels, (day: string, index: number) => {
                 Text(day)
                   .width(36).height(36).textAlign(TextAlign.Center).borderRadius(18)
                   .backgroundColor(this.currentDayIndex === index ? '#007DFF' : '#f0f0f0')
                   .fontColor(this.currentDayIndex === index ? Color.White : Color.Black)
                   .onClick(() => this.currentDayIndex = index)
               })
             }

             Column({ space: 8 }) {
               Row({ space: 8 }) {
                 Text('周次').fontSize(14)
                 Blank()
                 Text('全选').fontSize(12).fontColor(this.weekMode === 1 ? '#007DFF' : Color.Gray).onClick(() => this.setWeekMode(1))
                 Text('单周').fontSize(12).fontColor(this.weekMode === 2 ? '#007DFF' : Color.Gray).onClick(() => this.setWeekMode(2))
                 Text('双周').fontSize(12).fontColor(this.weekMode === 3 ? '#007DFF' : Color.Gray).onClick(() => this.setWeekMode(3))
               }.width('100%')
               
               Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
                 ForEach(this.currentSelectedWeeks, (isSelected: boolean, index: number) => {
                   Text(`${index + 1}`)
                     .width((300 - 32) / 8).height(30).textAlign(TextAlign.Center).margin(2).borderRadius(4)
                     .backgroundColor(isSelected ? '#007DFF' : '#f0f0f0')
                     .fontColor(isSelected ? Color.White : Color.Black)
                     .fontSize(12)
                     .onClick(() => this.toggleWeek(index))
                 })
               }
             }

             // Time and Location Config
             Row({ space: 10 }) {
               Select(this.timeStartOptions)
                 .value(this.timeStartOptions[this.startTimeIndex].value as string)
                 .selected(this.startTimeIndex)
                 .onSelect((index) => { this.startTimeIndex = index; this.calculateEndTime(); })
                 .height(40).layoutWeight(1).backgroundColor('#f0f0f0').borderRadius(8)
               
               if (this.timeStartOptions[this.startTimeIndex].value === '18:30') {
                 Row() {
                    Select(this.durationOptions)
                     .value(this.duration === 2 ? '2节' : '3节')
                     .selected(this.duration === 2 ? 0 : 1)
                     .onSelect((index) => { this.duration = index === 0 ? 2 : 3; this.calculateEndTime(); })
                     .height(40).width(80).backgroundColor('#f0f0f0').borderRadius(8)
                 }
               }

               Text(this.endTimeStr).fontSize(16).fontWeight(FontWeight.Bold).fontColor('#007DFF').width(60).textAlign(TextAlign.Center)
             }
             
             // Location Input for specific slot
             TextInput({ placeholder: '上课地点 (必填，如: 仙II-101)', text: this.currentLocation })
                .height(40).width('100%').onChange((val) => this.currentLocation = val)

             Button('确认添加该时间段')
               .width('100%').height(40).backgroundColor('#E6F2FF').fontColor('#007DFF')
               .onClick(() => this.addScheduleItem())

           }
           .padding(16).backgroundColor(Color.White).borderRadius(12)
           .border({ width: 1, color: '#007DFF' }).width('100%')

           if (this.scheduleList.length > 0) {
             Column({ space: 10 }) {
               Text(`已添加 ${this.scheduleList.length} 个时间段`).fontSize(14).fontColor(Color.Gray).width('100%')
               
               ForEach(this.scheduleList, (item: CourseScheduleItem, index: number) => {
                 Row() {
                   Column({ space: 4 }) {
                     Text(`${this.weekDayLabels[item.dayOfWeek-1]} ${item.startTime}-${item.endTime}`)
                       .fontSize(16).fontWeight(FontWeight.Medium)
                     Text(`地点: ${item.location}`).fontSize(14).fontColor('#333')
                     Text(`周次: ${this.getWeeksDescription(item.weeks)}`).fontSize(12).fontColor(Color.Gray)
                   }.alignItems(HorizontalAlign.Start).layoutWeight(1)
                   
                   Text('删除').fontColor(Color.Red).fontSize(14)
                     .onClick(() => this.removeScheduleItem(index))
                 }
                 .padding(12).backgroundColor(Color.White).borderRadius(8).width('100%')
               })
             }
             .width('100%')
           }

          Button(this.isLoading ? '正在保存...' : '完成并保存课程')
            .width('100%').height(50).backgroundColor('#007DFF').margin({ bottom: 30 })
            .onClick(async () => { await this.handleSave(); })
            .enabled(!this.isLoading)
        }
        .padding(16)
      }
      .backgroundColor('#f2f3f5')
      .layoutWeight(1)

      if (this.showSuccessDialog) {
        Stack() {
          Column()
            .width('100%')
            .height('100%')
            .backgroundColor('rgba(0, 0, 0, 0.5)')

          Column({ space: 20 }) {
            Text(this.isEditMode ? '更新成功' : '添加成功')
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor(Color.Black)

            Text(this.isEditMode ? '课程已成功更新！' : '课程已成功添加！')
              .fontSize(16)
              .fontColor(Color.Gray)

            Row({ space: 15 }) {
              if (!this.isEditMode) {
                Button('继续添加')
                  .layoutWeight(1)
                  .height(45)
                  .backgroundColor('#E6F2FF')
                  .fontColor('#007DFF')
                  .onClick(() => this.handleContinueAdding())
              }

              Button('返回课表')
                .layoutWeight(1)
                .height(45)
                .backgroundColor('#007DFF')
                .fontColor(Color.White)
                .onClick(() => this.handleReturnToSchedule())
            }
            .width('100%')
          }
          .width('80%')
          .padding(24)
          .backgroundColor(Color.White)
          .borderRadius(12)
        }
        .width('100%')
        .height('100%')
        .position({ x: 0, y: 0 })
        .zIndex(999)
      }
    }
    .width('100%').height('100%')
  }
}
