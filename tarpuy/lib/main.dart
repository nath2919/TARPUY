import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'data/app_state.dart';
import 'ui/widgets.dart';
import 'ui/dashboard.dart';
import 'ui/plot_screen.dart';
import 'ui/modules.dart';

void main() => runApp(const TarpuyApp());

class TarpuyApp extends StatelessWidget {
  const TarpuyApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'TARPUY · Inteligencia agrícola',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: cream,
      colorScheme: ColorScheme.fromSeed(
        seedColor: forest,
        primary: forest,
        secondary: green,
        surface: Colors.white,
      ),
      fontFamily: 'Arial',
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: ink, height: 1.5),
        titleLarge: TextStyle(color: ink, fontWeight: FontWeight.w600),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF7F8F3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFDCE3D8)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFDCE3D8)),
        ),
        contentPadding: const EdgeInsets.all(15),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    ),
    home: const TarpuyShell(),
  );
}

const pages = [
  'Dashboard',
  'Mi terreno',
  'Calendario agrícola',
  'Simulador de rotación',
  'Agricultura regenerativa',
  'Observación NASA',
  'Economía agrícola',
  'Calendario astronómico',
  'Asistente TARPUY',
  'Impacto ambiental',
];
const pageIcons = [
  Icons.space_dashboard_outlined,
  Icons.landscape_outlined,
  Icons.calendar_month_outlined,
  Icons.autorenew,
  Icons.eco_outlined,
  Icons.satellite_alt,
  Icons.insights,
  Icons.nightlight_outlined,
  Icons.auto_awesome_outlined,
  Icons.public,
];

class TarpuyShell extends StatefulWidget {
  const TarpuyShell({super.key});
  @override
  State<TarpuyShell> createState() => _TarpuyShellState();
}

class _TarpuyShellState extends State<TarpuyShell> {
  final state = AppState();
  int selected = 0;
  final scaffold = GlobalKey<ScaffoldState>();
  @override
  void dispose() {
    state.dispose();
    super.dispose();
  }

  void navigate(int i) {
    setState(() => selected = i);
    scaffold.currentState?.closeDrawer();
  }

  Widget sidebar() => Container(
    width: 244,
    color: forest,
    child: SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(28, 32, 20, 32),
            child: Row(
              children: [
                Icon(Icons.spa_outlined, color: lime, size: 33),
                SizedBox(width: 10),
                Text(
                  'TARPUY',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(left: 28, bottom: 16),
            child: Text(
              'TU ECOSISTEMA AGRÍCOLA',
              style: TextStyle(
                color: Color(0xFF8DAE9B),
                fontSize: 9,
                letterSpacing: 1.8,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              itemCount: pages.length,
              itemBuilder: (context, i) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Material(
                  color: selected == i ? lime : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                  child: ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 2,
                    ),
                    leading: Icon(
                      pageIcons[i],
                      size: 20,
                      color: selected == i ? forest : const Color(0xFFADBFAD),
                    ),
                    title: Text(
                      pages[i],
                      style: TextStyle(
                        fontSize: 12,
                        color: selected == i ? forest : const Color(0xFFD2DED2),
                        fontWeight: selected == i
                            ? FontWeight.w700
                            : FontWeight.w400,
                      ),
                    ),
                    onTap: () => navigate(i),
                  ),
                ),
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(17),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: .1)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.grass, color: lime),
                SizedBox(height: 9),
                Text(
                  'El futuro echa raíces.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 7),
                Text(
                  'Conocimiento de la tierra.\nPerspectiva desde el espacio.',
                  style: TextStyle(
                    color: Color(0xFFABC1AF),
                    fontSize: 11,
                    height: 1.7,
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(28, 4, 20, 24),
            child: Text(
              'HECHO PARA NUESTRA TIERRA  ↗',
              style: TextStyle(
                color: Color(0xFF8DAE9B),
                fontSize: 9,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    ),
  );
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: state,
    builder: (context, _) {
      final wide = MediaQuery.sizeOf(context).width >= 1050;
      final screen = switch (selected) {
        0 => Dashboard(state: state, navigate: navigate),
        1 => PlotScreen(state: state),
        2 => CalendarScreen(state: state),
        3 => RotationScreen(state: state),
        4 => RegenerationScreen(state: state),
        5 => NasaScreen(state: state),
        6 => EconomyScreen(state: state),
        7 => AstronomyScreen(state: state),
        8 => AssistantScreen(state: state),
        _ => ImpactScreen(state: state),
      };
      return Scaffold(
        key: scaffold,
        drawer: wide ? null : Drawer(width: 244, child: sidebar()),
        body: Row(
          children: [
            if (wide) sidebar(),
            Expanded(
              child: Column(
                children: [
                  Container(
                    height: 76,
                    padding: EdgeInsets.symmetric(horizontal: wide ? 34 : 16),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        bottom: BorderSide(color: Color(0xFFE8ECE4)),
                      ),
                    ),
                    child: Row(
                      children: [
                        if (!wide)
                          IconButton(
                            tooltip: 'Abrir navegación',
                            onPressed: () =>
                                scaffold.currentState?.openDrawer(),
                            icon: const Icon(Icons.menu),
                          ),
                        Expanded(
                          child: Text(
                            'Mi espacio  /  ${pages[selected]}',
                            style: const TextStyle(fontSize: 12, color: muted),
                          ),
                        ),
                        if (wide) const Tag('AGRICULTURA CON PROPÓSITO'),
                        const SizedBox(width: 18),
                        Tooltip(
                          message: 'Datos guardados en este navegador',
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: const BoxDecoration(
                              color: Color(0xFFE7EDDF),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.person_outline,
                              size: 20,
                              color: forest,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      key: ValueKey(selected),
                      padding: EdgeInsets.all(wide ? 34 : 18),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1400),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (selected != 0) ...[
                                Text(
                                  pages[selected],
                                  style: const TextStyle(
                                    fontSize: 30,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: -1,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Inteligencia agrícola para sembrar hoy, regenerar mañana.',
                                  style: TextStyle(color: muted, fontSize: 12),
                                ),
                                const SizedBox(height: 26),
                              ],
                              if (state.storageError != null)
                                Notice(state.storageError!),
                              screen,
                              const SizedBox(height: 32),
                              const Divider(color: Color(0xFFE0E6DB)),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 24,
                                runSpacing: 8,
                                alignment: WrapAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'TARPUY © 2026 · Sembrar para producir, cultivar para regenerar.',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: muted,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () => showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text(
                                          'Tus datos y las fuentes',
                                        ),
                                        content: const SingleChildScrollView(
                                          child: Text(
                                            'Esta versión guarda la parcela, tareas y planes en el navegador. No dispone de cuentas ni sincronización en la nube. NASA POWER se consulta solo bajo solicitud, mediante un servidor local. Las otras fuentes satelitales están pendientes. Los resultados de rotación son modelos didácticos sin calibrar. El asistente utiliza reglas locales; no hay un modelo de IA conectado.\n\nPuedes copiar un respaldo de tu parcela desde Mi terreno.',
                                          ),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context),
                                            child: const Text('Entendido'),
                                          ),
                                        ],
                                      ),
                                    ),
                                    child: const Text(
                                      'Datos y transparencia',
                                      style: TextStyle(fontSize: 10),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}

Future<void> copyText(BuildContext context, String text) async {
  try {
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Copiado al portapapeles')));
    }
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo acceder al portapapeles')),
      );
    }
  }
}
