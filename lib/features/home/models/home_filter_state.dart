import '../../../models/product.dart';

/// Состояние фильтра на Главной: пустые множества = "без ограничения"
/// (показываются все категории/все товары), а не "ничего не выбрано".
class HomeFilterState {
  final Set<ProductCategory> categories;
  final Set<ProductBadge> badges;

  const HomeFilterState({
    this.categories = const {},
    this.badges = const {},
  });

  bool get isActive => categories.isNotEmpty || badges.isNotEmpty;

  bool matches(Product p) {
    final categoryOk = categories.isEmpty || categories.contains(p.category);
    final badgeOk = badges.isEmpty || (p.badge != null && badges.contains(p.badge));
    return categoryOk && badgeOk;
  }

  HomeFilterState copyWith({Set<ProductCategory>? categories, Set<ProductBadge>? badges}) {
    return HomeFilterState(
      categories: categories ?? this.categories,
      badges: badges ?? this.badges,
    );
  }
}
