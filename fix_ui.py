import re

with open('lib/screens/emergency_map_screen_improved.dart', 'r', encoding='utf-8') as f:
    code = f.read()

# Fix Location Info Card Box shadow
code = code.replace(
'''              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],''',
'''              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],'''
)

# Fix Location Info Card Icon styling
code = code.replace(
'''                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.my_location,
                    color: Colors.white,
                    size: 24,
                  ),
                ),''',
'''                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.my_location_rounded,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    size: 28,
                  ),
                ),'''
)

# Fix Search bar styling
code = code.replace(
'''          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
            ),
            child: TextField(
              decoration: InputDecoration(
                hintText: widget.isEnglish ? 'Search shelters...' : 'Tìm kiếm nơi trú ẩn...',
                prefixIcon: const Icon(Icons.search),''',
'''          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(100),
              borderRadius: BorderRadius.circular(20),
            ),
            child: TextField(
              decoration: InputDecoration(
                hintText: widget.isEnglish ? 'Search shelters...' : 'Tìm kiếm nơi trú ẩn...',
                prefixIcon: const Icon(Icons.search_rounded),'''
)

# Fix Map container radius and shadow
code = code.replace(
'''              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                  ),
                ],
              ),''',
'''              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(20),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),'''
)

# Fix Shelter Card styling
code = code.replace(
'''        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: InkWell(
            onTap: () => _showShelterDetails(shelter),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Icon
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getShelterTypeColor(shelter.type),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getShelterTypeIcon(shelter.type),
                      color: Colors.white,
                      size: 20,
                    ),
                  ),''',
'''        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(10),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: Colors.grey.withAlpha(20)),
          ),
          child: InkWell(
            onTap: () => _showShelterDetails(shelter),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Icon
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _getShelterTypeColor(shelter.type).withAlpha(30),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getShelterTypeIcon(shelter.type),
                      color: _getShelterTypeColor(shelter.type),
                      size: 24,
                    ),
                  ),'''
)

with open('lib/screens/emergency_map_screen_improved.dart', 'w', encoding='utf-8') as f:
    f.write(code)

