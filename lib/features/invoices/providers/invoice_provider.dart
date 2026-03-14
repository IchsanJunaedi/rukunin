import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/supabase/supabase_client.dart';
import '../models/invoice_model.dart';

final residentInvoicesProvider = FutureProvider.family
    .autoDispose<List<InvoiceModel>, String>((ref, residentId) async {
  final client = ref.watch(supabaseClientProvider);
  
  final data = await client
      .from('invoices')
      .select('*, billing_types(name)')
      .eq('resident_id', residentId)
      .order('year', ascending: false)
      .order('month', ascending: false)
      .limit(6);

  return data.map((e) => InvoiceModel.fromJson(e)).toList();
});

final residentTotalArrearsProvider = FutureProvider.family
    .autoDispose<double, String>((ref, residentId) async {
  final client = ref.watch(supabaseClientProvider);
  
  final data = await client
      .from('invoices')
      .select('amount')
      .eq('resident_id', residentId)
      .neq('status', 'paid');
      
  double total = 0;
  for (var item in data) {
    total += (item['amount'] as num).toDouble();
  }
  return total;
});
