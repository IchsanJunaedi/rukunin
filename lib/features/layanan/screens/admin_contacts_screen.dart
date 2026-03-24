// lib/features/layanan/screens/admin_contacts_screen.dart

import 'dart:typed_data';

import 'package:flutter/services.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app/theme.dart';
import '../../../app/tokens.dart';
import '../../../core/supabase/supabase_client.dart';
import '../models/community_contact_model.dart';
import '../providers/layanan_provider.dart';

class AdminContactsScreen extends ConsumerWidget {
  const AdminContactsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final contactsAsync = ref.watch(adminContactsProvider);

    return Scaffold(
      backgroundColor: isDark ? RukuninColors.darkBg : RukuninColors.lightBg,
      appBar: AppBar(
        title: const Text('Kelola Kontak'),
      ),
      body: contactsAsync.when(
        data: (contacts) => contacts.isEmpty
            ? _buildEmpty(context, ref)
            : _buildList(context, ref, contacts),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('Error: $e',
              style: GoogleFonts.plusJakartaSans(color: RukuninColors.error)),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: RukuninColors.brandGreen,
        foregroundColor: Colors.white,
        onPressed: () => _showForm(context, ref, null, []),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.people_outline, size: 56, color: isDark ? RukuninColors.darkBorder : RukuninColors.lightBorder),
          const SizedBox(height: 12),
          Text(
            'Belum ada kontak',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isDark ? RukuninColors.darkTextTertiary : RukuninColors.lightTextTertiary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tap + untuk tambah kontak pengurus',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: isDark ? RukuninColors.darkTextTertiary : RukuninColors.lightTextTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(
      BuildContext context, WidgetRef ref, List<CommunityContactModel> contacts) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: contacts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final contact = contacts[index];
        return _ContactAdminCard(
          contact: contact,
          canMoveUp: index > 0,
          canMoveDown: index < contacts.length - 1,
          onMoveUp: () {
            final above = contacts[index - 1];
            ref.read(layananServiceProvider).swapUrutan(
                  contact.id, contact.urutan,
                  above.id, above.urutan,
                );
          },
          onMoveDown: () {
            final below = contacts[index + 1];
            ref.read(layananServiceProvider).swapUrutan(
                  contact.id, contact.urutan,
                  below.id, below.urutan,
                );
          },
          onEdit: () => _showForm(context, ref, contact, contacts),
        );
      },
    );
  }

  Future<void> _showForm(
    BuildContext context,
    WidgetRef ref,
    CommunityContactModel? existing,
    List<CommunityContactModel> allContacts,
  ) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? RukuninColors.darkSurface : RukuninColors.lightSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _ContactFormSheet(
        existing: existing,
        onSave: (nama, jabatan, phone, photoBytes, photoExt) async {
          final client = ref.read(supabaseClientProvider);
          final userId = client.auth.currentUser?.id;
          if (userId == null) return;

          final profile = await client
              .from('profiles')
              .select('community_id')
              .eq('id', userId)
              .maybeSingle();
          final communityId = profile?['community_id'] as String?;
          if (communityId == null) return;

          final service = ref.read(layananServiceProvider);

          if (existing == null) {
            // Tambah baru — upload foto dulu jika ada
            String? photoUrl;
            if (photoBytes != null && photoExt != null) {
              final tempId = DateTime.now().millisecondsSinceEpoch.toString();
              photoUrl = await service.uploadContactPhoto(
                communityId: communityId,
                contactId: tempId,
                fileBytes: photoBytes,
                fileExt: photoExt,
              );
            }
            await service.addContact(
              communityId: communityId,
              nama: nama,
              jabatan: jabatan,
              phone: phone,
              photoUrl: photoUrl,
            );
          } else {
            // Edit — upload foto baru jika diganti
            String? photoUrl = existing.photoUrl;
            if (photoBytes != null && photoExt != null) {
              photoUrl = await service.uploadContactPhoto(
                communityId: communityId,
                contactId: existing.id,
                fileBytes: photoBytes,
                fileExt: photoExt,
              );
            }
            await service.updateContact(
              id: existing.id,
              nama: nama,
              jabatan: jabatan,
              phone: phone,
              photoUrl: photoUrl,
            );
          }
        },
        onDelete: existing == null
            ? null
            : () async {
                final confirm = await showDialog<bool>(
                  context: ctx,
                  builder: (d) => AlertDialog(
                    title: const Text('Hapus Kontak'),
                    content: Text('Hapus kontak "${existing.nama}"?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(d, false),
                        child: const Text('Batal'),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: RukuninColors.error),
                        onPressed: () => Navigator.pop(d, true),
                        child: const Text('Hapus',
                            style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await ref
                      .read(layananServiceProvider)
                      .deleteContact(existing.id);
                  if (ctx.mounted) Navigator.pop(ctx);
                }
              },
      ),
    );
  }
}

// ── Card admin ────────────────────────────────────────────────
class _ContactAdminCard extends StatelessWidget {
  final CommunityContactModel contact;
  final bool canMoveUp;
  final bool canMoveDown;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;
  final VoidCallback onEdit;

