import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_svg/flutter_svg.dart';

extension ImageTypeExtension on String {
  ImageType get imageType {
    if (startsWith('http')) {
      // Check if it's a network SVG
      if (endsWith('.svg')) {
        return ImageType.networkSvg;
      }
      return ImageType.network;
    } else if (endsWith('.svg')) {
      return ImageType.svg;
    } else if (endsWith('.webp')) {
      return ImageType.webp;
    } else if (startsWith('/') ||
        contains('/data/') ||
        contains('/cache/') ||
        contains('image_picker') ||
        startsWith('file:') ||
        contains('/storage/')) {
      return ImageType.file;
    } else {
      return ImageType.png;
    }
  }
}

enum ImageType { svg, networkSvg, png, network, file, webp, unknown, jpg }

class AppCustomImageView extends StatelessWidget {
  const AppCustomImageView({
    super.key,
    this.imagePath,
    this.icon,
    this.iconSize,
    this.iconColor,
    this.height,
    this.width,
    this.color,
    this.fit,
    this.alignment,
    this.onTap,
    this.radius,
    this.margin,
    this.border,
    this.placeHolder = 'assets/images/placeholder.webp',
    this.isCircle = false,
    this.backgroundColor,
  });

  final String? imagePath;
  final IconData? icon;
  final double? iconSize;
  final Color? iconColor;
  final double? height;
  final double? width;
  final Color? color;
  final BoxFit? fit;
  final String placeHolder;
  final Alignment? alignment;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? radius;
  final BoxBorder? border;
  final bool isCircle;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return alignment != null ? Align(alignment: alignment!, child: _buildWidget()) : _buildWidget();
  }

  Widget _buildWidget() {
    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: InkWell(onTap: onTap, child: _buildImageContainer()),
    );
  }

  Widget _buildImageContainer() {
    if (isCircle) {
      return _buildCircleAvatar();
    } else {
      return _buildCircleImage();
    }
  }

  Widget _buildCircleAvatar() {
    final avatarRadius = (height ?? width ?? 40) / 2;

    if (icon != null) {
      return CircleAvatar(
        radius: 40,
        backgroundColor: backgroundColor ?? Colors.grey.shade200,
        child: Icon(icon, size: iconSize ?? avatarRadius, color: iconColor ?? color),
      );
    }

    if (imagePath != null) {
      switch (imagePath!.imageType) {
        case ImageType.networkSvg:
          return CircleAvatar(
            radius: avatarRadius,
            backgroundColor: backgroundColor ?? Colors.grey.shade200,
            child: ClipOval(
              child: SvgPicture.network(
                imagePath!,
                height: height ?? width,
                width: width ?? height,
                fit: fit ?? BoxFit.cover,
                colorFilter: color != null ? ColorFilter.mode(color ?? Colors.transparent, BlendMode.srcIn) : null,
                placeholderBuilder: (BuildContext context) => SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.grey.shade400,
                    backgroundColor: Colors.grey.shade200,
                  ),
                ),
              ),
            ),
          );
        case ImageType.svg:
          return CircleAvatar(
            radius: avatarRadius,
            backgroundColor: backgroundColor ?? Colors.grey.shade200,
            child: ClipOval(
              child: SvgPicture.asset(
                imagePath!,
                height: height ?? width,
                width: width ?? height,
                fit: fit ?? BoxFit.cover,
                colorFilter: color != null ? ColorFilter.mode(color ?? Colors.transparent, BlendMode.srcIn) : null,
              ),
            ),
          );
        case ImageType.file:
          return CircleAvatar(
            radius: avatarRadius,
            backgroundColor: backgroundColor ?? Colors.grey.shade200,
            backgroundImage: FileImage(File(imagePath!)),
            onBackgroundImageError: (exception, stackTrace) {
              // Handle error by showing placeholder
            },
            child: imagePath!.isEmpty ? _buildPlaceholderIcon(avatarRadius) : null,
          );
        case ImageType.webp:
        case ImageType.png:
          return CircleAvatar(
            radius: avatarRadius,
            backgroundColor: backgroundColor ?? Colors.grey.shade200,
            backgroundImage: AssetImage(imagePath!),
            onBackgroundImageError: (exception, stackTrace) {
              // Handle error by showing placeholder
            },
            child: imagePath!.isEmpty ? _buildPlaceholderIcon(avatarRadius) : null,
          );
        case ImageType.network:
          return CircleAvatar(
            radius: avatarRadius,
            backgroundColor: backgroundColor ?? Colors.grey.shade200,
            child: ClipOval(
              child: CachedNetworkImage(
                height: height ?? width,
                width: width ?? height,
                fit: fit ?? BoxFit.cover,
                imageUrl: imagePath!,
                color: color,
                placeholder: (context, url) => SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.grey.shade400,
                    backgroundColor: Colors.grey.shade200,
                  ),
                ),
                errorWidget: (context, url, error) => ClipOval(
                  child: Image.asset(
                    placeHolder,
                    height: height ?? width,
                    width: width ?? height,
                    fit: fit ?? BoxFit.cover,
                  ),
                ),
              ),
            ),
          );
        default:
          return CircleAvatar(
            radius: avatarRadius,
            backgroundColor: backgroundColor ?? Colors.grey.shade200,
            child: _buildPlaceholderIcon(avatarRadius),
          );
      }
    }

    return CircleAvatar(
      radius: avatarRadius,
      backgroundColor: backgroundColor ?? Colors.grey.shade200,
      child: _buildPlaceholderIcon(avatarRadius),
    );
  }

  Widget _buildPlaceholderIcon(double radius) {
    return Icon(Icons.directions_car, size: radius * 0.8, color: Colors.grey.shade400);
  }

  Widget _buildCircleImage() {
    if (radius != null) {
      return ClipRRect(borderRadius: radius ?? BorderRadius.zero, child: _buildImageWithBorder());
    } else {
      return _buildImageWithBorder();
    }
  }

  Widget _buildImageWithBorder() {
    if (border != null) {
      return Container(
        decoration: BoxDecoration(
          border: border,
          borderRadius: isCircle ? null : radius,
          shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
        ),
        child: _buildImageView(),
      );
    } else {
      return _buildImageView();
    }
  }

  Widget _buildImageView() {
    if (icon != null) {
      return Icon(icon, size: iconSize ?? height, color: iconColor ?? color);
    }

    if (imagePath != null) {
      switch (imagePath!.imageType) {
        case ImageType.networkSvg:
          return SizedBox(
            height: height,
            width: width,
            child: SvgPicture.network(
              imagePath!,
              height: height,
              width: width,
              fit: fit ?? BoxFit.contain,
              colorFilter: color != null ? ColorFilter.mode(color ?? Colors.transparent, BlendMode.srcIn) : null,
              placeholderBuilder: (BuildContext context) => SizedBox(
                height: 30,
                width: 30,
                child: LinearProgressIndicator(color: Colors.grey.shade200, backgroundColor: Colors.grey.shade100),
              ),
            ),
          );
        case ImageType.svg:
          return SizedBox(
            height: height,
            width: width,
            child: SvgPicture.asset(
              imagePath!,
              height: height,
              width: width,
              fit: fit ?? BoxFit.contain,
              colorFilter: color != null ? ColorFilter.mode(color ?? Colors.transparent, BlendMode.srcIn) : null,
            ),
          );
        case ImageType.file:
          return Image.file(File(imagePath!), height: height, width: width, fit: fit ?? BoxFit.cover, color: color);
        case ImageType.webp:
          return Image.asset(imagePath!, height: height, width: width, fit: fit ?? BoxFit.cover, color: color);
        case ImageType.network:
          return CachedNetworkImage(
            height: height,
            width: width,
            fit: fit,
            imageUrl: imagePath!,
            color: color,
            placeholder: (context, url) => SizedBox(
              height: 30,
              width: 30,
              child: LinearProgressIndicator(color: Colors.grey.shade200, backgroundColor: Colors.grey.shade100),
            ),
            errorWidget: (context, url, error) =>
                Image.asset(placeHolder, height: height, width: width, fit: fit ?? BoxFit.cover),
          );
        case ImageType.png:
        default:
          return Image.asset(
            imagePath!,
            height: height,
            width: width,
            fit: fit ?? BoxFit.cover,
            color: color,
            errorBuilder: (context, error, stackTrace) {
              return Image.asset(placeHolder, height: height, width: width, fit: fit ?? BoxFit.cover);
            },
          );
      }
    }
    return const SizedBox();
  }
}
