import router from '@ohos.router';
import { AuthService } from '../services/AuthService';
import { Logger } from '../common/utils/Logger';
import { RegisterRequest } from '../common/models/ApiModels';
import common from '@ohos.app.ability.common';
import promptAction from '@ohos.promptAction';

@Entry
@Component
struct RegisterPage {
  @State username: string = '';
  @State password: string = '';
  @State confirmPassword: string = '';
  @State nickname: string = '';
  @State studentId: string = '';
  @State isLoading: boolean = false;
  @State errorMessage: string = '';
  
  // 使用 aboutToAppear 初始化 context
  private context: common.UIAbilityContext | null = null;

  aboutToAppear() {
    this.context = getContext(this) as common.UIAbilityContext;
  }

  async handleRegister() {
    if (!this.context) {
       Logger.error('Context is null');
       promptAction.showToast({ message: '初始化失败，请重启应用', duration: 2000 });
       return;
    }

    if (this.username === '' || this.password === '') {
      this.errorMessage = '用户名和密码不能为空';
      return;
    }
    if (this.password !== this.confirmPassword) {
      this.errorMessage = '两次输入的密码不一致';
      Logger.info('Passwords do not match');
      return;
    }

    this.isLoading = true;
    this.errorMessage = '';
    try {
      const requestData: RegisterRequest = {
        username: this.username,
        password: this.password,
        nickname: this.nickname,
        studentId: this.studentId
      };

      // 使用已初始化的 this.context
      const result = await AuthService.register(this.context, requestData);
      Logger.info('Registration result:', JSON.stringify(result));
      
      if (result.code === 200) {
        Logger.info('Registration successful, navigating to login page');
        
        // 直接跳转，不使用setTimeout避免UI上下文丢失
        router.replaceUrl({ url: 'pages/LoginPage' })
          .then(() => {
            Logger.info('Navigation to LoginPage successful');
            this.isLoading = false;
          })
          .catch((err: object) => {
            Logger.error('Navigation failed:', JSON.stringify(err));
            this.isLoading = false;
          });
      } else {
        Logger.error('Registration failed:', result.message);
        this.errorMessage = `注册失败: ${result.message}`;
        this.isLoading = false;
      }
    } catch (err) {
      Logger.error('Registration failed:', JSON.stringify(err));
      this.errorMessage = '网络请求失败，请检查网络';
      this.isLoading = false;
    }
  }

  build() {
    Column() {
      Text('Register')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 50, bottom: 20 })

      // 错误消息显示
      if (this.errorMessage !== '') {
        Text(this.errorMessage)
          .fontSize(14)
          .fontColor(Color.Red)
          .width('80%')
          .margin({ bottom: 10 })
      }

      TextInput({ placeholder: 'Username', text: this.username })
        .width('80%')
        .margin({ bottom: 10 })
        .onChange((value) => this.username = value)

      TextInput({ placeholder: 'Nickname', text: this.nickname })
        .width('80%')
        .margin({ bottom: 10 })
        .onChange((value) => this.nickname = value)

      TextInput({ placeholder: 'Student ID', text: this.studentId })
        .width('80%')
        .margin({ bottom: 10 })
        .onChange((value) => this.studentId = value)

      TextInput({ placeholder: 'Password', text: this.password })
        .type(InputType.Password)
        .width('80%')
        .margin({ bottom: 10 })
        .onChange((value) => this.password = value)

      TextInput({ placeholder: 'Confirm Password', text: this.confirmPassword })
        .type(InputType.Password)
        .width('80%')
        .margin({ bottom: 20 })
        .onChange((value) => this.confirmPassword = value)

      Button('Register')
        .width('80%')
        .onClick(async () => {
           await this.handleRegister();
        })
        .enabled(!this.isLoading)

      Text('Back to Login')
        .fontColor(Color.Gray)
        .fontSize(16)
        .margin({ top: 15 })
        .onClick(() => {
          router.back();
        })
    }
    .width('100%')
    .height('100%')
  }
}
