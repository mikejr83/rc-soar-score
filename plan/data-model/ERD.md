# RC Soar Score Entity Relationship Diagram

ERD for the 44 conceptual entities (43 have an entity document; CONTEST_CONFIGURATION_PRESET does not yet). Physical design: PostgreSQL backend with IndexedDB clients, UUIDv7 identifiers, composite unique constraints on natural business keys.

```mermaid
erDiagram
    %% Accounts and Ownership
    ACCOUNT {
        uuid        id              PK
        text        first_name
        text        last_name
        text        email              "nullable, lowercase"
        bool        email_verified
        text        kind               "registered, guest, local, deleted"
        text        status             "active, archived"
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
        text        lifecycle_state
        text        scoring_access
        text        admin_lock
        bool        local_archive
        int         revision
        int         results_hidden_through_round    "optional"
        timestamptz results_hidden_at               "optional"
        timestamptz created_at
        timestamptz updated_at
    }

    CONTEST_CONFIGURATION_PRESET {
        uuid   id                    PK
        uuid   owner_account_id      FK
        uuid   discipline_profile_id FK
        text   name
        text   description
        string overrides                "jsonb: config field_key -> value"
        int    revision
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
        text        status                    "Candidate, Confirmed, Ended"
        text        origin                    "EmailMatch, DirectoryPull, InvitationRedemption"
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
        text   role_type                 "Pilot, NonFlier"
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
        text        type                "Pilot, NonFlier"
        timestamptz archived_at         "optional"
        int         revision
    }

    TEAM {
        uuid id           PK
        uuid contest_id   FK
        text name
        int  pilot_totals
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
        uuid id                       PK
        uuid contest_id               FK
        uuid contest_participation_id FK
        uuid model_catalog_id         FK "optional"
        text model_name
        text manufacturer
        text model_id
        int  revision
    }

    %% Discipline / Config
    DISCIPLINE_PROFILE {
        uuid      id                       PK
        text      type
        int       version
        text      name
        text      description
        text      category
        uuid      default_landing_table_id FK "optional"
        text      status
        text      superseded_by
        text      created_by
        timestamp created_at
        text      updated_by
        timestamp updated_at
    }

    DISCIPLINE_CONFIG_FIELD {
        uuid   id                    PK
        uuid   discipline_profile_id FK
        text   field_key
        text   field_type
        text   name
        text   description
        bool   required
        string default_value
        string options
        string validation
        int    display_order
    }

    DISCIPLINE_SCORE_FIELD {
        uuid   id                    PK
        uuid   discipline_profile_id FK
        text   field_key
        text   field_type
        text   name
        text   description
        bool   required
        string default_value
        string options
        string validation
        int    display_order
        bool   is_zero_reason
        text   zero_reason_code
    }

    DISCIPLINE_VALIDATION {
        uuid   id                    PK
        uuid   discipline_profile_id FK
        string field_keys
        text   constraint_type
        text   description
        string applies_to
        text   message
        int    display_order
    }

    DISCIPLINE_FORMULA {
        uuid   id                    PK
        uuid   discipline_profile_id FK
        text   formula_key
        text   formula_type
        text   description
        text   formula_text
        string inputs
        string outputs
        string depends_on
        bool   is_primary
        int    display_order
    }

    DISCIPLINE_RULE {
        uuid   id                    PK
        uuid   discipline_profile_id FK
        text   rule_key
        text   rule_type
        text   condition
        text   effect
        string applies_to
        string depends_on
        text   display_name
        text   description
        bool   auto_score_zero
        string affects_other_fields
        int    display_order
    }

    LANDING_TABLE {
        uuid        id                    PK
        uuid        owner_account_id      FK "optional; null for a system table"
        text        name
        text        input_unit               "meters, feet, points"
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
        int       revision_number
        uuid      discipline_profile_id FK
        int       profile_version
        uuid      source_preset_id      FK "optional"
        jsonb     config
        uuid      landing_table_id      FK "optional"
        uuid      created_by            FK
        text      notes
        timestamp created_at
        uuid      replaces_revision_id  FK "optional"
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
        int         lane
        int         flight_sequence
        text        assignment_type                "Original, Moved, Reflight, LateAdd"
        uuid        source_assignment_id        FK "optional"
        uuid        re_flight_id                FK "optional"
        uuid        superseded_by_assignment_id FK "optional, write-once"
        uuid        actor_id                    FK
        text        reason
        timestamptz created_at
    }

    MATRIX_REVISION {
        uuid        id                   PK
        uuid        contest_id           FK
        int         revision_number
        uuid        previous_revision_id FK "optional"
        int         first_round
        int         last_round
        text        draw_mode
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
        text status
        int  revision
        uuid superseded_by_round_id FK "optional, write-once"
    }

    RE_FLIGHT {
        uuid   id                PK
        uuid   contest_id        FK
        int    credited_round
        string type
        int    sequence
        string lifecycle_status
        string reasons
        string awards
        string selected_pilots
        string exclusion
        string responses
        string notifications
        string director_decision
        int    revision
    }

    %% Scores and Results
    SCORE_PLACEHOLDER {
        uuid id                       PK
        uuid contest_id               FK
        uuid contest_participation_id FK
        uuid assignment_id            FK
        text state
        int  score_revision
        int  revision
    }

    SCORE_ATTEMPT {
        uuid  id                   PK
        uuid  contest_id           FK
        uuid  score_placeholder_id FK
        uuid  config_revision_id   FK
        uuid  matrix_revision_id   FK
        jsonb raw_components
        uuid  actor_id             FK
        text  authority
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
        text        outcome                     "Scored, Zero"
        decimal     raw_points                  "discipline raw score"
        decimal     landing_points              "optional"
        decimal     flight_penalty_points       "optional"
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
        text        trigger           "owner_request, account_closure"
        text        reason            "optional"
        timestamptz requested_at
        text        state             "pending, approved, denied, withdrawn"
        uuid        decided_by     FK "optional"
        timestamptz decided_at        "optional"
        text        decision_note     "optional"
    }

    PUBLICATION_IDENTITY {
        uuid        id                           PK
        uuid        contest_id                   FK "optional; null once the contest is deleted"
        uuid        owner_public_profile_id      FK "optional; null while unclaimed"
        text        claim_status                    "Unclaimed, Claimed"
        text        verification_email              "optional"
        text        visibility                      "Unlisted, Public, Delisted"
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
        text        discipline_type
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
    SYNC_CURSOR {
        uuid      id                   PK
        uuid      contest_id           FK
        int       last_synced_sequence
        timestamp updated_at
    }

    MUTATION_RECORD {
        uuid      id                  PK
        uuid      entity_id
        text      entity_type
        uuid      contest_id          FK
        int       base_revision
        string    client_mutation_id
        uuid      actor_id
        text      authority
        string    source_installation
        timestamp client_time
        timestamp server_time
        text      outcome
        int       revision
    }

    CONFLICT_RECORD {
        uuid      id                 PK
        uuid      entity_id
        uuid      winner_mutation_id FK
        uuid      loser_mutation_id  FK
        text      reason
        text      resolution
        timestamp resolved_at
        uuid      resolved_by        FK
    }

    TOMBSTONE {
        uuid   id              PK
        uuid   entity_id
        text   entity_type
        uuid   contest_id      FK
        text   status
        string deletion_reason
    }

    INVITATION {
        uuid        id                       PK
        uuid        contest_id               FK
        uuid        contest_participation_id FK
        text        type                        "MagicURL, QRCode"
        text        protected_credential
        int         invitation_revision         "increases per participation"
        text        state                       "Active, Replaced, Revoked, Expired"
        text        audience                    "Pilot, Helper"
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
        uuid      id                   PK
        uuid      score_placeholder_id FK
        string    proposed_components
        string    participant_message
        uuid      requester_id
        int       base_score_revision
        timestamp requested_at
        text      state
        uuid      decision_actor_id
        timestamp decision_time
        string    decision_message
    }

    AUDIT_EVENT {
        uuid      id                 PK
        uuid      contest_id         FK "optional"
        uuid      publication_id        "optional; not an FK"
        text      entity_type
        uuid      entity_id
        text      action
        uuid      actor_id           FK
        text      authority
        string    installation
        int       base_revision
        int       resulting_revision
        timestamp server
        timestamp client
        text      reason
        text      outcome
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
    MATRIX_ASSIGNMENT |o--o{ MATRIX_ASSIGNMENT : "source of"
    MATRIX_ASSIGNMENT |o--o| MATRIX_ASSIGNMENT : "superseded by"
    RE_FLIGHT |o--o{ MATRIX_ASSIGNMENT : "creates"
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
    CONTEST_CONFIGURATION_REVISION |o--o| CONTEST_CONFIGURATION_REVISION : "replaces"
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
    MUTATION_RECORD |o--o{ CONFLICT_RECORD : "winner"
    MUTATION_RECORD |o--o{ CONFLICT_RECORD : "loser"
```
