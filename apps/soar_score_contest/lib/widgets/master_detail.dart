import 'package:flutter/material.dart';

/// Builds one pane of a [MasterDetail]; [wide] says whether both panes are
/// shown side by side.
typedef MasterDetailPaneBuilder = Widget Function(
  BuildContext context,
  bool wide,
);

/// A list and detail layout.
///
/// When the available width is at least [wideWidth] the list sits in a
/// fixed-width pane beside the detail. Narrower, only one pane shows: the
/// list, or the detail once [showDetail] is set (the detail pane then offers
/// its own way back).
class MasterDetail extends StatelessWidget {
  const MasterDetail({
    super.key,
    required this.list,
    required this.detail,
    required this.showDetail,
  });

  final MasterDetailPaneBuilder list;
  final MasterDetailPaneBuilder detail;

  /// Whether the narrow layout shows the detail instead of the list.
  final bool showDetail;

  static const double wideWidth = 800;
  static const double listWidth = 400;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final wide = constraints.maxWidth >= wideWidth;
      if (!wide) {
        return showDetail ? detail(context, false) : list(context, false);
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(width: listWidth, child: list(context, true)),
          const VerticalDivider(width: 1, thickness: 1),
          Expanded(child: detail(context, true)),
        ],
      );
    },
  );
}
