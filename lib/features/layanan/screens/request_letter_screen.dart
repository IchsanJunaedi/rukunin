import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../app/tokens.dart';
import '../../../core/supabase/supabase_client.dart';
import '../models/letter_request_model.dart';
import '../providers/layanan_provider.dart';

class RequestLetterScreen extends ConsumerStatefulWidget {
  final String? initialType;

  const RequestLetterScreen({super.key, this.initialType});

  @override
  ConsumerState<RequestLetterScreen> createState() =>
      _RequestLetterScreenState();
}

class _RequestLetterScreenState extends ConsumerState<RequestLetterScreen> {
  final _formKey = GlobalKey<FormState>();
  late String? _selectedType;
  final _purposeCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType;
  }

  @override
  void dispose() {
    _purposeCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final service = ref.read(layananServiceProvider);
      final client = ref.read(supabaseClientProvider);
      final userId = client.auth.currentUser!.id;
      final profile = await client
          .from('profiles')
          .select('community_id')
          .eq('id', userId)
          .single();
      await service.createLetterRequest(
        communityId: profile['community_id'] as String,
        residentId: userId,
        letterType: _selectedType!,
        purpose: _purposeCtrl.text.trim(),
        notes: _notesCtrl.text.trim().isEmpty
            ? null
            : _notesCtrl.text.trim(),
      );
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permohonan berhasil dikirim!'),
            backgroundColor: RukuninColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Gagal: $e'), backgroundColor: RukuninColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Permohonan Surat'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                // ignore: deprecated_member_use
                value: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Jenis Surat',
                ),
                items: letterRequestTypeLabels.entries
                    .map(
                      (e) => DropdownMenuItem(
                        value: e.key,
                        child: Text(e.value),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _selectedType = v),
                validator: (v) =>
                    v == null ? 'Jenis surat wajib dipilih' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _purposeCtrl,
                decoration: const InputDecoration(
                  labelText: 'Tujuan / Keperluan',
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Tujuan wajib diisi'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesCtrl,
                decoration: const InputDecoration(
                  labelText: 'Catatan Tambahan',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: RukuninColors.brandGreen,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                ),
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Kirim Permohonan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
