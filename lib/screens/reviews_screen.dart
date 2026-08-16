import 'package:flutter/material.dart';

class ReviewsScreen extends StatefulWidget {
  final String productName;
  final String productPrice;
  final String? productImage;
  final double rating;
  final int reviewCount;

  const ReviewsScreen({
    super.key,
    required this.productName,
    required this.productPrice,
    this.productImage,
    this.rating = 4.9,
    this.reviewCount = 64,
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

  final controller = TextEditingController();
  final formKey = GlobalKey();
  int selectedRating = 0;

  final reviews = <_Review>[
    _Review('Анна П.', '12 мая 2026', 5,
        'Очень вкусный эклер! Крем лёгкий, не слишком сладкий, шоколад глазированный. Буду заказывать ещё!', true),
    _Review('Сергей К.', '8 мая 2026', 5,
        'Свежий, нежный, просто тает во рту. Один из лучших эклеров, что я пробовал.'),
    _Review('Мария Л.', '1 мая 2026', 4,
        'Вкусно, но хотелось бы чуть больше крема внутри. В остальном всё отлично!'),
    _Review('Екатерина В.', '28 апреля 2026', 5,
        'Доставили аккуратно, эклер свежий и очень вкусный. Спасибо!'),
    _Review('Дмитрий С.', '24 апреля 2026', 5,
        'Шоколадный вкус идеальный, не приторный. Рекомендую!'),
  ];

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void submit() {
    if (selectedRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Поставьте оценку от 1 до 5')),
      );
      return;
    }
    final value = controller.text.trim();
    setState(() {
      reviews.insert(0, _Review('Вы', 'Сегодня', selectedRating,
          value.isEmpty ? 'Отзыв без комментария.' : value));
      selectedRating = 0;
      controller.clear();
    });
    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Спасибо! Ваш отзыв добавлен.')),
    );
  }

  void openForm() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || formKey.currentContext == null) return;
      Scrollable.ensureVisible(formKey.currentContext!,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic, alignment: .1);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: const Text('Отзывы',
            style: TextStyle(color: text, fontSize: 21, fontWeight: FontWeight.w700)),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: text),
        ),
      ),
      body: SafeArea(
        child: CustomScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              sliver: SliverToBoxAdapter(
                child: _ProductHeader(widget: widget, onWrite: openForm),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              sliver: SliverToBoxAdapter(
                child: _RatingSummary(widget.rating, widget.reviewCount),
              ),
            ),
            const SliverPadding(
              padding: EdgeInsets.fromLTRB(16, 24, 16, 12),
              sliver: SliverToBoxAdapter(
                child: Text('Отзывы клиентов',
                    style: TextStyle(color: text, fontSize: 21, fontWeight: FontWeight.w700)),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList.builder(
                itemCount: reviews.length,
                itemBuilder: (_, i) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _ReviewCard(review: reviews[i]),
                ),
              ),
            ),
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
                      const Text('Оставить отзыв',
                          style: TextStyle(color: text, fontSize: 21, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 14),
                      const Text('Ваша оценка',
                          style: TextStyle(color: secondary, fontSize: 13, fontWeight: FontWeight.w600)),
                      Row(
                        children: List.generate(5, (i) {
                          final n = i + 1;
                          return IconButton(
                            onPressed: () => setState(() => selectedRating = n),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 42, minHeight: 46),
                            icon: Icon(
                              n <= selectedRating ? Icons.star_rounded : Icons.star_outline_rounded,
                              size: 34, color: star,
                            ),
                          );
                        }),
                      ),
                      TextField(
                        controller: controller,
                        minLines: 4,
                        maxLines: 7,
                        maxLength: 500,
                        decoration: InputDecoration(
                          hintText: 'Поделитесь своим мнением о товаре...',
                          filled: true, fillColor: bg,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: const BorderSide(color: border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: const BorderSide(color: border),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: submit,
                          style: FilledButton.styleFrom(
                            backgroundColor: text, foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(52),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                          ),
                          child: const Text('Отправить отзыв',
                              style: TextStyle(fontWeight: FontWeight.w700)),
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
    );
  }
}

class _ProductHeader extends StatelessWidget {
  final ReviewsScreen widget;
  final VoidCallback onWrite;
  const _ProductHeader({required this.widget, required this.onWrite});

  @override
  Widget build(BuildContext context) {
    Widget image;
    if (widget.productImage == null || widget.productImage!.isEmpty) {
      image = const Icon(Icons.image_outlined, color: _ReviewsScreenState.secondary, size: 30);
    } else if (widget.productImage!.startsWith('http')) {
      image = Image.network(widget.productImage!, fit: BoxFit.cover);
    } else {
      image = Image.asset(widget.productImage!, fit: BoxFit.cover);
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _ReviewsScreenState.border),
      ),
      child: Row(children: [
        ClipRRect(borderRadius: BorderRadius.circular(16),
          child: SizedBox(width: 82, height: 82,
            child: Container(color: _ReviewsScreenState.bg, child: image))),
        const SizedBox(width: 13),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.productName, maxLines: 2, overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: _ReviewsScreenState.text, fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 5),
          Text(widget.productPrice,
              style: const TextStyle(color: _ReviewsScreenState.text, fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 5),
          Row(children: [
            const Icon(Icons.star_rounded, color: _ReviewsScreenState.star, size: 18),
            const SizedBox(width: 3),
            Text(widget.rating.toStringAsFixed(1),
                style: const TextStyle(color: _ReviewsScreenState.text, fontWeight: FontWeight.w700)),
            const SizedBox(width: 5),
            Text('(${widget.reviewCount})',
                style: const TextStyle(color: _ReviewsScreenState.secondary)),
          ]),
        ])),
        const SizedBox(width: 7),
        SizedBox(width: 110, child: FilledButton(
          onPressed: onWrite,
          style: FilledButton.styleFrom(
            backgroundColor: _ReviewsScreenState.text, foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          ),
          child: const Text('Написать отзыв', textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
        )),
      ]),
    );
  }
}

