package commands

import (
	"fmt"
	"testing"
)

func TestParseManifestMinimal(t *testing.T) {
	yaml := "tasks:\n" +
		"  test_task:\n" +
		"    description: test_description\n" +
		"    stage: test_stage\n" +
		"    required_agent_capabilities: [\"a\", \"b\"]"
	manifest, err := ParseManifest([]byte(yaml))

	if err != nil {
		t.Errorf("Did not expect error but got %v", err)
		t.Fail()
	} else {
		if len(manifest.Tasks) != 1 {
			t.Errorf("Expected exactly one task but got %v", len(manifest.Tasks))
			t.Fail()
		}
		task := manifest.Tasks["test_task"]
		if task.Description != "test_description" {
			t.Errorf("Wrong task description %v", task.Description)
			t.Fail()
		}
		if task.Stage != "test_stage" {
			t.Errorf("Wrong task stage %v", task.Stage)
			t.Fail()
		}
		if len(task.RequiredAgentCapabilities) != 2 || task.RequiredAgentCapabilities[0] != "a" || task.RequiredAgentCapabilities[1] != "b" {
			t.Errorf("Wrong required_agent_capabilities %v", task.RequiredAgentCapabilities)
			t.Fail()
		}
		if task.Flaky {
			t.Errorf("Wrong task flaky flag %v", task.Flaky)
			t.Fail()
		}
		if task.TimeoutInMinutes != 0 {
			t.Errorf("Wrong TimeoutInMinutes %v", task.TimeoutInMinutes)
			t.Fail()
		}
	}
}

func TestParseManifestFull(t *testing.T) {
	yaml := "tasks:\n" +
		"  test_task:\n" +
		"    description: test_description\n" +
		"    stage: test_stage\n" +
		"    required_agent_capabilities: [\"a\", \"b\"]\n" +
		"    flaky: true\n" +
		"    timeout_in_minutes: 24"
	manifest, err := ParseManifest([]byte(yaml))

	if err != nil {
		t.Errorf("Did not expect error but got %v", err)
		t.Fail()
	} else {
		if len(manifest.Tasks) != 1 {
			t.Errorf("Expected exactly one task but got %v", len(manifest.Tasks))
			t.Fail()
		}
		task := manifest.Tasks["test_task"]
		if task.Description != "test_description" {
			t.Errorf("Wrong task description %v", task.Description)
			t.Fail()
		}
		if task.Stage != "test_stage" {
			t.Errorf("Wrong task stage %v", task.Stage)
			t.Fail()
		}
		if len(task.RequiredAgentCapabilities) != 2 || task.RequiredAgentCapabilities[0] != "a" || task.RequiredAgentCapabilities[1] != "b" {
			t.Errorf("Wrong required_agent_capabilities %v", task.RequiredAgentCapabilities)
			t.Fail()
		}
		if !task.Flaky {
			t.Errorf("Wrong task flaky flag %v", task.Flaky)
			t.Fail()
		}
		if task.TimeoutInMinutes != 24 {
			t.Errorf("Wrong task TimeoutInMinutes %v", task.TimeoutInMinutes)
			t.Fail()
		}
	}
}

func TestParseManifestWrongKey(t *testing.T) {
	yaml := "foo: bar"
	manifest, err := ParseManifest([]byte(yaml))

	if manifest != nil {
		t.Error("Expected null manifest")
		t.Fail()
	}

	expected := "Unrecognized key 'foo' in manifest YAML"
	actual := fmt.Sprintf("%v", err)
	if actual != expected {
		t.Errorf("Expected error message: \"%v\"", expected)
		t.Errorf("Got: \"%v\"", actual)
		t.Fail()
	}
}

func TestParseManifestMissingDescription(t *testing.T) {
	yaml := "tasks:\n" +
		"  test_task:\n" +
		"    stage: test_stage\n" +
		"    required_agent_capabilities: [\"a\"]"
	manifest, err := ParseManifest([]byte(yaml))

	if manifest != nil {
		t.Error("Expected null manifest")
		t.Fail()
	}

	expected := "Task test_task is missing a description"
	actual := fmt.Sprintf("%v", err)
	if actual != expected {
		t.Errorf("Expected error message: \"%v\"", expected)
		t.Errorf("Got: \"%v\"", actual)
		t.Fail()
	}
}

func TestParseManifestMissingStage(t *testing.T) {
	yaml := "tasks:\n" +
		"  test_task:\n" +
		"    description: test_description\n" +
		"    required_agent_capabilities: [\"a\"]"
	manifest, err := ParseManifest([]byte(yaml))

	if manifest != nil {
		t.Error("Expected null manifest")
		t.Fail()
	}

	expected := "Task test_task is missing a stage"
	actual := fmt.Sprintf("%v", err)
	if actual != expected {
		t.Errorf("Expected error message: \"%v\"", expected)
		t.Errorf("Got: \"%v\"", actual)
		t.Fail()
	}
}

func TestParseManifestMissingRequiredAgentCapabilities(t *testing.T) {
	yaml := "tasks:\n" +
		"  test_task:\n" +
		"    description: test_description\n" +
		"    stage: test_stage\n"
	manifest, err := ParseManifest([]byte(yaml))

	if manifest != nil {
		t.Error("Expected null manifest")
		t.Fail()
	}

	expected := "Task test_task is missing required_agent_capabilities"
	actual := fmt.Sprintf("%v", err)
	if actual != expected {
		t.Errorf("Expected error message: \"%v\"", expected)
		t.Errorf("Got: \"%v\"", actual)
		t.Fail()
	}
}
