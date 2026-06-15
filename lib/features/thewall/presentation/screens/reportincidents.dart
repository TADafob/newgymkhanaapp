import 'dart:convert';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:nrbgymkhana/core/utils/appcolors.dart';

// Cloudinary config
const cloudName = 'dbeofdu5x';
const uploadPreset = 'NbiGymkhana_reports';
final _uploadUrl =
    Uri.parse('https://api.cloudinary.com/v1_1/ $cloudName/upload');

// Providers
final statusProvider = StateProvider<String?>((ref) => null);
final entityInputProvider = StateProvider<String>((ref) => '');
final entityListProvider = StateProvider<List<String>>((ref) => []);
final descriptionProvider = StateProvider<String>((ref) => '');
final attachmentsProvider = StateProvider<List<String>>((ref) => []);
final currentUser = FirebaseAuth.instance.currentUser!.uid;

void showIssueReportSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.6),
    elevation: 4,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
    ),
    builder: (ctx) => const IssueReportSheet(),
  );
}

class IssueReportSheet extends ConsumerStatefulWidget {
  const IssueReportSheet({super.key});

  @override
  ConsumerState<IssueReportSheet> createState() => _IssueReportSheetState();
}

class _IssueReportSheetState extends ConsumerState<IssueReportSheet> {
  final _formKey = GlobalKey<FormState>();
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUpload(String type) async {
    final picker = ImagePicker();
    XFile? picked;

    try {
      switch (type) {
        case 'photo':
          picked = await picker.pickImage(source: ImageSource.camera);
        case 'gallery':
          picked = await picker.pickImage(source: ImageSource.gallery);
        case 'video':
          picked = await picker.pickVideo(source: ImageSource.camera);
        case 'audio':
          final result =
              await FilePicker.platform.pickFiles(type: FileType.audio);
          if (result != null && result.files.single.path != null) {
            picked = XFile(result.files.single.path!);
          }
        default:
          return;
      }

      if (picked == null) return;

      final request = http.MultipartRequest('POST', _uploadUrl)
        ..fields['upload_preset'] = uploadPreset
        ..files.add(await http.MultipartFile.fromPath('file', picked.path));

      final resp = await request.send();

      if (resp.statusCode == 200) {
        final data = jsonDecode(await resp.stream.bytesToString());
        ref
            .read(attachmentsProvider.notifier)
            .update((list) => [...list, data['secure_url']]);
        Fluttertoast.showToast(
            msg: "File uploaded successfully",
            backgroundColor: AppKolors.accent2);
      } else {
        Fluttertoast.showToast(
            msg: "Upload failed", backgroundColor: AppKolors.accent3);
      }
    } catch (e) {
      Fluttertoast.showToast(
          msg: "Error: $e", backgroundColor: AppKolors.accent3);
    }
  }

