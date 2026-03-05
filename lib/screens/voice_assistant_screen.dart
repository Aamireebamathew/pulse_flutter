// voice_assistant_screen.dart
// Flutter equivalent of VoiceAssistant.tsx
// Full Supabase search + save + list + alerts via voice or text

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/voice_service.dart';
import '../../i18n/app_translations.dart';
import '../../utils/app_theme.dart';
import '../../widgets/common_widgets.dart';

class VoiceAssistantScreen extends StatefulWidget {
  final String langCode;
  const VoiceAssistantScreen({super.key, this.langCode = 'en-US'});

  @override
  State<VoiceAssistantScreen> createState() => _VoiceAssistantScreenState();
}

class _VoiceAssistantScreenState extends State<VoiceAssistantScreen> {
  final _supabase    = Supabase.instance.client;
  final _voice       = VoiceService.instance;
  final _searchCtrl  = TextEditingController();

  bool   _processing    = false;
  String _lastTranscript = '';
  String _lastResponse   = '';
  String _selectedLang   = 'en-US';
  bool   _showLangPicker = false;
  List<Map<String, dynamic>> _results = [];
  String? _resultSource; // 'voice' | 'search'

  late AppTranslations _t;

  static const _langs = AppTranslations.supportedCodes;

  // ── Intent detection ────────────────────────────────────────────────────────
  bool _isFindIntent(String text) =>
      RegExp(r'where\s+(is|are|was|were|s)\s+(my|the|a)?\s*', caseSensitive: false).hasMatch(text) ||
      RegExp(r'find\s+(my|the|a)?\s*', caseSensitive: false).hasMatch(text) ||
      RegExp(r'locate\s+(my|the|a)?\s*', caseSensitive: false).hasMatch(text);

  bool _isSaveIntent(String text) =>
      RegExp(r'(save|put|place|kept|left|stored)\s+.+\s+(in|on|at)\s+', caseSensitive: false).hasMatch(text);

  String _extractObjectName(String text) => text
      .replaceAll(RegExp(r'where\s+(is|are|was|were|s)\s+(my|the|a)?\s*', caseSensitive: false), '')
      .replaceAll(RegExp(r'find\s+(my|the|a)?\s*', caseSensitive: false), '')
      .replaceAll(RegExp(r'locate\s+(my|the|a)?\s*', caseSensitive: false), '')
      .trim()
      .replaceAll(RegExp(r'[?.!,]+$'), '');

  String _timeAgo(String? dateString) {
    if (dateString == null) return '';
    final dt = DateTime.tryParse(
        dateString.endsWith('Z') ? dateString : '${dateString}Z');
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return _t.commonJustNow;
    if (diff.inMinutes < 60) return '${diff.inMinutes} ${_t.commonMinutesAgo}';
    if (diff.inHours < 24)   return '${diff.inHours} ${_t.commonHoursAgo}';
    return '${diff.inDays} ${_t.commonDaysAgo}';
  }

