import 'dart:typed_data';

import 'package:doc_scan/utils/progress_dialog.dart';
import 'package:doc_scan/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:scanbot_sdk/scanbot_sdk.dart';
import 'package:scanbot_sdk/scanbot_sdk.dart' as sdk;

class PageFiltering extends StatelessWidget {
  final sdk.Page _page;

  const PageFiltering(this._page, {super.key});

  @override
  Widget build(BuildContext context) {
    var filterPreviewWidget = FilterPreviewWidget(_page);
    return Scaffold(
        appBar: AppBar(
          actions: <Widget>[
            GestureDetector(
              onTap: () {
                filterPreviewWidget.applyFilter();
              },
              child: const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('APPLY',
                      style: TextStyle(inherit: true, color: Colors.black)),
                ),
              ),
            ),
          ],
          iconTheme: const IconThemeData(
            color: Colors.black, //change your color here
          ),
          backgroundColor: Colors.white,
          title: const Text('Filtering',
              style: TextStyle(inherit: true, color: Colors.black)),
        ),
        body: filterPreviewWidget);
  }
}

// ignore: must_be_immutable
class FilterPreviewWidget extends StatefulWidget {
  final sdk.Page page;
  late FilterPreviewWidgetState filterPreviewWidgetState;

  FilterPreviewWidget(this.page, {super.key}) {
    filterPreviewWidgetState = FilterPreviewWidgetState(page);
  }

  void applyFilter() {
    filterPreviewWidgetState.applyFilter();
  }

  @override
  State<FilterPreviewWidget> createState() {
    // ignore: no_logic_in_create_state
    return filterPreviewWidgetState;
  }
}

class FilterPreviewWidgetState extends State<FilterPreviewWidget> {
  sdk.Page page;
  Uri? filteredImageUri;
  late ImageFilterType selectedFilter;

  FilterPreviewWidgetState(this.page) {
    filteredImageUri = page.documentImageFileUri;
    selectedFilter = page.filter ?? ImageFilterType.NONE;
  }

  @override
  Widget build(BuildContext context) {
    final imageData =
        ScanbotEncryptionHandler.getDecryptedDataFromFile(filteredImageUri!);
    final image = FutureBuilder<Uint8List>(
        future: imageData,
        builder: (BuildContext context, AsyncSnapshot<Uint8List> snapshot) {
          if (snapshot.data != null) {
            var image = Image.memory(snapshot.data!);
            return Center(child: image);
          } else {
            return Container();
          }
        });
    return ListView(
      shrinkWrap: true,
      children: <Widget>[
        buildContainer(image),
        const Text('Select filter',
            style: TextStyle(
                inherit: true,
                color: Colors.black,
                fontStyle: FontStyle.normal)),
        for (var filter in ImageFilterType.values)
          RadioListTile(
            title: titleFromFilterType(filter),
            value: filter,
            groupValue: selectedFilter,
            onChanged: (value) {
              previewFilter(page, value ?? ImageFilterType.NONE);
            },
          ),
      ],
    );
  }

  Container buildContainer(Widget image) {
    return Container(
      height: 400,
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
      child: Center(
        child: SizedBox(
          height: double.infinity,
          width: double.infinity,
          child: Center(child: image),
        ),
      ),
    );
  }

  Text titleFromFilterType(ImageFilterType filterType) {
    return Text(
      filterType.toString().replaceAll('ImageFilterType.', ''),
      style: const TextStyle(
        inherit: true,
        color: Colors.black,
        fontStyle: FontStyle.normal,
      ),
    );
  }

  Future<void> applyFilter() async {
    if (!await checkLicenseStatus(context)) {
      return;
    }

    // ignore: use_build_context_synchronously
    final dialog = ProgressDialog(context,
        type: ProgressDialogType.Normal, isDismissible: false);
    dialog.style(message: 'Processing');
    dialog.show();
    try {
      final updatedPage =
          await ScanbotSdk.applyImageFilter(page, selectedFilter);
      await dialog.hide();
      // ignore: use_build_context_synchronously
      Navigator.of(context).pop(updatedPage);
    } catch (e) {
      await dialog.hide();
      // ignore: avoid_print
      print(e);
    }
  }

  Future<void> previewFilter(sdk.Page page, ImageFilterType filterType) async {
    if (!await checkLicenseStatus(context)) {
      return;
    }

    try {
      final uri =
          await ScanbotSdk.getFilteredDocumentPreviewUri(page, filterType);
      setState(() {
        selectedFilter = filterType;
        filteredImageUri = uri;
      });
    } catch (e) {
      print(e);
    }
  }
}
