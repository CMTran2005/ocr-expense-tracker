import 'package:flutter/material.dart';
import '../../../core/constants/categories.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/utils/currency_formatter.dart';
import '../models/expense_item.dart';
import 'expense_detail_sheet.dart';
import '../../camera_scanner/presentation/camera_screen.dart';

class ExpensesListScreen extends StatefulWidget {
  const ExpensesListScreen({super.key});

  @override
  State<ExpensesListScreen> createState() => ExpensesListScreenState();
}

class ExpensesListScreenState extends State<ExpensesListScreen> {
  List<ExpenseItem> _expenses = [];
  bool _isLoading = true;
  String _searchQuery = '';
  ExpenseCategory? _selectedCategory;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    refreshData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> refreshData() async {
    setState(() => _isLoading = true);
    final items = await DatabaseHelper.instance.getAllExpenses(
      searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
      category: _selectedCategory,
    );
    if (mounted) {
      setState(() {
        _expenses = items;
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteItem(ExpenseItem item) async {
    if (item.id == null) return;
    await DatabaseHelper.instance.deleteExpense(item.id!);
    refreshData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã xóa "${item.merchant}"'),
          action: SnackBarAction(
            label: 'Hoàn tác',
            textColor: const Color(0xFF10B981),
            onPressed: () async {
              await DatabaseHelper.instance.insertExpense(item);
              refreshData();
            },
          ),
        ),
      );
    }
  }

  void _showDetail(ExpenseItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ExpenseDetailSheet(
        item: item,
        onDelete: () => _deleteItem(item),
      ),
    );
  }

  void _confirmClearAll() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
            SizedBox(width: 8),
            Text('Xóa toàn bộ dữ liệu', style: TextStyle(color: Colors.white, fontSize: 18)),
          ],
        ),
        content: const Text(
          'Bạn có chắc chắn muốn xóa sạch toàn bộ lịch sử chi tiêu không? Hành động này sẽ xóa vĩnh viễn tất cả hóa đơn đã lưu.',
          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Hủy', style: TextStyle(color: Color(0xFF94A3B8))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await DatabaseHelper.instance.clearAllExpenses();
              refreshData();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã xóa sạch toàn bộ dữ liệu chi tiêu!'),
                    backgroundColor: Color(0xFF0F172A),
                  ),
                );
              }
            },
            child: const Text('Xóa sạch'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử chi tiêu'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            tooltip: 'Tùy chọn dữ liệu',
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            color: const Color(0xFF1E293B),
            onSelected: (value) async {
              if (value == 'clear') {
                _confirmClearAll();
              } else if (value == 'seed') {
                await DatabaseHelper.instance.seedSampleData();
                refreshData();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Đã nạp 7 hóa đơn mẫu để trải nghiệm biểu đồ!'),
                      backgroundColor: Color(0xFF10B981),
                    ),
                  );
                }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.delete_sweep_rounded, color: Colors.redAccent, size: 20),
                    SizedBox(width: 10),
                    Text('Xóa toàn bộ dữ liệu', style: TextStyle(color: Colors.redAccent, fontSize: 14)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'seed',
                child: Row(
                  children: [
                    Icon(Icons.auto_fix_high_rounded, color: Color(0xFF10B981), size: 20),
                    SizedBox(width: 10),
                    Text('Nạp lại dữ liệu mẫu', style: TextStyle(color: Colors.white, fontSize: 14)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF10B981),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.qr_code_scanner_rounded),
        label: const Text('Quét hóa đơn'),
        onPressed: () async {
          final res = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (context) => const CameraScreen()),
          );
          if (res == true) refreshData();
        },
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm cửa hàng, giao dịch...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF94A3B8)),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Color(0xFF94A3B8)),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                          refreshData();
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (val) {
                setState(() => _searchQuery = val);
                refreshData();
              },
            ),
          ),

          // Category Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('Tất cả'),
                  selected: _selectedCategory == null,
                  onSelected: (val) {
                    setState(() => _selectedCategory = null);
                    refreshData();
                  },
                  selectedColor: const Color(0xFF10B981).withOpacity(0.2),
                  checkmarkColor: const Color(0xFF10B981),
                ),
                const SizedBox(width: 8),
                ...ExpenseCategory.values.map((cat) {
                  final isSelected = _selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      avatar: Icon(cat.icon, size: 16, color: cat.color),
                      label: Text(cat.shortName),
                      selected: isSelected,
                      onSelected: (val) {
                        setState(() => _selectedCategory = val ? cat : null);
                        refreshData();
                      },
                      selectedColor: cat.color.withOpacity(0.2),
                      checkmarkColor: cat.color,
                    ),
                  );
                }),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Transaction List or Empty State
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)))
                : _expenses.isEmpty
                    ? Center(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.receipt_long_outlined,
                                size: 64,
                                color: const Color(0xFF64748B).withOpacity(0.5),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _searchQuery.isNotEmpty || _selectedCategory != null
                                    ? 'Không tìm thấy chi tiêu phù hợp'
                                    : 'Chưa có khoản chi tiêu nào',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _searchQuery.isNotEmpty || _selectedCategory != null
                                    ? 'Thử xóa bộ lọc hoặc tìm kiếm bằng từ khóa khác.'
                                    : 'Hãy bấm nút Quét hóa đơn bên dưới để chụp hóa đơn thật, hoặc nạp dữ liệu mẫu để xem biểu đồ.',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontSize: 13,
                                  height: 1.4,
                                ),
                              ),
                              if (_searchQuery.isEmpty && _selectedCategory == null) ...[
                                const SizedBox(height: 20),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF10B981),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                    elevation: 2,
                                  ),
                                  icon: const Icon(Icons.qr_code_scanner_rounded, size: 20),
                                  label: const Text(
                                    'Quét hóa đơn ngay',
                                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                  ),
                                  onPressed: () async {
                                    final res = await Navigator.of(context).push<bool>(
                                      MaterialPageRoute(builder: (context) => const CameraScreen()),
                                    );
                                    if (res == true) refreshData();
                                  },
                                ),
                                const SizedBox(height: 10),
                                TextButton.icon(
                                  style: TextButton.styleFrom(
                                    foregroundColor: const Color(0xFF94A3B8),
                                  ),
                                  icon: const Icon(Icons.auto_fix_high_rounded, size: 16),
                                  label: const Text('Nạp dữ liệu mẫu (để thử nghiệm biểu đồ)'),
                                  onPressed: () async {
                                    await DatabaseHelper.instance.seedSampleData();
                                    refreshData();
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Đã nạp 7 hóa đơn mẫu để thử nghiệm biểu đồ!'),
                                          backgroundColor: Color(0xFF10B981),
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ],
                            ],
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        color: const Color(0xFF10B981),
                        onRefresh: refreshData,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                          itemCount: _expenses.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final item = _expenses[index];
                            return Dismissible(
                              key: ValueKey(item.id ?? index),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                decoration: BoxDecoration(
                                  color: Colors.redAccent,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(Icons.delete_rounded, color: Colors.white),
                              ),
                              onDismissed: (_) => _deleteItem(item),
                              child: InkWell(
                                onTap: () => _showDetail(item),
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1E293B),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: const Color(0xFF334155)),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: item.category.color.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Icon(item.category.icon, color: item.category.color, size: 22),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.merchant,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                                color: Colors.white,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 3),
                                            Text(
                                              '${item.category.shortName} • ${CurrencyFormatter.formatDate(item.transactionDate)}',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Color(0xFF94A3B8),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        CurrencyFormatter.formatVND(item.amount),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: Color(0xFF10B981),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
