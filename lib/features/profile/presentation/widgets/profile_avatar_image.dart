import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../data/profile_avatar.dart';

class ProfileAvatarImage extends StatelessWidget {
  const ProfileAvatarImage({
    super.key,
    required this.selection,
    required this.suggestedAssetPath,
    required this.size,
    this.semanticLabel = 'User avatar',
  });

  final ProfileAvatarSelection selection;
  final String suggestedAssetPath;
  final double size;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final entry = selection.kind == ProfileAvatarKind.bundled
        ? ProfileAvatarCatalog.findById(selection.avatarId)
        : null;
    final backgroundColor =
        entry?.frameColor ??
        (selection.kind == ProfileAvatarKind.custom
            ? Theme.of(context).colorScheme.surfaceContainerHighest
            : Colors.white.withValues(alpha: 0.18));

    Widget image;
    if (selection.kind == ProfileAvatarKind.custom &&
        selection.customBytes != null) {
      image = Image.memory(
        selection.customBytes!,
        fit: BoxFit.cover,
        width: size,
        height: size,
        gaplessPlayback: true,
        errorBuilder: (_, _, _) => _fallbackIcon(context),
      );
    } else if (entry != null) {
      image = Padding(
        padding: EdgeInsets.all(size * 0.035),
        child: entry.assetPath.toLowerCase().endsWith('.svg')
            ? SvgPicture.asset(
                entry.assetPath,
                fit: BoxFit.contain,
                width: size,
                height: size,
                placeholderBuilder: (_) => _fallbackIcon(context),
                errorBuilder: (_, _, _) => _fallbackIcon(context),
              )
            : Image.asset(
                entry.assetPath,
                fit: BoxFit.contain,
                width: size,
                height: size,
                errorBuilder: (_, _, _) => _fallbackIcon(context),
              ),
      );
    } else {
      image = Padding(
        padding: EdgeInsets.all(size * 0.1),
        child: Image.asset(
          suggestedAssetPath,
          fit: BoxFit.contain,
          width: size,
          height: size,
          errorBuilder: (_, _, _) => _fallbackIcon(context),
        ),
      );
    }

    return Semantics(
      image: true,
      label: semanticLabel,
      child: SizedBox.square(
        dimension: size,
        child: ClipOval(
          child: ColoredBox(color: backgroundColor, child: image),
        ),
      ),
    );
  }

  Widget _fallbackIcon(BuildContext context) {
    return Center(
      child: Icon(
        Icons.person_rounded,
        size: size * 0.54,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}

class CurrentUserAvatar extends StatefulWidget {
  const CurrentUserAvatar({
    super.key,
    required this.userId,
    required this.gender,
    required this.userType,
    required this.size,
    this.semanticLabel = 'User avatar',
    this.controller,
  });

  final int? userId;
  final String? gender;
  final String? userType;
  final double size;
  final String semanticLabel;
  final ProfileAvatarController? controller;

  @override
  State<CurrentUserAvatar> createState() => _CurrentUserAvatarState();
}

class _CurrentUserAvatarState extends State<CurrentUserAvatar> {
  ProfileAvatarController get _controller =>
      widget.controller ?? ProfileAvatarController.instance;

  @override
  void initState() {
    super.initState();
    _loadAvatar();
  }

  @override
  void didUpdateWidget(CurrentUserAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId ||
        oldWidget.controller != widget.controller) {
      _loadAvatar();
    }
  }

  void _loadAvatar() {
    final userId = widget.userId;
    if (userId != null && userId > 0) {
      unawaited(_controller.loadForUser(userId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final fallback = suggestedProfileAvatarAsset(
      widget.gender,
      widget.userType,
    );

    return ValueListenableBuilder<ProfileAvatarState>(
      valueListenable: _controller.notifier,
      builder: (context, state, _) {
        final selection = state.userId == widget.userId && state.isLoaded
            ? state.selection
            : const ProfileAvatarSelection.suggested();
        return ProfileAvatarImage(
          selection: selection,
          suggestedAssetPath: fallback,
          size: widget.size,
          semanticLabel: widget.semanticLabel,
        );
      },
    );
  }
}
