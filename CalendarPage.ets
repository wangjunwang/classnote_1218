// entry/src/main/ets/pages/CalendarPage.ets
import { dbHelper, Student, CourseRecord, InspirationRecord, TodoRecord } from '../db/DBHelper';
import { common } from '@kit.AbilityKit';
import { NotificationHelper } from '../utils/NotificationHelper';

// UI层使用的分组接口
interface StudentGroup {
  name: string;        // 分组名称 (作为唯一标识)
  studentIds: number[]; // 包含的学生ID
}

// =======================
// 1. 排课弹窗
// =======================
@CustomDialog
struct AddCourseDialog {
  controller: CustomDialogController
  students: Student[] = []
  groups: StudentGroup[] = []

  confirm: (studentIds: number[], hour: number, minute: number, note: string, groupName?: string) => void = () => {}

  @State selectedStudentIds: number[] = []
  @State note: string = ''

  @State hours: string[] = []
  @State minutes: string[] = []
  @State selectedHour: string = '10'
  @State selectedMinute: string = '00'

  @State currentGroupName: string = ''

  aboutToAppear() {
    for (let i = 0; i < 24; i++) this.hours.push(i.toString().padStart(2, '0'));
    for (let i = 0; i < 60; i++) this.minutes.push(i.toString().padStart(2, '0'));
  }

  toggleStudent(id: number) {
    if (this.selectedStudentIds.includes(id)) {
      this.selectedStudentIds = this.selectedStudentIds.filter(sid => sid !== id);
    } else {
      this.selectedStudentIds.push(id);
    }
    this.checkGroupMatch();
  }

  toggleGroup(group: StudentGroup) {
    if (this.currentGroupName === group.name) {
      this.selectedStudentIds = [];
      this.currentGroupName = '';
    } else {
      this.selectedStudentIds = [...group.studentIds];
      this.currentGroupName = group.name;
    }
  }

  checkGroupMatch() {
    this.currentGroupName = '';
    const matched = this.groups.find(g =>
    g.studentIds.length === this.selectedStudentIds.length &&
    g.studentIds.every(id => this.selectedStudentIds.includes(id))
    );
    if (matched) {
      this.currentGroupName = matched.name;
    }
  }

  getGridHeight(): number {
    if (this.students.length <= 6) return 100;
    else return 180;
  }