  // ── Lifecycle ───────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _selectedLang = widget.langCode;
    _t = AppTranslations.of(_selectedLang);
    _voice.addListener(_onVoiceUpdate);
    _voice.initialize().then((_) {
      _voice.setLanguage(_selectedLang);
    });
  }

  @override
  void dispose() {
    _voice.removeListener(_onVoiceUpdate);
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onVoiceUpdate() {
    if (!mounted) return;
    final text = _voice.transcript.toLowerCase().trim();
    if (text.isEmpty || text == _lastTranscript || _processing) return;
    setState(() => _lastTranscript = text);

    if (_isFindIntent(text)) {
      _processSearch(text);
    } else if (_isSaveIntent(text)) {
      _processSave(text);
    } else if (RegExp(r'show alerts|any alerts|unread alerts', caseSensitive: false).hasMatch(text)) {
      _processAlerts();
    } else if (RegExp(r'list|show.*objects', caseSensitive: false).hasMatch(text)) {
      _processList();
    }
  }

  // ── Commands ────────────────────────────────────────────────────────────────
  Future<void> _processSearch(String command) async {
    setState(() { _processing = true; _results = []; _resultSource = null; });

    final objName = _extractObjectName(command);
    if (objName.isEmpty) {
      _respond('What object are you looking for?');
      return;
    }

    final user = _supabase.auth.currentUser;
    if (user == null) { _respond('You need to be signed in.'); return; }

    var data = await _supabase
        .from('objects')
        .select('id, object_name, last_location, last_seen, is_unusual')
        .eq('user_id', user.id)
        .ilike('object_name', '%$objName%')
        .order('last_seen', ascending: false)
        .limit(5);

    if ((data as List).isEmpty) {
      for (final word in objName.split(RegExp(r'\s+')).where((w) => w.length > 2)) {
        final match = await _supabase
            .from('objects')
            .select('id, object_name, last_location, last_seen, is_unusual')
            .eq('user_id', user.id)
            .ilike('object_name', '%$word%')
            .order('last_seen', ascending: false)
            .limit(5);
        if ((match as List).isNotEmpty) { data = match; break; }
      }
    }

    final list = List<Map<String, dynamic>>.from(data as List);
    final top  = list.isNotEmpty ? list.first : null;
    final r = top != null
        ? 'Your ${top['object_name']} was last seen in ${top['last_location']}, ${_timeAgo(top['last_seen'])}.'
        : 'Sorry, I couldn\'t find $objName.';

    _voice.stopListening();
    setState(() {
      _lastResponse = r;
      _results      = list;
      _resultSource = 'voice';
      _processing   = false;
    });
    _voice.speak(r);
  }

  Future<void> _processSave(String command) async {
    setState(() => _processing = true);

    final match = RegExp(
      r'(?:save|put|place|kept|left|stored)\s+(?:my\s+|the\s+)?(.+?)\s+(?:in|on|at)\s+(?:the\s+)?(.+)',
      caseSensitive: false,
    ).firstMatch(command);

    final objName = match?.group(1)?.trim().replaceAll(RegExp(r'[?.!]+$'), '') ?? '';
    final location = match?.group(2)?.trim().replaceAll(RegExp(r'[?.!]+$'), '') ?? 'current location';

    if (objName.isEmpty) {
      _respond('I didn\'t catch what you want to save.');
      return;
    }

    final user = _supabase.auth.currentUser;
    if (user == null) { _respond('You need to be signed in to save objects.'); return; }

    final now = DateTime.now().toIso8601String();
    final existing = await _supabase
        .from('objects')
        .select('id, object_name')
        .eq('user_id', user.id)
        .ilike('object_name', '%$objName%')
        .maybeSingle();

    String r;
    if (existing != null) {
      await _supabase.from('objects').update({
        'last_location': location, 'last_seen': now, 'updated_at': now
      }).eq('id', existing['id']);
      r = 'Updated ${existing['object_name']} location to $location.';
    } else {
      await _supabase.from('objects').insert({
        'user_id': user.id, 'object_name': objName,
        'last_location': location, 'usual_location': location,
        'last_seen': now, 'is_unusual': false,
      });
      r = 'Got it! Registered $objName in $location.';
    }

    _voice.stopListening();
    setState(() { _lastResponse = r; _processing = false; });
    _voice.speak(r);
  }

  Future<void> _processList() async {
    setState(() => _processing = true);
    final user = _supabase.auth.currentUser;
    if (user == null) { setState(() => _processing = false); return; }

    final data = List<Map<String, dynamic>>.from(
      await _supabase.from('objects')
          .select('id, object_name, last_location, last_seen, is_unusual')
          .eq('user_id', user.id)
          .order('last_seen', ascending: false)
          .limit(5),
    );

    final r = data.isEmpty
        ? 'You have no tracked objects yet.'
        : 'Your items: ${data.map((o) => '${o['object_name']} in ${o['last_location'] ?? 'unknown'}').join(', ')}.';

    _voice.stopListening();
    setState(() {
      _lastResponse = r;
      _results      = data;
      _resultSource = 'voice';
      _processing   = false;
    });
    _voice.speak(r);
  }

  Future<void> _processAlerts() async {
    setState(() => _processing = true);
    final user = _supabase.auth.currentUser;
    if (user == null) { setState(() => _processing = false); return; }

    final data = List<Map<String, dynamic>>.from(
      await _supabase.from('alerts')
          .select()
          .eq('user_id', user.id)
          .eq('is_read', false),
    );

    final r = data.isEmpty
        ? 'You have no unread alerts.'
        : 'You have ${data.length} unread alert${data.length > 1 ? 's' : ''}.';

    _voice.stopListening();
    setState(() {
      _lastResponse = r;
      _results      = data;
      _resultSource = 'voice';
      _processing   = false;
    });
    _voice.speak(r);
  }

  Future<void> _handleSearch() async {
    final query = _searchCtrl.text.trim();
    if (query.isEmpty) return;
    setState(() { _processing = true; _resultSource = null; });

    final user = _supabase.auth.currentUser;
    if (user == null) { setState(() => _processing = false); return; }

    final cleanQuery = _isFindIntent(query)
        ? _extractObjectName(query.toLowerCase())
        : query;

    final objs = List<Map<String, dynamic>>.from(
      await _supabase.from('objects').select()
          .eq('user_id', user.id).ilike('object_name', '%$cleanQuery%'),
    );
    final alts = List<Map<String, dynamic>>.from(
      await _supabase.from('alerts').select()
          .eq('user_id', user.id).ilike('message', '%$cleanQuery%'),
    );

    final combined = [...objs, ...alts];
    setState(() { _results = combined; _resultSource = 'search'; _processing = false; });

    if (combined.isEmpty) {
      _voice.speak('Sorry, I couldn\'t find $cleanQuery.');
    } else {
      final top = combined.first;
      if (top.containsKey('object_name')) {
        _voice.speak('Your ${top['object_name']} was last seen in ${top['last_location']}, ${_timeAgo(top['last_seen'])}.');
      } else {
        _voice.speak('Found ${combined.length} result${combined.length > 1 ? 's' : ''}.');
      }
    }
  }

  void _respond(String text) {
    setState(() { _lastResponse = text; _processing = false; });
    _voice.speak(text);
  }

  // ── Build ───────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    if (!_voice.isSupported && _voice.micError == MicError.notSupported) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: _InfoBanner(
          color: AppColors.warning,
          icon: Icons.warning_amber_rounded,
          message: _t.voiceNotSupported,
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(children: [
        // ── Card ────────────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF0F172A).withOpacity(0.85)
                : Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(
              color: const Color(0xFF22D3EE).withOpacity(0.2),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // ── Header row ─────────────────────────────────────────────
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  // Title + lang picker
                  Row(children: [
                    Icon(Icons.graphic_eq,
                        size: 22, color: const Color(0xFF22D3EE)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(_t.voiceTitle,
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: context.textPrimary)),
                        Text(_t.voiceSubtitle,
                            style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF22D3EE))),
                      ]),
                    ),
                    // Language picker button
                    GestureDetector(
                      onTap: () =>
                          setState(() => _showLangPicker = !_showLangPicker),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: Colors.white.withOpacity(0.12)),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.language,
                              size: 13, color: Color(0xFF22D3EE)),
                          const SizedBox(width: 4),
                          Text(
                            AppTranslations.labelFor(_selectedLang),
                            style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF22D3EE)),
                          ),
                        ]),
                      ),
                    ),
                  ]),

                  // Language dropdown
                  if (_showLangPicker)
                    _LangPicker(
                      selected: _selectedLang,
                      onSelect: (code) {
                        setState(() {
                          _selectedLang  = code;
                          _t             = AppTranslations.of(code);
                          _showLangPicker = false;
                        });
                        _voice.setLanguage(code);
                      },
                    ),

                  const SizedBox(height: AppSpacing.md),

                  // Search bar
                  Row(children: [
                    Expanded(
                      child: TextField(
                        controller: _searchCtrl,
                        onSubmitted: (_) => _handleSearch(),
                        style: TextStyle(
                            color: context.textPrimary, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: _t.voiceSearchPlaceholder,
                          hintStyle: TextStyle(
                              color: context.textMuted, fontSize: 13),
                          prefixIcon: Icon(Icons.search,
                              size: 18, color: context.textMuted),
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 10),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.05),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide(
                                color: Colors.white.withOpacity(0.1)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide(
                                color: Colors.white.withOpacity(0.1)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 40,
                      child: ElevatedButton(
                        onPressed: _processing ? null : _handleSearch,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0891B2),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16),
                        ),
                        child: Text(_t.voiceSearchButton,
                            style: const TextStyle(fontSize: 13)),
                      ),
                    ),
                  ]),
                ]),
              ),

              const SizedBox(width: AppSpacing.md),

              // ── Mic button + sound bars ─────────────────────────────
              _MicButton(
                isListening: _voice.isListening,
                processing:  _processing,
                onTap: () => _voice.isListening
                    ? _voice.stopListening()
                    : _voice.startListening(),
              ),
            ]),

            // ── Mic error banner ──────────────────────────────────────
            if (_voice.micError != null &&
                _voice.micError != MicError.notSupported) ...[
              const SizedBox(height: AppSpacing.md),
              _InfoBanner(
                color: AppColors.error,
                icon: _micErrorIcon(_voice.micError!),
                message: _micErrorMessage(_voice.micError!),
              ),
            ],

            // ── Transcript ────────────────────────────────────────────
            if (_voice.transcript.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              _TranscriptBox(
                  label: _t.voiceYouSaid,
                  text: _voice.transcript,
                  color: const Color(0xFF22D3EE)),
            ],

            // ── Response ──────────────────────────────────────────────
            if (_lastResponse.isNotEmpty && !_processing) ...[
              const SizedBox(height: AppSpacing.md),
              _TranscriptBox(
                label: _t.voiceResponse,
                text: _lastResponse,
                color: const Color(0xFF22D3EE),
                bgOpacity: 0.10,
              ),
            ],

            // ── Processing indicator ──────────────────────────────────
            if (_processing) ...[
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Row(children: [
                  const SizedBox(
                    width: 14, height: 14,
                    child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF22D3EE)),
                  ),
                  const SizedBox(width: 10),
                  Text(_t.voiceProcessing,
                      style: const TextStyle(
                          color: Color(0xFF22D3EE), fontSize: 13)),
                ]),
              ),
            ],

            // ── Results ───────────────────────────────────────────────
            if (_results.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                _resultSource == 'voice'
                    ? _t.voiceVoiceResults
                    : _t.voiceSearchResults,
                style: const TextStyle(
                    fontSize: 11, color: Color(0xFF22D3EE)),
              ),
              const SizedBox(height: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 200),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _results.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: 6),
                  itemBuilder: (_, i) =>
                      _ResultTile(item: _results[i], timeAgo: _timeAgo),
                ),
              ),
            ],

            // ── No results ────────────────────────────────────────────
            if (_resultSource != null && _results.isEmpty && !_processing) ...[
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                      color: Colors.white.withOpacity(0.08)),
                ),
                child: Center(
                  child: Text(_t.voiceNoResults,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: context.textMuted, fontSize: 13)),
                ),
              ),
            ],

            // ── Tips ──────────────────────────────────────────────────
            const SizedBox(height: AppSpacing.md),
            Text(_t.voiceTips,
                style: const TextStyle(
                    fontSize: 11, color: Color(0xFF22D3EE))),
          ]),
        ),
      ]),
    );
  }

  IconData _micErrorIcon(MicError e) => switch (e) {
    MicError.permissionDenied => Icons.mic_off,
    MicError.noSpeech         => Icons.mic,
    MicError.network          => Icons.wifi_off,
    _                         => Icons.error_outline,
  };

  String _micErrorMessage(MicError e) => switch (e) {
    MicError.notSupported    => 'Voice not supported. Try Chrome or Edge.',
    MicError.permissionDenied => 'Microphone access denied. Allow mic in settings.',
    MicError.noSpeech         => 'No speech detected. Speak clearly and try again.',
    MicError.network          => 'Network error. Check your connection.',
    MicError.unknown          => 'Microphone error. Please try again.',
  };
}

