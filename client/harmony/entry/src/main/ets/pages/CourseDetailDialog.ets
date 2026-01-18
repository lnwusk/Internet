import { CourseDetail, TimeSlot, CourseScheduleItem } from '../common/models/ApiModels';
import router from '@ohos.router';
import { CourseService } from '../services/CourseService';
import { Logger } from '../common/utils/Logger';
import common from '@ohos.app.ability.common';

@CustomDialog
export struct CourseDetailDialog {
  controller: CustomDialogController;
  course: CourseDetail = new CourseDetail();
  currentSlot: TimeSlot = new TimeSlot();
  onDeleteSuccess: () => void = () => {};

  private context = getContext(this) as common.UIAbilityContext;

  @State showDeleteConfirm: boolean = false;
  @State isDeleting: boolean = false;

  async confirmDelete() {
    this.isDeleting = true;
    try {
      const res = await CourseService.deleteCourse(this.context, this.course.courseId);
      Logger.info('Delete result:', JSON.stringify(res));
      if (res.code === 200) {
        Logger.info('Course deleted successfully');
        this.controller.close();
        AppStorage.setOrCreate('needRefreshSchedule', Date.now());
      }
    } catch (err) {
      Logger.error('Delete course failed', JSON.stringify(err));
    } finally {
      this.isDeleting = false;
      this.showDeleteConfirm = false;
    }
  }

  handleEdit() {
    // 先关闭弹窗
    this.controller.close();
    // 延迟导航确保弹窗完全关闭
    setTimeout(() => {
      router.pushUrl({
        url: 'pages/CourseAddPage',
        params: {
          isEditMode: true,
          courseDetail: JSON.stringify(this.course)
        }
      });
    }, 100);
  }

  build() {
    Column() {
      // 标题栏
      Row() {
        Text(this.course.courseName)
          .fontSize(20).fontWeight(FontWeight.Bold).layoutWeight(1)
        Text('✕')
          .fontSize(20).onClick(() => this.controller.close())
      }.width('100%').margin({ bottom: 20 })

      // 信息列表
      Column({ space: 15 }) {
        Row() {
          Text('教师：').fontWeight(FontWeight.Bold).width(70)
          Text(this.course.teacher || '未设置').layoutWeight(1)
        }
        
        Row() {
          Text('学期：').fontWeight(FontWeight.Bold).width(70)
          Text(this.course.semester || '2025-2026-1').layoutWeight(1)
        }
        
        if (this.course.courseCode) {
            Row() {
              Text('代码：').fontWeight(FontWeight.Bold).width(70)
              Text(this.course.courseCode).layoutWeight(1)
            }
        }
        
        if (this.course.credits) {
            Row() {
              Text('学分：').fontWeight(FontWeight.Bold).width(70)
              Text(this.course.credits.toString()).layoutWeight(1)
            }
        }

        Row() {
          Text('安排：').fontWeight(FontWeight.Bold).width(70)
          Column({ space: 8 }) {
            ForEach(this.course.schedule, (item: CourseScheduleItem) => {
               Column({ space: 2 }) {
                   Text(`周${['一','二','三','四','五','六','日'][item.dayOfWeek-1]} ${item.startTime}-${item.endTime}`)
                     .fontSize(14).fontColor(Color.Black)
                   Text(`${item.location} (${item.weeks.length}周)`)
                     .fontSize(12).fontColor(Color.Gray)
               }.alignItems(HorizontalAlign.Start).width('100%')
            })
          }.alignItems(HorizontalAlign.Start).layoutWeight(1)
        }
      }.width('100%').alignItems(HorizontalAlign.Start)

      // 操作按钮
      Row({ space: 15 }) {
        Button('删除课程')
          .backgroundColor('#FFEBEE').fontColor(Color.Red)
          .layoutWeight(1)
          .onClick(() => this.showDeleteConfirm = true)
          .enabled(!this.isDeleting)
        
        Button('编辑课程')
          .backgroundColor('#E3F2FD').fontColor('#007DFF')
          .layoutWeight(1)
          .onClick(() => this.handleEdit())
          .enabled(!this.isDeleting)
      }.margin({ top: 30 }).width('100%')

      if (this.showDeleteConfirm) {
        Stack() {
          Column()
            .width('100%')
            .height('100%')
            .backgroundColor('rgba(0, 0, 0, 0.3)')
            .onClick(() => this.showDeleteConfirm = false)

          Column({ space: 20 }) {
            Text('删除课程')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)

            Text(`确定要删除 "${this.course.courseName}" 吗？此操作不可恢复。`)
              .fontSize(14)
              .fontColor(Color.Gray)

            Row({ space: 15 }) {
              Button('取消')
                .layoutWeight(1)
                .height(40)
                .backgroundColor('#f0f0f0')
                .fontColor(Color.Black)
                .onClick(() => this.showDeleteConfirm = false)
                .enabled(!this.isDeleting)

              Button(this.isDeleting ? '删除中...' : '删除')
                .layoutWeight(1)
                .height(40)
                .backgroundColor(Color.Red)
                .fontColor(Color.White)
                .onClick(() => this.confirmDelete())
                .enabled(!this.isDeleting)
            }
            .width('100%')
          }
          .width('85%')
          .padding(20)
          .backgroundColor(Color.White)
          .borderRadius(12)
        }
        .width('100%')
        .height('100%')
        .position({ x: 0, y: 0 })
        .zIndex(1000)
      }
    }
    .padding(24)
    .backgroundColor(Color.White)
    .borderRadius(16)
    .width('90%')
  }
}
