import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { notificationManager } from '@kit.NotificationKit';
import { BusinessError } from '@kit.BasicServicesKit';

const DOMAIN = 0x0000;

export default class EntryAbility extends UIAbility {

  /**
   * 【新增】处理快捷方式的公共方法
   * 解析 want 参数，如果包含 shortcutAction，则存入 AppStorage
   */
  private handleShortcut(want: Want) {
    if (want.parameters && want.parameters['shortcutAction']) {
      const action = want.parameters['shortcutAction'] as string;
      // 将动作存入全局变量，页面监听这个变量来弹出对应窗口
      AppStorage.setOrCreate('GlobalShortcutAction', action);
      hilog.info(DOMAIN, 'testTag', `快捷方式触发: ${action}`);
    }
  }

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    // 1. 设置颜色模式 (保留您原有的逻辑)
    try {
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    } catch (err) {
      hilog.error(DOMAIN, 'testTag', 'Failed to set colorMode. Cause: %{public}s', JSON.stringify(err));
    }
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onCreate');

    // 2. 【新增】处理冷启动时的快捷方式
    this.handleShortcut(want);
  }

  /**
   * 【新增】处理热启动
   * 当应用已经在后台运行时，再次点击图标或快捷方式会触发此生命周期
   */
  onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(DOMAIN, 'testTag', 'Ability onNewWant');
    // 处理热启动时的快捷方式
    this.handleShortcut(want);
  }

  onDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    // Main window is created, set main page for this ability
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageCreate');

    // 注意：请确认您的主页面路径。
    // 如果您前面的 CalendarPage 代码是在 pages/CalendarPage.ets，这里建议改为 'pages/CalendarPage'
    // 如果您的 CalendarPage 组件是在 pages/Index.ets 里引用的，则保持 'pages/Index' 不变。
    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(DOMAIN, 'testTag', 'Succeeded in loading the content.');
    });

    // 请求通知权限 (保留您原有的逻辑)
    notificationManager.requestEnableNotification().then(() => {
      console.info('请求通知权限成功');
    }).catch((err: BusinessError) => {
      console.error(`请求通知权限失败: code ${err.code}, message ${err.message}`);
    });
  }

  onWindowStageDestroy(): void {
    // Main window is destroyed, release UI related resources
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    // Ability has brought to foreground
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onForeground');
  }

  onBackground(): void {
    // Ability has back to background
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onBackground');
  }
}
