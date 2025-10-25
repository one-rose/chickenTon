import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:template/common/layout/default_layout.dart';
import 'package:template/core/themes/app_colors.dart';

class EisenhowerPage extends StatefulWidget {
  const EisenhowerPage({super.key});

  @override
  State<EisenhowerPage> createState() => _EisenhowerPageState();
}

class _EisenhowerPageState extends State<EisenhowerPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<QuerySnapshot<Map<String, dynamic>>> get tasksStream {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Stream.empty();
    print('🔥 현재 로그인 UID: ${FirebaseAuth.instance.currentUser?.uid}');

    return _firestore
        .collection('tasks')
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultLayout(
      title: '아이젠하워 매트릭스',
      appBarColor: const Color(0xFFF4F6FF),
      foregroundColor: Colors.black,
      backgroundColor: const Color(0xFFF4F6FF),
      floatingActionButton: FloatingActionButton(
        backgroundColor: context.colors.primary,
        onPressed: _showAddBottomSheet,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: tasksStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final allTasks =
              snapshot.data?.docs.map((e) {
                final data = e.data();
                data['id'] = e.id;
                return data;
              }).toList() ??
              [];

          return Padding(
            padding: EdgeInsets.all(8.w),
            child: Column(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildQuadrant(
                          '중요하고 급한 일',
                          '1',
                          Colors.pink.shade300,
                          _filter(allTasks, true, true),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: _buildQuadrant(
                          '중요하지만 급하지 않은 일',
                          '2',
                          Colors.orange.shade400,
                          _filter(allTasks, false, true),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 8.h),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildQuadrant(
                          '중요하지 않지만 급한 일',
                          '3',
                          Colors.blue.shade400,
                          _filter(allTasks, true, false),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: _buildQuadrant(
                          '중요하지도 급하지도 않은 일',
                          '4',
                          Colors.green.shade400,
                          _filter(allTasks, false, false),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Map<String, dynamic>> _filter(
    List<Map<String, dynamic>> all,
    bool urgent,
    bool important,
  ) {
    return all
        .where((e) => e['urgent'] == urgent && e['important'] == important)
        .toList();
  }

  Widget _buildQuadrant(
    String title,
    String roman,
    Color color,
    List<Map<String, dynamic>> items,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 6.r,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: EdgeInsets.all(10.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  roman,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 10.sp,
                  ),
                ),
              ),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 10.sp,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Text(
                      '할 일이 없어요',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12.sp,
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    child: Column(
                      children: items.map((task) {
                        return Padding(
                          padding: EdgeInsets.symmetric(vertical: 4.h),
                          child: Row(
                            children: [
                              Checkbox(
                                value: task['completed'] ?? false,
                                activeColor: context.colors.primary,
                                checkColor: Colors.white,
                                side: BorderSide(
                                  color: context.colors.textSecondary
                                      .withOpacity(0.6),
                                  width: 1.4,
                                ),
                                visualDensity: VisualDensity.compact,
                                onChanged: (v) {
                                  _firestore
                                      .collection('tasks')
                                      .where('title', isEqualTo: task['title'])
                                      .get()
                                      .then((snapshot) {
                                        for (final doc in snapshot.docs) {
                                          doc.reference.update({
                                            'completed': v ?? false,
                                          });
                                        }
                                      });
                                },
                              ),

                              Expanded(
                                child: GestureDetector(
                                  onTap: () => _showTaskDetailBottomSheet(task),
                                  child: Text(
                                    task['title'],
                                    style: TextStyle(
                                      color: (task['completed'] ?? false)
                                          ? Colors.grey.shade600
                                          : Colors.black,
                                      decoration: (task['completed'] ?? false)
                                          ? TextDecoration.lineThrough
                                          : null,
                                      decorationColor: Colors.black,
                                      decorationThickness: 1.5,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  String _getQuadrantLabel(Map<String, dynamic> task) {
    final urgent = task['urgent'] == true;
    final important = task['important'] == true;

    if (urgent && important) return '중요하고 급한 일';
    if (!urgent && important) return '중요하지만 급하지 않은 일';
    if (urgent && !important) return '중요하지 않지만 급한 일';
    return '중요하지도 급하지도 않은 일';
  }

  void _showTaskDetailBottomSheet(Map<String, dynamic> task) {
    final color = (task['urgent'] == true && task['important'] == true)
        ? context.colors.error
        : (task['urgent'] == false && task['important'] == true)
        ? context.colors.warning
        : (task['urgent'] == true && task['important'] == false)
        ? context.colors.primary
        : context.colors.success;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20.h,
            left: 16.w,
            right: 16.w,
            top: 20.h,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              SizedBox(height: 16.h),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text(
                      _getQuadrantLabel(task),
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13.sp,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
              12.verticalSpace,
              Row(
                children: [
                  Expanded(
                    child: Text(
                      task['title'] ?? '',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
              8.verticalSpace,
              if ((task['description'] ?? '').toString().isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(left: 12.w),
                  child: Text(
                    task['description'],
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),

              SizedBox(height: 24.h),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('수정'),
                    onPressed: () {
                      Navigator.pop(context);
                      _showEditBottomSheet(task['id'], task);
                    },
                  ),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('삭제'),
                    onPressed: () => _confirmDelete(task['id']),
                  ),
                ],
              ),
              SizedBox(height: 20.h),
            ],
          ),
        );
      },
    );
  }

  void _showAddBottomSheet() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    var selectedQuadrant = 1;

    final quadrants = [
      {
        'roman': '1',
        'label': '중요하고 급한 일',
        'color': context.colors.error,
        'urgent': true,
        'important': true,
      },
      {
        'roman': '2',
        'label': '중요하지만 급하지 않은 일',
        'color': context.colors.warning,
        'urgent': false,
        'important': true,
      },
      {
        'roman': '3',
        'label': '중요하지 않지만 급한 일',
        'color': context.colors.primary,
        'urgent': true,
        'important': false,
      },
      {
        'roman': '4',
        'label': '중요하지도 급하지도 않은 일',
        'color': context.colors.success,
        'urgent': false,
        'important': false,
      },
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return DecoratedBox(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                controller: scrollController,
                padding: EdgeInsets.fromLTRB(
                  16.w,
                  20.h,
                  16.w,
                  MediaQuery.of(context).viewInsets.bottom + 16.h,
                ),
                child: StatefulBuilder(
                  builder: (context, setModalState) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 40.w,
                            height: 4.h,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        SizedBox(height: 20.h),

                        // 제목 입력
                        TextField(
                          controller: titleController,
                          autofocus: true,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 16.sp,
                          ),
                          decoration: InputDecoration(
                            hintText: '무엇을 하고 싶으신가요?',
                            hintStyle: TextStyle(
                              color: context.colors.textSecondary.withOpacity(
                                0.7,
                              ),
                            ),
                            border: InputBorder.none,
                          ),
                        ),
                        SizedBox(height: 8.h),

                        // 설명 입력
                        ConstrainedBox(
                          constraints: BoxConstraints(maxHeight: 250.h),
                          child: Scrollbar(
                            thumbVisibility: true,
                            child: TextField(
                              controller: descController,
                              style: TextStyle(
                                color: Colors.grey.shade800,
                                fontSize: 13.sp,
                              ),
                              keyboardType: TextInputType.multiline,
                              maxLines: null,
                              scrollPhysics:
                                  const AlwaysScrollableScrollPhysics(),
                              decoration: InputDecoration(
                                hintText: '설명',
                                hintStyle: TextStyle(
                                  color: context.colors.textSecondary
                                      .withOpacity(0.7),
                                ),
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 12.h),

                        GestureDetector(
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              backgroundColor: Colors.white,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(24),
                                ),
                              ),
                              builder: (_) {
                                return SafeArea(
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 20.w,
                                      vertical: 16.h,
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: List.generate(
                                        quadrants.length,
                                        (i) {
                                          final q = quadrants[i];
                                          final color = q['color']! as Color;
                                          final selected =
                                              selectedQuadrant == i + 1;
                                          return GestureDetector(
                                            onTap: () {
                                              setModalState(() {
                                                selectedQuadrant = i + 1;
                                              });
                                              Navigator.pop(context);
                                            },
                                            child: Container(
                                              margin: EdgeInsets.symmetric(
                                                vertical: 6.h,
                                              ),
                                              padding: EdgeInsets.all(12.w),
                                              decoration: BoxDecoration(
                                                color: selected
                                                    ? color.withOpacity(0.08)
                                                    : Colors.grey.shade50,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: selected
                                                      ? color
                                                      : Colors.grey.shade300,
                                                ),
                                              ),
                                              child: Row(
                                                children: [
                                                  Container(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                          horizontal: 6.w,
                                                          vertical: 2.h,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: color.withOpacity(
                                                        0.15,
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8.r,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      q['roman']! as String,
                                                      style: TextStyle(
                                                        color: color,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                  SizedBox(width: 8.w),
                                                  Text(
                                                    q['label']! as String,
                                                    style: TextStyle(
                                                      color: color,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                          child: Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(
                              horizontal: 12.w,
                              vertical: 12.h,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 6.w,
                                    vertical: 2.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        (quadrants[selectedQuadrant -
                                                    1]['color']!
                                                as Color)
                                            .withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8.r),
                                  ),
                                  child: Text(
                                    quadrants[selectedQuadrant - 1]['roman']!
                                        as String,
                                    style: TextStyle(
                                      color:
                                          quadrants[selectedQuadrant -
                                                  1]['color']!
                                              as Color,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 8.w),
                                Text(
                                  quadrants[selectedQuadrant - 1]['label']!
                                      as String,
                                  style: TextStyle(
                                    color:
                                        quadrants[selectedQuadrant -
                                                1]['color']!
                                            as Color,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        SizedBox(height: 16.h),

                        // 추가 버튼
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF3E6DFF),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: EdgeInsets.symmetric(vertical: 14.h),
                            ),
                            onPressed: () async {
                              if (titleController.text.isEmpty) return;
                              final q = quadrants[selectedQuadrant - 1];
                              final user = FirebaseAuth.instance.currentUser;

                              if (user == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('로그인이 필요합니다.')),
                                );
                                return;
                              }

                              await _firestore.collection('tasks').add({
                                'title': titleController.text,
                                'description': descController.text,
                                'urgent': q['urgent'],
                                'important': q['important'],
                                'completed': false,
                                'createdAt': FieldValue.serverTimestamp(),
                                'userId': user.uid,
                              });
                              Navigator.pop(context);
                            },

                            child: const Text(
                              '추가하기',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 10.h),
                      ],
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showEditBottomSheet(String docId, Map<String, dynamic> task) {
    final titleController = TextEditingController(text: task['title']);
    final descController = TextEditingController(
      text: task['description'] ?? '',
    );
    final urgent = task['urgent'] ?? false;
    final important = task['important'] ?? false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return DecoratedBox(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                controller: scrollController,
                padding: EdgeInsets.fromLTRB(
                  16.w,
                  20.h,
                  16.w,
                  MediaQuery.of(context).viewInsets.bottom + 16.h,
                ),
                child: StatefulBuilder(
                  builder: (context, setModalState) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 40.w,
                            height: 4.h,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        SizedBox(height: 20.h),

                        TextField(
                          controller: titleController,
                          style: const TextStyle(color: Colors.black),
                          decoration: const InputDecoration(
                            labelText: '제목',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        SizedBox(height: 12.h),

                        ConstrainedBox(
                          constraints: BoxConstraints(maxHeight: 250.h),
                          child: Scrollbar(
                            thumbVisibility: true,
                            child: TextField(
                              controller: descController,
                              style: const TextStyle(color: Colors.black),
                              keyboardType: TextInputType.multiline,
                              maxLines: null,
                              decoration: const InputDecoration(
                                labelText: '설명',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 20.h),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () async {
                              final user = FirebaseAuth.instance.currentUser;
                              if (user == null) return;

                              final doc = await _firestore
                                  .collection('tasks')
                                  .doc(docId)
                                  .get();

                              if (doc.exists &&
                                  doc.data()?['userId'] == user.uid) {
                                await doc.reference.update({
                                  'title': titleController.text,
                                  'description': descController.text,
                                  'urgent': urgent,
                                  'important': important,
                                });
                                Navigator.pop(context);
                              } else {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('수정 권한이 없습니다.')),
                                );
                              }
                            },

                            style: ElevatedButton.styleFrom(
                              backgroundColor: context.colors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: EdgeInsets.symmetric(vertical: 14.h),
                            ),
                            child: const Text(
                              '수정 완료',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                        SizedBox(height: 10.h),
                      ],
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _confirmDelete(String docId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Text('삭제하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: context.colors.error,
              ),
              onPressed: () async {
                final user = FirebaseAuth.instance.currentUser;
                if (user == null) return;

                final doc = await _firestore
                    .collection('tasks')
                    .doc(docId)
                    .get();

                if (doc.exists && doc.data()?['userId'] == user.uid) {
                  await doc.reference.delete();
                  Navigator.pop(context);
                  Navigator.of(context, rootNavigator: true).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('삭제되었습니다.')),
                  );
                } else {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('삭제 권한이 없습니다.')),
                  );
                }
              },
              child: const Text('삭제'),
            ),
          ],
        );
      },
    );
  }
}
