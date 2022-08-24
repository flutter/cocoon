import 'dart:convert';

import 'package:auto_submit/model/big_query_pull_request_record.dart';
import 'package:auto_submit/model/big_query_revert_request_record.dart';
import 'package:auto_submit/service/access_client_provider.dart';
import 'package:auto_submit/service/bigquery.dart';
import 'package:googleapis/bigquery/v2.dart';
import 'package:mockito/mockito.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

import '../src/service/fake_bigquery_service.dart';
import '../utilities/mocks.dart';


const String revertRequestRecordResponse = '''
{
  "jobComplete": true,
  "rows": [
    { "f": [
        { "v": "flutter"},
        { "v": "cocoon" },
        { "v": "ricardoamador" },
        { "v": "1024" },
        { "v": "123f124" },
        { "v": "flutter/cocoon#1024" },
        { "v": "123456789" },
        { "v": "123456999" },
        { "v": "ricardoamador" },
        { "v": "2048" },
        { "v": "ce345dc" },
        { "v": "flutter/cocoon#2048" },
        { "v": "234567890" },
        { "v": "234567999" }
      ]
    }
  ]
}
''';

const String pullRequestRecordResponse = '''
{
  "jobComplete": true,
  "rows": [
    { "f": [
        { "v": "123456789"},
        { "v": "234567890" },
        { "v": "flutter" },
        { "v": "cocoon" },
        { "v": "ricardoamador" },
        { "v": "345" },
        { "v": "ade456" },
        { "v": "merge" }
      ]
    }
  ]
}
''';

const String successResponseNoRowsAffected = '''
{
  "jobComplete": true
}
''';

const String insertDeleteSuccessResponse = '''
{
  "jobComplete": true,
  "numDmlAffectedRows": "1" 
}
''';

const String insertDeleteSuccessTooManyRows = '''
{
  "jobComplete": true,
  "numDmlAffectedRows": "2"
}
''';

const String selectPullRequestTooManyRowsResponse = '''
{
  "jobComplete": true,
  "numDmlAffectedRows": "2",
  "rows": [
    { "f": [
        { "v": "123456789"},
        { "v": "234567890" },
        { "v": "flutter" },
        { "v": "cocoon" },
        { "v": "ricardoamador" },
        { "v": "345" },
        { "v": "ade456" },
        { "v": "merge" }
      ]
    },
    { "f": [
        { "v": "123456789"},
        { "v": "234567890" },
        { "v": "flutter" },
        { "v": "cocoon" },
        { "v": "ricardoamador" },
        { "v": "345" },
        { "v": "ade456" },
        { "v": "merge" }
      ]
    }
  ]
}
''';

const String selectRevertRequestTooManyRowsResponse = '''
{
  "jobComplete": true,
  "numDmlAffectedRows": "2",
  "rows": [
    { "f": [
        { "v": "flutter"},
        { "v": "cocoon" },
        { "v": "ricardoamador" },
        { "v": "1024" },
        { "v": "123f124" },
        { "v": "flutter/cocoon#1024" },
        { "v": "123456789" },
        { "v": "123456999" },
        { "v": "ricardoamador" },
        { "v": "2048" },
        { "v": "ce345dc" },
        { "v": "flutter/cocoon#2048" },
        { "v": "234567890" },
        { "v": "234567999" }
      ]
    },
    { "f": [
        { "v": "flutter"},
        { "v": "cocoon" },
        { "v": "ricardoamador" },
        { "v": "1024" },
        { "v": "123f124" },
        { "v": "flutter/cocoon#1024" },
        { "v": "123456789" },
        { "v": "123456999" },
        { "v": "ricardoamador" },
        { "v": "2048" },
        { "v": "ce345dc" },
        { "v": "flutter/cocoon#2048" },
        { "v": "234567890" },
        { "v": "234567999" }
      ]
    }
  ]
}
''';

const String errorResponse = '''
{
  "jobComplete": false
}
''';

const String expectedProjectId = 'flutter-dashboard';

