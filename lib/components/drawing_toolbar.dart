import 'package:flutter/material.dart';
import 'drawing_models.dart';

class DrawingToolbar extends StatelessWidget {
  final DrawingTool currentTool;
  final Color currentColor;
  final bool canUndo;
  final bool canRedo;
  final bool isSyncing;
  final bool hasUnsavedChanges;
  final Function(DrawingTool) onToolSelected;
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final VoidCallback onColorPicker;
  final VoidCallback onShapesPressed;
  final VoidCallback onImagePressed;
  final VoidCallback onMoreOptions;
  final GlobalKey? cameraIconKey;

  const DrawingToolbar({
    Key? key,
    required this.currentTool,
    required this.currentColor,
    required this.canUndo,
    required this.canRedo,
    required this.isSyncing,
    required this.hasUnsavedChanges,
    required this.onToolSelected,
    required this.onUndo,
    required this.onRedo,
    required this.onColorPicker,
    required this.onShapesPressed,
    required this.onImagePressed,
    required this.onMoreOptions,
    this.cameraIconKey,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Main toolbar
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              border: Border(
                bottom: BorderSide(
                  color: const Color(0xFFE5E7EB),
                  width: 1,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Row(
                  children: [
                    const SizedBox(width: 100),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildToolButton(
                            context: context,
                            iconPath: ToolbarIcons.selector,
                            icon: Icons.touch_app,
                            isSelected: currentTool == DrawingTool.selector,
                            onTap: () => onToolSelected(DrawingTool.selector),
                            tooltip: 'Selector',
                          ),
                          const SizedBox(width: 8),
                          _buildToolButton(
                            context: context,
                            iconPath: ToolbarIcons.ballpen,
                            icon: Icons.edit,
                            isSelected: currentTool == DrawingTool.ballpen,
                            onTap: () => onToolSelected(DrawingTool.ballpen),
                            tooltip: 'Ball Pen',
                          ),
                          const SizedBox(width: 8),
                          _buildToolButton(
                            context: context,
                            iconPath: ToolbarIcons.pencil,
                            icon: Icons.create,
                            isSelected: currentTool == DrawingTool.pencil,
                            onTap: () => onToolSelected(DrawingTool.pencil),
                            tooltip: 'Pencil',
                          ),
                          const SizedBox(width: 8),
                          _buildToolButton(
                            context: context,
                            iconPath: ToolbarIcons.marker,
                            icon: Icons.brush,
                            isSelected: currentTool == DrawingTool.marker,
                            onTap: () => onToolSelected(DrawingTool.marker),
                            tooltip: 'Marker',
                          ),
                          const SizedBox(width: 8),
                          _buildToolButton(
                            context: context,
                            iconPath: ToolbarIcons.eraser,
                            icon: Icons.clear,
                            isSelected: currentTool == DrawingTool.eraser,
                            onTap: () => onToolSelected(DrawingTool.eraser),
                            tooltip: 'Eraser',
                          ),
                          const SizedBox(width: 8),
                          _buildToolButton(
                            context: context,
                            iconPath: ToolbarIcons.text,
                            icon: Icons.text_fields,
                            isSelected: currentTool == DrawingTool.text,
                            onTap: () => onToolSelected(DrawingTool.text),
                            tooltip: 'Text',
                          ),
                          const SizedBox(width: 8),
                          _buildToolButton(
                            context: context,
                            key: cameraIconKey,
                            iconPath: ToolbarIcons.camera,
                            icon: Icons.camera_alt,
                            onTap: onShapesPressed,
                            tooltip: 'Shapes',
                          ),
                          const SizedBox(width: 8),
                          _buildToolButton(
                            context: context,
                            iconPath: ToolbarIcons.imageUploader,
                            icon: Icons.image,
                            onTap: onImagePressed,
                            tooltip: 'Upload Image',
                          ),
                          const SizedBox(width: 8),
                          _buildToolButton(
                            context: context,
                            iconPath: ToolbarIcons.zoom,
                            icon: Icons.zoom_in,
                            isSelected: currentTool == DrawingTool.zoom,
                            onTap: () => onToolSelected(DrawingTool.zoom),
                            tooltip: 'Zoom',
                          ),
                          const SizedBox(width: 8),
                          _buildToolButton(
                            context: context,
                            iconPath: ToolbarIcons.future,
                            icon: Icons.more_vert,
                            onTap: onMoreOptions,
                            tooltip: 'More Options',
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        const SizedBox(width: 16),
                        _buildColorIndicator(),
                        const SizedBox(width: 8),
                        _buildSyncStatus(),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Undo/Redo buttons
        Positioned(
          top: 12,
          left: 12,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
              border: Border.all(
                color: const Color(0xFFE5E7EB),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildCompactToolButton(
                  context: context,
                  iconPath: ToolbarIcons.undo,
                  icon: Icons.undo,
                  onTap: canUndo ? onUndo : null,
                  tooltip: 'Undo',
                  isEnabled: canUndo,
                ),
                Container(
                  width: 1,
                  height: 24,
                  color: const Color(0xFFE5E7EB),
                ),
                _buildCompactToolButton(
                  context: context,
                  iconPath: ToolbarIcons.redo,
                  icon: Icons.redo,
                  onTap: canRedo ? onRedo : null,
                  tooltip: 'Redo',
                  isEnabled: canRedo,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildToolButton({
    required BuildContext context,
    Key? key,
    required String iconPath,
    IconData? icon,
    bool isSelected = false,
    required VoidCallback? onTap,
    required String tooltip,
    bool isEnabled = true,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        key: key,
        color: Colors.transparent,
        child: InkWell(
          onTap: isEnabled ? onTap : null,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            width: 36,
            height: 36,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF3B82F6) : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: isSelected ? null : Border.all(
                color: Colors.transparent,
                width: 1,
              ),
            ),
            child: _buildIcon(context, iconPath, icon, isSelected, isEnabled),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactToolButton({
    required BuildContext context,
    required String iconPath,
    IconData? icon,
    required VoidCallback? onTap,
    required String tooltip,
    bool isEnabled = true,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isEnabled ? onTap : null,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            width: 32,
            height: 32,
            padding: const EdgeInsets.all(6),
            child: _buildIcon(context, iconPath, icon, false, isEnabled),
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(BuildContext context, String iconPath, IconData? fallbackIcon, bool isSelected, bool isEnabled) {
    return FutureBuilder<bool>(
      future: _checkAssetExists(context, iconPath),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data == true) {
          return Image.asset(
            iconPath,
            width: 24,
            height: 24,
            color: !isEnabled
                ? const Color(0xFF9CA3AF)
                : isSelected
                ? Colors.white
                : const Color(0xFF374151),
            errorBuilder: (context, error, stackTrace) {
              return Icon(
                fallbackIcon ?? Icons.help_outline,
                size: 24,
                color: !isEnabled
                    ? const Color(0xFF9CA3AF)
                    : isSelected
                    ? Colors.white
                    : const Color(0xFF374151),
              );
            },
          );
        } else {
          return Icon(
            fallbackIcon ?? Icons.help_outline,
            size: 24,
            color: !isEnabled
                ? const Color(0xFF9CA3AF)
                : isSelected
                ? Colors.white
                : const Color(0xFF374151),
          );
        }
      },
    );
  }

  Future<bool> _checkAssetExists(BuildContext context, String assetPath) async {
    try {
      await DefaultAssetBundle.of(context).load(assetPath);
      return true;
    } catch (e) {
      return false;
    }
  }

  Widget _buildColorIndicator() {
    return GestureDetector(
      onTap: onColorPicker,
      child: Container(
        width: 36,
        height: 36,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: currentColor,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
        ),
      ),
    );
  }

  Widget _buildSyncStatus() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: isSyncing
            ? const Color(0xFF3B82F6).withOpacity(0.1)
            : hasUnsavedChanges
            ? const Color(0xFFF59E0B).withOpacity(0.1)
            : const Color(0xFF10B981).withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isSyncing
              ? const Color(0xFF3B82F6).withOpacity(0.3)
              : hasUnsavedChanges
              ? const Color(0xFFF59E0B).withOpacity(0.3)
              : const Color(0xFF10B981).withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isSyncing)
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(const Color(0xFF3B82F6)),
              ),
            )
          else
            Icon(
              hasUnsavedChanges ? Icons.cloud_upload : Icons.cloud_done,
              size: 12,
              color: hasUnsavedChanges
                  ? const Color(0xFFF59E0B)
                  : const Color(0xFF10B981),
            ),
          const SizedBox(width: 4),
          Text(
            isSyncing ? 'Syncing' : (hasUnsavedChanges ? 'Saving' : 'Synced'),
            style: TextStyle(
              color: isSyncing
                  ? const Color(0xFF3B82F6)
                  : hasUnsavedChanges
                  ? const Color(0xFFF59E0B)
                  : const Color(0xFF10B981),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}