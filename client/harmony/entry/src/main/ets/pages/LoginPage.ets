import router from '@ohos.router';
import { AuthService } from '../services/AuthService';
import { Logger } from '../common/utils/Logger';
import common from '@ohos.app.ability.common';
import promptAction from '@ohos.promptAction';

@Entry
@Component
struct LoginPage {
  @State username: string = '';
  @State password: string = '';
  @State isLoading: boolean = false;
  @State errorMessage: string = '';
  
  // 使用 aboutToAppear 初始化 context
  private context: common.UIAbilityContext | null = null;

  aboutToAppear() {
    this.context = getContext(this) as common.UIAbilityContext;
  }

  async handleLogin() {
    if (!this.context) {
       Logger.error('Context is null');
       promptAction.showToast({ message: '初始化失败，请重启应用', duration: 2000 });
       return;
    }

    if (this.username === '' || this.password === '') {
      this.errorMessage = '请输入用户名和密码';
      Logger.info('Empty credentials');
      return;
    }

    Logger.info('=== Login button clicked ===');
    this.isLoading = true;
    this.errorMessage = '';
    Logger.info('isLoading set to true');
    
    try {
      // 使用已初始化的 this.context
      Logger.info('Calling AuthService.login');
      const result = await AuthService.login(this.context, this.username, this.password);
      Logger.info('=== Login Result ===:', JSON.stringify(result));
      Logger.info(`Result code: ${result.code}, type: ${typeof result.code}`);
      
      if (result.code === 200) {
        Logger.info('Login successful, token saved');
        Logger.info('Attempting navigation to Index');
        
        // 直接跳转，不使用setTimeout避免UI上下文丢失
        router.replaceUrl({ url: 'pages/Index' })
          .then(() => {
            Logger.info('Navigation to Index successful');
            this.isLoading = false;
          })
          .catch((err: object) => {
            Logger.error('Navigation failed:', JSON.stringify(err));
            this.isLoading = false;
          });
      } else {
        Logger.error(`Login failed with code ${result.code}:`, result.message);
        this.errorMessage = `登录失败: ${result.message}`;
        this.isLoading = false;
        Logger.info('isLoading reset to false (failed)');
      }
    } catch (err) {
      Logger.error('=== Login exception caught ===:', JSON.stringify(err));
      if (err instanceof Error) {
        Logger.error('Error message:', err.message);
        Logger.error('Error stack:', err.stack || 'No stack trace');
      }
      this.errorMessage = '网络请求失败，请检查网络';
      this.isLoading = false;
      Logger.info('isLoading reset to false (exception)');
    }
  }

  build() {
    Column() {
      Text('NjuPlan Login')
        .fontSize(30)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 100, bottom: 20 })

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
        .height(50)
        .margin({ bottom: 10 })
        .onChange((value: string) => {
          this.username = value;
        })

      TextInput({ placeholder: 'Password', text: this.password })
        .type(InputType.Password)
        .width('80%')
        .height(50)
        .margin({ bottom: 20 })
        .onChange((value: string) => {
          this.password = value;
        })

      Button('Login')
        .width('80%')
        .height(50)
        .onClick(async () => {
          await this.handleLogin();
        })
        .enabled(!this.isLoading)

      Row() {
        Text('No account? ')
        Text('Register')
          .fontColor(Color.Blue)
          .onClick(() => {
            router.pushUrl({ url: 'pages/RegisterPage' });
          })
      }
      .margin({ top: 20 })
    }
    .width('100%')
    .height('100%')
  }
}
