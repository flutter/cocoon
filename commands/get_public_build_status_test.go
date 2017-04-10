package commands

import (
	"testing"
	"cocoon/db"
)

// Test: no statuses in the database
func TestGetPublicBuildStatusBlank(t *testing.T) {
	result := computeTrend([]*db.BuildStatus{})
	if result != db.BuildWillFail {
		t.Errorf("Expected %v but was %v", db.BuildWillFail, result)
		t.Fail()
	}
}

// Test:
// foo
// succeeded
func TestGetPublicBuildStatusSuccess(t *testing.T) {
	result := computeTrend([]*db.BuildStatus{
		{
			Stages: []*db.Stage {
        {
					Tasks: []*db.TaskEntity{
						{
							Task: &db.Task{
								Name: "foo",
								Status: db.TaskSucceeded,
							},
						},
					},
				},
			},
		},
	})
	if result != db.BuildSucceeded {
		t.Errorf("Expected %v but was %v", db.BuildSucceeded, result)
		t.Fail()
	}
}

// Test:
// foo
// failed
// succeeded
func TestGetPublicBuildStatusSucceededThenFailed(t *testing.T) {
	result := computeTrend([]*db.BuildStatus{
		{
			Stages: []*db.Stage {
				{
					Tasks: []*db.TaskEntity{
						{
							Task: &db.Task{
								Name: "foo",
								Status: db.TaskFailed,
							},
						},
					},
				},
			},
		},
		{
			Stages: []*db.Stage {
				{
					Tasks: []*db.TaskEntity{
						{
							Task: &db.Task{
								Name: "foo",
								Status: db.TaskSucceeded,
							},
						},
					},
				},
			},
		},
	})
	if result != db.BuildWillFail {
		t.Errorf("Expected %v but was %v", db.BuildWillFail, result)
		t.Fail()
	}
}

// Test that flakes are considered successful:
// foo
// failed (flaky)
func TestGetPublicBuildStatusFlaky(t *testing.T) {
	result := computeTrend([]*db.BuildStatus{
		{
			Stages: []*db.Stage {
				{
					Tasks: []*db.TaskEntity{
						{
							Task: &db.Task{
								Name: "foo",
								Status: db.TaskFailed,
								Flaky: true,
							},
						},
					},
				},
			},
		},
	})
	if result != db.BuildSucceeded {
		t.Errorf("Expected %v but was %v", db.BuildSucceeded, result)
		t.Fail()
	}
}

// Test that marking a test as flaky shuts of warnings:
// foo
// failed (flaky)
// failed
func TestGetPublicBuildStatusFailedThenFlaky(t *testing.T) {
	result := computeTrend([]*db.BuildStatus{
		{
			Stages: []*db.Stage {
				{
					Tasks: []*db.TaskEntity{
						{
							Task: &db.Task{
								Name: "foo",
								Status: db.TaskFailed,
								Flaky: true,
							},
						},
					},
				},
			},
		},
		{
			Stages: []*db.Stage {
				{
					Tasks: []*db.TaskEntity{
						{
							Task: &db.Task{
								Name: "foo",
								Status: db.TaskFailed,
							},
						},
					},
				},
			},
		},
	})
	if result != db.BuildSucceeded {
		t.Errorf("Expected %v but was %v", db.BuildSucceeded, result)
		t.Fail()
	}
}

// Test that unmarking a test as flaky resumes warnings:
// foo
// failed
// failed (flaky)
func TestGetPublicBuildStatusFlakyThenFailed(t *testing.T) {
	result := computeTrend([]*db.BuildStatus{
		{
			Stages: []*db.Stage {
				{
					Tasks: []*db.TaskEntity{
						{
							Task: &db.Task{
								Name: "foo",
								Status: db.TaskFailed,
							},
						},
					},
				},
			},
		},
		{
			Stages: []*db.Stage {
				{
					Tasks: []*db.TaskEntity{
						{
							Task: &db.Task{
								Name: "foo",
								Status: db.TaskFailed,
								Flaky: true,
							},
						},
					},
				},
			},
		},
	})
	if result != db.BuildWillFail {
		t.Errorf("Expected %v but was %v", db.BuildWillFail, result)
		t.Fail()
	}
}

