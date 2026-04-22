import 'package:flutter_test/flutter_test.dart';
import 'package:runlini/app/theme/app_colors.dart';
import 'package:runlini/features/run_tracking/service/pace_color_mapper.dart';

void main() {
  group('PaceColorMapper', () {
    const mapper = PaceColorMapper();

    test('maps fast pace to volt green', () {
      expect(mapper.colorFor(230), AppColors.voltGreen);
    });

    test('maps steady pace to cyan', () {
      expect(mapper.colorFor(280), AppColors.cyan);
    });

    test('maps slower pace to electric red', () {
      expect(mapper.colorFor(380), AppColors.electricRed);
    });

    test('maps relative pace buckets against the run average', () {
      expect(
        mapper.colorForAverageRelative(
          paceSecPerKm: 330,
          averagePaceSecPerKm: 360,
        ),
        AppColors.voltGreen,
      );
      expect(
        mapper.colorForAverageRelative(
          paceSecPerKm: 360,
          averagePaceSecPerKm: 360,
        ),
        AppColors.amber,
      );
      expect(
        mapper.colorForAverageRelative(
          paceSecPerKm: 390,
          averagePaceSecPerKm: 360,
        ),
        AppColors.orange,
      );
      expect(
        mapper.colorForAverageRelative(
          paceSecPerKm: 430,
          averagePaceSecPerKm: 360,
        ),
        AppColors.electricRed,
      );
    });

    test('maps relative pace to a quantized gradient', () {
      expect(
        mapper.colorForRelativeGradient(
          paceSecPerKm: 306,
          baselinePaceSecPerKm: 360,
        ),
        AppColors.voltGreen,
      );
      expect(
        mapper.colorForRelativeGradient(
          paceSecPerKm: 360,
          baselinePaceSecPerKm: 360,
        ),
        AppColors.amber,
      );
      expect(
        mapper.colorForRelativeGradient(
          paceSecPerKm: 414,
          baselinePaceSecPerKm: 360,
        ),
        AppColors.electricRed,
      );

      final slightlyFast = mapper.colorForRelativeGradient(
        paceSecPerKm: 342,
        baselinePaceSecPerKm: 360,
      );
      final slightlySlow = mapper.colorForRelativeGradient(
        paceSecPerKm: 378,
        baselinePaceSecPerKm: 360,
      );
      expect(slightlyFast, isNot(AppColors.voltGreen));
      expect(slightlyFast, isNot(AppColors.amber));
      expect(slightlySlow, isNot(AppColors.amber));
      expect(slightlySlow, isNot(AppColors.electricRed));
      expect(slightlyFast, isNot(slightlySlow));
    });

    test('maps invalid gradient pace to chalk', () {
      expect(
        mapper.colorForRelativeGradient(
          paceSecPerKm: null,
          baselinePaceSecPerKm: 360,
        ),
        AppColors.chalk,
      );
      expect(
        mapper.colorForRelativeGradient(
          paceSecPerKm: 360,
          baselinePaceSecPerKm: 0,
        ),
        AppColors.chalk,
      );
    });
  });
}
