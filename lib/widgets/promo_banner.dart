import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shoefit/models/shoe_model.dart';

class PromoBanner extends StatelessWidget {
  const PromoBanner({
    super.key,
    required this.onExploreTap,
    this.featuredProduct,
  });

  final VoidCallback onExploreTap;
  final ShoeModel? featuredProduct;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 430;
        final bannerHeight = compact ? 250.0 : 260.0;
        final visualWidth = compact
            ? constraints.maxWidth * .43
            : constraints.maxWidth * .38;

        return Semantics(
          container: true,
          label: 'Premium Drop promotion',
          child: Container(
            height: bannerHeight,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF07142E),
                  Color(0xFF102E58),
                  Color(0xFF0D8F98),
                ],
                stops: [0, .55, 1],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0B5670).withValues(alpha: .22),
                  blurRadius: 28,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Stack(
              children: [
                const Positioned(
                  top: -72,
                  right: -42,
                  child: _GlowOrb(
                    size: 190,
                    colors: [Color(0x663DE5D4), Color(0x0017BEBB)],
                  ),
                ),
                const Positioned(
                  bottom: -92,
                  left: 160,
                  child: _GlowOrb(
                    size: 190,
                    colors: [Color(0x334A76FF), Color(0x000B132B)],
                  ),
                ),
                Positioned(
                  top: 18,
                  right: compact ? -10 : 20,
                  bottom: 18,
                  width: visualWidth,
                  child: Transform.rotate(
                    angle: .045,
                    child: _ProductVisual(product: featuredProduct),
                  ),
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF07142E),
                            const Color(0xFF07142E).withValues(alpha: .82),
                            const Color(0xFF07142E).withValues(alpha: .08),
                          ],
                          stops: compact
                              ? const [0, .58, .84]
                              : const [0, .46, .76],
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    compact ? 20 : 24,
                    21,
                    compact ? 16 : 22,
                    20,
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: SizedBox(
                      width: constraints.maxWidth * (compact ? .72 : .62),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _DropLabel(),
                          const Spacer(),
                          Text(
                            compact
                                ? 'Own the next\nstep.'
                                : 'Fresh pairs.\nSerious presence.',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: compact ? 27 : 31,
                              height: 1.03,
                              letterSpacing: -1,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            featuredProduct == null
                                ? 'A sharper weekly edit, curated for your rotation.'
                                : '${featuredProduct!.brand} • ${featuredProduct!.name}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: .72),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          _ExploreButton(onPressed: onExploreTap),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: compact ? 12 : 22,
                  bottom: 15,
                  child: Text(
                    'DROP / 01',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: .55),
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DropLabel extends StatelessWidget {
  const _DropLabel();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: .15)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome_rounded, color: Color(0xFF72F2E5), size: 14),
          SizedBox(width: 6),
          Text(
            'PREMIUM DROP',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExploreButton extends StatelessWidget {
  const _ExploreButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(999),
        child: const Padding(
          padding: EdgeInsets.fromLTRB(16, 10, 12, 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Explore the drop',
                style: TextStyle(
                  color: Color(0xFF0B132B),
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(width: 7),
              CircleAvatar(
                radius: 11,
                backgroundColor: Color(0xFF0B132B),
                child: Icon(
                  Icons.arrow_outward_rounded,
                  color: Colors.white,
                  size: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductVisual extends StatelessWidget {
  const _ProductVisual({required this.product});

  final ShoeModel? product;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(27),
        border: Border.all(
          color: Colors.white.withValues(alpha: .2),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .2),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: product == null || product!.imageUrl.trim().isEmpty
            ? const _ProductPlaceholder()
            : Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: product!.imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, _) => const _ProductPlaceholder(),
                    errorWidget: (_, _, _) => const _ProductPlaceholder(),
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.transparent, Color(0xB307142E)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: [.52, 1],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 12,
                    right: 12,
                    bottom: 13,
                    child: Text(
                      product!.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _ProductPlaceholder extends StatelessWidget {
  const _ProductPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1B5273), Color(0xFF18A7A4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.directions_run_rounded,
          color: Colors.white,
          size: 58,
        ),
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.size, required this.colors});

  final double size;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: colors),
      ),
    );
  }
}