  build() {
    Column({ space: 20 }) {
      Text('安排课程').fontSize(20).fontWeight(FontWeight.Bold).margin({ top: 10 }).fontColor($r('app.color.text_primary'))

      if (this.groups.length > 0) {
        Column({ space: 10 }) {
          Text('快捷分组').fontSize(16).fontColor($r('app.color.text_secondary')).width('100%')
          List({ space: 10 }) {
            ForEach(this.groups, (group: StudentGroup) => {
              ListItem() {
                Text(group.name)
                  .fontSize(14)
                  .fontColor(this.currentGroupName === group.name ? Color.White : $r('app.color.picker_selected_blue'))
                  .fontWeight(FontWeight.Medium)
                  .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                  .backgroundColor(this.currentGroupName === group.name ? $r('app.color.picker_selected_blue') : '#E6F2FF')
                  .borderRadius(16)
                  .onClick(() => this.toggleGroup(group))
              }
            })
          }
          .listDirection(Axis.Horizontal)
          .width('100%')
          .height(36)
          .scrollBar(BarState.Off)
        }.width('100%')
      }

      Column({ space: 10 }) {
        Text('选择学生 (可多选)').fontSize(16).fontColor($r('app.color.text_secondary')).width('100%')
        if (this.students.length > 0) {
          Grid() {
            ForEach(this.students, (stu: Student) => {
              GridItem() {
                Text(stu.name)
                  .fontSize(14)
                  .fontColor(this.selectedStudentIds.includes(stu.id) ? Color.White : $r('app.color.text_primary'))
                  .fontWeight(this.selectedStudentIds.includes(stu.id) ? FontWeight.Bold : FontWeight.Normal)
                  .textAlign(TextAlign.Center)
                  .width('100%')
                  .padding({ top: 8, bottom: 8 })
                  .backgroundColor(this.selectedStudentIds.includes(stu.id) ? $r('app.color.picker_selected_blue') : $r('app.color.input_bg'))
                  .borderRadius(8)
                  .onClick(() => this.toggleStudent(stu.id))
              }
            })
          }
          .columnsTemplate('1fr 1fr 1fr')
          .columnsGap(10).rowsGap(10)
          .height(this.getGridHeight())
        } else {
          Text('暂无学生档案，请去【学生】页添加').fontColor(Color.Red).fontSize(16)
        }
      }.width('100%')

      Column({ space: 5 }) {
        Text('上课时间').fontSize(16).fontColor($r('app.color.text_secondary')).width('100%')
        Row() {
          TextPicker({ range: this.hours, selected: parseInt(this.selectedHour) })
            .onChange((value: string | string[]) => { this.selectedHour = value as string })
            .layoutWeight(1)
            .height(55)
            .disappearTextStyle({ color: $r('app.color.picker_disappear_text'), font: { size: 12 } })
            .textStyle({ color: $r('app.color.picker_normal_text'), font: { size: 16 } })
            .selectedTextStyle({ color: $r('app.color.picker_selected_blue'), font: { size: 20, weight: FontWeight.Bold } })
            .canLoop(true)

          Text(':')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .margin({ left: 10, right: 10 })
            .padding({ bottom: 4 })

          TextPicker({ range: this.minutes, selected: parseInt(this.selectedMinute) })
            .onChange((value: string | string[]) => { this.selectedMinute = value as string })
            .layoutWeight(1)
            .height(55)
            .disappearTextStyle({ color: $r('app.color.picker_disappear_text'), font: { size: 12 } })
            .textStyle({ color: $r('app.color.picker_normal_text'), font: { size: 16 } })
            .selectedTextStyle({ color: $r('app.color.picker_selected_blue'), font: { size: 20, weight: FontWeight.Bold } })
            .canLoop(true)
        }.width('100%')
      }.width('100%').margin({ top: 10 })

      TextInput({ placeholder: '课程备注 (选填)', text: this.note })
        .onChange(v => this.note = v)
        .backgroundColor($r('app.color.input_bg')).fontColor($r('app.color.text_primary'))
        .fontSize(16).height(45).borderRadius(8)

      Row({ space: 20 }) {
        Button('取消').backgroundColor($r('app.color.input_bg')).fontColor($r('app.color.text_secondary'))
          .fontSize(16).onClick(() => this.controller.close()).layoutWeight(1)

        Button(`确定 (${this.selectedStudentIds.length})`)
          .backgroundColor($r('app.color.picker_selected_blue'))
          .fontSize(16)
          .onClick(() => {
            if (this.selectedStudentIds.length > 0) {
              this.confirm(
                this.selectedStudentIds,
                parseInt(this.selectedHour),
                parseInt(this.selectedMinute),
                this.note,
                this.currentGroupName
              );
            } else {
              AlertDialog.show({ message: '请至少选择一名学生' })
            }
          }).layoutWeight(1)
      }
      .width('100%')
    }
    .padding(25)
    .backgroundColor($r('app.color.card_bg'))
    .width('100%')
    .borderRadius({
      topLeft: 24,
      topRight: 24,
      bottomLeft: 0,
      bottomRight: 0
    })
  }
}

// =======================
// 2. 灵感弹窗
// =======================
@CustomDialog
struct AddInspirationDialog {
  controller: CustomDialogController
  confirm: (content: string) => void = () => {}
  @State content: string = ''

  build() {
    Column({ space: 20 }) {
      Text('记录灵感').fontSize(20).fontWeight(FontWeight.Bold).margin({ top: 10 }).fontColor($r('app.color.text_primary'))
      TextArea({ placeholder: '写下想法...', text: this.content }).onChange(v => this.content = v)
        .backgroundColor($r('app.color.input_bg')).fontColor($r('app.color.text_primary')).fontSize(16).height(120).borderRadius(8)
      Row({ space: 20 }) {
        Button('取消').backgroundColor($r('app.color.input_bg')).fontColor($r('app.color.text_secondary'))
          .fontSize(16).onClick(() => this.controller.close()).layoutWeight(1)
        Button('保存').backgroundColor('#FF9900')
          .fontSize(16).onClick(() => { if (this.content) { this.confirm(this.content); } }).layoutWeight(1)
      }.width('100%')
    }.padding(25).backgroundColor($r('app.color.card_bg')).borderRadius(16)
  }
}

// =======================
// 3. 待办添加弹窗
// =======================
@CustomDialog
struct AddTodoDialog {
  controller: CustomDialogController
  confirm: (content: string) => void = () => {}
  @State content: string = ''

