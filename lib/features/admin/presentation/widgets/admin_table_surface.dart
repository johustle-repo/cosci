import 'package:flutter/material.dart';

class AdminTableSurface extends StatefulWidget {
  const AdminTableSurface({
    super.key,
    required this.child,
    this.minWidth = 1040,
  });

  final Widget child;
  final double minWidth;

  static const _scrollbarThickness = 8.0;

  @override
  State<AdminTableSurface> createState() => _AdminTableSurfaceState();
}

class _AdminTableSurfaceState extends State<AdminTableSurface> {
  final ScrollController _horizontalController = ScrollController();

  @override
  void dispose() {
    _horizontalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tableWidth = constraints.maxWidth < widget.minWidth
            ? widget.minWidth
            : constraints.maxWidth;

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFD8E3F2)),
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0F173A67),
                blurRadius: 22,
                offset: Offset(0, 8),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Scrollbar(
            controller: _horizontalController,
            thumbVisibility: constraints.maxWidth < widget.minWidth,
            thickness: AdminTableSurface._scrollbarThickness,
            radius: const Radius.circular(20),
            child: SingleChildScrollView(
              controller: _horizontalController,
              scrollDirection: Axis.horizontal,
              primary: false,
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: SizedBox(width: tableWidth, child: widget.child),
            ),
          ),
        );
      },
    );
  }
}
