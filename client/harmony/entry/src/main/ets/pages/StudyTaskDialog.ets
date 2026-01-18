import common from '@ohos.app.ability.common';
import { StudyTask, CreateStudyTaskRequest, Assignment, AssignmentListData, ApiResponse } from '../common/models/ApiModels';
import { StudyTaskService } from '../services/StudyTaskService';
import { AssignmentService } from '../services/AssignmentService';
import { Logger } from '../common/utils/Logger';

// 学习任务添加/编辑弹窗
@CustomDialog
export struct StudyTaskDialog {
  controller: CustomDialogController;
  @State title: string = '';
  @State scheduledDate: string = '';
  @State startTime: string = '14:00';
  @State description: string = '';
  @State isLoading: boolean = false;
  @State errorMessage: string = '';

  // 作业关联
  @State assignments: Assignment[] = [];
  @State selectedAssignmentIndex: number = -1;
  @State selectedAssignmentId: string = '';

  // 外部传入的参数
  editTask?: StudyTask;
  presetDate?: string;
  presetStartTime?: string;
  onSuccess?: () => void;

  private context: common.UIAbilityContext | null = null;

  // 时间选项 (5分钟间隔)
  private hourOptions: string[] = ['06', '07', '08', '09', '10', '11', '12', '13', '14', '15', '16', '17', '18', '19', '20', '21', '22'];
  private minuteOptions: string[] = ['00', '05', '10', '15', '20', '25', '30', '35', '40', '45', '50', '55'];

  @State selectedHour: string = '14';
  @State selectedMinute: string = '00';

  aboutToAppear() {
    this.context = getContext(this) as common.UIAbilityContext;
    this.loadAssignments();

    if (this.editTask) {
      this.title = this.editTask.title;
      this.scheduledDate = this.editTask.scheduledDate;
      this.startTime = this.editTask.startTime;
      this.description = this.editTask.description || '';
      if (this.editTask.assignmentId) {
        this.selectedAssignmentId = this.editTask.assignmentId;
      }
      const parts = this.startTime.split(':');
      if (parts.length >= 2) {
        this.selectedHour = parts[0];
        this.selectedMinute = parts[1];
      }
    } else {
      if (this.presetDate) {
        this.scheduledDate = this.presetDate;
      }
      if (this.presetStartTime) {
        this.startTime = this.presetStartTime;
        const parts = this.presetStartTime.split(':');
        if (parts.length >= 2) {
          this.selectedHour = parts[0];
          const min = parseInt(parts[1]);
          const roundedMin = Math.floor(min / 5) * 5;
          this.selectedMinute = roundedMin.toString().padStart(2, '0');
        }
      }
    }
  }

  async loadAssignments() {
    if (!this.context) return;
    try {
      const response: ApiResponse<AssignmentListData> = await AssignmentService.getPendingAssignments(this.context);
      if (response.code === 200 && response.data) {
        this.assignments = response.data.assignments;
        // 如果编辑模式且有关联作业，找到索引
        if (this.selectedAssignmentId) {
          const idx = this.assignments.findIndex(a => a.assignmentId === this.selectedAssignmentId);
          if (idx >= 0) this.selectedAssignmentIndex = idx;
        }
      }
    } catch (err) {
      Logger.error('Load assignments failed:', JSON.stringify(err));
    }
  }

  updateStartTime() {
    this.startTime = `${this.selectedHour}:${this.selectedMinute}`;
  }

  async saveTask() {
    if (!this.title.trim()) {
      this.errorMessage = '请输入任务标题';
      return;
    }
    if (!this.scheduledDate) {
      this.errorMessage = '请选择日期';
      return;
    }
    if (!this.context) return;

    this.isLoading = true;
    this.errorMessage = '';

    try {
      const taskData: CreateStudyTaskRequest = new CreateStudyTaskRequest();
      taskData.title = this.title;
      taskData.scheduledDate = this.scheduledDate;
      taskData.startTime = this.startTime;
      taskData.endTime = this.startTime;
      taskData.description = this.description;
      taskData.assignmentId = this.selectedAssignmentId;

      if (this.editTask) {
        const response = await StudyTaskService.updateStudyTask(this.context, this.editTask.taskId, taskData);
        if (response.code === 200) {
          Logger.info('Task updated');
          if (this.onSuccess) this.onSuccess();
          this.controller.close();
        } else {
          this.errorMessage = response.message || '更新失败';
        }
      } else {
        const response = await StudyTaskService.createStudyTask(this.context, taskData);
        if (response.code === 200) {
          Logger.info('Task created');
          if (this.onSuccess) this.onSuccess();
          this.controller.close();
        } else {
          this.errorMessage = response.message || '创建失败';
        }
      }
    } catch (err) {
      Logger.error('Save task failed:', JSON.stringify(err));
      this.errorMessage = '保存失败';
    } finally {
      this.isLoading = false;
    }
  }

  async deleteTask() {
    if (!this.editTask || !this.context) return;
    this.isLoading = true;
    try {
      const response = await StudyTaskService.deleteStudyTask(this.context, this.editTask.taskId);
      if (response.code === 200) {
        if (this.onSuccess) this.onSuccess();
        this.controller.close();
      } else {
        this.errorMessage = response.message || '删除失败';
      }
    } catch (err) {
      this.errorMessage = '删除失败';
    } finally {
      this.isLoading = false;
    }
  }

