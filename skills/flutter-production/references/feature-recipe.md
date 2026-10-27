# Feature Recipe: a complete vertical slice

Example: an **Orders** list with a detail screen. Copy the shape and rename.

## models/order_models.dart

```dart
import 'package:flutter/foundation.dart';

@immutable
class Order {
  const Order({
    required this.id,
    required this.number,
    required this.status,
    required this.total,
    required this.createdAt,
    this.thumbnailUrl,
  });

  final int id;
  final String number;
  final String status;
  final double total;
  final DateTime? createdAt;
  final String? thumbnailUrl;

  factory Order.fromJson(Map<String, dynamic> json) => Order(
        id: (json['id'] as num?)?.toInt() ?? 0,
        number: json['number'] as String? ?? '',
        status: json['status'] as String? ?? 'unknown',
        total: (json['total'] as num?)?.toDouble() ?? 0.0,
        createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
        thumbnailUrl: json['thumbnail_url'] as String?,
      );
}
```

## data/orders_repository.dart

```dart
import '../../../core/network/api_client.dart';
import '../models/order_models.dart';

class OrdersRepository {
  const OrdersRepository({this.client = const ApiClient()});
  final ApiClient client;

  Future<List<Order>> fetchOrders() async {
    final json = await client.get('/orders');
    final rows = json['data'] as List<dynamic>? ?? const [];
    return rows.map((e) => Order.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> cancelOrder(int id, String reason) =>
      client.post('/orders/$id/cancel', {'reason': reason});
}
```

## providers/order_providers.dart

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/ref_cache.dart';
import '../data/orders_repository.dart';
import '../models/order_models.dart';

final ordersRepositoryProvider = Provider<OrdersRepository>((ref) => const OrdersRepository());

final orderStatusFilterProvider = NotifierProvider<OrderStatusFilterNotifier, String>(OrderStatusFilterNotifier.new);

class OrderStatusFilterNotifier extends Notifier<String> {
  @override
  String build() => 'all';
  void set(String status) => state = status;
}

/// Source: the only provider that calls GET /orders.
final ordersProvider = FutureProvider.autoDispose<List<Order>>((ref) async {
  ref.cacheFor(const Duration(minutes: 3));
  return ref.watch(ordersRepositoryProvider).fetchOrders();
});

/// Derived: filtered on the device.
final filteredOrdersProvider = Provider.autoDispose<AsyncValue<List<Order>>>((ref) {
  final status = ref.watch(orderStatusFilterProvider);
  return ref.watch(ordersProvider).whenData(
        (orders) => status == 'all' ? orders : orders.where((o) => o.status == status).toList(),
      );
});
```

## screens/orders_screen.dart

```dart
import 'package:auto_skeleton/auto_skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../core/navigation/slide_page_route.dart';
import '../../../core/utils/currency.dart';
import '../../../core/widgets/app_network_image.dart';
import '../../../core/widgets/app_state_views.dart';
import '../models/order_models.dart';
import '../providers/order_providers.dart';
import 'order_detail_screen.dart';

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(filteredOrdersProvider);
    final bottom = MediaQuery.viewPaddingOf(context).bottom;

    return Scaffold(
      appBar: AppBar(title: const Text('My Orders')),
      body: SafeArea(
        bottom: false, // the list adds viewPadding.bottom itself
        child: RefreshIndicator(
          onRefresh: () => ref.refresh(ordersProvider.future),
          child: orders.when(
            data: (items) => items.isEmpty
                ? AppEmptyView(
                    iconWidget: const HugeIcon(icon: HugeIcons.strokeRoundedShoppingBag01, size: 56),
                    title: 'No orders yet',
                    message: 'Your orders will appear here.',
                    actionLabel: 'Browse products',
                    onAction: () => Navigator.of(context).maybePop(),
                  )
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottom),
                    itemCount: items.length,
                    itemBuilder: (context, i) => _OrderTile(order: items[i]),
                  ),
            loading: () => const _OrdersSkeleton(),
            error: (e, _) => AppErrorView(
              title: 'Could not load orders',
              error: e,
              onRetry: () => ref.invalidate(ordersProvider),
            ),
          ),
        ),
      ),
    );
  }
}

