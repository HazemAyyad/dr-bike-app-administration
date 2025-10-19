import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/models/official_papers_models/papers_model.dart';
import '../../data/models/official_papers_models/pictures_model.dart';
import '../../data/models/official_papers_models/safes_model.dart';
import '../../domain/usecases/get_all_dinancial_usecase.dart';
import '../../domain/usecases/paper_usecase/add_document_usecase.dart';
import '../../domain/usecases/paper_usecase/add_paper_usecase.dart';
import '../../domain/usecases/paper_usecase/add_safe_usecase.dart';
import '../../domain/usecases/paper_usecase/cancel_paper_usecase.dart';
import '../../domain/usecases/paper_usecase/delete_file.dart';
import '../../domain/usecases/paper_usecase/get_file_papers_usecase.dart';
import 'assets_controller.dart';
import 'finacial_service.dart';

class OfficialPapersController extends GetxController
    with GetTickerProviderStateMixin {
  final GetAllFinancialUsecase getAllFinancialUsecase;
  final CancelPaperUsecase cancelPaperUsecase;
  final AddPaperUsecase addPaperUsecase;
  final AddPictureUsecase addPictureUsecase;
  final AddSafeUsecase addSafeUsecase;
  final DeleteFilesUsecase deleteFileUsecase;
  final GetFilePapersUsecase getFilePapersUsecase;

  OfficialPapersController({
    required this.getAllFinancialUsecase,
    required this.cancelPaperUsecase,
    required this.addPictureUsecase,
    required this.addPaperUsecase,
    required this.addSafeUsecase,
    required this.deleteFileUsecase,
    required this.getFilePapersUsecase,
  });

  final formKey = GlobalKey<FormState>();

  // add document
  final paperNameController = TextEditingController();
  final fileController = TextEditingController();
  List<File> paperFiles = [];
  final notesController = TextEditingController();

  // add picture
  final pictureNameController = TextEditingController();
  final pictureDescriptionController = TextEditingController();
  // List<File> pictureFiles = [];
  Rx<XFile?> selectedFile = Rx<XFile?>(null);

  final TextEditingController safeNameController = TextEditingController();

  final RxInt currentTab = 0.obs;
  final tabs = ['company_documents', 'important_images'].obs;

  void changeTab(int index) {
    currentTab.value = index;
    update();
  }

  List<PaperModel> papersSearch = [];

  List<PictureModel> picturesSearch = [];

  bool isEdit = false;
  // List<File> editPaperFiles = [];
  String paperId = '';
  void getPaperData({PaperModel? paper}) {
    if (isEdit) {
      paperNameController.text = paper!.paperName;
      fileController.text = FinacialService()
          .filesData
          .firstWhere(
            (e) => e.name == paper.fileName,
            orElse: () => FinacialService().filesData.first,
          )
          .id
          .toString();
      paperFiles = paper.img.map((e) => File(e)).toList();
      notesController.text = paper.note;
      paperId = paper.paperId.toString();
    } else {
      paperNameController.clear();
      fileController.clear();
      paperFiles.clear();
      notesController.clear();
      paperId = '';
    }
  }

  String pictureId = '';
  void getPictureData({PictureModel? picture}) {
    if (isEdit) {
      pictureNameController.text = picture!.name;
      selectedFile.value = XFile(picture.file);
      pictureDescriptionController.text = picture.description;
      pictureId = picture.id.toString();
    } else {
      pictureNameController.clear();
      selectedFile.value = null;
      pictureDescriptionController.clear();
      pictureId = '';
    }
  }

  void searchBar(String value) {
    if (value.isNotEmpty) {
      final papers = FinacialService().papers;
      final pictures = FinacialService().pictures;
      final search = value.toLowerCase();

      papersSearch = papers.where((element) {
        return element.paperName.toLowerCase().contains(search) ||
            element.treasuryName.toLowerCase().contains(search) ||
            element.fileBoxName.toLowerCase().contains(search) ||
            element.fileName.toLowerCase().contains(search) ||
            element.createdAt.toString().toLowerCase().contains(search);
      }).toList();

      picturesSearch = pictures.where((element) {
        return element.name.toLowerCase().contains(search) ||
            element.createdAt.toString().toLowerCase().contains(search);
      }).toList();
    } else {
      papersSearch = FinacialService().papers;
      picturesSearch = FinacialService().pictures;
    }

    update();
  }

  final RxBool isAddMenuOpen = false.obs;

  void toggleAddMenu() {
    isAddMenuOpen.value = !isAddMenuOpen.value;
  }

  late AnimationController animController;
  late Animation<double> opacityAnimation;
  late Animation<double> sizeAnimation;

  RxBool isLoading = false.obs;
  void getAllExpenses() async {
    FinacialService().papers.isEmpty ? isLoading(true) : isLoading(false);
    update();
    // papers
    final papers = await getAllFinancialUsecase.call(page: '4');
    final papersJson = papers['papers'] as List;
    final papersList = papersJson
        .map((e) => PaperModel.fromJson(e as Map<String, dynamic>))
        .toList();
    FinacialService().papers.assignAll(papersList);
    papersSearch = FinacialService().papers;

    // pictures
    final pictures = await getAllFinancialUsecase.call(page: '5');
    final picturesJson = pictures['pictures'] as List;
    final picturesList = picturesJson
        .map((e) => PictureModel.fromJson(e as Map<String, dynamic>))
        .toList();
    FinacialService().pictures.assignAll(picturesList);
    picturesSearch = FinacialService().pictures;

    // files
    final files = await getAllFinancialUsecase.call(page: '6');
    final filesJson = files['files'] as List;
    final filesList = filesJson
        .map((e) => FilesModel.fromJson(e as Map<String, dynamic>))
        .toList();
    FinacialService().filesData.assignAll(filesList);
    // filesSearch = FinacialService().files;
    isLoading(false);
    update();
  }

  RxBool isFilesLoading = false.obs;
  // get safes
  void getTreasury() async {
    isFilesLoading(true);
    final safes = await getAllFinancialUsecase.call(page: '7');
    final safesJson = safes['treasuries'] as List;
    final safesList = safesJson
        .map((e) => SafesModel.fromJson(e as Map<String, dynamic>))
        .toList();
    FinacialService().safes.assignAll(safesList);

    isFilesLoading(false);
    update();
  }

  // get file Data
  void getFileData({required String fileId}) async {
    isLoading(true);
    final filePapers = await getFilePapersUsecase.call(fileId: fileId);
    FinacialService().filesPapers.assignAll(filePapers);
    isLoading(false);
    update();
  }

  // add picture
  void addPicture() async {
    isLoading(true);
    if (formKey.currentState!.validate()) {
      final result = await addPictureUsecase.call(
        pictureId: pictureId,
        name: pictureNameController.text,
        description: pictureDescriptionController.text,
        media: [selectedFile.value],
      );

      result.fold(
        (failure) {
          Get.back();
          Get.snackbar(
            failure.errMessage,
            failure.data['message'],
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(milliseconds: 1500),
          );
        },
        (success) async {
          pictureNameController.clear();
          pictureDescriptionController.clear();
          selectedFile.value = null;
          getAllExpenses();
          if (isEdit) {
            Get.back();
          }
          Get.back();
          Get.snackbar(
            'success'.tr,
            success,
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(milliseconds: 1500),
          );
        },
      );
    }
    isLoading(false);
    update();
  }

  // add document
  void addPaper() async {
    isLoading(true);
    if (formKey.currentState!.validate()) {
      final result = await addPaperUsecase.call(
        paperId: paperId,
        name: paperNameController.text,
        fileId: fileController.text,
        media: paperFiles,
        notes: notesController.text,
      );

      result.fold(
        (failure) {
          Get.back();
          Get.snackbar(
            failure.errMessage,
            failure.data['message'],
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(milliseconds: 1500),
          );
        },
        (success) async {
          paperNameController.clear();
          fileController.clear();
          paperFiles.clear();
          notesController.clear();
          getAllExpenses();
          if (isEdit) {
            Get.back();
          }
          Get.back();
          Get.snackbar(
            'success'.tr,
            success,
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(milliseconds: 1500),
          );
        },
      );
    }
    isLoading(false);
    update();
  }

  // cancel paper
  void cancelPaper({required String paperId, bool? isPicture = false}) async {
    isLoading(true);
    final result =
        await cancelPaperUsecase.call(paperId: paperId, isPicture: isPicture);

    result.fold(
      (failure) {
        Get.back();
        Get.snackbar(
          failure.errMessage,
          failure.data['message'],
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(milliseconds: 1500),
        );
      },
      (success) async {
        getAllExpenses();
        Get.back();
        Get.snackbar(
          'success'.tr,
          success,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(milliseconds: 1500),
        );
      },
    );

    isLoading(false);
    update();
  }

  // add safe
  void addSafe({String? fileBoxId, String? treasuryId}) async {
    isLoading(true);
    if (formKey.currentState!.validate()) {
      final result = await addSafeUsecase.call(
        name: safeNameController.text,
        fileBoxId: fileBoxId ?? '',
        treasuryId: treasuryId ?? '',
      );

      result.fold(
        (failure) {
          Get.back();
          Get.snackbar(
            failure.errMessage,
            failure.data['message'],
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(milliseconds: 1500),
          );
        },
        (success) async {
          safeNameController.clear();

          Get.back();
          getTreasury();
          Get.snackbar(
            'success'.tr,
            success,
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(milliseconds: 1500),
          );
        },
      );
    }
    isLoading(false);
    update();
  }

  // delete File
  void deleteFiles({
    String? fileId,
    String? fileBoxId,
    String? treasuryId,
    String? assetId,
  }) async {
    isLoading(true);
    final result = await deleteFileUsecase.call(
      fileId: fileId,
      treasuryId: treasuryId,
      fileBoxId: fileBoxId,
      assetId: assetId,
    );

    result.fold(
      (failure) {
        Get.back();
        Get.snackbar(
          failure.errMessage,
          failure.data['message'],
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(milliseconds: 1500),
        );
      },
      (success) async {
        Get.back();
        Future.delayed(const Duration(milliseconds: 10), () {
          if (assetId != null) {
            Get.find<AssetsController>().getAllAssets();
          }
          getTreasury();
        });
        Get.snackbar(
          'success'.tr,
          success,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(milliseconds: 1500),
        );
      },
    );
    isLoading(false);
    update();
  }

  @override
  void onInit() {
    getAllExpenses();
    papersSearch = FinacialService().papers;
    picturesSearch = FinacialService().pictures;

    animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    opacityAnimation = Tween<double>(begin: 0, end: 1).animate(animController);
    sizeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: animController, curve: Curves.fastOutSlowIn),
    );

    ever(isAddMenuOpen, (bool open) {
      if (open) {
        animController.forward();
      } else {
        animController.reverse();
      }
    });
    super.onInit();
  }

  @override
  void onClose() {
    paperNameController.dispose();
    fileController.dispose();
    paperFiles.clear();
    pictureNameController.dispose();
    pictureDescriptionController.dispose();
    selectedFile.value = null;
    notesController.dispose();
    animController.dispose();
    opacityAnimation.isDismissed;
    sizeAnimation.isDismissed;
    super.onClose();
  }
}
