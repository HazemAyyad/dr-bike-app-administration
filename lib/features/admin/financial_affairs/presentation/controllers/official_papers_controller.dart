import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/models/official_papers_models/files_model.dart';
import '../../data/models/official_papers_models/papers_model.dart';
import '../../data/models/official_papers_models/pictures_model.dart';
import '../../domain/usecases/get_all_dinancial_usecase.dart';
import '../../domain/usecases/paper_usecase/add_document_usecase.dart';
import '../../domain/usecases/paper_usecase/add_paper_usecase.dart';
import '../../domain/usecases/paper_usecase/cancel_paper_usecase.dart';
import 'finacial_service.dart';

class OfficialPapersController extends GetxController
    with GetTickerProviderStateMixin {
  final GetAllFinancialUsecase getAllFinancialUsecase;
  final CancelPaperUsecase cancelPaperUsecase;
  final AddPaperUsecase addPaperUsecase;
  final AddPictureUsecase addPictureUsecase;

  OfficialPapersController({
    required this.getAllFinancialUsecase,
    required this.cancelPaperUsecase,
    required this.addPictureUsecase,
    required this.addPaperUsecase,
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
  List<File> pictureFiles = [];

  final RxInt currentTab = 0.obs;
  final tabs = ['company_documents', 'important_images'].obs;

  void changeTab(int index) {
    currentTab.value = index;
    update();
  }

  List<PaperModel> papersSearch = [];

  List<PictureModel> picturesSearch = [];

  void searchBar(String value) {
    if (value.isNotEmpty) {
      papersSearch = FinacialService()
          .papers
          .where(
            (element) => element.paperName.toLowerCase().contains(
                  value.toLowerCase(),
                ),
          )
          .toList();
      picturesSearch = FinacialService()
          .pictures
          .where(
            (element) => element.name.toLowerCase().contains(
                  value.toLowerCase(),
                ),
          )
          .toList();
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
    FinacialService().files.assignAll(filesList);
    // filesSearch = FinacialService().files;

    isLoading(false);
    update();
  }

  // add picture
  void addPicture() async {
    isLoading(true);
    if (formKey.currentState!.validate()) {
      final result = await addPictureUsecase.call(
        name: pictureNameController.text,
        description: pictureDescriptionController.text,
        media: pictureFiles,
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
          pictureFiles.clear();
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
    }
    isLoading(false);
    update();
  }

  // add document
  void addPaper({
    required String fileId,
  }) async {
    isLoading(true);
    if (formKey.currentState!.validate()) {
      final result = await addPaperUsecase.call(
        name: paperNameController.text,
        fileId: fileId,
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
  void cancelPaper({required String paperId}) async {
    isLoading(true);
    if (formKey.currentState!.validate()) {
      final result = await cancelPaperUsecase.call(paperId: paperId);

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
          Future.delayed(
            const Duration(milliseconds: 500),
            () {
              Get.snackbar(
                'success'.tr,
                success,
                snackPosition: SnackPosition.BOTTOM,
                duration: const Duration(milliseconds: 1500),
              );
            },
          );
        },
      );
    }
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
    pictureFiles.clear();
    notesController.dispose();
    animController.dispose();
    opacityAnimation.isDismissed;
    sizeAnimation.isDismissed;
    super.onClose();
  }
}
