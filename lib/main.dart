import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'audio/loop_audio_player.dart';
import 'config/legal_config.dart';
import 'services/external_link.dart';
import 'services/purchase_service.dart';

const black = Color(0xFF070707);
const panel = Color(0xFF171717);
const yellow = Color(0xFFFFC21C);
const blue = Color(0xFF399CFF);
const grey = Color(0xFF929292);
const captureMode = String.fromEnvironment('CAPTURE_MODE');
const customerPreview = bool.fromEnvironment('CUSTOMER_PREVIEW');

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: black,
    ),
  );
  runApp(const SuperCajonApp());
}

class Rhythm {
  const Rhythm(this.name, this.bpm, this.audio, this.cover, this.description);
  final String name;
  final int bpm;
  final String audio;
  final String cover;
  final String description;
}

const rhythms = <Rhythm>[
  Rhythm(
    'Arrocha',
    92,
    'Arrocha.wav',
    'arrocha_img.png',
    'Balanço envolvente e marcante',
  ),
  Rhythm(
    'Arrocha Rápido',
    118,
    'arrocha_rapido.wav',
    'arrocha_rapido_img.png',
    'Energia para levantar o salão',
  ),
  Rhythm(
    'Vanera',
    124,
    'Vanera.wav',
    'vanera_img.png',
    'Cadência gaúcha dançante',
  ),
  Rhythm(
    'Bachata',
    126,
    'Bachata.wav',
    'bachata_img.png',
    'Leve, latina e romântica',
  ),
  Rhythm(
    'Guarânia',
    78,
    'guarania.wav',
    'guarania_img.png',
    'Andamento lento e expressivo',
  ),
  Rhythm(
    'Pagode',
    96,
    'pagode.wav',
    'pagode_img.png',
    'Swing brasileiro essencial',
  ),
  Rhythm(
    'Pagode Rápido',
    116,
    'pagode_rapido.wav',
    'pagode_rapido_img.png',
    'Swing acelerado e festivo',
  ),
  Rhythm(
    'Axé Lento',
    104,
    'axe_lento.wav',
    'axe_lento_img.png',
    'Groove baiano cadenciado',
  ),
  Rhythm(
    'Axé Rápido',
    138,
    'axe_rapido.wav',
    'axe_rapido_img.png',
    'Pulso forte de carnaval',
  ),
  Rhythm(
    'Pop Rock',
    112,
    'pop_rock.wav',
    'pop_rock_img.png',
    'Base firme e versátil',
  ),
  Rhythm(
    'Pop Rock 2',
    128,
    'pop_rock_2.wav',
    'pop_rock_2_img.png',
    'Variação moderna e pulsante',
  ),
  Rhythm(
    'Xote',
    94,
    'xote.wav',
    'xote_img.png',
    'Forró macio para dançar junto',
  ),
  Rhythm(
    'Reggae',
    82,
    'reggae.wav',
    'reggae_img.png',
    'Contratempo leve e relaxado',
  ),
];

class SuperCajonApp extends StatefulWidget {
  const SuperCajonApp({super.key, this.initializePurchases = true});

  final bool initializePurchases;

  @override
  State<SuperCajonApp> createState() => _SuperCajonAppState();
}

