# قائمة Endpoints المطلوبة في الباك اند – DoctorBike

القاعدة: `BASE_URL = http://doctorbike.mj-sall.com/api/`

كل endpoint يضاف بعد الـ base، مثال: `POST BASE_URL + register` = `POST http://doctorbike.mj-sall.com/api/register`

---

## 1. المصادقة (Authentication)
| Endpoint | الوصف |
|----------|--------|
| `POST register` | تسجيل مستخدم جديد |
| `POST send/code` | إرسال كود OTP |
| `POST forgot-password` | طلب إعادة تعيين كلمة المرور |
| `POST reset-password` | تعيين كلمة مرور جديدة |
| `POST verify/code` | التحقق من كود OTP |
| `POST login` | تسجيل الدخول |
| `POST logout` | تسجيل الخروج |
| `POST change/password` | تغيير كلمة المرور |
| `POST update/profile` | تحديث الملف الشخصي |
| `GET me` | بيانات المستخدم الحالي |

---

## 2. لوحة الموظف (Employee Dashboard)
| Endpoint | الوصف |
|----------|--------|
| `GET employee/home/data` | بيانات الصفحة الرئيسية للموظف |
| `POST change/employee/task/to/completed` | إتمام مهمة موظف |
| `POST change/sub/employee/task/to/completed` | إتمام مهمة فرعية |
| `POST employee/add/overtime/order` | طلب إضافي |
| `POST employee/add/loan/order` | طلب قرض |
| `GET employee/orders` | طلبات الموظف (إضافي/قروض) |
| `GET get/attendance/details` | تفاصيل الحضور |

---

## 3. لوحة الإدارة (Admin Dashboard)
| Endpoint | الوصف |
|----------|--------|
| `GET all/logs` | كل السجلات |
| `GET admin/home/page/data` | بيانات الصفحة الرئيسية للإدارة |

---

## 4. الديون (Debts)
| Endpoint | الوصف |
|----------|--------|
| `GET total/debts/we/owe` | إجمالي ما علينا |
| `GET total/debts/owed/to/us` | إجمالي ما لنا |
| `GET get/debts/owed/to/us` | قائمة الديون لنا |
| `GET get/debts/we/owe` | قائمة الديون علينا |
| `GET person/debts` | ديون شخص معين |
| `POST add/debt` | إضافة دين |
| `GET get/debts/reports` | تقارير الديون |

---

## 5. الموظفون (Employees)
| Endpoint | الوصف |
|----------|--------|
| `POST create/employee` | إنشاء موظف |
| `POST add/points/to/employee` | إضافة نقاط |
| `POST minus/points/from/employee` | خصم نقاط |
| `POST pay/employee/salary` | صرف راتب |
| `GET employees` | قائمة الموظفين |
| `GET working/times` | أوقات العمل |
| `GET financial/dues` | المستحقات المالية |
| `GET show/employee/financial/details` | تفاصيل مالية موظف |
| `GET employee/permissions` | صلاحيات الموظفين |
| `POST qr-generation` | توليد QR للموظف |
| `POST edit/employee` | تعديل موظف |
| `POST qr-scan` | مسح QR (حضور) |
| `GET employee/overtime/orders` | طلبات الإضافي |
| `GET employee/loan/orders` | طلبات القروض |
| `POST reject/employee/order` | رفض طلب موظف |
| `POST approve/employee/loan/order` | الموافقة على قرض |
| `POST approve/employee/overtime/order` | الموافقة على إضافي |
| `GET employee/logs` | سجلات الموظف |
| `POST cancel/log` | إلغاء سجل |
| `GET get/employee/financial/data/report` | تقرير مالي للموظف |

---

## 6. مهام الموظفين (Employee Tasks)
| Endpoint | الوصف |
|----------|--------|
| `POST create/employee/task` | إنشاء مهمة |
| `POST edit/employee/task` | تعديل مهمة |
| `GET employee/ongoing/tasks` | المهام الجارية |
| `GET employee/completed/tasks` | المهام المكتملة |
| `GET employee/canceled/tasks` | المهام الملغاة |
| `POST cancel/employee/task` | إلغاء مهمة |
| `POST cancel/employee/task/with/repetition` | إلغاء مهمة متكررة |
| `GET show/employee/task` | تفاصيل مهمة |
| `POST employee/edit/employee/task/images` | تعديل صور المهمة |
| `POST employee/edit/employee/sub/task/images` | تعديل صور المهمة الفرعية |

