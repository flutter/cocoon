import 'package:angular/angular.dart';
import 'package:cocoon/build/common.dart';
import 'package:cocoon/models.dart';

@Component(
  selector: 'task-guide',
  templateUrl: 'task_guide.html',
  styleUrls: ['task_guide.css'],
  directives: [NgFor, NgIf],
)
class TaskGuideComponent extends ComponentState {
  HeaderRow get headerRow => _headerRow;
  HeaderRow _headerRow;
  @Input()
  set headerRow(HeaderRow value) {
    if (value == _headerRow) return;
    _headerRow = value;
    deliverStateChanges(); // ignore: deprecated_member_use
  }

  List<BuildStatus> get headerCol => _headerCol;
  List<BuildStatus> _headerCol;
  @Input()
  set headerCol(List<BuildStatus> value) {
    if (value == headerCol) return;
    _headerCol = value;
    deliverStateChanges(); // ignore: deprecated_member_use
  }
}