  build() {
    Column({ space: 20 }) {
      Text('新建待办').fontSize(20).fontWeight(FontWeight.Bold).margin({ top: 10 }).fontColor($r('app.color.text_primary'))
      TextInput({ placeholder: '要做什么？', text: this.content }).onChange(v => this.content = v)
        .backgroundColor($r('app.color.input_bg')).fontColor($r('app.color.text_primary')).fontSize(16).height(50).borderRadius(8)
      Row({ space: 20 }) {
        Button('取消').backgroundColor($r('app.color.input_bg')).fontColor($r('app.color.text_secondary'))
          .fontSize(16).onClick(() => this.controller.close()).layoutWeight(1)
        Button('保存').backgroundColor('#007DFF')
          .fontSize(16).onClick(() => { if (this.content) { this.confirm(this.content); } }).layoutWeight(1)
      }.width('100%')
    }.padding(25).backgroundColor($r('app.color.card_bg')).borderRadius(16)
  }
}

// =======================
// 4. 待办详情页
// =======================
@CustomDialog
struct TodoDetailDialog {
  controller: CustomDialogController
  currentDate: Date = new Date()
  onDataChanged: () => void = () => {}

  @State todos: TodoRecord[] = []
  addTodoCtrl: CustomDialogController | null = null

  async aboutToAppear() {
    await this.refreshLocalData();
  }

  async refreshLocalData() {
    const start = new Date(this.currentDate); start.setHours(0,0,0,0);
    const end = new Date(this.currentDate); end.setHours(23,59,59,999);
    this.todos = await dbHelper.getTodosByDate(start.getTime(), end.getTime());
    this.todos.sort((a, b) => a.isFinished - b.isFinished);
    this.onDataChanged();
  }

  getTitleDate(): string {
    return `${this.currentDate.getMonth() + 1}月${this.currentDate.getDate()}日`;
  }

  openAddTodo() {
    this.addTodoCtrl = new CustomDialogController({
      builder: AddTodoDialog({
        confirm: async (content) => {
          await dbHelper.addTodo(this.currentDate.getTime(), content);
          this.refreshLocalData();
          if (this.addTodoCtrl) this.addTodoCtrl.close();
        }
      }),
      alignment: DialogAlignment.Bottom, offset: { dx: 0, dy: -20 }
    });
    this.addTodoCtrl.open();
  }

  async toggleFinish(todo: TodoRecord) {
    const newStatus = todo.isFinished === 1 ? 0 : 1;
    await dbHelper.updateTodoStatus(todo.id, newStatus);
    this.refreshLocalData();
  }

  async handleDelete(id: number) {
    await dbHelper.deleteTodo(id);
    this.refreshLocalData();
  }

  @Builder SwipeMenu(id: number) {
    Row() {
      Button({ type: ButtonType.Circle }) {
        SymbolGlyph($r('sys.symbol.trash')).fontSize(24).fontColor([Color.White])
      }
      .width(40).height(40).backgroundColor(Color.Red)
      .onClick(() => this.handleDelete(id))
    }.width(60).justifyContent(FlexAlign.Center)
  }

  @Builder AddTodoButton() {
    Button() {
      Row({ space: 0 }) {
        Text('新建').fontSize(14).fontWeight(FontWeight.Bold).fontColor(Color.White)
      }
    }
    .height(36)
    .padding({ left: 12, right: 12 })
    .backgroundColor('#007DFF')
    .borderRadius(18)
    .shadow({ radius: 8, color: '#40007DFF', offsetY: 3 })
    .onClick(() => this.openAddTodo())
  }

  build() {
    Column() {
      Row() {
        Row() {
          Text(this.getTitleDate()).fontSize(24).fontWeight(FontWeight.Bold).fontColor($r('app.color.text_primary'))
          Text(' / 待办事项').fontSize(14).fontColor($r('app.color.text_secondary')).margin({ left: 8, bottom: 2 })
        }.alignItems(VerticalAlign.Bottom)
        Blank()
        this.AddTodoButton()
      }.width('100%').margin({ top: 10, bottom: 20 })

      if (this.todos.length === 0) {
        Column() {
          Text('今天没有待办任务').fontColor($r('app.color.text_secondary')).fontSize(14)
        }
        .width('100%').height(200).justifyContent(FlexAlign.Center)
      } else {
        List({ space: 10 }) {
          ForEach(this.todos, (item: TodoRecord) => {
            ListItem() {
              Row() {
                Stack({ alignContent: Alignment.Center }) {
                  Circle({ width: 24, height: 24 })
                    .fill(item.isFinished ? '#007DFF' : 'transparent')
                    .stroke(item.isFinished ? '#007DFF' : '#007DFF')
                    .strokeWidth(2)
                  if (item.isFinished) {
                    SymbolGlyph($r('sys.symbol.checkmark')).fontSize(14).fontColor([Color.White])
                  }
                }
                .onClick(() => this.toggleFinish(item))
                .margin({ right: 15 })

                Text(item.content)
                  .fontSize(16)
                  .fontColor(item.isFinished ? $r('app.color.text_secondary') : $r('app.color.text_primary'))
                  .decoration({ type: item.isFinished ? TextDecorationType.LineThrough : TextDecorationType.None, color: $r('app.color.text_secondary') })
                  .layoutWeight(1)
                  .maxLines(2)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
              }
              .width('100%').padding(15).backgroundColor($r('app.color.input_bg')).borderRadius(12)
            }
            .swipeAction({ end: this.SwipeMenu(item.id) })
          })
        }
        .width('100%').height(350).scrollBar(BarState.Off)
      }
    }
    .padding(25).backgroundColor($r('app.color.card_bg'))
    .borderRadius({ topLeft: 24, topRight: 24, bottomLeft: 0, bottomRight: 0 }).width('100%')
  }
}

