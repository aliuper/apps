import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';

// ==================== GLASS CARD ====================
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final double borderRadius;
  final Color? color;
  final bool showBorder;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 16,
    this.color,
    this.showBorder = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppProvider>().theme;
    
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: color ?? theme.card,
        borderRadius: BorderRadius.circular(borderRadius),
        border: showBorder ? Border.all(
          color: theme.gradient1.withOpacity(0.1),
          width: 1.5,
        ) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    );
  }
}

// ==================== ACCENT BUTTON ====================
class AccentButton extends StatelessWidget {
  final String text;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color? color;
  final double height;
  final double? width;
  final double borderRadius;

  const AccentButton({
    super.key,
    required this.text,
    this.icon,
    this.onPressed,
    this.isLoading = false,
    this.color,
    this.height = 52,
    this.width,
    this.borderRadius = 14,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppProvider>().theme;
    
    return SizedBox(
      height: height,
      width: width ?? double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? theme.accent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          elevation: 4,
          shadowColor: (color ?? theme.accent).withOpacity(0.4),
        ),
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    text,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// ==================== GHOST BUTTON ====================
class GhostButton extends StatelessWidget {
  final String text;
  final IconData? icon;
  final VoidCallback? onPressed;
  final Color? color;
  final double height;

  const GhostButton({
    super.key,
    required this.text,
    this.icon,
    this.onPressed,
    this.color,
    this.height = 46,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppProvider>().theme;
    
    return SizedBox(
      height: height,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: theme.card,
          foregroundColor: color ?? theme.t1,
          side: BorderSide(color: theme.card2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18),
              const SizedBox(width: 8),
            ],
            Text(text),
          ],
        ),
      ),
    );
  }
}

// ==================== ICON BUTTON CIRCLE ====================
class IconButtonCircle extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? color;
  final Color? backgroundColor;
  final double size;
  final double iconSize;

  const IconButtonCircle({
    super.key,
    required this.icon,
    this.onPressed,
    this.color,
    this.backgroundColor,
    this.size = 48,
    this.iconSize = 22,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppProvider>().theme;
    
    return Material(
      color: backgroundColor ?? theme.card,
      borderRadius: BorderRadius.circular(size / 2),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(size / 2),
        child: SizedBox(
          width: size,
          height: size,
          child: Center(
            child: Icon(
              icon,
              color: color ?? theme.t1,
              size: iconSize,
            ),
          ),
        ),
      ),
    );
  }
}

// ==================== STAT CARD ====================
class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppProvider>().theme;
    
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: theme.card,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 18),
                const SizedBox(width: 6),
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: theme.t3,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== PROGRESS BAR ====================
class AnimatedProgressBar extends StatelessWidget {
  final double progress;
  final Color? color;
  final double height;
  final double borderRadius;

  const AnimatedProgressBar({
    super.key,
    required this.progress,
    this.color,
    this.height = 24,
    this.borderRadius = 12,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppProvider>().theme;
    
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: theme.card2,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Stack(
        children: [
          AnimatedFractionallySizedBox(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            widthFactor: progress.clamp(0, 1),
            child: Container(
              margin: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    color ?? theme.accent,
                    (color ?? theme.accent).withOpacity(0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(borderRadius - 4),
                boxShadow: [
                  BoxShadow(
                    color: (color ?? theme.accent).withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== MENU ITEM CARD ====================
class MenuItemCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final VoidCallback? onTap;

  const MenuItemCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppProvider>().theme;
    
    return GlassCard(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: theme.t1,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: theme.t3,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.chevron_right,
              color: Colors.white,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== SELECTION CHIP ====================
class SelectionChip extends StatelessWidget {
  final String label;
  final String? prefix;
  final bool isSelected;
  final VoidCallback? onTap;
  final Color? selectedColor;
  final Color? unselectedColor;

  const SelectionChip({
    super.key,
    required this.label,
    this.prefix,
    required this.isSelected,
    this.onTap,
    this.selectedColor,
    this.unselectedColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppProvider>().theme;
    final bgColor = isSelected ? (selectedColor ?? theme.ok) : (unselectedColor ?? theme.card);
    
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: bgColor.withOpacity(isSelected ? 0.2 : 1),
          borderRadius: BorderRadius.circular(12),
          border: isSelected ? Border.all(color: bgColor, width: 2) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (prefix != null) ...[
              Text(prefix!, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected ? (selectedColor ?? theme.ok) : theme.t1,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Icon(
                Icons.check_circle,
                color: selectedColor ?? theme.ok,
                size: 18,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ==================== EMPTY STATE ====================
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppProvider>().theme;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: theme.t4),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                color: theme.t2,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: TextStyle(color: theme.t4, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 24),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

// ==================== APP BAR ====================
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showBack;
  final VoidCallback? onBack;

  const CustomAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.showBack = true,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppProvider>().theme;
    
    return Container(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      decoration: BoxDecoration(
        color: theme.bg,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: [
            if (showBack)
              IconButtonCircle(
                icon: Icons.arrow_back,
                onPressed: onBack ?? () => Navigator.pop(context),
              )
            else if (leading != null)
              leading!,
            if (showBack || leading != null) const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: theme.t1,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (actions != null) ...actions!,
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(60);
}
