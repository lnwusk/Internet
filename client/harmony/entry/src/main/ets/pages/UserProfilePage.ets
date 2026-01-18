import { UserService } from '../services/UserService';
import { UserProfile, UpdateProfileRequest, ApiResponse } from '../common/models/ApiModels';
import router from '@ohos.router';
import common from '@ohos.app.ability.common';
import { Logger } from '../common/utils/Logger';

@Entry
@Component
struct UserProfilePage {
  private context: common.Context = getContext(this) as common.Context;

  @State userProfile: UserProfile | null = null;
  @State isLoading: boolean = true;
  @State errorMessage: string = '';
  @State showSuccessDialog: boolean = false;

  @State tempNickname: string = '';
  @State tempStudentId: string = '';

  aboutToAppear(): void {
    this.loadUserProfile();
  }

  async loadUserProfile(): Promise<void> {
    this.isLoading = true;
    this.errorMessage = '';
    try {
      const response: ApiResponse<UserProfile> = await UserService.getUserProfile(this.context);
      if (response.code === 200 && response.data) {
        this.userProfile = response.data;
        this.resetEditFields();
      }
    } catch (error) {
      const err = error as Error;
      this.errorMessage = `加载失败: ${err.message}`;
    } finally {
      this.isLoading = false;
    }
  }

  resetEditFields(): void {
    if (this.userProfile) {
      this.tempNickname = this.userProfile.nickname;
      this.tempStudentId = this.userProfile.studentId;
    }
  }

  saveProfile(): void {
    if (!this.userProfile) return;

    const updateData: UpdateProfileRequest = new UpdateProfileRequest();
    let hasChanges = false;

    if (this.tempNickname !== this.userProfile.nickname) {
      updateData.nickname = this.tempNickname;
      hasChanges = true;
    }
    if (this.tempStudentId !== this.userProfile.studentId) {
      updateData.studentId = this.tempStudentId;
      hasChanges = true;
    }

    if (!hasChanges) {
      router.back();
      return;
    }

    this.isLoading = true;
    this.errorMessage = '';

    UserService.updateUserProfile(this.context, updateData)
      .then(() => {
        this.isLoading = false;
        if (this.userProfile) {
          if (updateData.nickname) this.userProfile.nickname = updateData.nickname;
          if (updateData.studentId) this.userProfile.studentId = updateData.studentId;
        }
        this.showSuccessDialog = true;
      })
      .catch((error: Error) => {
        this.isLoading = false;
        this.errorMessage = `更新失败: ${error.message}`;
      });
  }

  handleReturn(): void {
    this.showSuccessDialog = false;
    router.back();
  }

  @Builder
  LoadingState() {
    Column() {
      LoadingProgress().width(50).height(50).color('#007DFF')
      Text('加载中...').fontSize(16).fontColor('#666666').margin({ top: 12 })
    }.width('100%').height('100%').justifyContent(FlexAlign.Center)
  }

  @Builder
  ErrorState() {
    Column({ space: 20 }) {
      Text('加载失败').fontSize(18).fontColor('#FF3B30')
      Text(this.errorMessage).fontSize(14).fontColor('#666666')
      Button('重试').width(120).height(40).backgroundColor('#007DFF').onClick(() => this.loadUserProfile())
    }.width('100%').height('100%').justifyContent(FlexAlign.Center).padding(40)
  }

  build() {
    Column() {
      // 顶部导航栏
      Row({ space: 12 }) {
        Button('返回').fontSize(16).fontColor('#007DFF').backgroundColor(Color.Transparent)
          .onClick(() => router.back())
        Text('编辑资料').fontSize(20).fontWeight(FontWeight.Bold).layoutWeight(1).textAlign(TextAlign.Center)
        Button('保存').fontSize(16).fontColor('#007DFF').backgroundColor(Color.Transparent)
          .onClick(() => this.saveProfile())
      }.width('100%').padding({ left: 16, right: 16, top: 12, bottom: 12 }).backgroundColor('#FFFFFF')

      if (this.isLoading) {
        this.LoadingState()
      } else if (this.errorMessage && !this.userProfile) {
        this.ErrorState()
      } else if (this.userProfile) {
        Scroll() {
          Column({ space: 16 }) {
            if (this.errorMessage) {
              Text(this.errorMessage).fontSize(14).fontColor('#FF3B30').width('100%')
            }

            // 可编辑信息卡片
            Column({ space: 16 }) {
              // 昵称
              Column({ space: 8 }) {
                Text('昵称').fontSize(14).fontColor('#666666').width('100%')
                TextInput({ text: this.tempNickname, placeholder: '请输入昵称' })
                  .width('100%').height(48).backgroundColor('#F5F5F5').borderRadius(8)
                  .onChange((value: string) => { this.tempNickname = value; })
              }.alignItems(HorizontalAlign.Start).width('100%')

              // 学号
              Column({ space: 8 }) {
                Text('学号').fontSize(14).fontColor('#666666').width('100%')
                TextInput({ text: this.tempStudentId, placeholder: '请输入学号' })
                  .width('100%').height(48).backgroundColor('#F5F5F5').borderRadius(8)
                  .onChange((value: string) => { this.tempStudentId = value; })
              }.alignItems(HorizontalAlign.Start).width('100%')
            }.padding(16).backgroundColor('#FFFFFF').borderRadius(8).width('100%')

            // 只读信息卡片
            Column({ space: 16 }) {
              // 用户名
              Row() {
                Text('用户名').fontSize(14).fontColor('#666666').width(80)
                Text(this.userProfile.username).fontSize(16).fontColor('#333333').layoutWeight(1)
              }.width('100%')

              Divider().color('#E5E5E5')

              // 注册时间
              Row() {
                Text('注册时间').fontSize(14).fontColor('#666666').width(80)
                Text(this.userProfile.createdAt.substring(0, 10)).fontSize(16).fontColor('#333333').layoutWeight(1)
              }.width('100%')
            }.padding(16).backgroundColor('#FFFFFF').borderRadius(8).width('100%')
          }.padding(16).width('100%')
        }.scrollable(ScrollDirection.Vertical).layoutWeight(1)
      }

      // 成功弹窗
      if (this.showSuccessDialog) {
        Column() {
          Column({ space: 20 }) {
            Text('✓').fontSize(48).fontColor('#34C759')
            Text('资料更新成功！').fontSize(18).fontWeight(FontWeight.Bold)
            Button('返回个人中心')
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
    }.width('100%').height('100%').backgroundColor('#F5F5F5')
  }
}