// =======================
// 5. 详情页弹窗 (日程概览)
// =======================
interface DisplayGroup {
  type: 'group';
  date: number;
  records: CourseRecord[];
}

type ScheduleItem = DisplayGroup | InspirationRecord;

@CustomDialog
struct DailyDetailDialog {
  controller: CustomDialogController
  currentDate: Date = new Date()
  onDataChanged: () => void = () => {}

  @State items: ScheduleItem[] = []
  @State allStudents: Student[] = []
  @State allGroups: StudentGroup[] = []

  addCourseCtrl: CustomDialogController | null = null
  addInspCtrl: CustomDialogController | null = null

  async aboutToAppear() {
    this.allStudents = await dbHelper.getStudents();
    this.generateGroupsFromStudents();
    await this.refreshLocalData();
  }

  generateGroupsFromStudents() {
    const groupMap = new Map<string, number[]>();
    this.allStudents.forEach(stu => {
      const gName = stu.groupName || '默认分组';
      if (!groupMap.has(gName)) {
        groupMap.set(gName, []);
      }
      groupMap.get(gName)?.push(stu.id);
    });

    const groups: StudentGroup[] = [];
    if (this.allStudents.length > 1) {
      groups.push({
        name: '全员',
        studentIds: this.allStudents.map(s => s.id)
      });
    }

    groupMap.forEach((ids, name) => {
      if (ids.length > 0) {
        groups.push({ name: name, studentIds: ids });
      }
    });

    this.allGroups = groups;
  }

  async refreshLocalData() {
    const start = new Date(this.currentDate); start.setHours(0,0,0,0);
    const end = new Date(this.currentDate); end.setHours(23,59,59,999);

    const courses = await dbHelper.getCoursesByDate(start.getTime(), end.getTime());
    const insps = await dbHelper.getInspirationsByDate(start.getTime(), end.getTime());

    const groupsMap = new Map<number, CourseRecord[]>();
    courses.forEach(c => {
      if (!groupsMap.has(c.date)) {
        groupsMap.set(c.date, []);
      }
      groupsMap.get(c.date)?.push(c);
    });

    const displayGroups: DisplayGroup[] = [];
    groupsMap.forEach((recs, date) => {
      displayGroups.push({
        type: 'group',
        date: date,
        records: recs
      });
    });

    this.items = [...displayGroups, ...insps].sort((a, b) => a.date - b.date) as ScheduleItem[];
    this.onDataChanged();
  }

  formatTime(timestamp: number): string {
    const d = new Date(timestamp);
    return `${d.getHours().toString().padStart(2, '0')}:${d.getMinutes().toString().padStart(2, '0')}`;
  }

  getTitleDate(): string {
    return `${this.currentDate.getMonth() + 1}月${this.currentDate.getDate()}日`;
  }

  isGroupFinished(group: DisplayGroup): boolean {
    return group.records.every(r => r.isFinished === 1);
  }

  getStudentNames(group: DisplayGroup): string {
    return group.records.map(r => r.studentName).join('、');
  }

  async finishGroup(group: DisplayGroup) {
    for (const record of group.records) {
      if (record.isFinished === 0) {
        await dbHelper.finishCourse(record.id, record.studentId);
      }
    }
    this.refreshLocalData();
  }

  async deleteGroup(group: DisplayGroup) {
    for (const record of group.records) {
      await dbHelper.deleteCourse(record.id);
    }
    this.refreshLocalData();
  }

