// input_screen.dart (変更後)
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../widgets/responsive_layout.dart'; // 作成したレスポンシブレイアウトウィジェット

// --- データモデルクラス ---
// 選択された日付と期間（日単位）を管理するクラス
class SelectedDateEntry {
  DateTime date;
  double duration; // 1.0 または 0.5

  SelectedDateEntry({required this.date, this.duration = 1.0});

  // isSameDay との比較用
  bool isSameDate(DateTime otherDate) {
    return date.year == otherDate.year &&
           date.month == otherDate.month &&
           date.day == otherDate.day;
  }
}

// フォーム全体のデータを管理するクラス
class FormData {
  String name;
  String department;
  String email;
  List<SelectedDateEntry> selectedEntries;
  double totalDuration;
  String remarks; // ★ 新しく追加: 備考欄のためのプロパティ

  FormData({
    this.name = '',
    this.department = '',
    this.email = '',
    List<SelectedDateEntry>? selectedEntries,
    this.totalDuration = 0.0,
    this.remarks = '', // ★ コンストラクタにも追加（デフォルト値も設定）
  }) : this.selectedEntries = selectedEntries ?? [];
}
// --- データモデルクラスここまで ---

class InputScreen extends StatefulWidget {
  @override
  _InputScreenState createState() => _InputScreenState();
}

class _InputScreenState extends State<InputScreen> {
  final _formKey = GlobalKey<FormState>();
  final _formData = FormData(); // FormDataのインスタンス生成時に remarks も初期化される
  List<SelectedDateEntry> _selectedEntries = [];

  double get _calculatedTotalDuration {
    if (_selectedEntries.isEmpty) {
      return 0.0;
    }
    return _selectedEntries.map((entry) => entry.duration).reduce((a, b) => a + b);
  }

