import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../models/product.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/toast.dart';
import '../models/admin_product_meta.dart';

/// Результат экрана добавления/редактирования товара.
/// [deleted] — true, если пользователь удалил товар (тогда [product]/[meta]
/// не используются). Иначе — сохранённые [product] и [meta].
class AdminProductEditResult {
  final Product? product;
  final AdminProductMeta? meta;
  final bool deleted;

  /// Фотографии, выбранные пользователем на устройстве.
  /// Загружаются в Supabase Storage после создания/обновления товара,
  /// когда уже известен product.id.
  final List<XFile> pickedPhotos;

  const AdminProductEditResult.saved(
    Product this.product,
    AdminProductMeta this.meta, {
    this.pickedPhotos = const [],
  }) : deleted = false;
  const AdminProductEditResult.deleted()
    : product = null,
      meta = null,
      deleted = true,
      pickedPhotos = const [];
}

const _units = ['За штуку', 'За кг', 'За упаковку', 'За набор'];

/// Экран «Добавить товар» / «Редактирование товара» — открывается либо
/// с пустой формой (кнопка "Добавить" на экране "Товары"), либо с формой,
/// заполненной данными существующего товара (пункт "Редактировать товар"
/// в меню "⋮" на карточке товара). Заголовок и набор кнопок снизу
/// зависят от режима.
///
/// Основные поля (название, цена, категория, описание, состав, фото)
/// хранятся в общей модели [Product] — той же, что видит клиент в
/// «Каталоге». Административные поля (артикул, склад, себестоимость,
/// история цены, статистика спроса) — в отдельном [AdminProductMeta],
/// которого нет и не должно быть в клиентском приложении.
class AdminProductEditScreen extends StatefulWidget {
  final Product? product;
  final AdminProductMeta? meta;

  const AdminProductEditScreen({super.key, this.product, this.meta});

  bool get isEditing => product != null;

  @override
  State<AdminProductEditScreen> createState() => _AdminProductEditScreenState();
}

