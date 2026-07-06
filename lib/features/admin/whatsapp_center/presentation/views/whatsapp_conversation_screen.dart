import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:typed_data';

import '../controllers/whatsapp_conversation_controller.dart';
import '../widgets/whatsapp_media_bubble.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import '../../data/whatsapp_models.dart';
import 'whatsapp_product_picker_screen.dart';
import 'whatsapp_camera_screen.dart';

class WhatsAppConversationScreen
    extends GetView<WhatsAppConversationController> {
  const WhatsAppConversationScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => Directionality(
        textDirection: TextDirection.rtl,
        child: Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF075E54),
                brightness: Theme.of(context).brightness,
              ),
              dialogTheme: const DialogThemeData(
                backgroundColor: Color(0xFFF7FAF9),
                surfaceTintColor: Colors.transparent,
              ),
              bottomSheetTheme: const BottomSheetThemeData(
                backgroundColor: Color(0xFFF7FAF9),
                surfaceTintColor: Colors.transparent,
              ),
            ),
            child: Scaffold(
              appBar: AppBar(
                  title: Obx(() {
                    final c = controller.conversation.value;
                    final name = c?.contact?.name?.isNotEmpty == true
                        ? c!.contact!.name!
                        : c?.phone ?? 'المحادثة';
                    final linked = c?.contact?.customerId != null ||
                        c?.contact?.supplierId != null;
                    return Row(children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          CircleAvatar(
                            radius: 19,
                            backgroundColor: const Color(0xFFF8E7B5),
                            foregroundColor: const Color(0xFF66562E),
                            child: Text(name.characters.first),
                          ),
                          if (linked)
                            const Positioned(
                              left: -3,
                              bottom: -2,
                              child: _LinkedBadge(),
                            ),
                        ],
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600)),
                              if (c != null)
                                Text('حساب واتساب للأعمال • ${c.phone}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 11)),
                            ]),
                      ),
                    ]);
                  }),
                  actions: [
                    Obx(() {
                      final contact = controller.conversation.value?.contact;
                      final linked = contact?.customerId != null ||
                          contact?.supplierId != null;
                      final windowOpen =
                          controller.customerServiceWindowOpen.value;
                      return PopupMenuButton<String>(
                        tooltip: 'خيارات المحادثة',
                        color: const Color(0xFFF7FAF9),
                        surfaceTintColor: Colors.transparent,
                        icon: const Icon(Icons.more_vert),
                        onSelected: (value) {
                          if (value == 'add_person') {
                            _showAddPerson(context);
                          } else if (value == 'share_products') {
                            Get.to(() => const WhatsAppProductPickerScreen());
                          }
                        },
                        itemBuilder: (_) => [
                          PopupMenuItem<String>(
                            value: 'add_person',
                            enabled: !linked,
                            child: Row(
                              children: [
                                Icon(
                                  linked
                                      ? Icons.verified_user_outlined
                                      : Icons.person_add_alt_1,
                                  color: const Color(0xFF075E54),
                                ),
                                const SizedBox(width: 10),
                                Text(linked
                                    ? 'مضاف إلى النظام'
                                    : 'إضافة كزبون أو تاجر'),
                              ],
                            ),
                          ),
                          const PopupMenuDivider(),
                          PopupMenuItem<String>(
                            value: 'share_products',
                            enabled: windowOpen,
                            child: const Row(
                              children: [
                                Icon(Icons.inventory_2_outlined,
                                    color: Color(0xFF075E54)),
                                SizedBox(width: 10),
                                Text('مشاركة منتجات'),
                              ],
                            ),
                          ),
                        ],
                      );
                    }),
                  ]),
              body: CustomPaint(
                painter: _ChatPatternPainter(),
                child: Column(children: [
                  Expanded(child: Obx(() {
                    if (controller.loading.value) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (controller.error.value != null) {
                      return Center(
                          child: Text(controller.error.value!,
                              textAlign: TextAlign.center));
                    }
                    if (controller.messages.isEmpty) {
                      return const Center(child: Text('لا توجد رسائل بعد'));
                    }
                    return RefreshIndicator(
                      onRefresh: controller.load,
                      child: ListView.builder(
                        controller: controller.scrollController,
                        padding: const EdgeInsets.fromLTRB(10, 16, 10, 10),
                        itemCount: controller.messages.length,
                        itemBuilder: (_, index) {
                          final message = controller.messages[index];
                          final outbound = message.direction == 'outbound';
                          return Align(
                            alignment: outbound
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: GestureDetector(
                              onLongPress: () =>
                                  _showMessageActions(context, message),
                              onHorizontalDragEnd: (details) {
                                if ((details.primaryVelocity ?? 0).abs() >
                                    180) {
                                  controller.replyTo(message);
                                }
                              },
                              child: Container(
                                constraints: BoxConstraints(
                                    maxWidth:
                                        MediaQuery.sizeOf(context).width * .78),
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                padding:
                                    const EdgeInsets.fromLTRB(12, 9, 12, 7),
                                decoration: BoxDecoration(
                                  color: outbound
                                      ? const Color(0xFFD9FDD3)
                                      : message.customerDeletedAt != null
                                          ? const Color(0xFFFFE8A3)
                                          : Theme.of(context).cardColor,
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(10),
                                    topRight: const Radius.circular(10),
                                    bottomLeft:
                                        Radius.circular(outbound ? 10 : 2),
                                    bottomRight:
                                        Radius.circular(outbound ? 2 : 10),
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                        color: Color(0x18000000), blurRadius: 4)
                                  ],
                                ),
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (outbound &&
                                          (message.senderName != null ||
                                              message.isAutomatic))
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(bottom: 5),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                message.isAutomatic
                                                    ? Icons.smart_toy_outlined
                                                    : Icons.support_agent,
                                                size: 14,
                                                color: const Color(0xFF008069),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                message.isAutomatic
                                                    ? 'الرد التلقائي'
                                                    : message.senderName!,
                                                style: const TextStyle(
                                                  color: Color(0xFF008069),
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      if (message.replyTo != null)
                                        _ReplyPreview(
                                            message: message.replyTo!),
                                      if (message.mediaUrl != null &&
                                          message.type == 'image')
                                        GestureDetector(
                                          onTap: () =>
                                              controller.showMedia(message),
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            child: FutureBuilder<Uint8List>(
                                              future: controller
                                                  .getMediaBytes(message),
                                              builder: (context, snapshot) {
                                                if (snapshot.hasData) {
                                                  return Image.memory(
                                                    snapshot.data!,
                                                    width: 230,
                                                    height: 180,
                                                    fit: BoxFit.cover,
                                                  );
                                                }
                                                if (snapshot.hasError) {
                                                  return const SizedBox(
                                                    width: 230,
                                                    height: 90,
                                                    child: Center(
                                                        child: Icon(Icons
                                                            .broken_image_outlined)),
                                                  );
                                                }
                                                return const SizedBox(
                                                  width: 230,
                                                  height: 150,
                                                  child: Center(
                                                      child:
                                                          CircularProgressIndicator()),
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                      if (message.mediaUrl != null &&
                                          message.type == 'audio')
                                        WhatsAppAudioBubble(
                                          message: message,
                                          controller: controller,
                                        ),
                                      if (message.mediaUrl != null &&
                                          message.type == 'video')
                                        WhatsAppVideoBubble(
                                          message: message,
                                          controller: controller,
                                        ),
                                      if (message.mediaUrl != null &&
                                          !['image', 'audio', 'video']
                                              .contains(message.type))
                                        InkWell(
                                          onTap: () =>
                                              controller.showMedia(message),
                                          child: Container(
                                            padding: const EdgeInsets.all(10),
                                            margin: const EdgeInsets.only(
                                                bottom: 5),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                  color:
                                                      const Color(0xFFB8CBC6)),
                                            ),
                                            child: const Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(Icons.attach_file,
                                                      color: Color(0xFF075E54)),
                                                  SizedBox(width: 6),
                                                  Text('فتح المرفق'),
                                                ]),
                                          ),
                                        ),
                                      if (_visibleBody(message) != null)
                                        Text(_visibleBody(message)!),
                                      const SizedBox(height: 4),
                                      Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(_time(message.createdAt),
                                                style: const TextStyle(
                                                    fontSize: 10,
                                                    color: Colors.grey)),
                                            if (outbound) ...[
                                              const SizedBox(width: 5),
                                              Icon(_statusIcon(message.status),
                                                  size: 15,
                                                  color: _statusColor(
                                                      message.status)),
                                            ],
                                          ]),
                                      if (message.status == 'failed' &&
                                          message.errorMessage != null)
                                        Text(message.errorMessage!,
                                            style: const TextStyle(
                                                fontSize: 10,
                                                color: Colors.red)),
                                      if (message.customerDeletedAt != null)
                                        const Padding(
                                          padding: EdgeInsets.only(top: 5),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.history,
                                                  size: 14,
                                                  color: Color(0xFF8A5A00)),
                                              SizedBox(width: 4),
                                              Flexible(
                                                child: Text(
                                                  'حذفها الزبون من واتساب — النسخة محفوظة لدينا',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: Color(0xFF8A5A00),
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ]),
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  })),
                  _Composer(controller: controller),
                ]),
              ),
            )),
      );

  Future<void> _showMessageActions(
      BuildContext context, WhatsAppMessage message) async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.reply, color: Color(0xFF008069)),
              title: const Text('رد على الرسالة'),
              onTap: () {
                Navigator.pop(context);
                controller.replyTo(message);
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.delete_outline, color: Color(0xFFD93025)),
              title: const Text('حذف من عرضي'),
              subtitle: const Text('تبقى الرسالة محفوظة ولا تُحذف عند الزبون'),
              onTap: () {
                Navigator.pop(context);
                controller.hideMessage(message);
              },
            ),
            if (message.direction == 'outbound')
              const ListTile(
                enabled: false,
                leading: Icon(Icons.phonelink_erase),
                title: Text('حذف لدى الزبون'),
                subtitle: Text('غير متاح حاليًا عبر WhatsApp Cloud API'),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddPerson(BuildContext context) async {
    final name = TextEditingController(
        text: controller.conversation.value?.contact?.name);
    var type = 'customer';
    await showDialog<void>(
        context: context,
        builder: (_) => StatefulBuilder(
              builder: (context, setState) => AlertDialog(
                title: const Text('إضافة الرقم إلى النظام'),
                content: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(controller.conversation.value?.phone ?? '',
                      textDirection: TextDirection.ltr),
                  TextField(
                      controller: name,
                      decoration: const InputDecoration(labelText: 'الاسم')),
                  const SizedBox(height: 8),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                          value: 'customer',
                          label: Text('زبون'),
                          icon: Icon(Icons.person_outline)),
                      ButtonSegment(
                          value: 'seller',
                          label: Text('تاجر'),
                          icon: Icon(Icons.store_outlined)),
                    ],
                    selected: {type},
                    onSelectionChanged: (value) =>
                        setState(() => type = value.first),
                  ),
                ]),
                actions: [
                  TextButton(onPressed: Get.back, child: const Text('إلغاء')),
                  FilledButton(
                    style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF075E54)),
                    onPressed: () async {
                      if (await controller.addAsPerson(
                          type, name.text.trim())) {
                        Get.back();
                      }
                    },
                    child: const Text('إضافة'),
                  ),
                ],
              ),
            ));
    name.dispose();
  }
}

