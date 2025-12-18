// entry/src/main/ets/pages/StudentPage.ets
import { dbHelper, Student, CourseRecord } from '../db/DBHelper';
import { common } from '@kit.AbilityKit';
import { promptAction } from '@kit.ArkUI';
import fs from '@ohos.file.fs';
import picker from '@ohos.file.picker';
import { systemShare } from '@kit.ShareKit';
import { uniformTypeDescriptor } from '@kit.ArkData';
import fileUri from '@ohos.file.fileuri';
import { motion } from '@kit.MultimodalAwarenessKit';
import { curves } from '@kit.ArkUI';

// 分组数据接口
interface GroupInfo {
  name: string;
  count: number;
}

// =======================
// [自定义组件] 学生列表项卡片
// =======================
@Component
struct StudentItemCard {
  @Prop student: Student

  onHistoryClick: () => void = () => {}
  onTopUpClick: () => void = () => {}
  onDeleteClick: () => void = () => {}

  // 侧滑菜单：圆形删除按钮
  @Builder SwipeMenu() {
    Row() {
      Button({ type: ButtonType.Circle }) {
        SymbolGlyph($r('sys.symbol.trash'))
          .fontSize(22)
          .fontColor([Color.White])
      }
      .width(44)
      .height(44)
      .backgroundColor(Color.Red)
      .shadow({ radius: 5, color: '#20FF0000', offsetY: 2 })
      .onClick(() => {
        this.onDeleteClick()
      })
    }
    .width(80)
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }

  build() {
    ListItem() {
      Row() {
        // --- 左侧内容 ---
        Row() {
          Text(this.student.name.substring(0, 1))
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
            .width(40)
            .height(40)
            .textAlign(TextAlign.Center)
            .backgroundColor('#007DFF')
            .borderRadius(20)
            .margin({ right: 15 })

          Column() {
            Text(this.student.name)
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.text_primary'))
            Text(`剩余: ${this.student.totalCredits - this.student.usedCredits} 课时`)
              .fontSize(12)
              .fontColor($r('app.color.text_secondary'))
              .margin({ top: 4 })
          }.alignItems(HorizontalAlign.Start)
        }
        .layoutWeight(1)
        .onClick(() => { this.onHistoryClick() })

        // --- 右侧充值按钮 ---
        Text('充值')
          .fontSize(12)
          .fontWeight(FontWeight.Medium)
          .fontColor(Color.White)
          .backgroundColor('#007DFF')
          .padding({ left: 10, right: 10, top: 4, bottom: 4 })
          .borderRadius(12)
          .margin({ left: 10 })
          .onClick(() => { this.onTopUpClick() })
          .stateStyles({
            pressed: { .opacity(0.7).scale({ x: 0.95, y: 0.95 }) },
            normal: { .opacity(1.0).scale({ x: 1.0, y: 1.0 }) }
          })
      }
      .width('100%')
      .padding(15)
      .backgroundColor($r('app.color.card_bg'))
      .borderRadius(16)
    }
    .swipeAction({ end: this.SwipeMenu() })
    .width('100%')
  }
}

