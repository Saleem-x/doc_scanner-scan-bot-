import 'dart:io';

import 'package:doc_scan/pages_repository.dart';
import 'package:doc_scan/utils/filter_all_pages_widget.dart';
import 'package:doc_scan/utils/progress_dialog.dart';
import 'package:doc_scan/utils/utils.dart';
import 'package:doc_scan/views/docview/pagesoperations.dart';
import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:image_picker/image_picker.dart';
import 'package:scanbot_sdk/scanbot_sdk.dart' as sdk;
import 'package:scanbot_sdk/scanbot_sdk.dart';
import 'package:share_plus/share_plus.dart';

bool shouldInitWithEncryption = false;

class DocumentViewScreen extends StatefulWidget {
  const DocumentViewScreen({super.key});

  @override
  State<DocumentViewScreen> createState() => _DocumentViewScreenState();
}

class _DocumentViewScreenState extends State<DocumentViewScreen> {
  final PageRepository _pageRepository = PageRepository();
  late List<sdk.Page> _pages;

  @override
  void initState() {
    _pages = _pageRepository.pages;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Preview'),
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
              child: GridView.builder(
                  scrollDirection: Axis.vertical,
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 200,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10),
                  itemBuilder: (context, position) {
                    return GridTile(
                      child: GestureDetector(
                        onTap: () {
                          _showOperationsPage(_pages[position]);
                        },
                        child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Image.memory(
                              getimagememory(
                                _pages[position].documentPreviewImageFileUri!,
                              ),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  itemCount: _pages.length),
            ),
          ),
          BottomAppBar(
            child: Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                TextButton(
                  onPressed: () {
                    _addPageModalBottomSheet(context);
                  },
                  child: Row(
                    children: <Widget>[
                      const Icon(Icons.add_circle),
                      Container(width: 4),
                      const Text(
                        'Add',
                        style: TextStyle(
                          inherit: true,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {
                    settingModalBottomSheet(context);
                  },
                  child: Row(
                    children: <Widget>[
                      const Icon(Icons.more_vert),
                      Container(width: 4),
                      const Text(
                        'More',
                        style: TextStyle(
                          inherit: true,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Widget text = const SimpleDialogOption(
                      child: Text(
                          'Delete all images and generated files (PDF, TIFF, etc)?'),
                    );

                    // set up the SimpleDialog
                    final dialog = AlertDialog(
                      title: const Text('Delete all'),
                      content: text,
                      contentPadding: const EdgeInsets.all(0),
                      actions: <Widget>[
                        TextButton(
                          onPressed: () async {
                            try {
                              await ScanbotSdk.cleanupStorage();
                              await _pageRepository.clearPages();
                              _updatePagesList();
                            } catch (e) {
                              print(e);
                            }
                            // ignore: use_build_context_synchronously
                            Navigator.of(context).pop();
                          },
                          child: const Text('OK'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: const Text('CANCEL'),
                        ),
                      ],
                    );

                    // show the dialog
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return dialog;
                      },
                    );
                  },
                  child: Row(
                    children: <Widget>[
                      const Icon(
                        Icons.delete,
                        color: Colors.red,
                      ),
                      Container(width: 4),
                      const Text(
                        'Delete All',
                        style: TextStyle(
                          inherit: true,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _addPageModalBottomSheet(context) {
    showModalBottomSheet(
        context: context,
        builder: (BuildContext bc) {
          return Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.scanner),
                title: const Text('Scan Page'),
                onTap: () {
                  Navigator.pop(context);
                  _startDocumentScanning();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_size_select_actual),
                title: const Text('Import Page'),
                onTap: () {
                  Navigator.pop(context);
                  _importImage();
                },
              ),
              ListTile(
                leading: const Icon(Icons.close),
                title: const Text('Cancel'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          );
        });
  }

  Future<void> _startDocumentScanning() async {
    if (!await checkLicenseStatus(context as BuildContext)) {
      return;
    }

    DocumentScanningResult? result;
    try {
      var config = DocumentScannerConfiguration(
        orientationLockMode: sdk.OrientationLockMode.PORTRAIT,
        cameraPreviewMode: CameraPreviewMode.FIT_IN,
        ignoreBadAspectRatio: true,
        multiPageEnabled: false,
        multiPageButtonHidden: true,
      );
      result = await ScanbotSdkUi.startDocumentScanner(config);
    } catch (e) {
      print(e);
    }
    if (result != null) {
      if (isOperationSuccessful(result)) {
        await _pageRepository.addPages(result.pages);
        _updatePagesList();
      }
    }
  }

  void _updatePagesList() {
    setState(() {
      _pages = _pageRepository.pages;
    });
  }

  Future<void> _createPdf() async {
    if (!await _checkHasPages(context)) {
      return;
    }
    // ignore: use_build_context_synchronously
    if (!await checkLicenseStatus(context)) {
      return;
    }

    // ignore: use_build_context_synchronously
    final dialog = ProgressDialog(context,
        type: ProgressDialogType.Normal, isDismissible: false);
    dialog.style(message: 'Creating PDF ...');
    try {
      dialog.show();
      var options = const PdfRenderingOptions(pageSize: PageSize.A4);
      final pdfFileUri =
          await ScanbotSdk.createPdf(_pageRepository.pages, options);
      await dialog.hide();

      await Share.shareXFiles([XFile(pdfFileUri.path)]);
      /*  await showAlertDialog(context, pdfFileUri.toString(),
          title: 'PDF file URI'); */
    } catch (e) {
      print(e);
      await dialog.hide();
    }
  }

  Future<bool> _checkHasPages(BuildContext context) async {
    if (_pages.isNotEmpty) {
      return true;
    }
    await showAlertDialog(context,
        'Please scan or import some documents to perform this function.',
        title: 'Info');
    return false;
  }

  void settingModalBottomSheet(context) {
    showModalBottomSheet(
        context: context,
        builder: (BuildContext bc) {
          return Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.text_fields),
                title: const Text('Perform OCR'),
                onTap: () {
                  Navigator.pop(context);
                  // _performOcr();
                },
              ),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf),
                title: const Text('Save as PDF'),
                onTap: () {
                  Navigator.pop(context);
                  _createPdf();
                },
              ),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf),
                title: const Text('Save as PDF with OCR'),
                onTap: () {
                  Navigator.pop(context);
                  // _createOcrPdf();
                },
              ),
              ListTile(
                leading: const Icon(Icons.image),
                title: const Text('Save as TIFF'),
                onTap: () {
                  Navigator.pop(context);
                  // _createTiff(false);
                },
              ),
              ListTile(
                leading: const Icon(Icons.image),
                title: const Text('Save as TIFF 1-bit encoded'),
                onTap: () {
                  Navigator.pop(context);
                  // _createTiff(true);
                },
              ),
              ListTile(
                leading: const Icon(Icons.image),
                title: const Text('Apply Image Filter on ALL pages'),
                onTap: () {
                  Navigator.pop(context);
                  filterAllPages();
                  setState(() {});
                },
              ),
              ListTile(
                leading: const Icon(Icons.close),
                title: const Text('Cancel'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          );
        });
  }

  Future<void> _importImage() async {
    try {
      final image = await ImagePicker().pickImage(source: ImageSource.gallery);
      await _createPage(Uri.file(image?.path ?? ''));
    } catch (e) {
      print(e);
    }
  }

  Future<void> _createPage(Uri uri) async {
    if (!await checkLicenseStatus(context)) {
      return;
    }

    // ignore: use_build_context_synchronously
    var dialog = ProgressDialog(context,
        type: ProgressDialogType.Normal, isDismissible: true);
    dialog.style(message: 'Processing ...');
    dialog.show();
    try {
      var page = await ScanbotSdk.createPage(uri, false);
      page = await ScanbotSdk.detectDocument(page);
      await dialog.hide();
      await _pageRepository.addPage(page);
      _updatePagesList();
    } catch (e) {
      print(e);
      await dialog.hide();
    }
  }

  Future<void> filterAllPages() async {
    if (!await _checkHasPages(context)) {
      return;
    }
    // ignore: use_build_context_synchronously
    if (!await checkLicenseStatus(context)) {
      return;
    }

    // ignore: use_build_context_synchronously
    await Navigator.of(context).push(
      MaterialPageRoute(
          builder: (context) => MultiPageFiltering(_pageRepository)),
    );
  }

  Future<void> _showOperationsPage(sdk.Page page) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
          builder: (context) => PageOperationsScreen(
                page: page,
              )),
    );
    _updatePagesList();
  }

  getimagememory(Uri uri) {
    var file = File.fromUri(uri);

    var memory = file.readAsBytesSync();

    return memory;
  }
}
