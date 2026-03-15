import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:meo_sinhton/app/app_controller.dart';
import 'package:meo_sinhton/app/app_strings.dart';
import 'package:intl/intl.dart';

class MyPostsPage extends StatefulWidget {
  final AppController appController;
  final bool isEnglish;

  const MyPostsPage({
    super.key,
    required this.appController,
    required this.isEnglish,
  });

  @override
  State<MyPostsPage> createState() => _MyPostsPageState();
}

class _MyPostsPageState extends State<MyPostsPage> {
  List<dynamic> _myTips = [];
  bool _isLoading = true;
  String? _errorMessage;
  final String _baseUrl = 'https://codego.io.vn/api/';

  @override
  void initState() {
    super.initState();
    _fetchMyTips();
  }

  Future<void> _fetchMyTips() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null; 
    });
    try {
      final url = '${_baseUrl}get_my_community_tips.php?user_id=${widget.appController.userId}';
      print('>>> URL: $url');
      
      final response = await http.get(Uri.parse(url));
      print('>>> Status Code: ${response.statusCode}');
      print('>>> Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          setState(() {
            _myTips = data['data'];
            _isLoading = false;
          });
        } else {
           setState(() {
            _myTips = [];
            _errorMessage = data['message'] ?? 'Lỗi không xác định';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Lỗi máy chủ: ${response.statusCode}. (Nghiêm trọng: Bạn chưa upload file API này lên web)';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching my tips: $e');
      setState(() {
        _errorMessage = 'Không thể kết nối máy chủ.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEnglish ? 'My Shared Posts' : 'Bài viết của bạn'),
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              scheme.surface,
              scheme.surfaceContainerLowest,
            ],
          ),
        ),
        child: RefreshIndicator(
          onRefresh: _fetchMyTips,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _myTips.isEmpty
                  ? _buildEmptyState()
                  : _buildTipsList(),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView( // Sử dụng ListView để RefreshIndicator hoạt động được
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.post_add_rounded, size: 80, color: Theme.of(context).colorScheme.outlineVariant),
              const SizedBox(height: 16),
              Text(
                _errorMessage != null 
                    ? _errorMessage! 
                    : (widget.isEnglish ? 'No posts yet' : 'Chưa có bài viết nào'),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: _errorMessage != null ? Theme.of(context).colorScheme.error : null,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              if (_errorMessage == null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    widget.isEnglish
                        ? 'Shared tips based on your current device/IP will appear here.'
                        : 'Các mẹo bạn đã chia sẻ từ thiết bị này sẽ hiển thị tại đây.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant
                    ),
                  ),
                ),

            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTipsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _myTips.length,
      itemBuilder: (context, index) {
        final tip = _myTips[index];
        final int status = int.tryParse(tip['status'].toString()) ?? 1;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 0,
          color: Theme.of(context).colorScheme.surfaceContainer,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ExpansionTile(
            shape: const RoundedRectangleBorder(side: BorderSide.none),
            collapsedShape: const RoundedRectangleBorder(side: BorderSide.none),
            leading: Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  backgroundColor: _getCategoryColor(tip['category']).withOpacity(0.2),
                  child: Icon(_getCategoryIcon(tip['category']), 
                    color: _getCategoryColor(tip['category']), size: 20),
                ),
                Positioned(
                  right: -4,
                  top: -4,
                  child: _getStatusIcon(status),
                ),
              ],
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tip['title'],
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _getStatusChip(status),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('dd/MM/yyyy').format(DateTime.parse(tip['created_at'])),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 10),
                    ),
                  ],
                ),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Row(
                children: [
                  Icon(Icons.favorite, size: 14, color: Colors.red.shade400),
                  const SizedBox(width: 4),
                  Text('${tip['likes_count']} likes', style: const TextStyle(fontSize: 12)),
                  const SizedBox(width: 12),
                  Icon(Icons.comment, size: 14, color: Colors.blue.shade400),
                  const SizedBox(width: 4),
                  Text('0 comments', style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(),
                    Text(
                      widget.isEnglish ? 'Content:' : 'Nội dung:',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(tip['content']),
                    if (tip['images'] != null && (tip['images'] as List).isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _MyTipImageCarousel(images: List<String>.from(tip['images'])),
                    ] else if (tip['image_url'] != null) ...[
                      const SizedBox(height: 12),
                      _MyTipImageCarousel(images: [tip['image_url']]),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _getStatusIcon(int status) {
    IconData icon;
    Color color;
    switch (status) {
      case 1:
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      case 2:
        icon = Icons.error;
        color = Colors.red;
        break;
      default:
        icon = Icons.access_time_filled;
        color = Colors.orange;
    }
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
      child: Icon(icon, size: 14, color: color),
    );
  }

  Widget _getStatusChip(int status) {
    String label;
    Color color;
    switch (status) {
      case 1:
        label = widget.isEnglish ? 'Published' : 'Đã duyệt';
        color = Colors.green;
        break;
      case 2:
        label = widget.isEnglish ? 'Rejected' : 'Từ chối';
        color = Colors.red;
        break;
      default:
        label = widget.isEnglish ? 'Pending' : 'Chờ duyệt';
        color = Colors.orange;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.5), width: 0.5),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold),
      ),
    );
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
}

class _MyTipImageCarousel extends StatefulWidget {
  final List<String> images;

  const _MyTipImageCarousel({required this.images});

  @override
  State<_MyTipImageCarousel> createState() => _MyTipImageCarouselState();
}

class _MyTipImageCarouselState extends State<_MyTipImageCarousel> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.images.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        SizedBox(
          height: 180,
          child: Stack(
            children: [
              PageView.builder(
                itemCount: widget.images.length,
                onPageChanged: (index) => setState(() => _currentIndex = index),
                itemBuilder: (context, index) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      widget.images[index],
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.broken_image, color: Colors.grey),
                      ),
                    ),
                  );
                },
              ),
              if (widget.images.length > 1)
                Positioned(
                  bottom: 8,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(widget.images.length, (index) {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        width: _currentIndex == index ? 8 : 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: _currentIndex == index ? Colors.blue : Colors.white70,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      );
                    }),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