// ─── Language picker dropdown ─────────────────────────────────────────────────
class _LangPicker extends StatelessWidget {
  final String          selected;
  final void Function(String) onSelect;
  const _LangPicker({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      constraints: const BoxConstraints(maxHeight: 220),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: const Color(0xFF22D3EE).withOpacity(0.2)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 12),
        ],
      ),
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 4),
        children: AppTranslations.supportedCodes.map((code) {
          final active = code == selected;
          return InkWell(
            onTap: () => onSelect(code),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 9),
              child: Text(
                AppTranslations.labelFor(code),
                style: TextStyle(
                  fontSize: 13,
                  color: active
                      ? const Color(0xFF22D3EE)
                      : Colors.white,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Mic button + animated sound bars ────────────────────────────────────────
class _MicButton extends StatefulWidget {
  final bool isListening, processing;
  final VoidCallback onTap;
  const _MicButton({
    required this.isListening,
    required this.processing,
    required this.onTap,
  });

  @override
  State<_MicButton> createState() => _MicButtonState();
}

class _MicButtonState extends State<_MicButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600))
      ..repeat(reverse: true);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      GestureDetector(
        onTap: widget.processing ? null : widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 56, height: 56,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF06B6D4), Color(0xFF3B82F6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: widget.isListening
                ? [
                    BoxShadow(
                        color: const Color(0xFF06B6D4).withOpacity(0.5),
                        blurRadius: 16, spreadRadius: 2)
                  ]
                : [],
          ),
          child: widget.isListening
              ? Stack(alignment: Alignment.center, children: [
                  _PingRing(ctrl: _ctrl, delay: 0),
                  _PingRing(ctrl: _ctrl, delay: 400),
                  const Icon(Icons.mic, color: Colors.white, size: 24),
                ])
              : Icon(
                  widget.processing ? Icons.hourglass_empty : Icons.mic,
                  color: Colors.white.withOpacity(0.9),
                  size: 24,
                ),
        ),
      ),
      const SizedBox(height: 8),
      // Sound bars
      Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [0.9, 0.4, 1.0, 0.5, 0.8, 0.3, 0.7]
            .map((delay) => _SoundBar(
                  active: widget.isListening,
                  delay: Duration(milliseconds: (delay * 400).round()),
                  ctrl: _ctrl,
                ))
            .toList(),
      ),
    ]);
  }
}