class _SuperCajonAppState extends State<SuperCajonApp>
    with WidgetsBindingObserver {
  late final PurchaseService _purchases;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _purchases = PurchaseService();
    if (widget.initializePurchases && !customerPreview) {
      _purchases.initialize();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _purchases.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_purchases.refreshEntitlement());
    }
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Super Cajon',
    theme: ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: black,
      colorScheme: const ColorScheme.dark(
        primary: yellow,
        secondary: blue,
        surface: panel,
      ),
      fontFamily: 'Arial',
      sliderTheme: const SliderThemeData(
        activeTrackColor: yellow,
        inactiveTrackColor: Color(0xFF363636),
        thumbColor: yellow,
        trackHeight: 3,
      ),
    ),
    home: SplashScreen(purchases: _purchases),
  );
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.purchases});

  final PurchaseService purchases;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (captureMode != 'splash') {
      _timer = Timer(const Duration(milliseconds: 1500), _openPlayer);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _openPlayer() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 450),
        pageBuilder: (context, animation, secondaryAnimation) => FadeTransition(
          opacity: animation,
          child: PlayerScreen(purchases: widget.purchases),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: _openPlayer,
    child: Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -.12),
            radius: .75,
            colors: [Color(0xFF4A3100), Color(0xFF17130B), black],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset('assets/brand/logo-super-cajon.png', width: 310),
                const SizedBox(height: 28),
                const SizedBox(
                  width: 112,
                  child: LinearProgressIndicator(
                    minHeight: 3,
                    color: yellow,
                    backgroundColor: Color(0x22FFFFFF),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'CAJÓN PRONTO PARA TOCAR',
                  style: TextStyle(
                    color: grey,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key, required this.purchases});

  final PurchaseService purchases;

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  static const _freeRhythms = {0, 5, 11};
  final LoopAudioPlayer _player = LoopAudioPlayer();
  int _selected = 0;
  int _bpm = rhythms.first.bpm;
  double _volume = .9;
  bool _fadeStop = true;
  bool _ready = false;
  bool _loadingAudio = false;
  bool _resumeAfterLoad = false;
  int? _pendingRhythm;

  Rhythm get rhythm => rhythms[_selected];
  bool _isLocked(int index) =>
      !_freeRhythms.contains(index) && !widget.purchases.isPremium;

  @override
  void initState() {
    super.initState();
    widget.purchases.addListener(_purchaseChanged);
    _load(0);
    final capture = captureMode.isNotEmpty
        ? captureMode
        : Uri.base.queryParameters['capture'];
    if (capture == 'paywall' || capture == 'settings') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        capture == 'paywall' ? _openPaywall() : _openSettings();
      });
    }
  }

  void _purchaseChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _load(int index, {bool autoplay = false}) async {
    _pendingRhythm = index;
    _resumeAfterLoad = _resumeAfterLoad || autoplay || _player.playing;
    setState(() {
      _selected = index;
      _bpm = rhythms[index].bpm;
      _ready = false;
    });

    // Only one asset may be loaded at a time. Without this guard, the initial
    // Arrocha load can finish after a rhythm selected by the user and replace
    // the newer audio source, especially on the web preview.
    if (_loadingAudio) return;
    _loadingAudio = true;

    try {
      while (_pendingRhythm != null) {
        final target = _pendingRhythm!;
        _pendingRhythm = null;
        await _player.setAsset('assets/audio/${rhythms[target].audio}');

        // A newer tap arrived while this asset was loading. Load that request
        // before making the player available again.
        if (_pendingRhythm != null) continue;

        await _player.setVolume(_volume);
        await _player.setSpeed(1);
        if (!mounted) return;
        setState(() => _ready = true);
        if (_resumeAfterLoad) {
          _resumeAfterLoad = false;
          unawaited(_player.play());
        }
      }
    } finally {
      _loadingAudio = false;
    }
  }

  Future<void> _togglePlay() async {
    if (!_ready) return;
    if (_player.playing) {
      if (_fadeStop) {
        for (var step = 9; step >= 0; step--) {
          await _player.setVolume(_volume * step / 10);
          await Future<void>.delayed(const Duration(milliseconds: 50));
        }
      }
      await _player.pause();
      await _player.seek(Duration.zero);
      await _player.setVolume(_volume);
    } else {
      // play() completes only when playback completes. A looping source never
      // completes, so it must not hold this interaction future open.
      unawaited(_player.play());
    }
    if (mounted) setState(() {});
  }

  Future<void> _setBpm(int bpm) async {
    final next = bpm.clamp(70, 160);
    setState(() => _bpm = next);
    await _player.setSpeed(next / rhythm.bpm);
  }

  void _navigate(int delta) =>
      _selectRhythm((_selected + delta + rhythms.length) % rhythms.length);

  void _selectRhythm(int index) {
    if (_isLocked(index)) {
      _openPaywall();
      return;
    }
    _load(index, autoplay: _player.playing);
  }

  @override
  void dispose() {
    widget.purchases.removeListener(_purchaseChanged);
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -1),
          radius: 1.1,
          colors: [Color(0xFF292929), black],
        ),
      ),
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(22, 4, 22, 0),
              sliver: SliverList.list(
                children: [
                  _header(),
                  _hero(),
                  _tempo(),
                  _transport(),
                  _sectionTitle(),
                ],
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 18),
              sliver: SliverGrid.builder(
                itemCount: rhythms.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisExtent: 142,
                  crossAxisSpacing: 11,
                  mainAxisSpacing: 11,
                ),
                itemBuilder: (_, index) => _rhythmCard(index),
              ),
            ),
            const SliverToBoxAdapter(child: AppSignature()),
          ],
        ),
      ),
    ),
  );

  Widget _header() => SizedBox(
    height: 80,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Image.asset('assets/brand/logo-super-cajon.png', width: 74, height: 74),
        _circleButton(Icons.tune_rounded, _openSettings, size: 44),
      ],
    ),
  );

  Widget _hero() => Padding(
    padding: const EdgeInsets.fromLTRB(0, 30, 0, 20),
    child: Column(
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: blue,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: blue, blurRadius: 12)],
              ),
              child: SizedBox(width: 6, height: 6),
            ),
            SizedBox(width: 9),
            Text(
              'AGORA SELECIONADO',
              style: TextStyle(
                color: grey,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.8,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          rhythm.name,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 52,
            height: .96,
            fontWeight: FontWeight.w900,
            letterSpacing: -2.8,
          ),
        ),
        const SizedBox(height: 9),
        Text(
          rhythm.description,
          style: const TextStyle(color: grey, fontSize: 14),
        ),
        const SizedBox(height: 25),
        StreamBuilder<bool>(
          stream: _player.playingStream,
          builder: (_, snap) => Waveform(active: snap.data ?? false),
        ),
      ],
    ),
  );

  Widget _tempo() => Container(
    height: 126,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(25),
      border: Border.all(color: const Color(0xFF363636)),
      gradient: const LinearGradient(
        colors: [Color(0xFF222222), Color(0xFF111111)],
      ),
      boxShadow: const [
        BoxShadow(color: Colors.black54, blurRadius: 40, offset: Offset(0, 18)),
      ],
    ),
    child: Column(
      children: [
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _squareButton(Icons.remove_rounded, () => _setBpm(_bpm - 1)),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$_bpm',
                    style: const TextStyle(
                      fontSize: 42,
                      height: 1,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'BPM',
                    style: TextStyle(
                      color: yellow,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
              _squareButton(Icons.add_rounded, () => _setBpm(_bpm + 1)),
            ],
          ),
        ),
        Slider(
          value: _bpm.toDouble(),
          min: 70,
          max: 160,
          onChanged: (value) => _setBpm(value.round()),
        ),
      ],
    ),
  );

  Widget _transport() => Padding(
    padding: const EdgeInsets.symmetric(vertical: 28),
    child: StreamBuilder<bool>(
      stream: _player.playingStream,
      builder: (_, snap) {
        final playing = snap.data ?? false;
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _circleButton(Icons.skip_previous_rounded, () => _navigate(-1)),
            const SizedBox(width: 30),
            GestureDetector(
              onTap: _togglePlay,
              child: Container(
                width: 82,
                height: 82,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFFFFD84C), Color(0xFFF2A900)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x55FFC21C),
                      blurRadius: 30,
                      offset: Offset(0, 12),
                    ),
                  ],
                ),
                child: Icon(
                  playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: black,
                  size: 42,
                ),
              ),
            ),
            const SizedBox(width: 30),
            _circleButton(Icons.skip_next_rounded, () => _navigate(1)),
          ],
        );
      },
    ),
  );

  Widget _sectionTitle() => const Padding(
    padding: EdgeInsets.only(bottom: 16),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SEUS RITMOS',
              style: TextStyle(
                color: yellow,
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.8,
              ),
            ),
            SizedBox(height: 5),
            Text(
              'Escolha e toque',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        Text(
          '13 loops',
          style: TextStyle(
            color: blue,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );

  Widget _rhythmCard(int index) {
    final item = rhythms[index];
    final active = index == _selected;
    return Semantics(
      button: true,
      selected: active,
      label: '${item.name}, ${item.bpm} BPM',
      child: GestureDetector(
        onTap: () => _selectRhythm(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: active ? yellow : const Color(0xFF333333),
              width: active ? 2 : 1,
            ),
            image: DecorationImage(
              image: AssetImage('assets/covers/${item.cover}'),
              fit: BoxFit.cover,
            ),
            boxShadow: active
                ? const [BoxShadow(color: Color(0x33FFC21C), blurRadius: 18)]
                : null,
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              const Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Color(0xD9080808),
                        Color(0xF5080808),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 13,
                left: 14,
                child: Text(
                  '${index + 1}'.padLeft(2, '0'),
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    shadows: [Shadow(blurRadius: 5)],
                  ),
                ),
              ),
              Positioned(
                right: 14,
                top: 13,
                child: Icon(
                  _isLocked(index)
                      ? Icons.lock_rounded
                      : Icons.graphic_eq_rounded,
                  size: 19,
                  color: active || _isLocked(index) ? yellow : Colors.white,
                ),
              ),
              Positioned(
                left: 14,
                right: 10,
                bottom: 13,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        shadows: [Shadow(blurRadius: 8)],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${item.bpm} BPM ORIGINAL',
                      style: TextStyle(
                        color: active ? yellow : const Color(0xFFC1C7CA),
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _circleButton(IconData icon, VoidCallback onTap, {double size = 54}) =>
      IconButton(
        onPressed: onTap,
        icon: Icon(icon, size: 22),
        style: IconButton.styleFrom(
          fixedSize: Size.square(size),
          foregroundColor: Colors.white,
          backgroundColor: const Color(0xFF181818),
          side: const BorderSide(color: Color(0xFF353535)),
        ),
      );

  Widget _squareButton(IconData icon, VoidCallback onTap) => IconButton(
    onPressed: onTap,
    icon: Icon(icon, size: 29),
    style: IconButton.styleFrom(
      fixedSize: const Size.square(52),
      foregroundColor: Colors.white,
      backgroundColor: const Color(0xFF222222),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17)),
      side: const BorderSide(color: Color(0xFF3B3B3B)),
    ),
  );

  void _openPaywall() => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => AnimatedBuilder(
      animation: widget.purchases,
      builder: (context, child) {
        final purchases = widget.purchases;
        const marketingPreview = captureMode == 'marketing' || customerPreview;
        return Container(
          padding: const EdgeInsets.fromLTRB(22, 10, 22, 26),
          decoration: const BoxDecoration(
            color: panel,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            border: Border(top: BorderSide(color: Color(0xFF4A4A4A))),
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 34,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        const _SheetHandle(),
                        Align(
                          alignment: Alignment.centerRight,
                          child: IconButton(
                            tooltip: 'Fechar',
                            onPressed: () => Navigator.pop(sheetContext),
                            icon: const Icon(Icons.close_rounded, size: 20),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Image.asset(
                    'assets/brand/logo-super-cajon.png',
                    width: 132,
                    height: 132,
                  ),
                  Text(
                    purchases.isPremium
                        ? 'Super Cajon Completo'
                        : 'Desbloqueie o Super Cajon',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -.7,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    purchases.isPremium
                        ? 'Todos os ritmos estão disponíveis.'
                        : 'Assinatura anual com novos loops a cada trimestre.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: grey, fontSize: 13),
                  ),
                  const SizedBox(height: 22),
                  const _PaywallFeature(
                    icon: Icons.library_music_rounded,
                    text: 'Todos os 13 ritmos',
                  ),
                  const _PaywallFeature(
                    icon: Icons.speed_rounded,
                    text: 'Controle de BPM e parada suave',
                  ),
                  const _PaywallFeature(
                    icon: Icons.offline_bolt_rounded,
                    text: 'Loops disponíveis offline após a validação',
                  ),
                  const _PaywallFeature(
                    icon: Icons.block_rounded,
                    text: 'Sem anúncios',
                  ),
                  const _PaywallFeature(
                    icon: Icons.update_rounded,
                    text: 'Novos packs de loops trimestralmente',
                  ),
                  if (purchases.message != null && !marketingPreview) ...[
                    const SizedBox(height: 10),
                    Text(
                      purchases.message!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: purchases.isPremium
                            ? yellow
                            : const Color(0xFFB8B8B8),
                        fontSize: 11,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: FilledButton(
                      onPressed: purchases.isPremium
                          ? () => Navigator.pop(sheetContext)
                          : purchases.purchasePending ||
                                (purchases.product == null && !marketingPreview)
                          ? null
                          : customerPreview
                          ? purchases.previewUnlock
                          : marketingPreview
                          ? () {}
                          : purchases.buyAnnualSubscription,
                      style: FilledButton.styleFrom(
                        backgroundColor: yellow,
                        foregroundColor: black,
                        disabledBackgroundColor: const Color(0xFF3A3A3A),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(17),
                        ),
                      ),
                      child: purchases.purchasePending
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: yellow,
                              ),
                            )
                          : Text(
                              purchases.isPremium
                                  ? 'CONTINUAR'
                                  : purchases.product == null &&
                                        !marketingPreview
                                  ? 'INDISPONÍVEL NO PREVIEW'
                                  : 'ASSINAR • ${purchases.product?.price ?? 'R\$ 29,99'} / ANO',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                letterSpacing: .5,
                              ),
                            ),
                    ),
                  ),
                  if (!purchases.isPremium)
                    TextButton(
                      onPressed: purchases.purchasePending
                          ? null
                          : purchases.restore,
                      child: const Text(
                        'Restaurar assinatura',
                        style: TextStyle(
                          color: Color(0xFFB0B0B0),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  if (!purchases.isPremium) ...[
                    const Text(
                      'Você pode continuar usando Arrocha, Pagode e Xote '
                      'gratuitamente sem assinar.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: grey, fontSize: 10, height: 1.4),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Renovação automática a cada 12 meses. Cancele quando '
                      'quiser pela Google Play. O acesso permanece ativo até o '
                      'fim do período já pago.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: grey, fontSize: 10, height: 1.4),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      alignment: WrapAlignment.center,
                      children: [
                        TextButton(
                          onPressed: _openPrivacyNotice,
                          child: const Text('Privacidade'),
                        ),
                        TextButton(
                          onPressed: () => _openExternal(
                            LegalConfig.termsOfUseUrl,
                            'Não foi possível abrir os termos de uso.',
                          ),
                          child: const Text('Termos de uso'),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    ),
  );

  Future<void> _openExternal(String url, String failureMessage) async {
    final opened = await openExternalLink(url);
    if (!opened && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(failureMessage)));
    }
  }

  void _openPrivacyNotice() => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(sheetContext).height * .88,
      ),
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
      decoration: const BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: Color(0xFF3A3A3A))),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(child: _SheetHandle()),
              const SizedBox(height: 18),
              const Text(
                'Política de Privacidade',
                style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              const Text(
                'Última atualização: 13 de julho de 2026',
                style: TextStyle(color: grey, fontSize: 11),
              ),
              const SizedBox(height: 20),
              _legalParagraph(
                'Responsável',
                'O Super Cajon é oferecido por ${LegalConfig.developerName}. '
                    'Dúvidas sobre privacidade podem ser enviadas para '
                    '${LegalConfig.supportEmail}.',
              ),
              _legalParagraph(
                'Dados pessoais',
                'O aplicativo não exige cadastro e não coleta, transmite, '
                    'vende ou compartilha dados pessoais ou dados sensíveis '
                    'com o desenvolvedor. Não utilizamos anúncios nem serviços '
                    'de análise de comportamento.',
              ),
              _legalParagraph(
                'Assinatura Google Play',
                'A compra e a administração da assinatura são processadas '
                    'pela Google Play. O aplicativo recebe apenas o estado e '
                    'um token técnico da compra para liberar o conteúdo. Dados '
                    'de pagamento não são recebidos nem armazenados pelo '
                    'desenvolvedor.',
              ),
              _legalParagraph(
                'Armazenamento local',
                'O aplicativo guarda no dispositivo somente o estado da '
                    'assinatura e a data da última validação. Essas informações '
                    'podem ser removidas apagando os dados do aplicativo ou '
                    'desinstalando-o.',
              ),
              _legalParagraph(
                'Público-alvo',
                'A faixa etária declarada para o aplicativo é: '
                    '${LegalConfig.minimumTargetAge}. O conteúdo é adequado ao '
                    'público geral e familiar, mas não é direcionado '
                    'especificamente a crianças menores de 13 anos. O app não '
                    'possui comunicação entre usuários nem conteúdo gerado por '
                    'eles.',
              ),
              _legalParagraph(
                'Segurança e alterações',
                'Aplicamos minimização de dados e podemos atualizar esta '
                    'política quando o funcionamento do app mudar. A versão '
                    'vigente estará disponível no aplicativo e no endereço '
                    'público informado na Google Play.',
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _openExternal(
                    LegalConfig.privacyPolicyUrl,
                    'Não foi possível abrir a política de privacidade.',
                  ),
                  child: const Text('ABRIR VERSÃO ONLINE'),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _legalParagraph(String title, String body) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 5),
        Text(
          body,
          style: const TextStyle(color: Color(0xFFC7C7C7), height: 1.45),
        ),
      ],
    ),
  );

  void _openSettings() => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => StatefulBuilder(
      builder: (context, setSheetState) => Container(
        padding: const EdgeInsets.fromLTRB(22, 10, 22, 28),
        decoration: const BoxDecoration(
          color: panel,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(top: BorderSide(color: Color(0xFF3A3A3A))),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFF444444),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 16),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Ajustes',
                    style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900),
                  ),
                ),
                const Divider(height: 30, color: Color(0xFF333333)),
                Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Volume',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            'Saída geral dos loops',
                            style: TextStyle(color: grey, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 150,
                      child: Slider(
                        value: _volume,
                        activeColor: blue,
                        onChanged: (value) {
                          setState(() => _volume = value);
                          setSheetState(() {});
                          _player.setVolume(value);
                        },
                      ),
                    ),
                  ],
                ),
                const Divider(color: Color(0xFF333333)),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  value: _fadeStop,
                  activeTrackColor: yellow,
                  title: const Text(
                    'Parada suave',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: const Text(
                    'Fade ao pausar',
                    style: TextStyle(color: grey, fontSize: 11),
                  ),
                  onChanged: (value) {
                    setState(() => _fadeStop = value);
                    setSheetState(() {});
                  },
                ),
                const Divider(color: Color(0xFF333333)),
                AnimatedBuilder(
                  animation: widget.purchases,
                  builder: (context, child) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      widget.purchases.isPremium
                          ? Icons.verified_rounded
                          : Icons.workspace_premium_rounded,
                      color: widget.purchases.isPremium ? yellow : blue,
                    ),
                    title: Text(
                      widget.purchases.isPremium
                          ? 'Super Cajon Completo'
                          : 'Desbloquear versão completa',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      widget.purchases.isPremium
                          ? 'Assinatura anual ativa'
                          : 'R\$ 29,99 por ano',
                      style: const TextStyle(color: grey, fontSize: 11),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () {
                      Navigator.pop(context);
                      Future<void>.delayed(
                        const Duration(milliseconds: 180),
                        _openPaywall,
                      );
                    },
                  ),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.manage_accounts_rounded,
                    color: blue,
                  ),
                  title: const Text(
                    'Gerenciar assinatura',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: const Text(
                    'Renovar ou cancelar pela Google Play',
                    style: TextStyle(color: grey, fontSize: 11),
                  ),
                  trailing: const Icon(Icons.open_in_new_rounded, size: 18),
                  onTap: () => _openExternal(
                    LegalConfig.subscriptionManagementUrl,
                    'Não foi possível abrir a Google Play.',
                  ),
                ),
                const Divider(color: Color(0xFF333333)),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.privacy_tip_rounded, color: blue),
                  title: const Text(
                    'Política de privacidade',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: _openPrivacyNotice,
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.description_rounded, color: blue),
                  title: const Text(
                    'Termos de uso',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  trailing: const Icon(Icons.open_in_new_rounded, size: 18),
                  onTap: () => _openExternal(
                    LegalConfig.termsOfUseUrl,
                    'Não foi possível abrir os termos de uso.',
                  ),
                ),
                if (customerPreview && widget.purchases.isPremium)
                  TextButton.icon(
                    onPressed: widget.purchases.previewLock,
                    icon: const Icon(Icons.restart_alt_rounded, size: 18),
                    label: const Text('Resetar demonstração do paywall'),
                    style: TextButton.styleFrom(foregroundColor: blue),
                  ),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: Text(
                      '✓  Os loops funcionam offline entre validações periódicas.',
                      style: TextStyle(color: grey, fontSize: 11),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) => Container(
    width: 42,
    height: 4,
    decoration: BoxDecoration(
      color: const Color(0xFF444444),
      borderRadius: BorderRadius.circular(10),
    ),
  );
}