// =======================
// 导出弹窗
// =======================
@CustomDialog
struct ExportPanel {
  controller: CustomDialogController
  onSelect: (type: 'save' | 'share') => void = () => {}
  build() {
    Column() {
      Text('选择导出方式').fontSize(18).fontWeight(FontWeight.Bold).fontColor($r('app.color.text_primary')).margin({ top: 15, bottom: 20 })
      Row() {
        SymbolGlyph($r('sys.symbol.save')).fontSize(24).fontColor(['#007DFF']).margin({ right: 15 })
        Column() {
          Text('保存到文件').fontSize(16).fontColor($r('app.color.text_primary')).fontWeight(FontWeight.Medium)
          Text('存储到手机目录，可连接电脑查看').fontSize(12).fontColor($r('app.color.text_secondary')).margin({ top: 2 })
        }.alignItems(HorizontalAlign.Start).layoutWeight(1)
        SymbolGlyph($r('sys.symbol.chevron_right')).fontSize(20).fontColor([$r('app.color.text_secondary')])
      }
      .width('100%').padding(15).backgroundColor($r('app.color.input_bg')).borderRadius(12)
      .onClick(() => { this.onSelect('save'); if(this.controller) this.controller.close(); })
      Row() {
        SymbolGlyph($r('sys.symbol.paperplane')).fontSize(24).fontColor(['#00AA00']).margin({ right: 15 })
        Column() {
          Text('发送给好友').fontSize(16).fontColor($r('app.color.text_primary')).fontWeight(FontWeight.Medium)
          Text('通过微信、QQ、华为分享发送').fontSize(12).fontColor($r('app.color.text_secondary')).margin({ top: 2 })
        }.alignItems(HorizontalAlign.Start).layoutWeight(1)
        SymbolGlyph($r('sys.symbol.chevron_right')).fontSize(20).fontColor([$r('app.color.text_secondary')])
      }
      .width('100%').padding(15).margin({ top: 10 }).backgroundColor($r('app.color.input_bg')).borderRadius(12)
      .onClick(() => { this.onSelect('share'); if(this.controller) this.controller.close(); })
      Button('取消').width('100%').height(45).fontSize(16).backgroundColor(Color.Transparent).fontColor($r('app.color.text_secondary')).margin({ top: 15 })
        .onClick(() => { if(this.controller) this.controller.close() })
    }.padding(20).backgroundColor($r('app.color.card_bg')).borderRadius({ topLeft: 24, topRight: 24, bottomLeft: 0, bottomRight: 0 }).width('100%')
  }
}

// =======================
// 添加学生弹窗
// =======================
@CustomDialog
struct AddStudentDialog {
  controller: CustomDialogController
  confirm: (name: string, credits: number, groupName: string) => void = () => {}
  @State name: string = ''
  @State credits: string = ''
  @State groupName: string = ''

  build() {
    Column() {
      Text('新学生档案').fontSize(20).fontWeight(FontWeight.Bold).fontColor($r('app.color.text_primary')).width('100%').textAlign(TextAlign.Start).margin({ top: 10, bottom: 20 })

      Row() {
        SymbolGlyph($r('sys.symbol.person')).fontSize(24).fontColor(['#007DFF']).margin({ right: 15 })
        TextInput({ placeholder: '输入学生姓名', text: this.name }).onChange(v => this.name = v).layoutWeight(1).backgroundColor(Color.Transparent).height(40)
      }.padding(15).backgroundColor($r('app.color.input_bg')).borderRadius(12).width('100%')

      Row() {
        SymbolGlyph($r('sys.symbol.folder')).fontSize(24).fontColor(['#9900FF']).margin({ right: 15 })
        TextInput({ placeholder: '分组名称 (例如: 钢琴班)', text: this.groupName }).onChange(v => this.groupName = v).layoutWeight(1).backgroundColor(Color.Transparent).height(40)
      }.padding(15).margin({ top: 10 }).backgroundColor($r('app.color.input_bg')).borderRadius(12).width('100%')

      Row() {
        SymbolGlyph($r('sys.symbol.clock')).fontSize(24).fontColor(['#FF9900']).margin({ right: 15 })
        TextInput({ placeholder: '初始课时 (默认为0)', text: this.credits }).type(InputType.Number).onChange(v => this.credits = v).layoutWeight(1).backgroundColor(Color.Transparent).height(40)
      }.padding(15).margin({ top: 10 }).backgroundColor($r('app.color.input_bg')).borderRadius(12).width('100%')

      Row({ space: 15 }) {
        Button('取消').layoutWeight(1).backgroundColor($r('app.color.input_bg')).fontColor($r('app.color.text_secondary')).onClick(() => { if(this.controller) this.controller.close() })
        Button('保存档案').layoutWeight(2).backgroundColor('#007DFF').onClick(() => {
          if (this.name) {
            const val = this.credits ? parseInt(this.credits) : 0;
            const group = this.groupName.trim() ? this.groupName.trim() : '默认分组';
            this.confirm(this.name, val, group);
            if(this.controller) this.controller.close();
          }
        })
      }.width('100%').margin({ top: 25 })
    }.padding(25).backgroundColor($r('app.color.card_bg')).borderRadius({ topLeft: 24, topRight: 24, bottomLeft: 0, bottomRight: 0 }).width('100%')
  }
}