class _RatingSummary extends StatelessWidget {
  final double rating;
  final int count;
  const _RatingSummary(this.rating, this.count);

  @override
  Widget build(BuildContext context) {
    const values = [57, 5, 1, 1, 0];
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _ReviewsScreenState.border),
      ),
      child: Row(children: [
        SizedBox(width: 105, child: Column(children: [
          Text(rating.toStringAsFixed(1),
              style: const TextStyle(color: _ReviewsScreenState.text, fontSize: 47, fontWeight: FontWeight.w800)),
          const Row(mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.star_rounded, color: _ReviewsScreenState.star, size: 17),
              Icon(Icons.star_rounded, color: _ReviewsScreenState.star, size: 17),
              Icon(Icons.star_rounded, color: _ReviewsScreenState.star, size: 17),
              Icon(Icons.star_rounded, color: _ReviewsScreenState.star, size: 17),
              Icon(Icons.star_rounded, color: _ReviewsScreenState.star, size: 17),
            ]),
          const SizedBox(height: 6),
          Text('$count отзывов', style: const TextStyle(color: _ReviewsScreenState.secondary, fontSize: 13)),
        ])),
        const SizedBox(width: 12),
        Expanded(child: Column(
          children: List.generate(5, (i) {
            final n = 5 - i;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(children: [
                SizedBox(width: 14, child: Text('$n', style: const TextStyle(color: _ReviewsScreenState.secondary, fontSize: 12))),
                const Icon(Icons.star_rounded, color: _ReviewsScreenState.star, size: 13),
                const SizedBox(width: 6),
                Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(20),
                  child: LinearProgressIndicator(
                    minHeight: 6, value: values[i] / count,
                    backgroundColor: _ReviewsScreenState.bg, color: _ReviewsScreenState.star,
                  ))),
                const SizedBox(width: 7),
                SizedBox(width: 20, child: Text('${values[i]}', textAlign: TextAlign.right,
                    style: const TextStyle(color: _ReviewsScreenState.secondary, fontSize: 11))),
              ]),
            );
          }),
        )),
      ]),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final _Review review;
  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _ReviewsScreenState.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(review.author,
              style: const TextStyle(color: _ReviewsScreenState.text, fontWeight: FontWeight.w700))),
          Text(review.date, style: const TextStyle(color: _ReviewsScreenState.secondary, fontSize: 11)),
          const SizedBox(width: 5),
          const Icon(Icons.more_vert_rounded, size: 18, color: _ReviewsScreenState.secondary),
        ]),
        const SizedBox(height: 6),
        Row(children: List.generate(5, (i) => Icon(
          i < review.rating ? Icons.star_rounded : Icons.star_border_rounded,
          size: 18, color: _ReviewsScreenState.star,
        ))),
        const SizedBox(height: 9),
        Text(review.text,
            style: const TextStyle(color: _ReviewsScreenState.text, fontSize: 13.5, height: 1.45)),
        if (review.photo) ...[
          const SizedBox(height: 12),
          Container(width: 88, height: 88,
            decoration: BoxDecoration(color: _ReviewsScreenState.bg, borderRadius: BorderRadius.circular(15)),
            child: const Icon(Icons.photo_outlined, color: _ReviewsScreenState.secondary)),
        ],
      ]),
    );
  }
}

class _Review {
  final String author, date, text;
  final int rating;
  final bool photo;
  const _Review(this.author, this.date, this.rating, this.text, [this.photo = false]);
}

