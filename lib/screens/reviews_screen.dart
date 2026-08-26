import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReviewsScreen extends StatefulWidget {
  final String productId;
  final String productName;
  final String productPrice;
  final String? productImage;

  /// Начальные значения приходят из products.
  /// После загрузки реальных отзывов экран использует
  /// фактические данные из product_reviews.
  final double rating;
  final int reviewCount;

  const ReviewsScreen({
    super.key,
    required this.productId,
    required this.productName,
    required this.productPrice,
    this.productImage,
    this.rating = 0,
    this.reviewCount = 0,
  });

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  static const bg = Color(0xFFFAF6F0);
  static const text = Color(0xFF24211F);
  static const secondary = Color(0xFF8D8781);
  static const border = Color(0xFFE8E1D8);
  static const star = Color(0xFFF2A51A);

  final SupabaseClient _supabase = Supabase.instance.client;

  final TextEditingController controller = TextEditingController();
  final GlobalKey formKey = GlobalKey();

  List<_Review> reviews = [];

  int selectedRating = 0;

  bool isLoading = true;
  bool isSubmitting = false;
  bool showForm = false;

  String? loadError;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // LOAD REVIEWS
  // ---------------------------------------------------------------------------

  Future<void> _loadReviews() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      loadError = null;
    });

    try {
      // Отзывы загружаем независимо от profiles.
      //
      // RLS profiles разрешает обычному пользователю читать только
      // собственный профиль. Поэтому нельзя делать profiles частью
      // основного запроса отзывов: иначе отображение отзыва может
      // зависеть от доступа к профилю его автора.
      final rows = await _supabase
          .from('product_reviews')
          .select('''
            id,
            product_id,
            user_id,
            rating,
            review_text,
            created_at
          ''')
          .eq('product_id', widget.productId)
          .order('created_at', ascending: false);

      final loadedReviews = (rows as List)
          .map((row) => _reviewFromSupabase(Map<String, dynamic>.from(row)))
          .toList();

      if (!mounted) return;

      setState(() {
        reviews = loadedReviews;
        isLoading = false;
      });

      debugPrint(
        'DEBUG reviews LOAD SUCCESS: '
        'productId=${widget.productId}, '
        'count=${reviews.length}',
      );

      for (final review in reviews) {
        debugPrint(
          'DEBUG REVIEW: '
          'author=${review.author}, '
          'rating=${review.rating}, '
          'text=${review.text}',
        );
      }
    } on PostgrestException catch (error) {
      debugPrint(
        'DEBUG reviews LOAD ERROR: '
        'message=${error.message}, '
        'code=${error.code}, '
        'details=${error.details}, '
        'hint=${error.hint}',
      );

      if (!mounted) return;

      setState(() {
        isLoading = false;
        loadError = error.message;
      });
    } catch (error) {
      debugPrint('DEBUG reviews LOAD UNKNOWN ERROR: $error');

      if (!mounted) return;

      setState(() {
        isLoading = false;
        loadError = error.toString();
      });
    }
  }

  // ---------------------------------------------------------------------------
  // PARSE REVIEW
  // ---------------------------------------------------------------------------

  _Review _reviewFromSupabase(Map<String, dynamic> row) {
    final profileRaw = row['profiles'];

    Map<String, dynamic> profile = {};

    if (profileRaw is Map) {
      profile = Map<String, dynamic>.from(profileRaw);
    }

    final firstName = profile['first_name']?.toString().trim() ?? '';
    final lastName = profile['last_name']?.toString().trim() ?? '';
    final displayName = profile['display_name']?.toString().trim() ?? '';
    final email = profile['email']?.toString().trim() ?? '';

    String author;

    if (displayName.isNotEmpty) {
      author = displayName;
    } else if (firstName.isNotEmpty || lastName.isNotEmpty) {
      author = '$firstName $lastName'.trim();
    } else if (email.isNotEmpty) {
      author = email;
    } else {
      author = 'Пользователь';
    }

    final ratingValue = row['rating'];

    final int rating = ratingValue is int
        ? ratingValue
        : int.tryParse(ratingValue?.toString() ?? '') ?? 0;

    final createdAt = DateTime.tryParse(row['created_at']?.toString() ?? '');

    return _Review(
      id: row['id']?.toString() ?? '',
      author: author,
      date: _formatDate(createdAt),
      rating: rating.clamp(1, 5),
      text: row['review_text']?.toString() ?? '',
      userId: row['user_id']?.toString(),
    );
  }

  // ---------------------------------------------------------------------------
  // DATE
  // ---------------------------------------------------------------------------

  String _formatDate(DateTime? date) {
    if (date == null) {
      return '';
    }

    final local = date.toLocal();

    const months = <int, String>{
      1: 'января',
      2: 'февраля',
      3: 'марта',
      4: 'апреля',
      5: 'мая',
      6: 'июня',
      7: 'июля',
      8: 'августа',
      9: 'сентября',
      10: 'октября',
      11: 'ноября',
      12: 'декабря',
    };

    return '${local.day} ${months[local.month]} ${local.year}';
  }

  // ---------------------------------------------------------------------------
  // CALCULATED RATING
  // ---------------------------------------------------------------------------

  double get actualRating {
    if (reviews.isEmpty) {
      return 0;
    }

    final total = reviews.fold<int>(0, (sum, review) => sum + review.rating);

    return total / reviews.length;
  }

  int get actualReviewCount => reviews.length;

  int countForRating(int rating) {
    return reviews.where((review) => review.rating == rating).length;
  }

  // ---------------------------------------------------------------------------
  // OPEN FORM
  // ---------------------------------------------------------------------------

  void openForm() {
    if (showForm) {
      _scrollToForm();
      return;
    }

    setState(() {
      showForm = true;
    });

    _scrollToForm();
  }

  void _scrollToForm() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || formKey.currentContext == null) {
        return;
      }

      Scrollable.ensureVisible(
        formKey.currentContext!,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
        alignment: 0.08,
      );
    });
  }

  // ---------------------------------------------------------------------------
  // SUBMIT REVIEW
  // ---------------------------------------------------------------------------

  Future<void> submit() async {
    if (isSubmitting) {
      return;
    }

    final user = _supabase.auth.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Чтобы оставить отзыв, необходимо войти в аккаунт.'),
        ),
      );
      return;
    }

    if (selectedRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Поставьте оценку от 1 до 5')),
      );
      return;
    }

    final value = controller.text.trim();

    if (value.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Напишите несколько слов о товаре.')),
      );
      return;
    }

    if (value.length > 500) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Отзыв не должен быть длиннее 500 символов.'),
        ),
      );
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    debugPrint(
      'DEBUG reviews INSERT: '
      'productId=${widget.productId}, '
      'userId=${user.id}, '
      'rating=$selectedRating',
    );

    try {
      await _supabase.from('product_reviews').insert({
        'product_id': widget.productId,
        'user_id': user.id,
        'rating': selectedRating,
        'review_text': value,
      });

      debugPrint('DEBUG reviews INSERT SUCCESS');

      controller.clear();

      if (!mounted) return;

      setState(() {
        selectedRating = 0;
        showForm = false;
        isSubmitting = false;
      });

      FocusScope.of(context).unfocus();

      await _loadReviews();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Спасибо! Ваш отзыв добавлен.')),
      );
    } on PostgrestException catch (error) {
      debugPrint(
        'DEBUG reviews INSERT ERROR: '
        'message=${error.message}, '
        'code=${error.code}, '
        'details=${error.details}, '
        'hint=${error.hint}',
      );

      if (!mounted) return;

      setState(() {
        isSubmitting = false;
      });

      if (error.code == '23505') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Вы уже оставляли отзыв для этого товара.'),
          ),
        );

        setState(() {
          showForm = false;
          selectedRating = 0;
          controller.clear();
        });

        await _loadReviews();

        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Не удалось отправить отзыв: ${error.message}')),
      );
    } catch (error) {
      debugPrint('DEBUG reviews INSERT UNKNOWN ERROR: $error');

      if (!mounted) return;

      setState(() {
        isSubmitting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Не удалось отправить отзыв. Попробуйте ещё раз.'),
        ),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final rating = actualReviewCount > 0 ? actualRating : widget.rating;

    final count = actualReviewCount > 0
        ? actualReviewCount
        : widget.reviewCount;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: const Text(
          'Отзывы',
          style: TextStyle(
            color: text,
            fontSize: 21,
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: text),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadReviews,
          color: star,
          child: CustomScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            slivers: [
              // -----------------------------------------------------------------
              // PRODUCT HEADER
              // -----------------------------------------------------------------
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                sliver: SliverToBoxAdapter(
                  child: _ProductHeader(
                    productName: widget.productName,
                    productPrice: widget.productPrice,
                    productImage: widget.productImage,
                    rating: rating,
                    reviewCount: count,
                    onWrite: openForm,
                  ),
                ),
              ),

              // -----------------------------------------------------------------
              // RATING SUMMARY
              // -----------------------------------------------------------------
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                sliver: SliverToBoxAdapter(
                  child: _RatingSummary(
                    rating: rating,
                    count: count,
                    countForRating: countForRating,
                  ),
                ),
              ),

              // -----------------------------------------------------------------
              // TITLE
              // -----------------------------------------------------------------
              const SliverPadding(
                padding: EdgeInsets.fromLTRB(16, 24, 16, 12),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    'Отзывы клиентов',
                    style: TextStyle(
                      color: text,
                      fontSize: 21,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),

              // -----------------------------------------------------------------
              // LOADING
              // -----------------------------------------------------------------
              if (isLoading)
                const SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 30),
                  sliver: SliverToBoxAdapter(
                    child: Center(child: CircularProgressIndicator()),
                  ),
                )
              // -----------------------------------------------------------------
              // ERROR
              // -----------------------------------------------------------------
              else if (loadError != null)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 20,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: _ErrorCard(
                      message: loadError!,
                      onRetry: _loadReviews,
                    ),
                  ),
                )
              // -----------------------------------------------------------------
              // EMPTY
              // -----------------------------------------------------------------
              else if (reviews.isEmpty)
                const SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 25),
                  sliver: SliverToBoxAdapter(child: _EmptyReviews()),
                )
              // -----------------------------------------------------------------
              // REVIEWS
              // -----------------------------------------------------------------
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList.builder(
                    itemCount: reviews.length,
                    itemBuilder: (_, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _ReviewCard(review: reviews[index]),
                      );
                    },
                  ),
                ),

              // -----------------------------------------------------------------
              // WRITE REVIEW FORM
              // -----------------------------------------------------------------
              if (showForm)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
                  sliver: SliverToBoxAdapter(
                    child: Container(
                      key: formKey,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Оставить отзыв',
                            style: TextStyle(
                              color: text,
                              fontSize: 21,
                              fontWeight: FontWeight.w700,
                            ),
                          ),

                          const SizedBox(height: 14),

                          const Text(
                            'Ваша оценка',
                            style: TextStyle(
                              color: secondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),

                          const SizedBox(height: 5),

                          Row(
                            children: List.generate(5, (index) {
                              final n = index + 1;

                              return IconButton(
                                onPressed: isSubmitting
                                    ? null
                                    : () {
                                        setState(() {
                                          selectedRating = n;
                                        });
                                      },
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 42,
                                  minHeight: 46,
                                ),
                                icon: Icon(
                                  n <= selectedRating
                                      ? Icons.star_rounded
                                      : Icons.star_outline_rounded,
                                  size: 34,
                                  color: star,
                                ),
                              );
                            }),
                          ),

                          const SizedBox(height: 5),

                          TextField(
                            controller: controller,
                            enabled: !isSubmitting,
                            minLines: 4,
                            maxLines: 7,
                            maxLength: 500,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: InputDecoration(
                              hintText: 'Поделитесь своим мнением о товаре...',
                              filled: true,
                              fillColor: bg,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: const BorderSide(color: border),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: const BorderSide(color: border),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: const BorderSide(color: text),
                              ),
                            ),
                          ),

                          const SizedBox(height: 8),

                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: isSubmitting ? null : submit,
                              style: FilledButton.styleFrom(
                                backgroundColor: text,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: secondary,
                                minimumSize: const Size.fromHeight(52),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                              child: isSubmitting
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      'Отправить отзыв',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// PRODUCT HEADER
// =============================================================================

class _ProductHeader extends StatelessWidget {
  final String productName;
  final String productPrice;
  final String? productImage;
  final double rating;
  final int reviewCount;
  final VoidCallback onWrite;

  const _ProductHeader({
    required this.productName,
    required this.productPrice,
    required this.productImage,
    required this.rating,
    required this.reviewCount,
    required this.onWrite,
  });

  @override
  Widget build(BuildContext context) {
    Widget image;

    if (productImage == null || productImage!.isEmpty) {
      image = const Icon(
        Icons.image_outlined,
        color: _ReviewsScreenState.secondary,
        size: 30,
      );
    } else if (productImage!.startsWith('http')) {
      image = Image.network(
        productImage!,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) {
          return const Icon(
            Icons.image_not_supported_outlined,
            color: _ReviewsScreenState.secondary,
            size: 30,
          );
        },
      );
    } else {
      image = Image.asset(productImage!, fit: BoxFit.cover);
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _ReviewsScreenState.border),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              width: 82,
              height: 82,
              child: Container(color: _ReviewsScreenState.bg, child: image),
            ),
          ),

          const SizedBox(width: 13),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  productName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _ReviewsScreenState.text,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  productPrice,
                  style: const TextStyle(
                    color: _ReviewsScreenState.text,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 5),

                Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      color: _ReviewsScreenState.star,
                      size: 18,
                    ),

                    const SizedBox(width: 3),

                    Text(
                      rating > 0 ? rating.toStringAsFixed(1) : '—',
                      style: const TextStyle(
                        color: _ReviewsScreenState.text,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(width: 5),

                    Text(
                      '($reviewCount)',
                      style: const TextStyle(
                        color: _ReviewsScreenState.secondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 7),

          SizedBox(
            width: 110,
            child: FilledButton(
              onPressed: onWrite,
              style: FilledButton.styleFrom(
                backgroundColor: _ReviewsScreenState.text,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: const Text(
                'Написать отзыв',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// RATING SUMMARY
// =============================================================================

class _RatingSummary extends StatelessWidget {
  final double rating;
  final int count;
  final int Function(int rating) countForRating;

  const _RatingSummary({
    required this.rating,
    required this.count,
    required this.countForRating,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _ReviewsScreenState.border),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 105,
            child: Column(
              children: [
                Text(
                  rating > 0 ? rating.toStringAsFixed(1) : '—',
                  style: const TextStyle(
                    color: _ReviewsScreenState.text,
                    fontSize: 47,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    5,
                    (index) => Icon(
                      index < rating.round()
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      color: _ReviewsScreenState.star,
                      size: 17,
                    ),
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  '$count отзывов',
                  style: const TextStyle(
                    color: _ReviewsScreenState.secondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              children: List.generate(5, (index) {
                final ratingValue = 5 - index;
                final ratingCount = countForRating(ratingValue);

                final progress = count == 0 ? 0.0 : ratingCount / count;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 14,
                        child: Text(
                          '$ratingValue',
                          style: const TextStyle(
                            color: _ReviewsScreenState.secondary,
                            fontSize: 12,
                          ),
                        ),
                      ),

                      const Icon(
                        Icons.star_rounded,
                        color: _ReviewsScreenState.star,
                        size: 13,
                      ),

                      const SizedBox(width: 6),

                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: LinearProgressIndicator(
                            minHeight: 6,
                            value: progress,
                            backgroundColor: _ReviewsScreenState.bg,
                            color: _ReviewsScreenState.star,
                          ),
                        ),
                      ),

                      const SizedBox(width: 7),

                      SizedBox(
                        width: 20,
                        child: Text(
                          '$ratingCount',
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            color: _ReviewsScreenState.secondary,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// REVIEW CARD
// =============================================================================

class _ReviewCard extends StatelessWidget {
  final _Review review;

  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _ReviewsScreenState.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  review.author,
                  style: const TextStyle(
                    color: _ReviewsScreenState.text,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              Text(
                review.date,
                style: const TextStyle(
                  color: _ReviewsScreenState.secondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          Row(
            children: List.generate(
              5,
              (index) => Icon(
                index < review.rating
                    ? Icons.star_rounded
                    : Icons.star_border_rounded,
                size: 18,
                color: _ReviewsScreenState.star,
              ),
            ),
          ),

          const SizedBox(height: 9),

          Text(
            review.text,
            style: const TextStyle(
              color: _ReviewsScreenState.text,
              fontSize: 13.5,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// EMPTY REVIEWS
// =============================================================================

class _EmptyReviews extends StatelessWidget {
  const _EmptyReviews();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _ReviewsScreenState.border),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.rate_review_outlined,
            size: 42,
            color: _ReviewsScreenState.secondary,
          ),
          SizedBox(height: 12),
          Text(
            'Пока нет отзывов',
            style: TextStyle(
              color: _ReviewsScreenState.text,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Будьте первым, кто поделится своим мнением.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _ReviewsScreenState.secondary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// ERROR
// =============================================================================

class _ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorCard({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _ReviewsScreenState.border),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 40,
            color: _ReviewsScreenState.secondary,
          ),

          const SizedBox(height: 10),

          const Text(
            'Не удалось загрузить отзывы',
            style: TextStyle(
              color: _ReviewsScreenState.text,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            message,
            textAlign: TextAlign.center,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _ReviewsScreenState.secondary,
              fontSize: 12,
            ),
          ),

          const SizedBox(height: 14),

          OutlinedButton(onPressed: onRetry, child: const Text('Повторить')),
        ],
      ),
    );
  }
}

// =============================================================================
// MODEL
// =============================================================================

class _Review {
  final String id;
  final String author;
  final String date;
  final int rating;
  final String text;
  final String? userId;

  const _Review({
    required this.id,
    required this.author,
    required this.date,
    required this.rating,
    required this.text,
    this.userId,
  });
}
