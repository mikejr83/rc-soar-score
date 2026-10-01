# RC Soar Score Entity Relationship Diagram

ERD for the 31 conceptual entities. Physical design: PostgreSQL backend with IndexedDB clients, UUIDv7 identifiers, composite unique constraints on natural business keys.

```mermaid
erDiagram
    %% Accounts and Ownership
    ACCOUNT {
        uuid id "PK"
        text first_name
        text last_name
        text email
        text provider_subject
    }

    %% Contest
    CONTEST {
        uuid id "PK"
        text name
        timestamp start_date_time
        timestamp end_date_time
        text timezone
        text host
        text city
        text state
        text country
        uuid owner_account_id "FK optional"
        text lifecycle_state
        text scoring_access
        text admin_lock
        text publication_status
        text visibility
        text deletion_status
        bool local_archive
        int revision
    }

    %% Participants
    PARTICIPANT_PROFILE {
        uuid id "PK"
        text first_name
        text last_name
        text club
        text fai_number
        text national_org_id
        text city
        text state
        text country
        text email
        bool is_shared
        int revision
    }

    PARTICIPANT_ACCOUNT_LINK {
        uuid id "PK"
        uuid participant_profile_id "FK"
        uuid account_id "FK"
        int revision
    }

    CONTEST_PARTICIPATION {
        uuid id "PK"
        uuid contest_id "FK"
        uuid participant_profile_id "FK"
        string cls
        uuid role_id "FK"
        text role_type
        int participant_number
        uuid team_membership_id "FK optional"
        uuid contest_model_link_id "FK optional"
        uuid scoring_uuid
        int revision
    }

    %% Teams, Roles, Models
    ROLE {
        uuid id "PK"
        text display_name
        text type
        text scope
        text permission
        int revision
    }

    TEAM {
        uuid id "PK"
        uuid contest_id "FK"
        text name
        int pilot_totals
        int revision
    }

    TEAM_MEMBERSHIP {
        uuid id "PK"
        uuid team_id "FK"
        uuid contest_participation_id "FK"
        text role
        int revision
    }

    MODEL_CATALOG {
        uuid id "PK"
        text name
        text manufacturer
        int revision
    }

    CONTEST_MODEL_LINK {
        uuid id "PK"
        uuid contest_id "FK"
        uuid contest_participation_id "FK"
        uuid model_catalog_id "FK optional"
        text model_name
        text manufacturer
        text model_id
        int revision
    }

    %% Discipline / Config
    DISCIPLINE_PROFILE {
        uuid id "PK"
        text type
        int version
        string config
    }

    LANDING_TABLE {
        uuid id "PK"
        text name
        int revision
        string config
    }

    LANDING_RESULT {
        uuid id "PK"
        int point_value
        string display_value
        int points
        string note
        uuid landing_table_id "FK"
    }

    ROUND_CONFIG {
        uuid id "PK"
        uuid contest_id "FK"
        text mode
        int groups_per_round
        int group_size
        int revision
    }

    CONTEST_CONFIGURATION_REVISION {
        uuid id "PK"
        uuid contest_id "FK"
        uuid discipline_profile_id "FK"
        text profile_version
        text group_score_mode
        text dropped_rounds_mode
        string overrides
        int revision
    }

    %% Matrix / Assignments
    MATRIX_REVISION {
        uuid id "PK"
        uuid contest_id "FK"
        string config
        uuid seed
        text fairness_result
        uuid creator_id
        text reason
        text finalizing_agent
        bool finalized
        int revision
    }

    MATRIX_ASSIGNMENT {
        uuid id "PK"
        uuid matrix_revision_id "FK"
        uuid contest_participation_id "FK"
        int scheduled_round
        int credited_round
        int group
        int lane
        text assignment_type
        uuid source_assignment_id "FK optional"
        text flight_sequence
        int assignment_revision
        int revision
    }

    RE_FLIGHT {
        uuid id "PK"
        uuid contest_id "FK"
        int credited_round
        string type
        int sequence
        string lifecycle_status
        string reasons
        string awards
        string selected_pilots
        string exclusion
        string responses
        string notifications
        string director_decision
        int revision
    }

    %% Scores and Results
    SCORE_PLACEHOLDER {
        uuid id "PK"
        uuid assignment_id "FK"
        uuid contest_participation_id "FK"
        int scheduled_round
        int credited_round
        int group
        int flight_sequence
        text state
        int score_revision
        int revision
    }

    SCORE_ATTEMPT {
        uuid id "PK"
        uuid score_placeholder_id "FK"
        string raw_components
        int cumulative_penalty
        text zero_reason
        string deductions
        uuid actor_id
        text authority
        uuid invitation_reference
        string source_device
        string client_mutation_id
        timestamp acceptance_time
        int base_score_revision
        int revision
    }

    OFFICIAL_SCORE {
        uuid id "PK"
        uuid score_placeholder_id "FK"
        int score_revision
        string components
        timestamp set_at
        int revision
    }

    SCORE_CALCULATION_RESULT {
        uuid id "PK"
        uuid official_score_id "FK"
        int raw_flight_score
        int normalized_group_score
        int contest_total
        bool dropped_round
        int rank
        int team_total
        string calculation_stage
        int revision
    }

    %% Publication
    PUBLICATION_IDENTITY {
        uuid id "PK"
        uuid contest_id "FK"
        text owner
        text claim_status
        text visibility
        int revision
    }

    PUBLICATION_PROJECTION {
        uuid id "PK"
        uuid publication_id "FK"
        int source_revision
        string content
        timestamp published_at
        text result
        int projection_revision
        int revision
    }

    %% Synchronization and Audit
    SYNC_CURSOR {
        uuid id "PK"
        uuid contest_id "FK"
        int last_synced_sequence
        timestamp updated_at
    }

    MUTATION_RECORD {
        uuid id "PK"
        uuid entity_id
        text entity_type
        uuid contest_id "FK"
        int base_revision
        string client_mutation_id
        uuid actor_id
        text authority
        string source_installation
        timestamp client_time
        timestamp server_time
        text outcome
        int revision
    }

    CONFLICT_RECORD {
        uuid id "PK"
        uuid entity_id
        uuid winner_mutation_id "FK"
        uuid loser_mutation_id "FK"
        text reason
        text resolution
    }

    TOMBSTONE {
        uuid id "PK"
        uuid entity_id
        text entity_type
        uuid contest_id "FK"
        text status
        string deletion_reason
    }

    INVITATION {
        uuid id "PK"
        uuid contest_id "FK"
        uuid contest_participation_id "FK"
        string type
        string protected_credential
        int invitation_revision
        text state
        text audience
        timestamp issued_at
        timestamp used_at
        timestamp expired_at
        timestamp revoked_at
    }

    REVIEW_REQUEST {
        uuid id "PK"
        uuid score_placeholder_id "FK"
        string proposed_components
        int proposed_cumulative_penalty
        string participant_message
        uuid requester_id
        int base_score_revision
        timestamp requested_at
        text state
        uuid decision_actor_id
        timestamp decision_time
        string decision_message
    }

    AUDIT_EVENT {
        uuid id "PK"
        uuid contest_id "FK"
        text entity_type
        uuid entity_id
        text action
        uuid actor_id "FK"
        text authority
        string installation
        int base_revision
        int resulting_revision
        timestamp server
        timestamp client
        text reason
        text outcome
    }

    %% Relationships
    ACCOUNT ||--o{ CONTEST : "owns (optional)"
    ACCOUNT }o--o{ PARTICIPANT_ACCOUNT_LINK : "linked to"
    PARTICIPANT_PROFILE }o--o{ PARTICIPANT_ACCOUNT_LINK : "linked to"
    PARTICIPANT_ACCOUNT_LINK }o--o{ PARTICIPANT_PROFILE : "-1"

    CONTEST ||--o{ CONTEST_CONFIGURATION_REVISION : "has revisions"
    CONTEST ||--o{ MATRIX_REVISION : "has revisions"
    CONTEST ||--o{ SYNC_CURSOR : "has cursor"
    CONTEST ||--o{ ROUND_CONFIG : "has"
    CONTEST ||--o{ TEAM : "has teams"
    CONTEST ||--o{ CONTEST_PARTICIPATION : "has participations"
    CONTEST ||--o{ CONTEST_MODEL_LINK : "has links"
    CONTEST ||--o{ RE_FLIGHT : "has"
    CONTEST ||--o{ INVITATION : "has"
    CONTEST ||--o{ AUDIT_EVENT : "has events"
    CONTEST ||--o{ SCORE_PLACEHOLDER : "indirect ownership via assignment"
    CONTEST ||--o{ MUTATION_RECORD : "has"
    CONTEST ||--o{ CONFLICT_RECORD : "has"
    CONTEST ||--o{ TOMBSTONE : "has"
    CONTEST ||--o{ SCORE_ATTEMPT : "indirect ownership via placeholder"
    CONTEST ||--o{ OFFICIAL_SCORE : "indirect ownership via placeholder"
    CONTEST ||--o{ SCORE_CALCULATION_RESULT : "indirect ownership"
    CONTEST ||--o{ PUBLICATION_IDENTITY : "has"
    CONTEST ||--o{ REVIEW_REQUEST : "indirect ownership"

    PARTICIPANT_PROFILE ||--o{ CONTEST_PARTICIPATION : "profile for"
    PARTICIPANT_PROFILE }o--o{ CONTEST_PARTICIPATION : "profile for"
    PARTICIPANT_PROFILE ||--o{ CONTEST_MODEL_LINK : "model snapshot"
    PARTICIPANT_PROFILE }o--o{ CONTEST_MODEL_LINK : "model snapshot"

    CONTEST_PARTICIPATION ||--o{ MATRIX_ASSIGNMENT : "assignment belongs to this participation"
    CONTEST_PARTICIPATION }o--o{ MATRIX_ASSIGNMENT : "assignment belongs to this participation"
    CONTEST_PARTICIPATION }o--o{ SCORE_PLACEHOLDER : "has placeholders"
    CONTEST_PARTICIPATION }o--o{ REVIEW_REQUEST : "has review requests"
    CONTEST_PARTICIPATION }o--o{ INVITATION : "has invitations"

    MATRIX_REVISION ||--o{ MATRIX_ASSIGNMENT : "contains"
    MATRIX_REVISION }o--o{ MATRIX_ASSIGNMENT : "contains"
    MATRIX_REVISION ||--o{ RE_FLIGHT : "has"
    MATRIX_REVISION }o--o{ RE_FLIGHT : "has"

    CONTEST_CONFIGURATION_REVISION ||--o{ SCORE_ATTEMPT : "cited by"
    CONTEST_CONFIGURATION_REVISION }o--o{ SCORE_ATTEMPT : "cited by"
    MATRIX_REVISION ||--o{ SCORE_ATTEMPT : "cited by"
    MATRIX_REVISION }o--o{ SCORE_ATTEMPT : "cited by"

    DISCIPLINE_PROFILE ||--o{ CONTEST_CONFIGURATION_REVISION : "referenced by"
    DISCIPLINE_PROFILE }o--o{ CONTEST_CONFIGURATION_REVISION : "referenced by"

    LANDING_TABLE ||--o{ CONTEST_CONFIGURATION_REVISION : "used by"
    LANDING_TABLE }o--o{ CONTEST_CONFIGURATION_REVISION : "used by"
    LANDING_TABLE ||--o{ SCORE_ATTEMPT : "used by"
    LANDING_TABLE }o--o{ SCORE_ATTEMPT : "used by"

    SCORE_PLACEHOLDER ||--o{ OFFICIAL_SCORE : "has"
    SCORE_PLACEHOLDER }o--o{ OFFICIAL_SCORE : "has"
    SCORE_PLACEHOLDER ||--o{ SCORE_CALCULATION_RESULT : "has"
    SCORE_PLACEHOLDER }o--o{ SCORE_CALCULATION_RESULT : "has"

    PUBLICATION_IDENTITY ||--o{ PUBLICATION_PROJECTION : "has"
    PUBLICATION_IDENTITY }o--o{ PUBLICATION_PROJECTION : "has"

    CONTEST ||--o{ PUBLICATION_PROJECTION : "projected to"
    CONTEST }o--o{ PUBLICATION_PROJECTION : "projected to"

    TEAM ||--o{ TEAM_MEMBERSHIP : "has members"
    TEAM }o--o{ TEAM_MEMBERSHIP : "has members"
    CONTEST_PARTICIPATION }o--o{ TEAM_MEMBERSHIP : "is member"
    TEAM_MEMBERSHIP }o--o{ CONTEST_PARTICIPATION : "is member"
```