class _Composer extends StatefulWidget {
  const _Composer({required this.controller});

  final WhatsAppConversationController controller;

  @override
  State<_Composer> createState() => _ComposerState();
}

class _ComposerState extends State<_Composer> {
  bool _emojiVisible = false;
  double? _recordStartX;
  double? _recordStartY;
  bool _cancelBySlide = false;
  final FocusNode _messageFocus = FocusNode();

  WhatsAppConversationController get controller => widget.controller;

  @override
  void dispose() {
    _messageFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Container(
        color: const Color(0xFFF7F8F8),
        child: SafeArea(
          top: false,
          child: Obx(() => Padding(
                padding: const EdgeInsets.fromLTRB(7, 5, 7, 7),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (controller.replyingTo.value != null) _replyBanner(),
                    if (!controller.customerServiceWindowOpen.value)
                      _closedWindowBanner()
                    else ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Container(
                              constraints: const BoxConstraints(minHeight: 50),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(25),
                                border:
                                    Border.all(color: const Color(0x18000000)),
                              ),
                              child: controller.recording.value
                                  ? _recordingBar()
                                  : _messageField(context),
                            ),
                          ),
                          const SizedBox(width: 6),
                          _actionButton(),
                        ],
                      ),
                      if (_emojiVisible && !controller.recording.value)
                        _emojiPanel(),
                    ],
                  ],
                ),
              )),
        ),
      );

  Widget _closedWindowBanner() => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3CD),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFFD76A)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Row(
              children: [
                Icon(Icons.schedule, color: Color(0xFF8A5A00)),
                SizedBox(width: 9),
                Expanded(
                  child: Text(
                    'انتهت نافذة الرد خلال 24 ساعة. أرسل للزبون طلبًا معتمدًا للاستمرار بالمحادثة.',
                    style: TextStyle(
                      color: Color(0xFF6F4A00),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: controller.sending.value
                    ? null
                    : controller.requestContinuation,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF075E54),
                  foregroundColor: Colors.white,
                ),
                icon: controller.sending.value
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.mark_chat_unread_outlined),
                label: const Text('هل تريد الاستمرار مع دكتور بايك؟'),
              ),
            ),
          ],
        ),
      );

  Widget _replyBanner() => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.fromLTRB(10, 5, 4, 5),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5F1),
          borderRadius: BorderRadius.circular(10),
          border: const Border(
            right: BorderSide(color: Color(0xFF00A884), width: 4),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: _ReplyPreview(
                message: controller.replyingTo.value!,
                compact: true,
              ),
            ),
            IconButton(
              onPressed: controller.cancelReply,
              icon: const Icon(Icons.close, size: 20),
            ),
          ],
        ),
      );

  Widget _messageField(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          InkWell(
            onTap: () {
              setState(() => _emojiVisible = !_emojiVisible);
              _emojiVisible
                  ? _messageFocus.unfocus()
                  : _messageFocus.requestFocus();
            },
            borderRadius: BorderRadius.circular(20),
            child: const Padding(
              padding: EdgeInsets.fromLTRB(8, 13, 8, 13),
              child:
                  Icon(Icons.emoji_emotions_outlined, color: Color(0xFF667781)),
            ),
          ),
          Expanded(
            child: TextField(
              controller: controller.input,
              focusNode: _messageFocus,
              minLines: 1,
              maxLines: 5,
              textInputAction: TextInputAction.newline,
              decoration: const InputDecoration(
                hintText: 'رسالة',
                border: InputBorder.none,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 8, vertical: 13),
              ),
            ),
          ),
          IconButton(
            tooltip: 'إرفاق',
            onPressed: () => _attachmentSource(context),
            icon: const Icon(Icons.attach_file, color: Color(0xFF667781)),
          ),
          IconButton(
            tooltip: 'فتح الكاميرا',
            onPressed: () => _cameraSource(context),
            icon:
                const Icon(Icons.camera_alt_outlined, color: Color(0xFF667781)),
          ),
        ],
      );

  Widget _recordingBar() => controller.recordingLocked.value
      ? _lockedRecordingBar()
      : _heldRecordingBar();

  Widget _heldRecordingBar() => SizedBox(
        height: 50,
        child: Row(
          children: [
            const SizedBox(width: 14),
            const Icon(Icons.fiber_manual_record, color: Colors.red, size: 14),
            const SizedBox(width: 5),
            Text(
              _duration(controller.recordingDuration.value),
              textDirection: TextDirection.ltr,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            Expanded(
              child: Text(
                _cancelBySlide ? 'اترك للإلغاء' : '‹ اسحب للإلغاء',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _cancelBySlide ? Colors.red : const Color(0xFF667781),
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      );

  Widget _lockedRecordingBar() => SizedBox(
        height: 50,
        child: Row(
          children: [
            IconButton(
              tooltip: 'حذف التسجيل',
              onPressed: controller.cancelRecording,
              icon: const Icon(Icons.delete_outline, color: Color(0xFF667781)),
            ),
            Text(
              _duration(controller.recordingDuration.value),
              textDirection: TextDirection.ltr,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: AudioWaveforms(
                recorderController: controller.recorder,
                size: const Size(double.infinity, 42),
                waveStyle: const WaveStyle(
                  waveColor: Color(0xFF00A884),
                  showMiddleLine: false,
                  extendWaveform: true,
                  spacing: 5,
                ),
              ),
            ),
            IconButton(
              tooltip: controller.recordingPaused.value
                  ? 'متابعة التسجيل'
                  : 'إيقاف مؤقت',
              onPressed: controller.toggleRecordingPause,
              icon: Icon(
                controller.recordingPaused.value
                    ? Icons.mic
                    : Icons.pause_rounded,
                color: const Color(0xFFFF5368),
                size: 30,
              ),
            ),
          ],
        ),
      );

  Widget _actionButton() {
    if (controller.sending.value) {
      return _circle(
        child: const SizedBox.square(
          dimension: 20,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
        ),
      );
    }
    if (controller.recording.value && controller.recordingLocked.value) {
      return GestureDetector(
        onTap: controller.stopAndSendRecording,
        child: _circle(
          child: const Icon(Icons.send, color: Colors.white, size: 28),
        ),
      );
    }
    if (controller.composing.value) {
      return GestureDetector(
        onTap: controller.send,
        child: _circle(child: const Icon(Icons.send, color: Colors.white)),
      );
    }
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPressStart: (details) async {
        setState(() => _emojiVisible = false);
        _recordStartX = details.globalPosition.dx;
        _recordStartY = details.globalPosition.dy;
        _cancelBySlide = false;
        await controller.startRecording();
      },
      onLongPressMoveUpdate: (details) {
        if (!controller.recording.value || controller.recordingLocked.value) {
          return;
        }
        final startX = _recordStartX;
        final startY = _recordStartY;
        if (startX == null || startY == null) return;
        if (startY - details.globalPosition.dy >= 75) {
          controller.lockRecording();
          return;
        }
        final cancel = (details.globalPosition.dx - startX).abs() >= 90;
        if (cancel != _cancelBySlide) {
          setState(() => _cancelBySlide = cancel);
        }
      },
      onLongPressEnd: (_) async {
        if (!controller.recording.value || controller.recordingLocked.value) {
          return;
        }
        if (_cancelBySlide) {
          await controller.cancelRecording();
        } else {
          await controller.stopAndSendRecording();
        }
        if (mounted) {
          setState(() {
            _recordStartX = null;
            _recordStartY = null;
            _cancelBySlide = false;
          });
        }
      },
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          if (controller.recording.value && !controller.recordingLocked.value)
            Positioned(
              bottom: 58,
              child: Container(
                width: 48,
                height: 105,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [
                    BoxShadow(color: Color(0x33000000), blurRadius: 8),
                  ],
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock_outline, color: Color(0xFF667781)),
                    SizedBox(height: 6),
                    Icon(Icons.keyboard_arrow_up, color: Color(0xFF667781)),
                  ],
                ),
              ),
            ),
          _circle(
            color: controller.recording.value
                ? const Color(0xFF00A884)
                : const Color(0xFF00A884),
            child: const Icon(Icons.mic, color: Colors.white, size: 27),
          ),
        ],
      ),
    );
  }

  Widget _circle(
          {required Widget child, Color color = const Color(0xFF00A884)}) =>
      Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        alignment: Alignment.center,
        child: child,
      );

  Widget _emojiPanel() {
    const emojis = <String>[
      '😀',
      '😂',
      '😍',
      '🥰',
      '😊',
      '😎',
      '🤩',
      '😘',
      '👍',
      '👎',
      '👏',
      '🙏',
      '💪',
      '👌',
      '🤝',
      '👋',
      '❤️',
      '💚',
      '💙',
      '🔥',
      '✨',
      '🎉',
      '✅',
      '❌',
      '🚲',
      '🛵',
      '🔧',
      '🧰',
      '📍',
      '📞',
      '💬',
      '🛒',
    ];
    return Container(
      height: 210,
      margin: const EdgeInsets.only(top: 6),
      color: const Color(0xFFF0F2F5),
      child: GridView.builder(
        padding: const EdgeInsets.all(10),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 8,
        ),
        itemCount: emojis.length,
        itemBuilder: (_, index) => InkWell(
          onTap: () => _insertEmoji(emojis[index]),
          child: Center(
            child: Text(emojis[index], style: const TextStyle(fontSize: 25)),
          ),
        ),
      ),
    );
  }

  void _insertEmoji(String emoji) {
    final value = controller.input.value;
    final start =
        value.selection.start < 0 ? value.text.length : value.selection.start;
    final end =
        value.selection.end < 0 ? value.text.length : value.selection.end;
    controller.input.value = value.copyWith(
      text: value.text.replaceRange(start, end, emoji),
      selection: TextSelection.collapsed(offset: start + emoji.length),
      composing: TextRange.empty,
    );
  }

  Future<void> _cameraSource(BuildContext context) async {
    final capture =
        await Get.to<WhatsAppCapture>(() => const WhatsAppCameraScreen());
    if (capture != null) {
      await controller.sendCapturedMedia(capture.path, capture.mediaKind);
    }
  }

  Future<void> _attachmentSource(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading:
                  const Icon(Icons.photo_library, color: Color(0xFF00A884)),
              title: const Text('صورة من المعرض'),
              onTap: () {
                Navigator.pop(context);
                controller.pickAndSendImage(fromCamera: false);
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.video_library, color: Color(0xFF00A884)),
              title: const Text('فيديو من المعرض'),
              onTap: () {
                Navigator.pop(context);
                controller.pickAndSendVideo(fromCamera: false);
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.insert_drive_file, color: Color(0xFF00A884)),
              title: const Text('مستند أو ملف صوتي'),
              onTap: () {
                Navigator.pop(context);
                controller.pickAndSendAttachment();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatPatternPainter extends CustomPainter {
  final Paint _paint = Paint()
    ..color = const Color(0x0C5F6F68)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.2;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawColor(const Color(0xFFEFEAE2), BlendMode.src);
    const cell = 86.0;
    for (double y = 18; y < size.height; y += cell) {
      for (double x = 18; x < size.width; x += cell) {
        final offset = ((y / cell).round().isEven) ? 0.0 : cell / 2;
        final center = Offset(x + offset, y);
        canvas.drawCircle(center, 10, _paint);
        canvas.drawLine(
            center.translate(-15, 18), center.translate(15, 18), _paint);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: center.translate(20, 38), width: 18, height: 13),
            const Radius.circular(3),
          ),
          _paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LinkedBadge extends StatelessWidget {
  const _LinkedBadge();

  @override
  Widget build(BuildContext context) => Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          color: const Color(0xFF1D9BF0),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: const Icon(Icons.check, color: Colors.white, size: 11),
      );
}

class _ReplyPreview extends StatelessWidget {
  const _ReplyPreview({required this.message, this.compact = false});

  final WhatsAppMessage message;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final text = _visibleBody(message) ?? _mediaLabel(message.type);
    return Container(
      width: double.infinity,
      margin: compact ? EdgeInsets.zero : const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0x1200A884),
        borderRadius: BorderRadius.circular(7),
        border: const Border(
          right: BorderSide(color: Color(0xFF00A884), width: 3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message.direction == 'outbound' ? 'أنت' : 'الزبون',
            style: const TextStyle(
              color: Color(0xFF008069),
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
          Text(
            text,
            maxLines: compact ? 1 : 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: Color(0xFF52635F)),
          ),
        ],
      ),
    );
  }
}