  async completeTask() {
    if (!this.editTask || !this.context) return;
    this.isLoading = true;
    try {
      const response = await StudyTaskService.completeStudyTask(this.context, this.editTask.taskId);
      if (response.code === 200) {
        if (this.onSuccess) this.onSuccess();
        this.controller.close();
      } else {
        this.errorMessage = response.message || '操作失败';
      }
    } catch (err) {
      this.errorMessage = '操作失败';
    } finally {
      this.isLoading = false;
    }
  }

  build() {
    Column() {
      // 标题栏
      Row() {
        Text(this.editTask ? '编辑学习任务' : '添加学习任务')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
        Blank()
        Button({ type: ButtonType.Circle }) {
          Text('✕').fontSize(16)
        }
        .width(30).height(30).backgroundColor('#f0f0f0')
        .onClick(() => this.controller.close())
      }
      .width('100%')
      .margin({ bottom: 16 })

      // 任务标题
      Column() {
        Text('任务标题').fontSize(14).fontColor('#666').margin({ bottom: 4 })
        TextInput({ placeholder: '例如：完成Web作业', text: this.title })
          .onChange((value: string) => this.title = value)
          .height(44)
          .backgroundColor('#f5f5f5')
          .borderRadius(8)
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')
      .margin({ bottom: 12 })

      // 关联作业
      Column() {
        Text('关联作业（可选）').fontSize(14).fontColor('#666').margin({ bottom: 4 })
        if (this.assignments.length > 0) {
          Select([{ value: '不关联作业' } as SelectOption].concat(
            this.assignments.map((a: Assignment) => {
              return { value: `${a.title} (${a.courseName})` } as SelectOption;
            })
          ))
            .selected(this.selectedAssignmentIndex >= 0 ? this.selectedAssignmentIndex + 1 : 0)
            .value(this.selectedAssignmentIndex >= 0 ? this.assignments[this.selectedAssignmentIndex].title : '不关联作业')
            .width('100%').height(44).backgroundColor('#f5f5f5').borderRadius(8)
            .onSelect((index: number) => {
              if (index === 0) {
                this.selectedAssignmentIndex = -1;
                this.selectedAssignmentId = '';
              } else {
                this.selectedAssignmentIndex = index - 1;
                this.selectedAssignmentId = this.assignments[index - 1].assignmentId;
                // 自动填充标题
                if (!this.title) {
                  this.title = this.assignments[index - 1].title;
                }
              }
            })
        } else {
          Text('暂无待完成作业').fontSize(12).fontColor('#999')
        }
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')
      .margin({ bottom: 12 })

      // 日期
      Column() {
        Text('日期').fontSize(14).fontColor('#666').margin({ bottom: 4 })
        TextInput({ placeholder: 'YYYY-MM-DD', text: this.scheduledDate })
          .onChange((value: string) => this.scheduledDate = value)
          .height(44)
          .backgroundColor('#f5f5f5')
          .borderRadius(8)
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')
      .margin({ bottom: 12 })

      // 开始时间 (精确到5分钟)
      Column() {
        Text('开始时间').fontSize(14).fontColor('#666').margin({ bottom: 4 })

        Row({ space: 8 }) {
          // 小时选择
          Select(this.hourOptions.map((h: string) => {
            return { value: h } as SelectOption;
          }))
            .selected(this.hourOptions.indexOf(this.selectedHour))
            .value(this.selectedHour)
            .height(44)
            .backgroundColor('#f5f5f5')
            .borderRadius(8)
            .layoutWeight(1)
            .onSelect((index: number) => {
              this.selectedHour = this.hourOptions[index];
              this.updateStartTime();
            })

          Text(':').fontSize(20).fontColor('#333')

          // 分钟选择
          Select(this.minuteOptions.map((m: string) => {
            return { value: m } as SelectOption;
          }))
            .selected(this.minuteOptions.indexOf(this.selectedMinute))
            .value(this.selectedMinute)
            .height(44)
            .backgroundColor('#f5f5f5')
            .borderRadius(8)
            .layoutWeight(1)
            .onSelect((index: number) => {
              this.selectedMinute = this.minuteOptions[index];
              this.updateStartTime();
            })
        }
        .width('100%')
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')
      .margin({ bottom: 12 })

      // 描述
      Column() {
        Text('备注（可选）').fontSize(14).fontColor('#666').margin({ bottom: 4 })
        TextArea({ placeholder: '任务详情...', text: this.description })
          .onChange((value: string) => this.description = value)
          .height(80)
          .backgroundColor('#f5f5f5')
          .borderRadius(8)
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')
      .margin({ bottom: 16 })

      // 错误信息
      if (this.errorMessage) {
        Text(this.errorMessage)
          .fontSize(14)
          .fontColor('#FF3B30')
          .margin({ bottom: 12 })
      }

      // 按钮区
      if (this.editTask) {
        Row({ space: 12 }) {
          Button('删除')
            .layoutWeight(1)
            .height(44)
            .backgroundColor('#FF3B30')
            .fontColor(Color.White)
            .onClick(() => this.deleteTask())

          Button('完成')
            .layoutWeight(1)
            .height(44)
            .backgroundColor('#34C759')
            .fontColor(Color.White)
            .onClick(() => this.completeTask())

          Button('保存')
            .layoutWeight(1)
            .height(44)
            .backgroundColor('#007DFF')
            .fontColor(Color.White)
            .onClick(() => this.saveTask())
        }
        .width('100%')
      } else {
        Button(this.isLoading ? '保存中...' : '保存')
          .width('100%')
          .height(44)
          .backgroundColor('#007DFF')
          .fontColor(Color.White)
          .enabled(!this.isLoading)
          .onClick(() => this.saveTask())
      }
    }
    .padding(20)
    .backgroundColor(Color.White)
    .borderRadius(16)
    .width('90%')
  }
}