  async deleteInsp(id: number) {
    await dbHelper.deleteInspiration(id);
    this.refreshLocalData();
  }

  openAddCourse() {
    this.addCourseCtrl = new CustomDialogController({
      builder: AddCourseDialog({
        students: this.allStudents,
        groups: this.allGroups,
        confirm: async (sids, h, m, note, groupName) => {
          const d = new Date(this.currentDate);
          d.setHours(h, m, 0, 0);

          for(const sid of sids) await dbHelper.addCourse(sid, d.getTime(), note);

          let title = '';
          if (groupName && groupName !== '全员' && groupName !== '默认分组') {
            title = groupName;
          } else if (groupName === '全员') {
            title = '全员课程';
          } else {
            const targetStudents = this.allStudents.filter(s => sids.includes(s.id));
            const names = targetStudents.map(s => s.name).join('、');
            title = names ? names : '课程提醒';
          }

          await NotificationHelper.addCourseReminder(title, d.getTime());

          this.refreshLocalData();
          if (this.addCourseCtrl) this.addCourseCtrl.close();
        }
      }),
      alignment: DialogAlignment.Bottom,
      customStyle: true,
      offset: { dx: 0, dy: 0 }
    });
    this.addCourseCtrl.open();
  }

  openAddInsp() {
    this.addInspCtrl = new CustomDialogController({
      builder: AddInspirationDialog({
        confirm: async (content) => {
          const d = new Date(this.currentDate);
          await dbHelper.addInspiration(d.getTime(), content);
          this.refreshLocalData();
          if (this.addInspCtrl) this.addInspCtrl.close();
        }
      }),
      alignment: DialogAlignment.Bottom, offset: { dx: 0, dy: -20 }
    });
    this.addInspCtrl.open();
  }

  @Builder SwipeMenu(item: ScheduleItem) {
    Row() {
      Button({ type: ButtonType.Circle }) {
        SymbolGlyph($r('sys.symbol.trash')).fontSize(24).fontColor([Color.White])
      }
      .width(40).height(40).backgroundColor(Color.Red)
      .onClick(() => {
        if (item.type === 'group') {
          this.deleteGroup(item as DisplayGroup);
        } else {
          this.deleteInsp((item as InspirationRecord).id);
        }
      })
    }
    .width(60).justifyContent(FlexAlign.Center)
  }

  @Builder AddCourseInspButton(title: string, icon: Resource, color: string, action: () => void) {
    Button() {
      Row() {
        SymbolGlyph(icon).fontSize(20).fontColor([color]).margin({ right: 8 });
        Text(title).fontSize(16).fontWeight(FontWeight.Bold).fontColor(color)
      }
    }
    .layoutWeight(1).height(50).backgroundColor($r('app.color.input_bg')).borderRadius(12).onClick(action)
  }