class _AdminProductEditScreenState extends State<AdminProductEditScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  late final TextEditingController _nameCtrl;
  late final TextEditingController _articleCtrl;
  late final TextEditingController _subcategoryCtrl;
  late final TextEditingController _descriptionCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _stockCtrl;
  late final TextEditingController _minStockCtrl;
  late final TextEditingController _compositionCtrl;
  late final TextEditingController _techCardCtrl;
  late final TextEditingController _yieldCtrl;
  late final TextEditingController _costCtrl;
  late final TextEditingController _caloriesCtrl;
  late final TextEditingController _proteinCtrl;
  late final TextEditingController _fatCtrl;
  late final TextEditingController _carbsCtrl;

  late ProductCategory _category;
  late String _unit;
  late bool _active;
  late bool _orderable;
  late bool _showInCatalog;
  late List<String> _photos;

  /// Новые фотографии, выбранные с устройства.
  /// Пока не загружены в Supabase Storage.
  late List<XFile> _pickedPhotos;

  final ImagePicker _imagePicker = ImagePicker();

  late List<PriceHistoryEntry> _priceHistory;

  static const _descriptionMax = 255;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    final m = widget.meta ?? AdminProductMeta.blank();

    _tabController = TabController(length: 5, vsync: this);

    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _articleCtrl = TextEditingController(text: m.article);
    _subcategoryCtrl = TextEditingController(text: m.subcategory);
    _descriptionCtrl = TextEditingController(text: p?.description ?? '');
    _priceCtrl = TextEditingController(
      text: p != null ? p.price.toString() : '',
    );
    _stockCtrl = TextEditingController(text: m.stockQuantity.toString());
    _minStockCtrl = TextEditingController(text: m.minStock.toString());
    _compositionCtrl = TextEditingController(text: p?.composition ?? '');
    _techCardCtrl = TextEditingController(text: m.techCardCode);
    _yieldCtrl = TextEditingController(
      text: m.yieldWeight.isNotEmpty ? m.yieldWeight : (p?.weightLabel ?? ''),
    );
    _costCtrl = TextEditingController(
      text: m.costPrice > 0 ? m.costPrice.toString() : '',
    );
    _caloriesCtrl = TextEditingController(
      text: p?.caloriesPer100g?.toString() ?? '',
    );
    _proteinCtrl = TextEditingController(
      text: p?.proteinPer100g?.toString() ?? '',
    );
    _fatCtrl = TextEditingController(text: p?.fatPer100g?.toString() ?? '');
    _carbsCtrl = TextEditingController(text: p?.carbsPer100g?.toString() ?? '');

    _category = p?.category ?? ProductCategory.bread;
    _unit = _units.contains(m.unit) ? m.unit : _units.first;
    _active = m.active;
    _orderable = m.orderable;
    _showInCatalog = m.showInCatalog;
    _photos = List.of(p?.gallery ?? const []);
    _pickedPhotos = [];
    _priceHistory = List.of(m.priceHistory);

    _descriptionCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameCtrl.dispose();
    _articleCtrl.dispose();
    _subcategoryCtrl.dispose();
    _descriptionCtrl.dispose();
    _priceCtrl.dispose();
    _stockCtrl.dispose();
    _minStockCtrl.dispose();
    _compositionCtrl.dispose();
    _techCardCtrl.dispose();
    _yieldCtrl.dispose();
    _costCtrl.dispose();
    _caloriesCtrl.dispose();
    _proteinCtrl.dispose();
    _fatCtrl.dispose();
    _carbsCtrl.dispose();
    super.dispose();
  }

  /// Добавляет фотографию с устройства.
  ///
  /// Галерея позволяет выбрать несколько фотографий.
  /// Камера добавляет одну фотографию за раз.
  Future<void> _addPhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),

            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Выбрать из галереи'),
              onTap: () {
                Navigator.of(context).pop(ImageSource.gallery);
              },
            ),

            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Сделать фото'),
              onTap: () {
                Navigator.of(context).pop(ImageSource.camera);
              },
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (source == null || !mounted) {
      return;
    }

    try {
      if (source == ImageSource.gallery) {
        final images = await _imagePicker.pickMultiImage(
          imageQuality: 84,
          maxWidth: 1600,
          maxHeight: 1600,
        );

        if (images.isEmpty || !mounted) {
          return;
        }

        setState(() {
          _pickedPhotos.addAll(images);
        });

        return;
      }

      final image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 84,
        maxWidth: 1600,
        maxHeight: 1600,
      );

      if (image == null || !mounted) {
        return;
      }

      setState(() {
        _pickedPhotos.add(image);
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      FadeToast.show(
        context,
        'Не удалось выбрать фотографию',
        icon: Icons.error_outline,
      );
    }
  }

  void _removePhoto(int index) {
    setState(() {
      _photos.removeAt(index);
    });
  }

  void _addPriceEntry() {
    final price = int.tryParse(_priceCtrl.text.trim());
    if (price == null || price <= 0) {
      FadeToast.show(
        context,
        'Сначала укажите корректную цену',
        icon: Icons.error_outline,
      );
      return;
    }
    setState(() {
      _priceHistory = [
        PriceHistoryEntry(date: DateTime.now(), price: price, author: 'Сергей'),
        ..._priceHistory,
      ];
    });
    FadeToast.show(
      context,
      'Цена зафиксирована в истории',
      icon: Icons.check_circle_outline,
    );
  }

  bool get _isFormValid =>
      _nameCtrl.text.trim().isNotEmpty &&
      (int.tryParse(_priceCtrl.text.trim()) ?? 0) > 0;

  void _save() {
    final name = _nameCtrl.text.trim();
    final price = int.tryParse(_priceCtrl.text.trim()) ?? 0;
    if (name.isEmpty) {
      FadeToast.show(
        context,
        'Укажите название товара',
        icon: Icons.error_outline,
      );
      _tabController.index = 0;
      return;
    }
    if (price <= 0) {
      FadeToast.show(
        context,
        'Укажите корректную цену',
        icon: Icons.error_outline,
      );
      _tabController.index = 1;
      return;
    }

    final id =
        widget.product?.id ?? 'local-${DateTime.now().millisecondsSinceEpoch}';
    final product = Product(
      id: id,
      name: name,
      price: price,
      imageUrl: _photos.isNotEmpty
          ? _photos.first
          : (widget.product?.imageUrl ?? ''),
      category: _category,
      badge: widget.product?.badge,
      inStock: _orderable,
      isWeighed: widget.product?.isWeighed ?? false,
      rating: widget.product?.rating,
      reviewsCount: widget.product?.reviewsCount,
      weightLabel: _yieldCtrl.text.trim().isNotEmpty
          ? _yieldCtrl.text.trim()
          : (widget.product?.weightLabel ?? '1 шт'),
      description: _descriptionCtrl.text.trim().isEmpty
          ? null
          : _descriptionCtrl.text.trim(),
      caloriesPer100g: int.tryParse(_caloriesCtrl.text.trim()),
      proteinPer100g: double.tryParse(
        _proteinCtrl.text.trim().replaceAll(',', '.'),
      ),
      fatPer100g: double.tryParse(_fatCtrl.text.trim().replaceAll(',', '.')),
      carbsPer100g: double.tryParse(
        _carbsCtrl.text.trim().replaceAll(',', '.'),
      ),
      composition: _compositionCtrl.text.trim().isEmpty
          ? null
          : _compositionCtrl.text.trim(),
      galleryImages: _photos.isEmpty ? null : _photos,
    );

    final meta = AdminProductMeta(
      article: _articleCtrl.text.trim(),
      subcategory: _subcategoryCtrl.text.trim(),
      active: _active,
      unit: _unit,
      stockQuantity: int.tryParse(_stockCtrl.text.trim()) ?? 0,
      minStock: int.tryParse(_minStockCtrl.text.trim()) ?? 0,
      orderable: _orderable,
      showInCatalog: _showInCatalog,
      priceHistory: _priceHistory,
      techCardCode: _techCardCtrl.text.trim(),
      yieldWeight: _yieldCtrl.text.trim(),
      costPrice: int.tryParse(_costCtrl.text.trim()) ?? 0,
    );

    Navigator.of(context).pop(
      AdminProductEditResult.saved(
        product,
        meta,
        pickedPhotos: List<XFile>.of(_pickedPhotos),
      ),
    );
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить товар?'),
        content: Text(
          '«${widget.product?.name}» будет удалён из каталога без возможности восстановления.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Удалить',
              style: TextStyle(color: Color(0xFFB5544A)),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      Navigator.of(context).pop(const AdminProductEditResult.deleted());
    }
  }

  void _showMoreMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.isEditing)
                InkWell(
                  onTap: () {
                    Navigator.of(context).pop();
                    setState(() => _active = !_active);
                    FadeToast.show(
                      context,
                      _active
                          ? 'Товар снова активен'
                          : 'Товар скрыт из каталога',
                      icon: Icons.visibility_outlined,
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      children: [
                        Icon(
                          _active
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 19,
                          color: AppColors.primaryBrown,
                        ),
                        const SizedBox(width: 14),
                        Text(
                          _active ? 'Скрыть товар' : 'Показать товар',
                          style: AppTextStyles.rowLabel,
                        ),
                      ],
                    ),
                  ),
                ),
              InkWell(
                onTap: () {
                  Navigator.of(context).pop();
                  FadeToast.show(
                    context,
                    'Дублирование товара — скоро',
                    icon: Icons.copy_outlined,
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.copy_outlined,
                        size: 19,
                        color: AppColors.primaryBrown,
                      ),
                      const SizedBox(width: 14),
                      Text('Дублировать товар', style: AppTextStyles.rowLabel),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _header(context),
            _tabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _mainTab(),
                  _saleTab(),
                  _compositionTab(),
                  _productionTab(),
                  _statsTab(),
                ],
              ),
            ),
            _bottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
    child: Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.of(context).maybePop(),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.divider),
            ),
            child: const Icon(
              Icons.chevron_left,
              color: AppColors.primaryBrown,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            widget.isEditing ? 'Редактирование товара' : 'Добавить товар',
            style: AppTextStyles.screenTitleSmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        GestureDetector(
          onTap: _showMoreMenu,
          child: Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            child: const Icon(Icons.more_vert, color: AppColors.textSecondary),
          ),
        ),
      ],
    ),
  );

  Widget _tabBar() => TabBar(
    controller: _tabController,
    isScrollable: true,
    labelColor: AppColors.primaryBrown,
    unselectedLabelColor: AppColors.textSecondary,
    indicatorColor: AppColors.primaryBrown,
    labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
    unselectedLabelStyle: const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w500,
    ),
    tabs: const [
      Tab(icon: Icon(Icons.info_outline, size: 17), text: 'Основное'),
      Tab(icon: Icon(Icons.payments_outlined, size: 17), text: 'Продажа'),
      Tab(icon: Icon(Icons.eco_outlined, size: 17), text: 'Состав'),
      Tab(
        icon: Icon(Icons.storefront_outlined, size: 17),
        text: 'Производство',
      ),
      Tab(icon: Icon(Icons.bar_chart_outlined, size: 17), text: 'Статистика'),
    ],
  );

  // ---------------------------------------------------------------------
  // Вкладка "Основное"
  // ---------------------------------------------------------------------
  Widget _mainTab() => ListView(
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
    children: [
      _photosRow(),
      const SizedBox(height: 18),
      _label('Название', required: true),
      _textField(_nameCtrl, hint: 'Например, Хлеб деревенский на закваске'),
      const SizedBox(height: 14),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _label('Артикул'),
                _textField(_articleCtrl, hint: '1001'),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [_label('Категория'), _categoryDropdown()],
            ),
          ),
        ],
      ),
      const SizedBox(height: 14),
      _label('Подкатегория'),
      _textField(_subcategoryCtrl, hint: 'Например, Ремесленный хлеб'),
      const SizedBox(height: 14),
      _label('Краткое описание'),
      TextField(
        controller: _descriptionCtrl,
        maxLines: 4,
        maxLength: _descriptionMax,
        decoration: _inputDecoration(
          hint: 'Пара предложений о товаре для карточки в каталоге',
        ),
      ),
      const SizedBox(height: 10),
      _label('Статус'),
      _segmentedToggle(
        leftLabel: 'Активен',
        rightLabel: 'Скрыт',
        value: _active,
        onChanged: (v) => setState(() => _active = v),
      ),
    ],
  );

  Widget _photosRow() => SizedBox(
    height: 96,
    child: ListView(
      scrollDirection: Axis.horizontal,
      children: [
        // Уже загруженные фотографии из Supabase.
        for (int i = 0; i < _photos.length; i++) ...[
          _photoThumb(
            _photos[i],
            isCover: i == 0,
            onRemove: () => _removePhoto(i),
          ),
          const SizedBox(width: 10),
        ],

        // Новые фотографии, выбранные с устройства.
        for (int i = 0; i < _pickedPhotos.length; i++) ...[
          _pickedPhotoThumb(
            _pickedPhotos[i],
            isCover: _photos.isEmpty && i == 0,
            onRemove: () {
              setState(() {
                _pickedPhotos.removeAt(i);
              });
            },
          ),
          const SizedBox(width: 10),
        ],

        _addPhotoTile(),
      ],
    ),
  );

  Widget _photoThumb(
    String path, {
    required bool isCover,
    required VoidCallback onRemove,
  }) => Stack(
    children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.network(
          path,
          width: 96,
          height: 96,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.broken_image_outlined,
              color: AppColors.divider,
            ),
          ),
        ),
      ),

      if (isCover)
        Positioned(
          left: 6,
          bottom: 6,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: .55),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Главное',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),

      Positioned(
        right: 4,
        top: 4,
        child: GestureDetector(
          onTap: onRemove,
          child: Container(
            width: 22,
            height: 22,
            decoration: const BoxDecoration(
              color: Colors.black54,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.close, size: 14, color: Colors.white),
          ),
        ),
      ),
    ],
  );

  Widget _pickedPhotoThumb(
    XFile photo, {
    required bool isCover,
    required VoidCallback onRemove,
  }) => Stack(
    children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.file(
          File(photo.path),
          width: 96,
          height: 96,
          fit: BoxFit.cover,
        ),
      ),

      if (isCover)
        Positioned(
          left: 6,
          bottom: 6,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: .55),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Главное',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),

      Positioned(
        right: 4,
        top: 4,
        child: GestureDetector(
          onTap: onRemove,
          child: Container(
            width: 22,
            height: 22,
            decoration: const BoxDecoration(
              color: Colors.black54,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.close, size: 14, color: Colors.white),
          ),
        ),
      ),
    ],
  );

  Widget _addPhotoTile() => GestureDetector(
    onTap: _addPhoto,
    child: Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: const Icon(
        Icons.add_a_photo_outlined,
        color: AppColors.primaryBrown,
      ),
    ),
  );

  // ---------------------------------------------------------------------
  // Вкладка "Продажа"
  // ---------------------------------------------------------------------
  Widget _saleTab() => ListView(
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
    children: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _label('Текущая цена', required: true),
                _textField(
                  _priceCtrl,
                  hint: '450',
                  keyboardType: TextInputType.number,
                  suffix: '₽',
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [_label('Единица измерения'), _unitDropdown()],
            ),
          ),
        ],
      ),
      const SizedBox(height: 14),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _label('Наличие на складе'),
                _textField(
                  _stockCtrl,
                  hint: '0',
                  keyboardType: TextInputType.number,
                  suffix: 'шт.',
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _label('Минимальный остаток'),
                _textField(
                  _minStockCtrl,
                  hint: '0',
                  keyboardType: TextInputType.number,
                  suffix: 'шт.',
                ),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      _switchRow(
        'Доступен для заказа',
        _orderable,
        (v) => setState(() => _orderable = v),
      ),
      const SizedBox(height: 10),
      _switchRow(
        'Показывать в каталоге',
        _showInCatalog,
        (v) => setState(() => _showInCatalog = v),
      ),
      const SizedBox(height: 20),
      _card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'История цены',
                    style: AppTextStyles.rowLabel.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _addPriceEntry,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Изменить цену'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryBrown,
                    side: const BorderSide(color: AppColors.divider),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_priceHistory.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Пока нет истории изменения цены',
                  style: AppTextStyles.rowLabelMuted,
                ),
              )
            else
              ..._priceHistory
                  .take(4)
                  .map(
                    (entry) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Text(
                              _formatDate(entry.date),
                              style: AppTextStyles.rowLabelMuted,
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              '${entry.price} ₽',
                              style: AppTextStyles.rowLabel.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              entry.author,
                              style: AppTextStyles.rowLabelMuted,
                              textAlign: TextAlign.end,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ],
        ),
      ),
    ],
  );

  // ---------------------------------------------------------------------
  // Вкладка "Состав"
  // ---------------------------------------------------------------------
  Widget _compositionTab() => ListView(
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
    children: [
      _label('Состав'),
      Text(
        'Ингредиенты через запятую — так же, как показывается покупателю на карточке товара.',
        style: AppTextStyles.rowLabelMuted.copyWith(fontSize: 12),
      ),
      const SizedBox(height: 8),
      TextField(
        controller: _compositionCtrl,
        maxLines: 6,
        decoration: _inputDecoration(
          hint: 'Мука пшеничная высшего сорта, вода, закваска, соль',
        ),
      ),

      const SizedBox(height: 24),

      _label('Пищевая ценность на 100 г'),
      Text(
        'Укажите значения для отображения КБЖУ на карточке товара.',
        style: AppTextStyles.rowLabelMuted.copyWith(fontSize: 12),
      ),

      const SizedBox(height: 12),

      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _label('Калорийность'),
                _textField(
                  _caloriesCtrl,
                  hint: '250',
                  keyboardType: TextInputType.number,
                  suffix: 'ккал',
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _label('Белки'),
                _textField(
                  _proteinCtrl,
                  hint: '8.5',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  suffix: 'г',
                ),
              ],
            ),
          ),
        ],
      ),

      const SizedBox(height: 12),

      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _label('Жиры'),
                _textField(
                  _fatCtrl,
                  hint: '12.0',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  suffix: 'г',
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _label('Углеводы'),
                _textField(
                  _carbsCtrl,
                  hint: '45.0',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  suffix: 'г',
                ),
              ],
            ),
          ),
        ],
      ),
    ],
  );

  // ---------------------------------------------------------------------
  // Вкладка "Производство"
  // ---------------------------------------------------------------------
  Widget _productionTab() => ListView(
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
    children: [
      _label('Технологическая карта'),
      _textField(_techCardCtrl, hint: 'ТТК-ХЛЕБ-001'),
      const SizedBox(height: 14),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _label('Выход готового изделия'),
                _textField(_yieldCtrl, hint: '450 г'),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _label('Себестоимость'),
                _textField(
                  _costCtrl,
                  hint: '156',
                  keyboardType: TextInputType.number,
                  suffix: '₽',
                ),
              ],
            ),
          ),
        ],
      ),
    ],
  );

  // ---------------------------------------------------------------------
  // Вкладка "Статистика"
  // ---------------------------------------------------------------------
  Widget _statsTab() {
    final m = widget.meta;
    if (!widget.isEditing || m == null) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(20, 40, 20, 28),
        children: [
          Column(
            children: [
              const Icon(
                Icons.bar_chart_outlined,
                size: 40,
                color: AppColors.textSecondary,
              ),
              const SizedBox(height: 12),
              Text(
                'Статистика появится после того, как товар опубликуют и покупатели начнут с ним взаимодействовать',
                textAlign: TextAlign.center,
                style: AppTextStyles.rowLabelMuted,
              ),
            ],
          ),
        ],
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      children: [
        _label('Показатели спроса'),
        const SizedBox(height: 8),
        _card(
          child: GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 2.4,
            children: [
              _statTile('В избранном', '${m.favoritesCount}'),
              _statTile('В корзине', '${m.inCartCount}'),
              _statTile('Оформлено заказов', '${m.ordersCount}'),
              _statTile('Отложили (нет в наличии)', '${m.postponedCount}'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _statTile(String label, String value) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: AppTextStyles.rowLabelMuted.copyWith(fontSize: 12)),
      const SizedBox(height: 4),
      Text(
        value,
        style: AppTextStyles.rowLabel.copyWith(
          fontWeight: FontWeight.w700,
          fontSize: 20,
        ),
      ),
    ],
  );

  // ---------------------------------------------------------------------
  // Общие мелкие виджеты
  // ---------------------------------------------------------------------
  Widget _bottomBar() => Container(
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
    decoration: const BoxDecoration(
      color: Colors.white,
      border: Border(top: BorderSide(color: AppColors.divider)),
    ),
    child: SafeArea(
      top: false,
      child: widget.isEditing
          ? Row(
              children: [
                Expanded(
                  flex: 2,
                  child: OutlinedButton.icon(
                    onPressed: _confirmDelete,
                    icon: const Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: Color(0xFFB5544A),
                    ),
                    label: const Text('Удалить товар'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFB5544A),
                      side: const BorderSide(color: AppColors.divider),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 3,
                  child: ElevatedButton.icon(
                    onPressed: _isFormValid ? _save : null,
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Сохранить изменения'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBrown,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            )
          : SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isFormValid ? _save : null,
                icon: const Icon(Icons.check, size: 18),
                label: const Text('Добавить товар'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBrown,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
    ),
  );

  Widget _label(String text, {bool required = false}) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: RichText(
      text: TextSpan(
        style: AppTextStyles.rowLabelMuted,
        children: [
          TextSpan(text: text),
          if (required)
            const TextSpan(
              text: ' *',
              style: TextStyle(color: Color(0xFFB5544A)),
            ),
        ],
      ),
    ),
  );

  InputDecoration _inputDecoration({String? hint, String? suffixText}) =>
      InputDecoration(
        hintText: hint,
        suffixText: suffixText,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primaryBrown),
        ),
      );

  Widget _textField(
    TextEditingController controller, {
    String? hint,
    TextInputType? keyboardType,
    String? suffix,
  }) => TextField(
    controller: controller,
    keyboardType: keyboardType,
    decoration: _inputDecoration(hint: hint, suffixText: suffix),
    onChanged: (_) => setState(() {}),
  );

  Widget _categoryDropdown() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.divider),
    ),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<ProductCategory>(
        value: _category,
        isExpanded: true,
        items: ProductCategory.values
            .map(
              (c) => DropdownMenuItem(
                value: c,
                child: Text(c.label, style: AppTextStyles.rowLabel),
              ),
            )
            .toList(),
        onChanged: (v) {
          if (v != null) setState(() => _category = v);
        },
      ),
    ),
  );

  Widget _unitDropdown() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.divider),
    ),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: _unit,
        isExpanded: true,
        items: _units
            .map(
              (u) => DropdownMenuItem(
                value: u,
                child: Text(u, style: AppTextStyles.rowLabel),
              ),
            )
            .toList(),
        onChanged: (v) {
          if (v != null) setState(() => _unit = v);
        },
      ),
    ),
  );

  Widget _segmentedToggle({
    required String leftLabel,
    required String rightLabel,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) => Container(
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: AppColors.surfaceMuted,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      children: [
        Expanded(
          child: _segmentButton(leftLabel, value, () => onChanged(true)),
        ),
        Expanded(
          child: _segmentButton(rightLabel, !value, () => onChanged(false)),
        ),
      ],
    ),
  );

  Widget _segmentButton(String label, bool selected, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppColors.primaryBrown : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : AppColors.textSecondary,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
      );

  Widget _switchRow(String label, bool value, ValueChanged<bool> onChanged) =>
      Row(
        children: [
          Expanded(child: Text(label, style: AppTextStyles.rowLabel)),
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: AppColors.primaryBrown,
          ),
        ],
      );

  Widget _card({required Widget child}) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppColors.divider),
    ),
    child: child,
  );

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
}