  Future<void> _showCalendarDialog() async {
    Set<DateTime> tempSelectedDatesInDialog =
        _selectedEntries.map((entry) => entry.date).toSet();

    DateTime initialDialogFocusedDay;
    if (tempSelectedDatesInDialog.isNotEmpty) {
      List<DateTime> sortedDates = tempSelectedDatesInDialog.toList();
      sortedDates.sort((a, b) => a.compareTo(b));
      initialDialogFocusedDay = sortedDates.last;
    } else {
      initialDialogFocusedDay = DateTime.now();
    }

    final List<DateTime>? result = await showDialog<List<DateTime>>(
      context: context,
      builder: (BuildContext context) {
        DateTime dialogCalendarFocusedDay = initialDialogFocusedDay;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('日付を選択'),
              content: Container(
                width: double.maxFinite,
                child: TableCalendar(
                  locale: 'ja_JP',
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: dialogCalendarFocusedDay,
                  selectedDayPredicate: (day) {
                    return tempSelectedDatesInDialog
                        .any((selectedDay) => isSameDay(selectedDay, day));
                  },
                  onDaySelected: (selectedDay, focusedDayFromCalendar) {
                    setDialogState(() {
                      final dateOnly = DateTime.utc(
                          selectedDay.year, selectedDay.month, selectedDay.day);
                      if (tempSelectedDatesInDialog
                          .any((d) => isSameDay(d, dateOnly))) {
                        tempSelectedDatesInDialog
                            .removeWhere((d) => isSameDay(d, dateOnly));
                      } else {
                        tempSelectedDatesInDialog.add(dateOnly);
                      }
                      dialogCalendarFocusedDay = focusedDayFromCalendar;
                    });
                  },
                  onPageChanged: (focusedDayOnPageChange) {
                    setDialogState(() {
                      dialogCalendarFocusedDay = focusedDayOnPageChange;
                    });
                  },
                  calendarFormat: CalendarFormat.month,
                  headerStyle: HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                  ),
                  calendarBuilders: CalendarBuilders(
                    selectedBuilder: (context, date, events) => Container(
                      margin: const EdgeInsets.all(4.0),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        date.day.toString(),
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    todayBuilder: (context, date, events) => Container( //
                      margin: const EdgeInsets.all(4.0), //
                      alignment: Alignment.center, //
                      decoration: BoxDecoration( //
                        color: null, //
                        shape: BoxShape.circle, //
                      ),
                      child: Text( //
                        date.day.toString(), //
                        style: TextStyle(color: Colors.black), //
                      ),
                    ),
                  ),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text('キャンセル'),
                  onPressed: () {
                    Navigator.of(context).pop(null);
                  },
                ),
                TextButton(
                  child: Text('決定'),
                  onPressed: () {
                    Navigator.of(context)
                        .pop(tempSelectedDatesInDialog.toList()..sort());
                  },
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null) {
      setState(() {
        List<SelectedDateEntry> newEntries = [];
        for (var dateFromDialog in result) {
          var existingEntry = _selectedEntries.firstWhere(
              (entry) => entry.isSameDate(dateFromDialog),
              orElse: () => SelectedDateEntry(
                  date: dateFromDialog, duration: 1.0)
          );
          newEntries.add(existingEntry);
        }
        _selectedEntries = newEntries;
        _selectedEntries.sort((a, b) => a.date.compareTo(b.date));
      });
    }
  }

  void _removeDateEntry(SelectedDateEntry entryToRemove) {
    setState(() {
      _selectedEntries.removeWhere((entry) => entry.date == entryToRemove.date);
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget mainContent = Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: ListView(
            children: <Widget>[
              TextFormField(
                decoration: InputDecoration(labelText: '氏名'),
                validator: (value) {
                  if (value == null || value.isEmpty) return '氏名を入力してください';
                  return null;
                },
                onSaved: (value) => _formData.name = value!,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: '配属先'),
                validator: (value) {
                  if (value == null || value.isEmpty) return '配属先を入力してください';
                  return null;
                },
                onSaved: (value) => _formData.department = value!,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'メールアドレス'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'メールアドレスを入力してください';
                  final emailRegex = RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+");
                  if (!emailRegex.hasMatch(value)) return '有効なメールアドレスを入力してください';
                  return null;
                },
                onSaved: (value) => _formData.email = value!,
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('日付:', style: TextStyle(fontSize: 16)),
                  ElevatedButton(
                    onPressed: _showCalendarDialog,
                    child: Text('カレンダーから選択'),
                  ),
                ],
              ),
              SizedBox(height: 10),
              if (_selectedEntries.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text('選択された日付一覧 (合計: ${_calculatedTotalDuration.toStringAsFixed(1)}日):', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              _selectedEntries.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text('日付が選択されていません'),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(), //
                      itemCount: _selectedEntries.length,
                      itemBuilder: (context, index) {
                        final entry = _selectedEntries[index];
                        final DateFormat formatter = DateFormat('yyyy/MM/dd');
                        return Card(
                          margin: EdgeInsets.symmetric(vertical: 4.0),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                Text(formatter.format(entry.date)),
                                DropdownButton<double>(
                                  value: entry.duration,
                                  dropdownColor: null, //
                                  elevation: 0, //
                                  underline: Container( //
                                    height: 0, //
                                  ),
                                  items: [
                                    DropdownMenuItem(child: Text('1.0日'), value: 1.0),
                                    DropdownMenuItem(child: Text('0.5日'), value: 0.5),
                                  ],
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() {
                                        entry.duration = value;
                                      });
                                    }
                                  },
                                ),
                                IconButton(
                                  icon: Icon(Icons.clear), //
                                  onPressed: () => _removeDateEntry(entry),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
              SizedBox(height: 20), // ★ 備考欄の前に少しスペースを追加

              // ★==== 新しい入力項目（備考欄） ====★
              TextFormField(
                decoration: InputDecoration(
                  labelText: '備考（任意）',
                  hintText: '特記事項があれば入力してください',
                  border: OutlineInputBorder(), // 枠線をつけると入力エリアが分かりやすくなります
                ),
                keyboardType: TextInputType.multiline, // 改行を許可
                maxLines: 3, // 表示される行数の目安（nullにすると入力に応じて高さが伸びます）
                onSaved: (value) => _formData.remarks = value ?? '', // nullの場合は空文字を保存
              ),
              // ★==== ここまで ====★

              SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    _formData.selectedEntries = List.from(_selectedEntries);
                    _formData.totalDuration = _calculatedTotalDuration;

                    if (_formData.selectedEntries.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('日付を1つ以上選択してください')),
                      );
                      return;
                    }
                    Navigator.pushNamed(context, '/confirm', arguments: _formData);
                  }
                },
                child: Text('確認画面へ'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 15.0),
                  textStyle: TextStyle(fontSize: 16)
                ),
              ),
              // ★==== セーフティエリアのための余白 ====★
              SizedBox(height: MediaQuery.of(context).padding.bottom + 30), // 下部のシステムパディング + 追加の余白
            ],
        ),
      ),
    );

    return Scaffold(
      appBar: AppBar(title: Text('入力画面')),
      body: ResponsiveLayout(child: mainContent),
    );
  }
}