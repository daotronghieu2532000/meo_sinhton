import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:meo_sinhton/app/app_controller.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/foundation.dart';
import 'package:meo_sinhton/app/admob_config.dart';
import 'package:share_plus/share_plus.dart';

class CommunityPage extends StatefulWidget {
  final AppController appController;
  final bool isEnglish;

  const CommunityPage({
    super.key,
    required this.appController,
    required this.isEnglish,
  });

  @override
  State<CommunityPage> createState() => CommunityPageState();
}

class CommunityPageState extends State<CommunityPage> {
  List<dynamic> _tips = [];
  List<dynamic> _filteredTips = [];
  bool _isLoading = true;
  final String _baseUrl = 'https://codego.io.vn/api/';
  final TextEditingController _searchController = TextEditingController();
  bool _isSearchExpanded = false;

  String _tr({required String vi, required String en, required String pl}) {
    switch (widget.appController.language) {
      case AppLanguage.english:
        return en;
      case AppLanguage.polish:
        return pl;
      case AppLanguage.vietnamese:
        return vi;
    }
  }

  void toggleSearch() {
    setState(() {
      _isSearchExpanded = !_isSearchExpanded;
      if (!_isSearchExpanded) {
        _searchController.clear();
        _filterTips('');
      }
    });
  }

  int _submitCount = 0;
  InterstitialAd? _interstitialAd;
  bool _isInterstitialAdReady = false;

  void _loadInterstitialAd() {
    if (kIsWeb) return;
    InterstitialAd.load(
      adUnitId: AdmobConfig.interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialAdReady = true;
          _interstitialAd?.fullScreenContentCallback =
              FullScreenContentCallback(
                onAdDismissedFullScreenContent: (ad) {
                  ad.dispose();
                  _isInterstitialAdReady = false;
                  _loadInterstitialAd();
                },
                onAdFailedToShowFullScreenContent: (ad, error) {
                  ad.dispose();
                  _isInterstitialAdReady = false;
                  _loadInterstitialAd();
                },
              );
        },
        onAdFailedToLoad: (error) {
          _isInterstitialAdReady = false;
        },
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _interstitialAd?.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _fetchTips();
    _loadInterstitialAd();
  }

