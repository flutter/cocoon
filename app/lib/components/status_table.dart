// Copyright (c) 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:html';

import 'package:angular2/angular2.dart';

@Component(
  selector: 'status-table',
  template: '''
<table>
  <tr>
    <th>&nbsp;</th>
    <th>b4k5n66h5v4j (abarth)</th>
    <th>n38595u55i95 (sethladd)</th>
    <th>4958dhe74282 (hixie)</th>
    <th>hh3g4749u47i (tvolkert)</th>
  </tr>
  <tr>
    <td>travis linux</td>
    <td class="task-successful">&nbsp;</td>
    <td class="task-failed">&nbsp;</td>
    <td class="task-underperformed">&nbsp;</td>
    <td class="task-skipped">&nbsp;</td>
  </tr>
  <tr>
    <td>travis linux</td>
    <td class="task-underperformed">&nbsp;</td>
    <td class="task-successful">&nbsp;</td>
    <td class="task-in-progress">&nbsp;</td>
    <td class="task-skipped">&nbsp;</td>
  </tr>
</table>
'''
)
class StatusTable implements OnInit {
  @override
  ngOnInit() async {
    String json = await HttpRequest.getString('/api/get-status');
    print(json);
  }
}