  const _ContactAdminCard({
    required this.contact,
    required this.canMoveUp,
    required this.canMoveDown,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? RukuninColors.darkSurface : RukuninColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _Avatar(contact: contact, radius: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contact.nama,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark ? RukuninColors.darkTextPrimary : RukuninColors.lightTextPrimary,
                  ),
                ),
                Text(
                  contact.jabatan,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: isDark ? RukuninColors.darkTextTertiary : RukuninColors.lightTextTertiary,
                  ),
                ),
                Text(
                  contact.phone,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: isDark ? RukuninColors.darkTextTertiary : RukuninColors.lightTextTertiary,
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_upward, size: 18),
                onPressed: canMoveUp ? onMoveUp : null,
                color: canMoveUp
                    ? (isDark ? RukuninColors.darkTextSecondary : RukuninColors.lightTextSecondary)
                    : (isDark ? RukuninColors.darkBorder : RukuninColors.lightBorder),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(height: 4),
              IconButton(
                icon: const Icon(Icons.arrow_downward, size: 18),
                onPressed: canMoveDown ? onMoveDown : null,
                color: canMoveDown
                    ? (isDark ? RukuninColors.darkTextSecondary : RukuninColors.lightTextSecondary)
                    : (isDark ? RukuninColors.darkBorder : RukuninColors.lightBorder),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20),
            onPressed: onEdit,
            color: isDark ? RukuninColors.darkTextSecondary : RukuninColors.lightTextSecondary,
          ),
        ],
      ),
    );
  }
}

// ── Avatar helper ─────────────────────────────────────────────
class _Avatar extends StatelessWidget {
  final CommunityContactModel contact;
  final double radius;

  const _Avatar({required this.contact, required this.radius});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (contact.photoUrl != null) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: isDark ? RukuninColors.darkSurface2 : RukuninColors.lightSurface2,
        backgroundImage: CachedNetworkImageProvider(contact.photoUrl!),
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: RukuninColors.brandGreen.withValues(alpha: 0.15),
      child: Text(
        contact.initials,
        style: GoogleFonts.plusJakartaSans(
          fontSize: radius * 0.6,
          fontWeight: FontWeight.w700,
          color: RukuninColors.brandGreen,
        ),
      ),
    );
  }
}

// ── Form bottom sheet ─────────────────────────────────────────
class _ContactFormSheet extends ConsumerStatefulWidget {
  final CommunityContactModel? existing;
  final Future<void> Function(
    String nama,
    String jabatan,
    String phone,
    List<int>? photoBytes,
    String? photoExt,
  ) onSave;
  final Future<void> Function()? onDelete;

  const _ContactFormSheet({
    required this.existing,
    required this.onSave,
    this.onDelete,
  });

  @override
  ConsumerState<_ContactFormSheet> createState() => _ContactFormSheetState();
}

class _ContactFormSheetState extends ConsumerState<_ContactFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _namaCtrl;
  late final TextEditingController _jabatanCtrl;
  late final TextEditingController _phoneCtrl;
  List<int>? _photoBytes;
  String? _photoExt;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _namaCtrl = TextEditingController(text: widget.existing?.nama ?? '');
    _jabatanCtrl = TextEditingController(text: widget.existing?.jabatan ?? '');
    _phoneCtrl = TextEditingController(text: widget.existing?.phone ?? '');
  }

  @override
  void dispose() {
    _namaCtrl.dispose();
    _jabatanCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image == null) return;
    final bytes = await image.readAsBytes();
    final ext = image.name.split('.').last.toLowerCase();
    setState(() {
      _photoBytes = bytes;
      _photoExt = ext;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      await widget.onSave(
        _namaCtrl.text.trim(),
        _jabatanCtrl.text.trim(),
        _phoneCtrl.text.trim(),
        _photoBytes,
        _photoExt,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEdit = widget.existing != null;
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isEdit ? 'Edit Kontak' : 'Tambah Kontak',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: isDark ? RukuninColors.darkTextPrimary : RukuninColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 20),

            // Foto
            Center(
              child: GestureDetector(
                onTap: _pickPhoto,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: isDark ? RukuninColors.darkSurface2 : RukuninColors.lightSurface2,
                      backgroundImage: _photoBytes != null
                          ? MemoryImage(Uint8List.fromList(_photoBytes!))
                          : (widget.existing?.photoUrl != null
                              ? CachedNetworkImageProvider(
                                  widget.existing!.photoUrl!) as ImageProvider
                              : null),
                      child: (_photoBytes == null &&
                              widget.existing?.photoUrl == null)
                          ? Icon(Icons.camera_alt_outlined,
                              color: isDark ? RukuninColors.darkTextTertiary : RukuninColors.lightTextTertiary, size: 28)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: RukuninColors.brandGreen,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.edit, size: 12, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Nama
            TextFormField(
              controller: _namaCtrl,
              decoration: InputDecoration(
                labelText: 'Nama',
                hintText: 'Contoh: Pak Budi Santoso',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama wajib diisi' : null,
            ),
            const SizedBox(height: 12),

            // Jabatan
            TextFormField(
              controller: _jabatanCtrl,
              decoration: InputDecoration(
                labelText: 'Jabatan',
                hintText: 'Contoh: Ketua RW, Sekretaris, Bendahara',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Jabatan wajib diisi' : null,
            ),
            const SizedBox(height: 12),

            // Nomor WA
            TextFormField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.number,
              maxLength: 15,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: 'Nomor WhatsApp',
                hintText: '628123456789 (format internasional tanpa +)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Nomor WA wajib diisi';
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Tombol simpan
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: RukuninColors.brandGreen,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100)),
                  elevation: 0,
                  textStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Simpan'),
              ),
            ),

            // Tombol hapus (hanya saat edit)
            if (isEdit && widget.onDelete != null) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: RukuninColors.error,
                    textStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onPressed: widget.onDelete,
                  child: const Text('Hapus Kontak'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