  Widget _buildSectionHeader(String title, {Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                  fontSize: 16,
                ),
          ),
          if (trailing != null) ...[
            const Spacer(),
            trailing,
          ]
        ],
      ),
    );
  }

  Widget _buildStatusSelector() {
    final status = ref.watch(statusProvider);
    return SegmentedButton<String>(
      segments: const [
        ButtonSegment(
          value: 'Staff',
          label: Text('Staff'),
          icon: Icon(Icons.person_outline),
        ),
        ButtonSegment(
          value: 'Member',
          label: Text('Member'),
          icon: Icon(Icons.group_outlined),
        ),
        ButtonSegment(
          value: 'Facility',
          label: Text('Facility'),
          icon: Icon(Icons.location_city_outlined),
        ),
      ],
      selected: status != null ? {status} : const {},
      onSelectionChanged: (newSelection) {
        ref.read(statusProvider.notifier).state = newSelection.firstOrNull;
      },
      emptySelectionAllowed: true,
      multiSelectionEnabled: false,
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.selected)) {
            return Theme.of(context).primaryColor.withValues(alpha: 0.15);
          }
          return Colors.grey[200];
        }),
      ),
    );
  }

  Widget _buildEntityInput() {
    final input = ref.watch(entityInputProvider);
    final list = ref.watch(entityListProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                initialValue: input,
                onChanged: (value) =>
                    ref.read(entityInputProvider.notifier).state = value,
                decoration: InputDecoration(
                  hintText: 'Enter ${ref.read(statusProvider)} involved',
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  prefixIcon: const Icon(Icons.search, size: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
            const SizedBox(width: 8),
            FloatingActionButton.small(
              backgroundColor: Theme.of(context).primaryColor,
              onPressed: () {
                final text = input.trim();
                if (text.isNotEmpty) {
                  ref
                      .read(entityListProvider.notifier)
                      .update((s) => [...s, text]);
                  ref.read(entityInputProvider.notifier).state = '';
                }
              },
              child: const Icon(Icons.add),
            ),
          ],
        ),
        if (list.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: list
                  .map((e) => InputChip(
                        label: Text(e),
                        onDeleted: () => ref
                            .read(entityListProvider.notifier)
                            .update((s) => s.where((x) => x != e).toList()),
                        backgroundColor: Theme.of(context)
                            .primaryColor
                            .withValues(alpha: 0.1),
                        deleteIconColor: Theme.of(context).primaryColor,
                      ))
                  .toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildDescriptionInput() {
    final description = ref.watch(descriptionProvider);

    return TextFormField(
      initialValue: description,
      onChanged: (value) =>
          ref.read(descriptionProvider.notifier).state = value,
      maxLines: 5,
      minLines: 3,
      decoration: InputDecoration(
        hintText: 'Describe the issue in detail...',
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.all(16),
        counterText: '${description.length}/500',
      ),
      maxLength: 500,
    );
  }

  Widget _buildMediaSection() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _MediaOption(
              icon: Icons.camera_alt,
              label: 'Photo',
              color: Colors.blue.shade100,
              onTap: () => _pickAndUpload('photo'),
            ),
            _MediaOption(
              icon: Icons.photo_library,
              label: 'Gallery',
              color: Colors.green.shade100,
              onTap: () => _pickAndUpload('gallery'),
            ),
            _MediaOption(
              icon: Icons.videocam,
              label: 'Video',
              color: Colors.purple.shade100,
              onTap: () => _pickAndUpload('video'),
            ),
            _MediaOption(
              icon: Icons.mic,
              label: 'Audio',
              color: Colors.orange.shade100,
              onTap: () => _pickAndUpload('audio'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildAttachmentsPreview(),
      ],
    );
  }

  Widget _buildAttachmentsPreview() {
    final atts = ref.watch(attachmentsProvider);

    if (atts.isEmpty) {
      return const Center(
        child: Text(
          'No attachments added yet',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: atts.length,
        itemBuilder: (context, index) {
          final url = atts[index];
          return Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: Stack(
              alignment: Alignment.topRight,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey[300],
                    image: DecorationImage(
                      image: NetworkImage(url),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => ref
                      .read(attachmentsProvider.notifier)
                      .update((s) => s.where((x) => x != url).toList()),
                  icon: const Icon(Icons.close, size: 18, color: Colors.white),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            top: 24,
            left: 20,
            right: 20,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.92),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, -5),
              )
            ],
          ),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 50,
                      height: 6,
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),

                  // Title
                  Text(
                    'Report an Issue',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                  ),
                  const SizedBox(height: 32),

                  // Type of Issue
                  _buildSectionHeader('Type of Issue'),
                  _buildStatusSelector(),
                  const SizedBox(height: 24),

                  // Entities
                  if (ref.watch(statusProvider) != null) ...[
                    _buildSectionHeader('Add ${ref.watch(statusProvider)}(s)'),
                    _buildEntityInput(),
                    const SizedBox(height: 24),
                  ],

                  // Description
                  _buildSectionHeader('Issue Description *'),
                  _buildDescriptionInput(),
                  const SizedBox(height: 24),

                  // Attachments
                  _buildSectionHeader('Attachments'),
                  _buildMediaSection(),
                  const SizedBox(height: 32),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (_formKey.currentState?.validate() ?? false) {
                          try {
                            final doc = {
                              'report_Id': 'report$currentUser',
                              'reported_By': currentUser,
                              'type': ref.watch(statusProvider),
                              'reported_List': ref.watch(entityListProvider),
                              'description': ref.watch(descriptionProvider),
                              'attachments': ref.watch(attachmentsProvider),
                              'date_Reported': FieldValue.serverTimestamp(),
                              'isResolved': false,
                            };

                            await FirebaseFirestore.instance
                                .collection('reports_Collection')
                                .add(doc);

                            Navigator.pop(context);
                            Fluttertoast.showToast(
                              msg: 'Report successfully sent!',
                              backgroundColor: AppKolors.accent2,
                              toastLength: Toast.LENGTH_SHORT,
                            );
                          } catch (e) {
                            Fluttertoast.showToast(
                              msg: 'Failed to submit report: $e',
                              backgroundColor: AppKolors.accent3,
                              toastLength: Toast.LENGTH_LONG,
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 4,
                        shadowColor: Theme.of(context)
                            .primaryColor
                            .withValues(alpha: 0.3),
                        animationDuration: const Duration(milliseconds: 200),
                        foregroundColor: AppKolors.background,
                        textStyle: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.send, size: 20),
                          SizedBox(width: 10),
                          Text('Submit Report'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MediaOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _MediaOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Icon(icon, color: AppKolors.background, size: 28),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
