# RC Soar Score Entity Relationship Diagram

ERD for the 48 conceptual entities. Physical design: PostgreSQL backend and SQLite in the native offline application (web clients hold no contest data and use the API), UUIDv7 identifiers, composite unique constraints on natural business keys.

```mermaid
erDiagram
    %% Accounts and Ownership
    ACCOUNT {
        uuid        id              PK
        text        first_name
        text        last_name
        text        email              "nullable, lowercase"
        bool        email_verified
        text        kind               "enum, registered, guest, local, deleted"
        text        status             "enum, active, archived"
        timestamptz archived_at        "optional"
        bool        is_system_admin
        timestamptz created_at
        timestamptz updated_at
    }

    ACCOUNT_IDENTITY {
        uuid        id         PK
        uuid        account_id FK
        text        issuer
        text        subject
        timestamptz created_at
    }

    ACCOUNT_PUBLIC_PROFILE {
        uuid        id           PK
        uuid        account_id   FK "optional, unique"
        text        display_name
        timestamptz created_at
    }

    %% Contest
    CONTEST {
        uuid        id                           PK
        text        name
        timestamp   start_date_time
        timestamp   end_date_time
        text        timezone
        text        host
        text        city
        text        state
        text        country
        uuid        owner_account_id             FK "optional"
        text        lifecycle_state    "enum"
        text        scoring_access    "enum"
        text        admin_lock    "enum"
        bool        local_archive
        int         revision
        int         results_hidden_through_round    "optional"
        timestamptz results_hidden_at               "optional"
        timestamptz created_at
        timestamptz updated_at
    }

    CONTEST_CONFIGURATION_PRESET {
        uuid        id                    PK
        uuid        owner_account_id      FK
        uuid        discipline_profile_id FK
        text        name
        text        description              "optional"
        jsonb       config                   "core and discipline; full resolved"
        uuid        landing_table_id      FK "optional"
        timestamptz created_at
        timestamptz updated_at
        int         revision
    }

    %% Participants
    PARTICIPANT_DIRECTORY_ENTRY {
        uuid        id                         PK
        uuid        account_id                 FK "unique"
        text        first_name
        text        last_name
        text        club                          "optional"
        text        fai_number                    "optional"
        text        national_org_id               "optional"
        text        city                          "optional"
        text        state                         "optional"
        text        country                       "optional"
        bool        is_listed                     "opt-in to be found by directors"
        bool        email_visible_to_directors
        timestamptz created_at
        timestamptz updated_at
    }

    PARTICIPANT_PROFILE {
        uuid        id               PK
        uuid        owner_account_id FK "the owning director"
        text        first_name
        text        last_name
        text        club
        text        fai_number
        text        national_org_id
        text        city
        text        state
        text        country
        text        email               "private"
        timestamptz created_at
        timestamptz updated_at
        int         revision
    }

    PARTICIPANT_ACCOUNT_LINK {
        uuid        id                     PK
        uuid        participant_profile_id FK
        uuid        account_id             FK
        text        status                    "enum, Candidate, Confirmed, Ended"
        text        origin                    "enum, EmailMatch, DirectoryPull, InvitationRedemption"
        timestamptz created_at
        timestamptz confirmed_at              "optional"
        timestamptz ended_at                  "optional"
        int         revision
    }

    CONTEST_PARTICIPATION {
        uuid   id                     PK
        uuid   contest_id             FK
        uuid   participant_profile_id FK
        string classification            "pilots only, nullable"
        uuid   role_id                FK
        text   role_name                 "snapshot at assignment"
        text   role_type                 "enum, Pilot, NonFlier"
        int    participant_number        "one sequence for all roles; nullable until the first draw"
        uuid   scoring_uuid              "random UUIDv4"
        int    retired_at_round          "optional; pilots only"
        int    revision
    }

    %% Teams, Roles, Models
    ROLE {
        uuid        id               PK
        uuid        owner_account_id FK "optional; null for a system role"
        text        display_name
        text        type                "enum, Pilot, NonFlier"
        timestamptz archived_at         "optional"
        int         revision
    }

    TEAM {
        uuid id         PK
        uuid contest_id FK
        text name
        int  revision
    }

    TEAM_MEMBERSHIP {
        uuid id                       PK
        uuid contest_id               FK
        uuid team_id                  FK
        uuid contest_participation_id FK
        int  revision
    }

    MODEL_CATALOG {
        uuid id           PK
        text name
        text manufacturer
        int  revision
    }

    CONTEST_MODEL_LINK {
        uuid id                          PK
        uuid contest_id                  FK
        uuid contest_participation_id    FK
        uuid model_catalog_id            FK "optional"
        text model_name
        text manufacturer
        text model_id
        text contest_specific_identifier    "optional"
        int  revision
    }

    %% Discipline / Config
    DISCIPLINE_PROFILE {
        uuid      id                       PK
        text      type    "enum"
        int       version
        text      name
        text      description
        text      category    "enum"
        uuid      default_landing_table_id FK "optional"
        jsonb     default_options             "optional; core option defaults"
        text      status    "enum"
        uuid      superseded_by            FK "optional"
        uuid      created_by               FK
        timestamp created_at
        uuid      updated_by               FK "optional"
        timestamp updated_at
    }

    DISCIPLINE_CONFIG_FIELD {
        uuid        id                    PK
        uuid        discipline_profile_id FK
        text        field_key
        text        field_type    "enum"
        text        name
        text        description
        text        unit                     "optional"
        bool        required
        string      default_value
        string      options
        string      validation
        int         display_order
        timestamptz created_at
    }

    DISCIPLINE_SCORE_FIELD {
        uuid        id                    PK
        uuid        discipline_profile_id FK
        text        field_key
        text        field_type    "enum"
        text        name
        text        description
        text        field_kind               "enum, input, status_flag, derived"
        text        unit                     "optional"
        int         precision                "optional"
        bool        required
        string      default_value
        string      options
        string      validation
        int         display_order
        bool        is_zero_reason
        text        zero_reason_code
        timestamptz created_at
    }

    DISCIPLINE_VALIDATION {
        uuid        id                    PK
        uuid        discipline_profile_id FK
        string      field_keys
        text        constraint_type
        text        description
        string      applies_to
        text        message
        int         display_order
        timestamptz created_at
    }

    DISCIPLINE_FORMULA {
        uuid        id                    PK
        uuid        discipline_profile_id FK
        text        formula_key
        text        formula_type    "enum"
        text        description
        text        formula_text
        string      inputs
        string      outputs
        string      depends_on
        bool        is_primary
        int         display_order
        timestamptz created_at
    }

    DISCIPLINE_RULE {
        uuid        id                    PK
        uuid        discipline_profile_id FK
        text        rule_key
        text        rule_type    "enum"
        text        condition
        text        effect
        string      applies_to
        string      depends_on
        text        display_name
        text        description
        bool        auto_score_zero
        string      affects_other_fields
        int         display_order
        timestamptz created_at
    }

    LANDING_TABLE {
        uuid        id                    PK
        uuid        owner_account_id      FK "optional; null for a system table"
        text        name
        text        input_unit               "enum, meters, feet, points"
        timestamptz created_at
    }

    LANDING_RESULT {
        uuid id               PK
        uuid landing_table_id FK
        text entry_key
        text display_value
        int  point_value         "points awarded"
        int  ordinal_position
    }

    CONTEST_CONFIGURATION_REVISION {
        uuid      id                    PK
        uuid      contest_id            FK
        int       revision_number          "highest is current"
        uuid      discipline_profile_id FK
        uuid      source_preset_id      FK "optional; provenance only"
        jsonb     config                   "core and discipline; full resolved"
        uuid      landing_table_id      FK "optional"
        uuid      created_by            FK
        text      notes                    "optional"
        timestamp created_at
    }

    %% Matrix / Assignments
    MATRIX_ASSIGNMENT {
        uuid        id                          PK
        uuid        contest_id                  FK
        uuid        matrix_revision_id          FK
        uuid        contest_participation_id    FK
        uuid        scheduled_round_id          FK
        uuid        credited_round_id           FK
        int         group
        int         lane                           "optional; null when lane mode is None"
        int         flight_sequence
        text        assignment_type                "enum, Original, Moved, Reflight, LateAdd"
        uuid        source_assignment_id        FK "optional"
        uuid        re_flight_id                FK "optional"
        uuid        superseded_by_assignment_id FK "optional, write-once"
        uuid        actor_id                    FK
        text        reason
        text        existing_score_handling        "enum, None, Reset"
        int         reset_score_revision           "optional"
        timestamptz created_at
    }

    MATRIX_REVISION {
        uuid        id                   PK
        uuid        contest_id           FK
        int         revision_number
        uuid        previous_revision_id FK "optional"
        int         first_round
        int         last_round
        text        draw_mode    "enum"
        bigint      random_seed
        text        algorithm_version
        jsonb       draw_config
        jsonb       seeding_snapshot
        jsonb       fairness_summary
        text        reason
        uuid        created_by           FK
        timestamptz created_at
        uuid        finalized_by         FK "optional"
        timestamptz finalized_at            "optional"
    }

    ROUND {
        uuid id                     PK
        uuid contest_id             FK
        uuid matrix_revision_id     FK
        int  ordinal
        int  group_count
        text status    "enum"
        int  revision
        uuid superseded_by_round_id FK "optional, write-once"
    }

    ROUND_GROUP {
        uuid        id           PK
        uuid        contest_id   FK
        uuid        round_id     FK
        int         group_number
        text        status          "enum, Open, Locked"
        uuid        locked_by    FK "optional"
        timestamptz locked_at       "optional"
        int         revision
    }

    RE_FLIGHT {
        uuid        id                       PK
        uuid        contest_id               FK
        uuid        credited_round_id        FK
        uuid        source_round_id          FK
        int         source_group
        text        type                        "enum, MoveToGroup, RandomDraw, ReflyEntireGroup"
        int         sequence                    "per source group"
        uuid        previous_reflight_id     FK "optional"
        text        status                      "enum, Proposed, DrawPending, AwaitingResponses, ReadyToFly, Finalized, Cancelled"
        text        reason
        uuid        scheduled_round_id       FK
        int         flown_group                 "may exceed the round group_count"
        bool        deviation_acknowledged
        int         requested_group_size        "optional"
        int         achievable_max_size         "optional"
        bool        size_exception_confirmed
        bigint      random_seed                 "optional"
        text        algorithm_version           "optional"
        uuid        config_revision_id       FK "decided under"
        uuid        created_by               FK
        timestamptz created_at
        uuid        group_finalized_by       FK "optional"
        timestamptz group_finalized_at          "optional"
        uuid        finalized_by             FK "optional"
        timestamptz finalized_at                "optional"
        uuid        cancelled_by             FK "optional"
        timestamptz cancelled_at                "optional"
        text        cancel_reason               "optional"
        int         revision
    }

    RE_FLIGHT_PARTICIPANT {
        uuid        id                       PK
        uuid        contest_id               FK
        uuid        re_flight_id             FK
        uuid        contest_participation_id FK
        text        role                        "enum, Awarded, Drawn, GroupMember, Candidate, Excluded"
        text        excluded_reason             "enum, optional"
        int         draw_position               "optional"
        text        response                    "enum, NotRequired, Pending, Accepted, Declined"
        text        responded_by                "enum, optional; Participant or Director"
        timestamptz responded_at                "optional"
        text        notification_state          "enum, NotRequired, Pending, Delivered, Failed"
        timestamptz notified_at                 "optional"
        timestamptz acknowledged_at             "optional"
        uuid        assignment_id            FK "optional"
        int         revision
    }

    %% Scores and Results
    SCORE_PLACEHOLDER {
        uuid        id                       PK
        uuid        contest_id               FK
        uuid        contest_participation_id FK
        uuid        assignment_id            FK
        text        state    "enum"
        int         score_revision
        uuid        locked_by                FK "optional"
        timestamptz locked_at                   "optional"
        int         revision
    }

    SCORE_ATTEMPT {
        uuid  id                   PK
        uuid  contest_id           FK
        uuid  score_placeholder_id FK
        uuid  config_revision_id   FK
        uuid  matrix_revision_id   FK
        jsonb raw_components
        uuid  actor_id             FK
        text  authority    "enum"
        uuid  invitation_id        FK "optional"
        text  source_device
        text  client_mutation_id
        int   base_score_revision
    }

    OFFICIAL_SCORE {
        uuid      id                   PK
        uuid      contest_id           FK
        uuid      score_placeholder_id FK
        uuid      score_attempt_id     FK
        int       score_revision
        jsonb     components
        timestamp set_at
        uuid      set_by               FK
        text      reason
    }

    FLIGHT_RESULT {
        uuid        id                       PK
        uuid        contest_id               FK
        uuid        score_placeholder_id     FK "unique"
        uuid        official_score_id        FK "computed from"
        uuid        contest_participation_id FK
        uuid        credited_round_id        FK
        text        outcome                     "enum, Scored, Zero"
        decimal     raw_points                  "discipline raw score"
        decimal     landing_points              "optional"
        decimal     flight_penalty_points       "optional; discipline plus entered flight penalty"
        int         cumulative_penalty          "optional; copy of the official component"
        decimal     group_score                 "normalized round result"
        bool        is_selected                 "supplies the round result"
        bool        is_preliminary
        uuid        config_revision_id       FK "calculated under"
        uuid        matrix_revision_id       FK
        text        calculation_version
        timestamptz computed_at
    }

    PARTICIPATION_STANDING {
        uuid        id                       PK
        uuid        contest_id               FK
        uuid        contest_participation_id FK
        int         as_of_round                 "round ordinal; not an FK"
        int         place
        bool        is_tied
        decimal     raw_total                   "before drops and penalties"
        jsonb       dropped_rounds
        decimal     penalty_total               "sum of cumulative penalties"
        decimal     overall_score
        bool        is_preliminary
        uuid        config_revision_id       FK "calculated under"
        uuid        matrix_revision_id       FK
        text        calculation_version
        timestamptz computed_at
    }

    TEAM_STANDING {
        uuid        id                     PK
        uuid        contest_id             FK
        uuid        team_id                FK
        int         as_of_round               "round ordinal; not an FK"
        int         place
        bool        is_tied
        decimal     team_score
        jsonb       counted_participations    "highest score first"
        bool        is_preliminary
        uuid        config_revision_id     FK "calculated under"
        uuid        matrix_revision_id     FK
        text        calculation_version
        timestamptz computed_at
    }

    %% Publication
    PUBLICATION_PARTICIPANT {
        uuid        id                      PK
        uuid        publication_id          FK
        text        pilot_key
        uuid        source_participation_id    "optional; no FK; cleared when the contest is deleted"
        jsonb       details                    "optional; null once redacted"
        uuid        public_profile_id       FK "optional"
        timestamptz redacted_at                "optional"
        timestamptz created_at
        timestamptz updated_at
    }

    DELIST_REQUEST {
        uuid        id             PK
        uuid        publication_id FK
        uuid        requested_by   FK
        text        trigger           "enum, owner_request, account_closure"
        text        reason            "optional"
        timestamptz requested_at
        text        state             "enum, pending, approved, denied, withdrawn"
        uuid        decided_by     FK "optional"
        timestamptz decided_at        "optional"
        text        decision_note     "optional"
    }

    PUBLICATION_IDENTITY {
        uuid        id                           PK
        uuid        contest_id                   FK "optional; null once the contest is deleted"
        uuid        owner_public_profile_id      FK "optional; null while unclaimed"
        text        claim_status                    "enum, Unclaimed, Claimed"
        text        verification_email              "optional"
        text        visibility                      "enum, Unlisted, Public, Delisted"
        timestamptz published_at                    "optional"
        uuid        current_projection_id        FK "optional"
        int         results_hidden_through_round    "optional"
        timestamptz results_hidden_at               "optional"
        int         revision
    }

    PUBLICATION_PROJECTION {
        uuid        id                       PK
        uuid        publication_id           FK
        int         projection_revision
        int         contest_revision            "source number; not an FK"
        int         config_revision             "source number; not an FK"
        int         matrix_revision             "source number; not an FK"
        text        discipline_type    "enum"
        int         discipline_rules_version
        text        calculation_version
        jsonb       contest_identity
        jsonb       participants                "optional; pilot_key only"
        jsonb       teams                       "optional"
        jsonb       matrix_info                 "optional"
        jsonb       scores                      "optional"
        jsonb       standings                   "optional; after each completed round"
        jsonb       calculation_metadata        "optional"
        timestamptz published_at
        uuid        published_by             FK "optional; null for anonymous"
        text        client_mutation_id          "unique per publication"
    }

    %% Synchronization and Audit
    INSTALLATION {
        uuid        id               PK
        uuid        owner_account_id FK "the owning director"
        text        label
        text        platform            "enum, Web, Windows, Other"
        timestamptz created_at
        timestamptz last_seen_at        "optional"
        timestamptz last_sync_at        "optional"
        bigint      system_data_seq     "system data applied; comes down only"
        timestamptz revoked_at          "optional"
    }

    INSTALLATION_ACTIVATION {
        uuid        id              PK
        uuid        contest_id      FK
        uuid        installation_id FK
        uuid        activated_by    FK
        text        kind               "enum, Initial, Replacement, Reclaim"
        timestamptz activated_at
        timestamptz ended_at           "optional; one open row per contest"
    }

    SYNC_CURSOR {
        uuid        id                   PK
        uuid        installation_id      FK
        uuid        contest_id           FK "one of contest_id or owner_account_id"
        uuid        owner_account_id     FK "director data scope"
        bigint      last_synced_sequence
        timestamptz last_synced_at          "optional"
        timestamptz updated_at
    }

    MUTATION_RECORD {
        uuid        id                     PK
        uuid        contest_id             FK "one of contest_id or owner_account_id"
        uuid        owner_account_id       FK "director data scope"
        bigint      sequence                  "assigned when accepted"
        text        entity_type
        uuid        entity_id
        int         base_revision             "optional"
        text        client_mutation_id        "unique per scope"
        uuid        actor_id               FK "optional"
        text        authority "enum, Director, Participant, Helper, System, Administrator"
        uuid        source_installation_id FK "optional"
        text        source_device             "optional"
        timestamptz client_time
        timestamptz server_acceptance_time    "optional"
        timestamptz server_rejection_time     "optional"
        jsonb       payload
        text        outcome                   "enum, Pending, Accepted, Rejected, Conflict, Skipped"
        text        reason_code               "optional"
        text        error_message             "optional"
        uuid        depends_on_mutation_id FK "optional"
    }

    CONFLICT_RECORD {
        uuid        id                    PK
        uuid        contest_id            FK "one of contest_id or owner_account_id"
        uuid        owner_account_id      FK "director data scope"
        text        entity_type
        uuid        entity_id
        uuid        accepted_mutation_id  FK "optional"
        uuid        competing_mutation_id FK
        text        reason_code
        text        reason                   "optional"
        bool        requires_action          "false for a silent record"
        text        resolution               "enum, Pending, Automatic, Manual"
        text        resolution_choice        "enum, optional"
        timestamptz created_at
        timestamptz resolved_at              "optional"
        uuid        resolved_by           FK "optional"
    }

    TOMBSTONE {
        uuid        id               PK
        uuid        contest_id       FK "one of contest_id or owner_account_id"
        uuid        owner_account_id FK "director data scope"
        text        entity_type
        uuid        entity_id
        text        status              "enum, Pending, Acknowledged"
        timestamptz deleted_at
        timestamptz acknowledged_at     "optional"
        timestamptz purge_after         "acknowledged plus 90 days"
        text        deletion_reason     "optional"
    }

    INVITATION {
        uuid        id                       PK
        uuid        contest_id               FK
        uuid        contest_participation_id FK
        text        type                        "enum, MagicURL, QRCode"
        text        protected_credential
        int         invitation_revision         "increases per participation"
        text        state                       "enum, Active, Replaced, Revoked, Expired"
        text        audience                    "enum, Pilot, Helper"
        uuid        issued_by                FK
        timestamptz issued_at
        timestamptz expires_at                  "optional; null for QR tokens"
        timestamptz first_used_at               "optional"
        timestamptz last_used_at                "optional"
        timestamptz revoked_at                  "optional"
        uuid        replaces_invitation_id   FK "optional"
        uuid        redeemed_by_account_id   FK "optional"
        jsonb       delivery_outcomes           "optional"
        text        client_mutation_id          "unique per contest"
    }

    REVIEW_REQUEST {
        uuid        id                   PK
        uuid        contest_id           FK
        uuid        score_placeholder_id FK
        jsonb       proposed_components
        text        participant_message     "optional"
        uuid        requester_id         FK
        int         base_score_revision
        timestamptz requested_at
        text        state                   "enum, Submitted, UnderReview, Approved, Rejected, Superseded"
        uuid        decision_actor_id    FK "optional"
        timestamptz decision_time           "optional"
        text        decision_message        "optional"
        uuid        resulting_attempt_id FK "optional"
        int         revision
    }

    AUDIT_EVENT {
        uuid        id                 PK
        uuid        contest_id         FK "optional"
        uuid        owner_account_id   FK "optional; director data scope"
        uuid        publication_id        "optional; not an FK"
        text        entity_type
        uuid        entity_id
        text        action    "enum"
        uuid        actor_id           FK "optional"
        text        authority "enum, Director, Participant, Helper, System, Administrator"
        uuid        installation_id    FK "optional"
        text        device                "optional"
        int         base_revision         "optional"
        int         resulting_revision    "optional"
        timestamptz server_timestamp
        timestamptz client_timestamp      "optional; audit only"
        text        reason                "optional"
        text        outcome               "enum, Success, Rejected, Conflict"
    }

    %% Relationships
    ACCOUNT ||--o{ ACCOUNT_IDENTITY : "signs in with"
    ACCOUNT |o--o| ACCOUNT_PUBLIC_PROFILE : "publicly represented by"
    ACCOUNT |o--o{ CONTEST : "owns (optional)"
    ACCOUNT ||--o{ PARTICIPANT_ACCOUNT_LINK : "linked via"
    ACCOUNT ||--o{ PARTICIPANT_PROFILE : "owns (director)"
    ACCOUNT |o--o| PARTICIPANT_DIRECTORY_ENTRY : "offers"
    PARTICIPANT_PROFILE ||--o{ PARTICIPANT_ACCOUNT_LINK : "linked via"
    ACCOUNT ||--o{ CONTEST_CONFIGURATION_PRESET : "owns"
    ACCOUNT ||--o{ CONTEST_CONFIGURATION_REVISION : "created"
    ACCOUNT |o--o{ LANDING_TABLE : "authored"

    CONTEST ||--o{ CONTEST_CONFIGURATION_REVISION : "has revisions"
    CONTEST ||--o{ MATRIX_REVISION : "has revisions"
    CONTEST ||--o{ ROUND : "has"
    CONTEST ||--o{ SYNC_CURSOR : "has cursors"
    CONTEST ||--o{ TEAM : "has teams"
    CONTEST ||--o{ CONTEST_PARTICIPATION : "has participations"
    CONTEST ||--o{ CONTEST_MODEL_LINK : "has links"
    CONTEST ||--o{ RE_FLIGHT : "has"
    CONTEST ||--o{ INVITATION : "has"
    CONTEST |o--o{ AUDIT_EVENT : "has events"
    PUBLICATION_IDENTITY |o--o{ AUDIT_EVENT : "audited by"
    CONTEST ||--o{ MUTATION_RECORD : "has"
    CONTEST ||--o{ CONFLICT_RECORD : "has"
    CONTEST ||--o{ TOMBSTONE : "has"
    CONTEST ||--o{ SCORE_PLACEHOLDER : "denormalized contest_id"
    CONTEST ||--o{ SCORE_ATTEMPT : "denormalized contest_id"
    CONTEST ||--o{ OFFICIAL_SCORE : "denormalized contest_id"
    CONTEST |o--o| PUBLICATION_IDENTITY : "published as"

    PARTICIPANT_PROFILE ||--o{ CONTEST_PARTICIPATION : "profile for"
    CONTEST_PARTICIPATION ||--o{ CONTEST_MODEL_LINK : "enters models"
    MODEL_CATALOG |o--o{ CONTEST_MODEL_LINK : "catalog source"
    TEAM ||--o{ TEAM_MEMBERSHIP : "has members"
    CONTEST_PARTICIPATION ||--o| TEAM_MEMBERSHIP : "is member via"
    ROLE ||--o{ CONTEST_PARTICIPATION : "assigned to"
    ACCOUNT |o--o{ ROLE : "owns"
    CONTEST ||--o{ TEAM_MEMBERSHIP : "denormalized contest_id"
    CONTEST_PARTICIPATION ||--o{ INVITATION : "has invitations"
    INVITATION |o--o| INVITATION : "replaces"
    ACCOUNT ||--o{ INVITATION : "issues"
    ACCOUNT |o--o{ INVITATION : "redeems"
    CONTEST_PARTICIPATION ||--o{ MATRIX_ASSIGNMENT : "flies"
    CONTEST_PARTICIPATION ||--o{ SCORE_PLACEHOLDER : "has placeholders"

    MATRIX_REVISION ||--o{ ROUND : "contains"
    MATRIX_REVISION ||--o{ MATRIX_ASSIGNMENT : "contains"
    MATRIX_REVISION |o--o| MATRIX_REVISION : "extends"
    ROUND ||--o{ MATRIX_ASSIGNMENT : "scheduled in"
    ROUND ||--o{ MATRIX_ASSIGNMENT : "credited to"
    ROUND |o--o| ROUND : "superseded by"
    ROUND ||--o{ ROUND_GROUP : "contains"
    CONTEST ||--o{ ROUND_GROUP : "denormalized contest_id"
    ROUND_GROUP ||--o{ MATRIX_ASSIGNMENT : "flown in"
    ACCOUNT |o--o{ ROUND_GROUP : "locks"
    ACCOUNT |o--o{ SCORE_PLACEHOLDER : "locks"
    MATRIX_ASSIGNMENT |o--o{ MATRIX_ASSIGNMENT : "source of"
    MATRIX_ASSIGNMENT |o--o| MATRIX_ASSIGNMENT : "superseded by"
    RE_FLIGHT |o--o{ MATRIX_ASSIGNMENT : "creates"
    RE_FLIGHT |o--o| RE_FLIGHT : "follows"
    RE_FLIGHT ||--o{ RE_FLIGHT_PARTICIPANT : "involves"
    CONTEST ||--o{ RE_FLIGHT_PARTICIPANT : "denormalized contest_id"
    CONTEST_PARTICIPATION ||--o{ RE_FLIGHT_PARTICIPANT : "takes part as"
    MATRIX_ASSIGNMENT |o--o| RE_FLIGHT_PARTICIPANT : "created for"
    ROUND ||--o{ RE_FLIGHT : "credited to"
    ROUND ||--o{ RE_FLIGHT : "flown in"
    CONTEST_CONFIGURATION_REVISION ||--o{ RE_FLIGHT : "decided under"
    MATRIX_ASSIGNMENT ||--o| SCORE_PLACEHOLDER : "scored by"

    SCORE_PLACEHOLDER ||--o{ SCORE_ATTEMPT : "has attempts"
    SCORE_PLACEHOLDER ||--o{ OFFICIAL_SCORE : "has versions"
    SCORE_PLACEHOLDER ||--o{ REVIEW_REQUEST : "has"
    SCORE_ATTEMPT ||--o{ OFFICIAL_SCORE : "produces"
    INVITATION |o--o{ SCORE_ATTEMPT : "submitted under"
    CONTEST_CONFIGURATION_REVISION ||--o{ SCORE_ATTEMPT : "entered under"
    MATRIX_REVISION ||--o{ SCORE_ATTEMPT : "entered under"
    SCORE_PLACEHOLDER ||--o| FLIGHT_RESULT : "calculated as"
    OFFICIAL_SCORE ||--o{ FLIGHT_RESULT : "computed from"
    CONTEST_PARTICIPATION ||--o{ PARTICIPATION_STANDING : "has"
    TEAM ||--o{ TEAM_STANDING : "has"
    CONTEST ||--o{ FLIGHT_RESULT : "denormalized contest_id"
    CONTEST ||--o{ PARTICIPATION_STANDING : "denormalized contest_id"
    CONTEST ||--o{ TEAM_STANDING : "denormalized contest_id"
    CONTEST_CONFIGURATION_REVISION ||--o{ FLIGHT_RESULT : "calculated under"
    CONTEST_CONFIGURATION_REVISION ||--o{ PARTICIPATION_STANDING : "calculated under"
    CONTEST_CONFIGURATION_REVISION ||--o{ TEAM_STANDING : "calculated under"
    MATRIX_REVISION ||--o{ FLIGHT_RESULT : "calculated under"
    MATRIX_REVISION ||--o{ PARTICIPATION_STANDING : "calculated under"
    MATRIX_REVISION ||--o{ TEAM_STANDING : "calculated under"

    DISCIPLINE_PROFILE ||--o{ CONTEST_CONFIGURATION_PRESET : "based on"
    DISCIPLINE_PROFILE ||--o{ CONTEST_CONFIGURATION_REVISION : "selected by"
    CONTEST_CONFIGURATION_PRESET |o--o{ CONTEST_CONFIGURATION_REVISION : "source preset"
    LANDING_TABLE |o--o{ CONTEST_CONFIGURATION_PRESET : "selected by"
    DISCIPLINE_PROFILE |o--o| DISCIPLINE_PROFILE : "superseded by"
    ACCOUNT ||--o{ DISCIPLINE_PROFILE : "authored"
    DISCIPLINE_PROFILE ||--o{ DISCIPLINE_CONFIG_FIELD : "defines"
    DISCIPLINE_PROFILE ||--o{ DISCIPLINE_SCORE_FIELD : "defines"
    DISCIPLINE_PROFILE ||--o{ DISCIPLINE_VALIDATION : "defines"
    DISCIPLINE_PROFILE ||--o{ DISCIPLINE_FORMULA : "defines"
    DISCIPLINE_PROFILE ||--o{ DISCIPLINE_RULE : "defines"
    LANDING_TABLE |o--o{ DISCIPLINE_PROFILE : "default for"
    LANDING_TABLE ||--o{ LANDING_RESULT : "contains"
    LANDING_TABLE |o--o{ CONTEST_CONFIGURATION_REVISION : "selected by"

    PUBLICATION_IDENTITY ||--o{ PUBLICATION_PROJECTION : "has"
    ACCOUNT |o--o{ PUBLICATION_PROJECTION : "published"
    PUBLICATION_IDENTITY ||--o{ PUBLICATION_PARTICIPANT : "identifies pilots"
    PUBLICATION_IDENTITY ||--o{ DELIST_REQUEST : "subject of"
    ACCOUNT_PUBLIC_PROFILE |o--o{ PUBLICATION_PARTICIPANT : "supports results of"
    ACCOUNT_PUBLIC_PROFILE |o--o{ PUBLICATION_IDENTITY : "owns"
    ACCOUNT ||--o{ DELIST_REQUEST : "requests"
    ACCOUNT |o--o{ DELIST_REQUEST : "decides"
    MUTATION_RECORD |o--o{ CONFLICT_RECORD : "accepted"
    MUTATION_RECORD ||--o{ CONFLICT_RECORD : "competing"
    MUTATION_RECORD |o--o{ MUTATION_RECORD : "depends on"
    ACCOUNT ||--o{ INSTALLATION : "owns"
    ACCOUNT ||--o{ INSTALLATION_ACTIVATION : "activates"
    CONTEST ||--o{ INSTALLATION_ACTIVATION : "authority history"
    INSTALLATION ||--o{ INSTALLATION_ACTIVATION : "holds authority via"
    INSTALLATION ||--o{ SYNC_CURSOR : "tracked by"
    INSTALLATION |o--o{ MUTATION_RECORD : "submitted"
    INSTALLATION |o--o{ AUDIT_EVENT : "originated"
    ACCOUNT |o--o{ MUTATION_RECORD : "acts"
    CONTEST ||--o{ REVIEW_REQUEST : "denormalized contest_id"
    SCORE_ATTEMPT |o--o| REVIEW_REQUEST : "created on approval"
```