---

## 7. المهام الخاصة (Special Tasks)
| Endpoint | الوصف |
|----------|--------|
| `POST create/special/task` | إنشاء مهمة خاصة |
| `GET ongoing/special/tasks` | المهام الخاصة الجارية |
| `GET no-date/special/tasks` | مهام بدون تاريخ |
| `GET completed/special/tasks` | المهام المكتملة |
| `POST change/special/task/to/completed` | إتمام مهمة خاصة |
| `GET show/special/task` | تفاصيل مهمة خاصة |
| `POST cancel/special/task` | إلغاء مهمة خاصة |
| `POST cancel/special/task/with/repitition` | إلغاء مهمة متكررة |
| `POST transfer/special/task` | نقل مهمة خاصة |
| `POST change/sub/special/task/to/completed` | إتمام مهمة فرعية خاصة |
| `POST update/special/task` | تحديث مهمة خاصة |

---

## 8. الصناديق (Boxes)
| Endpoint | الوصف |
|----------|--------|
| `POST add/box` | إضافة صندوق |
| `GET get/shown/boxes` | الصناديق الظاهرة |
| `GET get/hidden/boxes` | الصناديق المخفية |
| `GET all/box/logs` | سجلات الصناديق |
| `POST transfer/box/balance` | تحويل رصيد بين صناديق |
| `GET show/box` | تفاصيل صندوق |
| `POST add/box/balance` | إضافة رصيد لصندوق |
| `POST edit/box` | تعديل صندوق |
| `GET box/logs/report` | تقرير سجلات الصندوق |
| `POST delete/box` | حذف صندوق |

---

## 9. الشيكات (Checks)
| Endpoint | الوصف |
|----------|--------|
| `GET general/checks/data/first/page` | بيانات الشيكات (الصفحة الأولى) |
| `POST add/outgoing/check` | إضافة شيك صادر |
| `POST add/incoming/check` | إضافة شيك وارد |
| `POST edit/outgoing/check` | تعديل شيك صادر |
| `POST edit/incoming/check` | تعديل شيك وارد |
| `GET not-cashed/outgoing/checks` | شيكات صادرة غير مقبوضة |
| `GET not-cashed/incoming/checks` | شيكات واردة غير مقبوضة |
| `GET cashed/to/person/outgoing/checks` | شيكات صادرة مقبوضة لشخص |
| `GET cashed/to/person/incoming/checks` | شيكات واردة مقبوضة لشخص |
| `GET archived/outgoing/checks` | شيكات صادرة أرشفة |
| `GET archived/incoming/checks` | شيكات واردة أرشفة |
| `POST cancel/an/outgoing/check` | إلغاء شيك صادر |
| `POST cancel/an/incoming/check` | إلغاء شيك وارد |
| `POST cash/an/outgoing/check/to/person` | صرف شيك صادر لشخص |
| `POST cash/incoming/check/to/person` | صرف شيك وارد لشخص |
| `POST cash/an/outgoing/check` | صرف شيك صادر |
| `POST cash/an/incoming/check` | صرف شيك وارد |
| `POST return/an/outgoing/check` | إرجاع شيك صادر |
| `POST return/an/incoming/check` | إرجاع شيك وارد |
| `GET all/customers` | كل العملاء |
| `GET all/sellers` | كل الموردين |
| `POST cash/incoming/check/to/box` | صرف شيك وارد للصندوق |
| `POST cash/outgoing/check/from/box` | صرف شيك صادر من الصندوق |
| `POST delete/incoming/check` | حذف شيك وارد |
| `POST delete/outgoing/check` | حذف شيك صادر |

---