class _PingRing extends StatelessWidget {
  final AnimationController ctrl;
  final int delay;
  const _PingRing({required this.ctrl, required this.delay});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ctrl,
      builder: (_, __) => Container(
        width:  48 + ctrl.value * 12,
        height: 48 + ctrl.value * 12,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: const Color(0xFF22D3EE)
                .withOpacity(0.4 * (1 - ctrl.value)),
            width: 1.5,
          ),
        ),
      ),
    );
  }
}

class _SoundBar extends StatelessWidget {
  final bool active;
  final Duration delay;
  final AnimationController ctrl;
  const _SoundBar(
      {required this.active, required this.delay, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ctrl,
      builder: (_, __) => Container(
        width:  3,
        height: active ? 4 + ctrl.value * 12 : 2,
        margin: const EdgeInsets.symmetric(horizontal: 1.5),
        decoration: BoxDecoration(
          color: active
              ? const Color(0xFF22D3EE)
              : const Color(0xFF22D3EE).withOpacity(0.25),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

// ─── Transcript/response box ──────────────────────────────────────────────────
class _TranscriptBox extends StatelessWidget {
  final String label, text;
  final Color  color;
  final double bgOpacity;
  const _TranscriptBox({
    required this.label,
    required this.text,
    required this.color,
    this.bgOpacity = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgOpacity > 0
            ? color.withOpacity(bgOpacity)
            : const Color(0xFF1E293B).withOpacity(0.5),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: bgOpacity > 0
            ? Border.all(color: color.withOpacity(0.2))
            : null,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: TextStyle(
                fontSize: 11, color: color, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text(text,
            style: TextStyle(
                fontSize: 14, color: context.textPrimary, height: 1.4)),
      ]),
    );
  }
}

// ─── Search result tile ───────────────────────────────────────────────────────
class _ResultTile extends StatelessWidget {
  final Map<String, dynamic> item;
  final String Function(String?) timeAgo;
  const _ResultTile({required this.item, required this.timeAgo});

  @override
  Widget build(BuildContext context) {
    final isObject = item.containsKey('object_name');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withOpacity(0.6),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: isObject
          ? Row(children: [
              Text(item['object_name'] ?? '',
                  style: const TextStyle(
                      color: Color(0xFF22D3EE),
                      fontWeight: FontWeight.w500,
                      fontSize: 13)),
              const Text(' — ',
                  style: TextStyle(color: Colors.white70, fontSize: 13)),
              Expanded(
                child: Text(item['last_location'] ?? 'No location',
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 13)),
              ),
              Text(timeAgo(item['last_seen']),
                  style: const TextStyle(
                      color: Color(0xFF22D3EE),
                      fontSize: 10)),
            ])
          : Text('⚠ ${item['message'] ?? ''}',
              style: const TextStyle(
                  color: Color(0xFFFBBF24), fontSize: 13)),
    );
  }
}

// ─── Info banner ──────────────────────────────────────────────────────────────
class _InfoBanner extends StatelessWidget {
  final Color    color;
  final IconData icon;
  final String   message;
  const _InfoBanner(
      {required this.color, required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 8),
        Expanded(
            child: Text(message,
                style: TextStyle(color: color, fontSize: 13))),
      ]),
    );
  }
}