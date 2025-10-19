import '../../data/models/invoice_model.dart';
import '../repositories/sales_repositores.dart';

class InvoiceModelUsecase {
  final SalesRepository salesRepository;

  InvoiceModelUsecase({required this.salesRepository});

  Future<InvoiceModel> call({required String invoiceId}) async {
    return await salesRepository.getInvoice(invoiceId: invoiceId);
  }
}
