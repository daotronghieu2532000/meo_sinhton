import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:meo_sinhton/app/app_controller.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class CommunityPage extends StatefulWidget {
  final AppController appController;
  final bool isEnglish;

  const CommunityPage({
    super.key,
    required this.appController,
    required this.isEnglish,
  });

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  List<dynamic> _tips = [];
  List<dynamic> _filteredTips = [];
  bool _isLoading = true;
  final String _baseUrl = 'https://codego.io.vn/api/';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _fetchTips();
  }

  Future<void> _fetchTips() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(Uri.parse('${_baseUrl}get_community_tips.php'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          setState(() {
            _tips = data['data'];
            _filteredTips = _tips;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error fetching tips: $e');
      setState(() => _isLoading = false);
    }
  }

  void _filterTips(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredTips = _tips;
      } else {
        _filteredTips = _tips.where((tip) {
          final title = tip['title'].toString().toLowerCase();
          final content = tip['content'].toString().toLowerCase();
          final searchLower = query.toLowerCase();
          return title.contains(searchLower) || content.contains(searchLower);
        }).toList();
      }
    });
  }

  void _showAddTipDialog() {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    final authorController = TextEditingController();
    List<TextEditingController> stepControllers = [
      TextEditingController(),
      TextEditingController(),
    ];
    String selectedCategory = 'tip';
    File? selectedImage;
    final ImagePicker picker = ImagePicker();

    Future<void> pickImage(void Function(void Function()) setModalState) async {
      try {
        // Nén ngay từ nguồn: maxWidth, maxHeight và imageQuality giúp giảm dung lượng xuống ~200-300KB
        final XFile? image = await picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 1024, 
          maxHeight: 1024,
          imageQuality: 85, 
        );
        if (image != null) {
          setModalState(() {
            selectedImage = File(image.path);
          });
        }
      } catch (e) {
        print('Error picking image: $e');
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 24,
            left: 20,
            right: 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.isEnglish ? 'Share your experience' : 'Chia sẻ kinh nghiệm',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: widget.isEnglish ? 'Title' : 'Tiêu đề',
                    hintText: widget.isEnglish ? 'e.g. How to find water' : 'VD: Cách tìm nước sạch',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: authorController,
                  decoration: InputDecoration(
                    labelText: widget.isEnglish ? 'Your Name (optional)' : 'Tên bạn (không bắt buộc)',
                    hintText: widget.isEnglish ? 'Anonymous' : 'Ẩn danh',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  items: [
                    DropdownMenuItem(value: 'tip', child: Text(widget.isEnglish ? 'Survival Tip' : 'Mẹo')),
                    DropdownMenuItem(value: 'experience', child: Text(widget.isEnglish ? 'Survival Experience' : 'Kinh nghiệm sinh tồn')),
                    DropdownMenuItem(value: 'first_aid', child: Text(widget.isEnglish ? 'First Aid' : 'Sơ cứu')),
                    DropdownMenuItem(value: 'feedback', child: Text(widget.isEnglish ? 'App Feedback' : 'Góp ý ứng dụng')),
                    DropdownMenuItem(value: 'other', child: Text(widget.isEnglish ? 'Other' : 'Khác')),
                  ],
                  onChanged: (val) => selectedCategory = val!,
                  decoration: InputDecoration(
                    labelText: widget.isEnglish ? 'Category' : 'Danh mục',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: contentController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: widget.isEnglish ? 'Content' : 'Nội dung mô tả',
                    hintText: widget.isEnglish ? 'Describe your tip or scenario...' : 'Mô tả ngắn gọn về mẹo hoặc tình huống...',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 16),
                // Khu vực chọn ảnh
                InkWell(
                  onTap: () => pickImage(setModalState),
                  child: Container(
                    width: double.infinity,
                    height: 150,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                    ),
                    child: selectedImage != null 
                      ? Stack(
                          fit: StackFit.expand,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(15),
                              child: Image.file(selectedImage!, fit: BoxFit.cover),
                            ),
                            Positioned(
                              top: 8, right: 8,
                              child: IconButton.filled(
                                onPressed: () => setModalState(() => selectedImage = null),
                                icon: const Icon(Icons.delete_outline, size: 20),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo_outlined, color: Theme.of(context).colorScheme.primary),
                            const SizedBox(height: 8),
                            Text(
                              widget.isEnglish ? 'Add illustration photo (Optional)' : 'Thêm ảnh minh họa (Không bắt buộc)',
                              style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 13),
                            ),
                          ],
                        ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  widget.isEnglish ? 'Implementation Steps' : 'Các bước thực hiện',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...List.generate(stepControllers.length, (index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 12,
                          child: Text('${index + 1}', style: const TextStyle(fontSize: 12)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: stepControllers[index],
                            decoration: InputDecoration(
                              hintText: widget.isEnglish ? 'Step ${index + 1} details...' : 'Chi tiết bước ${index + 1}...',
                              isDense: true,
                            ),
                            maxLines: null,
                          ),
                        ),
                        if (stepControllers.length > 2)
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline, color: Colors.grey),
                            onPressed: () {
                              setModalState(() {
                                stepControllers.removeAt(index);
                              });
                            },
                          ),
                      ],
                    ),
                  );
                }),
                TextButton.icon(
                  onPressed: () {
                    setModalState(() {
                      stepControllers.add(TextEditingController());
                    });
                  },
                  icon: const Icon(Icons.add_circle_outline),
                  label: Text(widget.isEnglish ? 'Add Step' : 'Thêm bước'),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: FilledButton(
                    onPressed: () async {
                      if (titleController.text.isEmpty || contentController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(widget.isEnglish ? 'Please fill title and content' : 'Vui lòng điền tiêu đề và nội dung')),
                        );
                        return;
                      }
                      
                      List<String> stepsData = stepControllers
                          .where((c) => c.text.isNotEmpty)
                          .map((c) => c.text)
                          .toList();

                      // Sử dụng MultipartRequest để gửi cả ảnh và dữ liệu
                      var request = http.MultipartRequest('POST', Uri.parse('${_baseUrl}add_community_tip.php'));
                      
                      request.fields['title'] = titleController.text;
                      request.fields['content'] = contentController.text;
                      request.fields['author_name'] = authorController.text.isEmpty ? 'Ẩn danh' : authorController.text;
                      request.fields['category'] = selectedCategory;
                      request.fields['steps'] = json.encode(stepsData);

                      if (selectedImage != null) {
                        request.files.add(await http.MultipartFile.fromPath(
                          'image',
                          selectedImage!.path,
                        ));
                      }

                      final streamedResponse = await request.send();
                      final response = await http.Response.fromStream(streamedResponse);

                      if (response.statusCode == 200) {
                        final data = json.decode(response.body);
                        if (data['success']) {
                          if (context.mounted) Navigator.pop(context);
                          _fetchTips();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(data['message'])),
                            );
                          }
                        } else {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(data['message'])),
                            );
                          }
                        }
                      } else {
                        print('Server Error: ${response.statusCode}');
                        print('Response Body: ${response.body}');
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Lỗi máy chủ (${response.statusCode}). Bạn thử lại xem!')),
                          );
                        }
                      }
                    },
                    child: Text(widget.isEnglish ? 'Submit' : 'Gửi đi'),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          // Thanh tìm kiếm
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: _filterTips,
              decoration: InputDecoration(
                hintText: widget.isEnglish ? 'Search tips...' : 'Tìm kiếm mẹo, kinh nghiệm...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty 
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: () {
                        _searchController.clear();
                        _filterTips('');
                      },
                    )
                  : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainer,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetchTips,
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : _filteredTips.isEmpty 
                  ? _buildEmptyState()
                  : _buildTipsList(),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddTipDialog,
        icon: const Icon(Icons.add_comment_rounded),
        label: Text(widget.isEnglish ? 'Share Feedback' : 'Góp ý & Mẹo'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 80, color: Theme.of(context).colorScheme.outlineVariant),
          const SizedBox(height: 16),
          Text(
            widget.isEnglish ? 'Be the first to share!' : 'Hãy là người đầu tiên chia sẻ!',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              widget.isEnglish 
                ? 'Your survival stories and tips can save lives.' 
                : 'Những câu chuyện và mẹo của bạn có thể cứu sống nhiều sinh mạng.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredTips.length,
      itemBuilder: (context, index) {
        final tip = _filteredTips[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 0,
          color: Theme.of(context).colorScheme.surfaceContainer,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ExpansionTile(
            shape: const RoundedRectangleBorder(side: BorderSide.none),
            collapsedShape: const RoundedRectangleBorder(side: BorderSide.none),
            leading: CircleAvatar(
              backgroundColor: _getCategoryColor(tip['category']).withOpacity(0.2),
              child: Icon(_getCategoryIcon(tip['category']), color: _getCategoryColor(tip['category']), size: 20),
            ),
            title: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tip['title'],
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${tip['author_name']} ${_getFlagEmoji(tip['country_code'] ?? 'VN')} • ${DateFormat('dd/MM/yyyy').format(DateTime.parse(tip['created_at']))}',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                if (tip['image_url'] != null)
                   GestureDetector(
                     onTap: () => _showZoomedImage(tip['image_url']),
                     child: Container(
                       margin: const EdgeInsets.only(left: 12),
                       decoration: BoxDecoration(
                         borderRadius: BorderRadius.circular(10),
                         border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5)),
                       ),
                       child: ClipRRect(
                         borderRadius: BorderRadius.circular(9),
                         child: Image.network(
                           tip['image_url'],
                           width: 54,
                           height: 54,
                           fit: BoxFit.cover,
                           errorBuilder: (context, error, stackTrace) => const SizedBox(),
                         ),
                       ),
                     ),
                   ),
              ],
            ),
            subtitle: null, // Subtitle moved inside title for better alignment
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(),
                    const SizedBox(height: 8),
                    Text(
                      widget.isEnglish ? 'Description:' : 'Mô tả:',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tip['content'],
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    if (tip['image_url'] != null) ...[
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () => _showZoomedImage(tip['image_url']),
                        child: Center(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(15),
                              child: Image.network(
                                tip['image_url'],
                                width: MediaQuery.of(context).size.width * 0.7,
                                height: 160,
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Container(
                                    width: MediaQuery.of(context).size.width * 0.7,
                                    height: 160,
                                    color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                                    child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                    if (tip['steps'] != null && (tip['steps'] as List).isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        widget.isEnglish ? 'Implementation Steps:' : 'Các bước xử lý:',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      ...(tip['steps'] as List).asMap().entries.map((entry) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '${entry.key + 1}',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.primary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  entry.value.toString(),
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getCategoryColor(tip['category']).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _getCategoryLabel(tip['category']),
                            style: TextStyle(
                              color: _getCategoryColor(tip['category']),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              onPressed: () => _likeTip(tip['id']),
                              icon: Icon(
                                (tip['is_liked'] ?? false) ? Icons.favorite : Icons.favorite_border, 
                                size: 20, 
                                color: (tip['is_liked'] ?? false) ? Colors.red : Colors.grey
                              ),
                              visualDensity: VisualDensity.compact,
                            ),
                            Text(
                              '${tip['likes_count']}',
                              style: Theme.of(context).textTheme.labelMedium,
                            ),
                             const SizedBox(width: 8),
                            IconButton(
                              onPressed: () {
                                // Xem bình luận (phát triển sau)
                                ScaffoldMessenger.of(context).showSnackBar(
                                   SnackBar(content: Text(widget.isEnglish ? 'Comments coming soon' : 'Tính năng bình luận sắp ra mắt'))
                                );
                              },
                              icon: const Icon(Icons.comment_outlined, size: 20),
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _likeTip(int tipId) async {
    // 1. Cập nhật UI ngay lập tức (Optimistic Update)
    bool ? originalStatus;
    int ? originalCount;

    setState(() {
      for (var tip in _tips) {
        if (tip['id'] == tipId) {
          originalStatus = tip['is_liked'] ?? false;
          originalCount = tip['likes_count'] ?? 0;
          
          tip['is_liked'] = !(tip['is_liked'] ?? false);
          tip['likes_count'] = tip['is_liked'] ? (tip['likes_count'] ?? 0) + 1 : (tip['likes_count'] ?? 1) - 1;
          break;
        }
      }
    });

    try {
      final response = await http.post(
        Uri.parse('${_baseUrl}like_community_tip.php'),
        body: {'tip_id': tipId.toString()},
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          // Cập nhật lại chính xác từ Server trả về
          setState(() {
            for (var tip in _tips) {
              if (tip['id'] == tipId) {
                tip['is_liked'] = data['is_liked'];
                tip['likes_count'] = data['new_likes_count'];
                break;
              }
            }
          });
        }
      }
    } catch (e) {
      print('Error liking tip: $e');
      // Rollback nếu có lỗi
      if (originalStatus != null) {
        setState(() {
          for (var tip in _tips) {
            if (tip['id'] == tipId) {
              tip['is_liked'] = originalStatus;
              tip['likes_count'] = originalCount;
              break;
            }
          }
        });
      }
    }
  }

  void _showZoomedImage(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          alignment: Alignment.center,
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.black.withOpacity(0.85),
              ),
            ),
            InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getFlagEmoji(String countryCode) {
    if (countryCode.length != 2) return '';
    int firstLetter = countryCode.toUpperCase().codeUnitAt(0) - 0x41 + 0x1F1E6;
    int secondLetter = countryCode.toUpperCase().codeUnitAt(1) - 0x41 + 0x1F1E6;
    return String.fromCharCode(firstLetter) + String.fromCharCode(secondLetter);
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'tip': return Colors.amber;
      case 'experience': return Colors.teal;
      case 'first_aid': return Colors.red;
      case 'feedback': return Colors.blue;
      default: return Colors.blueGrey;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'tip': return Icons.lightbulb_outline;
      case 'experience': return Icons.verified_user_rounded;
      case 'first_aid': return Icons.medical_services_rounded;
      case 'feedback': return Icons.feedback_rounded;
      default: return Icons.more_horiz_rounded;
    }
  }

  String _getCategoryLabel(String category) {
    if (widget.isEnglish) {
      switch (category) {
        case 'tip': return 'TIP';
        case 'experience': return 'STORY';
        case 'first_aid': return 'MEDICAL';
        case 'feedback': return 'FEEDBACK';
        default: return 'OTHER';
      }
    } else {
       switch (category) {
        case 'tip': return 'MẸO';
        case 'experience': return 'CHIA SẺ';
        case 'first_aid': return 'Y TẾ';
        case 'feedback': return 'GÓP Ý';
        default: return 'KHÁC';
      }
    }
  }
}
