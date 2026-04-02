import 'package:edu_app_flutter/constants/app_colors.dart';
import 'package:edu_app_flutter/constants/app_ui.dart';
import 'package:edu_app_flutter/models/ocr_models.dart';
import 'package:flutter/material.dart';

class EditableScoreTable extends StatefulWidget {
  const EditableScoreTable({
    super.key,
    required this.rows,
    required this.onChanged,
  });

  final List<OcrScoreRow> rows;
  final ValueChanged<List<OcrScoreRow>> onChanged;

  @override
  State<EditableScoreTable> createState() => _EditableScoreTableState();
}

class _EditableScoreTableState extends State<EditableScoreTable> {
  late List<OcrScoreRow> _rows;

  @override
  void initState() {
    super.initState();
    _rows = List<OcrScoreRow>.from(widget.rows);
  }

  @override
  void didUpdateWidget(covariant EditableScoreTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isSameRows(oldWidget.rows, widget.rows)) {
      _rows = List<OcrScoreRow>.from(widget.rows);
    }
  }

  bool _isSameRows(List<OcrScoreRow> a, List<OcrScoreRow> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      final left = a[i];
      final right = b[i];
      if (left.subject != right.subject ||
          left.hk1 != right.hk1 ||
          left.hk2 != right.hk2 ||
          left.caNam != right.caNam) {
        return false;
      }
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    if (_rows.isEmpty) {
      return const Text(
        'Khong co dong diem OCR cho lop nay.',
        style: TextStyle(
          fontSize: AppFontSizes.dashboardCaption,
          color: AppColors.subtitle,
          fontWeight: FontWeight.w600,
        ),
      );
    }

    return Column(
      children: [
        _buildHeader(),
        const SizedBox(height: 8),
        ...List.generate(_rows.length, (index) => _buildRow(index)),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF4FF),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Row(
        children: [
          _HeaderCell(label: 'Tên môn', flex: 4),
          _HeaderCell(label: 'HK I', flex: 2),
          _HeaderCell(label: 'HK II', flex: 2),
          _HeaderCell(label: 'Cả năm', flex: 2),
        ],
      ),
    );
  }

  Widget _buildRow(int index) {
    final row = _rows[index];
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFF),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFDCE5F4)),
        ),
        child: Row(
          children: [
            _EditableCell(
              flex: 4,
              initialValue: row.subject,
              onChanged: (value) {
                _updateRow(index, row.copyWith(subject: value));
              },
            ),
            _EditableCell(
              flex: 2,
              initialValue: row.hk1,
              onChanged: (value) {
                _updateRow(index, row.copyWith(hk1: value));
              },
            ),
            _EditableCell(
              flex: 2,
              initialValue: row.hk2,
              onChanged: (value) {
                _updateRow(index, row.copyWith(hk2: value));
              },
            ),
            _EditableCell(
              flex: 2,
              initialValue: row.caNam,
              onChanged: (value) {
                _updateRow(index, row.copyWith(caNam: value));
              },
            ),
          ],
        ),
      ),
    );
  }

  void _updateRow(int index, OcrScoreRow next) {
    _rows[index] = next;
    widget.onChanged(List<OcrScoreRow>.from(_rows));
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell({required this.label, required this.flex});

  final String label;
  final int flex;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        softWrap: true,
        style: const TextStyle(
          fontSize: AppFontSizes.dashboardCaption,
          fontWeight: FontWeight.w700,
          color: AppColors.subtitle,
        ),
      ),
    );
  }
}

class _EditableCell extends StatelessWidget {
  const _EditableCell({
    required this.flex,
    required this.initialValue,
    required this.onChanged,
  });

  final int flex;
  final String initialValue;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.only(right: 8),
        child: TextFormField(
          key: ValueKey('$flex-$initialValue'),
          initialValue: initialValue,
          onChanged: onChanged,
          maxLines: null,
          minLines: 1,
          expands: false,
          style: const TextStyle(
            fontSize: AppFontSizes.dashboardBody,
            fontWeight: FontWeight.w600,
            color: AppColors.title,
          ),
          decoration: const InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            filled: true,
            fillColor: AppColors.white,
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFD6DFEE)),
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.primary),
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
          ),
        ),
      ),
    );
  }
}