class _PaywallFeature extends StatelessWidget {
  const _PaywallFeature({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: const Color(0x1AFFC21C),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: yellow, size: 17),
        ),
        const SizedBox(width: 12),
        Text(
          text,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ],
    ),
  );
}

class AppSignature extends StatelessWidget {
  const AppSignature({super.key});

  @override
  Widget build(BuildContext context) => const SafeArea(
    top: false,
    child: Padding(
      padding: EdgeInsets.fromLTRB(22, 12, 22, 22),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'DEVELOPED BY ',
            style: TextStyle(
              color: Color(0xFF666666),
              fontSize: 8,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.25,
            ),
          ),
          Text(
            'DOPE STUDIO',
            style: TextStyle(
              color: Color(0xFF9A9A9A),
              fontSize: 8,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.25,
            ),
          ),
        ],
      ),
    ),
  );
}

class Waveform extends StatefulWidget {
  const Waveform({super.key, required this.active});
  final bool active;

  @override
  State<Waveform> createState() => _WaveformState();
}

class _WaveformState extends State<Waveform>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1050),
    );
    if (widget.active) _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant Waveform oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active == oldWidget.active) return;
    if (widget.active) {
      _controller.repeat();
    } else {
      _controller.animateBack(
        0,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return SizedBox(
      height: 42,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final progress = reduceMotion ? 0.25 : _controller.value;
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(28, (index) {
              final envelope =
                  .42 + .58 * math.sin((index / 27) * math.pi).abs();
              final waveA = math
                  .sin(progress * math.pi * 2 + index * .72)
                  .abs();
              final waveB = math
                  .sin(progress * math.pi * 4 - index * .31)
                  .abs();
              final movement = (waveA * .68) + (waveB * .32);
              final playingHeight = 7 + (31 * envelope * movement);
              final idleHeight = 5 + ((index * 7) % 8).toDouble();

              return Container(
                width: 3,
                height: widget.active && !reduceMotion
                    ? playingHeight
                    : idleHeight,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: widget.active ? yellow : const Color(0xFF464646),
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: widget.active
                      ? const [
                          BoxShadow(color: Color(0x55FFC21C), blurRadius: 5),
                        ]
                      : null,
                ),
              );
            }),
          );
        },
      ),
    );
  }
}
