import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_provider.dart';
import '../state/time_provider.dart';
import '../theme/pixel.dart';
import 'atividades_tab.dart';
import 'config_screen.dart';
import 'painel_tab.dart';
import 'tabelas_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  static const _titles = [
    ('PAINEL', 'CICLO DE TESTE'),
    ('TABELAS', 'RELATÓRIOS DA SPRINT'),
    ('ATIVIDADES', 'TEMPO TRABALHADO'),
  ];

  void _openConfig() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ConfigScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final time = context.watch<TimeProvider>();

    if (!app.loaded || !time.loaded) {
      return const Scaffold(
        body: Center(child: Text('CARREGANDO...', style: TextStyle(fontFamily: 'PressStart', fontSize: 10, color: Px.cyan))),
      );
    }

    final (title, subtitle) = _titles[_index];

    return Scaffold(
      body: Column(
        children: [
          _TopBar(title: title, subtitle: subtitle, onSettings: _openConfig),
          Expanded(
            child: IndexedStack(
              index: _index,
              children: const [PainelTab(), TabelasTab(), AtividadesTab()],
            ),
          ),
          _BottomNav(index: _index, onChanged: (i) => setState(() => _index = i)),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.title, required this.subtitle, required this.onSettings});

  final String title;
  final String subtitle;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 12, 16, 12),
      decoration: const BoxDecoration(
        color: Px.header,
        border: Border(bottom: BorderSide(color: Colors.black, width: 4)),
      ),
      child: Row(
        children: [
          Image.asset('assets/images/logo.png', width: 40, height: 40, filterQuality: FilterQuality.none),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Px.p(14, color: Px.cyan, height: 1).copyWith(
                    shadows: const [Shadow(color: Color(0xB300F0FF), blurRadius: 6)],
                  ),
                ),
                const SizedBox(height: 6),
                Text(subtitle, style: Px.v(19, color: Px.amber).copyWith(letterSpacing: 1)),
              ],
            ),
          ),
          PixelButton(icon: Icons.settings, width: 44, tooltip: 'Configurações', onPressed: onSettings),
        ],
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.index, required this.onChanged});

  final int index;
  final ValueChanged<int> onChanged;

  static const _items = [
    (Icons.monitor_heart_outlined, 'PAINEL'),
    (Icons.grid_on, 'TABELAS'),
    (Icons.timer_outlined, 'ATIVIDADES'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
      decoration: const BoxDecoration(
        color: Px.header,
        border: Border(top: BorderSide(color: Colors.black, width: 4)),
      ),
      child: Row(
        children: [
          for (var i = 0; i < _items.length; i++)
            Expanded(
              child: Semantics(
                button: true,
                selected: i == index,
                label: _items[i].$2,
                child: ExcludeSemantics(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onChanged(i),
                    child: Container(
                      height: 60,
                      decoration: BoxDecoration(
                        color: i == index ? const Color(0xFF0F2A4A) : Colors.transparent,
                        border: Border(top: BorderSide(color: i == index ? Px.cyan : Colors.transparent, width: 4)),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(_items[i].$1, size: 22, color: i == index ? Px.cyan : const Color(0xFF8FA0D0)),
                          const SizedBox(height: 6),
                          Text(
                            _items[i].$2,
                            style: Px.p(8, color: i == index ? Px.cyan : const Color(0xFF8FA0D0), height: 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
