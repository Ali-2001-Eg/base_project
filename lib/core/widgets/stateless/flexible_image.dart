part of '../widgets.dart';


class FlexibleImage extends StatelessWidget {
  final dynamic source;
  final double borderRadius;
  final bool isCircular;
  final Widget? placeholder;
  final double? width;
  final double? height;
  final BoxFit? fit;
  const FlexibleImage({
    super.key,
    required this.source,
    this.borderRadius = 15,
    this.isCircular = false,
    this.placeholder,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  bool _isNetworkImage(String path) {
    return Uri.tryParse(path)?.hasAbsolutePath ?? false;
  }

  bool _isFileImage(String path) {
    return File(path).existsSync();
  }

  bool _isMemoryImage(dynamic data) {
    return data is Uint8List;
  }

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;
    if (source is String) {
      if (_isFileImage(source)) {
        imageWidget = Image.file(
          File(source),
          fit: fit,
        );
      } else if (_isNetworkImage(source)) {
        imageWidget = CachedNetworkImage(
          imageUrl: source,
          placeholder: (context, url) =>
          placeholder ??
              Center(
                  child: CustomShimmerWidget(
                    height: height,
                  )),
          errorWidget: (context, url, error) => Container(
              height: height,
              width: width,
              color: HexColor.greyColor.withValues(alpha: 0.3),
              child: const Icon(
                Icons.error,
                color: Colors.red,
              )),
          fit: fit,
        );
      } else {
        imageWidget = Container(
          padding: const EdgeInsets.all(8.0),
          decoration: const BoxDecoration(
            shape:BoxShape.circle,
            // color: context.colorScheme.secondary
          ),
          child: Image.asset(
            source,
            fit: fit,
            errorBuilder: (context, error, stackTrace) =>
                Container(padding: const EdgeInsets.all(5), decoration: BoxDecoration(shape: BoxShape.circle ,color: context.colorScheme.secondary), child: const Center(child: Icon(Icons.image_not_supported,size: 20,))),
          ),
        );
      }
    } else if (_isMemoryImage(source)) {
      imageWidget = Image.memory(
        source,
        fit: fit,
      );
    } else {
      imageWidget = placeholder ?? const Icon(Icons.image);
    }

    return ClipRRect(
      borderRadius: isCircular
          ? BorderRadius.circular(1000)
          : BorderRadius.circular(borderRadius),
      child: SizedBox(
        width: width,
        height: height,
        child: imageWidget,
      ),
    );
  }
}
