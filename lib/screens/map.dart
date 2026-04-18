import 'package:auto_route/auto_route.dart';
import 'package:factline/api/models/post.dart';
import 'package:factline/api/models/user.dart';
import 'package:factline/api/post.dart';
import 'package:factline/router/router.gr.dart';
import 'package:factline/services/auth.dart';
import 'package:factline/widgets/translated_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:latlong2/latlong.dart';

@RoutePage()
class MapScreen extends StatefulWidget {
  final AuthService authService;
  final User user;
  const MapScreen({super.key, required this.authService, required this.user});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  List<PostPin> _posts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPosts();
  }

  Future<void> _fetchPosts() async {
    try {
      final posts = await PostAPI().getMapPins();
      if (mounted) {
        setState(() {
          _posts = posts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final markers = _posts
        .where((p) => p.lat != null && p.long != null)
        .map((p) => _buildMarker(p))
        .toList();

    final heatCircles = _posts
        .where((p) => p.lat != null && p.long != null)
        .take(500)
        .map((p) {
          final intensity = (100 - (p.credibilityScore ?? 50)) / 100.0;
          return CircleMarker(
            point: LatLng(p.lat!, p.long!),
            radius: 5 + (intensity * 15),
            useRadiusInMeter: false,
            color: const Color(
              0xffD90429,
            ).withValues(alpha: 0.01 + (intensity * 0.05)),
            borderColor: Colors.transparent,
          );
        })
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xff0F0F0F),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(20, 0),
              initialZoom: 2.5,
              maxZoom: 18,
              minZoom: 2,
              backgroundColor: const Color(0xff0F0F0F),
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
                tileProvider: FMTCTileProvider(
                  stores: {'factline_hq': BrowseStoreStrategy.readUpdate},
                ),
              ),
              if (heatCircles.isNotEmpty) CircleLayer(circles: heatCircles),
              if (markers.isNotEmpty)
                MarkerClusterLayerWidget(
                  options: MarkerClusterLayerOptions(
                    maxClusterRadius: 80,
                    size: const Size(50, 50),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.all(50),
                    maxZoom: 15,
                    markers: markers,
                    builder: (context, clusterMarkers) {
                      return _buildClusterWidget(clusterMarkers);
                    },
                  ),
                ),
            ],
          ),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: Color(0xffD90429)),
            ),
          _buildMapHeader(),
          Positioned(
            bottom: 30,
            right: 20,
            child: FloatingActionButton(
              onPressed: () {
                _mapController.move(const LatLng(20, 0), 2.5);
              },
              backgroundColor: const Color(0xffD90429),
              elevation: 8,
              shape: const CircleBorder(),
              child: const Icon(
                Icons.zoom_out_map_rounded,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClusterWidget(List<Marker> markers) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xff18181B).withValues(alpha: 0.9),
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0xffD90429).withValues(alpha: 0.8),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xffD90429).withValues(alpha: 0.4),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Center(
        child: FactlineInter(
          markers.length.toString(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Marker _buildMarker(PostPin p) {
    final color = (p.credibilityScore ?? 0) > 70
        ? const Color(0xff457B9D)
        : const Color(0xffD90429);

    return Marker(
      point: LatLng(p.lat!, p.long!),
      width: 36,
      height: 36,
      child: GestureDetector(
        onTap: () => _showPostDetails(p),
        child: Container(
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.8),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 10),
            ],
          ),
          child: Icon(
            (p.credibilityScore ?? 0) > 70
                ? Icons.verified_user_rounded
                : Icons.warning_amber_rounded,
            color: Colors.white,
            size: 18,
          ),
        ),
      ),
    );
  }

  Widget _buildMapHeader() {
    return Positioned(
      top: 50,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(
              Icons.public_rounded,
              color: Color(0xffD90429),
              size: 28,
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FactlineMerriweather(
                    "Forensic Truth-Signal Matrix",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  FactlineInter(
                    "${_posts.length} Active Global Signals Detected",
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.white38,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPostDetails(PostPin post) async {
    // We need the full post detail for the bottom sheet
    try {
      final fullPost = await PostAPI().getPostDetail(post.id);
      if (fullPost != null && mounted) {
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (context) => _PostDetailSheet(
              post: fullPost, authService: widget.authService),
        );
      }
    } catch (e) {
      // Handle error
    }
  }
}

class _PostDetailSheet extends StatelessWidget {
  final Post post;
  final AuthService authService;
  const _PostDetailSheet({required this.post, required this.authService});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.45,
      decoration: const BoxDecoration(
        color: Color(0xff0F0F0F),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        border: Border(top: BorderSide(color: Colors.white10)),
      ),
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _statusBadge(post.riskType ?? "UNKNOWN"),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.close_rounded,
                    color: Colors.white70,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          FactlineMerriweather(
            post.title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.2,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          FactlineInter(
            post.summaryEasy ?? post.body ?? "",
            style: TextStyle(
              fontSize: 15,
              color: Colors.white.withValues(alpha: 0.6),
              height: 1.5,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xffD90429),
              foregroundColor: Colors.white,
              elevation: 0,
              minimumSize: const Size(double.infinity, 64),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
              context.router.push(
                NewsFullRoute(post: post, authService: authService),
              );
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FactlineInter(
                  "AUDIT FULL REPORT",
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.0,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.arrow_forward_rounded, size: 18),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String type) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xffD90429).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xffD90429).withValues(alpha: 0.3),
        ),
      ),
      child: FactlineInter(
        type.replaceAll("_", " "),
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          color: Color(0xffD90429),
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}
