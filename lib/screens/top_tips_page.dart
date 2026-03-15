import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math' as math;
import 'package:intl/intl.dart';
import 'package:meo_sinhton/app/app_controller.dart';
import 'package:share_plus/share_plus.dart';

class TopTipsPage extends StatefulWidget {
  final AppController appController;
  final bool isEnglish;

  const TopTipsPage({
    super.key,
    required this.appController,
    required this.isEnglish,
  });

  @override
  State<TopTipsPage> createState() => _TopTipsPageState();
}

class _TopTipsPageState extends State<TopTipsPage> {
  final String _baseUrl = 'https://codego.io.vn/api/';
  List<dynamic> _topTips = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTopTips();
  }

  Future<void> _shareTip(dynamic tip) async {
    final String content = """
${tip['title'] ?? (widget.isEnglish ? 'Survival Tip' : 'Mẹo sinh tồn')}

${tip['content']}

${tip['steps'] != null && (tip['steps'] as List).isNotEmpty ? (widget.isEnglish ? 'Steps:\n' : 'Các bước xử lý:\n') + (tip['steps'] as List).asMap().entries.map((e) => '${e.key + 1}. ${e.value}').join('\n') : ''}

${widget.isEnglish ? 'Shared from Mẹo Sinh Tồn App' : 'Chia sẻ từ ứng dụng Mẹo Sinh Tồn'}
""";
    await Share.share(content);
  }

  Future<void> _likeTip(dynamic tipIdRaw) async {
    final int tipId = tipIdRaw is String ? int.parse(tipIdRaw) : tipIdRaw;
    
    // 1. Optimistic Update
    bool? originalStatus;
    int? originalCount;

    setState(() {
      for (var tip in _topTips) {
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
          setState(() {
            for (var tip in _topTips) {
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
      print('Error liking: $e');
      if (originalStatus != null) {
        setState(() {
          for (var tip in _topTips) {
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

  Future<void> _fetchTopTips() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(Uri.parse('${_baseUrl}get_top_tips.php'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          setState(() {
            _topTips = data['data'];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error fetching top tips: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchTopTips,
              child: _topTips.isEmpty
                  ? Center(child: Text(widget.isEnglish ? 'No top tips yet' : 'Chưa có góp ý nổi bật'))
                  : ListView.builder(
                      padding: EdgeInsets.zero,
                      itemCount: _topTips.length + ( _topTips.length >= 3 ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (_topTips.length >= 3 && index == 0) {
                          return _buildPodiumBanner();
                        }
                        final actualIndex = _topTips.length >= 3 ? index - 1 : index;
                        final tip = _topTips[actualIndex];
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: _buildTopTipCard(tip, actualIndex),
                        );
                      },
                    ),
            ),
    );
  }

  Widget _buildPodiumBanner() {
    final top3 = _topTips.take(3).toList();
    if (top3.length < 3) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      height: 180,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: const BoxDecoration(
        color: Color(0xFF0F0C29),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF1A1A40),
            Color(0xFF0F0C29),
          ],
        ),
      ),
      child: Stack(
        children: [
          // Background Glow for Top 1
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: 150,
              height: 100,
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.amber.withOpacity(0.12),
                    blurRadius: 50,
                    spreadRadius: 10,
                  ),
                ],
              ),
            ),
          ),
          // Subtle stars background
          Positioned.fill(
            child: Opacity(
              opacity: 0.3,
              child: CustomPaint(
                painter: _StarPainter(),
              ),
            ),
          ),
          // Podium content
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildPodiumSpot(top3[1], 2, Colors.grey.shade300, 40, 40, Icons.military_tech),
                  _buildPodiumSpot(top3[0], 1, Colors.amber, 55, 65, Icons.emoji_events),
                  _buildPodiumSpot(top3[2], 3, Colors.brown.shade200, 40, 30, Icons.military_tech),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPodiumSpot(Map<String, dynamic> tip, int rank, Color color, double avatarSize, double pillarHeight, IconData icon) {
    bool isTop = rank == 1;
    return SizedBox(
      width: 100,
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          // Pillar
          Container(
            width: isTop ? 85 : 75,
            height: pillarHeight,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withOpacity(0.15),
                  Colors.white.withOpacity(0.0),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
              border: Border.all(color: Colors.white.withOpacity(0.15), width: 0.5),
            ),
          ),
          // Floating content above pillar
          Positioned(
            bottom: pillarHeight + 8,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: isTop ? 24 : 18),
                const SizedBox(height: 4),
                Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: color.withOpacity(0.3),
                            blurRadius: 15,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: avatarSize / 2,
                        backgroundColor: color.withOpacity(0.1),
                        backgroundImage: (tip['images'] != null && (tip['images'] as List).isNotEmpty)
                          ? NetworkImage(tip['images'][0])
                          : (tip['image_url'] != null ? NetworkImage(tip['image_url']) : null),
                        child: (tip['images'] == null || (tip['images'] as List).isEmpty) && tip['image_url'] == null 
                          ? Icon(Icons.person, color: Colors.white.withOpacity(0.8), size: avatarSize * 0.5)
                          : null,
                      ),
                    ),
                    Positioned(
                      bottom: -4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF0F0C29), width: 1.5),
                        ),
                        child: Text(
                          '$rank',
                          style: TextStyle(
                            color: isTop ? Colors.black : Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Info Text
          Positioned(
            bottom: 8,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  tip['author_name'] ?? 'Guest',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: isTop ? FontWeight.bold : FontWeight.w500,
                    fontSize: isTop ? 12 : 11,
                  ),
                ),
                GestureDetector(
                  onTap: () => _likeTip(tip['id']),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_getFlagEmoji(tip['country_code'] ?? 'VN'), style: const TextStyle(fontSize: 10)),
                      const SizedBox(width: 4),
                      Text(
                        '${tip['likes_count']}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.85),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        (tip['is_liked'] ?? false) ? Icons.favorite : Icons.favorite_border, 
                        color: (tip['is_liked'] ?? false) ? Colors.redAccent : Colors.white.withOpacity(0.7), 
                        size: 10
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopTipCard(Map<String, dynamic> tip, int index) {
    Color rankColor;
    if (index == 0) rankColor = Colors.amber;
    else if (index == 1) rankColor = Colors.grey.shade400;
    else if (index == 2) rankColor = Colors.brown.shade300;
    else rankColor = Theme.of(context).colorScheme.outlineVariant;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainer,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    CircleAvatar(
                      backgroundColor: _getCategoryColor(tip['category']).withValues(alpha: 0.2),
                      radius: 20,
                      child: Icon(_getCategoryIcon(tip['category']), color: _getCategoryColor(tip['category']), size: 24),
                    ),
                    Positioned(
                      right: -6,
                      top: -6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: rankColor,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            if (index < 3)
                              BoxShadow(color: rankColor.withValues(alpha: 0.4), blurRadius: 4, spreadRadius: 1)
                          ]
                        ),
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: index < 3 ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${tip['author_name']} ${_getFlagEmoji(tip['country_code'] ?? 'VN')}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            DateFormat('dd/MM/yyyy • HH:mm').format(DateTime.parse(tip['created_at'])),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.public, size: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_horiz),
                  onPressed: () {},
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          // Title and Content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (tip['title'] != null) ...[
                  Text(
                    tip['title'],
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                ],
                Text(
                  tip['content'],
                  style: const TextStyle(fontSize: 15),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),

          // Image Carousel
          if (tip['images'] != null && (tip['images'] as List).isNotEmpty) ...[
            const SizedBox(height: 4),
            _TopTipImageCarousel(images: List<String>.from(tip['images'])),
          ] else if (tip['image_url'] != null) ...[
            const SizedBox(height: 4),
            _TopTipImageCarousel(images: [tip['image_url']]),
          ],

          // Engagement Stats
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.thumb_up, size: 12, color: Colors.white),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${tip['likes_count'] ?? 0}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(height: 1, thickness: 1),

          // Action Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(
                  icon: (tip['is_liked'] ?? false) ? Icons.thumb_up : Icons.thumb_up_alt_outlined,
                  label: widget.isEnglish ? 'Like' : 'Thích',
                  color: (tip['is_liked'] ?? false) ? Colors.blue : Theme.of(context).colorScheme.onSurfaceVariant,
                  onTap: () => _likeTip(tip['id']),
                ),
                _buildActionButton(
                  icon: Icons.chat_bubble_outline,
                  label: widget.isEnglish ? 'Comment' : 'Bình luận',
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(widget.isEnglish ? 'Comments coming soon' : 'Tính năng bình luận sắp ra mắt'))
                    );
                  },
                ),
                _buildActionButton(
                  icon: Icons.share_outlined,
                  label: widget.isEnglish ? 'Share' : 'Chia sẻ',
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  onTap: () => _shareTip(tip),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon, 
    required String label, 
    required Color color, 
    required VoidCallback onTap
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showZoomedImage(String imageUrl, {List<String>? allImages, int initialIndex = 0}) {
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
                color: Colors.black.withOpacity(0.9),
              ),
            ),
            if (allImages != null && allImages.length > 1)
              _TopTipImageCarousel(
                images: allImages, 
                initialIndex: initialIndex,
                isZoomMode: true,
              )
            else
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

  String _getFlagEmoji(String countryCode) {
    if (countryCode.length != 2) return '';
    int firstLetter = countryCode.toUpperCase().codeUnitAt(0) - 0x41 + 0x1F1E6;
    int secondLetter = countryCode.toUpperCase().codeUnitAt(1) - 0x41 + 0x1F1E6;
    return String.fromCharCode(firstLetter) + String.fromCharCode(secondLetter);
  }
}

