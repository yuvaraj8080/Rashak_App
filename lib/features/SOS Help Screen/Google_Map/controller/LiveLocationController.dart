import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:vibration/vibration.dart';
import '../../../../common/widgets.Login_Signup/loaders/snackbar_loader.dart';
import '../../../Advanced_Safety_Tool/models/ReportIncidentModel.dart';
import 'SOS_Help_Controller.dart';

class LiveLocationController extends GetxController {
  static LiveLocationController get instance => Get.find();

  RxBool isShakeModeEnabled = false.obs;
  String? lastClusterId;
  var reports = <ReportIncidentModel>[].obs;
  var markers = <Marker>[].obs;
  var polygons = <Polygon>[].obs;
  Rx<LatLng> initialLatLng = LatLng(19.1213, 72.8237).obs;
  Rx<GoogleMapController?> googleMapController = Rx<GoogleMapController?>(null);
  final SOSController _sosController = Get.put(SOSController());
  int shakeCount = 0;


  @override
  void onInit() {
    super.onInit();
    _getPermission();
    getCurrentLocation();
    fetchReports();
    _startListeningShakeDetector();
    Timer.periodic(Duration(seconds: 5), (timer) {
      updateUserLocation(); // Check the user's location every 5 seconds
    });
  }

  // Method to check if the user is in a cluster
  void checkUserInCluster(LatLng userLocation) {
    for (var cluster in polygons) {
      if (_isPointInCluster(userLocation, cluster.points, 100)) {
        if (lastClusterId != cluster.polygonId.value) {
          lastClusterId = cluster.polygonId.value;
          TLoaders.warningSnackBar(title: "Alert: Danger zone", message: "You are in the Danger Area, Please Be Careful");
        }
        return;
      }
    }
    lastClusterId = null;
  }



  // Call this method whenever the user's location is updated
  Future<void> updateUserLocation() async {
    Position? position = await getCurrentLocation();
    if (position != null) {
      LatLng userLocation = LatLng(position.latitude, position.longitude);
      checkUserInCluster(userLocation);
    }
  }

  Future<void> fetchReports() async {
    try {
      final QuerySnapshot<Map<String, dynamic>> querySnapshot = await FirebaseFirestore.instance.collection("ReportIncidents").get();
      final List<ReportIncidentModel> fetchedReports = querySnapshot.docs.map((doc) => ReportIncidentModel.fromSnapshot(doc)).toList();
      reports.assignAll(fetchedReports);
      _loadPolygonsAndMarkers();
    } catch (e) {
      Get.snackbar('Error', 'Failed to fetch reports: $e');
    }
  }

  void _loadPolygonsAndMarkers() {
    final List<List<LatLng>> clusters = _clusterReports(reports, 100);
    final List<Polygon> reportPolygons = clusters.map((cluster) {
      final String id = cluster.map((e) => e.toString()).join();
      return Polygon(
        polygonId: PolygonId(id),
        points: cluster,
        strokeColor: Colors.redAccent,
        strokeWidth: 2,
        fillColor: Colors.red.withOpacity(0.15),
      );
    }).toList();

    final List<Marker> reportMarkers = [];
    for (var report in reports) {
      LatLng point = LatLng(double.parse(report.latitude), double.parse(report.longitude));
      reportMarkers.add(
        Marker(
          markerId: MarkerId(report.id),
          position: point,
          infoWindow: InfoWindow(
            title: report.titleIncident,
            snippet: report.incidentDescription,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
    }

    polygons.assignAll(reportPolygons);
    markers.assignAll(reportMarkers);
  }

  List<List<LatLng>> _clusterReports(List<ReportIncidentModel> reports, double distanceInMeters) {
    List<List<LatLng>> clusters = [];
    for (ReportIncidentModel report in reports) {
      LatLng point = LatLng(double.parse(report.latitude), double.parse(report.longitude));
      bool addedToCluster = false;
      for (List<LatLng> cluster in clusters) {
        if (_isPointInCluster(point, cluster, distanceInMeters)) {
          cluster.add(point);
          addedToCluster = true;
          break;
        }
      }
      if (!addedToCluster) {
        clusters.add([point]);
      }
    }
    return clusters;
  }

  bool _isPointInCluster(LatLng point, List<LatLng> cluster, double distanceInMeters) {
    for (LatLng clusterPoint in cluster) {
      double distance = Geolocator.distanceBetween(
        point.latitude,
        point.longitude,
        clusterPoint.latitude,
        clusterPoint.longitude,
      );
      if (distance <= distanceInMeters) {
        return true;
      }
    }
    return false;
  }

  Future<void> _getPermission() async {
    await Permission.location.request();
    await Permission.sms.request();
    await Permission.contacts.request();
  }

  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    while (!serviceEnabled) {
      TLoaders.warningSnackBar(title: 'Location services are disabled. Please Enable Location');
      await Geolocator.openLocationSettings();
      await Future.delayed(Duration(seconds: 2)); // wait for 2 seconds
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        TLoaders.warningSnackBar(title: 'Location Permissions are Denied');
        return false;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      TLoaders.warningSnackBar(
          title:'Location permissions are permanently Denied, we cannot request Permissions.');
      return false;
    }
    return true;
  }


  Future<Position?> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      TLoaders.warningSnackBar(title: 'Location services are disabled.');
      return null;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.whileInUse && permission != LocationPermission.always) {
        TLoaders.warningSnackBar(title: 'Location permissions are denied.');
        return null;
      }
    }

    return await Geolocator.getCurrentPosition(
      // desiredAccuracy: LocationAccuracy.high,
    );
  }

  /// SHAKE FEATURE IS HARE [SEND SOS HELP]
  void _startListeningShakeDetector() {
    accelerometerEvents.listen((event) async {
      if (isShakeModeEnabled.value && _isShaking(event)) {
        shakeCount++;
        if (shakeCount == 3) {
          Position? position = await getCurrentLocation();
          if (position != null) {
            await _sosController.sendShakeSOS(position);
            if (await Vibration.hasVibrator() ?? false) {
              Vibration.vibrate(duration: 100);
            }
          }
          shakeCount = 0; // reset shake count
        }
      }
    });
  }

  bool _isShaking(AccelerometerEvent event) {
    final double threshold = 70.0;
    return event.x.abs() > threshold || event.y.abs() > threshold || event.z.abs() > threshold;
  }
}
