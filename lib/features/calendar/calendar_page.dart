import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:template/core/themes/app_colors.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  var _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  final double _calendarHeight = 360.h;

  final CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F6FF),
        elevation: 0,
        centerTitle: true,
        title: Text(
          '${_focusedDay.month}월',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 22.sp,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _focusedDay = DateTime.now();
                _selectedDay = DateTime.now();
              });
            },
            child: const Text(
              '오늘',
              style: TextStyle(
                color: Color(0xFF3E6DFF),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),

      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              color: const Color(0xFFF4F6FF),
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: SizedBox(
                height: _calendarHeight,
                child: TableCalendar(
                  locale: 'ko_KR',
                  firstDay: DateTime.utc(2020),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: _focusedDay,
                  calendarFormat: _calendarFormat,
                  onPageChanged: (focusedDay) {
                    setState(() => _focusedDay = focusedDay);
                  },
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  onDaySelected: (selected, focused) {
                    setState(() {
                      _selectedDay = selected;
                      _focusedDay = focused;
                    });
                  },
                  headerVisible: false,
                  calendarStyle: CalendarStyle(
                    outsideDaysVisible: false,
                    defaultTextStyle: const TextStyle(color: Colors.black),
                    weekendTextStyle: const TextStyle(color: Colors.black),
                    todayDecoration: BoxDecoration(
                      color: const Color(0xFF3E6DFF).withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: const BoxDecoration(
                      color: Color(0xFF3E6DFF),
                      shape: BoxShape.circle,
                    ),
                    selectedTextStyle: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
          ),

          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _taskStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final tasks =
                  snapshot.data?.docs.map((e) {
                    final data = e.data();
                    data['id'] = e.id;
                    return data;
                  }).toList() ??
                  [];

              if (tasks.isEmpty) {
                return SliverToBoxAdapter(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/images/no.png',
                          width: 160.w,
                          fit: BoxFit.contain,
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          '등록된 일정이 없습니다',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 15.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final task = tasks[index];
                    final done = task['completed'] ?? false;

                    return Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 6.h,
                      ),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12.r),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.shade200,
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 8.h,
                          ),
                          child: Row(
                            children: [
                              Checkbox(
                                value: done,
                                activeColor: context.colors.primary,
                                checkColor: Colors.white,
                                side: BorderSide(
                                  color: context.colors.textSecondary
                                      .withOpacity(0.6),
                                  width: 1.4,
                                ),
                                onChanged: (v) async {
                                  final user =
                                      FirebaseAuth.instance.currentUser;
                                  if (user == null) return;

                                  final doc = await _firestore
                                      .collection('tasks')
                                      .doc(task['id'])
                                      .get();

                                  if (doc.exists &&
                                      doc.data()?['userId'] == user.uid) {
                                    await doc.reference.update({
                                      'completed': v ?? false,
                                    });
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('수정 권한이 없습니다.'),
                                      ),
                                    );
                                  }
                                },
                              ),
                              SizedBox(width: 8.w),
                              Expanded(
                                child: Text(
                                  task['title'] ?? '',
                                  style: TextStyle(
                                    color: done
                                        ? Colors.grey.shade500
                                        : Colors.black,
                                    fontWeight: FontWeight.w600,
                                    decoration: done
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                  childCount: tasks.length,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> get _taskStream {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Stream.empty();

    final selectedDate = _selectedDay ?? DateTime.now();
    final start = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );
    final end = start.add(const Duration(days: 1));

    return _firestore
        .collection('tasks')
        .where('userId', isEqualTo: user.uid)
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('createdAt', isLessThan: Timestamp.fromDate(end))
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
}
