
message Task {
    optional string StageName = 1;
    optional string Name = 2;
    optional string Status = 3;
    optional string Reason = 4;
    optional int32 Attempts = 5;
    optional string ReservedForAgentID = 6;
    optional int64 CreateTimestamp = 7;
    optional int64 StartTimestamp = 8;
    optional int64 EndTimestamp = 9;
    optional bool Flaky = 10;
    optional int32 TimeoutInMinutes = 11;
    repeated string RequiredCapabilities = 12;
}

/// Timeseries contains a history of values of a certain performance metric.
message Timeseries {
    required string ID = 1;
    optional string TaskName = 2;
    optional string label = 3;
    optional string unit = 4;
    optional double goal = 5;
    optional double baseline = 6;
    optional bool archived = 7;
  }
