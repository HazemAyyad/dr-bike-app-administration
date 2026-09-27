String purchaseWorkflowLabel(String status) {
  switch (status.trim().toLowerCase()) {
    case 'draft':
    case 'awaiting_receiving':
      return 'بانتظار الاستلام';
    case 'partially_received':
      return 'استلام جزئي';
    case 'receiving_issues':
      return 'فروقات استلام';
    case 'received':
      return 'مستلمة بانتظار الاعتماد';
    case 'awaiting_finalization':
      return 'بانتظار الاعتماد';
    case 'finalized':
    case 'finished':
      return 'مكتملة';
    case 'cancelled':
      return 'ملغاة';
    case 'unfinished':
      return 'غير مكتملة';
    case '':
      return 'بانتظار الاستلام';
    default:
      return 'حالة غير معروفة';
  }
}

String purchasePaymentStatusLabel(String status) {
  switch (status.trim().toLowerCase()) {
    case 'paid':
      return 'مدفوعة';
    case 'partially_paid':
    case 'partial':
      return 'مدفوعة جزئياً';
    case 'unpaid':
    case '':
      return 'غير مدفوعة';
    default:
      return 'حالة دفع غير معروفة';
  }
}

String purchasePaymentTypeLabel(String type) {
  switch (type.trim().toLowerCase()) {
    case 'initial_payment':
      return 'دفعة أولية';
    case 'payment':
      return 'دفعة على الفاتورة';
    case 'account_payment':
      return 'دفعة على الحساب';
    case 'return_settlement':
      return 'تسوية مرتجع';
    case 'refund':
      return 'استرداد';
    case '':
      return 'دفعة شراء';
    default:
      return 'دفعة شراء';
  }
}

String purchaseReturnStatusLabel(String status) {
  switch (status.trim().toLowerCase()) {
    case 'draft':
      return 'مسودة';
    case 'confirmed':
    case 'pending':
      return 'قيد التسليم';
    case 'delivered':
      return 'قيد التسوية';
    case 'settled':
      return 'مكتمل';
    case 'cancelled':
      return 'ملغى';
    default:
      return 'حالة غير معروفة';
  }
}

String purchaseItemStatusLabel(String status) {
  switch (status.trim().toLowerCase()) {
    case 'finished':
      return 'مستلم';
    case 'unfinished':
      return 'بانتظار الاستلام';
    case 'extra':
      return 'كمية زائدة';
    case 'damaged':
      return 'تالف';
    case 'not_compatible':
    case 'mismatched':
      return 'غير مطابق';
    case 'missing':
      return 'ناقص';
    case '':
      return 'غير محدد';
    default:
      return 'حالة غير معروفة';
  }
}
