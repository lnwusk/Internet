import { AssignmentService } from '../services/AssignmentService';
import { CourseService } from '../services/CourseService';
import { AssignmentDetail, CreateAssignmentRequest, UpdateAssignmentRequest, ApiResponse, CourseDetail, CourseListData, AssignmentOperationResponse } from '../common/models/ApiModels';
import router from '@ohos.router';
import common from '@ohos.app.ability.common';
import { Logger } from '../common/utils/Logger';

interface RouterParams {
  assignmentId?: string;
  mode?: string;
}

@Entry
@Component
struct AssignmentDetailPage {
  private context: common.Context = getContext(this) as common.Context;

  @State assignmentId: string = '';
  @State isCreateMode: boolean = false;
  @State isLoading: boolean = false;
  @State errorMessage: string = '';
  @State showSuccessDialog: boolean = false;
  @State successMessage: string = '';

  @State courses: CourseDetail[] = [];
  @State selectedCourseIndex: number = -1;

  @State title: string = '';
  @State description: string = '';
  @State courseId: string = '';
  @State dueDate: string = '';
  @State type: string = '';
  @State difficulty: string = '';

  aboutToAppear(): void {
    const params = router.getParams() as RouterParams;
    if (params?.mode === 'create') {
      this.isCreateMode = true;
      this.loadCourses();
    } else if (params?.assignmentId) {
      this.assignmentId = params.assignmentId;
      this.loadAssignmentDetail();
    }
  }

  async loadCourses(): Promise<void> {
    try {
      const response: ApiResponse<CourseListData> = await CourseService.getCourseList(this.context);
      if (response.code === 200 && response.data && response.data.courses) {
        this.courses = response.data.courses;
        Logger.info('Loaded courses:', this.courses.length.toString());
      }
    } catch (error) {
      Logger.error('Load courses error:', JSON.stringify(error));
    }
  }

  async loadAssignmentDetail(): Promise<void> {
    this.isLoading = true;
    try {
      await this.loadCourses();
      const response: ApiResponse<AssignmentDetail> = await AssignmentService.getAssignmentDetail(this.context, this.assignmentId);
      if (response.code === 200 && response.data) {
        this.title = response.data.title;
        this.description = response.data.description;
        this.courseId = response.data.courseId;
        this.dueDate = response.data.dueDate.substring(0, 10);
        this.type = response.data.type || '';
        this.difficulty = response.data.difficulty || '';
        const idx = this.courses.findIndex(c => c.courseId === this.courseId);
        if (idx >= 0) { this.selectedCourseIndex = idx; }
      }
    } catch (error) {
      const err = error as Error;
      this.errorMessage = `加载失败: ${err.message}`;
    } finally {
      this.isLoading = false;
    }
  }

  saveAssignment(): void {
    if (!this.title) { this.errorMessage = '请输入作业标题'; return; }
    if (!this.courseId) { this.errorMessage = '请选择关联的课程'; return; }
    if (!this.dueDate) { this.errorMessage = '请输入截止日期'; return; }

    this.isLoading = true;
    this.errorMessage = '';

    if (this.isCreateMode) {
      const request: CreateAssignmentRequest = new CreateAssignmentRequest();
      request.courseId = this.courseId;
      request.title = this.title;
      request.description = this.description;
      request.dueDate = this.dueDate + 'T23:59:59Z';
      request.type = this.type;
      request.difficulty = this.difficulty;
      request.wordCount = 0;

      AssignmentService.createAssignment(this.context, request)
        .then((response: ApiResponse<AssignmentOperationResponse>) => {
          this.isLoading = false;
          if (response.code === 200) {
            this.successMessage = '作业创建成功';
            this.showSuccessDialog = true;
          } else {
            this.errorMessage = response.message || '创建失败';
          }
        })
        .catch((error: Error) => {
          this.isLoading = false;
          this.errorMessage = `创建失败: ${error.message}`;
        });
    } else {
      const request: UpdateAssignmentRequest = new UpdateAssignmentRequest();
      request.title = this.title;
      request.description = this.description;
      request.dueDate = this.dueDate + 'T23:59:59Z';
      request.type = this.type;
      request.difficulty = this.difficulty;

      AssignmentService.updateAssignment(this.context, this.assignmentId, request)
        .then((response: ApiResponse<AssignmentOperationResponse>) => {
          this.isLoading = false;
          if (response.code === 200) {
            this.successMessage = '作业更新成功';
            this.showSuccessDialog = true;
          } else {
            this.errorMessage = response.message || '更新失败';
          }
        })
        .catch((error: Error) => {
          this.isLoading = false;
          this.errorMessage = `更新失败: ${error.message}`;
        });
    }
  }

  handleReturn(): void {
    this.showSuccessDialog = false;
    router.back();
  }

