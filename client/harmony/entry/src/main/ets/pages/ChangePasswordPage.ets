import { AuthService } from '../services/AuthService';
import { ApiResponse } from '../common/models/ApiModels';
import router from '@ohos.router';
import common from '@ohos.app.ability.common';
import { Logger } from '../common/utils/Logger';

@Entry
@Component
struct ChangePasswordPage {
  private context: common.Context = getContext(this) as common.Context;

  @State oldPassword: string = '';
  @State newPassword: string = '';
  @State confirmPassword: string = '';
  @State isLoading: boolean = false;
  @State errorMessage: string = '';
  @State showSuccessDialog: boolean = false;

  changePassword(): void {
    if (!this.oldPassword || !this.newPassword || !this.confirmPassword) {
      this.errorMessage = '请填写所有字段';
      return;
    }
    if (this.newPassword.length < 8) {
      this.errorMessage = '新密码至少8个字符';
      return;
    }
    if (this.newPassword !== this.confirmPassword) {
      this.errorMessage = '两次输入的密码不一致';
      return;
    }

    this.isLoading = true;
    this.errorMessage = '';

    AuthService.changePassword(this.context, this.oldPassword, this.newPassword)
      .then((response: ApiResponse<null>) => {
        this.isLoading = false;
        if (response.code === 200) {
          Logger.info('Password changed successfully');
          this.showSuccessDialog = true;
        } else {
          this.errorMessage = response.message || '修改失败';
        }
      })
      .catch((error: Error) => {
        this.isLoading = false;
        this.errorMessage = error.message;
      });
  }

  handleReturn(): void {
    this.showSuccessDialog = false;
    router.back();
  }

  build() {
    Column() {
      // 顶部导航栏
      Row({ space: 12 }) {
        Button('返回').fontSize(16).fontColor('#007DFF').backgroundColor(Color.Transparent)
          .onClick(() => router.back())
        Text('修改密码').fontSize(20).fontWeight(FontWeight.Bold).layoutWeight(1).textAlign(TextAlign.Center)
        Text('').width(60)
      }.width('100%').padding({ left: 16, right: 16, top: 12, bottom: 12 }).backgroundColor('#FFFFFF')

      Column({ space: 24 }) {
        Column({ space: 8 }) {
          Text('当前密码').fontSize(14).fontColor('#666666')
          TextInput({ placeholder: '请输入当前密码' })
            .type(InputType.Password)
            .width('100%').height(48).backgroundColor('#F5F5F5').borderRadius(8)
            .onChange((value: string) => { this.oldPassword = value; })
        }.alignItems(HorizontalAlign.Start)

        Column({ space: 8 }) {
          Text('新密码').fontSize(14).fontColor('#666666')
          TextInput({ placeholder: '请输入新密码（至少8个字符）' })
            .type(InputType.Password)
            .width('100%').height(48).backgroundColor('#F5F5F5').borderRadius(8)
            .onChange((value: string) => { this.newPassword = value; })
        }.alignItems(HorizontalAlign.Start)

        Column({ space: 8 }) {
          Text('确认新密码').fontSize(14).fontColor('#666666')
          TextInput({ placeholder: '请再次输入新密码' })
            .type(InputType.Password)
            .width('100%').height(48).backgroundColor('#F5F5F5').borderRadius(8)
            .onChange((value: string) => { this.confirmPassword = value; })
        }.alignItems(HorizontalAlign.Start)

        if (this.errorMessage) {
          Text(this.errorMessage).fontSize(14).fontColor('#FF3B30')
        }

        Button(this.isLoading ? '提交中...' : '确认修改')
          .width('100%').height(48).backgroundColor('#007DFF').fontColor('#FFFFFF')
          .enabled(!this.isLoading)
          .onClick(() => this.changePassword())
      }.padding(24).layoutWeight(1)

      // 成功弹窗
      if (this.showSuccessDialog) {
        Column() {
          Column({ space: 20 }) {
            Text('✓').fontSize(48).fontColor('#34C759')
            Text('密码修改成功！').fontSize(18).fontWeight(FontWeight.Bold)
            Text('请使用新密码重新登录').fontSize(14).fontColor('#666666')
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
    }.width('100%').height('100%').backgroundColor('#FFFFFF')
  }
}
