import 'package:flutter_test/flutter_test.dart';
import 'package:tarpuy/data/app_state.dart';
import 'package:tarpuy/data/models.dart';

void main() {
  test(
    'Parcela, tareas, escenario y estrategias sobreviven a recrear el estado',
    () {
      final a = AppState();
      a.savePlot(
        Plot(
          name: 'Ensayo local',
          department: 'Cusco',
          province: 'Cusco',
          district: 'Cusco',
          latitude: -13.5,
          longitude: -71.9,
          area: 2,
          updatedAt: DateTime.utc(2025),
        ),
      );
      a.addTask('Medir pH', DateTime(2025, 10, 10));
      a.toggleTask(a.tasks.single);
      a.savePlan([crops[1], crops[2]], 10, false);
      a.toggleStrategy('Cultivos de cobertura');
      a.dispose();
      final b = AppState();
      expect(b.plot!.name, 'Ensayo local');
      expect(b.plot!.ph, isNull);
      expect(b.tasks.single.done, isTrue);
      expect(b.tasks.single.name, 'Medir pH');
      expect(b.rotation.map((c) => c.name), ['Quinua', 'Haba']);
      expect(b.years, 10);
      expect(b.cover, isFalse);
      expect(b.strategies, contains('Cultivos de cobertura'));
      b.dispose();
    },
  );
}