String? _visibleBody(WhatsAppMessage message) {
  final body = message.body?.trim();
  if (body == null || body.isEmpty) return null;
  if (['image', 'audio', 'video'].contains(message.type)) {
    final normalized = body.toLowerCase();
    if (normalized == '[${message.type}]') return null;
    if (RegExp(r'\.(jpg|jpeg|png|webp|m4a|mp4|aac|ogg|wav|mp3|mov)$')
        .hasMatch(normalized)) {
      return null;
    }
  }
  return body;
}

String _mediaLabel(String type) =>
    const {
      'image': '📷 صورة',
      'audio': '🎤 رسالة صوتية',
      'video': '🎬 فيديو',
      'document': '📎 مستند',
      'interactive': '🛍️ منتجات',
    }[type] ??
    'رسالة';

IconData _statusIcon(String status) {
  if (status == 'read' || status == 'delivered') return Icons.done_all;
  if (status == 'sent') return Icons.done;
  if (status == 'failed') return Icons.error_outline;
  return Icons.schedule;
}

Color _statusColor(String status) {
  if (status == 'read') return const Color(0xFF53BDEB);
  if (status == 'failed') return Colors.red;
  return const Color(0xFF667781);
}

String _duration(Duration value) {
  final minutes = value.inMinutes.toString().padLeft(2, '0');
  final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}

String _time(DateTime? date) {
  if (date == null) return '';
  final d = date.toLocal();
  return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}
