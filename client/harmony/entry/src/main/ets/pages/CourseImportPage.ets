import common from '@ohos.app.ability.common';
import router from '@ohos.router';
import { picker } from '@kit.CoreFileKit';
import { fileIo } from '@kit.CoreFileKit';
import { Logger } from '../common/utils/Logger';
import { SyncService } from '../services/SyncService';
import { ImportedCourse, CourseScheduleItem } from '../common/models/ApiModels';

@Entry
@Component
export struct CourseImportPage {
  @State isLoading: boolean = false;
  @State loadingText: string = '';
  @State selectedFileName: string = '';
  @State selectedFileUri: string = '';
  @State parsedCourses: ImportedCourse[] = [];
  @State totalCourses: number = 0;
  @State totalSchedules: number = 0;
  @State showPreview: boolean = false;
  @State errorMessage: string = '';
  @State currentSemester: string = '2025-2026-1';

  private context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
  private weekDays: string[] = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];

  // 选择文件
  async selectFile() {
    try {
      const options = new picker.DocumentSelectOptions();
      options.maxSelectNumber = 1;
      options.fileSuffixFilters = ['.xlsx', '.xls'];

      const documentPicker = new picker.DocumentViewPicker(this.context);
      const result = await documentPicker.select(options);

      if (result && result.length > 0) {
        const uri = result[0];
        const fileName = uri.split('/').pop() || 'timetable.xlsx';

        this.selectedFileUri = uri;
        this.selectedFileName = fileName;
        this.errorMessage = '';

        Logger.info(`Selected file: ${fileName}, URI: ${uri}`);
      }
    } catch (err) {
      Logger.error('File selection failed:', JSON.stringify(err));
      this.errorMessage = '文件选择失败，请重试';
    }
  }

  // 上传并解析文件
  async uploadFile() {
    if (!this.selectedFileUri) {
      this.errorMessage = '请先选择文件';
      return;
    }

    this.isLoading = true;
    this.loadingText = '正在解析课表...';
    this.errorMessage = '';

    try {
      // 将picker返回的URI复制到沙箱，获取可用于上传的路径
      const sandboxPath = `${this.context.cacheDir}/temp_upload.xlsx`;

      // 打开源文件读取
      const srcFile = await fileIo.open(this.selectedFileUri, fileIo.OpenMode.READ_ONLY);
      const destFile = await fileIo.open(sandboxPath, fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE);

      // 读取并写入
      const buffer = new ArrayBuffer(10 * 1024 * 1024);  // 10MB buffer
      const readLen = await fileIo.read(srcFile.fd, buffer);
      await fileIo.write(destFile.fd, buffer, { length: readLen });

      await fileIo.close(srcFile);
      await fileIo.close(destFile);

      // 调用上传接口
      const response = await SyncService.uploadCourseFile(
        this.context,
        sandboxPath,
        this.selectedFileName,
        this.currentSemester
      );

      if (response.code === 200 && response.data) {
        this.parsedCourses = response.data.courses;
        this.totalCourses = response.data.summary.totalCourses;
        this.totalSchedules = response.data.summary.totalSchedules;
        this.showPreview = true;
        Logger.info(`Parsed ${this.totalCourses} courses`);
      } else {
        this.errorMessage = response.message || '解析失败';
      }
    } catch (err) {
      Logger.error('Upload failed:', JSON.stringify(err));
      this.errorMessage = '上传失败，请检查网络连接';
    } finally {
      this.isLoading = false;
      this.loadingText = '';
    }
  }

  // 确认导入
  async confirmImport() {
    if (this.parsedCourses.length === 0) {
      return;
    }

    this.isLoading = true;
    this.loadingText = '正在保存课程...';

    try {
      const response = await SyncService.confirmCourses(
        this.context,
        this.parsedCourses,
        this.currentSemester
      );

      if (response.code === 200 && response.data) {
        Logger.info(`Saved ${response.data.savedCount} courses`);
        // 返回课表页面
        router.back();
      } else {
        this.errorMessage = response.message || '保存失败';
      }
    } catch (err) {
      Logger.error('Confirm failed:', JSON.stringify(err));
      this.errorMessage = '保存失败，请重试';
    } finally {
      this.isLoading = false;
      this.loadingText = '';
    }
  }

  // 格式化时间显示
  formatSchedule(schedule: CourseScheduleItem[]): string {
    return schedule.map(s => {
      const day = this.weekDays[s.dayOfWeek - 1] || '';
      return `${day} ${s.startTime}-${s.endTime}`;
    }).join(', ');
  }

  // 格式化周次显示
  formatWeeks(weeks: number[]): string {
    if (!weeks || weeks.length === 0) return '';
    if (weeks.length > 2 && weeks[weeks.length - 1] - weeks[0] === weeks.length - 1) {
      return `${weeks[0]}-${weeks[weeks.length - 1]}周`;
    }
    return `第${weeks.slice(0, 3).join(',')}${weeks.length > 3 ? '...' : ''}周`;
  }

  build() {
    Stack() {
      Column() {
        // 顶部导航
        Row() {
          Button({ type: ButtonType.Circle }) {
            Text('←').fontSize(20).fontColor('#333')
          }
          .width(36).height(36).backgroundColor('#f5f5f5')
          .onClick(() => router.back())

          Text('导入课表')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .layoutWeight(1)
            .textAlign(TextAlign.Center)

          Blank().width(36)
        }
        .padding(12)
        .width('100%')

        // 主要内容区
        if (!this.showPreview) {
          // 文件选择视图
          Column() {
            Image($r('app.media.startIcon'))
              .width(80)
              .height(80)
              .margin({ top: 60, bottom: 20 })

            Text('导入xlsx课表文件')
              .fontSize(18)
              .fontColor('#333')
              .margin({ bottom: 8 })

            Text('支持从教务系统导出的xlsx或xls格式课表')
              .fontSize(14)
              .fontColor('#999')
              .margin({ bottom: 30 })

            // 选择文件按钮
            Button('选择文件')
              .width('80%')
              .height(48)
              .backgroundColor('#007DFF')
              .onClick(() => this.selectFile())

            // 已选择文件显示
            if (this.selectedFileName) {
              Row() {
                Text('📄').fontSize(16)
                Text(this.selectedFileName)
                  .fontSize(14)
                  .fontColor('#333')
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .layoutWeight(1)
                  .margin({ left: 8 })
              }
              .padding(12)
              .margin({ top: 20 })
              .backgroundColor('#f5f5f5')
              .borderRadius(8)
              .width('80%')

              // 开始解析按钮
              Button('开始解析')
                .width('80%')
                .height(48)
                .backgroundColor('#28a745')
                .margin({ top: 16 })
                .onClick(() => this.uploadFile())
            }

            // 错误消息
            if (this.errorMessage) {
              Text(this.errorMessage)
                .fontSize(14)
                .fontColor('#dc3545')
                .margin({ top: 16 })
            }
          }
          .width('100%')
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Center)

        } else {
          // 预览视图
          Column() {
            // 摘要
            Row() {
              Text(`共 ${this.totalCourses} 门课程，${this.totalSchedules} 个时间段`)
                .fontSize(14)
                .fontColor('#666')
            }
            .padding(12)
            .width('100%')
            .backgroundColor('#f8f9fa')

            // 课程列表
            List({ space: 8 }) {
              ForEach(this.parsedCourses, (course: ImportedCourse) => {
                ListItem() {
                  Column() {
                    Row() {
                      Text(course.courseName)
                        .fontSize(16)
                        .fontWeight(FontWeight.Bold)
                        .fontColor('#333')
                        .layoutWeight(1)
                      if (course.credits > 0) {
                        Text(`${course.credits}学分`)
                          .fontSize(12)
                          .fontColor('#999')
                      }
                    }.width('100%')

                    if (course.teacher) {
                      Text(`教师: ${course.teacher}`)
                        .fontSize(14)
                        .fontColor('#666')
                        .margin({ top: 4 })
                    }

                    Text(this.formatSchedule(course.schedule))
                      .fontSize(13)
                      .fontColor('#007DFF')
                      .margin({ top: 4 })

                    if (course.schedule.length > 0 && course.schedule[0].weeks.length > 0) {
                      Text(this.formatWeeks(course.schedule[0].weeks))
                        .fontSize(12)
                        .fontColor('#999')
                        .margin({ top: 2 })
                    }
                  }
                  .padding(12)
                  .backgroundColor(Color.White)
                  .borderRadius(8)
                  .width('100%')
                  .alignItems(HorizontalAlign.Start)
                }
              })
            }
            .layoutWeight(1)
            .padding({ left: 12, right: 12 })

            // 底部按钮
            Row() {
              Button('取消')
                .layoutWeight(1)
                .height(48)
                .backgroundColor('#6c757d')
                .margin({ right: 8 })
                .onClick(() => {
                  this.showPreview = false;
                  this.parsedCourses = [];
                })

              Button('确认导入')
                .layoutWeight(1)
                .height(48)
                .backgroundColor('#28a745')
                .margin({ left: 8 })
                .onClick(() => this.confirmImport())
            }
            .padding(12)
            .width('100%')

            // 错误消息
            if (this.errorMessage) {
              Text(this.errorMessage)
                .fontSize(14)
                .fontColor('#dc3545')
                .margin({ bottom: 8 })
            }
          }
          .width('100%')
          .layoutWeight(1)
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#f5f5f5')

      // 加载遮罩
      if (this.isLoading) {
        Column() {
          LoadingProgress()
            .width(50)
            .height(50)
            .color(Color.White)
          Text(this.loadingText)
            .fontSize(14)
            .fontColor(Color.White)
            .margin({ top: 10 })
        }
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(0,0,0,0.5)')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      }
    }
    .width('100%')
    .height('100%')
  }
}
