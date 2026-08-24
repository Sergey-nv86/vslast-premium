import '../models/promotion.dart';
import '../models/promotion_store.dart';

/// Single data-access point for the promotions feature.
///
/// The current implementation keeps the existing local store so the approved
/// UI continues to work unchanged. Supabase persistence will be plugged into
/// this repository next, without coupling screens to the data source.
class PromotionRepository {
  PromotionRepository._();

  static final PromotionRepository instance = PromotionRepository._();

  final PromotionStore _store = PromotionStore.instance;

  List<Promotion> get items => _store.items;

  Future<List<Promotion>> getAll() async => items;

  Future<Promotion?> getById(String id) async {
    for (final promotion in items) {
      if (promotion.id == id) return promotion;
    }
    return null;
  }

  Future<void> create(Promotion promotion) async {
    _store.add(promotion);
  }

  Future<void> update(Promotion promotion) async {
    _store.update(promotion);
  }

  Future<void> delete(String id) async {
    _store.remove(id);
  }

  Future<void> setAvailability(String id, bool value) async {
    _store.setAvailability(id, value);
  }
}
