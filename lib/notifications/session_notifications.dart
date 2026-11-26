import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:material_ui/material_ui.dart';
import 'package:timezone/timezone.dart' as tz;

import '../data/local_store.dart';
import '../models/run_session.dart';
import '../state/app_state.dart';
import '../theme/palette.dart';
import 'mission_notice.dart';

const _ongoingId = 1;
const _actionDone = 'done';
const _actionPlus5 = 'plus5';

/// Buttons pressed while the app's Dart code is not running get queued;
/// the app applies them when it is back (see [SessionNotifications]).
@pragma('vm:entry-point')
Future<void> onNotificationActionInBackground(NotificationResponse r) async {
  final id = r.actionId;
  if (id != _actionDone && id != _actionPlus5) return;
  WidgetsFlutterBinding.ensureInitialized();
  await LocalStore.queueAction(
    QueuedAction(id!, r.payload ?? '', DateTime.now()),
  );
}

/// Android notifications for a running mission:
///
/// * an ongoing notification with the block name, a countdown, a progress
///   bar and Gotowe / +5 buttons, kept up to date while the app is in the
///   background (a foreground service keeps the app alive for that);
/// * heads-up reminders 2 minutes before a block ends and when it ends,
///   scheduled as alarms so they fire even if the app was closed. They are
///   only armed while the app is in the background; in the app the
///   countdown screen plays its own sounds.
class SessionNotifications with WidgetsBindingObserver {
  SessionNotifications(this.app, this.store);

  final AppState app;
  final LocalStore store;
  final _plugin = FlutterLocalNotificationsPlugin();
  AndroidFlutterLocalNotificationsPlugin? _android;
  Timer? _timer;
  bool _inBackground = false;
  bool _running = false;
  bool _askedPermission = false;
  bool _serviceStarted = false;
  String _scheduledFor = '';

  Future<void> start() async {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    _android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
      onDidReceiveNotificationResponse: _onResponse,
      onDidReceiveBackgroundNotificationResponse:
          onNotificationActionInBackground,
    );
    WidgetsBinding.instance.addObserver(this);
    app.addListener(_sync);
    await _drainQueue();
    _sync();
  }

  void _onResponse(NotificationResponse r) {
    final id = r.actionId;
    if (id == _actionDone || id == _actionPlus5) {
      app.applyNotificationAction(
        QueuedAction(id!, r.payload ?? '', DateTime.now()),
      );
    }
  }

  Future<void> _drainQueue() async {
    for (final a in await store.takeQueuedActions()) {
      app.applyNotificationAction(a);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _inBackground = state != AppLifecycleState.resumed;
    _scheduledFor = '';
    if (!_inBackground) unawaited(_drainQueue());
    _sync();
  }

  /// Called on every state change and every few seconds while a mission
  /// runs.
  void _sync() {
    final s = app.session;
    if (s == null || s.finished) {
      if (_running) unawaited(_stop());
      return;
    }
    if (!_running) {
      _running = true;
      unawaited(_askPermissionOnce());
      _timer = Timer.periodic(const Duration(seconds: 10), (_) async {
        await _drainQueue();
        _sync();
      });
    }
    unawaited(_showOngoing(s));
    unawaited(_schedulePrompts(s));
  }

  Future<void> _askPermissionOnce() async {
    if (_askedPermission) return;
    _askedPermission = true;
    await _android?.requestNotificationsPermission();
  }

  Future<void> _showOngoing(RunSession s) async {
    final n = missionNotice(s, app.now());
    final details = AndroidNotificationDetails(
      'mission_progress',
      'Misja w toku',
      channelDescription: 'Pasek postępu i licznik bieżącego etapu.',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      onlyAlertOnce: true,
      playSound: false,
      enableVibration: false,
      showProgress: true,
      maxProgress: MissionNotice.maxProgress,
      progress: n.progress,
      usesChronometer: true,
      chronometerCountDown: true,
      when: n.endsAt.millisecondsSinceEpoch,
      showWhen: true,
      color: n.over ? Palette.rose : Palette.teal,
      category: AndroidNotificationCategory.progress,
      visibility: NotificationVisibility.public,
      styleInformation: BigTextStyleInformation(n.body),
      actions: _actions(n.allowPlusFive),
    );
    if (_serviceStarted) {
      // Same id: updates the service's notification in place.
      await _plugin.show(
        id: _ongoingId,
        title: n.title,
        body: n.body,
        notificationDetails: NotificationDetails(android: details),
        payload: n.payload,
      );
      return;
    }
    try {
      // Started while the app is in front (mission start), so Android 12+
      // allows it; later updates only refresh the notification.
      _serviceStarted = true;
      await _android?.startForegroundService(
        id: _ongoingId,
        title: n.title,
        body: n.body,
        notificationDetails: details,
        payload: n.payload,
        foregroundServiceTypes: {
          AndroidServiceForegroundType.foregroundServiceTypeSpecialUse,
        },
      );
    } catch (_) {
      // Without the service (e.g. not allowed right now) a plain ongoing
      // notification still shows the progress.
      await _plugin.show(
        id: _ongoingId,
        title: n.title,
        body: n.body,
        notificationDetails: NotificationDetails(android: details),
        payload: n.payload,
      );
    }
  }

  List<AndroidNotificationAction> _actions(bool plusFive) => [
    const AndroidNotificationAction(
      _actionDone,
      'Gotowe',
      cancelNotification: false,
    ),
    if (plusFive)
      const AndroidNotificationAction(
        _actionPlus5,
        '+5 min',
        cancelNotification: false,
      ),
  ];

  Future<void> _schedulePrompts(RunSession s) async {
    // Re-plan only when the block, its length or foreground/background
    // changes, not on every tick.
    final key = '${stepPayload(s)}:${s.allowedMinutes}:$_inBackground';
    if (key == _scheduledFor) return;
    _scheduledFor = key;
    await _plugin.cancel(id: promptWarnId);
    await _plugin.cancel(id: promptUpId);
    if (!_inBackground) return;

    final id = s.current.blockId;
    final warn = id == null || (app.blockById(id)?.warnBeforeEnd ?? true);
    final exact = await _android?.canScheduleExactNotifications() ?? false;
    for (final p in promptsFor(s, app.now(), warn: warn)) {
      await _plugin.zonedSchedule(
        id: p.id,
        title: p.title,
        body: p.body,
        payload: stepPayload(s),
        scheduledDate: tz.TZDateTime.from(p.at.toUtc(), tz.UTC),
        androidScheduleMode: exact
            ? AndroidScheduleMode.exactAllowWhileIdle
            : AndroidScheduleMode.inexactAllowWhileIdle,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            'mission_prompts',
            'Przypomnienia o etapach',
            channelDescription: '2 minuty przed końcem etapu i gdy czas minie.',
            importance: Importance.high,
            priority: Priority.high,
            category: AndroidNotificationCategory.reminder,
            color: Palette.gold,
            timeoutAfter: 10 * 60 * 1000,
            actions: _actions(s.current.allowPlusFive),
          ),
        ),
      );
    }
  }

  Future<void> _stop() async {
    _running = false;
    _scheduledFor = '';
    _timer?.cancel();
    _timer = null;
    await _plugin.cancel(id: promptWarnId);
    await _plugin.cancel(id: promptUpId);
    _serviceStarted = false;
    await _android?.stopForegroundService();
    await _plugin.cancel(id: _ongoingId);
  }
}
