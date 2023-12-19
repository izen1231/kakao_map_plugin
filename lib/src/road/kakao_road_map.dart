part of kakao_map_plugin;

class KakaoRoadMap extends StatefulWidget {
  final RoadMapCreateCallback? onMapCreated;
  final int currentLevel;
  final LatLng? center;
  final List<Marker>? markers;

  const KakaoRoadMap({
    Key? key,
    this.onMapCreated,
    this.currentLevel = 3,
    this.center,
    this.markers,
  }) : super(key: key);

  @override
  State<KakaoRoadMap> createState() => _KakaoRoadMapState();
}

class _KakaoRoadMapState extends State<KakaoRoadMap> {
  String json = '';
  List<Map<String, dynamic>> mapList = [];
  late final KakaoRoadMapController _mapController;

  @override
  void initState() {
    super.initState();

    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    final WebViewController controller =
        WebViewController.fromPlatformCreationParams(params);

    addJavaScriptChannels(controller);

    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadHtmlString(_loadMap());

    if (controller.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(true);
      (controller.platform as AndroidWebViewController)
          .setMediaPlaybackRequiresUserGesture(false);
    }

    _mapController = KakaoRoadMapController(controller);
  }

  @override
  Widget build(BuildContext context) {
    getMarkers();
    return WebViewWidget(
      controller: _mapController.webViewController,
      gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
        Factory(() => EagerGestureRecognizer()),
      },
    );
  }

  getMarkers() {
    int length = widget.markers?.length ?? 0;

    for (int i = 0; i < length; i++) {
      final item = widget.markers![i];
      Map<String, dynamic> marker = {
        "markerId": item.markerId,
        "latitude": item.latLng.latitude,
        "longitude": item.latLng.longitude,
        "text": item.infoWindowContent,
      };

      mapList.add(marker);
    }

    json = jsonEncode(mapList);
  }

  String _loadMap() {
    return _htmlWrapper("""<script>

  let roadview = null;
  let roadviewClient = null;
  const defaultCenter = new kakao.maps.LatLng(33.450701, 126.570667);

  window.onload = function () {
    const container = document.getElementById('map'); //로드뷰를 표시할 div
    roadview = new kakao.maps.Roadview(container); //로드뷰 객체
    roadviewClient = new kakao.maps.RoadviewClient(); //좌표로부터 로드뷰 파노ID를 가져올 로드뷰 helper객체

    let center = defaultCenter;
    let position = new kakao.maps.LatLng(33.450701, 126.570667);
    
    toggleRoadview(position.getLat(), position.getLng())
    
    onMapCreated.postMessage({"test": 1});
  }


  function toggleRoadview(latitude, longitude) {
  const position = new kakao.maps.LatLng(latitude, longitude)
    // 특정 위치의 좌표와 가까운 로드뷰의 panoId를 추출하여 로드뷰를 띄운다.
    roadviewClient.getNearestPanoId(position, 50, function (panoId) {
      roadview.setPanoId(panoId, position); //panoId와 중심좌표를 통해 로드뷰 실행
    });

  }
</script>""");
  }

  @override
  void didUpdateWidget(covariant KakaoRoadMap oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  void addJavaScriptChannels(WebViewController controller) {
    controller
      ..addJavaScriptChannel('onMapCreated',
          onMessageReceived: (JavaScriptMessage result) {
        if (widget.onMapCreated != null) {
          widget.onMapCreated!(_mapController);
        }
      });
  }
}
