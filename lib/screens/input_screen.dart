// lib/screens/input_screen.dart (最終修正版)

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../widgets/responsive_layout.dart';

// --- データモデルクラス (変更なし) ---
class SelectedDateEntry {
  DateTime date;
  double duration;

  SelectedDateEntry({required this.date, this.duration = 1.0});

  bool isSameDate(DateTime otherDate) {
    return date.year == otherDate.year &&
        date.month == otherDate.month &&
        date.day == otherDate.day;
  }
}

class FormData {
  String name;
  String department;
  String email;
  List<SelectedDateEntry> selectedEntries;
  double totalDuration;
  String remarks;

  FormData({
    this.name = '',
    this.department = '',
    this.email = '',
    List<SelectedDateEntry>? selectedEntries,
    this.totalDuration = 0.0,
    this.remarks = '',
  }) : selectedEntries = selectedEntries ?? [];
}
// --- データモデルクラスここまで ---

class InputScreen extends StatefulWidget {
  const InputScreen({super.key});
  @override
  InputScreenState createState() => InputScreenState();
}

class InputScreenState extends State<InputScreen> {
  final _formKey = GlobalKey<FormState>();
  final _formData = FormData();
  List<SelectedDateEntry> _selectedEntries = [];

  final _emailController = TextEditingController();

  // ★★★ 変更箇所 ★★★
  // didChangeDependencies全体を、より堅牢なロジックに置き換え
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // このメソッドは複数回呼ばれる可能性があるため、最初の1回だけ実行するようにする
    // また、setStateを安全に呼び出すために一手間加える
    
    // 現在のフレームの描画が終わった直後に実行するスケジュールを組む
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Navigatorから渡された引数を取得
      final verifiedEmail = ModalRoute.of(context)?.settings.arguments as String?;

      // Eメールが渡されており、かつ現在の表示と異なる場合のみ更新
      if (verifiedEmail != null && _emailController.text != verifiedEmail) {
        
        // setStateを呼び出して、フレームワークに再描画を依頼する
        setState(() {
          print('InputScreen: Eメールを受信しました -> $verifiedEmail'); // デバッグ用出力
          _emailController.text = verifiedEmail;
          _formData.email = verifiedEmail;
        });
      }
    });
  }
  
  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  double get _calculatedTotalDuration {
    // (変更なし)
    if (_selectedEntries.isEmpty) {
      return 0.0;
    }
    return _selectedEntries.map((entry) => entry.duration).reduce((a, b) => a + b);
  }

  Future<void> _showCalendarDialog() async {
    // (変更なし)
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
                    todayBuilder: (context, date, events) => Container(
                      margin: const EdgeInsets.all(4.0),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: null,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        date.day.toString(),
                        style: TextStyle(color: Colors.black),
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
              orElse: () =>
                  SelectedDateEntry(date: dateFromDialog, duration: 1.0));
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
    // (buildメソッド自体には変更はありません)
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
            
            Padding(
              padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'メールアドレス',
                    style: TextStyle(
                      color: Theme.of(context).hintColor,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _emailController.text,
                    style: const TextStyle(
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Divider(),
                ],
              ),
            ),

            SizedBox(height: 8),
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
                child: Text(
                    '選択された日付一覧 (合計: ${_calculatedTotalDuration.toStringAsFixed(1)}日):',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            _selectedEntries.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text('日付が選択されていません'),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
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
                                dropdownColor: null,
                                elevation: 0,
                                underline: Container(
                                  height: 0,
                                ),
                                items: [
                                  DropdownMenuItem(
                                      value: 1.0, child: Text('1.0日')),
                                  DropdownMenuItem(
                                      value: 0.5, child: Text('0.5日')),
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
                                icon: Icon(Icons.clear),
                                onPressed: () => _removeDateEntry(entry),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
            SizedBox(height: 20),
            TextFormField(
              decoration: InputDecoration(
                labelText: '備考（任意）',
                hintText: '特記事項があれば入力してください',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.multiline,
              maxLines: 3,
              onSaved: (value) => _formData.remarks = value ?? '',
            ),
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
                  Navigator.pushNamed(context, '/confirm',
                      arguments: _formData);
                }
              },
              style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 15.0),
                  textStyle: TextStyle(fontSize: 16)),
              child: Text('確認画面へ'),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 30),
          ],
        ),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('入力画面'),
        automaticallyImplyLeading: false
        ),
      body: ResponsiveLayout(child: mainContent),
    );
  }
}