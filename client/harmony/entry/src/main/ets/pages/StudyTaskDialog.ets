import common from '@ohos.app.ability.common';
import { StudyTask, CreateStudyTaskRequest } from '../common/models/ApiModels';
import { StudyTaskService } from '../services/StudyTaskService';
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
    if (this.editTask) {
      // 编辑模式
      this.title = this.editTask.title;
      this.scheduledDate = this.editTask.scheduledDate;
      this.startTime = this.editTask.startTime;
      this.description = this.editTask.description || '';
      // 解析时间
      const parts = this.startTime.split(':');
      if (parts.length >= 2) {
        this.selectedHour = parts[0];
        this.selectedMinute = parts[1];
      }
    } else {
      // 新建模式
      if (this.presetDate) {
        this.scheduledDate = this.presetDate;
      }
      if (this.presetStartTime) {
        this.startTime = this.presetStartTime;
        const parts = this.presetStartTime.split(':');
        if (parts.length >= 2) {
          this.selectedHour = parts[0];
          // 四舍五入到5分钟
          const min = parseInt(parts[1]);
          const roundedMin = Math.floor(min / 5) * 5;
          this.selectedMinute = roundedMin.toString().padStart(2, '0');
        }
      }
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
      taskData.endTime = this.startTime; // 只有开始时间
      taskData.description = this.description;

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

        Row() {
          // 小时选择
          Select(this.hourOptions.map(h => ({ value: h } as SelectOption)))
            .value(this.selectedHour)
            .font({ size: 16 })
            .backgroundColor('#f5f5f5')
            .borderRadius(8)
            .onSelect((index: number, value: string) => {
              this.selectedHour = value;
              this.updateStartTime();
            })

          Text(':').fontSize(20).margin({ left: 8, right: 8 })

          // 分钟选择 (5分钟间隔)
          Select(this.minuteOptions.map(m => ({ value: m } as SelectOption)))
            .value(this.selectedMinute)
            .font({ size: 16 })
            .backgroundColor('#f5f5f5')
            .borderRadius(8)
            .onSelect((index: number, value: string) => {
              this.selectedMinute = value;
              this.updateStartTime();
            })

          Blank()

          Text(this.startTime)
            .fontSize(16)
            .fontColor('#007DFF')
            .fontWeight(FontWeight.Medium)
        }
        .width('100%')
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')
      .margin({ bottom: 12 })

      // 关联作业 (占位按钮)
      Column() {
        Text('关联作业（可选）').fontSize(14).fontColor('#666').margin({ bottom: 4 })
        Button('选择作业...')
          .width('100%')
          .height(44)
          .backgroundColor('#f5f5f5')
          .fontColor('#999')
          .onClick(() => {
            // TODO: 作业功能实现后打开作业选择列表
            this.errorMessage = '作业功能开发中...';
          })
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')
      .margin({ bottom: 16 })

      // 错误消息
      if (this.errorMessage) {
        Text(this.errorMessage)
          .fontSize(14)
          .fontColor('#dc3545')
          .margin({ bottom: 12 })
      }

      // 按钮区域
      if (this.editTask) {
        Row() {
          Button('删除')
            .layoutWeight(1)
            .height(44)
            .backgroundColor('#dc3545')
            .margin({ right: 4 })
            .onClick(() => this.deleteTask())

          Button(this.editTask.status === 'completed' ? '✓ 已完成' : '标记完成')
            .layoutWeight(1)
            .height(44)
            .backgroundColor(this.editTask.status === 'completed' ? '#6c757d' : '#28a745')
            .margin({ left: 4, right: 4 })
            .enabled(this.editTask.status !== 'completed')
            .onClick(() => this.completeTask())

          Button('保存')
            .layoutWeight(1)
            .height(44)
            .backgroundColor('#007DFF')
            .margin({ left: 4 })
            .onClick(() => this.saveTask())
        }
        .width('100%')
      } else {
        Row() {
          Button('取消')
            .layoutWeight(1)
            .height(44)
            .backgroundColor('#6c757d')
            .margin({ right: 8 })
            .onClick(() => this.controller.close())

          Button('创建任务')
            .layoutWeight(1)
            .height(44)
            .backgroundColor('#28a745')
            .margin({ left: 8 })
            .onClick(() => this.saveTask())
        }
        .width('100%')
      }

      if (this.isLoading) {
        LoadingProgress().width(30).height(30).margin({ top: 10 })
      }
    }
    .padding(20)
    .backgroundColor(Color.White)
    .borderRadius(16)
    .width('90%')
  }
}