// =======================
// 充值弹窗
// =======================
@CustomDialog
struct TopUpDialog {
  controller: CustomDialogController
  studentName: string = ''
  confirm: (amount: number) => void = () => {}
  @State amount: string = ''
  build() {
    Column() {
      Text(`课时充值`).fontSize(20).fontWeight(FontWeight.Bold).fontColor($r('app.color.text_primary')).width('100%').textAlign(TextAlign.Start).margin({ top: 10, bottom: 5 })
      Text(`为 ${this.studentName} 增加课时`).fontSize(14).fontColor($r('app.color.text_secondary')).width('100%').textAlign(TextAlign.Start).margin({ bottom: 20 })
      Row() {
        SymbolGlyph($r('sys.symbol.plus_circle')).fontSize(24).fontColor(['#00AA00']).margin({ right: 15 })
        TextInput({ placeholder: '输入充值数量', text: this.amount }).type(InputType.Number).onChange(v => this.amount = v).layoutWeight(1).backgroundColor(Color.Transparent).height(40)
      }.padding(15).backgroundColor($r('app.color.input_bg')).borderRadius(12).width('100%')
      Row({ space: 15 }) {
        Button('取消').layoutWeight(1).backgroundColor($r('app.color.input_bg')).fontColor($r('app.color.text_secondary')).onClick(() => { if(this.controller) this.controller.close() })
        Button('确认充值').layoutWeight(2).backgroundColor('#007DFF').onClick(() => {
          const val = parseInt(this.amount);
          if (val > 0) {
            this.confirm(val);
            if(this.controller) this.controller.close();
          }
        })
      }.width('100%').margin({ top: 25 })
    }.padding(25).backgroundColor($r('app.color.card_bg')).borderRadius({ topLeft: 24, topRight: 24, bottomLeft: 0, bottomRight: 0 }).width('100%')
  }
}

// =======================
// 历史记录弹窗
// =======================
@CustomDialog
struct HistoryDialog {
  controller: CustomDialogController
  studentId: number = 0
  studentName: string = ''
  totalCredits: number = 0
  usedCredits: number = 0
  @State records: CourseRecord[] = []
  exportController: CustomDialogController | null = null

  async aboutToAppear() {
    this.records = await dbHelper.getStudentCourses(this.studentId);
  }

  formatTime(timestamp: number): string {
    const d = new Date(timestamp);
    return `${d.getFullYear()}/${d.getMonth()+1}/${d.getDate()} ${d.getHours().toString().padStart(2,'0')}:${d.getMinutes().toString().padStart(2,'0')}`;
  }

  generateCSVContent(): string {
    let content = '\uFEFF';
    const remaining = this.totalCredits - this.usedCredits;
    content += `学生姓名,${this.studentName}\n`;
    content += `总充值课时,${this.totalCredits}\n`;
    content += `已消耗课时,${this.usedCredits}\n`;
    content += `剩余课时,${remaining}\n`;
    content += `导出时间,${new Date().toLocaleString()}\n`;
    content += `\n日期时间,课程状态,备注说明\n`;

    this.records.forEach(r => {
      const time = this.formatTime(r.date);
      const status = r.isFinished ? '已消课' : '待消课';
      const note = (r.note || '').replace(/,/g, '，').replace(/\n/g, ' ');
      content += `${time},${status},${note}\n`;
    });
    return content;
  }

