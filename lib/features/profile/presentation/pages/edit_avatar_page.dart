import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../shared/theme/app_page_style.dart';
import '../../data/profile_avatar.dart';
import '../widgets/profile_avatar_image.dart';
import 'avatar_crop_page.dart';

typedef ProfileAvatarImagePicker = Future<XFile?> Function();
typedef ProfileAvatarCropper =
    Future<Uint8List?> Function(BuildContext context, Uint8List sourceBytes);

class EditAvatarPage extends StatefulWidget {
  const EditAvatarPage({
    super.key,
    required this.userId,
    required this.gender,
    required this.userType,
    this.controller,
    this.pickImage,
    this.cropImage,
  });

  final int userId;
  final String? gender;
  final String? userType;
  final ProfileAvatarController? controller;
  final ProfileAvatarImagePicker? pickImage;
  final ProfileAvatarCropper? cropImage;

  @override
  State<EditAvatarPage> createState() => _EditAvatarPageState();
}

class _EditAvatarPageState extends State<EditAvatarPage> {
  ProfileAvatarController get _controller =>
      widget.controller ?? ProfileAvatarController.instance;

  ProfileAvatarSelection _draft = const ProfileAvatarSelection.suggested();
  bool _isLoading = true;
  bool _isPicking = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSelection();
  }

  Future<void> _loadSelection() async {
    final selection = await _controller.loadForUser(widget.userId);
    if (!mounted) return;
    setState(() {
      _draft = selection;
      _isLoading = false;
    });
  }

  Future<XFile?> _defaultPickImage() {
    return ImagePicker().pickImage(source: ImageSource.gallery);
  }

  Future<Uint8List?> _defaultCropImage(
    BuildContext context,
    Uint8List sourceBytes,
  ) {
    return Navigator.of(context).push<Uint8List>(
      MaterialPageRoute(
        builder: (_) => AvatarCropPage(imageBytes: sourceBytes),
      ),
    );
  }

  Future<void> _uploadPhoto() async {
    if (_isPicking || _isSaving) return;
    setState(() => _isPicking = true);

    try {
      final picked = await (widget.pickImage ?? _defaultPickImage)();
      if (picked == null) return;

      final sourceBytes = await picked.readAsBytes();
      ProfileAvatarImageProcessor.validateInput(sourceBytes);
      if (!mounted) return;

      final cropped = await (widget.cropImage ?? _defaultCropImage)(
        context,
        sourceBytes,
      );
      if (cropped == null || !mounted) return;

      if (cropped.length > ProfileAvatarImageProcessor.maxOutputBytes ||
          !ProfileAvatarImageProcessor.isJpeg(cropped)) {
        throw const ProfileAvatarException(
          'The cropped photo could not be prepared.',
        );
      }

      setState(() => _draft = ProfileAvatarSelection.custom(cropped));
    } catch (error) {
      if (!mounted) return;
      final message = error is ProfileAvatarException
          ? error.message
          : 'Unable to open that photo. Please try another image.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  Future<void> _saveAvatar() async {
    if (_isSaving || _isPicking) return;
    setState(() => _isSaving = true);

    try {
      switch (_draft.kind) {
        case ProfileAvatarKind.suggested:
          await _controller.resetToSuggested(widget.userId);
        case ProfileAvatarKind.bundled:
          await _controller.saveBundled(widget.userId, _draft.avatarId!);
        case ProfileAvatarKind.custom:
          await _controller.saveCustom(widget.userId, _draft.customBytes!);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile avatar updated.')));
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      final message = error is ProfileAvatarException
          ? error.message
          : 'Unable to save the profile avatar.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final suggestedAsset = suggestedProfileAvatarAsset(
      widget.gender,
      widget.userType,
    );

    return PopScope(
      canPop: !_isSaving,
      child: Container(
        decoration: buildPageDecoration(context),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.transparent,
            foregroundColor: pagePrimaryTextColor(context),
            leading: IconButton(
              onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
            ),
            title: Text(
              'Edit avatar',
              style: TextStyle(
                color: pagePrimaryTextColor(context),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SafeArea(
                  top: false,
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      10,
                      16,
                      pageBottomContentPadding(context),
                    ),
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 720),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _AvatarPreviewCard(
                              selection: _draft,
                              suggestedAsset: suggestedAsset,
                            ),
                            const SizedBox(height: 18),
                            _AvatarSectionCard(
                              title: 'Upload your photo',
                              subtitle:
                                  'Choose a JPEG, PNG, or WebP image up to 10 MB.',
                              child: SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  key: const ValueKey(
                                    'avatar-upload-photo-button',
                                  ),
                                  onPressed: _isPicking || _isSaving
                                      ? null
                                      : _uploadPhoto,
                                  icon: _isPicking
                                      ? const SizedBox.square(
                                          dimension: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.2,
                                          ),
                                        )
                                      : const Icon(
                                          Icons.add_photo_alternate_outlined,
                                        ),
                                  label: Text(
                                    _isPicking
                                        ? 'Opening gallery...'
                                        : 'Choose and crop photo',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 15,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            _AvatarSectionCard(
                              title: 'Choose an avatar',
                              subtitle:
                                  'Browse professional roles or the original Personas collection.',
                              child: _AvatarCatalog(
                                key: const ValueKey('avatar-catalog-grid'),
                                selectedAvatarId:
                                    _draft.kind == ProfileAvatarKind.bundled
                                    ? _draft.avatarId
                                    : null,
                                onSelected: (entry) {
                                  setState(() {
                                    _draft = ProfileAvatarSelection.bundled(
                                      entry.id,
                                    );
                                  });
                                },
                              ),
                            ),
                            const SizedBox(height: 14),
                            TextButton.icon(
                              key: const ValueKey('avatar-use-suggested'),
                              onPressed: _isSaving
                                  ? null
                                  : () {
                                      setState(() {
                                        _draft =
                                            const ProfileAvatarSelection.suggested();
                                      });
                                    },
                              icon: const Icon(Icons.person_outline_rounded),
                              label: const Text(
                                'Use suggested avatar',
                                style: TextStyle(fontWeight: FontWeight.w800),
                              ),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              key: const ValueKey('avatar-save-button'),
                              onPressed: _isSaving || _isPicking
                                  ? null
                                  : _saveAvatar,
                              icon: _isSaving
                                  ? const SizedBox.square(
                                      dimension: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.save_outlined),
                              label: Text(
                                _isSaving ? 'Saving...' : 'Save avatar',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1D8CA8),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

class _AvatarPreviewCard extends StatelessWidget {
  const _AvatarPreviewCard({
    required this.selection,
    required this.suggestedAsset,
  });

  final ProfileAvatarSelection selection;
  final String suggestedAsset;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('avatar-preview-card'),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1D8CA8), Color(0xFF5DB8F0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.22),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.55),
                width: 2,
              ),
            ),
            child: ProfileAvatarImage(
              selection: selection,
              suggestedAssetPath: suggestedAsset,
              size: 142,
              semanticLabel: 'Avatar preview',
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Your profile avatar',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Preview changes before saving',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.86),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarSectionCard extends StatelessWidget {
  const _AvatarSectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: pageSurfaceColor(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: pageBorderColor(context)),
        boxShadow: pageCardShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: pagePrimaryTextColor(context),
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: pageSecondaryTextColor(context),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _AvatarCatalog extends StatelessWidget {
  const _AvatarCatalog({
    super.key,
    required this.selectedAvatarId,
    required this.onSelected,
  });

  final String? selectedAvatarId;
  final ValueChanged<AvatarCatalogEntry> onSelected;

  @override
  Widget build(BuildContext context) {
    final entries = [
      for (final category in ProfileAvatarCategory.values)
        ...ProfileAvatarCatalog.entriesFor(category),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: entries.length,
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 104,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
      ),
      itemBuilder: (context, index) {
        final entry = entries[index];
        return _AvatarOption(
          entry: entry,
          selected: selectedAvatarId == entry.id,
          onTap: () => onSelected(entry),
        );
      },
    );
  }
}

class _AvatarOption extends StatelessWidget {
  const _AvatarOption({
    required this.entry,
    required this.selected,
    required this.onTap,
  });

  final AvatarCatalogEntry entry;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Semantics(
      selected: selected,
      button: true,
      label: entry.semanticLabel,
      child: InkWell(
        key: ValueKey('avatar-option-${entry.id}'),
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Stack(
          fit: StackFit.expand,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? primary : Colors.transparent,
                  width: 3,
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: primary.withValues(alpha: 0.24),
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
              child: ProfileAvatarImage(
                selection: ProfileAvatarSelection.bundled(entry.id),
                suggestedAssetPath: 'assets/images/user.png',
                size: 84,
                semanticLabel: entry.semanticLabel,
              ),
            ),
            if (selected)
              Align(
                alignment: Alignment.bottomRight,
                child: Container(
                  width: 25,
                  height: 25,
                  decoration: BoxDecoration(
                    color: primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
