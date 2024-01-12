import 'dart:developer';
import 'dart:io';

import 'package:doc_scan/pages_repository.dart';
import 'package:doc_scan/utils/utils.dart';
import 'package:doc_scan/views/docview/docviewer.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:scanbot_sdk/scanbot_sdk.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    _initScanbotSdk();
    super.initState();
  }

  final PageRepository _pageRepository = PageRepository();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('scan'),
      ),
      body: const Column(
        children: [
          Center(
            child: Text('data'),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _startDocumentScanning();
        },
        child: const Icon(Icons.camera),
      ),
    );
  }

  Future<void> _startDocumentScanning() async {
    if (!await checkLicenseStatus(context)) {
      return;
    }

    DocumentScanningResult? result;
    try {
      var config = DocumentScannerConfiguration(
        bottomBarBackgroundColor: ScanbotRedColor,
        ignoreBadAspectRatio: true,
        multiPageEnabled: true,
        //maxNumberOfPages: 3,
        //flashEnabled: true,
        //autoSnappingSensitivity: 0.7,
        cameraPreviewMode: CameraPreviewMode.FIT_IN,
        orientationLockMode: OrientationLockMode.PORTRAIT,
        //documentImageSizeLimit: Size(2000, 3000),
        cancelButtonTitle: 'Cancel',
        pageCounterButtonTitle: '%d Page(s)',
        textHintOK: "Perfect, don't move...",
        //textHintNothingDetected: "Nothing",
        // ...
      );
      result = await ScanbotSdkUi.startDocumentScanner(config);
    } catch (e) {
      log('$e');
    }
    if (result != null) {
      if (isOperationSuccessful(result)) {
        await _pageRepository.addPages(result.pages);

        await _gotoImagesView();
      }
    }
  }

// ignore: constant_identifier_names, prefer_interpolation_to_compose_strings, prefer_adjacent_string_concatenation
  static const LICENSE_KEY = "lhbV0K6f7PrJkQtaaJzAzm4D+fpXGJ" +
      "rLeEDNc1mfNA1nbDKQ+uwOWRs+nptn" +
      "/tBZBwGYaL3imO5hlhTRuCC8Pgzn9L" +
      "Y/bS/9ZhtlUeBdLB+M5PrtU6ovQE8S" +
      "niOxhobdP7207G4WPH2MCouIiGF2gc" +
      "sBfpGgU2n/kwdIVPEJUK1PluAH3eJs" +
      "SPhTw/D/ORcXeF9XF7bwhjsDdgPBsn" +
      "9BG4yU3cMVYaZ+kFSAF25DsCvEqIl6" +
      "ETfXyBOlMl2q+IoGNgwC98kvh8bqYl" +
      "1TM+GzX4WsU7mQ9zjdYXuATSj1kVc1" +
      "FClLh0A9BK51/DQYprP9pv3DQk1sTi" +
      "SsnRKnOBqYfA==\nU2NhbmJvdFNESw" +
      "pjb20uZXhhbXBsZS5kb2Nfc2Nhbgox" +
      "NzA1NjIyMzk5CjgzODg2MDcKMTk=\n";

  Future<void> _initScanbotSdk() async {
    // Consider adjusting this optional storageBaseDirectory - see the comments below.
    final customStorageBaseDirectory = await getDemoStorageBaseDirectory();
    await ScanbotSdk.initScanbotSdk(ScanbotSdkConfig(licenseKey: LICENSE_KEY));

    // final encryptionParams = _getEncryptionParams();

    var config = ScanbotSdkConfig(
      loggingEnabled: true,
      // Consider switching logging OFF in production builds for security and performance reasons.
      licenseKey: LICENSE_KEY,
      imageFormat: ImageFormat.JPG,
      imageQuality: 100,
      storageBaseDirectory: customStorageBaseDirectory,
      documentDetectorMode: DocumentDetectorMode
          .ML_BASED, /*   encryptionParameters: encryptionParams */
    );
    try {
      await ScanbotSdk.initScanbotSdk(config);
      // await PageRepository().loadPages();
    } catch (e) {
      // Logger.root.severe(e);
      log('$e');
    }
  }

  Future<String> getDemoStorageBaseDirectory() async {
    Directory storageDirectory;
    if (Platform.isAndroid) {
      storageDirectory = (await getExternalStorageDirectory())!;
    } else if (Platform.isIOS) {
      storageDirectory = await getApplicationDocumentsDirectory();
    } else {
      throw ('Unsupported platform');
    }

    return '${storageDirectory.path}/my-custom-storage';
  }

  EncryptionParameters? _getEncryptionParams() {
    EncryptionParameters? encryptionParams;
    if (shouldInitWithEncryption) {
      encryptionParams = EncryptionParameters(
        password: 'SomeSecretPa\$\$w0rdForFileEncryption',
        mode: FileEncryptionMode.AES256,
      );
    }
    return encryptionParams;
  }

  bool shouldInitWithEncryption = false;

  Future<dynamic> _gotoImagesView() async {
    return await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const DocumentViewScreen()),
    );
  }
}