  openExportPanel() {
    if (this.records.length === 0) { try { promptAction.showToast({ message: '暂无数据可导出' }); } catch(e) {} return; }

    this.exportController = new CustomDialogController({
      builder: ExportPanel({
        onSelect: async (type) => {
          const csvContent = this.generateCSVContent();
          if (type === 'save') await this.saveToLocalDevice(csvContent);
          else await this.shareToSystem(csvContent);
        }
      }),
      alignment: DialogAlignment.Bottom,
      customStyle: true,
      autoCancel: true
    });
    this.exportController.open();
  }

  async saveToLocalDevice(content: string) {
    try {
      const saveOptions = new picker.DocumentSaveOptions();
      saveOptions.newFileNames = [`${this.studentName}_记录_${Date.now()}.csv`];
      const documentViewPicker = new picker.DocumentViewPicker();
      const documentSaveResult = await documentViewPicker.save(saveOptions);

      if (documentSaveResult && documentSaveResult.length > 0) {
        const uri = documentSaveResult[0];
        const file = fs.openSync(uri, fs.OpenMode.WRITE_ONLY | fs.OpenMode.CREATE | fs.OpenMode.TRUNC);
        fs.writeSync(file.fd, content);
        fs.closeSync(file);
        promptAction.showToast({ message: '保存成功' });
      }
    } catch (error) {
      try { promptAction.showToast({ message: '保存取消或失败' }); } catch(e) {}
    }
  }

  async shareToSystem(content: string) {
    try {
      let context = getContext(this) as common.UIAbilityContext;
      const fileName = `${this.studentName}_记录.csv`;
      const filePath = `${context.cacheDir}/${fileName}`;
      const file = fs.openSync(filePath, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE | fs.OpenMode.TRUNC);
      fs.writeSync(file.fd, content);
      fs.closeSync(file);

      const uri = fileUri.getUriFromPath(filePath);
      const sharedData = new systemShare.SharedData({
        utd: uniformTypeDescriptor.UniformDataType.FILE,
        uri: uri,
        title: fileName,
        content: content
      });
      sharedData.addRecord({ utd: uniformTypeDescriptor.UniformDataType.FILE, uri: uri, title: fileName });

      const controller = new systemShare.ShareController(sharedData);
      const options: systemShare.ShareControllerOptions = { previewMode: 0, selectionMode: 0 };
      await controller.show(context, options);
    } catch (error) {
      try { promptAction.showToast({ message: '分享调起失败' }); } catch(e) {}
    }
  }

  build() {
    Column() {
      Row() {
        Text(`${this.studentName} 的记录`).fontSize(20).fontWeight(FontWeight.Bold).fontColor($r('app.color.text_primary'))
        Blank()
        Button({ type: ButtonType.Circle }) {
          SymbolGlyph($r('sys.symbol.share')).fontSize(20).fontColor(['#007DFF'])
        }
        .width(36).height(36).backgroundColor($r('app.color.input_bg')).margin({ right: 10 })
        .onClick(() => this.openExportPanel())
        Button({ type: ButtonType.Circle }) {
          SymbolGlyph($r('sys.symbol.xmark')).fontSize(20).fontColor([$r('app.color.text_secondary')])
        }
        .width(36).height(36).backgroundColor($r('app.color.input_bg'))
        .onClick(() => { if(this.controller) this.controller.close() })
      }.width('100%').margin({ top: 10, bottom: 20 })

      if (this.records.length === 0) {
        Column() { Text('暂无上课记录').fontColor($r('app.color.text_secondary')).fontSize(14) }.width('100%').height(150).justifyContent(FlexAlign.Center)
      } else {
        List({ space: 10 }) {
          ForEach(this.records, (item: CourseRecord) => {
            ListItem() {
              Row() {
                Column() {
                  Text(this.formatTime(item.date)).fontSize(14).fontColor($r('app.color.text_primary')).fontWeight(FontWeight.Medium);
                  if(item.note){
                    Text(item.note).fontSize(12).fontColor($r('app.color.text_secondary')).margin({ top: 4 })
                  }
                }.alignItems(HorizontalAlign.Start).layoutWeight(1);

                if (item.isFinished) {
                  Text('已消课').fontSize(12).fontColor('#00AA00').backgroundColor('#E0F8E0').padding({left:6, right:6, top:2, bottom:2}).borderRadius(4)
                } else {
                  Text('待消课').fontSize(12).fontColor('#FF9900').backgroundColor('#FFF4E0').padding({left:6, right:6, top:2, bottom:2}).borderRadius(4)
                }
              }.width('100%').padding(15).backgroundColor($r('app.color.input_bg')).borderRadius(8)
            }
          })
        }.width('100%').height(300).scrollBar(BarState.Off)
      }
    }.padding(25).backgroundColor($r('app.color.card_bg')).borderRadius(16)
  }
}

