import 'dart:io';

import 'package:doc_scan/pages_repository.dart';
import 'package:doc_scan/utils/cropping_custom_ui.dart';
import 'package:doc_scan/utils/filter_page_widget.dart';
import 'package:doc_scan/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:scanbot_sdk/scanbot_sdk.dart' as sdk;
import 'package:scanbot_sdk/scanbot_sdk.dart';

class PageOperationsScreen extends StatefulWidget {
  final sdk.Page page;
  const PageOperationsScreen({super.key, required this.page});

  @override
  State<PageOperationsScreen> createState() => _PageOperationsScreenState();
}

class _PageOperationsScreenState extends State<PageOperationsScreen> {
  final PageRepository _pageRepository = PageRepository();
  late sdk.Page _page;
  bool showProgressBar = false;
  @override
  void initState() {
    _page = widget.page;
    super.initState();
  }

  Future<void> _updatePage(sdk.Page page) async {
    setState(() {
      showProgressBar = true;
    });
    await _pageRepository.updatePage(page);
    setState(() {
      showProgressBar = false;
      _page = page;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Column(
        children: <Widget>[
          Expanded(
            child: Container(
              padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
              child: Image
                  . /* file(
                File(
                  _page.documentImageFileUri!.path,
                ),
                // fit: BoxFit.fi,
              ) */
                  memory(getimagememory(_page.documentImageFileUri!)),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        padding: const EdgeInsetsDirectional.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            TextButton(
              onPressed: () {
                startCroppingScreen(_page);
              },
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(Icons.crop),
                  Text(
                    'RTU Crop',
                    style: TextStyle(inherit: true, color: Colors.black),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () {
                startCustomUiCroppingScreen(_page);
              },
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(Icons.crop),
                  Text(
                    'Classic Crop',
                    style: TextStyle(inherit: true, color: Colors.black),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () {
                showFilterPage(_page);
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Icon(Icons.filter),
                  Container(height: 4),
                  const Text(
                    'Filter',
                    style: TextStyle(inherit: true, color: Colors.black),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () {
                deletePage(_page);
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Icon(Icons.delete, color: Colors.red),
                  Container(width: 4),
                  const Text(
                    'Delete',
                    style: TextStyle(inherit: true, color: Colors.red),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> startCroppingScreen(sdk.Page page) async {
    if (!await checkLicenseStatus(context)) {
      return;
    }

    try {
      final config = CroppingScreenConfiguration(
        bottomBarBackgroundColor: Colors.blue,
        // polygonColor: Colors.yellow,
        // polygonLineWidth: 10,
        cancelButtonTitle: 'Cancel',
        doneButtonTitle: 'Save',
        // See further configs ...
      );
      final result = await ScanbotSdkUi.startCroppingScreen(page, config);
      if (isOperationSuccessful(result) && result.page != null) {
        await _updatePage(result.page!);
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> startCustomUiCroppingScreen(sdk.Page page) async {
    if (!await checkLicenseStatus(context)) {
      return;
    }

    try {
      var newPage = await Navigator.of(context).push(
        MaterialPageRoute(
            builder: (context) => CroppingScreenWidget(page: page)),
      );
      await _updatePage(newPage!);
    } catch (e) {
      print(e);
    }
  }

  Future<void> showFilterPage(sdk.Page page) async {
    if (!await checkLicenseStatus(context)) {
      return;
    }

    // ignore: use_build_context_synchronously
    final resultPage = await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => PageFiltering(page)),
    );
    if (resultPage != null) {
      await _updatePage(resultPage);
    }
  }

  Future<void> deletePage(sdk.Page page) async {
    try {
      await ScanbotSdk.deletePage(page);
      await _pageRepository.removePage(page);
      // ignore: use_build_context_synchronously
      Navigator.of(context).pop();
    } catch (e) {
      print(e);
    }
  }

  getimagememory(Uri uri) {
    var file = File.fromUri(uri);

    var memory = file.readAsBytesSync();

    return memory;
  }
}
