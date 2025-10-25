import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:template/common/layout/default_layout.dart';
import 'package:template/core/themes/app_colors.dart';

class TaskPage extends StatefulWidget {
  const TaskPage({super.key});

  @override
  State<TaskPage> createState() => _TaskPageState();
}

class _TaskPageState extends State<TaskPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  var searchQuery = '';

  Stream<QuerySnapshot<Map<String, dynamic>>> get tasksStream {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Stream.empty();

    return _firestore
        .collection('tasks')
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultLayout(
      title: '과제',
      appBarColor: const Color(0xFFF4F6FF),
      foregroundColor: Colors.black,
      floatingActionButton: FloatingActionButton(
        backgroundColor: context.colors.primary,
        onPressed: _showAddTaskBottomSheet,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      backgroundColor: const Color(0xFFF4F6FF),
      child: Column(
        children: [
          _buildSearchBar(),
          Expanded(
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

                final filteredTasks = allTasks.where((t) {
                  return t['title'].toString().toLowerCase().contains(
                    searchQuery.toLowerCase(),
                  );
                }).toList();

                if (filteredTasks.isEmpty) {
                  return const Center(
                    child: Text('등록된 과제가 없습니다.'),
                  );
                }

                return ListView.builder(
                  itemCount: filteredTasks.length,
                  itemBuilder: (context, index) {
                    final task = filteredTasks[index];
                    return _buildTaskItem(task);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // 검색바
  Widget _buildSearchBar() {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              onChanged: (v) => setState(() => searchQuery = v),
              style: const TextStyle(color: Colors.black),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close, color: Colors.grey),
                        onPressed: () {
                          setState(() => searchQuery = '');
                          FocusManager.instance.primaryFocus?.unfocus();
                        },
                      )
                    : null,
                hintText: '과제 검색...',
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.symmetric(vertical: 12.h),
                hintStyle: const TextStyle(color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.r),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 과제 리스트 아이템
  Widget _buildTaskItem(Map<String, dynamic> task) {
    final done = task['completed'] ?? false;
    final color = _getCategoryColor(task);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
      child: GestureDetector(
        onTap: () => _showTaskDetailBottomSheet(task),
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
          child: ListTile(
            leading: IconButton(
              icon: Icon(
                done ? Icons.check_circle : Icons.radio_button_unchecked,
                color: done ? color : Colors.grey,
              ),
              onPressed: () async {
                await _firestore.collection('tasks').doc(task['id']).update({
                  'completed': !done,
                });
              },
            ),
            title: Text(
              task['title'] ?? '',
              style: TextStyle(
                color: done ? Colors.grey.shade600 : Colors.black,
                decoration: done ? TextDecoration.lineThrough : null,
                decorationColor: Colors.black,
                decorationThickness: 1.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Padding(
              padding: EdgeInsets.only(top: 2.h),
              child: Text(
                task['description'] ?? '',
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 13,
                  height: 1.3,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            trailing: Icon(Icons.circle, color: color, size: 10),
          ),
        ),
      ),
    );
  }

  // 과제 상세보기 BottomSheet
  void _showTaskDetailBottomSheet(Map<String, dynamic> task) {
    final color = _getCategoryColor(task);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
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
                  20.w,
                  20.h,
                  20.w,
                  MediaQuery.of(context).viewInsets.bottom + 16.h,
                ),
                child: Column(
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

                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 6.h,
                      ),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _getCategoryLabel(task),
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    SizedBox(height: 16.h),

                    Text(
                      task['title'] ?? '',
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8.h),

                    Text(
                      task['description'] ?? '',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),

                    SizedBox(height: 24.h),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _showEditTaskBottomSheet(task);
                          },
                          icon: const Icon(Icons.edit, size: 18),
                          label: const Text('수정'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () async {
                            await _firestore
                                .collection('tasks')
                                .doc(task['id'])
                                .delete();
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.delete_outline, size: 18),
                          label: const Text('삭제'),
                        ),
                      ],
                    ),
                    SizedBox(height: 30.h),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // 과제 추가 BottomSheet
  void _showAddTaskBottomSheet() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    var selectedCategory = 1;

    final categories = [
      {'label': '중요하고 급한 일', 'color': context.colors.error, 'id': 1},
      {'label': '중요하지만 급하지 않은 일', 'color': context.colors.warning, 'id': 2},
      {'label': '중요하지 않지만 급한 일', 'color': context.colors.primary, 'id': 3},
      {'label': '중요하지도 급하지도 않은 일', 'color': context.colors.success, 'id': 4},
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
                  20.w,
                  20.h,
                  20.w,
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
                            hintText: '과제 제목 입력...',
                            hintStyle: TextStyle(color: Colors.grey),
                            border: InputBorder.none,
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
                                hintText: '설명 입력...',
                                hintStyle: TextStyle(color: Colors.grey),
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 20.h),

                        Column(
                          children: categories.map((c) {
                            final selected = selectedCategory == c['id'];
                            return GestureDetector(
                              onTap: () => setModalState(() {
                                selectedCategory = c['id']! as int;
                              }),
                              child: Container(
                                margin: EdgeInsets.symmetric(vertical: 4.h),
                                padding: EdgeInsets.all(12.w),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? (c['color']! as Color).withOpacity(0.1)
                                      : Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: selected
                                        ? c['color']! as Color
                                        : Colors.transparent,
                                    width: 1.5,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      selected
                                          ? Icons.radio_button_checked
                                          : Icons.radio_button_unchecked,
                                      color: c['color']! as Color,
                                    ),
                                    SizedBox(width: 8.w),
                                    Text(
                                      c['label']! as String,
                                      style: TextStyle(
                                        color: c['color']! as Color,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        SizedBox(height: 24.h),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: context.colors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: EdgeInsets.symmetric(vertical: 14.h),
                            ),
                            onPressed: () async {
                              if (titleController.text.trim().isEmpty) return;
                              final user = FirebaseAuth.instance.currentUser;

                              await _firestore.collection('tasks').add({
                                'title': titleController.text,
                                'description': descController.text,
                                'urgent':
                                    selectedCategory == 1 ||
                                    selectedCategory == 3,
                                'important':
                                    selectedCategory == 1 ||
                                    selectedCategory == 2,
                                'completed': false,
                                'createdAt': FieldValue.serverTimestamp(),
                                'userId': user!.uid,
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

  /// ✏️ 수정 BottomSheet
  void _showEditTaskBottomSheet(Map<String, dynamic> task) {
    final titleController = TextEditingController(text: task['title']);
    final descController = TextEditingController(text: task['description']);
    var selectedCategory = _getCategoryFromTask(task);

    final categories = [
      {'label': '중요하고 급한 일', 'color': context.colors.error, 'id': 1},
      {'label': '중요하지만 급하지 않은 일', 'color': context.colors.warning, 'id': 2},
      {'label': '중요하지 않지만 급한 일', 'color': context.colors.primary, 'id': 3},
      {'label': '중요하지도 급하지도 않은 일', 'color': context.colors.success, 'id': 4},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
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
                  20.w,
                  20.h,
                  20.w,
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
                            labelText: '과제 제목',
                            labelStyle: TextStyle(color: Colors.grey),
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

                        Column(
                          children: categories.map((c) {
                            final selected = selectedCategory == c['id'];
                            return GestureDetector(
                              onTap: () => setModalState(() {
                                selectedCategory = c['id']! as int;
                              }),
                              child: Container(
                                margin: EdgeInsets.symmetric(vertical: 4.h),
                                padding: EdgeInsets.all(12.w),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? (c['color']! as Color).withOpacity(0.1)
                                      : Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: selected
                                        ? c['color']! as Color
                                        : Colors.transparent,
                                    width: 1.5,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      selected
                                          ? Icons.radio_button_checked
                                          : Icons.radio_button_unchecked,
                                      color: c['color']! as Color,
                                    ),
                                    SizedBox(width: 8.w),
                                    Text(
                                      c['label']! as String,
                                      style: TextStyle(
                                        color: c['color']! as Color,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        SizedBox(height: 24.h),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: context.colors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: EdgeInsets.symmetric(vertical: 14.h),
                            ),
                            onPressed: () async {
                              await _firestore
                                  .collection('tasks')
                                  .doc(task['id'])
                                  .update({
                                    'title': titleController.text,
                                    'description': descController.text,
                                    'urgent':
                                        selectedCategory == 1 ||
                                        selectedCategory == 3,
                                    'important':
                                        selectedCategory == 1 ||
                                        selectedCategory == 2,
                                  });
                              Navigator.pop(context);
                            },
                            child: const Text(
                              '수정 완료',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
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

  int _getCategoryFromTask(Map<String, dynamic> task) {
    final urgent = task['urgent'] ?? false;
    final important = task['important'] ?? false;
    if (urgent && important) return 1;
    if (!urgent && important) return 2;
    if (urgent && !important) return 3;
    return 4;
  }

  Color _getCategoryColor(Map<String, dynamic> task) {
    final urgent = task['urgent'] ?? false;
    final important = task['important'] ?? false;
    if (urgent && important) return context.colors.error;
    if (!urgent && important) return context.colors.warning;
    if (urgent && !important) return context.colors.primary;
    return context.colors.success;
  }

  String _getCategoryLabel(Map<String, dynamic> task) {
    final urgent = task['urgent'] ?? false;
    final important = task['important'] ?? false;
    if (urgent && important) return '중요하고 급한 일';
    if (!urgent && important) return '중요하지만 급하지 않은 일';
    if (urgent && !important) return '중요하지 않지만 급한 일';
    return '중요하지도 급하지도 않은 일';
  }
}