  build() {
    Column() {
      Row() {
        Row() {
          Text(this.getTitleDate()).fontSize(24).fontWeight(FontWeight.Bold).fontColor($r('app.color.text_primary'))
          Text(' / 日程概览').fontSize(14).fontColor($r('app.color.text_secondary')).margin({ left: 8, bottom: 2 })
        }.alignItems(VerticalAlign.Bottom)
        Blank()
        Button('收起').fontSize(12).height(28).backgroundColor('#007DFF').fontColor(Color.White)
          .onClick(() => this.controller.close())
      }.width('100%').margin({ top: 10, bottom: 20 })

      Row({ space: 15 }) {
        this.AddCourseInspButton('排一节课', $r('sys.symbol.calendar'), '#007DFF', (): void => this.openAddCourse())
        this.AddCourseInspButton('记个灵感', $r('sys.symbol.lightbulb'), '#FF9900', (): void => this.openAddInsp())
      }.width('100%').margin({ bottom: 20 })

      if (this.items.length === 0) {
        Column() { Text('暂无安排').fontColor($r('app.color.text_secondary')).fontSize(14) }.width('100%').height(100).justifyContent(FlexAlign.Center)
      } else {
        List({ space: 15 }) {
          ForEach(this.items, (item: ScheduleItem) => {
            ListItem() {
              Row() {
                Divider().vertical(true).height(30)
                  .color(item.type === 'group' ? '#007DFF' : '#FF9900')
                  .strokeWidth(4).lineCap(LineCapStyle.Round).margin({ right: 15 })

                if (item.type === 'group') {
                  Row() {
                    Column() {
                      Text('课程').fontSize(16).fontWeight(FontWeight.Bold).fontColor($r('app.color.text_primary'))
                      Text(this.formatTime(item.date)).fontSize(12).fontColor($r('app.color.text_secondary')).margin({ top: 2 })
                    }.width(60).alignItems(HorizontalAlign.Start)

                    Text(this.getStudentNames(item as DisplayGroup))
                      .fontSize(16).fontWeight(FontWeight.Medium).fontColor($r('app.color.text_primary'))
                      .layoutWeight(1).maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis }).margin({ left: 10, right: 10 })

                    Row() {
                      if (this.isGroupFinished(item as DisplayGroup)) {
                        Text('已消课').fontSize(12).fontColor('#00AA00').backgroundColor('#E0F8E0').padding({left:6, right:6, top:2, bottom:2}).borderRadius(4)
                      } else {
                        Button('消课')
                          .fontSize(12).height(24).padding({ left: 8, right: 8 }).backgroundColor('#007DFF')
                          .onClick(() => this.finishGroup(item as DisplayGroup))
                      }
                    }.flexShrink(0).margin({ left: 0 })
                  }.layoutWeight(1)
                } else {
                  Row() {
                    Column() {
                      Text('灵感笔记').fontSize(16).fontWeight(FontWeight.Bold).fontColor($r('app.color.text_primary'))
                    }.width(80).alignItems(HorizontalAlign.Start)

                    Text((item as InspirationRecord).content)
                      .fontSize(14).fontColor($r('app.color.text_secondary'))
                      .layoutWeight(1).maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis }).margin({ left: 5 })
                  }.layoutWeight(1)
                }
              }
              .width('100%').padding(15).backgroundColor($r('app.color.input_bg')).borderRadius(12)
            }
            .swipeAction({ end: this.SwipeMenu(item) })
          })
        }
        .width('100%').height(300).scrollBar(BarState.Off)
      }
    }
    .padding(25).backgroundColor($r('app.color.card_bg'))
    .borderRadius({ topLeft: 24, topRight: 24, bottomLeft: 0, bottomRight: 0 }).width('100%')
  }
}

// =======================
// 6. 主页面 (主入口)
// =======================
@Component
export struct CalendarPage {
  @State currentYear: number = new Date().getFullYear();
  @State currentMonth: number = new Date().getMonth() + 1;
  @State selectedDay: number = new Date().getDate();
  @State daysInMonth: number[] = [];
  @State startWeekDay: number = 0;
  @State courseMarkers: number[] = [];
  @State inspMarkers: number[] = [];
  @State todayCoursesCount: number = 0;
  @State todayTodosCount: number = 0;

  @StorageProp('AppGlobalUpdate') @Watch('refreshData') updateSignal: number = 0;

  // 👇👇👇【新增】监听快捷方式动作 👇👇👇
  @StorageLink('GlobalShortcutAction') @Watch('onShortcutTrigger') shortcutAction: string = '';

  detailController: CustomDialogController | null = null;
  todoController: CustomDialogController | null = null;

  // 临时存储排课用的 Controller，避免类型错误
  directAddCourseController: CustomDialogController | null = null;

  async aboutToAppear(): Promise<void> {
    let context = getContext(this) as common.UIAbilityContext;
    await dbHelper.initDB(context);
    this.initCalendar();
    this.refreshData();
    // 关键：初始化时检查快捷方式
    this.onShortcutTrigger();
  }

  onPageShow() {
    this.refreshData();
    // 关键：页面显示时检查快捷方式 (热启动)
    this.onShortcutTrigger();
  }

