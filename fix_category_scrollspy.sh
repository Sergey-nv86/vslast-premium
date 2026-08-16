#!/bin/bash
set -euo pipefail

PROJECT="${1:-$(pwd)}"
FILE="$PROJECT/lib/features/home/screens/home_screen.dart"

if [ ! -f "$FILE" ]; then
  echo "ERROR: $FILE not found"
  exit 1
fi

cp "$FILE" "$FILE.bak_scrollspy_$(date +%Y%m%d_%H%M%S)"
echo "Backup created."

python3 - "$FILE" <<'PY'
from pathlib import Path
import sys

p = Path(sys.argv[1])
s = p.read_text()

old = """  void _updateActiveCategory() {
    final selfBox =
        _viewportKey.currentContext?.findRenderObject() as RenderBox?;
    if (selfBox == null || !selfBox.attached) return;

    ProductCategory? best;
    double bestOffset = double.negativeInfinity;
    for (final category in _categoriesShown) {
      final ctx = _sectionKeys[category]?.currentContext;
      final box = ctx?.findRenderObject() as RenderBox?;
      if (box == null || !box.attached) continue;
      final offset = box.localToGlobal(Offset.zero, ancestor: selfBox).dy;
      if (offset <= _spyThreshold && offset > bestOffset) {
        bestOffset = offset;
        best = category;
      }
    }
    best ??= _categoriesShown.isNotEmpty ? _categoriesShown.first : null;
    if (best != _activeCategory) setState(() => _activeCategory = best);
  }"""

new = """  void _updateActiveCategory() {
    if (_categoriesShown.isEmpty) return;

    final selfBox =
        _viewportKey.currentContext?.findRenderObject() as RenderBox?;
    if (selfBox == null || !selfBox.attached) return;

    // CategoryBar is pinned at the top of this viewport. A category becomes
    // active when its section heading crosses the bottom of CategoryBar.
    final threshold = _pinnedBarHeight;

    final activeIndex = _activeCategory == null
        ? -1
        : _categoriesShown.indexOf(_activeCategory!);

    ProductCategory? candidate;
    double candidateTop = double.negativeInfinity;
    int candidateIndex = -1;

    // Off-screen slivers can be detached by Flutter. Do not fall back to
    // the first category when the previous heading is temporarily detached.
    for (var i = 0; i < _categoriesShown.length; i++) {
      final category = _categoriesShown[i];
      final ctx = _sectionKeys[category]?.currentContext;
      final box = ctx?.findRenderObject() as RenderBox?;
      if (box == null || !box.attached) continue;

      final top = box.localToGlobal(
        Offset.zero,
        ancestor: selfBox,
      ).dy;

      if (top <= threshold && top > candidateTop) {
        candidate = category;
        candidateTop = top;
        candidateIndex = i;
      }
    }

    if (candidate != null) {
      if (candidateIndex != activeIndex) {
        _setActiveCategory(candidate);
      }
      return;
    }

    // Keep the current category while the previous heading is detached and
    // the next heading has not yet reached the pinned CategoryBar.
    if (_activeCategory == null) {
      _setActiveCategory(_categoriesShown.first);
    }
  }

  void _setActiveCategory(ProductCategory category) {
    if (_activeCategory == category || !mounted) return;
    setState(() => _activeCategory = category);
  }"""

if old not in s:
    raise SystemExit("ERROR: original _updateActiveCategory block not found")
s = s.replace(old, new)

old2 = """  void _scrollToCategory(ProductCategory category) {
    final ctx = _sectionKeys[category]?.currentContext;
    final box = ctx?.findRenderObject() as RenderBox?;
    final selfBox =
        _viewportKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || selfBox == null || !_scrollController.hasClients) return;

    final targetLocalY = box.localToGlobal(Offset.zero, ancestor: selfBox).dy;
    final delta = targetLocalY - _pinnedBarHeight;
    final targetOffset = (_scrollController.offset + delta).clamp(
      _scrollController.position.minScrollExtent,
      _scrollController.position.maxScrollExtent,
    );
    _scrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }"""

new2 = """  void _scrollToCategory(ProductCategory category) {
    final ctx = _sectionKeys[category]?.currentContext;
    final box = ctx?.findRenderObject() as RenderBox?;
    final selfBox =
        _viewportKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || selfBox == null || !_scrollController.hasClients) {
      return;
    }

    final targetLocalY = box.localToGlobal(
      Offset.zero,
      ancestor: selfBox,
    ).dy;

    final delta = targetLocalY - _pinnedBarHeight;
    final targetOffset = (_scrollController.offset + delta).clamp(
      _scrollController.position.minScrollExtent,
      _scrollController.position.maxScrollExtent,
    );

    // Immediate visual response to a tap; the scroll listener keeps it
    // synchronized during and after the animation.
    _setActiveCategory(category);

    _scrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }"""

if old2 not in s:
    raise SystemExit("ERROR: original _scrollToCategory block not found")
s = s.replace(old2, new2)

p.write_text(s)
PY

echo "Scroll-spy patched successfully."
echo
echo "Next:"
echo "  flutter analyze"
echo "  flutter run -d chrome"
