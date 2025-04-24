import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sheshield/common/widgets.Login_Signup/loaders/snackbar_loader.dart';
import '../controller/LiveLocationController.dart';
import '../controller/SOS_Help_Controller.dart';

class GoogleMap_View_Screen extends StatelessWidget {
  final LiveLocationController locationController = Get.put(LiveLocationController());
  final SOSController sosController = Get.put(SOSController());

  @override
  Widget build(BuildContext context) {
    return Obx(() => Scaffold(
      body: GoogleMap(
        buildingsEnabled: true,
        trafficEnabled: true,
        mapType: MapType.normal,
        initialCameraPosition: CameraPosition(
          target: locationController.initialLatLng.value,
          zoom: 14.0,
        ),
        markers: Set<Marker>.of(locationController.markers),
        polygons: Set<Polygon>.of(locationController.polygons),
        myLocationButtonEnabled: true,
        myLocationEnabled: true,
        onMapCreated: (GoogleMapController controller) {
          locationController.googleMapController.value = controller;
        },
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: GestureDetector(
        onLongPress: () async {
          await sosController.stopSOS(); // Stop SOS on long press
        },
        child: FloatingActionButton.extended(
          label: Text(sosController.isSOSActive.value ? "Stop SOS" : "Start SOS"),
          icon: sosController.isSOSActive.value
              ? Icon(Icons.stop, color: Colors.white)
              : Row(
            children: [
              CircleAvatar(
                backgroundImage: AssetImage("assets/images/sos.png"),
                radius: 25,
              ),
            ],
          ),
          backgroundColor: sosController.isSOSActive.value ? Colors.red : Colors.blue,
          onPressed: () async {
            print("printing");
            Position? position = await locationController.getCurrentLocation();
            print("Printing: ${position.toString()}");
            if (position != null) {
              await sosController.sendSOS(position); // Send SOS on tap
            } else {
              TLoaders.warningSnackBar(title: 'Failed to get current location');
            }
          },
        ),
      ),
    ));
  }
}