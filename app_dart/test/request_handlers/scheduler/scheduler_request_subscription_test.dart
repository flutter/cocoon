// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:cocoon_service/cocoon_service.dart';
import 'package:cocoon_service/src/model/luci/pubsub_message_v2.dart';
import 'package:cocoon_service/src/request_handlers/scheduler/scheduler_request_subscription.dart';
import 'package:cocoon_service/src/request_handling/exceptions.dart';
import 'package:fixnum/fixnum.dart';
import 'package:mockito/mockito.dart';
import 'package:retry/retry.dart';
import 'package:test/test.dart';
import 'package:buildbucket/buildbucket_pb.dart' as bbv2;

import '../../src/datastore/fake_config.dart';
import '../../src/request_handling/fake_authentication.dart';
import '../../src/request_handling/fake_http.dart';
import '../../src/request_handling/subscription_v2_tester.dart';
import '../../src/utilities/mocks.dart';

void main() {
  late SchedulerRequestSubscriptionV2 handler;
  late SubscriptionV2Tester tester;

  late MockBuildBucketV2Client buildBucketV2Client;

  setUp(() async {
    buildBucketV2Client = MockBuildBucketV2Client();
    handler = SchedulerRequestSubscriptionV2(
      cache: CacheService(inMemory: true),
      config: FakeConfig(),
      authProvider: FakeAuthenticationProvider(),
      buildBucketClient: buildBucketV2Client,
      retryOptions: const RetryOptions(
        maxAttempts: 3,
        maxDelay: Duration.zero,
      ),
    );

    tester = SubscriptionV2Tester(
      request: FakeHttpRequest(),
    );
  });

  test('throws exception when BatchRequest cannot be decoded', () async {
    tester.message = const PushMessageV2();
    expect(() => tester.post(handler), throwsA(isA<BadRequestException>()));
  });

  test('Push Message v2 decoding', () {
    // we get this after calling utf8 decode and transforming into messagev2
    // object comes in proto 3 form.
    const String message = '''
      {"message":{"data":"eyJyZXF1ZXN0cyI6W3sic2NoZWR1bGVCdWlsZCI6eyJidWlsZGVyIjp7InByb2plY3QiOiJmbHV0dGVyIiwiYnVja2V0IjoidHJ5IiwiYnVpbGRlciI6IkxpbnV4IHdlYl9jYW52YXNraXRfdGVzdHNfNSJ9LCJwcm9wZXJ0aWVzIjp7ImRlcGVuZGVuY2llcyI6W3siZGVwZW5kZW5jeSI6ImN1cmwiLCJ2ZXJzaW9uIjoidmVyc2lvbjo3LjY0LjAifSx7ImRlcGVuZGVuY3kiOiJhbmRyb2lkX3NkayIsInZlcnNpb24iOiJ2ZXJzaW9uOjMzdjYifSx7ImRlcGVuZGVuY3kiOiJjaHJvbWVfYW5kX2RyaXZlciIsInZlcnNpb24iOiJ2ZXJzaW9uOjExOS4wLjYwNDUuOSJ9LHsiZGVwZW5kZW5jeSI6ImdvbGRjdGwiLCJ2ZXJzaW9uIjoiZ2l0X3JldmlzaW9uOjcyMGE1NDJmNmZlNGY5MjkyMmMzYjhmMGZkY2M0ZDJhYzZiYjgzY2QifV0sIm9zIjoiVWJ1bnR1IiwiY29yZXMiOjgsImRldmljZV90eXBlIjoibm9uZSIsInNoYXJkIjoid2ViX2NhbnZhc2tpdF90ZXN0cyIsInN1YnNoYXJkIjo1LCJ0YWdzIjpbImZyYW1ld29yayIsImhvc3Rvbmx5Iiwic2hhcmQiLCJsaW51eCJdLCJwcmVzdWJtaXRfbWF4X2F0dGVtcHRzIjoyLCJicmluZ3VwIjpmYWxzZSwiZ2l0X2JyYW5jaCI6Im1hc3RlciIsImdpdF91cmwiOiJodHRwczovL2dpdGh1Yi5jb20vZmx1dHRlci9mbHV0dGVyIiwiZ2l0X3JlZiI6InJlZnMvcHVsbC8xMzczODgvaGVhZCIsImV4ZV9jaXBkX3ZlcnNpb24iOiJyZWZzL2hlYWRzL21haW4ifSwidGFncyI6W3sia2V5IjoiZ2l0aHViX2NoZWNrcnVuIiwidmFsdWUiOiIxODI4MzE0MDI2OSJ9LHsia2V5IjoiYnVpbGRzZXQiLCJ2YWx1ZSI6InByL2dpdC8xMzczODgifSx7ImtleSI6ImJ1aWxkc2V0IiwidmFsdWUiOiJzaGEvZ2l0LzI1NjkxZjcwMjA3NzEyZTYzNTQyN2U2YmMzYzQ0ZGQ3OWFhYTQzOWUifSx7ImtleSI6InVzZXJfYWdlbnQiLCJ2YWx1ZSI6ImZsdXR0ZXItY29jb29uIn0seyJrZXkiOiJnaXRodWJfbGluayIsInZhbHVlIjoiaHR0cHM6Ly9naXRodWIuY29tL2ZsdXR0ZXIvZmx1dHRlci9wdWxsLzEzNzM4OCJ9LHsia2V5IjoiY2lwZF92ZXJzaW9uIiwidmFsdWUiOiJyZWZzL2hlYWRzL21haW4ifV0sImRpbWVuc2lvbnMiOlt7ImtleSI6Im9zIiwidmFsdWUiOiJVYnVudHUifSx7ImtleSI6ImRldmljZV90eXBlIiwidmFsdWUiOiJub25lIn0seyJrZXkiOiJjb3JlcyIsInZhbHVlIjoiOCJ9XSwibm90aWZ5Ijp7InB1YnN1YlRvcGljIjoicHJvamVjdHMvZmx1dHRlci1kYXNoYm9hcmQvdG9waWNzL2x1Y2ktYnVpbGRzIiwidXNlckRhdGEiOiJaWGxLYVdSWGJITmFSMVo1V0RJMWFHSlhWV2xQYVVwTllWYzFNV1ZEUWpOYVYwcG1XVEpHZFdSdFJucGhNbXd3V0ROU2JHTXpVbnBZZWxWcFRFTkthbUZIVm1waE1UbDVaRmMxWm1GWFVXbFBha1UwVFdwbmVrMVVVWGROYWxrMVRFTkthbUl5TVhSaFdGSm1ZekpvYUVscWIybE5hbFV5VDFSR2JVNTZRWGxOUkdNelRWUktiRTVxVFRGT1JFa3pXbFJhYVZsNlRtcE9SRkpyV2tSak5WbFhSbWhPUkUwMVdsTkpjMGx0VG5aaVZ6RndaRVk1YVdOdFJuVlpNbWRwVDJsS2RGbFlUakJhV0VscFRFTktlVnBZUW5aWU1qa3pZbTFXZVVscWIybGFiWGd4WkVoU2JHTnBTWE5KYmtwc1kwYzVabUp0Um5SYVUwazJTVzFhYzJSWVVqQmFXRWxwVEVOS01XTXlWbmxZTWtadVdsYzFNRWxxYjJsYWJYZ3haRWhTYkdOcE1XcGlNazUyWWpJMGFXWlJQVDA9In0sImZpZWxkcyI6ImlkLGJ1aWxkZXIsbnVtYmVyLHN0YXR1cyx0YWdzIiwiZXhlIjp7ImNpcGRWZXJzaW9uIjoicmVmcy9oZWFkcy9tYWluIn19fSx7InNjaGVkdWxlQnVpbGQiOnsiYnVpbGRlciI6eyJwcm9qZWN0IjoiZmx1dHRlciIsImJ1Y2tldCI6InRyeSIsImJ1aWxkZXIiOiJMaW51eCB3ZWJfY2FudmFza2l0X3Rlc3RzXzYifSwicHJvcGVydGllcyI6eyJkZXBlbmRlbmNpZXMiOlt7ImRlcGVuZGVuY3kiOiJjdXJsIiwidmVyc2lvbiI6InZlcnNpb246Ny42NC4wIn0seyJkZXBlbmRlbmN5IjoiYW5kcm9pZF9zZGsiLCJ2ZXJzaW9uIjoidmVyc2lvbjozM3Y2In0seyJkZXBlbmRlbmN5IjoiY2hyb21lX2FuZF9kcml2ZXIiLCJ2ZXJzaW9uIjoidmVyc2lvbjoxMTkuMC42MDQ1LjkifSx7ImRlcGVuZGVuY3kiOiJnb2xkY3RsIiwidmVyc2lvbiI6ImdpdF9yZXZpc2lvbjo3MjBhNTQyZjZmZTRmOTI5MjJjM2I4ZjBmZGNjNGQyYWM2YmI4M2NkIn1dLCJvcyI6IlVidW50dSIsImNvcmVzIjo4LCJkZXZpY2VfdHlwZSI6Im5vbmUiLCJzaGFyZCI6IndlYl9jYW52YXNraXRfdGVzdHMiLCJzdWJzaGFyZCI6NiwidGFncyI6WyJmcmFtZXdvcmsiLCJob3N0b25seSIsInNoYXJkIiwibGludXgiXSwicHJlc3VibWl0X21heF9hdHRlbXB0cyI6MiwiYnJpbmd1cCI6ZmFsc2UsImdpdF9icmFuY2giOiJtYXN0ZXIiLCJnaXRfdXJsIjoiaHR0cHM6Ly9naXRodWIuY29tL2ZsdXR0ZXIvZmx1dHRlciIsImdpdF9yZWYiOiJyZWZzL3B1bGwvMTM3Mzg4L2hlYWQiLCJleGVfY2lwZF92ZXJzaW9uIjoicmVmcy9oZWFkcy9tYWluIn0sInRhZ3MiOlt7ImtleSI6ImdpdGh1Yl9jaGVja3J1biIsInZhbHVlIjoiMTgyODMxNDAzNzYifSx7ImtleSI6ImJ1aWxkc2V0IiwidmFsdWUiOiJwci9naXQvMTM3Mzg4In0seyJrZXkiOiJidWlsZHNldCIsInZhbHVlIjoic2hhL2dpdC8yNTY5MWY3MDIwNzcxMmU2MzU0MjdlNmJjM2M0NGRkNzlhYWE0MzllIn0seyJrZXkiOiJ1c2VyX2FnZW50IiwidmFsdWUiOiJmbHV0dGVyLWNvY29vbiJ9LHsia2V5IjoiZ2l0aHViX2xpbmsiLCJ2YWx1ZSI6Imh0dHBzOi8vZ2l0aHViLmNvbS9mbHV0dGVyL2ZsdXR0ZXIvcHVsbC8xMzczODgifSx7ImtleSI6ImNpcGRfdmVyc2lvbiIsInZhbHVlIjoicmVmcy9oZWFkcy9tYWluIn1dLCJkaW1lbnNpb25zIjpbeyJrZXkiOiJvcyIsInZhbHVlIjoiVWJ1bnR1In0seyJrZXkiOiJkZXZpY2VfdHlwZSIsInZhbHVlIjoibm9uZSJ9LHsia2V5IjoiY29yZXMiLCJ2YWx1ZSI6IjgifV0sIm5vdGlmeSI6eyJwdWJzdWJUb3BpYyI6InByb2plY3RzL2ZsdXR0ZXItZGFzaGJvYXJkL3RvcGljcy9sdWNpLWJ1aWxkcyIsInVzZXJEYXRhIjoiWlhsS2FXUlhiSE5hUjFaNVdESTFhR0pYVldsUGFVcE5ZVmMxTVdWRFFqTmFWMHBtV1RKR2RXUnRSbnBoTW13d1dETlNiR016VW5wWWVsbHBURU5LYW1GSFZtcGhNVGw1WkZjMVptRlhVV2xQYWtVMFRXcG5lazFVVVhkTmVtTXlURU5LYW1JeU1YUmhXRkptWXpKb2FFbHFiMmxOYWxVeVQxUkdiVTU2UVhsTlJHTXpUVlJLYkU1cVRURk9SRWt6V2xSYWFWbDZUbXBPUkZKcldrUmpOVmxYUm1oT1JFMDFXbE5KYzBsdFRuWmlWekZ3WkVZNWFXTnRSblZaTW1kcFQybEtkRmxZVGpCYVdFbHBURU5LZVZwWVFuWllNamt6WW0xV2VVbHFiMmxhYlhneFpFaFNiR05wU1hOSmJrcHNZMGM1Wm1KdFJuUmFVMGsyU1cxYWMyUllVakJhV0VscFRFTktNV015Vm5sWU1rWnVXbGMxTUVscWIybGFiWGd4WkVoU2JHTnBNV3BpTWs1MllqSTBhV1pSUFQwPSJ9LCJmaWVsZHMiOiJpZCxidWlsZGVyLG51bWJlcixzdGF0dXMsdGFncyIsImV4ZSI6eyJjaXBkVmVyc2lvbiI6InJlZnMvaGVhZHMvbWFpbiJ9fX0seyJzY2hlZHVsZUJ1aWxkIjp7ImJ1aWxkZXIiOnsicHJvamVjdCI6ImZsdXR0ZXIiLCJidWNrZXQiOiJ0cnkiLCJidWlsZGVyIjoiTGludXggd2ViX2NhbnZhc2tpdF90ZXN0c183X2xhc3QifSwicHJvcGVydGllcyI6eyJkZXBlbmRlbmNpZXMiOlt7ImRlcGVuZGVuY3kiOiJjdXJsIiwidmVyc2lvbiI6InZlcnNpb246Ny42NC4wIn0seyJkZXBlbmRlbmN5IjoiYW5kcm9pZF9zZGsiLCJ2ZXJzaW9uIjoidmVyc2lvbjozM3Y2In0seyJkZXBlbmRlbmN5IjoiY2hyb21lX2FuZF9kcml2ZXIiLCJ2ZXJzaW9uIjoidmVyc2lvbjoxMTkuMC42MDQ1LjkifSx7ImRlcGVuZGVuY3kiOiJnb2xkY3RsIiwidmVyc2lvbiI6ImdpdF9yZXZpc2lvbjo3MjBhNTQyZjZmZTRmOTI5MjJjM2I4ZjBmZGNjNGQyYWM2YmI4M2NkIn1dLCJvcyI6IlVidW50dSIsImNvcmVzIjo4LCJkZXZpY2VfdHlwZSI6Im5vbmUiLCJzaGFyZCI6IndlYl9jYW52YXNraXRfdGVzdHMiLCJzdWJzaGFyZCI6IjdfbGFzdCIsInRhZ3MiOlsiZnJhbWV3b3JrIiwiaG9zdG9ubHkiLCJzaGFyZCIsImxpbnV4Il0sInByZXN1Ym1pdF9tYXhfYXR0ZW1wdHMiOjIsImJyaW5ndXAiOmZhbHNlLCJnaXRfYnJhbmNoIjoibWFzdGVyIiwiZ2l0X3VybCI6Imh0dHBzOi8vZ2l0aHViLmNvbS9mbHV0dGVyL2ZsdXR0ZXIiLCJnaXRfcmVmIjoicmVmcy9wdWxsLzEzNzM4OC9oZWFkIiwiZXhlX2NpcGRfdmVyc2lvbiI6InJlZnMvaGVhZHMvbWFpbiJ9LCJ0YWdzIjpbeyJrZXkiOiJnaXRodWJfY2hlY2tydW4iLCJ2YWx1ZSI6IjE4MjgzMTQwNDk1In0seyJrZXkiOiJidWlsZHNldCIsInZhbHVlIjoicHIvZ2l0LzEzNzM4OCJ9LHsia2V5IjoiYnVpbGRzZXQiLCJ2YWx1ZSI6InNoYS9naXQvMjU2OTFmNzAyMDc3MTJlNjM1NDI3ZTZiYzNjNDRkZDc5YWFhNDM5ZSJ9LHsia2V5IjoidXNlcl9hZ2VudCIsInZhbHVlIjoiZmx1dHRlci1jb2Nvb24ifSx7ImtleSI6ImdpdGh1Yl9saW5rIiwidmFsdWUiOiJodHRwczovL2dpdGh1Yi5jb20vZmx1dHRlci9mbHV0dGVyL3B1bGwvMTM3Mzg4In0seyJrZXkiOiJjaXBkX3ZlcnNpb24iLCJ2YWx1ZSI6InJlZnMvaGVhZHMvbWFpbiJ9XSwiZGltZW5zaW9ucyI6W3sia2V5Ijoib3MiLCJ2YWx1ZSI6IlVidW50dSJ9LHsia2V5IjoiZGV2aWNlX3R5cGUiLCJ2YWx1ZSI6Im5vbmUifSx7ImtleSI6ImNvcmVzIiwidmFsdWUiOiI4In1dLCJub3RpZnkiOnsicHVic3ViVG9waWMiOiJwcm9qZWN0cy9mbHV0dGVyLWRhc2hib2FyZC90b3BpY3MvbHVjaS1idWlsZHMiLCJ1c2VyRGF0YSI6IlpYbEthV1JYYkhOYVIxWjVXREkxYUdKWFZXbFBhVXBOWVZjMU1XVkRRak5hVjBwbVdUSkdkV1J0Um5waE1td3dXRE5TYkdNelVucFllbVJtWWtkR2VtUkRTWE5KYlU1dldsZE9jbGd6U2pGaWJEbHdXa05KTmsxVVozbFBSRTE0VGtSQk1FOVVWWE5KYlU1MllsY3hjR1JHT1hwaFIwVnBUMmxKZVU1VVdUVk5WMWt6VFVSSmQwNTZZM2hOYlZVeVRYcFZNRTFxWkd4T2JVcHFUVEpOTUU1SFVtdE9lbXhvV1ZkRk1FMTZiR3hKYVhkcFdUSTVkR0pYYkRCWU1rcDVXVmMxYW1GRFNUWkpiVEZvWXpOU2JHTnBTWE5KYmtwc1kwYzVabUl6WkhWYVdFbHBUMmxLYldKSVZqQmtSMVo1U1dsM2FXTnRWbmRpTVRsMVdWY3hiRWxxYjJsYWJYZ3haRWhTYkdOcFNYTkpibFo2V2xoS1psbFhaR3hpYmxGcFQybEtiV0pJVmpCa1IxWjVURmRPZGxreU9YWmlhVW81In0sImZpZWxkcyI6ImlkLGJ1aWxkZXIsbnVtYmVyLHN0YXR1cyx0YWdzIiwiZXhlIjp7ImNpcGRWZXJzaW9uIjoicmVmcy9oZWFkcy9tYWluIn19fSx7InNjaGVkdWxlQnVpbGQiOnsiYnVpbGRlciI6eyJwcm9qZWN0IjoiZmx1dHRlciIsImJ1Y2tldCI6InRyeSIsImJ1aWxkZXIiOiJMaW51eF9hbmRyb2lkIGFuZHJvaWRfZGVmaW5lc190ZXN0In0sInByb3BlcnRpZXMiOnsiZGVwZW5kZW5jaWVzIjpbeyJkZXBlbmRlbmN5IjoiYW5kcm9pZF9zZGsiLCJ2ZXJzaW9uIjoidmVyc2lvbjozM3Y2In0seyJkZXBlbmRlbmN5Ijoib3Blbl9qZGsiLCJ2ZXJzaW9uIjoidmVyc2lvbjoxMSJ9LHsiZGVwZW5kZW5jeSI6ImN1cmwiLCJ2ZXJzaW9uIjoidmVyc2lvbjo3LjY0LjAifSx7ImRlcGVuZGVuY3kiOiJhbmRyb2lkX3ZpcnR1YWxfZGV2aWNlIiwidmVyc2lvbiI6IjM0In1dLCJvcyI6IkxpbnV4IiwiZGV2aWNlX3R5cGUiOiJub25lIiwidGFncyI6WyJkZXZpY2VsYWIiLCJsaW51eCJdLCJ0YXNrX25hbWUiOiJhbmRyb2lkX2RlZmluZXNfdGVzdCIsImJyaW5ndXAiOmZhbHNlLCJnaXRfYnJhbmNoIjoibWFzdGVyIiwiZ2l0X3VybCI6Imh0dHBzOi8vZ2l0aHViLmNvbS9mbHV0dGVyL2ZsdXR0ZXIiLCJnaXRfcmVmIjoicmVmcy9wdWxsLzEzNzM4OC9oZWFkIiwiZXhlX2NpcGRfdmVyc2lvbiI6InJlZnMvaGVhZHMvbWFpbiJ9LCJ0YWdzIjpbeyJrZXkiOiJnaXRodWJfY2hlY2tydW4iLCJ2YWx1ZSI6IjE4MjgzMTQwNjE2In0seyJrZXkiOiJidWlsZHNldCIsInZhbHVlIjoicHIvZ2l0LzEzNzM4OCJ9LHsia2V5IjoiYnVpbGRzZXQiLCJ2YWx1ZSI6InNoYS9naXQvMjU2OTFmNzAyMDc3MTJlNjM1NDI3ZTZiYzNjNDRkZDc5YWFhNDM5ZSJ9LHsia2V5IjoidXNlcl9hZ2VudCIsInZhbHVlIjoiZmx1dHRlci1jb2Nvb24ifSx7ImtleSI6ImdpdGh1Yl9saW5rIiwidmFsdWUiOiJodHRwczovL2dpdGh1Yi5jb20vZmx1dHRlci9mbHV0dGVyL3B1bGwvMTM3Mzg4In0seyJrZXkiOiJjaXBkX3ZlcnNpb24iLCJ2YWx1ZSI6InJlZnMvaGVhZHMvbWFpbiJ9XSwiZGltZW5zaW9ucyI6W3sia2V5Ijoib3MiLCJ2YWx1ZSI6IkxpbnV4In0seyJrZXkiOiJkZXZpY2VfdHlwZSIsInZhbHVlIjoibm9uZSJ9LHsia2V5Ijoia3ZtIiwidmFsdWUiOiIxIn0seyJrZXkiOiJjb3JlcyIsInZhbHVlIjoiOCJ9LHsia2V5IjoibWFjaGluZV90eXBlIiwidmFsdWUiOiJuMS1zdGFuZGFyZC04In1dLCJub3RpZnkiOnsicHVic3ViVG9waWMiOiJwcm9qZWN0cy9mbHV0dGVyLWRhc2hib2FyZC90b3BpY3MvbHVjaS1idWlsZHMiLCJ1c2VyRGF0YSI6IlpYbEthV1JYYkhOYVIxWjVXREkxYUdKWFZXbFBhVXBOWVZjMU1XVkdPV2hpYlZKNVlqSnNhMGxIUm5WYVNFcDJZVmRTWmxwSFZtMWhWelZzWXpFNU1GcFlUakJKYVhkcFdUSm9iRmt5ZEdaamJsWjFXREpzYTBscWIzaFBSRWswVFhwRk1FMUVXWGhPYVhkcFdUSTVkR0pYYkRCWU0wNXZXVk5KTmtscVNURk9hbXQ0V21wamQwMXFRVE5PZWtWNVdsUlplazVVVVhsT01sVXlXVzFOZWxsNlVUQmFSMUV6VDFkR2FGbFVVWHBQVjFWcFRFTkthbUl5TVhSaFdGSm1XVzVLYUdKdFRtOUphbTlwWWxkR2VtUkhWbmxKYVhkcFkyMVdkMkl4T1haa01qVnNZMmxKTmtsdFduTmtXRkl3V2xoSmFVeERTbmxhV0VKMldESTFhR0pYVldsUGFVcHRZa2hXTUdSSFZubEphWGRwWkZoT2JHTnNPV2hhTWxaMVpFTkpOa2x0V25Oa1dGSXdXbGhKZEZreU9XcGlNamwxU1c0d1BRPT0ifSwiZmllbGRzIjoiaWQsYnVpbGRlcixudW1iZXIsc3RhdHVzLHRhZ3MiLCJleGUiOnsiY2lwZFZlcnNpb24iOiJyZWZzL2hlYWRzL21haW4ifX19LHsic2NoZWR1bGVCdWlsZCI6eyJidWlsZGVyIjp7InByb2plY3QiOiJmbHV0dGVyIiwiYnVja2V0IjoidHJ5IiwiYnVpbGRlciI6Ik1hYyBidWlsZF90ZXN0c18xXzQifSwicHJvcGVydGllcyI6eyJkZXBlbmRlbmNpZXMiOlt7ImRlcGVuZGVuY3kiOiJhcHBsZV9zaWduaW5nIiwidmVyc2lvbiI6InZlcnNpb246dG9fMjAyNCJ9LHsiZGVwZW5kZW5jeSI6ImFuZHJvaWRfc2RrIiwidmVyc2lvbiI6InZlcnNpb246MzN2NiJ9LHsiZGVwZW5kZW5jeSI6ImNocm9tZV9hbmRfZHJpdmVyIiwidmVyc2lvbiI6InZlcnNpb246MTE5LjAuNjA0NS45In0seyJkZXBlbmRlbmN5Ijoib3Blbl9qZGsiLCJ2ZXJzaW9uIjoidmVyc2lvbjoxNyJ9LHsiZGVwZW5kZW5jeSI6InJ1YnkiLCJ2ZXJzaW9uIjoicnVieV8zLjEtcG9kXzEuMTMifSx7ImRlcGVuZGVuY3kiOiJnb2xkY3RsIiwidmVyc2lvbiI6ImdpdF9yZXZpc2lvbjo3MjBhNTQyZjZmZTRmOTI5MjJjM2I4ZjBmZGNjNGQyYWM2YmI4M2NkIn1dLCJvcyI6Ik1hYy0xMnxNYWMtMTMiLCJkZXZpY2VfdHlwZSI6Im5vbmUiLCIkZmx1dHRlci9vc3hfc2RrIjp7InNka192ZXJzaW9uIjoiMTRlMzAwYyJ9LCJhZGRfcmVjaXBlc19jcSI6dHJ1ZSwic2hhcmQiOiJidWlsZF90ZXN0cyIsInN1YnNoYXJkIjoiMV80IiwidGFncyI6WyJmcmFtZXdvcmsiLCJob3N0b25seSIsInNoYXJkIiwibWFjIl0sImJyaW5ndXAiOmZhbHNlLCJnaXRfYnJhbmNoIjoibWFzdGVyIiwiZ2l0X3VybCI6Imh0dHBzOi8vZ2l0aHViLmNvbS9mbHV0dGVyL2ZsdXR0ZXIiLCJnaXRfcmVmIjoicmVmcy9wdWxsLzEzNzM4OC9oZWFkIiwiZXhlX2NpcGRfdmVyc2lvbiI6InJlZnMvaGVhZHMvbWFpbiJ9LCJ0YWdzIjpbeyJrZXkiOiJnaXRodWJfY2hlY2tydW4iLCJ2YWx1ZSI6IjE4MjgzMTQwNzIxIn0seyJrZXkiOiJidWlsZHNldCIsInZhbHVlIjoicHIvZ2l0LzEzNzM4OCJ9LHsia2V5IjoiYnVpbGRzZXQiLCJ2YWx1ZSI6InNoYS9naXQvMjU2OTFmNzAyMDc3MTJlNjM1NDI3ZTZiYzNjNDRkZDc5YWFhNDM5ZSJ9LHsia2V5IjoidXNlcl9hZ2VudCIsInZhbHVlIjoiZmx1dHRlci1jb2Nvb24ifSx7ImtleSI6ImdpdGh1Yl9saW5rIiwidmFsdWUiOiJodHRwczovL2dpdGh1Yi5jb20vZmx1dHRlci9mbHV0dGVyL3B1bGwvMTM3Mzg4In0seyJrZXkiOiJjaXBkX3ZlcnNpb24iLCJ2YWx1ZSI6InJlZnMvaGVhZHMvbWFpbiJ9XSwiZGltZW5zaW9ucyI6W3sia2V5Ijoib3MiLCJ2YWx1ZSI6Ik1hYy0xMnxNYWMtMTMifSx7ImtleSI6ImRldmljZV90eXBlIiwidmFsdWUiOiJub25lIn1dLCJub3RpZnkiOnsicHVic3ViVG9waWMiOiJwcm9qZWN0cy9mbHV0dGVyLWRhc2hib2FyZC90b3BpY3MvbHVjaS1idWlsZHMiLCJ1c2VyRGF0YSI6IlpYbEthV1JYYkhOYVIxWjVXREkxYUdKWFZXbFBhVXBPV1ZkTloxbHVWbkJpUjFKbVpFZFdlbVJJVG1aTlZqZ3dTV2wzYVZreWFHeFpNblJtWTI1V2RWZ3liR3RKYW05NFQwUkpORTE2UlRCTlJHTjVUVk4zYVZreU9YUmlWMnd3V0ROT2IxbFRTVFpKYWtreFRtcHJlRnBxWTNkTmFrRXpUbnBGZVZwVVdYcE9WRkY1VGpKVk1sbHRUWHBaZWxFd1drZFJNMDlYUm1oWlZGRjZUMWRWYVV4RFNtcGlNakYwWVZoU1psbHVTbWhpYlU1dlNXcHZhV0pYUm5wa1IxWjVTV2wzYVdOdFZuZGlNVGwyWkRJMWJHTnBTVFpKYlZwelpGaFNNRnBZU1dsTVEwcDVXbGhDZGxneU5XaGlWMVZwVDJsS2JXSklWakJrUjFaNVNXbDNhV1JZVG14amJEbG9XakpXZFdSRFNUWkpiVnB6WkZoU01GcFlTWFJaTWpscVlqSTVkVWx1TUQwPSJ9LCJmaWVsZHMiOiJpZCxidWlsZGVyLG51bWJlcixzdGF0dXMsdGFncyIsImV4ZSI6eyJjaXBkVmVyc2lvbiI6InJlZnMvaGVhZHMvbWFpbiJ9fX1dfQ==","messageId":"9540536530549731","publishTime":"2023-11-02T00:17:00.467Z"},"subscription":"projects/flutter-dashboard/subscriptions/scheduler-requests-sub"}
''';

    final PubSubPushMessageV2 pushMessageV2 = PubSubPushMessageV2.fromJson(json.decode(message));
    final bbv2.PubSubCallBack pubSubCallBack = bbv2.PubSubCallBack();

    // print(pubSubCallBack.hasUserData());

    // pubSubCallBack.mergeFromProto3Json(jsonDecode(message) as Map<String, dynamic>);
    // print('...');
    // print(String.fromCharCodes(base64Decode(String.fromCharCodes(pubSubCallBack.userData))));
    // print('...');

    // print(String.fromCharCodes((base64.decode(pushMessageV2.message!.data!))));

    // print(pushMessageV2.message!.data!.toString());

    // final String unencodedData = String.fromCharCodes((base64.decode(pushMessageV2.message!.data!)));

    final bbv2.BatchRequest batchRequest = bbv2.BatchRequest.create();

    batchRequest.mergeFromProto3Json(jsonDecode(pushMessageV2.message!.data!));

    print(jsonEncode(batchRequest.toProto3Json()));

    // expect(batchRequest.requests.length, 5);
    // Absolutely need this Encode call before sending over https to prpc.
    // print(jsonEncode(batchRequest.toProto3Json()));
  });

  test('schedules request to buildbucket', () async {
    final bbv2.BuilderID responseBuilderID = bbv2.BuilderID();
    responseBuilderID.builder = 'Linux A';

    final bbv2.Build responseBuild = bbv2.Build();
    responseBuild.id = Int64(12345);
    responseBuild.builder = responseBuilderID;

    // has a list of BatchResponse_Response
    final bbv2.BatchResponse batchResponse = bbv2.BatchResponse();
    final bbv2.BatchResponse_Response batchResponseResponse = bbv2.BatchResponse_Response();
    batchResponseResponse.scheduleBuild = responseBuild;
    batchResponse.responses.add(batchResponseResponse);

    when(buildBucketV2Client.batch(any)).thenAnswer((_) async => batchResponse);

    // We cannot construct the object manually with the protos as we cannot write out
    // the json with all the required double quotes and testing fails.
    const String messageData = '''
{
  "requests": [
    {
      "scheduleBuild": {
        "builder": {
          "builder": "Linux A"
        }
      }
    }
  ]
}
''';

    const PushMessageV2 pushMessageV2 = PushMessageV2(data: messageData, messageId: '798274983');
    tester.message = pushMessageV2;
    final Body body = await tester.post(handler);
    expect(body, Body.empty);
  });

  test('retries schedule build if no response comes back', () async {
    final bbv2.BuilderID responseBuilderID = bbv2.BuilderID();
    responseBuilderID.builder = 'Linux A';

    final bbv2.Build responseBuild = bbv2.Build();
    responseBuild.id = Int64(12345);
    responseBuild.builder = responseBuilderID;

    // has a list of BatchResponse_Response
    final bbv2.BatchResponse batchResponse = bbv2.BatchResponse();

    final bbv2.BatchResponse_Response batchResponseResponse = bbv2.BatchResponse_Response();
    batchResponseResponse.scheduleBuild = responseBuild;

    batchResponse.responses.add(batchResponseResponse);

    int attempt = 0;

    when(buildBucketV2Client.batch(any)).thenAnswer((_) async {
      attempt += 1;
      if (attempt == 2) {
        return batchResponse;
      }

      return bbv2.BatchResponse().createEmptyInstance();
    });

    const String messageData = '''
{
  "requests": [
    {
      "scheduleBuild": {
        "builder": {
          "builder": "Linux A"
        }
      }
    }
  ]
}
''';

    const PushMessageV2 pushMessageV2 = PushMessageV2(data: messageData, messageId: '798274983');
    tester.message = pushMessageV2;
    final Body body = await tester.post(handler);

    expect(body, Body.empty);
    expect(verify(buildBucketV2Client.batch(any)).callCount, 2);
  });

  test('acking message and logging error when no response comes back after retry limit', () async {
    when(buildBucketV2Client.batch(any)).thenAnswer((_) async {
      return bbv2.BatchResponse().createEmptyInstance();
    });

    const String messageData = '''
{
  "requests": [
    {
      "scheduleBuild": {
        "builder": {
          "builder": "Linux A"
        }
      }
    }
  ]
}
''';

    const PushMessageV2 pushMessageV2 = PushMessageV2(data: messageData, messageId: '798274983');
    tester.message = pushMessageV2;
    final Body body = await tester.post(handler);

    expect(body, isNotNull);
    expect(verify(buildBucketV2Client.batch(any)).callCount, 3);
  });
}