// =======================
// 学生管理主页面
// =======================
@Entry
@Component
export struct StudentPage {
  @State allStudents: Student[] = []     // 原始数据
  @State groupList: GroupInfo[] = []     // 分组数据
  @State selectedGroup: string | null = null

  @State floatingButtonScale: number = 1.0;
  @StorageProp('AppGlobalUpdate') @Watch('refreshData') updateSignal: number = 0;

  // 👇👇👇【新增】监听快捷方式动作 👇👇👇
  @StorageLink('GlobalShortcutAction') @Watch('onShortcutTrigger') shortcutAction: string = '';

  addController: CustomDialogController | null = null
  topUpController: CustomDialogController | null = null
  historyController: CustomDialogController | null = null

  // 握持状态相关
  @State isRightHand: boolean = true
  @State opacityValue: number = 1;
  @State offsetX: number = 0;
  private motionTimerId: number = -1;
  private readonly DEBOUNCE_DELAY: number = 200; // 防抖延迟

  async aboutToAppear() {
    let context = getContext(this) as common.UIAbilityContext;
    await dbHelper.initDB(context);
    this.refreshData();
    // 启动 Motion 监听
    this.startMotion();
    this.onShortcutTrigger();
  }

  // 销毁监听
  aboutToDisappear() {
    this.stopMotion();
  }

  onPageShow() { this.refreshData();this.onShortcutTrigger(); }

  // 👇👇👇【新增】处理快捷方式触发：打开添加学生弹窗 👇👇👇
  onShortcutTrigger() {
    if (this.shortcutAction === 'action_add_student') {
      console.info('StudentPage 响应快捷方式: 打开添加学生弹窗');

      // 延迟 100ms，等待 Index 页面切换动画完成
      setTimeout(() => {
        // 打开弹窗
        this.openAddStudent();

        // 立即清空动作，防止重复触发
        this.shortcutAction = '';
        AppStorage.setOrCreate('GlobalShortcutAction', '');
      }, 200);
    }
  }

  // ==========================================
  // 核心功能：监听握持姿势 (防抖 + 弹簧动画)
  // ==========================================
  startMotion() {
    try {
      motion.on('holdingHandChanged', (data: number) => {
        // data=2 视为右手布局
        let targetIsRightHand: boolean = (data === 2);

        if (targetIsRightHand !== this.isRightHand) {

          if (this.motionTimerId !== -1) {
            clearTimeout(this.motionTimerId);
          }

          this.motionTimerId = setTimeout(() => {
            let exitOffsetX = this.isRightHand ? 200 : -200;

            // 1. 滑出
            animateTo({ duration: 250, curve: Curve.EaseIn, onFinish: () => {

              this.isRightHand = targetIsRightHand;
              this.offsetX = targetIsRightHand ? 200 : -200;

              // 2. 滑入 (弹簧效果)
              animateTo({
                curve: curves.springCurve(0, 1, 228, 30)
              }, () => {
                this.offsetX = 0;
                this.opacityValue = 1;
              });

            } }, () => {
              this.offsetX = exitOffsetX;
              this.opacityValue = 0;
            });

            this.motionTimerId = -1;

          }, this.DEBOUNCE_DELAY);

        } else {
          if (this.motionTimerId !== -1) {
            clearTimeout(this.motionTimerId);
            this.motionTimerId = -1;
          }
        }
      });
    } catch (err) {
      console.error('Motion 监听失败: ' + JSON.stringify(err));
    }
  }

