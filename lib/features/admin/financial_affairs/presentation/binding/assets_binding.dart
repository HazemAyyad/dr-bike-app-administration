import 'package:doctorbike/features/admin/financial_affairs/data/repositories/financial_affairs_implement.dart';
import 'package:get/get.dart';

import '../../domain/usecases/assets_usecases/add_new_assers_usecase.dart';
import '../../domain/usecases/assets_usecases/assets_detials_usecase.dart';
import '../../domain/usecases/assets_usecases/depreciate_assets_usecase.dart';
import '../../domain/usecases/get_all_dinancial_usecase.dart';
import '../../domain/usecases/assets_usecases/get_assets_logs_usecase.dart';
import '../controllers/assets_controller.dart';
import '../controllers/official_papers_controller.dart';
import '../../domain/usecases/paper_usecase/add_document_usecase.dart';
import '../../domain/usecases/paper_usecase/add_paper_usecase.dart';
import '../../domain/usecases/paper_usecase/add_safe_usecase.dart';
import '../../domain/usecases/paper_usecase/cancel_paper_usecase.dart';
import '../../domain/usecases/paper_usecase/delete_file.dart';
import '../../domain/usecases/paper_usecase/get_file_papers_usecase.dart';

class AssetsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => AssetsController(
        getAllFinancialUsecase: GetAllFinancialUsecase(
          financialAffairsRepository: Get.find<FinancialAffairsImplement>(),
        ),
        getAssetsLogsUsecase: GetAssetsLogsUsecase(
          financialAffairsRepository: Get.find<FinancialAffairsImplement>(),
        ),
        addNewAssetsUsecase: AddNewAssetsUsecase(
          financialAffairsRepository: Get.find<FinancialAffairsImplement>(),
        ),
        depreciateAssetsUsecase: DepreciateAssetsUsecase(
          financialAffairsRepository: Get.find<FinancialAffairsImplement>(),
        ),
        assetsDetialsUsecase: AssetsDetialsUsecase(
          financialAffairsRepository: Get.find<FinancialAffairsImplement>(),
        ),
      ),
    );
    Get.lazyPut(
      () => OfficialPapersController(
        getAllFinancialUsecase: GetAllFinancialUsecase(
          financialAffairsRepository: Get.find<FinancialAffairsImplement>(),
        ),
        cancelPaperUsecase: CancelPaperUsecase(
          financialAffairsRepository: Get.find<FinancialAffairsImplement>(),
        ),
        addPictureUsecase: AddPictureUsecase(
          financialAffairsRepository: Get.find<FinancialAffairsImplement>(),
        ),
        addPaperUsecase: AddPaperUsecase(
          financialAffairsRepository: Get.find<FinancialAffairsImplement>(),
        ),
        addSafeUsecase: AddSafeUsecase(
          financialAffairsRepository: Get.find<FinancialAffairsImplement>(),
        ),
        deleteFileUsecase: DeleteFilesUsecase(
          financialAffairsRepository: Get.find<FinancialAffairsImplement>(),
        ),
        getFilePapersUsecase: GetFilePapersUsecase(
          financialAffairsRepository: Get.find<FinancialAffairsImplement>(),
        ),
      ),
      fenix: true,
    );
  }
}
