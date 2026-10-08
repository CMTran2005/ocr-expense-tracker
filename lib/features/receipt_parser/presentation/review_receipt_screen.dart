import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../../core/constants/categories.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/utils/currency_formatter.dart';
import '../models/parsed_receipt_draft.dart';
import '../../expense_tracker/models/expense_item.dart';

class ReviewReceiptScreen extends StatefulWidget {
  final ParsedReceiptDraft draft;

  const ReviewReceiptScreen({super.key, required this.draft});

  @override
  State<ReviewReceiptScreen> createState() => _ReviewReceiptScreenState();
}

class _ReviewReceiptScreenState extends State<ReviewReceiptScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _merchantController;
  late TextEditingController _amountController;
  late TextEditingController _notesController;
  late DateTime _selectedDate;
  late ExpenseCategory _selectedCategory;
  bool _isSaving = false;
  bool _showRawOcr = false;

  @override
  void initState() {
    super.initState();
    _merchantController = TextEditingController(text: widget.draft.merchant);
    _amountController = TextEditingController(
      text: widget.draft.totalAmount > 0
          ? widget.draft.totalAmount.toInt().toString()
          : '',
    );
    _notesController = TextEditingController();
    _selectedDate = widget.draft.transactionDate;
    _selectedCategory = widget.draft.suggestedCategory;
  }

  @override
  void dispose() {
    _merchantController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      String? cachedImagePath;
      if (widget.draft.imagePath != null) {
        final srcFile = File(widget.draft.imagePath!);
        if (await srcFile.exists()) {
          final docsDir = await getApplicationDocumentsDirectory();
          final fileName = 'receipt_${DateTime.now().millisecondsSinceEpoch}${p.extension(widget.draft.imagePath!)}';
          final savedImage = await srcFile.copy(p.join(docsDir.path, fileName));
          cachedImagePath = savedImage.path;
        }
      }

      final amount = CurrencyFormatter.parseAmount(_amountController.text);

      final item = ExpenseItem(
        merchant: _merchantController.text.trim(),
        amount: amount,
        category: _selectedCategory,
        transactionDate: _selectedDate,
        receiptImagePath: cachedImagePath,
        rawOcrText: widget.draft.rawText,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );

      await DatabaseHelper.instance.insertExpense(item);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã lưu chi tiêu thành công!'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
        Navigator.of(context).pop(true); // Return success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi lưu giao dịch: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Xác nhận thông tin hóa đơn'),
        actions: [
          IconButton(
            tooltip: _showRawOcr ? 'Ẩn văn bản thô' : 'Xem OCR thô',
            icon: Icon(_showRawOcr ? Icons.text_snippet : Icons.text_snippet_outlined),
            onPressed: () => setState(() => _showRawOcr = !_showRawOcr),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Receipt Thumbnail & Confidence Banner
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: Row(
                  children: [
                    if (widget.draft.imagePath != null && File(widget.draft.imagePath!).existsSync())
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(widget.draft.imagePath!),
                          width: 60,
                          height: 70,
                          fit: BoxFit.cover,
                        ),
                      )
                    else
                      Container(
                        width: 60,
                        height: 70,
                        decoration: BoxDecoration(
                          color: const Color(0xFF334155),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.receipt_long, color: Color(0xFF94A3B8)),
                      ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.auto_awesome, size: 16, color: Color(0xFF10B981)),
                              const SizedBox(width: 6),
                              Text(
                                'Độ tin cậy OCR: ${(widget.draft.confidenceScore * 100).toInt()}%',
                                style: const TextStyle(
                                  color: Color(0xFF10B981),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Vui lòng kiểm tra lại số tiền và cửa hàng trước khi lưu vào sổ.',
                            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              if (_showRawOcr) ...[
                const Text(
                  'Văn bản ML Kit trích xuất (Raw OCR):',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white70),
                ),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF334155)),
                  ),
                  child: Text(
                    widget.draft.rawText.isEmpty ? '(Không tìm thấy chữ)' : widget.draft.rawText,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: Color(0xFFCBD5E1),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Merchant Field
              const Text('Cửa hàng / Người bán', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _merchantController,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.storefront_rounded, color: Color(0xFF94A3B8)),
                  hintText: 'VD: WinMart+, Highlands Coffee...',
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Vui lòng nhập tên người bán' : null,
              ),

              const SizedBox(height: 16),

              // Total Amount Field
              const Text('Tổng số tiền (VNĐ)', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.payments_rounded, color: Color(0xFF10B981)),
                  hintText: 'VD: 150000',
                  suffixText: '₫',
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Vui lòng nhập số tiền';
                  if (CurrencyFormatter.parseAmount(val) <= 0) return 'Số tiền phải lớn hơn 0';
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Category Selector
              const Text('Danh mục chi tiêu', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
              const SizedBox(height: 6),
              DropdownButtonFormField<ExpenseCategory>(
                value: _selectedCategory,
                items: ExpenseCategory.values.map((cat) {
                  return DropdownMenuItem(
                    value: cat,
                    child: Row(
                      children: [
                        Icon(cat.icon, color: cat.color, size: 20),
                        const SizedBox(width: 10),
                        Text(cat.displayName),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedCategory = val);
                },
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.category_rounded, color: Color(0xFF94A3B8)),
                ),
              ),

              const SizedBox(height: 16),

              // Transaction Date Selector
              const Text('Ngày giao dịch', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
              const SizedBox(height: 6),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF334155)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded, size: 20, color: Color(0xFF94A3B8)),
                          const SizedBox(width: 12),
                          Text(
                            CurrencyFormatter.formatDate(_selectedDate),
                            style: const TextStyle(fontSize: 16, color: Colors.white),
                          ),
                        ],
                      ),
                      const Icon(Icons.arrow_drop_down, color: Color(0xFF94A3B8)),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Notes Field
              const Text('Ghi chú (Tùy chọn)', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _notesController,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: 'Thêm ghi chú mặt hàng, mục đích chi tiêu...',
                ),
              ),

              const SizedBox(height: 28),

              // Save Action Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveExpense,
                  icon: _isSaving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.check_circle_rounded),
                  label: Text(_isSaving ? 'Đang lưu...' : 'Xác nhận & Lưu vào sổ'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