  stopMotion() {
    try {
      motion.off('holdingHandChanged');
      if (this.motionTimerId !== -1) {
        clearTimeout(this.motionTimerId);
      }
    } catch (err) {}
  }
  // ==========================================

  processGroups() {
    const groups: Map<string, number> = new Map();
    this.allStudents.forEach(stu => {
      const gName = stu.groupName || '默认分组';
      const count = groups.get(gName) || 0;
      groups.set(gName, count + 1);
    });

    const result: GroupInfo[] = [];
    groups.forEach((count, name) => {
      result.push({ name: name, count: count });
    });

    this.groupList = result.sort((a, b) => a.name.localeCompare(b.name));
  }

  async refreshData() {
    this.allStudents = await dbHelper.getStudents();
    this.processGroups();
  }

  openAddStudent() {
    this.addController = new CustomDialogController({
      builder: AddStudentDialog({
        confirm: async (name, credits, groupName) => {
          await dbHelper.addStudent(name, credits, groupName);
          this.refreshData();
        }
      }),
      alignment: DialogAlignment.Bottom,
      customStyle: true,
      autoCancel: true
    });
    this.addController.open();
  }

  openTopUp(stu: Student) {
    this.topUpController = new CustomDialogController({
      builder: TopUpDialog({
        studentName: stu.name,
        confirm: async (amount) => {
          await dbHelper.topUpCredits(stu.id, amount);
          this.refreshData();
        }
      }),
      alignment: DialogAlignment.Bottom,
      customStyle: true,
      autoCancel: true
    });
    this.topUpController.open();
  }

  openHistory(stu: Student) {
    this.historyController = new CustomDialogController({
      builder: HistoryDialog({
        studentId: stu.id,
        studentName: stu.name,
        totalCredits: stu.totalCredits,
        usedCredits: stu.usedCredits
      }),
      alignment: DialogAlignment.Bottom,
      customStyle: true,
      autoCancel: true
    });
    this.historyController.open();
  }

  async deleteStudent(id: number) {
    await dbHelper.deleteStudent(id);
    this.refreshData();
  }

  @Builder GroupCardItem(group: GroupInfo) {
    ListItem() {
      Row() {
        Row() {
          SymbolGlyph($r('sys.symbol.folder_fill'))
            .fontSize(22)
            .fontColor(['#007DFF'])
        }
        .width(40).height(40)
        .backgroundColor('#E6F2FF')
        .borderRadius(12)
        .justifyContent(FlexAlign.Center)
        .margin({ right: 15 })

        Column() {
          Text(group.name)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.text_primary'))
          Text(`${group.count} 名学生`)
            .fontSize(12)
            .fontColor($r('app.color.text_secondary'))
            .margin({ top: 4 })
        }.alignItems(HorizontalAlign.Start).layoutWeight(1)

        SymbolGlyph($r('sys.symbol.chevron_right'))
          .fontSize(20)
          .fontColor([$r('app.color.text_secondary')])
      }
      .width('100%')
      .padding(15)
      .backgroundColor($r('app.color.card_bg'))
      .borderRadius(16)
      .onClick(() => {
        animateTo({ duration: 300, curve: Curve.EaseOut }, () => {
          this.selectedGroup = group.name;
        })
      })
    }.margin({ bottom: 10 })
  }

