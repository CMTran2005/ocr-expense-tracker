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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử chi tiêu'),
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
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey.withOpacity(0.4)),
                            const SizedBox(height: 12),
                            const Text(
                              'Không có chi tiêu nào phù hợp',
                              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 16),
                            ),
                          ],
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