  build() {
    Column() {
      Row({ space: 12 }) {
        Button('返回').fontSize(16).fontColor('#007DFF').backgroundColor(Color.Transparent)
          .onClick(() => router.back())
        Text(this.isCreateMode ? '添加作业' : '作业详情')
          .fontSize(20).fontWeight(FontWeight.Bold).layoutWeight(1).textAlign(TextAlign.Center)
        Button('保存').fontSize(16).fontColor('#007DFF').backgroundColor(Color.Transparent)
          .onClick(() => this.saveAssignment())
      }.width('100%').padding({ left: 16, right: 16, top: 12, bottom: 12 }).backgroundColor('#FFFFFF')

      if (this.isLoading) {
        Column() {
          LoadingProgress().width(50).height(50).color('#007DFF')
          Text('处理中...').fontSize(16).fontColor('#666666').margin({ top: 12 })
        }.width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
      } else {
        Scroll() {
          Column({ space: 16 }) {
            if (this.errorMessage) {
              Text(this.errorMessage).fontSize(14).fontColor('#FF3B30').width('100%')
            }

            Column({ space: 8 }) {
              Text('标题 *').fontSize(14).fontColor('#666666')
              TextInput({ text: this.title, placeholder: '请输入作业标题' })
                .width('100%').height(48).backgroundColor('#F5F5F5').borderRadius(8)
                .onChange((value: string) => { this.title = value; })
            }.alignItems(HorizontalAlign.Start)

            Column({ space: 8 }) {
              Text('选择课程 *').fontSize(14).fontColor('#666666')
              if (this.courses.length > 0) {
                Select(this.courses.map((c: CourseDetail) => {
                  return { value: `${c.courseName} (${c.courseCode})` } as SelectOption;
                }))
                  .selected(this.selectedCourseIndex >= 0 ? this.selectedCourseIndex : 0)
                  .value(this.selectedCourseIndex >= 0 ? `${this.courses[this.selectedCourseIndex].courseName}` : '请选择课程')
                  .width('100%').height(48).backgroundColor('#F5F5F5').borderRadius(8)
                  .onSelect((index: number) => {
                    this.selectedCourseIndex = index;
                    this.courseId = this.courses[index].courseId;
                  })
              } else {
                Text('加载课程列表中...').fontSize(14).fontColor('#999999')
              }
            }.alignItems(HorizontalAlign.Start)

            Column({ space: 8 }) {
              Text('截止日期 *').fontSize(14).fontColor('#666666')
              TextInput({ text: this.dueDate, placeholder: 'YYYY-MM-DD (如: 2026-01-20)' })
                .width('100%').height(48).backgroundColor('#F5F5F5').borderRadius(8)
                .onChange((value: string) => { this.dueDate = value; })
            }.alignItems(HorizontalAlign.Start)

            Column({ space: 8 }) {
              Text('描述').fontSize(14).fontColor('#666666')
              TextArea({ text: this.description, placeholder: '请输入作业描述' })
                .width('100%').height(120).backgroundColor('#F5F5F5').borderRadius(8)
                .onChange((value: string) => { this.description = value; })
            }.alignItems(HorizontalAlign.Start)

            Column({ space: 8 }) {
              Text('类型').fontSize(14).fontColor('#666666')
              Row({ space: 8 }) {
                ForEach(['programming', 'essay', 'report', 'presentation'], (t: string) => {
                  Button(t).fontSize(12).height(32)
                    .fontColor(this.type === t ? '#FFFFFF' : '#007DFF')
                    .backgroundColor(this.type === t ? '#007DFF' : '#E3F2FD')
                    .onClick(() => { this.type = t; })
                })
              }
            }.alignItems(HorizontalAlign.Start)

            Column({ space: 8 }) {
              Text('难度').fontSize(14).fontColor('#666666')
              Row({ space: 8 }) {
                ForEach(['easy', 'medium', 'hard'], (d: string) => {
                  Button(d === 'easy' ? '简单' : d === 'medium' ? '中等' : '困难')
                    .fontSize(12).height(32)
                    .fontColor(this.difficulty === d ? '#FFFFFF' : '#007DFF')
                    .backgroundColor(this.difficulty === d ? '#007DFF' : '#E3F2FD')
                    .onClick(() => { this.difficulty = d; })
                })
              }
            }.alignItems(HorizontalAlign.Start)
          }.padding(16)
        }.layoutWeight(1)
      }

      // 成功弹窗
      if (this.showSuccessDialog) {
        Column() {
          Column({ space: 20 }) {
            Text('✓').fontSize(48).fontColor('#34C759')
            Text(this.successMessage).fontSize(18).fontWeight(FontWeight.Bold)
            Button('返回作业列表')
              .width('100%').height(45).backgroundColor('#007DFF').fontColor(Color.White)
              .onClick(() => this.handleReturn())
          }
          .width('80%').padding(24).backgroundColor(Color.White).borderRadius(12)
        }
        .width('100%').height('100%')
        .backgroundColor('rgba(0,0,0,0.5)')
        .justifyContent(FlexAlign.Center)
        .position({ x: 0, y: 0 }).zIndex(999)
      }
    }.width('100%').height('100%').backgroundColor('#FFFFFF')
  }
}
