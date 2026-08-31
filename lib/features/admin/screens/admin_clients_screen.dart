import 'package:flutter/material.dart';

import '../services/admin_clients_service.dart';

class AdminClientsScreen extends StatefulWidget {
  const AdminClientsScreen({super.key});

  @override
  State<AdminClientsScreen> createState() => _AdminClientsScreenState();
}

class _AdminClientsScreenState extends State<AdminClientsScreen> {
  static const bg = Color(0xFFF8F4EE);
  static const brown = Color(0xFF8B5E3C);
  static const dark = Color(0xFF3B281F);
  static const muted = Color(0xFF806F65);
  static const border = Color(0xFFEADFD5);

  final TextEditingController _searchController = TextEditingController();

  List<AdminClient> _clients = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadClients();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadClients() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final clients = await AdminClientsService.instance.fetchClients();

      if (!mounted) return;

      setState(() {
        _clients = clients;
        _loading = false;
      });
    } catch (e) {
      debugPrint('ADMIN CLIENTS ERROR: $e');

      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = 'Не удалось загрузить клиентов';
      });
    }
  }

  List<AdminClient> get _filteredClients {
    final query = _searchController.text.trim().toLowerCase();

    if (query.isEmpty) {
      return _clients;
    }

    return _clients.where((client) {
      return client.name.toLowerCase().contains(query) ||
          client.phone.toLowerCase().contains(query);
    }).toList();
  }

  Future<void> _openClient(AdminClient client) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AdminClientDetailScreen(clientId: client.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final clients = _filteredClients;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 20,
        title: const Text(
          'Клиенты',
          style: TextStyle(
            color: dark,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: RefreshIndicator(
        color: brown,
        onRefresh: _loadClients,
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: brown))
            : _error != null
            ? _buildError()
            : ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
                children: [
                  _buildSummary(),
                  const SizedBox(height: 14),
                  _buildSearch(),
                  const SizedBox(height: 16),
                  if (clients.isEmpty)
                    _buildEmpty()
                  else
                    ...clients.map((client) => _buildClientCard(client)),
                ],
              ),
      ),
    );
  }

  Widget _buildError() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 180),
        Center(
          child: Column(
            children: [
              const Icon(Icons.people_outline, size: 48, color: muted),
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: dark, fontSize: 15)),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: _loadClients,
                child: const Text('Повторить'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummary() {
    final now = DateTime.now();

    final weekAgo = now.subtract(const Duration(days: 7));

    final newThisWeek = _clients.where((client) {
      final date = client.registeredAt;

      return date != null && !date.isBefore(weekAgo);
    }).length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: Color(0xFFF1E8E0),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.people_outline, color: brown),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_clients.length}',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: dark,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'всего клиентов',
                  style: TextStyle(fontSize: 13, color: muted),
                ),
              ],
            ),
          ),
          Text(
            '+$newThisWeek',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: brown,
            ),
          ),
          const SizedBox(width: 4),
          const Text('за 7 дней', style: TextStyle(fontSize: 12, color: muted)),
        ],
      ),
    );
  }

  Widget _buildSearch() {
    return TextField(
      controller: _searchController,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        hintText: 'Поиск клиента или телефона',
        prefixIcon: const Icon(Icons.search_rounded, color: muted),
        suffixIcon: _searchController.text.isEmpty
            ? null
            : IconButton(
                onPressed: () {
                  _searchController.clear();
                  setState(() {});
                },
                icon: const Icon(Icons.close_rounded),
              ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: brown),
        ),
      ),
    );
  }

  Widget _buildClientCard(AdminClient client) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _openClient(client),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF1E8E0),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _initials(client.name),
                    style: const TextStyle(
                      color: brown,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        client.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: dark,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        client.phone,
                        style: const TextStyle(color: muted, fontSize: 13),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Последнее действие: '
                        '${_formatDateTime(client.lastActionAt)}',
                        style: const TextStyle(color: muted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: muted),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return const Padding(
      padding: EdgeInsets.only(top: 90),
      child: Column(
        children: [
          Icon(Icons.people_outline, size: 52, color: muted),
          SizedBox(height: 14),
          Text(
            'Клиенты не найдены',
            style: TextStyle(
              color: dark,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .toList();

    if (parts.isEmpty) return 'К';

    if (parts.length == 1) {
      final value = parts.first;

      return value.substring(0, value.length >= 2 ? 2 : 1).toUpperCase();
    }

    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  String _formatDateTime(DateTime? date) {
    if (date == null) {
      return 'нет данных';
    }

    final local = date.toLocal();
    final now = DateTime.now();

    final sameDay =
        local.year == now.year &&
        local.month == now.month &&
        local.day == now.day;

    if (sameDay) {
      return 'сегодня, '
          '${_two(local.hour)}:'
          '${_two(local.minute)}';
    }

    final yesterday = now.subtract(const Duration(days: 1));

    final isYesterday =
        local.year == yesterday.year &&
        local.month == yesterday.month &&
        local.day == yesterday.day;

    if (isYesterday) {
      return 'вчера, '
          '${_two(local.hour)}:'
          '${_two(local.minute)}';
    }

    return '${_two(local.day)}.'
        '${_two(local.month)}.'
        '${local.year} '
        '${_two(local.hour)}:'
        '${_two(local.minute)}';
  }

  String _two(int value) => value.toString().padLeft(2, '0');
}

// ============================================================
// CLIENT DETAIL
// ============================================================

class AdminClientDetailScreen extends StatefulWidget {
  final String clientId;

  const AdminClientDetailScreen({super.key, required this.clientId});

  @override
  State<AdminClientDetailScreen> createState() =>
      _AdminClientDetailScreenState();
}

class _AdminClientDetailScreenState extends State<AdminClientDetailScreen> {
  static const bg = Color(0xFFF8F4EE);
  static const brown = Color(0xFF8B5E3C);
  static const dark = Color(0xFF3B281F);
  static const muted = Color(0xFF806F65);
  static const border = Color(0xFFEADFD5);

  AdminClientDetails? _details;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final details = await AdminClientsService.instance.fetchClientDetails(
        widget.clientId,
      );

      if (!mounted) return;

      setState(() {
        _details = details;
        _loading = false;
      });
    } catch (e) {
      debugPrint('ADMIN CLIENT DETAIL ERROR: $e');

      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = 'Не удалось загрузить данные клиента';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 0,
        title: const Text(
          'Профиль клиента',
          style: TextStyle(
            color: dark,
            fontSize: 21,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: brown))
          : _error != null
          ? _buildError()
          : _details == null
          ? const SizedBox.shrink()
          : RefreshIndicator(
              color: brown,
              onRefresh: _loadDetails,
              child: _buildContent(_details!),
            ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.person_off_outlined, size: 48, color: muted),
          const SizedBox(height: 12),
          Text(_error!, style: const TextStyle(color: dark, fontSize: 15)),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: _loadDetails,
            child: const Text('Повторить'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(AdminClientDetails details) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
      children: [
        _buildProfileHeader(details),
        const SizedBox(height: 12),
        _buildMetrics(details),
        const SizedBox(height: 18),
        const Text(
          'История заказов',
          style: TextStyle(
            color: dark,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        if (details.orders.isEmpty)
          _buildNoOrders()
        else
          ...details.orders.map(_buildOrderCard),
      ],
    );
  }

  Widget _buildProfileHeader(AdminClientDetails details) {
    final client = details.client;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: const BoxDecoration(
              color: Color(0xFFF1E8E0),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              _initials(client.name),
              style: const TextStyle(
                color: brown,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  client.name,
                  style: const TextStyle(
                    color: dark,
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  client.phone,
                  style: const TextStyle(color: muted, fontSize: 14),
                ),
                const SizedBox(height: 6),
                Text(
                  'Клиент с '
                  '${_formatDate(client.registeredAt)}',
                  style: const TextStyle(color: muted, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetrics(AdminClientDetails details) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                icon: Icons.receipt_long_outlined,
                title: 'Заказов',
                value: '${details.ordersCount}',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricCard(
                icon: Icons.payments_outlined,
                title: 'Покупки',
                value: '${_money(details.totalPurchases)} ₽',
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                icon: Icons.card_giftcard_outlined,
                title: 'Бонусы',
                value: _money(details.client.bonusBalance),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricCard(
                icon: Icons.calendar_today_outlined,
                title: 'Последний заказ',
                value: _formatDate(details.lastOrderAt),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOrderCard(AdminClientOrder order) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: Color(0xFFF1E8E0),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.receipt_long_outlined,
                color: brown,
                size: 21,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Заказ №${order.number}',
                    style: const TextStyle(
                      color: dark,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDateTime(order.date),
                    style: const TextStyle(color: muted, fontSize: 12),
                  ),
                  const SizedBox(height: 5),
                  _StatusChip(status: order.status),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${_money(order.amount)} ₽',
              style: const TextStyle(
                color: dark,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoOrders() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
      ),
      child: const Column(
        children: [
          Icon(Icons.receipt_long_outlined, size: 44, color: muted),
          SizedBox(height: 12),
          Text(
            'Заказов пока нет',
            style: TextStyle(
              color: dark,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .toList();

    if (parts.isEmpty) return 'К';

    if (parts.length == 1) {
      final value = parts.first;

      return value.substring(0, value.length >= 2 ? 2 : 1).toUpperCase();
    }

    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  String _money(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }

    return value.toStringAsFixed(2).replaceAll('.', ',');
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'нет данных';

    final local = date.toLocal();

    return '${_two(local.day)}.'
        '${_two(local.month)}.'
        '${local.year}';
  }

  String _formatDateTime(DateTime? date) {
    if (date == null) {
      return 'нет даты';
    }

    final local = date.toLocal();

    return '${_two(local.day)}.'
        '${_two(local.month)}.'
        '${local.year} · '
        '${_two(local.hour)}:'
        '${_two(local.minute)}';
  }

  String _two(int value) => value.toString().padLeft(2, '0');
}

// ============================================================
// SMALL UI COMPONENTS
// ============================================================

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _MetricCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  static const brown = Color(0xFF8B5E3C);
  static const dark = Color(0xFF3B281F);
  static const muted = Color(0xFF806F65);
  static const border = Color(0xFFEADFD5);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              color: Color(0xFFF1E8E0),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: brown, size: 19),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: muted, fontSize: 11),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: dark,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final normalized = status.toLowerCase();

    String label = status;

    if (normalized.contains('cancel') || normalized.contains('отмен')) {
      label = 'Отменён';
    } else if (normalized.contains('complete') ||
        normalized.contains('completed') ||
        normalized.contains('заверш')) {
      label = 'Завершён';
    } else if (normalized.contains('deliver') ||
        normalized.contains('достав')) {
      label = 'Доставлен';
    } else if (normalized.contains('ready') || normalized.contains('готов')) {
      label = 'Готов';
    } else if (normalized.contains('process') || normalized.contains('готов')) {
      label = 'В работе';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1E8E0),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF8B5E3C),
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
