part of '../widgets.dart';

class CustomShimmerWidget extends StatelessWidget {
  final double? height;
  final double? width;
  final Color? highlightColor;
  final BoxShape? shape;

  const CustomShimmerWidget({
    super.key,
    this.height = 50,
    this.shape = BoxShape.rectangle,
    this.width = double.infinity,
    this.highlightColor = Colors.white,
  });

  const CustomShimmerWidget.circular({
    super.key,
    this.highlightColor = Colors.white,
  })  : height = 20,
        width = 20,
        shape = BoxShape.circle;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: highlightColor!,
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          shape: shape!,
          borderRadius: shape == BoxShape.circle ? null : BorderRadius.circular(10),
        ),
      ),
    );
  }
}