  build() {
    Column() {
      // 标题栏
      Row() {
        if (this.selectedGroup !== null) {
          Button({ type: ButtonType.Circle }) {
            SymbolGlyph($r('sys.symbol.chevron_left'))
              .fontSize(24)
              .fontColor([$r('app.color.text_primary')])
          }
          .backgroundColor(Color.Transparent)
          .width(40).height(40)
          .margin({ right: 5 })
          .onClick(() => {
            animateTo({ duration: 300, curve: Curve.EaseOut }, () => {
              this.selectedGroup = null;
            })
          })
        }

        Text(this.selectedGroup ? this.selectedGroup : "学生档案")
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
          .layoutWeight(1)
          .textAlign(this.selectedGroup ? TextAlign.Start : TextAlign.Center)
      }
      .width('100%')
      .padding({ top: 56, bottom: 10, left: 15, right: 15 })
      .backgroundColor($r('app.color.page_bg'))

      // 内容区域
      if (this.allStudents.length === 0) {
        Column() {
          SymbolGlyph($r('sys.symbol.person_crop_circle_fill_1')).fontSize(50).fontColor([$r('app.color.text_secondary')]);
          Text('还没有学生，快去添加吧').fontSize(14).fontColor($r('app.color.text_secondary')).margin({ top: 10 })
        }.width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
      }
      else if (this.selectedGroup === null) {
        // 分组视图
        List({ space: 0 }) {
          ForEach(this.groupList, (group: GroupInfo) => {
            this.GroupCardItem(group)
          })
          ListItem().height(80)
        }
        .width('100%').layoutWeight(1)
        .padding({ left: 15, right: 15 })
        .scrollBar(BarState.Off)
        .transition(TransitionEffect.OPACITY.animation({ duration: 300 }))
      }
      else {
        // 学生列表视图
        List({ space: 10 }) {
          ForEach(
            this.allStudents.filter(s => (s.groupName || '默认分组') === this.selectedGroup),
            (stu: Student) => {
              StudentItemCard({
                student: stu,
                onHistoryClick: () => { this.openHistory(stu) },
                onTopUpClick: () => { this.openTopUp(stu) },
                onDeleteClick: () => { this.deleteStudent(stu.id) }
              })
            },
            (stu: Student) => stu.id.toString()
          )
          ListItem().height(80)
        }
        .width('100%').layoutWeight(1)
        .padding({ left: 15, right: 15 })
        .scrollBar(BarState.Off)
        .transition(TransitionEffect.move(TransitionEdge.END).animation({ duration: 300 }))
      }

      // 悬浮按钮 (动态跟随 + 80% 高度 + 弹簧动画)
      Row() {
        Button() {
          Row() {
            SymbolGlyph($r('sys.symbol.person_crop_circle_fill_1')).fontSize(24).fontColor([Color.White]).margin({ right: 8 });
            Text('添加学生').fontSize(16).fontWeight(FontWeight.Bold).fontColor(Color.White)
          }
        }
        .height(50).padding({ left: 20, right: 20 }).backgroundColor('#007DFF').borderRadius(25).shadow({ radius: 10, color: '#40007DFF', offsetY: 5 })
        .onClick(() => this.openAddStudent())
        .stateStyles({
          pressed: { .scale({ x: 0.95, y: 0.95 }) },
          normal: { .scale({ x: 1.0, y: 1.0 }) }
        })
      }
      .width('100%')
      // 设置位置为 80%
      .position({ x: 0, y: '80%' })
      // 动态左右对齐
      .justifyContent(this.isRightHand ? FlexAlign.End : FlexAlign.Start)
      // 统一内边距
      .padding({ left: 20, right: 20 })
      // 动画属性
      .translate({ x: this.offsetX })
      .opacity(this.opacityValue)
      .hitTestBehavior(HitTestMode.Transparent)

    }.width('100%').height('100%').backgroundColor($r('app.color.page_bg'))
  }
}
