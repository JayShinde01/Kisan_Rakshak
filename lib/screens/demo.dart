import 'package:flutter/material.dart';

class SatelliteScreen extends StatefulWidget {
  const SatelliteScreen({Key? key}) : super(key: key);

  @override
  _SatelliteScreenState createState() => _SatelliteScreenState();
}

class _SatelliteScreenState extends State<SatelliteScreen> {
  final latController = TextEditingController();
  final lonController = TextEditingController();
  String? imageUrl;

  // TODO: Replace with your Instance ID
  final String instanceId = "0ba0454d-6434-482f-ac8e-2a0659708e8d";

  void loadImage() {
    final lat = latController.text.trim();
    final lon = lonController.text.trim();

    if (lat.isEmpty || lon.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Enter Lat & Lon")));
      return;
    }

    // Sentinel Hub WMS URL (NDVI Layer)
    final url =
        "https://services.sentinel-hub.com/ogc/wms/$instanceId"
        "?SERVICE=WMS"
        "&REQUEST=GetMap"
        "&LAYERS=NDVI"
        "&FORMAT=image/png"
        "&BBOX=${lon},${lat},${double.parse(lon) + 0.01},${double.parse(lat) + 0.01}"
        "&WIDTH=512"
        "&HEIGHT=512";

    setState(() {
      imageUrl = url;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("CropCareAI Satellite View"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: latController,
              decoration: const InputDecoration(
                labelText: "Latitude",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: lonController,
              decoration: const InputDecoration(
                labelText: "Longitude",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            ElevatedButton(
              onPressed: loadImage,
              child: const Text("Load Satellite Image"),
            ),

            const SizedBox(height: 20),

            Expanded(
              child: imageUrl == null
                  ? const Center(child: Text("No image loaded"))
                  : Image.network(imageUrl!),
            ),
          ],
        ),
      ),
    );
  }
}