class _StarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    final random = math.Random(42);
    for (int i = 0; i < 40; i++) {
        final x = random.nextDouble() * size.width;
        final y = random.nextDouble() * size.height;
        final radius = random.nextDouble() * 1.5;
        canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _TopTipImageCarousel extends StatefulWidget {
  final List<String> images;
  final int initialIndex;
  final bool isZoomMode;

  const _TopTipImageCarousel({
    required this.images,
    this.initialIndex = 0,
    this.isZoomMode = false,
  });

  @override
  State<_TopTipImageCarousel> createState() => _TopTipImageCarouselState();
}

class _TopTipImageCarouselState extends State<_TopTipImageCarousel> {
  late PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.images.isEmpty) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: widget.isZoomMode ? MediaQuery.of(context).size.height * 0.8 : 220,
          child: Stack(
            children: [
              PageView.builder(
                controller: _pageController,
                itemCount: widget.images.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: widget.isZoomMode ? null : () {
                      _TopTipsPageState parent = context.findAncestorStateOfType<_TopTipsPageState>()!;
                      parent._showZoomedImage(widget.images[index], allImages: widget.images, initialIndex: index);
                    },
                    child: widget.isZoomMode 
                      ? InteractiveViewer(
                          child: Image.network(widget.images[index], fit: BoxFit.contain),
                        )
                      : Image.network(
                          widget.images[index],
                          width: double.infinity,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              width: double.infinity,
                              height: 220,
                              color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                              child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) => Container(
                            width: double.infinity,
                            height: 220,
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.broken_image, color: Colors.grey),
                          ),
                        ),
                  );
                },
              ),
              if (widget.images.length > 1) ...[
                // Dot indicator improved
                Positioned(
                  bottom: 15,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(widget.images.length, (index) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: _currentIndex == index ? 8 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: _currentIndex == index ? Colors.blue : Colors.white.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 2,
                              offset: const Offset(0, 1),
                            )
                          ],
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
