import 'package:angular/angular.dart';

@Component(
  selector: 'legend',
  templateUrl: 'legend.html',
  directives: const [
    NgIf,
  ],
)
class LegendComponent extends ComponentState {
  bool legendVisible = false;

  void toggleVisibility() {
    setState(() {
      legendVisible = !legendVisible;
    });
  }
}
