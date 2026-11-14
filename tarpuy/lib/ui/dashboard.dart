import 'package:flutter/material.dart';
import '../data/app_state.dart';
import '../data/models.dart';
import 'widgets.dart';

class Dashboard extends StatelessWidget {
  final AppState state;
  final void Function(int) navigate;
  const Dashboard({super.key, required this.state, required this.navigate});
  @override
  Widget build(BuildContext context) {
    final plot = state.plot;
    String value(String key) {
      final m = state.weather?.latest(key);
      return m == null ? '—' : '${m.value!.toStringAsFixed(1)} ${m.unit}';
    }

    String source(String key) {
      final m = state.weather?.latest(key);
      return m == null
          ? 'Sin consulta · NASA POWER'
          : 'NASA POWER · estimado regional\n${dateLabel(m.observationDate)} · consulta ${dateLabel(m.fetchedAt)}';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          spacing: 20,
          runSpacing: 12,
          children: [
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cada siembra, un nuevo futuro.',
                  style: TextStyle(
                    fontSize: 29,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -1,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Tu tierra tiene mucho que contarte. Escuchémosla.',
                  style: TextStyle(fontSize: 12, color: muted),
                ),
              ],
            ),
            OutlinedButton.icon(
              onPressed: () => navigate(1),
              icon: const Icon(Icons.location_on_outlined, size: 16),
              label: Text(plot == null ? 'Registrar mi terreno' : plot.name),
            ),
          ],
        ),
        const SizedBox(height: 26),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 280),
            child: Stack(
              children: [
                Positioned.fill(child: CustomPaint(painter: Andes())),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          forest.withValues(alpha: .97),
                          forest.withValues(alpha: .64),
                          Colors.transparent,
                        ],
                        stops: const [0, .47, 1],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(28),
                  child: SizedBox(
                    width: 490,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Tag('DE LOS ANDES AL ESPACIO', color: lime),
                        const SizedBox(height: 16),
                        const Text(
                          'Conoce tu tierra.\nCultiva su potencial.',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 31,
                            height: 1.12,
                            letterSpacing: -.8,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Ciencia de la NASA y saber agrícola,\nal servicio de cada decisión.',
                          style: TextStyle(
                            color: Color(0xFFCFDBCA),
                            fontSize: 12,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            foregroundColor: lime,
                            padding: EdgeInsets.zero,
                          ),
                          onPressed: () => navigate(plot == null ? 1 : 5),
                          label: Text(
                            plot == null
                                ? 'Comenzar con mi parcela'
                                : 'Explorar observaciones',
                          ),
                          icon: const Icon(Icons.arrow_forward, size: 17),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            const Expanded(
              child: Text(
                'El pulso de tu terreno',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
            TextButton.icon(
              onPressed: plot == null || state.loading
                  ? null
                  : state.recentWeather,
              icon: state.loading
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh, size: 16),
              label: Text(
                state.loading ? 'Consultando…' : 'Consultar NASA',
                style: const TextStyle(fontSize: 11),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ResponsiveGrid(
          minWidth: 195,
          children: [
            Metric(
              'Temperatura media diaria',
              value('T2M'),
              source('T2M'),
              Icons.thermostat_outlined,
            ),
            Metric(
              'Precipitación diaria',
              value('PRECTOTCORR'),
              source('PRECTOTCORR'),
              Icons.water_drop_outlined,
            ),
            Metric(
              'Humedad del suelo',
              'Pendiente',
              'SMAP sin conectar\nRequiere sensor o estimación regional',
              Icons.waves,
            ),
            Metric(
              'Radiación solar diaria',
              value('ALLSKY_SFC_SW_DWN'),
              source('ALLSKY_SFC_SW_DWN'),
              Icons.wb_sunny_outlined,
            ),
          ],
        ),
        if (state.error != null) Notice(state.error!),
        if (plot == null)
          const Notice(
            'Registra tu parcela para consultar datos por coordenadas. No se muestran mediciones de ejemplo.',
          ),
        const SizedBox(height: 24),
        LayoutBuilder(
          builder: (context, box) {
            final climate = Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Una mirada al clima',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Tag('NASA POWER'),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Temperatura media diaria · serie consultada',
                    style: TextStyle(fontSize: 11, color: muted),
                  ),
                  const SizedBox(height: 25),
                  ClimateChart(
                    data: state.weather?.measurements ?? [],
                    variable: 'T2M',
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Estimaciones regionales · no es un pronóstico meteorológico.',
                    style: TextStyle(fontSize: 10, color: muted),
                  ),
                ],
              ),
            );
            final profile = Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.landscape_outlined, color: green),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Tu parcela, en contexto',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    height: 145,
                    child: plot == null
                        ? Container(
                            decoration: BoxDecoration(
                              color: cream,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.add_location_alt_outlined,
                                size: 40,
                                color: muted,
                              ),
                            ),
                          )
                        : PlotMap(
                            latitude: plot.latitude,
                            longitude: plot.longitude,
                          ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    plot?.name ?? 'Aquí empieza tu historia',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    plot == null
                        ? 'Ubica tu terreno y crea su perfil agrícola.'
                        : '${plot.district}, ${plot.department}\n${plot.area} ha · ${plot.region}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: muted,
                      height: 1.7,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => navigate(1),
                    child: Text(
                      plot == null
                          ? 'Registrar parcela →'
                          : 'Ver perfil del terreno →',
                    ),
                  ),
                ],
              ),
            );
            return box.maxWidth > 760
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: climate),
                      const SizedBox(width: 20),
                      Expanded(flex: 2, child: profile),
                    ],
                  )
                : Column(
                    children: [climate, const SizedBox(height: 16), profile],
                  );
          },
        ),
        const SizedBox(height: 24),
        ResponsiveGrid(
          minWidth: 310,
          children: [
            Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Próximos pasos',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),
                  if (state.tasks.where((t) => !t.done).isEmpty)
                    const Text(
                      'Crea tu primera actividad en el calendario.',
                      style: TextStyle(color: muted, fontSize: 12),
                    ),
                  ...state.tasks
                      .where((t) => !t.done)
                      .take(3)
                      .map(
                        (t) => CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          value: t.done,
                          onChanged: (_) => state.toggleTask(t),
                          title: Text(
                            t.name,
                            style: const TextStyle(fontSize: 12),
                          ),
                          subtitle: Text(
                            dateLabel(t.date),
                            style: const TextStyle(fontSize: 10),
                          ),
                        ),
                      ),
                  TextButton(
                    onPressed: () => navigate(2),
                    child: const Text('Abrir calendario →'),
                  ),
                ],
              ),
            ),
            Panel(
              color: const Color(0xFFEBEFDF),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Tag('CULTIVAR TAMBIÉN ES REGENERAR'),
                  const SizedBox(height: 16),
                  const Text(
                    'Una rotación puede\ncambiar tu suelo.',
                    style: TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Explora diversidad, cobertura y uso del agua con escenarios transparentes.',
                    style: TextStyle(color: muted, fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: () => navigate(3),
                    icon: const Icon(Icons.arrow_forward, size: 17),
                    label: const Text('Diseñar mi rotación'),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Notice(
          'Salud del suelo, vegetación y alertas climáticas: pendientes de mediciones o conectores específicos. NASA POWER aporta historia climática regional; no permite descartar riesgos futuros.',
        ),
      ],
    );
  }
}