class _OrderTile extends StatelessWidget {
  const _OrderTile({required this.order});
  final Order order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () => context.pushSlide(OrderDetailScreen(orderId: order.id)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              AppNetworkImage(
                imageUrl: order.thumbnailUrl,
                width: 56,
                height: 56,
                memCacheWidth: 150,
                memCacheHeight: 150,
                borderRadius: BorderRadius.circular(10),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(order.number, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleSmall),
                    const SizedBox(height: 2),
                    Text(order.status, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall),
                    const SizedBox(height: 2),
                    // Money gets its own line: a trailing non-flexible Text in the Row
                    // overflowed at 320px @1.5x in the layout-matrix test.
                    Text(formatInr(order.total), maxLines: 1, style: theme.textTheme.titleSmall),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrdersSkeleton extends StatelessWidget {
  const _OrdersSkeleton();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        AutoSkeleton(
          enabled: true,
          skeletonItemCount: 6,
          skeletonItem: Container(
            height: 80,
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(color: cs.surfaceContainerLow, borderRadius: BorderRadius.circular(16)),
            child: const ListTile(title: Text('ORD-000000'), subtitle: Text('Out for delivery')),
          ),
          child: const SizedBox.shrink(),
        ),
      ],
    );
  }
}
```

## Mutation from a bottom sheet (cancel with a reason)

```dart
Future<void> _cancel(BuildContext context, WidgetRef ref, Order order) async {
  final reason = await showAppModalSheet<String>(
    context: context,
    builder: (_) => const ReasonSheet(title: 'Why are you cancelling?'),
  );
  if (reason == null || !context.mounted) return;
  try {
    await ref.read(ordersRepositoryProvider).cancelOrder(order.id, reason);
    ref.invalidate(ordersProvider); // the SOURCE
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order cancelled')));
  } on ApiException catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
  }
}
```

## test/orders_test.dart

```dart
class _FakeOrdersRepository extends OrdersRepository {
  const _FakeOrdersRepository({this.orders = const [], this.fail = false});
  final List<Order> orders;
  final bool fail;

  @override
  Future<List<Order>> fetchOrders() async {
    if (fail) throw const ApiException('Server down', statusCode: 500);
    return orders;
  }
}

Widget _app(OrdersRepository repo) => ProviderScope(
      retry: (_, _) => null, // Riverpod 3 retries failed providers by default; tests must see the error at once
      overrides: [ordersRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp(theme: AppTheme.lightTheme, home: const OrdersScreen()),
    );

void main() {
  testWidgets('renders orders', (tester) async {
    await tester.pumpWidget(_app(const _FakeOrdersRepository(orders: [
      Order(id: 1, number: 'ORD-1', status: 'placed', total: 250, createdAt: null),
    ])));
    await tester.pump();
    expect(find.text('ORD-1'), findsOneWidget);
  });

  testWidgets('error shows retry', (tester) async {
    await tester.pumpWidget(_app(const _FakeOrdersRepository(fail: true)));
    await tester.pump();
    expect(find.text('Could not load orders'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('empty state', (tester) async {
    await tester.pumpWidget(_app(const _FakeOrdersRepository()));
    await tester.pump();
    expect(find.text('No orders yet'), findsOneWidget);
  });

  testLayoutMatrix('orders list does not overflow', (tester) async {
    await tester.pumpWidget(_app(const _FakeOrdersRepository(orders: [
      Order(id: 1, number: 'ORD-WITH-A-VERY-LONG-NUMBER-0000000001', status: 'out_for_delivery', total: 123456, createdAt: null),
    ])));
    await tester.pump();
  });
}
```

Then add a `changes/CHANGELOG.md` entry: `## YYYY-MM-DD — Orders › List: orders list with cache, skeleton, retry, empty state`.
