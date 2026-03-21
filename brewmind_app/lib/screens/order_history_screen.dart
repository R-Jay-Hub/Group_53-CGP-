import 'package:brewmind_app/models/order_model.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/order_service.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});
  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  final _orderService = OrderService();
  List<OrderModel> _orders = [];
  bool _loading = true;
  String _filterStatus = 'all';

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  // Loard orders
  void _loadOrders() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() => _loading = false);
      return;
    }

    // real time updates
    _orderService
        .getUserOrdersStream(uid)
        .listen(
          (orders) {
            if (mounted) {
              setState(() {
                _orders = orders;
                _loading = false;
              });
            }
          },
          onError: (e) {
            print('❌ Order history error: $e');
            if (mounted) setState(() => _loading = false);
          },
        );
  }

  List<OrderModel> get _filteredOrders {
    if (_filterStatus == 'all') return _orders;
    return _orders.where((o) => o.status == _filterStatus).toList();
  }

  // Status color
  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return const Color(0xFFF4C430);
      case 'preparing':
        return const Color(0xFFA89BC0);
      case 'ready':
        return const Color(0xFF7EB8A4);
      case 'completed':
        return const Color(0xFFC8965A);
      case 'cancelled':
        return const Color(0xFFD4856A);
      default:
        return const Color(0xFF9A8C7E);
    }
  }

  // Status emoji
  String _statusEmoji(String status) {
    switch (status) {
      case 'pending':
        return '🕐';
      case 'preparing':
        return '👨‍🍳';
      case 'ready':
        return '✅';
      case 'completed':
        return '☕';
      case 'cancelled':
        return '❌';
      default:
        return '•';
    }
  }

  int _countByStatus(String status) =>
      _orders.where((o) => o.status == status).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0D0B),
      appBar: AppBar(
        title: const Text(
          'Order History',
          style: TextStyle(
            fontFamily: 'PlayfairDisplay',
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: const Color(0xFF0F0D0B),
        foregroundColor: const Color(0xFFF0E8DC),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            color: const Color(0xFF9A8C7E),
            onPressed: () {
              setState(() => _loading = true);
              _loadOrders();
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFC8965A)),
            )
          : RefreshIndicator(
              color: const Color(0xFFC8965A),
              backgroundColor: const Color(0xFF1A1714),
              onRefresh: () async {
                setState(() => _loading = true);
                _loadOrders();
                await Future.delayed(const Duration(seconds: 1));
              },
              child: _orders.isEmpty
                  ? _buildEmptyState()
                  : CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(child: _buildFilterTabs()),

                        // Order list
                        _filteredOrders.isEmpty
                            ? SliverToBoxAdapter(
                                child: Padding(
                                  padding: const EdgeInsets.all(40),
                                  child: Center(
                                    child: Text(
                                      'No $_filterStatus orders.',
                                      style: const TextStyle(
                                        color: Color(0xFF9A8C7E),
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            : SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (ctx, i) =>
                                      _buildOrderCard(_filteredOrders[i]),
                                  childCount: _filteredOrders.length,
                                ),
                              ),

                        const SliverToBoxAdapter(child: SizedBox(height: 24)),
                      ],
                    ),
            ),
    );
  }

  // Empty state
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🧾', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          const Text(
            'No orders yet',
            style: TextStyle(
              fontFamily: 'PlayfairDisplay',
              color: Color(0xFFF0E8DC),
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Your order history will appear here.',
            style: TextStyle(color: Color(0xFF9A8C7E), fontSize: 13),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC8965A),
              foregroundColor: const Color(0xFF1A1714),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Browse Menu',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  // Filter tabs
  Widget _buildFilterTabs() {
    final tabs = [
      {'key': 'all', 'label': 'All'},
      {'key': 'pending', 'label': '🕐 Pending'},
      {'key': 'preparing', 'label': '👨‍🍳 Preparing'},
      {'key': 'ready', 'label': '✅ Ready'},
      {'key': 'completed', 'label': '☕ Done'},
    ];

    return Container(
      height: 40,
      margin: const EdgeInsets.fromLTRB(0, 16, 0, 12),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: tabs.length,
        itemBuilder: (ctx, i) {
          final tab = tabs[i];
          final isActive = _filterStatus == tab['key'];
          final count = tab['key'] == 'all'
              ? _orders.length
              : _countByStatus(tab['key']!);

          return GestureDetector(
            onTap: () => setState(() => _filterStatus = tab['key']!),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isActive
                    ? const Color(0x22C8965A)
                    : const Color(0xFF1A1714),
                border: Border.all(
                  color: isActive
                      ? const Color(0x55C8965A)
                      : const Color(0xFF2E2820),
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Text(
                    tab['label']!,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isActive
                          ? const Color(0xFFC8965A)
                          : const Color(0xFF9A8C7E),
                    ),
                  ),
                  if (count > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: isActive
                            ? const Color(0xFFC8965A)
                            : const Color(0xFF2E2820),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$count',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: isActive
                              ? const Color(0xFF1A1714)
                              : const Color(0xFF9A8C7E),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOrderCard(OrderModel order) {
    final items = order.drinkList.map((d) {
      final qty = (d['quantity'] ?? 1) as int;
      final name = d['name'] ?? 'Unknown';
      final emoji = d['emoji'] ?? '☕';
      return '$emoji $name${qty > 1 ? ' ×$qty' : ''}';
    }).toList();

    final dateStr = order.date.toLocal().toString().substring(0, 16);
    final orderId = order.orderID.length > 8
        ? '${order.orderID.substring(0, 8)}…'
        : order.orderID;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1714),
        border: Border.all(
          color: order.status == 'ready'
              ? const Color(0x447EB8A4)
              : const Color(0xFF2E2820),
          width: order.status == 'ready' ? 1.5 : 1,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _statusColor(order.status).withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _statusColor(order.status).withOpacity(0.4),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      _statusEmoji(order.status),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order #$orderId',
                        style: const TextStyle(
                          fontFamily: 'DM Mono',
                          fontSize: 12,
                          color: Color(0xFF9A8C7E),
                        ),
                      ),
                      Text(
                        dateStr,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF5A504A),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _statusColor(order.status).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _statusColor(order.status).withOpacity(0.4),
                    ),
                  ),
                  child: Text(
                    order.status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: _statusColor(order.status),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFF2E2820)),

          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...items.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      item,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFFF0E8DC),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                if (order.notes.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Note: ${order.notes}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF9A8C7E),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFF2E2820)),

          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text('⭐ ', style: TextStyle(fontSize: 13)),
                    Text(
                      order.status == 'completed'
                          ? '+10 pts earned'
                          : 'Pts pending',
                      style: TextStyle(
                        fontSize: 12,
                        color: order.status == 'completed'
                            ? const Color(0xFFC8965A)
                            : const Color(0xFF5A504A),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Text(
                  'Rs ${order.totalPrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontFamily: 'PlayfairDisplay',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFC8965A),
                  ),
                ),
              ],
            ),
          ),

          if (order.status == 'ready')
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: const BoxDecoration(
                color: Color(0x227EB8A4),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(14),
                  bottomRight: Radius.circular(14),
                ),
              ),
              child: const Center(
                child: Text(
                  '✅ Your order is ready — please collect it!',
                  style: TextStyle(
                    color: Color(0xFF7EB8A4),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
