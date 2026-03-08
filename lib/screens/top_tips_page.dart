import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math' as math;
import 'package:intl/intl.dart';
import 'package:meo_sinhton/app/app_controller.dart';

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
                        backgroundImage: tip['image_url'] != null ? NetworkImage(tip['image_url']) : null,
                        child: tip['image_url'] == null 
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
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ExpansionTile(
        shape: const RoundedRectangleBorder(side: BorderSide.none),
        collapsedShape: const RoundedRectangleBorder(side: BorderSide.none),
        leading: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            CircleAvatar(
              backgroundColor: _getCategoryColor(tip['category']).withOpacity(0.2),
              child: Icon(_getCategoryIcon(tip['category']), color: _getCategoryColor(tip['category']), size: 18),
            ),
            Positioned(
              right: -10,
              top: -6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: rankColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    if (index < 3)
                      BoxShadow(color: rankColor.withOpacity(0.4), blurRadius: 4, spreadRadius: 1)
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
              Container(
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
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      widget.isEnglish ? 'Description:' : 'Mô tả:',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(
                        (tip['is_liked'] ?? false) ? Icons.favorite : Icons.favorite_border,
                        size: 18, 
                        color: (tip['is_liked'] ?? false) ? Colors.red.shade400 : Colors.grey
                      ),
                      onPressed: () => _likeTip(tip['id']),
                      visualDensity: VisualDensity.compact,
                    ),
                    const SizedBox(width: 2),
                    Text('${tip['likes_count']} likes', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  tip['content'],
                  style: const TextStyle(fontSize: 14, height: 1.5),
                ),
                if (tip['image_url'] != null) ...[
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => _showZoomedImage(tip['image_url']),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5)),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(11),
                        child: Image.network(
                          tip['image_url'],
                          fit: BoxFit.cover,
                          height: 220,
                          width: double.infinity,
                          errorBuilder: (context, error, stackTrace) => const SizedBox(),
                        ),
                      ),
                    ),
                  ),
                ],
                if (tip['steps'] != null && (tip['steps'] as List).isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    widget.isEnglish ? 'Implementation steps:' : 'Các bước thực hiện:',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  ...(tip['steps'] as List).asMap().entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 2, right: 10),
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
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              entry.value.toString(),
                              style: const TextStyle(fontSize: 14, height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ],
            ),
          ),
        ],
      ),
    );
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
