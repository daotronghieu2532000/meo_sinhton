class AppI18n {
  static String text({
    required bool isEnglish,
    required String vi,
    required String en,
  }) {
    return isEnglish ? en : vi;
  }

  static String category(String value, bool isEnglish) {
    if (!isEnglish) {
      return value;
    }
    return _categoryMap[value] ?? value;
  }

  static String difficulty(String value, bool isEnglish) {
    if (!isEnglish) {
      return value;
    }
    return _difficultyMap[value] ?? value;
  }

  static String tag(String value, bool isEnglish, {bool isPolish = false}) {
    if (isPolish) {
      // Map tiếng Việt sang tiếng Ba Lan cho các tag phổ biến
      switch (value) {
        case 'khẩn cấp':
          return 'Alarm';
        case 'sinh tồn':
          return 'Przetrwanie';
        case 'nước uống':
          return 'Woda pitna';
        case 'rừng':
          return 'Las';
        case 'sơ cứu':
          return 'Pierwsza pomoc';
        // ...bổ sung thêm nếu cần
        default:
          return value;
      }
    }
    if (!isEnglish) {
      return value;
    }
    return _tagMap[value] ?? value;
  }

  static const Map<String, String> _categoryMap = {
    'Tất cả': 'All',
    'Sinh tồn thiên nhiên': 'Wilderness Survival',
    'Kỹ năng thực hành': 'Practical Skills',
    'Mẹo cuộc sống': 'Life Hacks',
    'Khẩn cấp đô thị': 'Urban Emergency',
    'Sức khỏe': 'Health',
  };

  static const Map<String, String> _difficultyMap = {
    'Cơ bản': 'Basic',
    'Trung bình': 'Intermediate',
    'Nâng cao': 'Advanced',
  };

  static const Map<String, String> _tagMap = {
    'sa mạc': 'desert',
    'định hướng': 'navigation',
    'khẩn cấp': 'emergency',
    'nước uống': 'drinking water',
    'sinh tồn': 'survival',
    'rừng': 'forest',
    'nước': 'water',
    'lọc nước': 'water filtration',
    'núi': 'mountain',
    'mưa giông': 'thunderstorm',
    'an toàn': 'safety',
    'nút dây': 'knots',
    'buộc đồ': 'bundling',
    'outdoor': 'outdoor',
    'lều trại': 'camping',
    'buộc cọc': 'anchor tie',
    'siết chặt': 'tightening',
    'chằng hàng': 'cargo lashing',
    'gấp quần áo': 'folding clothes',
    'ngăn nắp': 'organized',
    'du lịch': 'travel',
    'vali': 'suitcase',
    'khóa cửa': 'door lock',
    'gia đình': 'family',
    'bồn cầu': 'toilet',
    'thông tắc': 'unclogging',
    'sửa chữa': 'repair',
    'gas': 'gas',
    'cháy nổ': 'fire/explosion',
    'động đất': 'earthquake',
    'thiên tai': 'natural disaster',
    'mưa lũ': 'flood',
    'sơ tán': 'evacuation',
    'chuẩn bị': 'preparedness',
    'bỏng': 'burn',
    'sơ cứu': 'first aid',
    'y tế': 'medical',
    'máu cam': 'nosebleed',
    'mất điện': 'power outage',
    'thực phẩm': 'food',
    'xe đạp': 'bike',
    'xích': 'chain',
    'sửa nhanh': 'quick fix',
    'điện thoại': 'phone',
    'pin': 'battery',
    'lửa trại': 'campfire',
    'trekking': 'trekking',
    'suối': 'stream',
    'nước mưa': 'rainwater',
    'thiếu nước': 'water shortage',
    'balo': 'backpack',
    'tối ưu': 'optimization',
  };
}
