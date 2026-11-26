import 'package:flutter/material.dart';
import 'card_3d.dart';
import 'exchange_rate_controller.dart';

class RateBanner extends StatelessWidget {
  final ExchangeRateController ctrl;
  final VoidCallback onChanged;

  const RateBanner({super.key, required this.ctrl, required this.onChanged});

  Future<void> _editRateDialog(BuildContext context) async {
    final c = TextEditingController(text: ctrl.usdToNewSyp.toString());
    final res = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('سعر الصرف (المدير فقط)'),
        content: TextField(
          controller: c,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'سعر 1 دولار بالليرة الجديدة',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.pop(ctx, double.tryParse(c.text.trim())),
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
    c.dispose();

    if (res != null && ctrl.updateRate(res)) {
      onChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    final rate = ctrl.usdToNewSyp;
    final oldRate = ctrl.toOldSyp(1.0);
    return Card3D(
      onTap: ctrl.canEditRate ? () => _editRateDialog(context) : null,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              '1\$ = ${rate.toStringAsFixed(2)} جديدة | ${oldRate.toStringAsFixed(0)} قديمة',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Text(ctrl.canEditRate ? 'تعديل' : 'عرض فقط'),
        ],
      ),
    );
  }
}
