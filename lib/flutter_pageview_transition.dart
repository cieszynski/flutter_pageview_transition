import 'package:flutter/material.dart';

typedef PageView PageViewBuilder(BuildContext context,
    PageViewVisibilityResolver pageViewVisibilityResolver);

class PageViewVisibilityResolver {
  PageViewVisibilityResolver({this.metrics});
  final ScrollMetrics metrics;

  double _getVisibility(int index, double position) {
    if (position > -1.0 && position <= 1.0) {
      return 1.0 - position.abs();
    }
    return 0.0;
  }

  double _getPagePosition(int index) {
    final double pageViewWidth = metrics?.viewportDimension ?? 1.0;
    final double pageX = pageViewWidth * index;
    final double scrollX = (metrics?.pixels ?? 0.0);
    final double pagePosition = (pageX - scrollX) / pageViewWidth;
    final double safePagePosition = !pagePosition.isNaN ? pagePosition : 0.0;

    if (safePagePosition > 1.0) {
      return 1.0;
    } else if (safePagePosition < -1.0) {
      return -1.0;
    }

    return safePagePosition;
  }

  PageViewVisibility resolve(int index) {
    final double position = _getPagePosition(index);
    final double visibility = _getVisibility(index, position);
    return PageViewVisibility(position: position, visibility: visibility, axis: metrics?.axis);
  }
}

class PageViewVisibility {
  PageViewVisibility({this.position, this.visibility, this.axis});
  final double position;
  final double visibility;
  final Axis axis;
}

class PageViewTransitionItem extends StatelessWidget {
  PageViewTransitionItem(this.pageViewVisibility);
  final PageViewVisibility pageViewVisibility;

  @override
  Widget build(BuildContext context) {
    return Stack(fit: StackFit.expand, children: [
      prepare(
          Center(
            child: Text("text1"),
          ),
          16),
      prepare(
          Center(
            child: Text("text2"),
          ),
          32),
    ]);
  }

  Widget prepare(Widget child, int elevation) {
    // return Center(child: Text(this.pageViewVisibility.pagePosition.toString()));
    final double translation = pageViewVisibility.position * elevation * 10;
    return Opacity(
      opacity: pageViewVisibility.visibility,
      child: Transform(
        alignment: FractionalOffset.topLeft,
        transform: Matrix4.translationValues(
          (pageViewVisibility.axis==Axis.horizontal) ? translation : 0.0,
          (pageViewVisibility.axis==Axis.vertical) ? translation : 0.0,
          0.0,
        ),
        child: Center(child: child),
      ),
    );
  }
}

class PageViewTransition extends StatefulWidget {
  PageViewTransition({@required this.pageViewBuilder});

  final PageViewBuilder pageViewBuilder;

  @override
  _PageViewTransitionState createState() => _PageViewTransitionState();
}

class _PageViewTransitionState extends State<PageViewTransition> {
  PageViewVisibilityResolver _pageViewVisibilityResolver;

  @override
  Widget build(BuildContext context) {
    final pageView = widget.pageViewBuilder(
        context, _pageViewVisibilityResolver ?? PageViewVisibilityResolver());
    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification notification) {
        setState(() {
          _pageViewVisibilityResolver =
              PageViewVisibilityResolver(metrics: notification.metrics);
        });
        return;
      },
      child: pageView,
    );
  }
}