  // 👇👇👇【关键逻辑】处理快捷方式触发 👇👇👇
  async onShortcutTrigger() {
    if (!this.shortcutAction) return;

    // 只有动作为 action_add_course 时才响应 (注意：这里必须匹配 shortcuts_config.json 的 action)
    if (this.shortcutAction === 'action_add_course') {
      console.info('CalendarPage 响应快捷方式: 排一节课');

      // 延迟 200ms，确保 Tab 切换动画完成
      setTimeout(async () => {
        // 1. 获取所有学生数据 (因为 AddCourseDialog 需要数据)
        const students = await dbHelper.getStudents();

        // 2. 生成简单分组
        const groups: StudentGroup[] = [];
        // 简单分组逻辑：按 student.groupName 分组
        const groupMap = new Map<string, number[]>();
        students.forEach(stu => {
          const gName = stu.groupName || '默认分组';
          if (!groupMap.has(gName)) groupMap.set(gName, []);
          groupMap.get(gName)?.push(stu.id);
        });
        if (students.length > 1) {
          groups.push({ name: '全员', studentIds: students.map(s => s.id) });
        }
        groupMap.forEach((ids, name) => {
          if (ids.length > 0) groups.push({ name: name, studentIds: ids });
        });

        // 3. 直接打开排课弹窗 (AddCourseDialog)
        this.directAddCourseController = new CustomDialogController({
          builder: AddCourseDialog({
            students: students,
            groups: groups,
            confirm: async (sids, h, m, note, groupName) => {
              // 排课保存逻辑
              const d = new Date(); // 默认为今天
              d.setHours(h, m, 0, 0);

              for(const sid of sids) await dbHelper.addCourse(sid, d.getTime(), note);

              // 通知逻辑
              let title = '';
              if (groupName && groupName !== '全员' && groupName !== '默认分组') title = groupName;
              else if (groupName === '全员') title = '全员课程';
              else {
                const targetStudents = students.filter(s => sids.includes(s.id));
                const names = targetStudents.map(s => s.name).join('、');
                title = names ? names : '课程提醒';
              }
              await NotificationHelper.addCourseReminder(title, d.getTime());

              // 刷新页面数据
              this.refreshData();
              if (this.directAddCourseController) this.directAddCourseController.close();
            }
          }),
          alignment: DialogAlignment.Bottom,
          customStyle: true,
          offset: { dx: 0, dy: 0 }
        });
        this.directAddCourseController.open();

        // 4. 清空全局动作，防止重复触发
        AppStorage.setOrCreate('GlobalShortcutAction', '');
        this.shortcutAction = ''; // 本地状态也清空

      }, 200);
    }
  }

  initCalendar(): void {
    const date = new Date(this.currentYear, this.currentMonth - 1, 1);
    this.startWeekDay = date.getDay();
    const lastDay = new Date(this.currentYear, this.currentMonth, 0).getDate();
    this.daysInMonth = [];
    for(let i=1; i<=lastDay; i++) this.daysInMonth.push(i);
  }

  async refreshData(): Promise<void> {
    const markers = await dbHelper.getMonthMarkers(this.currentYear, this.currentMonth);
    this.courseMarkers = markers.courses;
    this.inspMarkers = markers.inspirations;

    const selDate = new Date(this.currentYear, this.currentMonth - 1, this.selectedDay);
    const start = new Date(selDate); start.setHours(0,0,0,0);
    const end = new Date(selDate); end.setHours(23,59,59,999);

    const courses = await dbHelper.getCoursesByDate(start.getTime(), end.getTime());
    const insps = await dbHelper.getInspirationsByDate(start.getTime(), end.getTime());
    const todos = await dbHelper.getTodosByDate(start.getTime(), end.getTime());

    this.todayCoursesCount = courses.length + insps.length;
    this.todayTodosCount = todos.filter(t => t.isFinished === 0).length;
  }

  handleMonthChange(year: number, month: number): void {
    this.currentYear = year;
    this.currentMonth = month;
    const lastDayOfNewMonth = new Date(year, month, 0).getDate();
    this.selectedDay = Math.min(this.selectedDay, lastDayOfNewMonth);

    this.initCalendar();
    this.refreshData();
  }

  handlePrevMonth(): void {
    let newYear = this.currentYear;
    let newMonth = this.currentMonth - 1;
    if (newMonth === 0) { newYear--; newMonth = 12; }
    this.handleMonthChange(newYear, newMonth);
  }

  handleNextMonth(): void {
    let newYear = this.currentYear;
    let newMonth = this.currentMonth + 1;
    if (newMonth === 13) { newYear++; newMonth = 1; }
    this.handleMonthChange(newYear, newMonth);
  }

  onDayClick(day: number): void {
    this.selectedDay = day;
    this.refreshData().then(() => {
      this.openDetailDialog();
    });
  }

  openDetailDialog(): void {
    this.detailController = new CustomDialogController({
      builder: DailyDetailDialog({
        currentDate: new Date(this.currentYear, this.currentMonth - 1, this.selectedDay),
        onDataChanged: () => {
          this.refreshData();
        }
      }),
      alignment: DialogAlignment.Bottom,
      customStyle: true,
      autoCancel: true
    });
    this.detailController.open();
  }

  openTodoDialog(): void {
    this.todoController = new CustomDialogController({
      builder: TodoDetailDialog({
        currentDate: new Date(this.currentYear, this.currentMonth - 1, this.selectedDay),
        onDataChanged: () => {
          this.refreshData();
        }
      }),
      alignment: DialogAlignment.Bottom,
      customStyle: true,
      autoCancel: true
    });
    this.todoController.open();
  }