void main() {
  late FakeBigqueryService service;
  late MockJobsResource jobsResource;

  setUp(() {
    jobsResource = MockJobsResource();
    service = FakeBigqueryService(jobsResource);
  });

  test('Insert pull request record is successful.', () async {
    when(jobsResource.query(captureAny, expectedProjectId)).thenAnswer((Invocation invocation) {
      return Future<QueryResponse>.value(
          QueryResponse.fromJson(jsonDecode(insertDeleteSuccessResponse) as Map<dynamic, dynamic>));
    });

    PullRequestRecord pullRequestRecord = PullRequestRecord(
      prCreatedTimestamp: 123456789,
      prLandedTimestamp: 234567890,
      organization: 'flutter',
      repository: 'cocoon',
      author: 'ricardoamador',
      prId: 345,
      prCommit: 'ade456',
      prRequestType: 'merge',
    );

    bool hasError = false;
    try {
      await service.insertPullRequestRecord(expectedProjectId, pullRequestRecord);
    } catch (exception) {
      hasError = true;
    }
    expect(hasError, isFalse);
  });

  test('Insert pull request record handles unsuccessful job complete error.', () async {
    when(jobsResource.query(captureAny, expectedProjectId)).thenAnswer((Invocation invocation) {
      return Future<QueryResponse>.value(
          QueryResponse.fromJson(jsonDecode(errorResponse) as Map<dynamic, dynamic>));
    });

    bool hasError = false;
    PullRequestRecord pullRequestRecord = PullRequestRecord(
      prCreatedTimestamp: 123456789,
      prLandedTimestamp: 234567890,
      organization: 'flutter',
      repository: 'cocoon',
      author: 'ricardoamador',
      prId: 345,
      prCommit: 'ade456',
      prRequestType: 'merge',
    );

    try {
      await service.insertPullRequestRecord(expectedProjectId, pullRequestRecord);
    } catch (exception) {
      expect(exception.toString(), 'Exception: Insert pull request record for $pullRequestRecord did not complete.');
      hasError = true;
    }
    expect(hasError, isTrue);
  });

  test('Insert pull request fails when multiple rows are returned.', () async {
    when(jobsResource.query(captureAny, expectedProjectId)).thenAnswer((Invocation invocation) {
      return Future<QueryResponse>.value(
          QueryResponse.fromJson(jsonDecode(selectPullRequestTooManyRowsResponse) as Map<dynamic, dynamic>));
    });

    bool hasError = false;
    PullRequestRecord pullRequestRecord = PullRequestRecord(
      prCreatedTimestamp: 123456789,
      prLandedTimestamp: 234567890,
      organization: 'flutter',
      repository: 'cocoon',
      author: 'ricardoamador',
      prId: 345,
      prCommit: 'ade456',
      prRequestType: 'merge',
    );

    try {
      await service.insertPullRequestRecord(expectedProjectId, pullRequestRecord);
    } catch (exception) {
      expect(exception.toString(), 'Exception: There was an error inserting $pullRequestRecord into the table.');
      hasError = true;
    }
    expect(hasError, isTrue);
  });

  test('Select pull request is successful.', () async {
    when(jobsResource.query(captureAny, expectedProjectId)).thenAnswer((Invocation invocation) {
      return Future<QueryResponse>.value(
          QueryResponse.fromJson(jsonDecode(pullRequestRecordResponse) as Map<dynamic, dynamic>));
    });

    PullRequestRecord pullRequestRecord = await service.selectPullRequestRecordByPrId(expectedProjectId, 345, 'cocoon');
    expect(pullRequestRecord, isNotNull);
    expect(pullRequestRecord.prCreatedTimestamp, equals(123456789));
    expect(pullRequestRecord.prLandedTimestamp, equals(234567890));
    expect(pullRequestRecord.organization, equals('flutter'));
    expect(pullRequestRecord.repository, equals('cocoon'));
    expect(pullRequestRecord.author, equals('ricardoamador'));
    expect(pullRequestRecord.prId, 345);
    expect(pullRequestRecord.prCommit, equals('ade456'));
    expect(pullRequestRecord.prRequestType, equals('merge'));
  });

  test('Select pull request handles unsuccessful job failure.', () async {
    when(jobsResource.query(captureAny, expectedProjectId)).thenAnswer((Invocation invocation) {
      return Future<QueryResponse>.value(
        QueryResponse.fromJson(jsonDecode(errorResponse) as Map<dynamic, dynamic>));
    });

    bool hasError = false;
    try {
      PullRequestRecord pullRequestRecord = await service.selectPullRequestRecordByPrId(expectedProjectId, 345, 'cocoon');
    } catch(exception) {
      hasError = true;
      expect(exception.toString(), 'Exception: Get pull request by id for 345 and cocoon did not complete.');
    }
    expect(hasError, isTrue);
  });

  test('Select pull request handles no rows returned failure.', () async {
    when(jobsResource.query(captureAny, expectedProjectId)).thenAnswer((Invocation invocation) {
      return Future<QueryResponse>.value(
        QueryResponse.fromJson(jsonDecode(successResponseNoRowsAffected) as Map<dynamic, dynamic>));
    });

    bool hasError = false;
    try {
      PullRequestRecord pullRequestRecord = await service.selectPullRequestRecordByPrId(expectedProjectId, 345, 'cocoon');
    } catch(exception) {
      hasError = true;
      expect(exception.toString(), 'Exception: Could not find an entry for pull request id 345 in repository cocoon.');
    }
    expect(hasError, isTrue);
  });

  test('Select pull request handles too many rows returned failure.', () async {
    when(jobsResource.query(captureAny, expectedProjectId)).thenAnswer((Invocation invocation) {
      return Future<QueryResponse>.value(
        QueryResponse.fromJson(jsonDecode(selectPullRequestTooManyRowsResponse) as Map<dynamic, dynamic>));
    });

    bool hasError = false;
    try {
      PullRequestRecord pullRequestRecord = await service.selectPullRequestRecordByPrId(expectedProjectId, 345, 'cocoon');
    } catch(exception) {
      hasError = true;
      expect(exception.toString(), 'Exception: More than one record was returned for pull request id 345 in repository cocoon.');
    }
    expect(hasError, isTrue);
  });

  test('Delete pull request record handles failure to complete job.', () async {
    when(jobsResource.query(captureAny, expectedProjectId)).thenAnswer((Invocation invocation) {
      return Future<QueryResponse>.value(
        QueryResponse.fromJson(jsonDecode(errorResponse) as Map<dynamic, dynamic>));
    });

    bool hasError = false;
    try {
      await service.deletePullRequestRecord(expectedProjectId, 345, 'cocoon');
    } catch(exception) {
      hasError = true;
      expect(exception.toString(), 'Exception: Delete pull request for 345 in repository cocoon did not complete.');
    }
    expect(hasError, isTrue);
  });

  test('Delete pull request record handles success but no affected rows.', () async {
    when(jobsResource.query(captureAny, expectedProjectId)).thenAnswer((Invocation invocation) {
      return Future<QueryResponse>.value(
        QueryResponse.fromJson(jsonDecode(successResponseNoRowsAffected) as Map<dynamic, dynamic>));
    });

    bool hasError = false;
    try {
      await service.deletePullRequestRecord(expectedProjectId, 345, 'cocoon');
    } catch(exception) {
      hasError = true;
      expect(exception.toString(), 'Exception: The pull request record for 345 in repository cocoon was not deleted.');
    }
    expect(hasError, isTrue);
  });

  test('Delete pull request record handles success but wrong number of affected rows.', () async {
    when(jobsResource.query(captureAny, expectedProjectId)).thenAnswer((Invocation invocation) {
      return Future<QueryResponse>.value(
        QueryResponse.fromJson(jsonDecode(insertDeleteSuccessTooManyRows) as Map<dynamic, dynamic>));
    });

    bool hasError = false;
    try {
      await service.deletePullRequestRecord(expectedProjectId, 345, 'cocoon');
    } catch(exception) {
      hasError = true;
      expect(exception.toString(), 'Exception: More than one row we deleted from the database for 345 in repository cocoon.');
    }
    expect(hasError, isTrue);
  });


  test('Insert revert request record is successful.', () async {
    when(jobsResource.query(captureAny, expectedProjectId)).thenAnswer((Invocation invocation) {
      return Future<QueryResponse>.value(
          QueryResponse.fromJson(jsonDecode(insertDeleteSuccessResponse) as Map<dynamic, dynamic>));
    });

    RevertRequestRecord revertRequestRecord = RevertRequestRecord(
        organization: 'flutter',
        repository: 'cocoon',
        revertingPrAuthor: 'ricardoamador',
        revertingPrId: 1024,
        revertingPrCommit: '123f124',
        revertingPrUrl: 'flutter/cocoon#1024',
        revertingPrCreatedTimestamp: 123456789,
        revertingPrLandedTimestamp: 123456999,
        originalPrAuthor: 'ricardoamador',
        originalPrId: 1000,
        originalPrCommit: 'ce345dc',
        originalPrCreatedTimestamp: 234567890,
        originalPrLandedTimestamp: 234567999,
      );

    bool hasError = false;
    try {
      await service.insertRevertRequest(expectedProjectId, revertRequestRecord);
    } catch (exception) {
      hasError = true;
    }
    expect(hasError, isFalse);
  });

  test('Insert revert request record handles unsuccessful job complete error.', () async {
    when(jobsResource.query(captureAny, expectedProjectId)).thenAnswer((Invocation invocation) {
      return Future<QueryResponse>.value(
          QueryResponse.fromJson(jsonDecode(errorResponse) as Map<dynamic, dynamic>));
    });

    bool hasError = false;
    RevertRequestRecord revertRequestRecord = RevertRequestRecord(
        organization: 'flutter',
        repository: 'cocoon',
        revertingPrAuthor: 'ricardoamador',
        revertingPrId: 1024,
        revertingPrCommit: '123f124',
        revertingPrUrl: 'flutter/cocoon#1024',
        revertingPrCreatedTimestamp: 123456789,
        revertingPrLandedTimestamp: 123456999,
        originalPrAuthor: 'ricardoamador',
        originalPrId: 1000,
        originalPrCommit: 'ce345dc',
        originalPrCreatedTimestamp: 234567890,
        originalPrLandedTimestamp: 234567999,
      );

    try {
      await service.insertRevertRequest(expectedProjectId, revertRequestRecord);
    } catch (e) {
      expect(e.toString(), 'Exception: Insert revert request $revertRequestRecord did not complete.');
      hasError = true;
    }
    expect(hasError, isTrue);
  });

  test('Select revert request is successful.', () async {
    when(jobsResource.query(captureAny, expectedProjectId)).thenAnswer((Invocation invocation) {
      return Future<QueryResponse>.value(
          QueryResponse.fromJson(jsonDecode(revertRequestRecordResponse) as Map<dynamic, dynamic>));
    });

    RevertRequestRecord revertRequestRecord = await service.selectRevertRequestByRevertPrId(expectedProjectId, 2048, 'cocoon');
    expect(revertRequestRecord, isNotNull);
    expect(revertRequestRecord.organization, equals('flutter'));
    expect(revertRequestRecord.repository, equals('cocoon'));
    expect(revertRequestRecord.revertingPrAuthor, equals('ricardoamador'));
    expect(revertRequestRecord.revertingPrId, equals(1024));
    expect(revertRequestRecord.revertingPrCommit, equals('123f124'));
    expect(revertRequestRecord.revertingPrUrl, equals('flutter/cocoon#1024'));
    expect(revertRequestRecord.revertingPrCreatedTimestamp, equals(123456789));
    expect(revertRequestRecord.revertingPrLandedTimestamp, equals(123456999));
    expect(revertRequestRecord.originalPrAuthor, equals('ricardoamador'));
    expect(revertRequestRecord.originalPrId, equals(2048));
    expect(revertRequestRecord.originalPrCommit, equals('ce345dc'));
    expect(revertRequestRecord.originalPrUrl, equals('flutter/cocoon#2048'));
    expect(revertRequestRecord.originalPrCreatedTimestamp, equals(234567890));
    expect(revertRequestRecord.originalPrLandedTimestamp, equals(234567999));
  });

  test('Select revert request is unsuccessful with job did not complete error.', () async {
    when(jobsResource.query(captureAny, expectedProjectId)).thenAnswer((Invocation invocation) {
      return Future<QueryResponse>.value(
        QueryResponse.fromJson(jsonDecode(errorResponse) as Map<dynamic, dynamic>));
    });

    bool hasError = false;
    try {
      RevertRequestRecord revertRequestRecord = await service.selectRevertRequestByRevertPrId(expectedProjectId, 2048, 'cocoon');
    } catch(exception) {
      hasError = true;
      expect(exception.toString(), 'Exception: Get revert request by id 2048 in repository cocoon did not complete.');
    }
    expect(hasError, isTrue);
  });

  test('Select revert request is successful but does not return any rows.', () async {
    when(jobsResource.query(captureAny, expectedProjectId)).thenAnswer((Invocation invocation) {
      return Future<QueryResponse>.value(
        QueryResponse.fromJson(jsonDecode(successResponseNoRowsAffected) as Map<dynamic, dynamic>));
    });

    bool hasError = false;
    try {
      RevertRequestRecord revertRequestRecord = await service.selectRevertRequestByRevertPrId(expectedProjectId, 2048, 'cocoon');
    } catch(exception) {
      hasError = true;
      expect(exception.toString(), 'Exception: Could not find an entry for revert request id 2048 in repository cocoon.');
    }
    expect(hasError, isTrue);
  });

  test('Select is successful but returns more than one row in the request.', () async {
    when(jobsResource.query(captureAny, expectedProjectId)).thenAnswer((Invocation invocation) {
      return Future<QueryResponse>.value(
        QueryResponse.fromJson(jsonDecode(selectRevertRequestTooManyRowsResponse) as Map<dynamic, dynamic>));
    });

    bool hasError = false;
    try {
      RevertRequestRecord revertRequestRecord = await service.selectRevertRequestByRevertPrId(expectedProjectId, 2048, 'cocoon');
    } catch(exception) {
      hasError = true;
      expect(exception.toString(), 'Exception: More than one record was returned for revert request id 2048 in repository cocoon.');
    }
    expect(hasError, isTrue);
  });

  test('Delete revert request record handles failure to complete job.', () async {
    when(jobsResource.query(captureAny, expectedProjectId)).thenAnswer((Invocation invocation) {
      return Future<QueryResponse>.value(
        QueryResponse.fromJson(jsonDecode(errorResponse) as Map<dynamic, dynamic>));
    });

    bool hasError = false;
    try {
      await service.deleteRevertRequestRecord(expectedProjectId, 2048, 'cocoon');
    } catch(exception) {
      hasError = true;
      expect(exception.toString(), 'Exception: Delete revert request for 2048 in repository cocoon did not complete.');
    }
    expect(hasError, isTrue);
  });

  test('Delete revert request record handles success but no affected rows.', () async {
    when(jobsResource.query(captureAny, expectedProjectId)).thenAnswer((Invocation invocation) {
      return Future<QueryResponse>.value(
        QueryResponse.fromJson(jsonDecode(successResponseNoRowsAffected) as Map<dynamic, dynamic>));
    });

    bool hasError = false;
    try {
      await service.deleteRevertRequestRecord(expectedProjectId, 2048, 'cocoon');
    } catch(exception) {
      hasError = true;
      expect(exception.toString(), 'Exception: The request record for 2048 in repository cocoon was not deleted.');
    }
    expect(hasError, isTrue);
  });

  test('Delete revert request record handles success but wrong number of affected rows.', () async {
    when(jobsResource.query(captureAny, expectedProjectId)).thenAnswer((Invocation invocation) {
      return Future<QueryResponse>.value(
        QueryResponse.fromJson(jsonDecode(insertDeleteSuccessTooManyRows) as Map<dynamic, dynamic>));
    });

    bool hasError = false;
    try {
      await service.deleteRevertRequestRecord(expectedProjectId, 2048, 'cocoon');
    } catch(exception) {
      hasError = true;
      expect(exception.toString(), 'Exception: More than one row we deleted from the database for 2048 in repository cocoon.');
    }
    expect(hasError, isTrue);
  });



  test('Testing select revert request record from bigquery.', () async {
    
    final AccessClientProvider accessClientProvider = AccessClientProvider();
    BigqueryService bigqueryService = BigqueryService(accessClientProvider);

    try {
      RevertRequestRecord revertRequestRecord = await bigqueryService.selectRevertRequestByRevertPrId('flutter-dashboard', 1024, 'cocoon');
      expect(revertRequestRecord.organization, isNotNull);
      print(revertRequestRecord);
    } catch(exception) {
      print(exception.toString());
    }
  }, skip: true);

  test('Testing insert revert request record into bigquery.', () async {
    final AccessClientProvider accessClientProvider = AccessClientProvider();
    BigqueryService bigqueryService = BigqueryService(accessClientProvider);

    try {
      RevertRequestRecord revertRequestRecord = RevertRequestRecord(
        organization: 'flutter',
        repository: 'cocoon',
        revertingPrAuthor: 'ricardoamador',
        revertingPrId: 1024,
        revertingPrCommit: '123f124',
        revertingPrUrl: 'flutter/cocoon#1024',
        revertingPrCreatedTimestamp: 123456789,
        revertingPrLandedTimestamp: 123456999,
        originalPrAuthor: 'ricardoamador',
        originalPrId: 1000,
        originalPrCommit: 'ce345dc',
        originalPrCreatedTimestamp: 234567890,
        originalPrLandedTimestamp: 234567999,
      );

      await bigqueryService.insertRevertRequest('flutter-dashboard', revertRequestRecord);
    } catch(exception) {
      print(exception.toString());
    }
  }, skip: true);

  test('Testing delete of a revert request record into bigquery.', () async {
    final AccessClientProvider accessClientProvider = AccessClientProvider();
    BigqueryService bigqueryService = BigqueryService(accessClientProvider);

    try {
      await bigqueryService.deleteRevertRequestRecord('flutter-dashboard', 1024, 'cocoon');
    } catch(exception) {
      print(exception.toString());
    }
  }, skip: true);

  test('Testing select of pull request record from bigquery.', () async {
    final AccessClientProvider accessClientProvider = AccessClientProvider();
    BigqueryService bigqueryService = BigqueryService(accessClientProvider);

    try {
      PullRequestRecord pullRequestRecord = await bigqueryService.selectPullRequestRecordByPrId('flutter-dashboard', 345, 'cocoon');
      expect(pullRequestRecord.organization, isNotNull);
      print(pullRequestRecord);
    } catch(exception) {
      print(exception.toString());
    }
  }, skip: true);

  test('Test delete pull request record from bigquery.', () async {
    final AccessClientProvider accessClientProvider = AccessClientProvider();
    BigqueryService bigqueryService = BigqueryService(accessClientProvider);

    try {
      await bigqueryService.deletePullRequestRecord('flutter-dashboard', 345, 'cocoon');
    } catch(exception) {
      print(exception.toString());
    }
  }, skip: true);

  test('Test insert pull request record into bigquery.', () async {
    final AccessClientProvider accessClientProvider = AccessClientProvider();
    BigqueryService bigqueryService = BigqueryService(accessClientProvider);

    PullRequestRecord pullRequestRecord = PullRequestRecord(
      prCreatedTimestamp: 123456789,
      prLandedTimestamp: 234567890,
      organization: 'flutter',
      repository: 'cocoon',
      author: 'ricardoamador',
      prId: 345,
      prCommit: 'ade456',
      prRequestType: 'merge',
    );

    try {
      await bigqueryService.insertPullRequestRecord('flutter-dashboard', pullRequestRecord);
    } catch(exception) {
      print(exception.toString());
    }
  }, skip: true);
}