## 10. المخزون (Stock)
| Endpoint | الوصف |
|----------|--------|
| `GET get/products/list` | قائمة المنتجات |
| `GET get/unarchived/closeouts` | الجرد غير المؤرشف |
| `GET get/all/combinations` | كل التركيبات |
| `GET get/product/details` | تفاصيل منتج |
| `POST archive/closeout` | أرشفة جرد |
| `POST add/product/to/closeouts` | إضافة منتج للجرد |
| `GET get/archived/closeouts` | الجرد المؤرشف |
| `GET get/all/subcategories` | كل الفئات الفرعية |
| `GET get/all/projects` | كل المشاريع |
| `GET search/products/by/name` | بحث منتجات بالاسم |
| `POST add/combination` | إضافة تركيبة |

---

## 11. المبيعات (Sales)
| Endpoint | الوصف |
|----------|--------|
| `GET all/products` | كل المنتجات |
| `GET get/all/categories` | كل التصنيفات |
| `GET get/all/subcategories` | التصنيفات الفرعية |
| `GET get/instant/sale/invoice` | فاتورة بيع فوري |
| `POST create/profit/sale` | إنشاء بيع بربح |
| `GET all/profit/sales` | كل مبيعات الربح |
| `POST create/instant/sale` | إنشاء بيع فوري |
| `GET all/instant/sales` | كل المبيعات الفورية |

---

## 12. الأشخاص/العملاء/الموردين (General Data List)
| Endpoint | الوصف |
|----------|--------|
| `POST create/person` | إنشاء شخص (عميل/مورد) |
| `POST edit/person` | تعديل شخص |
| `GET show/person` | تفاصيل شخص |
| `POST delete/person` | حذف شخص |
| `GET main/page/customers` | عملاء الصفحة الرئيسية |
| `GET main/page/sellers` | موردين الصفحة الرئيسية |
| `GET main/page/incomplete/persons` | أشخاص غير مكتملي البيانات |

---

## 13. الشؤون المالية – الأصول (Assets)
| Endpoint | الوصف |
|----------|--------|
| `POST add/asset` | إضافة أصل |
| `POST edit/asset` | تعديل أصل |
| `POST depreciate/all/assets` | إهلاك كل الأصول |
| `GET show/asset` | تفاصيل أصل |
| `GET get/all/assets` | كل الأصول |
| `GET get/all/asset/logs` | سجلات الأصول |
| `GET get/all/treasuries` | كل الخزائن |
| `GET file/papers` | أوراق الملف |
| `POST delete/asset` | حذف أصل |
| `GET get/all/asset/logs/report` | تقرير سجلات الأصول |
| `POST depreciate/one/asset` | إهلاك أصل واحد |

---

## 14. الشؤون المالية – المصروفات (Expenses)
| Endpoint | الوصف |
|----------|--------|
| `GET get/all/expenses` | كل المصروفات |
| `GET get/all/destructions` | كل التلفيات |
| `POST store/destruction` | تسجيل تلف |
| `POST store/expense` | إضافة مصروف |
| `POST edit/expense` | تعديل مصروف |
| `GET show/expense` | تفاصيل مصروف |

---

## 15. الشؤون المالية – الأوراق والملفات (Papers & Files)
| Endpoint | الوصف |
|----------|--------|
| `GET get/all/papers` | كل الأوراق |
| `GET get/all/pictures` | كل الصور |
| `POST cancel/paper` | إلغاء ورقة |
| `POST delete/picture` | حذف صورة |
| `POST store/picture` | إضافة صورة |
| `POST edit/picture` | تعديل صورة |
| `POST store/paper` | إضافة ورقة |
| `POST edit/paper` | تعديل ورقة |
| `POST store/treasury` | إضافة خزينة |
| `POST store/file-box` | إضافة صندوق ملفات |
| `POST store/file` | إضافة ملف |
| `GET get/all/files` | كل الملفات |
| `POST delete/file` | حذف ملف |
| `POST cancel/file-box` | إلغاء صندوق ملفات |
| `POST cancel/treasury` | إلغاء خزينة |

---

## 16. المشاريع (Projects)
| Endpoint | الوصف |
|----------|--------|
| `GET ongoing/project` | مشاريع جارية |
| `GET completed/project` | مشاريع مكتملة |
| `POST create/project` | إنشاء مشروع |
| `POST edit/project` | تعديل مشروع |
| `GET show/project` | تفاصيل مشروع |
| `POST add/product/to/project` | إضافة منتج لمشروع |
| `POST complete/a/project` | إتمام مشروع |
| `GET project/sales` | مبيعات المشروع |
| `GET get/project/expenses` | مصروفات المشروع |
| `POST add/project/expense` | إضافة مصروف لمشروع |