  @Builder OverviewCard() {
    Row() {
      Column() {
        Text('今日概览').fontSize(18).fontWeight(FontWeight.Bold).fontColor('#007DFF')
        Text(`${this.todayCoursesCount} 项日程`).fontSize(14).fontColor($r('app.color.text_primary')).margin({ top: 5 })
      }.alignItems(HorizontalAlign.Start)
      Blank()
      SymbolGlyph($r('sys.symbol.calendar')).fontSize(32).fontColor(['#007DFF'])
    }.width('100%').padding(20).backgroundColor($r('app.color.card_bg')).borderRadius(20)
    .onClick(() => {
      const today = new Date().getDate();
      this.selectedDay = today;
      this.openDetailDialog();
    })
  }

  @Builder TodoCard() {
    Row() {
      Column() {
        Text('今日待办').fontSize(18).fontWeight(FontWeight.Bold).fontColor('#007DFF')
        Text(`${this.todayTodosCount} 个未完成`).fontSize(14).fontColor($r('app.color.text_primary')).margin({ top: 5 })
      }.alignItems(HorizontalAlign.Start)
      Blank()
      SymbolGlyph($r('sys.symbol.doc_plaintext')).fontSize(32).fontColor(['#007DFF'])
    }.width('100%').padding(20).backgroundColor($r('app.color.card_bg')).borderRadius(20)
    .onClick(() => { this.openTodoDialog(); })
  }

  build() {
    Column() {
      Text("课时记").fontSize(24).fontWeight(FontWeight.Bold).width('100%').textAlign(TextAlign.Center) .padding({ top: 56, bottom: 10 }).fontColor($r('app.color.text_primary')).backgroundColor($r('app.color.page_bg'))

      Scroll() {
        Column({ space: 15 }) {
          // 1. 日历卡片
          Column() {
            Row() {
              SymbolGlyph($r('sys.symbol.chevron_left')).fontSize(20).fontColor([$r('app.color.text_secondary')]).onClick(() => this.handlePrevMonth()).padding(10)
              Text(`${this.currentYear}年 ${this.currentMonth}月`).fontSize(18).fontWeight(FontWeight.Bold).fontColor($r('app.color.text_primary')).margin({ left: 10, right: 10 })
              SymbolGlyph($r('sys.symbol.chevron_right')).fontSize(20).fontColor([$r('app.color.text_secondary')]).onClick(() => this.handleNextMonth()).padding(10)
            }.width('100%').justifyContent(FlexAlign.Center).margin({ bottom: 15 })

            Row() {
              ForEach(['日','一','二','三','四','五','六'], (d: string) => {
                Text(d).fontSize(14).fontColor($r('app.color.text_secondary')).textAlign(TextAlign.Center).layoutWeight(1)
              })
            }.width('100%').margin({ bottom: 10 })

            Grid() {
              ForEach(Array(this.startWeekDay).fill(0), () => { GridItem() })
              ForEach(this.daysInMonth, (day: number) => {
                GridItem() {
                  Column() {
                    Text(day.toString())
                      .fontSize(16).fontWeight(this.selectedDay === day ? FontWeight.Bold : FontWeight.Normal)
                      .fontColor(this.selectedDay === day ? Color.White : $r('app.color.text_primary'))
                      .width(36).height(36).textAlign(TextAlign.Center)
                      .backgroundColor(this.selectedDay === day ? '#007DFF' : 'transparent').borderRadius(18)
                    Row({ space: 3 }) {
                      if (this.courseMarkers.includes(day)) Circle({ width: 4, height: 4 }).fill('#007DFF')
                      if (this.inspMarkers.includes(day)) Circle({ width: 4, height: 4 }).fill('#FF9900')
                    }.margin({ top: 4 }).height(4)
                  }.width('100%').height(50).justifyContent(FlexAlign.Start).onClick(() => this.onDayClick(day))
                }
              })
            }.columnsTemplate('1fr 1fr 1fr 1fr 1fr 1fr 1fr').rowsGap(5).height(300)
          }
          .width('100%').padding(15).backgroundColor($r('app.color.card_bg')).borderRadius(24)

          // 2. 今日概览卡片
          this.OverviewCard()

          // 3. 今日待办卡片
          this.TodoCard()

        }.padding({ left: 15, right: 15, bottom: 20 })
      }.scrollBar(BarState.Off).align(Alignment.Top).height('100%')
    }.width('100%').height('100%').backgroundColor($r('app.color.page_bg'))
  }
}