  Future<void> _fetchTips() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse(
          '${_baseUrl}get_community_tips.php?user_id=${widget.appController.userId}',
        ),
      );
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
    List<File> selectedImages = [];
    final ImagePicker picker = ImagePicker();

    Future<void> pickImages(
      void Function(void Function()) setModalState,
    ) async {
      try {
        final List<XFile> images = await picker.pickMultiImage(
          maxWidth: 1024,
          maxHeight: 1024,
          imageQuality: 85,
        );
        if (images.isNotEmpty) {
          setModalState(() {
            selectedImages.addAll(images.map((img) => File(img.path)));
          });
        }
      } catch (e) {
        print('Error picking images: $e');
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.9,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                // Facebook-style Header
                AppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  centerTitle: true,
                  leading: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                  title: Text(
                    _tr(
                      vi: 'Tạo bài viết',
                      en: 'Create Post',
                      pl: 'Utworz post',
                    ),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () async {
                        if (titleController.text.isEmpty ||
                            contentController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                _tr(
                                  vi: 'Vui lòng điền tiêu đề và nội dung',
                                  en: 'Please fill title and content',
                                  pl: 'Wypelnij tytul i tresc',
                                ),
                              ),
                            ),
                          );
                          return;
                        }

                        List<String> stepsData = stepControllers
                            .where((c) => c.text.isNotEmpty)
                            .map((c) => c.text)
                            .toList();

                        var request = http.MultipartRequest(
                          'POST',
                          Uri.parse('${_baseUrl}add_community_tip.php'),
                        );
                        request.fields['title'] = titleController.text;
                        request.fields['content'] = contentController.text;
                        request.fields['author_name'] =
                            authorController.text.isEmpty
                            ? _tr(vi: 'Ẩn danh', en: 'Anonymous', pl: 'Anonim')
                            : authorController.text;
                        request.fields['category'] = selectedCategory;
                        request.fields['steps'] = json.encode(stepsData);
                        request.fields['user_id'] = widget.appController.userId;

                        if (selectedImages.isNotEmpty) {
                          for (int i = 0; i < selectedImages.length; i++) {
                            request.files.add(
                              await http.MultipartFile.fromPath(
                                'images[$i]',
                                selectedImages[i].path,
                              ),
                            );
                          }
                        }

                        print('>>> Sending fields: ${request.fields}');
                        final streamedResponse = await request.send();
                        final response = await http.Response.fromStream(
                          streamedResponse,
                        );
                        print('>>> Post Status Code: ${response.statusCode}');
                        print('>>> Post Response Body: ${response.body}');

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
                            _submitCount++;
                            if (!widget
                                    .appController
                                    .areAdsTemporarilyDisabled &&
                                _submitCount % 1 == 0 &&
                                _isInterstitialAdReady &&
                                _interstitialAd != null) {
                              _interstitialAd!.show();
                              _isInterstitialAdReady = false;
                              _interstitialAd = null;
                            }
                          }
                        }
                      },
                      child: Text(
                        _tr(vi: 'ĐĂNG', en: 'POST', pl: 'OPUBLIKUJ'),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color:
                              (titleController.text.isNotEmpty &&
                                  contentController.text.isNotEmpty)
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 1),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      12,
                      16,
                      MediaQuery.of(context).viewInsets.bottom + 20,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // User Info Row
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.primaryContainer,
                              child: Icon(
                                Icons.person,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  TextField(
                                    controller: authorController,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: _tr(
                                        vi: 'Tên của bạn',
                                        en: 'Your name',
                                        pl: 'Twoje imie',
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(30),
                                        borderSide: BorderSide(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.outlineVariant,
                                        ),
                                      ),
                                      isDense: true,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 8,
                                          ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  GestureDetector(
                                    onTap: () => _showCategoryPicker(
                                      context,
                                      setModalState,
                                      (val) => selectedCategory = val,
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.surfaceContainerHighest,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.public,
                                            size: 12,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onSurfaceVariant,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            _getCategoryLabel(selectedCategory),
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                          const Icon(
                                            Icons.arrow_drop_down,
                                            size: 16,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Top Toolbar bar (moved up)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest
                                .withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Text(
                                _tr(
                                  vi: 'Thêm nội dung',
                                  en: 'Add content',
                                  pl: 'Dodaj tresc',
                                ),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              const Spacer(),
                              IconButton(
                                onPressed: () => pickImages(setModalState),
                                icon: const Icon(
                                  Icons.image,
                                  color: Colors.green,
                                  size: 20,
                                ),
                                tooltip: _tr(
                                  vi: 'Thêm ảnh',
                                  en: 'Add photos',
                                  pl: 'Dodaj zdjecia',
                                ),
                              ),
                              IconButton(
                                onPressed: () => _showCategoryPicker(
                                  context,
                                  setModalState,
                                  (val) => selectedCategory = val,
                                ),
                                icon: const Icon(
                                  Icons.label,
                                  color: Colors.blue,
                                  size: 20,
                                ),
                                tooltip: _tr(
                                  vi: 'Đổi danh mục',
                                  en: 'Change category',
                                  pl: 'Zmien kategorie',
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Title Input Styled
                        TextField(
                          controller: titleController,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                          decoration: InputDecoration(
                            hintText: _tr(
                              vi: 'Nhập tiêu đề...',
                              en: 'Enter title...',
                              pl: 'Wpisz tytul...',
                            ),
                            filled: true,
                            fillColor: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest
                                .withOpacity(0.2),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.all(16),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Content Input Styled
                        TextField(
                          controller: contentController,
                          maxLines: null,
                          minLines: 3,
                          style: Theme.of(context).textTheme.bodyLarge,
                          decoration: InputDecoration(
                            hintText: _tr(
                              vi: 'Bạn muốn chia sẻ điều gì?',
                              en: "What\'s on your mind?",
                              pl: 'Co masz na mysli?',
                            ),
                            filled: true,
                            fillColor: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest
                                .withOpacity(0.2),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.all(16),
                          ),
                          onChanged: (val) => setModalState(() {}),
                        ),
                        const SizedBox(height: 20),
                        // Steps section
                        Text(
                          _tr(
                            vi: 'Các bước xử lý',
                            en: 'Implementation Steps',
                            pl: 'Kroki wykonania',
                          ),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...List.generate(stepControllers.length, (index) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  margin: const EdgeInsets.only(top: 12),
                                  decoration: BoxDecoration(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.surfaceContainerHighest,
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '${index + 1}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextField(
                                    controller: stepControllers[index],
                                    decoration: InputDecoration(
                                      hintText: _tr(
                                        vi: 'Chi tiết bước...',
                                        en: 'Step detail...',
                                        pl: 'Szczegoly kroku...',
                                      ),
                                      filled: true,
                                      fillColor: Theme.of(context)
                                          .colorScheme
                                          .surfaceContainerHighest
                                          .withOpacity(0.1),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide.none,
                                      ),
                                    ),
                                    maxLines: null,
                                  ),
                                ),
                                if (stepControllers.length > 2)
                                  IconButton(
                                    icon: const Icon(
                                      Icons.close,
                                      size: 18,
                                      color: Colors.grey,
                                    ),
                                    onPressed: () => setModalState(
                                      () => stepControllers.removeAt(index),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        }),
                        TextButton.icon(
                          onPressed: () => setModalState(
                            () => stepControllers.add(TextEditingController()),
                          ),
                          icon: const Icon(Icons.add_circle_outline),
                          label: Text(
                            _tr(
                              vi: 'Thêm bước',
                              en: 'Add step',
                              pl: 'Dodaj krok',
                            ),
                          ),
                        ),
                        if (selectedImages.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 100,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: selectedImages.length,
                              itemBuilder: (context, index) {
                                return Stack(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        right: 8.0,
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.file(
                                          selectedImages[index],
                                          width: 100,
                                          height: 100,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 4,
                                      right: 12,
                                      child: GestureDetector(
                                        onTap: () => setModalState(
                                          () => selectedImages.removeAt(index),
                                        ),
                                        child: Container(
                                          padding: const EdgeInsets.all(2),
                                          decoration: const BoxDecoration(
                                            color: Colors.black54,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.close,
                                            size: 14,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showCategoryPicker(
    BuildContext context,
    Function setModalState,
    Function onSelect,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(
          _tr(
            vi: 'Chọn danh mục',
            en: 'Select category',
            pl: 'Wybierz kategorie',
          ),
        ),
        children: [
          _categoryOption(
            ctx,
            'tip',
            _tr(vi: 'Mẹo', en: 'Survival tip', pl: 'Porada survivalowa'),
            Icons.lightbulb,
            setModalState,
            onSelect,
          ),
          _categoryOption(
            ctx,
            'experience',
            _tr(vi: 'Kinh nghiệm', en: 'Experience', pl: 'Doswiadczenie'),
            Icons.verified_user,
            setModalState,
            onSelect,
          ),
          _categoryOption(
            ctx,
            'first_aid',
            _tr(vi: 'Sơ cứu', en: 'First aid', pl: 'Pierwsza pomoc'),
            Icons.medical_services,
            setModalState,
            onSelect,
          ),
          _categoryOption(
            ctx,
            'feedback',
            _tr(vi: 'Góp ý', en: 'Feedback', pl: 'Opinie'),
            Icons.feedback,
            setModalState,
            onSelect,
          ),
        ],
      ),
    );
  }

  Widget _categoryOption(
    BuildContext ctx,
    String value,
    String label,
    IconData icon,
    Function setModalState,
    Function onSelect,
  ) {
    return SimpleDialogOption(
      onPressed: () {
        setModalState(() => onSelect(value));
        Navigator.pop(ctx);
      },
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 12),
          Text(label),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          // Thanh tìm kiếm (Animated)
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: Visibility(
              visible: _isSearchExpanded,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: TextField(
                  controller: _searchController,
                  onChanged: _filterTips,
                  decoration: InputDecoration(
                    hintText: _tr(
                      vi: 'Tìm kiếm mẹo, kinh nghiệm...',
                      en: 'Search tips...',
                      pl: 'Szukaj porad i doswiadczen...',
                    ),
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
        label: Text(
          _tr(vi: 'Góp ý & Mẹo', en: 'Share feedback', pl: 'Udostepnij opinie'),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 80,
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          const SizedBox(height: 16),
          Text(
            _tr(
              vi: 'Hãy là người đầu tiên chia sẻ!',
              en: 'Be the first to share!',
              pl: 'Badz pierwsza osoba, ktora sie podzieli!',
            ),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              _tr(
                vi: 'Những câu chuyện và mẹo của bạn có thể cứu sống nhiều sinh mạng.',
                en: 'Your survival stories and tips can save lives.',
                pl: 'Twoje historie i porady survivalowe moga uratowac zycie.',
              ),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipsList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _filteredTips.length,
      itemBuilder: (context, index) {
        final tip = _filteredTips[index];
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
                    CircleAvatar(
                      backgroundColor: _getCategoryColor(
                        tip['category'],
                      ).withOpacity(0.2),
                      radius: 20,
                      child: Icon(
                        _getCategoryIcon(tip['category']),
                        color: _getCategoryColor(tip['category']),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  '${tip['author_name']} ${_getFlagEmoji(tip['country_code'] ?? 'VN')}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: _getCategoryColor(
                                    tip['category'],
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
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
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Text(
                                DateFormat(
                                  'dd/MM/yyyy • HH:mm',
                                ).format(DateTime.parse(tip['created_at'])),
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.public,
                                size: 12,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
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
                    if (tip['title'] != null &&
                        tip['title'].toString().isNotEmpty) ...[
                      Text(
                        tip['title'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                    Text(tip['content'], style: const TextStyle(fontSize: 15)),
                    const SizedBox(height: 8),
                    const SizedBox(height: 8),

                    // Steps (if any)
                    if (tip['steps'] != null &&
                        (tip['steps'] as List).isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Divider(height: 1, thickness: 0.5),
                      const SizedBox(height: 16),
                      Text(
                        _tr(
                          vi: 'Các bước xử lý',
                          en: 'Implementation Steps',
                          pl: 'Kroki wykonania',
                        ),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...(tip['steps'] as List).asMap().entries.map((entry) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                margin: const EdgeInsets.only(top: 1),
                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.surfaceContainerHighest,
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '${entry.key + 1}',
                                  style: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  entry.value.toString(),
                                  style: const TextStyle(
                                    fontSize: 15,
                                    height: 1.5,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      const Divider(height: 1, thickness: 0.5),
                    ],
                    const SizedBox(height: 8),
                  ],
                ),
              ),

              // Image Carousel
              if (tip['images'] != null &&
                  (tip['images'] as List).isNotEmpty) ...[
                const SizedBox(height: 4),
                _TipImageCarousel(images: List<String>.from(tip['images'])),
              ] else if (tip['image_url'] != null) ...[
                const SizedBox(height: 4),
                _TipImageCarousel(images: [tip['image_url']]),
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
                          child: const Icon(
                            Icons.thumb_up,
                            size: 12,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${tip['likes_count'] ?? 0}',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                    Text(
                      _tr(
                        vi: '0 bình luận',
                        en: '0 comments',
                        pl: '0 komentarzy',
                      ),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
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
                      icon: (tip['is_liked'] ?? false)
                          ? Icons.thumb_up
                          : Icons.thumb_up_alt_outlined,
                      label: _tr(vi: 'Thích', en: 'Like', pl: 'Polub'),
                      color: (tip['is_liked'] ?? false)
                          ? Colors.blue
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                      onTap: () => _likeTip(tip['id']),
                    ),
                    _buildActionButton(
                      icon: Icons.chat_bubble_outline,
                      label: _tr(
                        vi: 'Bình luận',
                        en: 'Comment',
                        pl: 'Komentarz',
                      ),
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              _tr(
                                vi: 'Tính năng bình luận sắp ra mắt',
                                en: 'Comments coming soon',
                                pl: 'Komentarze wkrotce',
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    _buildActionButton(
                      icon: Icons.share_outlined,
                      label: _tr(vi: 'Chia sẻ', en: 'Share', pl: 'Udostepnij'),
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
      },
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
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

  Future<void> _shareTip(dynamic tip) async {
    final String content =
        """
${tip['title'] ?? _tr(vi: 'Mẹo sinh tồn', en: 'Survival tip', pl: 'Porada survivalowa')}

${tip['content']}

${tip['steps'] != null && (tip['steps'] as List).isNotEmpty ? (_tr(vi: 'Các bước xử lý:\n', en: 'Steps:\n', pl: 'Kroki:\n')) + (tip['steps'] as List).asMap().entries.map((e) => '${e.key + 1}. ${e.value}').join('\n') : ''}

${_tr(vi: 'Chia sẻ từ ứng dụng Mẹo Sinh Tồn', en: 'Shared from Mẹo Sinh Tồn App', pl: 'Udostepniono z aplikacji Mẹo Sinh Tồn')}
""";
    await Share.share(content);
  }

  Future<void> _likeTip(int tipId) async {
    // 1. Cập nhật UI ngay lập tức (Optimistic Update)
    bool? originalStatus;
    int? originalCount;

    setState(() {
      for (var tip in _tips) {
        if (tip['id'] == tipId) {
          originalStatus = tip['is_liked'] ?? false;
          originalCount = tip['likes_count'] ?? 0;

          tip['is_liked'] = !(tip['is_liked'] ?? false);
          tip['likes_count'] = tip['is_liked']
              ? (tip['likes_count'] ?? 0) + 1
              : (tip['likes_count'] ?? 1) - 1;
          break;
        }
      }
    });

    print('>>> LIKING Tip ID: $tipId for User: ${widget.appController.userId}');
    try {
      final response = await http.post(
        Uri.parse('${_baseUrl}like_community_tip.php'),
        body: {
          'tip_id': tipId.toString(),
          'user_id': widget.appController.userId,
        },
      );

      print('>>> Like Response Code: ${response.statusCode}');
      print('>>> Like Response Body: ${response.body}');

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

  void _showZoomedImage(
    String imageUrl, {
    List<String>? allImages,
    int initialIndex = 0,
  }) {
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
              _TipImageCarousel(
                images: allImages,
                initialIndex: initialIndex,
                isZoomMode: true,
              )
            else
              InteractiveViewer(
                panEnabled: true,
                minScale: 0.5,
                maxScale: 4.0,
                child: Image.network(imageUrl, fit: BoxFit.contain),
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
      case 'tip':
        return Colors.amber;
      case 'experience':
        return Colors.teal;
      case 'first_aid':
        return Colors.red;
      case 'feedback':
        return Colors.blue;
      default:
        return Colors.blueGrey;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'tip':
        return Icons.lightbulb_outline;
      case 'experience':
        return Icons.verified_user_rounded;
      case 'first_aid':
        return Icons.medical_services_rounded;
      case 'feedback':
        return Icons.feedback_rounded;
      default:
        return Icons.more_horiz_rounded;
    }
  }

  String _getCategoryLabel(String category) {
    switch (category) {
      case 'tip':
        return _tr(vi: 'MẸO', en: 'TIP', pl: 'PORADA');
      case 'experience':
        return _tr(vi: 'CHIA SẺ', en: 'STORY', pl: 'HISTORIA');
      case 'first_aid':
        return _tr(vi: 'Y TẾ', en: 'MEDICAL', pl: 'MEDYCZNE');
      case 'feedback':
        return _tr(vi: 'GÓP Ý', en: 'FEEDBACK', pl: 'OPINIA');
      default:
        return _tr(vi: 'KHÁC', en: 'OTHER', pl: 'INNE');
    }
  }
}

class _TipImageCarousel extends StatefulWidget {
  final List<String> images;
  final int initialIndex;
  final bool isZoomMode;

  const _TipImageCarousel({
    required this.images,
    this.initialIndex = 0,
    this.isZoomMode = false,
  });

  @override
  State<_TipImageCarousel> createState() => _TipImageCarouselState();
}

class _TipImageCarouselState extends State<_TipImageCarousel> {
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
          height: widget.isZoomMode
              ? MediaQuery.of(context).size.height * 0.8
              : 220,
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
                    onTap: widget.isZoomMode
                        ? null
                        : () {
                            CommunityPageState parent = context
                                .findAncestorStateOfType<CommunityPageState>()!;
                            parent._showZoomedImage(
                              widget.images[index],
                              allImages: widget.images,
                              initialIndex: index,
                            );
                          },
                    child: widget.isZoomMode
                        ? InteractiveViewer(
                            child: Image.network(
                              widget.images[index],
                              fit: BoxFit.contain,
                            ),
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
                                color: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest
                                    .withOpacity(0.3),
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                                  width: double.infinity,
                                  height: 220,
                                  color: Colors.grey.shade200,
                                  child: const Icon(
                                    Icons.broken_image,
                                    color: Colors.grey,
                                  ),
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
                          color: _currentIndex == index
                              ? Colors.blue
                              : Colors.white.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 2,
                              offset: const Offset(0, 1),
                            ),
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
