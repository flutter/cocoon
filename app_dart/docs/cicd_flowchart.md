# CICD Label Flowchart

This flowchart describes the logic for managing the `CICD` label in Cocoon for running presubmit CI.

```mermaid
flowchart TD
    PR_Opened([Event: PR Opened]) --> Is_Draft{Is Draft?}

    Is_Draft -- No --> Is_Privileged_Open{Is Privileged?}
    Is_Draft -- Yes --> Create_Awaiting[Create Awaiting Check Run]

    Is_Privileged_Open -- Yes --> Add_Label[Add CICD Label]
    Add_Label --> Start_Pre[Start Presubmits]

    Is_Privileged_Open -- No --> Create_Awaiting

    Create_Awaiting --> State_Awaiting((State: Awaiting))
    Start_Pre --> State_Running((State: Running))

    State_Awaiting --> Label_Added([Event: CICD Label Added])
    Label_Added --> Resolve_Awaiting[Resolve Awaiting Check Run]
    Resolve_Awaiting --> Start_Pre

    State_Running --> Changes_Pushed([Event: Changes Pushed])
    Changes_Pushed --> Is_Privileged_Push{Is Privileged?}
    Remove_Label --> Create_Awaiting

    Is_Privileged_Push -- No --> Remove_Label[Remove CICD Label]

    Is_Privileged_Push -- Yes --> Label_Present{Has CICD Label?}
    Label_Present -- Yes --> Start_Pre
    Label_Present -- No --> Create_Awaiting
```

## Alternative State Machine Diagram (PlantUML)

```plantuml
@startuml
state PR {
  state Waiting
  Waiting : entry / Create Awaiting Check Run
  Waiting : exit / resolve(awaiting check)

  state Running
  Running: entry/ Start Presubmits

  state if_priv2 <<choice>>
  Running --> if_priv2: onPushed
  if_priv2 --> Running: isPrivileged && labeled(CICD)
  if_priv2 --> Waiting : default: remove(CICD)

  state if_draft <<choice>>
  PR --> if_draft: openned

  if_draft --> Waiting : isDraft
  if_draft --> Running: isPrivileged
  if_draft --> Waiting : default

  Waiting --> Running: labeled(CICD)
}
@enduml
```