// Test that marking a test as flaky shuts off warnings immediately:
// foo
// new (flaky)
// failed
func TestGetPublicBuildStatusEagerlyFlaky(t *testing.T) {
	result := computeTrend([]*db.BuildStatus{
		{
			Stages: []*db.Stage {
				{
					Tasks: []*db.TaskEntity{
						{
							Task: &db.Task{
								Name: "foo",
								Status: db.TaskNew,
								Flaky: true,
							},
						},
					},
				},
			},
		},
		{
			Stages: []*db.Stage {
				{
					Tasks: []*db.TaskEntity{
						{
							Task: &db.Task{
								Name: "foo",
								Status: db.TaskFailed,
							},
						},
					},
				},
			},
		},
	})
	if result != db.BuildSucceeded {
		t.Errorf("Expected %v but was %v", db.BuildSucceeded, result)
		t.Fail()
	}
}

// Test:
// foo
// succeeded
// failed
func TestGetPublicBuildStatusFailedThenSucceeded(t *testing.T) {
	result := computeTrend([]*db.BuildStatus{
		{
			Stages: []*db.Stage {
				{
					Tasks: []*db.TaskEntity{
						{
							Task: &db.Task{
								Name: "foo",
								Status: db.TaskSucceeded,
							},
						},
					},
				},
			},
		},
		{
			Stages: []*db.Stage {
				{
					Tasks: []*db.TaskEntity{
						{
							Task: &db.Task{
								Name: "foo",
								Status: db.TaskFailed,
							},
						},
					},
				},
			},
		},
	})
	if result != db.BuildSucceeded {
		t.Errorf("Expected %v but was %v", db.BuildSucceeded, result)
		t.Fail()
	}
}

// Test:
// foo       bar
// succeeded failed
func TestGetPublicBuildStatusOneFailedOtherSucceeded(t *testing.T) {
	result := computeTrend([]*db.BuildStatus{
		{
			Stages: []*db.Stage {
				{
					Tasks: []*db.TaskEntity{
						{
							Task: &db.Task{
								Name: "foo",
								Status: db.TaskSucceeded,
							},
						},
					},
				},
				{
					Tasks: []*db.TaskEntity{
						{
							Task: &db.Task{
								Name: "bar",
								Status: db.TaskFailed,
							},
						},
					},
				},
			},
		},
	})
	if result != db.BuildWillFail {
		t.Errorf("Expected %v but was %v", db.BuildWillFail, result)
		t.Fail()
	}
}

// Test:
// foo       bar
// succeeded in progress
// failed    succeeded
func TestGetPublicBuildStatusAnticipateSuccessfulUnfinishedBuild(t *testing.T) {
	result := computeTrend([]*db.BuildStatus{
		{
			Stages: []*db.Stage {
				{
					Tasks: []*db.TaskEntity{
						{
							Task: &db.Task{
								Name: "foo",
								Status: db.TaskSucceeded,
							},
						},
						{
							Task: &db.Task{
								Name: "bar",
								Status: db.TaskInProgress,
							},
						},
					},
				},
			},
		},
		{
			Stages: []*db.Stage {
				{
					Tasks: []*db.TaskEntity{
						{
							Task: &db.Task{
								Name: "foo",
								Status: db.TaskFailed,
							},
						},
						{
							Task: &db.Task{
								Name: "bar",
								Status: db.TaskSucceeded,
							},
						},
					},
				},
			},
		},
	})
	if result != db.BuildSucceeded {
		t.Errorf("Expected %v but was %v", db.BuildSucceeded, result)
		t.Fail()
	}
}
