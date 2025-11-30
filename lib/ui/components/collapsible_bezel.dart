// Collapsible Bezel Component
//
// Base widget for bottom bezel panels that slide up from the bottom edge.
// Features smooth animations, glassmorphic styling, and lock functionality.
//
// Visual States:
// - Collapsed: 56px height showing tab button
// - Expanded: 300px height showing full content
// - Locked: Long-press to keep panel open
//
// A Paul Phillips Manifestation
//
import 'package:flutter/material.dart';
import '../theme/synth_theme.dart';
import 'package:provider/provider.dart';
import '../../providers/ui_state_provider.dart';
import '../panels/synthesis_panel.dart';
import '../panels/effects_panel.dart';
import '../panels/geometry_panel.dart';
import '../panels/mapping_panel.dart';

class CollapsibleBezel extends StatefulWidget {
  final String panelId;
  final String label;
  final IconData icon;
  final Widget content;
  final SystemColors systemColors;

  const CollapsibleBezel({
    super.key,
    required this.panelId,
    required this.label,
    required this.icon,
    required this.content,
    required this.systemColors,
  });

  @override
  State<CollapsibleBezel> createState() => _CollapsibleBezelState();
}

class _CollapsibleBezelState extends State<CollapsibleBezel>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _heightAnimation;
  late Animation<double> _opacityAnimation;
  bool _isLocked = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: SynthTheme.transitionStandard,
      vsync: this,
    );
    _heightAnimation = Tween<double>(
      begin: SynthTheme.panelCollapsedHeight,
      end: SynthTheme.panelExpandedHeight,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: SynthTheme.curveStandard,
      ),
    );
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.3, 1.0, curve: SynthTheme.curveEnter),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _togglePanel(UIStateProvider uiState) {
    final isExpanded = uiState.isPanelExpanded(widget.panelId);
    if (isExpanded) {
      _animationController.reverse();
      uiState.collapsePanel(widget.panelId);
    } else {
      // Collapse all other panels first
      uiState.collapseAllPanels();
      _animationController.forward();
      uiState.expandPanel(widget.panelId);
    }
  }

  void _handleLongPress() {
    setState(() => _isLocked = !_isLocked);
    // Haptic feedback placeholder - implement in Sprint 4
    debugPrint('🔒 Panel ${widget.panelId} locked: $_isLocked');
  }

  @override
  Widget build(BuildContext context) {
    final uiState = Provider.of<UIStateProvider>(context);
    final theme = SynthTheme(systemColors: widget.systemColors);
    final isExpanded = uiState.isPanelExpanded(widget.panelId);

    // Sync animation with state
    if (isExpanded && !_animationController.isCompleted) {
      _animationController.forward();
    } else if (!isExpanded && !_animationController.isDismissed) {
      _animationController.reverse();
    }

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Container(
          height: _heightAnimation.value,
          decoration: theme.getGlassPanelDecoration(expanded: isExpanded),
          child: Column(
            children: [
              // Tab button (always visible)
              GestureDetector(
                onTap: () => _togglePanel(uiState),
                onLongPress: _handleLongPress,
                child: Container(
                  height: SynthTheme.panelCollapsedHeight,
                  padding: const EdgeInsets.symmetric(
                    horizontal: SynthTheme.spacingMedium,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: isExpanded
                          ? BorderSide(
                              color: widget.systemColors.primary,
                              width: 2,
                            )
                          : BorderSide.none,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        widget.icon,
                        color: isExpanded
                            ? widget.systemColors.primary
                            : SynthTheme.textSecondary,
                        size: 20,
                      ),
                      const SizedBox(width: SynthTheme.spacingSmall),
                      Text(
                        widget.label,
                        style: SynthTheme.textStyleBody.copyWith(
                          color: theme.getTextColor(isExpanded),
                          fontWeight: isExpanded
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      if (_isLocked) ...[
                        const SizedBox(width: SynthTheme.spacingSmall),
                        Icon(
                          Icons.lock,
                          color: widget.systemColors.accent,
                          size: 14,
                        ),
                      ],
                      // Expansion indicator
                      const Spacer(),
                      Icon(
                        isExpanded
                            ? Icons.keyboard_arrow_down
                            : Icons.keyboard_arrow_up,
                        color: isExpanded
                            ? widget.systemColors.primary
                            : SynthTheme.textSecondary,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),

              // Panel content (visible when expanded)
              if (isExpanded)
                Expanded(
                  child: FadeTransition(
                    opacity: _opacityAnimation,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(SynthTheme.spacingMedium),
                      child: widget.content,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Bottom bezel container that holds all four panel tabs
class BottomBezelContainer extends StatelessWidget {
  final SystemColors systemColors;

  const BottomBezelContainer({
    super.key,
    required this.systemColors,
  });

  @override
  Widget build(BuildContext context) {
    final uiState = Provider.of<UIStateProvider>(context);
    final anyExpanded = uiState.isAnyPanelExpanded();

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Collapsed tabs (show all 4 when nothing is expanded)
          if (!anyExpanded)
            Container(
              height: SynthTheme.panelCollapsedHeight,
              decoration: BoxDecoration(
                color: SynthTheme.panelBackground.withOpacity(0.8),
                border: Border(
                  top: BorderSide(
                    color: SynthTheme.borderSubtle,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  _buildTabButton(
                    context,
                    'synthesis',
                    'Synthesis',
                    Icons.music_note,
                    uiState,
                  ),
                  _buildTabButton(
                    context,
                    'effects',
                    'Effects',
                    Icons.graphic_eq,
                    uiState,
                  ),
                  _buildTabButton(
                    context,
                    'geometry',
                    'Geometry',
                    Icons.category,
                    uiState,
                  ),
                  _buildTabButton(
                    context,
                    'mapping',
                    'Mapping',
                    Icons.settings_input_component,
                    uiState,
                  ),
                ],
              ),
            ),

          // Expanded panel (only one can be open at a time)
          if (anyExpanded)
            CollapsibleBezel(
              panelId: _getExpandedPanelId(uiState),
              label: _getExpandedPanelLabel(uiState),
              icon: _getExpandedPanelIcon(uiState),
              content: _getExpandedPanelContent(context, uiState),
              systemColors: systemColors,
            ),
        ],
      ),
    );
  }

  Widget _buildTabButton(
    BuildContext context,
    String panelId,
    String label,
    IconData icon,
    UIStateProvider uiState,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: () => uiState.expandPanel(panelId),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              right: BorderSide(
                color: SynthTheme.borderSubtle,
                width: 0.5,
              ),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: SynthTheme.textSecondary,
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: SynthTheme.textStyleCaption,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getExpandedPanelId(UIStateProvider uiState) {
    if (uiState.isPanelExpanded('synthesis')) return 'synthesis';
    if (uiState.isPanelExpanded('effects')) return 'effects';
    if (uiState.isPanelExpanded('geometry')) return 'geometry';
    if (uiState.isPanelExpanded('mapping')) return 'mapping';
    return 'synthesis';
  }

  String _getExpandedPanelLabel(UIStateProvider uiState) {
    final id = _getExpandedPanelId(uiState);
    return id[0].toUpperCase() + id.substring(1);
  }

  IconData _getExpandedPanelIcon(UIStateProvider uiState) {
    final id = _getExpandedPanelId(uiState);
    switch (id) {
      case 'synthesis':
        return Icons.music_note;
      case 'effects':
        return Icons.graphic_eq;
      case 'geometry':
        return Icons.category;
      case 'mapping':
        return Icons.settings_input_component;
      default:
        return Icons.music_note;
    }
  }

  Widget _getExpandedPanelContent(BuildContext context, UIStateProvider uiState) {
    final id = _getExpandedPanelId(uiState);
    switch (id) {
      case 'synthesis':
        return const SynthesisPanelContent();
      case 'effects':
        return const EffectsPanelContent();
      case 'geometry':
        return const GeometryPanelContent();
      case 'mapping':
        return const MappingPanelContent();
      default:
        return const SynthesisPanelContent();
    }
  }
}