---

## 17. التقارير والدفع
| Endpoint | الوصف |
|----------|--------|
| `GET get/all/report/information` | كل معلومات التقارير |
| `GET get/reprot/by/type` | تقرير حسب النوع |
| `POST add/transaction` | إضافة حركة (دفع) |

---

## 18. الصيانة (Maintenance)
| Endpoint | الوصف |
|----------|--------|
| `POST add/maintenance` | إضافة صيانة |
| `POST change/maintenance/status` | تغيير حالة الصيانة |
| `GET get/new/maintenances` | صيانات جديدة |
| `GET get/ongoing/maintenances` | صيانات جارية |
| `GET get/ready/maintenances` | صيانات جاهزة |
| `GET get/delivered/maintenances` | صيانات مُسلّمة |
| `GET show/maintenance` | تفاصيل صيانة |

---

## 19. الأهداف (Goals)
| Endpoint | الوصف |
|----------|--------|
| `GET get/all/goals` | كل الأهداف |
| `POST add/goal` | إضافة هدف |
| `POST edit/goal` | تعديل هدف |
| `GET show/goal` | تفاصيل هدف |
| `POST delete/goal` | حذف هدف |
| `POST transfer/goal` | نقل هدف |
| `POST cancel/goal` | إلغاء هدف |

---

## 20. المتابعة (Followups)
| Endpoint | الوصف |
|----------|--------|
| `POST add/followup` | إضافة متابعة |
| `POST update/followup` | تحديث متابعة |
| `GET show/followup` | تفاصيل متابعة |
| `POST followup/store/customer` | حفظ عميل من المتابعة |
| `POST cancel/followup` | إلغاء متابعة |
| `GET get/initial/followups` | متابعات أولية |
| `GET get/inform/person/followups` | متابعات إبلاغ الشخص |
| `GET get/finish/and/agreement/followups` | متابعات انتهاء واتفاق |
| `GET get/archived/followups` | متابعات أرشفة |

---

## 21. الفواتير والمشتريات (Bills / Buying)
| Endpoint | الوصف |
|----------|--------|
| `POST add/bill` | إضافة فاتورة |
| `POST add/quantity/bill` | إضافة كمية للفاتورة |
| `POST add/return/purchase` | إضافة مرتجع مشتريات |
| `GET get/bill/details` | تفاصيل فاتورة |
| `GET bill/report` | تقرير الفواتير |
| `GET unfinished/bills` | فواتير غير منتهية |
| `GET archived/bills` | فواتير أرشفة |
| `GET finished/bills` | فواتير منتهية |
| `GET unmatched/bills` | فواتير غير مطابقة |
| `GET securities/bills` | فواتير ضمانات |
| `GET get/pending/return/purchases` | مرتجعات مشتريات معلقة |
| `GET get/delivered/return/purchases` | مرتجعات مشتريات مُسلّمة |
| `POST cancel/bill` | إلغاء فاتورة |
| `POST change/product/status` | تغيير حالة منتج |
| `POST purchase/new/price` | سعر شراء جديد |
| `POST deliver/one/product` | تسليم منتج واحد |
| `POST purchase/extra/products` | شراء منتجات إضافية |
| `POST change/return/purchase/to/delivered` | تحويل مرتجع لمُسلّم |

---

## 22. تطوير المنتجات (Product Developments)
| Endpoint | الوصف |
|----------|--------|
| `GET get/all/product/developments` | كل تطويرات المنتجات |
| `POST create/product/development` | إنشاء تطوير منتج |
| `POST update/product/development/step` | تحديث مرحلة التطوير |

---

## ملخص العدد
- **المجموع التقريبي:** ~170+ endpoint
- يفضل أن يدعم الباك اند **Bearer token** للمصادقة لجميع الـ endpoints المحمية (ما عدا login, register, forgot-password, send/code, verify/code, reset-password).
- الردود المتوقعة غالباً بصيغة JSON مع حقل مثل `status` و `data` كما في `ApiKey` في التطبيق.
