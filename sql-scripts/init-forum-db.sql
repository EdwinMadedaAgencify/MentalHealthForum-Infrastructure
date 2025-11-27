-- -----------------------------------------------------------
-- Mental Health Support Forum Database Schema V22 (PostgreSQL)
-- All primary keys use UUIDs for consistency and scalability.
-- -----------------------------------------------------------

-- ============================================================================================================================
--                                              USER PROFILE & IDENTITY
-- ============================================================================================================================
-- Supporting ENUM Types
CREATE TYPE support_role_enum AS ENUM (
    'NOT_SPECIFIED',      -- Default: user hasn't chosen yet or prefers not to say
    'SEEKING_SUPPORT',    -- "I'm here to find support"
    'OFFERING_SUPPORT',   -- "I'm here to help others"
    'BOTH'                -- "I seek and offer support"
    );

-- Main app_users table
CREATE TABLE IF NOT EXISTS app_users (
    -- Identity
                             id UUID PRIMARY KEY DEFAULT gen_random_uuid(), -- Internal DB Primary Key (UUID)
                             keycloak_id UUID NOT NULL, -- The unique Keycloak UUID (sub claim)

    -- Synced from Keycloak
                             email VARCHAR(255) NOT NULL,
                             username VARCHAR(255) NOT NULL,
                             first_name VARCHAR(255) NOT NULL,
                             last_name VARCHAR(255) NOT NULL,

    -- Cached/display-only fields from Keycloak
                             is_enabled BOOLEAN,
                             roles TEXT[],
                             groups TEXT[],
                             last_synced_at TIMESTAMP DEFAULT NULL, -- Last sync with Keycloak

    -- Application-specific profile data (Source of Truth is this database)
                             display_name VARCHAR(100),
                             avatar_url TEXT,
                             bio TEXT,
                             bio_html TEXT, -- Optional: Rich-text bio
                             timezone VARCHAR(50) DEFAULT 'UTC',
                             language VARCHAR(10) DEFAULT 'en',
    -- User preferences
                             prefers_anonymity BOOLEAN DEFAULT FALSE,  -- This controls whether the user is anonymous or not
                             support_role support_role_enum DEFAULT 'NOT_SPECIFIED', -- User's stated purpose
                             notification_preferences    JSONB DEFAULT '{
                               "in_app": {
                                 "replies": true,
                                 "reactions": true,
                                 "follows": true,
                                 "moderation": true,
                                 "system": true
                               },
                               "email": {
                                 "replies": false,
                                 "reactions": false,
                                 "follows": false,
                                 "moderation": true,
                                 "system": false
                               }
                             }'::jsonb,

    -- Metrics
                             posts_count INT DEFAULT 0,
                             reputation_score NUMERIC(10,2) DEFAULT 0.0,

    -- Timestamps
                             date_joined TIMESTAMP   NOT NULL,
                             last_active_at TIMESTAMP  ,
                             last_posted_at TIMESTAMP  ,

    -- Account lifecycle
                             is_active                   BOOLEAN DEFAULT TRUE,
                             account_deletion_requested_at TIMESTAMP   DEFAULT NULL  -- For GDPR compliance
);

-- Index for fast lookups
CREATE UNIQUE INDEX idx_unique_display_name ON app_users (display_name);
CREATE UNIQUE INDEX idx_keycloak_id ON app_users (keycloak_id);
CREATE INDEX idx_users_active ON app_users (is_active, last_active_at DESC);
CREATE INDEX idx_users_reputation ON app_users (reputation_score DESC);


-- ============================================================================================================================
--                                        FORUM CATEGORIES - HIERARCHICAL & TAGGED
-- ============================================================================================================================
-- Supporting ENUM Types
CREATE TYPE content_warning_enum AS ENUM (
    'NONE',
    'SELF_HARM',
    'SUICIDE',
    'TRAUMA',
    'ABUSE',
    'VIOLENCE',
    'SUBSTANCE_USE',
    'EATING_DISORDERS'
    );

-- Main forum_categories table
CREATE TABLE forum_categories (
                              id                          UUID PRIMARY KEY DEFAULT gen_random_uuid(),  -- Primary key (UUID)
                              name                        VARCHAR(100) NOT NULL UNIQUE,                 -- Category name (unique)
                              slug                        VARCHAR(100) NOT NULL UNIQUE,                 -- Slug for URL
                              description                 TEXT,                                          -- Description of the category

    -- Visual Design
                              color_theme                 VARCHAR(50),  -- Color scheme for UI differentiation (e.g., 'blue-500')

    -- Hierarchy (one level only: parent → child, no grandchildren)
                              parent_category_id          UUID REFERENCES forum_categories(id) ON DELETE CASCADE,  -- Parent category (nullable)

    -- Access Control (role-based access) for the category
                              participation_requirements     JSONB DEFAULT '{}'::jsonb, --  (jsonb: min_reputation, required_roles, etc.)
                                -- Example structure:
                                -- {
                                --   "view_access": "PUBLIC",                   // Who can VIEW: "PUBLIC", "MEMBERS_ONLY", "VERIFIED_ONLY", "MODERATORS_ONLY"
                                --   "post_requirements": {
                                --     "min_reputation": 50,                    // Need 50+ reputation to post
                                --     "required_roles": ["trusted_member"],    // Must have this role
                                --     "min_account_age_days": 7,               // Account must be 7+ days old
                                --     "max_posts_per_day": 10                  // Rate limiting for this category
                                --   }
                                -- }

    -- Safety Features
                              content_warning_type content_warning_enum DEFAULT 'NONE',
                              content_warning_custom_text VARCHAR(255) DEFAULT NULL,  -- Optional additional context

    -- Thread Behavior Settings
                              default_thread_settings     JSONB DEFAULT '{}'::jsonb,  -- JSONB for evolving settings (e.g., auto_lock, approval required)
                                -- Example structure:
                                -- {
                                --   "auto_lock_after_days": 90,                // Lock threads after 90 days of inactivity
                                --   "auto_archive_after_days": 180,            // (Hide) Archive old threads
                                --   "require_moderator_approval": true,        // New threads need approval first
                                --   "max_posts_per_thread": 500,               // Split long threads
                                --   "allow_anonymous_posts": true              // Override global anonymity settings
                                -- }

    -- Category Status & Sorting
                              is_active                   BOOLEAN DEFAULT TRUE NOT NULL,  -- Whether the category is active
                              sort_order                  INTEGER DEFAULT 0 NOT NULL,    -- Sort order for display (manual control by admin)
                                                                                         -- Lower numbers appear first (e.g., `sort_order = 1` shows before `sort_order = 10`)
                                                                                         -- Allows admins to manually arrange categories: "Crisis Support" at top, "General Chat" at bottom
                              created_at                  TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL  -- Timestamp of creation

-- Constraint: parent categories cannot have parents themselves (One level of hierarchy only)
                                  CHECK (parent_category_id IS NULL OR
                                         (SELECT parent_category_id FROM forum_categories WHERE id = parent_category_id) IS NULL)
);

-- Indexes for optimization
CREATE INDEX idx_category_active_sort ON forum_categories (is_active DESC, sort_order ASC);
CREATE INDEX idx_category_slug ON forum_categories (slug);
CREATE INDEX idx_category_parent_id ON forum_categories (parent_category_id);

-- Category Tags Table (Flexible Classification via Tags)
CREATE TABLE category_tags (
                               id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),  -- Primary key (UUID)
                               category_id     UUID NOT NULL REFERENCES forum_categories(id) ON DELETE CASCADE,  -- Foreign Key to forum_categories
                               tag_name        VARCHAR(50) NOT NULL,  -- Tag name (e.g., 'crisis-support', 'peer-reviewed')
                               tag_description TEXT,  -- Optional description of the tag
                               created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,  -- Timestamp of tag creation
                               UNIQUE(category_id, tag_name)  -- Ensures no duplicate tags for a category
);

-- Index for quick searching/filtering by tag name and category
CREATE INDEX idx_category_tags_name ON category_tags(tag_name);
CREATE INDEX idx_category_tags_category ON category_tags(category_id);



-- ============================================================================================================================
--                                        THREADS - LIFECYCLE & METADATA
-- ============================================================================================================================
-- Supporting ENUM Types
CREATE TYPE thread_type_enum AS ENUM (
    'DISCUSSION',      -- General conversation, no specific outcome expected
    'QUESTION',        -- Seeking specific answers/advice
    'CRISIS_SUPPORT',  -- Urgent support needed
    'PEER_REVIEW',     -- Sharing for feedback from peers
    'POLL'             -- Community poll/survey
    );

CREATE TYPE thread_status_enum AS ENUM (
    'OPEN',      -- Active discussion, accepting new posts
    'RESOLVED',  -- Question answered or issue addressed (for QUESTION threads)
    'CLOSED',    -- No longer accepting posts, but still visible
    'ARCHIVED'   -- Old/inactive, hidden from main view but searchable
    );

-- Reuse content_warning_enum from earlier

-- Reference tables for UI/help text
CREATE TABLE thread_type_definitions (
                                         thread_type         thread_type_enum PRIMARY KEY,
                                         display_name        VARCHAR(50) NOT NULL,
                                         description         TEXT NOT NULL,
                                         icon_hint           VARCHAR(50),  -- For UI
                                         example             TEXT
);

-- Seed data:
INSERT INTO thread_type_definitions VALUES
    ('DISCUSSION', 'Discussion', 'Open-ended conversation on a topic. No specific outcome expected.', 'chat', 'Share your thoughts on coping with workplace anxiety'),
    ('QUESTION', 'Question', 'Seeking specific answers or advice from the community.', 'help-circle', 'How do I handle panic attacks in public?'),
    ('CRISIS_SUPPORT', 'Crisis Support', 'Urgent support needed. Peer supporters and moderators will be notified.', 'alert-circle', 'Feeling overwhelmed and need immediate support'),
    ('PEER_REVIEW', 'Peer Review', 'Sharing your story or approach for feedback from others.', 'users', 'I wrote about my journey with depression, would love your thoughts'),
    ('POLL', 'Poll', 'Community survey to gather opinions or preferences.', 'bar-chart', 'What coping strategies work best for you?');

-- Same for status:
CREATE TABLE thread_status_definitions (
                                           thread_status       thread_status_enum PRIMARY KEY,
                                           display_name        VARCHAR(50) NOT NULL,
                                           description         TEXT NOT NULL,
                                           user_visible        BOOLEAN NOT NULL  -- Show to regular users or moderators only?
);

-- Main threads table
CREATE TABLE forum_threads (
                               id                          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                               title                       VARCHAR(255) NOT NULL,
                               creator_id                  UUID REFERENCES app_users(keycloak_id) ON DELETE SET NULL,
                               category_id                 UUID NOT NULL REFERENCES forum_categories(id) ON DELETE RESTRICT,

    -- Type and lifecycle
                               thread_type                 thread_type_enum NOT NULL DEFAULT 'DISCUSSION',
                               status                      thread_status_enum NOT NULL DEFAULT 'OPEN',

    -- Resolution tracking (for QUESTION threads)
                               resolved_at                 TIMESTAMP DEFAULT NULL,
                               resolved_by_user_id         UUID REFERENCES app_users(keycloak_id) ON DELETE SET NULL,
                               best_answer_post_id         UUID REFERENCES forum_posts(id) ON DELETE SET NULL, -- FK added later (after forum_posts exists)

    -- Safety
                               content_warning_type        content_warning_enum DEFAULT 'NONE' NOT NULL,
                               content_warning_custom_text VARCHAR(255) DEFAULT NULL,

    -- Organization
                               tags                        TEXT[],  -- User-generated tags
                               is_sticky                   BOOLEAN DEFAULT FALSE NOT NULL,
                               is_featured                 BOOLEAN DEFAULT FALSE NOT NULL,  -- Moderator highlights
                                                            -- Moderator/admin marks threads everyone should see
                                                            -- Featured badge, pinned to category top
                               is_deleted                  BOOLEAN DEFAULT FALSE NOT NULL,

    -- Advanced settings (evolving)
                               thread_settings             JSONB DEFAULT '{}'::jsonb,
                                -- Example structure:
                                -- {
                                --   "auto_lock_at": "2025-12-31T23:59:59Z",
                                --   "scheduled_post_at": "2025-11-25T10:00:00Z",
                                --   "custom_reminder": "Remember to check the resources pinned at top"
                                -- }

    -- Timestamps
                               created_at                  TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
                               updated_at                  TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
                               last_activity_at            TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,

    -- Cached counts
                               post_count                  INTEGER DEFAULT 0 NOT NULL,
                               view_count                  INTEGER DEFAULT 0 NOT NULL
);

CREATE INDEX idx_thread_activity ON forum_threads (category_id, is_sticky DESC, last_activity_at DESC);
CREATE INDEX idx_thread_status ON forum_threads (status, updated_at DESC);
CREATE INDEX idx_thread_type ON forum_threads (thread_type);
CREATE INDEX idx_thread_featured ON forum_threads (is_featured DESC, created_at DESC) WHERE is_featured = TRUE;
CREATE INDEX idx_thread_creator ON forum_threads (creator_id, created_at DESC);

-- Note: Trigger for updating last_activity_at will be created in POSTS section
-- (after forum_posts table exists)


-- Trigger for last_activity_at
CREATE OR REPLACE FUNCTION update_thread_activity()
    RETURNS TRIGGER AS $$
BEGIN
    UPDATE forum_threads
    SET
        last_activity_at = NEW.created_at,
        post_count = post_count + 1
    WHERE id = NEW.thread_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_thread_activity
    AFTER INSERT ON forum_posts
    FOR EACH ROW
EXECUTE FUNCTION update_thread_activity();

-- ============================================================================================================================
--                                        POSTS - RICHER CONTENT & SAFETY
-- ============================================================================================================================
-- Supporting ENUM Types
CREATE TYPE post_type_enum AS ENUM (
    'REPLY',            -- Standard user response
    'ANSWER',           -- Answer to a QUESTION thread (potential best answer)
    'SYSTEM_MESSAGE',   -- Auto-generated system message
    'MODERATOR_NOTE'    -- Official moderator communication
    );

CREATE TYPE edit_reason_enum AS ENUM (
    'TYPO_FIX',
    'ADDED_CONTEXT',
    'CLARIFICATION',
    'REMOVED_PERSONAL_INFO',
    'CONTENT_POLICY_VIOLATION',
    'FORMATTING',
    'OTHER'
    );

-- Reuse content_warning_enum from earlier

-- Main posts table
CREATE TABLE forum_posts (
                             id                          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                             thread_id                   UUID NOT NULL REFERENCES forum_threads(id) ON DELETE CASCADE,
                             author_id                   UUID REFERENCES app_users(keycloak_id) ON DELETE SET NULL,

    -- Post type and threading
                             post_type                   post_type_enum DEFAULT 'REPLY' NOT NULL,
                             parent_post_id              UUID REFERENCES forum_posts(id) ON DELETE SET NULL,

    -- Content
                             content                     TEXT NOT NULL,
                             word_count                  INTEGER DEFAULT 0 NOT NULL,  -- Calculated on insert/update

    -- Safety
                             content_warning_type        content_warning_enum DEFAULT 'NONE',
                             content_warning_custom_text VARCHAR(255) DEFAULT NULL,
                             flagged_for_review          BOOLEAN DEFAULT FALSE NOT NULL,

    -- Edit tracking
                             is_edited                   BOOLEAN DEFAULT FALSE NOT NULL,
                             edit_reason_type            edit_reason_enum DEFAULT NULL,
                             edit_reason_custom_text     VARCHAR(255) DEFAULT NULL,  -- Used when type = 'OTHER' or to add details
                             edited_by_user_id           UUID REFERENCES app_users(keycloak_id) ON DELETE SET NULL,

    -- Anonymity (Phase 2 - unused in Phase 1)
                             is_anonymous                BOOLEAN DEFAULT FALSE NOT NULL, -- Override user's global preference for THIS post
                             anonymous_identifier        VARCHAR(50) DEFAULT NULL,  -- Consistent pseudonym within thread

    -- Timestamps
                             created_at                  TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
                             updated_at                  TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,

    -- Status
                             is_deleted                  BOOLEAN DEFAULT FALSE NOT NULL,

    -- Cached counts
                             reaction_count              INTEGER DEFAULT 0 NOT NULL,

    -- Constraint: One level of threading only
                             CHECK (parent_post_id IS NULL OR
                                    (SELECT parent_post_id FROM forum_posts WHERE id = parent_post_id) IS NULL)
);

-- Indexes
CREATE INDEX idx_posts_by_thread ON forum_posts (thread_id, created_at ASC);
CREATE INDEX idx_posts_by_author ON forum_posts (author_id, created_at DESC);
CREATE INDEX idx_posts_flagged ON forum_posts (flagged_for_review, created_at DESC) WHERE flagged_for_review = TRUE;
CREATE INDEX idx_posts_parent ON forum_posts (parent_post_id) WHERE parent_post_id IS NOT NULL;
CREATE INDEX idx_posts_type ON forum_posts (post_type, thread_id);

-- Edit history table
CREATE TABLE post_edit_history (
                                   id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                                   post_id                 UUID NOT NULL REFERENCES forum_posts(id) ON DELETE CASCADE,
                                   previous_content        TEXT NOT NULL,
                                   previous_word_count     INTEGER,
                                   edited_at               TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
                                   edited_by               UUID NOT NULL REFERENCES app_users(keycloak_id),
                                   edit_reason_type        edit_reason_enum,
                                   edit_reason_custom_text VARCHAR(255)
);

CREATE INDEX idx_edit_history_post ON post_edit_history(post_id, edited_at DESC);
CREATE INDEX idx_edit_history_user ON post_edit_history(edited_by);

-- Trigger to calculate word_count
CREATE OR REPLACE FUNCTION calculate_word_count()
    RETURNS TRIGGER AS $$
BEGIN
    NEW.word_count := array_length(regexp_split_to_array(trim(NEW.content), '\s+'), 1);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_calculate_word_count
    BEFORE INSERT OR UPDATE OF content ON forum_posts
    FOR EACH ROW
EXECUTE FUNCTION calculate_word_count();

-- Trigger to update thread activity and post_count
CREATE OR REPLACE FUNCTION update_thread_on_post()
    RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE forum_threads
        SET
            last_activity_at = NEW.created_at,
            post_count = post_count + 1
        WHERE id = NEW.thread_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_thread_on_post
    AFTER INSERT ON forum_posts
    FOR EACH ROW
EXECUTE FUNCTION update_thread_on_post();

-- Fix circular dependency: Add best_answer FK to forum_threads
ALTER TABLE forum_threads
    ADD CONSTRAINT fk_best_answer_post
        FOREIGN KEY (best_answer_post_id)
            REFERENCES forum_posts(id)
            ON DELETE SET NULL;

-- ============================================================================================================================
--                                        REACTIONS - EXPANDED EMOTIONAL SUPPORT
-- ============================================================================================================================

-- Expanded reaction types
CREATE TYPE reaction_enum AS ENUM (
    'UPVOTE',       -- General agreement
    'HELPFUL',      -- Actionable advice
    'SUPPORTIVE',   -- Emotional support
    'INSIGHTFUL',   -- New perspective
    'HUGS',         -- Virtual comfort
    'RELATABLE',    -- Shared experience
    'BRAVE',        -- Courage to share
    'HOPE'          -- Inspiring
    );

-- Reference table for reaction metadata
CREATE TABLE reaction_definitions (
                                      reaction_type           reaction_enum PRIMARY KEY,
                                      display_name            VARCHAR(50) NOT NULL,
                                      icon_class              VARCHAR(50),  -- For UI icon reference (emoji or CSS class)
                                      description             TEXT NOT NULL,
                                      reputation_points       INTEGER DEFAULT 0 NOT NULL,  -- Reputation granted to post author
                                      available_to_roles      TEXT[],  -- NULL = everyone, otherwise specific roles only
                                      sort_order              INTEGER DEFAULT 0 NOT NULL,  -- Display order in UI
                                      created_at              TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL
);

-- Seed data
INSERT INTO reaction_definitions (reaction_type, display_name, icon_class, description, reputation_points, available_to_roles, sort_order) VALUES
   ('UPVOTE', 'Upvote', '👍', 'General agreement or approval', 1, NULL, 1),
   ('HELPFUL', 'Helpful', '💡', 'This provided actionable advice', 3, NULL, 2),
   ('SUPPORTIVE', 'Supportive', '❤️', 'Offering emotional support', 2, NULL, 3),
   ('INSIGHTFUL', 'Insightful', '🧠', 'New perspective or deep insight', 3, NULL, 4),
   ('HUGS', 'Hugs', '🤗', 'Virtual comfort and warmth', 2, NULL, 5),
   ('RELATABLE', 'Relatable', '🙋', 'I have the same experience', 1, NULL, 6),
   ('BRAVE', 'Brave', '💪', 'Courage to share vulnerably', 2, NULL, 7),
   ('HOPE', 'Hope', '✨', 'This gives me hope', 2, NULL, 8);

-- User reactions to posts
CREATE TABLE post_reactions (
                                id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                                post_id                 UUID NOT NULL REFERENCES forum_posts(id) ON DELETE CASCADE,
                                user_id                 UUID NOT NULL REFERENCES app_users(keycloak_id) ON DELETE CASCADE,
                                reaction_type           reaction_enum NOT NULL,
                                created_at              TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,

    -- User can only react once per post per reaction type
                                CONSTRAINT uq_user_post_reaction UNIQUE (post_id, user_id, reaction_type)
);

-- Indexes
CREATE INDEX idx_reaction_post ON post_reactions (post_id, reaction_type);
CREATE INDEX idx_reaction_user ON post_reactions (user_id, created_at DESC);

-- Trigger to update reaction_count on forum_posts
CREATE OR REPLACE FUNCTION update_post_reaction_count()
    RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE forum_posts
        SET reaction_count = reaction_count + 1
        WHERE id = NEW.post_id;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE forum_posts
        SET reaction_count = reaction_count - 1
        WHERE id = OLD.post_id;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_post_reaction_count
    AFTER INSERT OR DELETE ON post_reactions
    FOR EACH ROW
EXECUTE FUNCTION update_post_reaction_count();

-- Trigger to update user reputation when they receive reactions
CREATE OR REPLACE FUNCTION update_author_reputation()
    RETURNS TRIGGER AS $$
DECLARE
    points INTEGER;
    author UUID;
BEGIN
    -- Get reputation points for this reaction type
    SELECT reputation_points INTO points
    FROM reaction_definitions
    WHERE reaction_type = NEW.reaction_type;

    -- Get post author
    SELECT author_id INTO author
    FROM forum_posts
    WHERE id = NEW.post_id;

    -- Update author's reputation (if author exists)
    IF author IS NOT NULL THEN
        UPDATE app_users
        SET reputation_score = reputation_score + points
        WHERE keycloak_id = author;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_author_reputation
    AFTER INSERT ON post_reactions
    FOR EACH ROW
EXECUTE FUNCTION update_author_reputation();

-- ============================================================================================================================
--                                       CONTENT REPORTS - COMPREHENSIVE SAFETY
-- ============================================================================================================================


-- Supporting Enums
CREATE TYPE report_target_type_enum AS ENUM (
    'THREAD',
    'POST',
    'USER'
    );


CREATE TYPE report_category_enum AS ENUM (
    'SPAM',             -- Promotional content, off-topic
    'HARASSMENT',       -- Targeting/bullying another user
    'SELF_HARM',        -- Content about self-harm
    'SUICIDE',          -- Content about suicide
    'VIOLENCE',         -- Threats or violent content
    'MISINFORMATION',   -- Dangerous medical/mental health misinformation
    'PRIVACY_VIOLATION', -- Sharing someone's personal info
    'INAPPROPRIATE',    -- Generally inappropriate content
    'OTHER'             -- Requires manual review
    );

CREATE TYPE severity_enum AS ENUM (
    'LOW',      -- Minor issue, low priority
    'MEDIUM',   -- Needs attention, standard priority
    'HIGH',     -- Serious concern, escalate
    'CRITICAL'  -- Immediate danger, alert all mods
    );

CREATE TYPE report_status_enum AS ENUM (
    'PENDING',
    'UNDER_REVIEW',
    'ACTION_TAKEN',
    'DISMISSED',
    'ESCALATED'
    );

-- Main reports table
CREATE TABLE content_reports (
                                 id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Who filed the report
                                 reporter_id             UUID NOT NULL REFERENCES app_users(keycloak_id) ON DELETE CASCADE,
                                 is_anonymous            BOOLEAN DEFAULT FALSE NOT NULL,  -- Reporter's choice

    -- What's being reported (post OR thread OR user)
                                 target_type         report_target_type_enum NOT NULL,
                                 thread_id           UUID REFERENCES forum_threads(id) ON DELETE CASCADE,
                                 post_id             UUID REFERENCES forum_posts(id) ON DELETE CASCADE,
                                 reported_user_id    UUID REFERENCES app_users(keycloak_id) ON DELETE SET NULL,


    -- Report classification
                                 report_category         report_category_enum NOT NULL,
                                 severity                severity_enum NOT NULL,

    -- Context
                                 reason                  VARCHAR(100) NOT NULL,  -- Template or custom
                                 details                 TEXT,  -- Additional context

    -- Workflow tracking
                                 status                  report_status_enum DEFAULT 'PENDING' NOT NULL,
                                 assigned_moderator_id   UUID REFERENCES app_users(keycloak_id) ON DELETE SET NULL,
                                 assigned_at             TIMESTAMP,
                                 reviewed_at             TIMESTAMP,
                                 reviewed_by             UUID REFERENCES app_users(keycloak_id) ON DELETE SET NULL,
                                 action_taken        TEXT,            -- e.g., "Post deleted", "User warned"
                                 resolution_notes        TEXT,  -- Moderator's explanation

    -- Metadata
                                 auto_flagged            BOOLEAN DEFAULT FALSE NOT NULL,  -- Always FALSE until AI feature
                                 related_report_ids      UUID[],  -- Linked reports

    -- Future: Appeal system
                                 appeal_id               UUID,  -- FK to appeals table (when implemented)

    -- Timestamps
                                 reported_at             TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
                                 last_modified_at        TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,

    -- Constraints
                                 CONSTRAINT chk_report_target CHECK (
                                     (target_type = 'POST' AND post_id IS NOT NULL) OR
                                     (target_type = 'THREAD' AND thread_id IS NOT NULL) OR
                                     (target_type = 'USER' AND reported_user_id IS NOT NULL)
                                     ),
                                 CONSTRAINT uq_user_report UNIQUE (reporter_id, post_id, thread_id, reported_user_id)
);

-- Indexes
CREATE INDEX idx_reports_pending ON content_reports (status, severity DESC, reported_at DESC) WHERE status = 'PENDING';
CREATE INDEX idx_reports_assigned ON content_reports (assigned_moderator_id, status) WHERE assigned_moderator_id IS NOT NULL;
CREATE INDEX idx_reports_reporter ON content_reports (reporter_id, reported_at DESC);
CREATE INDEX idx_reports_post ON content_reports (post_id) WHERE post_id IS NOT NULL;
CREATE INDEX idx_reports_thread ON content_reports (thread_id) WHERE thread_id IS NOT NULL;

-- Report templates (pre-written reasons)
CREATE TABLE report_templates (
                                  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                                  report_category     report_category_enum NOT NULL,
                                  template_text       TEXT NOT NULL,
                                  requires_details    BOOLEAN DEFAULT FALSE NOT NULL,
                                  auto_severity       severity_enum NOT NULL,
                                  display_order       INTEGER DEFAULT 0 NOT NULL,
                                  is_active           BOOLEAN DEFAULT TRUE NOT NULL,
                                  created_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL
);

-- Seed report templates
INSERT INTO report_templates (report_category, template_text, requires_details, auto_severity, display_order) VALUES
      ('SPAM', 'This post contains spam or promotional content', FALSE, 'LOW', 1),
      ('SPAM', 'This post is off-topic or irrelevant', FALSE, 'LOW', 2),
      ('HARASSMENT', 'This post harasses or bullies another user', TRUE, 'HIGH', 3),
      ('HARASSMENT', 'This post contains personal attacks', TRUE, 'HIGH', 4),
      ('SELF_HARM', 'This post discusses self-harm in concerning detail', TRUE, 'CRITICAL', 5),
      ('SUICIDE', 'This post expresses suicidal thoughts or plans', TRUE, 'CRITICAL', 6),
      ('VIOLENCE', 'This post contains threats of violence', TRUE, 'CRITICAL', 7),
      ('MISINFORMATION', 'This post contains dangerous mental health misinformation', TRUE, 'HIGH', 8),
      ('PRIVACY_VIOLATION', 'This post shares someone''s personal information', TRUE, 'HIGH', 9),
      ('INAPPROPRIATE', 'This post contains inappropriate content', TRUE, 'MEDIUM', 10),
      ('OTHER', 'Other reason (please explain)', TRUE, 'MEDIUM', 11);

CREATE INDEX idx_templates_category ON report_templates (report_category, display_order);

-- User report history (track abuse)
CREATE TABLE user_report_history (
                                     user_id                 UUID PRIMARY KEY REFERENCES app_users(keycloak_id) ON DELETE CASCADE,
                                     total_reports_made      INTEGER DEFAULT 0 NOT NULL,
                                     reports_upheld          INTEGER DEFAULT 0 NOT NULL,
                                     reports_dismissed       INTEGER DEFAULT 0 NOT NULL,
                                     accuracy_rate           NUMERIC(5,2) GENERATED ALWAYS AS (
                                         CASE
                                             WHEN total_reports_made > 0
                                                 THEN (reports_upheld::NUMERIC / total_reports_made * 100)
                                             ELSE 0
                                             END
                                         ) STORED,
                                     last_report_at          TIMESTAMP ,
                                     is_report_banned        BOOLEAN DEFAULT FALSE NOT NULL,
                                     report_ban_reason       TEXT,
                                     report_ban_until        TIMESTAMP ,
                                     created_at              TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL
);

-- REPORT HISTORY (Audit Log)
CREATE TABLE report_history (
                                id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                                report_id    UUID NOT NULL REFERENCES content_reports(id) ON DELETE CASCADE,
                                action       TEXT NOT NULL,  -- e.g., "STATUS_CHANGED", "ASSIGNED", "ACTION_TAKEN"
                                old_value    TEXT,
                                new_value    TEXT,
                                acted_by     UUID REFERENCES app_users(keycloak_id) ON DELETE SET NULL,
                                created_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL
);
CREATE INDEX idx_report_history_report ON report_history(report_id, created_at DESC);

-- Trigger: Auto-update last_modified_at
CREATE OR REPLACE FUNCTION update_last_modified()
    RETURNS TRIGGER AS $$
BEGIN
    NEW.last_modified_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_last_modified
    BEFORE UPDATE ON content_reports
    FOR EACH ROW
EXECUTE FUNCTION update_last_modified();

-- Trigger: Update user report history and log changes (selective logging)
CREATE OR REPLACE FUNCTION update_report_history()
    RETURNS TRIGGER AS $$
BEGIN
    -- Initialize history record if doesn't exist
    IF TG_OP = 'INSERT' THEN
        INSERT INTO user_report_history (user_id, last_report_at)
        VALUES (NEW.reporter_id, NEW.reported_at)
        ON CONFLICT (user_id) DO UPDATE
            SET
                total_reports_made = user_report_history.total_reports_made + 1,
                last_report_at = NEW.reported_at;

        -- Log report creation
        INSERT INTO report_history(report_id, action, new_value, acted_by)
        VALUES (NEW.id, 'CREATED', NEW.status::text, NEW.reporter_id);
    END IF;

    -- On update, log specific field changes
    IF TG_OP = 'UPDATE' THEN
        -- Status change
        IF OLD.status IS DISTINCT FROM NEW.status THEN
            INSERT INTO report_history(report_id, action, old_value, new_value, acted_by)
            VALUES (NEW.id, 'STATUS_CHANGED', OLD.status::text, NEW.status::text, NEW.reviewed_by);

            -- Update reporter statistics
            IF OLD.status = 'PENDING' AND NEW.status IN ('ACTION_TAKEN', 'DISMISSED') THEN
                UPDATE user_report_history
                SET
                    reports_upheld = reports_upheld + CASE WHEN NEW.status = 'ACTION_TAKEN' THEN 1 ELSE 0 END,
                    reports_dismissed = reports_dismissed + CASE WHEN NEW.status = 'DISMISSED' THEN 1 ELSE 0 END
                WHERE user_id = NEW.reporter_id;
            END IF;
        END IF;

        -- Assignment change
        IF OLD.assigned_moderator_id IS DISTINCT FROM NEW.assigned_moderator_id THEN
            INSERT INTO report_history(report_id, action, old_value, new_value, acted_by)
            VALUES (NEW.id, 'ASSIGNED', OLD.assigned_moderator_id::text, NEW.assigned_moderator_id::text, NEW.assigned_moderator_id);
        END IF;

        -- Severity change
        IF OLD.severity IS DISTINCT FROM NEW.severity THEN
            INSERT INTO report_history(report_id, action, old_value, new_value, acted_by)
            VALUES (NEW.id, 'SEVERITY_CHANGED', OLD.severity::text, NEW.severity::text, NEW.reviewed_by);
        END IF;

        -- Action taken
        IF OLD.action_taken IS DISTINCT FROM NEW.action_taken AND NEW.action_taken IS NOT NULL THEN
            INSERT INTO report_history(report_id, action, new_value, acted_by)
            VALUES (NEW.id, 'ACTION_TAKEN', NEW.action_taken, NEW.reviewed_by);
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_report_history
    AFTER INSERT OR UPDATE ON content_reports
    FOR EACH ROW
EXECUTE FUNCTION update_report_history();

-- Trigger: Flag content when reported
CREATE OR REPLACE FUNCTION flag_content_on_report()
    RETURNS TRIGGER AS $$
BEGIN
    IF NEW.target_type = 'POST' AND NEW.post_id IS NOT NULL THEN
        UPDATE forum_posts
        SET flagged_for_review = TRUE
        WHERE id = NEW.post_id;
    END IF;

    -- Could add flagged_for_review to threads/users if needed

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_flag_content_on_report
    AFTER INSERT ON content_reports
    FOR EACH ROW
EXECUTE FUNCTION flag_content_on_report();


-- ============================================================================================================================
--                                      MODERATION - ENHANCED ACTIONS & WORKFLOWS
-- ============================================================================================================================
-- Metadata examples
-- {"from_category": "uuid1", "to_category": "uuid2"} // For THREAD_MOVED
-- {"old_reputation": 50, "new_reputation": 75, "adjustment": +25} // For USER_REPUTATION_ADJUSTED
-- {"affected_posts": ["uuid1", "uuid2", "uuid3"], "action": "delete"} For BULK_ACTION
-- Expanded actions (all possibilities, even if not all used immediately)

-- Moderation tiers (defines permissions per role)
CREATE TABLE moderation_tiers (
                                  tier_name VARCHAR(50) PRIMARY KEY,
                                  allowed_actions JSONB NOT NULL,
                                  action_limits JSONB DEFAULT '{}'
);

-- Seed data
INSERT INTO moderation_tiers VALUES
     ('moderator', '{
       "allowed_actions": [
         "POST_DELETED", "POST_EDITED", "POST_FLAGGED",
         "THREAD_LOCKED", "THREAD_UNLOCKED", "THREAD_MOVED",
         "USER_WARNED", "USER_MUTED", "REPORT_ASSIGNED", "REPORT_ACTIONED"
       ],
       "restrictions": {
         "max_mute_duration_hours": 24,
         "cannot_permanent_ban": true,
         "cannot_change_roles": true
       }
     }'),

     ('admin', '{
       "allowed_actions": [
         "POST_DELETED", "POST_EDITED", "POST_FLAGGED", "POST_RESTORED",
         "THREAD_LOCKED", "THREAD_UNLOCKED", "THREAD_DELETED", "THREAD_MOVED",
         "USER_WARNED", "USER_MUTED", "USER_SUSPENDED", "USER_BANNED",
         "USER_REPUTATION_ADJUSTED", "ROLE_GRANTED", "ROLE_REVOKED"
       ],
       "restrictions": {}
     }');

-- Supporting Enums
CREATE TYPE moderation_action_enum AS ENUM (
    -- Content actions
    'POST_DELETED',
    'POST_EDITED',
    'POST_FLAGGED',
    'POST_CONTENT_WARNING_ADDED',
    'POST_RESTORED',

    -- Thread actions
    'THREAD_LOCKED',
    'THREAD_UNLOCKED',
    'THREAD_DELETED',
    'THREAD_MOVED',
    'THREAD_MERGED',
    'THREAD_SPLIT',
    'THREAD_STATUS_CHANGED',
    'THREAD_FEATURED',
    'THREAD_UNFEATURED',

    -- User actions
    'USER_WARNED',
    'USER_MUTED',
    'USER_UNMUTED',
    'USER_SUSPENDED',
    'USER_UNSUSPENDED',
    'USER_BANNED',
    'USER_UNBANNED',
    'USER_REPUTATION_ADJUSTED',

    -- Role/permission changes
    'ROLE_GRANTED',
    'ROLE_REVOKED',
    'GROUP_ADDED',
    'GROUP_REMOVED',

    -- Report handling
    'REPORT_ASSIGNED',
    'REPORT_ESCALATED',
    'REPORT_ACTIONED',
    'REPORT_DISMISSED',

    -- System/bulk actions
    'BULK_ACTION',
    'CATEGORY_ACCESS_CHANGED'
    );

CREATE TYPE visibility_enum AS ENUM (
    'PUBLIC',
    'MODERATORS_ONLY',
    'ADMIN_ONLY'
    );

-- Main moderation log
CREATE TABLE moderation_log (
                                id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Who performed the action
                                moderator_id            UUID NOT NULL REFERENCES app_users(keycloak_id),

    -- What action
                                action_type             moderation_action_enum NOT NULL,
                                action_description      VARCHAR(255) NOT NULL,
                                rationale               TEXT NOT NULL,

    -- Targets (what was acted upon)
                                target_user_id          UUID REFERENCES app_users(keycloak_id) ON DELETE SET NULL,
                                target_post_id          UUID REFERENCES forum_posts(id) ON DELETE SET NULL,
                                target_thread_id        UUID REFERENCES forum_threads(id) ON DELETE SET NULL,
                                report_id               UUID REFERENCES content_reports(id) ON DELETE SET NULL,

    -- Action metadata
                                metadata                JSONB,  -- Flexible field for action-specific data
                                -- Example metadata:
                                -- {"from_category": "uuid1", "to_category": "uuid2"} // For THREAD_MOVED
                                -- {"old_reputation": 50, "new_reputation": 75, "adjustment": +25} // For USER_REPUTATION_ADJUSTED
                                -- {"affected_posts": ["uuid1", "uuid2", "uuid3"], "action": "delete"} // For BULK_ACTION

                                visibility              visibility_enum DEFAULT 'MODERATORS_ONLY' NOT NULL,

    -- Temporary action support
                                expires_at              TIMESTAMP ,  -- For mutes, suspensions, etc.

    -- Automation (placeholder for future)
                                is_automated            BOOLEAN DEFAULT FALSE NOT NULL,
                                automation_rule_id      UUID,  -- FK to moderation_rules (when implemented)

    -- Appeal (placeholder for future)
                                appeal_allowed          BOOLEAN DEFAULT FALSE NOT NULL,
                                appeal_deadline         TIMESTAMP ,

    -- Timestamp
                                action_taken_at         TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL
);

CREATE INDEX idx_moderator_actions ON moderation_log (moderator_id, action_taken_at DESC);
CREATE INDEX idx_user_history ON moderation_log (target_user_id, action_taken_at DESC);
CREATE INDEX idx_action_type ON moderation_log (action_type, action_taken_at DESC);
CREATE INDEX idx_report_actions ON moderation_log (report_id) WHERE report_id IS NOT NULL;

-- User warnings (graduated enforcement)
CREATE TYPE warning_type_enum AS ENUM (
    'INFORMAL',         -- Friendly reminder
    'FORMAL',           -- Official warning
    'FINAL',            -- Last warning before action
    'POLICY_VIOLATION'  -- Specific rule broken
    );

CREATE TABLE warning_type_definitions (
                                          warning_type warning_type_enum PRIMARY KEY,
                                          display_name VARCHAR(50) NOT NULL,
                                          description TEXT NOT NULL,
                                          severity_level INTEGER NOT NULL
);

INSERT INTO warning_type_definitions VALUES
     ('INFORMAL', 'Informal Reminder', 'Friendly nudge about community guidelines', 1),
     ('FORMAL', 'Formal Warning', 'Official warning on record', 2),
     ('FINAL', 'Final Warning', 'Last warning before suspension/ban', 3),
     ('POLICY_VIOLATION', 'Policy Violation', 'Specific community rule violated', 2);

CREATE TABLE user_warnings (
                               id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                               user_id                 UUID NOT NULL REFERENCES app_users(keycloak_id) ON DELETE CASCADE,
                               warned_by               UUID NOT NULL REFERENCES app_users(keycloak_id),

                               warning_type            warning_type_enum NOT NULL,
                               warning_text            TEXT NOT NULL,

    -- Context
                               related_post_id         UUID REFERENCES forum_posts(id) ON DELETE SET NULL,
                               related_thread_id       UUID REFERENCES forum_threads(id) ON DELETE SET NULL,
                               related_report_id       UUID REFERENCES content_reports(id) ON DELETE SET NULL,

    -- Lifecycle
                               warned_at               TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
                               acknowledged_at         TIMESTAMP, -- When user saw/accepted warning
                               expires_at              TIMESTAMP, -- Warning expires (for escalation tracking)
                               is_active               BOOLEAN DEFAULT TRUE NOT NULL
);

CREATE INDEX idx_warnings_user ON user_warnings (user_id, warned_at DESC);
CREATE INDEX idx_warnings_active ON user_warnings (user_id, is_active) WHERE is_active = TRUE;

-- User restrictions (mutes, suspensions, bans)
CREATE TYPE restriction_type_enum AS ENUM (
    'MUTE',         -- Can read, cannot post
    'POSTING_BAN',  -- Cannot create threads/posts
    'CATEGORY_BAN', -- Banned from specific category
    'SUSPENSION',   -- Cannot access forum at all
    'PERMANENT_BAN'
    );

CREATE TABLE user_restrictions (
                                   id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                                   user_id                 UUID NOT NULL REFERENCES app_users(keycloak_id) ON DELETE CASCADE,
                                   restriction_type        restriction_type_enum NOT NULL,

    -- Details
                                   reason                  TEXT NOT NULL,
                                   imposed_by              UUID NOT NULL REFERENCES app_users(keycloak_id),
                                   related_report_id       UUID REFERENCES content_reports(id) ON DELETE SET NULL,

    -- Category-specific (if CATEGORY_BAN)
                                   restricted_category_id  UUID REFERENCES forum_categories(id) ON DELETE CASCADE,

    -- Duration (NULL = permanent)
                                   starts_at               TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
                                   expires_at              TIMESTAMP,  -- NULL for permanent bans

    -- Status
                                   is_active               BOOLEAN DEFAULT TRUE NOT NULL,
                                   lifted_at               TIMESTAMP ,
                                   lifted_by               UUID REFERENCES app_users(keycloak_id),
                                   lift_reason             TEXT
);

CREATE INDEX idx_restrictions_user ON user_restrictions (user_id, is_active);
CREATE INDEX idx_restrictions_active ON user_restrictions (expires_at) WHERE is_active = TRUE AND expires_at IS NOT NULL;
CREATE INDEX idx_restrictions_type ON user_restrictions (restriction_type, is_active);

-- Moderation rules (schema exists, manual use only for now)
CREATE TABLE moderation_rules (
                                  id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                                  rule_name               VARCHAR(100) NOT NULL,
                                  description             TEXT,

    -- Trigger conditions (JSONB for flexibility)
                                  trigger_conditions      JSONB NOT NULL,

    -- Action to take
                                  action_type             moderation_action_enum NOT NULL,
                                  action_parameters       JSONB, -- Action-specific settings
                                -- Example: {"mute_duration_hours": 24, "notification_text": "..."}

    -- Rule metadata
                                  priority                INTEGER DEFAULT 0 NOT NULL,
                                  is_active               BOOLEAN DEFAULT TRUE NOT NULL,
                                  created_by              UUID NOT NULL REFERENCES app_users(keycloak_id),
                                  created_at              TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
                                  last_triggered_at       TIMESTAMP ,
                                  trigger_count           INTEGER DEFAULT 0 NOT NULL
);

CREATE INDEX idx_rules_active ON moderation_rules (is_active, priority DESC) WHERE is_active = TRUE;

-- Helper view: Active restrictions per user
CREATE VIEW user_active_restrictions AS
SELECT
    user_id,
    array_agg(restriction_type) as active_restriction_types,
    MAX(expires_at) as latest_expiry
FROM user_restrictions
WHERE is_active = TRUE
  AND (expires_at IS NULL OR expires_at > NOW())
GROUP BY user_id;

-- Helper view: Count active warnings per user
CREATE VIEW user_warning_counts AS
SELECT
    user_id,
    COUNT(*) FILTER (WHERE warning_type = 'INFORMAL') as informal_warnings,
    COUNT(*) FILTER (WHERE warning_type = 'FORMAL') as formal_warnings,
    COUNT(*) FILTER (WHERE warning_type = 'FINAL') as final_warnings,
    COUNT(*) as total_active_warnings
FROM user_warnings
WHERE is_active = TRUE
  AND (expires_at IS NULL OR expires_at > NOW())
GROUP BY user_id;

-- Function to auto-expire restrictions (runs daily via cron)
CREATE OR REPLACE FUNCTION expire_restrictions()
    RETURNS void AS $$
BEGIN
    UPDATE user_restrictions
    SET is_active = FALSE
    WHERE is_active = TRUE
      AND expires_at IS NOT NULL
      AND expires_at < NOW();
END;
$$ LANGUAGE plpgsql;

-- Same for warnings
CREATE OR REPLACE FUNCTION expire_warnings()
    RETURNS void AS $$
BEGIN
    UPDATE user_warnings
    SET is_active = FALSE
    WHERE is_active = TRUE
      AND expires_at IS NOT NULL
      AND expires_at < NOW();
END;
$$ LANGUAGE plpgsql;


-- ============================================================================================================================
--                                        ROLE CAPABILITIES
-- ============================================================================================================================

CREATE TYPE realm_role_enum AS ENUM (
    'moderator', 'forum_member', 'peer_supporter', 'trusted_member', 'admin'
    );


CREATE TABLE role_configurations (
                                     role_name realm_role_enum PRIMARY KEY,
                                     capabilities JSONB NOT NULL DEFAULT '{}'
);

-- Insert empty configurations for all roles
INSERT INTO role_configurations (role_name) VALUES
    ('moderator'),
    ('forum_member'),
    ('peer_supporter'),
    ('trusted_member'),
    ('admin');

-- ============================================================================================================================
--                                        GROUP CAPABILITIES
-- ============================================================================================================================

CREATE TYPE groups_enum AS ENUM (
    'members',
    'members/new',
    'members/active',
    'members/trusted',
    'moderators',
    'moderators/peer',
    'moderators/professional',
    'administrators'
    );

CREATE TABLE group_configurations (
                                      group_path groups_enum PRIMARY KEY,
                                     capabilities JSONB NOT NULL DEFAULT '{}'
);

-- Insert empty configurations for all groups
INSERT INTO group_configurations (group_path) VALUES
      ('members'),
      ('members/new'),
      ('members/active'),
      ('members/trusted'),
      ('moderators'),
      ('moderators/peer'),
      ('moderators/professional'),
      ('administrators');

-- ============================================================================================================================
--                                                      DISCOVERY
-- ============================================================================================================================

-- 1. Thread Bookmarks (Personal Favorites)
CREATE TABLE thread_bookmarks (
                                  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                                  user_id         UUID NOT NULL REFERENCES app_users(keycloak_id) ON DELETE CASCADE,
                                  thread_id       UUID NOT NULL REFERENCES forum_threads(id) ON DELETE CASCADE,
                                  notes           TEXT,  -- Personal context: "Helpful breathing techniques"
                                  created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
                                  UNIQUE(user_id, thread_id)
);

CREATE INDEX idx_bookmarks_by_user ON thread_bookmarks(user_id, created_at DESC);
CREATE INDEX idx_bookmarks_by_thread ON thread_bookmarks(thread_id);

-- 2. User Follows (Subscriptions)
CREATE TABLE user_follows (
                              id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                              follower_id             UUID NOT NULL REFERENCES app_users(keycloak_id) ON DELETE CASCADE,

    -- Follow exactly ONE of these
                              followed_user_id        UUID REFERENCES app_users(keycloak_id) ON DELETE CASCADE,
                              followed_thread_id      UUID REFERENCES forum_threads(id) ON DELETE CASCADE,
                              followed_category_id    UUID REFERENCES forum_categories(id) ON DELETE CASCADE,

                              notification_enabled    BOOLEAN DEFAULT TRUE NOT NULL,
                              created_at              TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,

    -- Constraint: Must follow exactly one thing
                              CONSTRAINT chk_follow_target CHECK (
                                  (followed_user_id IS NOT NULL AND followed_thread_id IS NULL AND followed_category_id IS NULL) OR
                                  (followed_user_id IS NULL AND followed_thread_id IS NOT NULL AND followed_category_id IS NULL) OR
                                  (followed_user_id IS NULL AND followed_thread_id IS NULL AND followed_category_id IS NOT NULL)
                                  ),
    -- Constraint: Can't follow same thing twice
                              UNIQUE(follower_id, followed_user_id),
                              UNIQUE(follower_id, followed_thread_id),
                              UNIQUE(follower_id, followed_category_id)
);

CREATE INDEX idx_follows_follower ON user_follows(follower_id);
CREATE INDEX idx_follows_user ON user_follows(followed_user_id) WHERE followed_user_id IS NOT NULL;
CREATE INDEX idx_follows_thread ON user_follows(followed_thread_id) WHERE followed_thread_id IS NOT NULL;
CREATE INDEX idx_follows_category ON user_follows(followed_category_id) WHERE followed_category_id IS NOT NULL;

-- Helper view: Follow counts (public, but not lists)
CREATE VIEW user_follow_counts AS
SELECT
    u.keycloak_id as user_id,
    (SELECT COUNT(*) FROM user_follows WHERE followed_user_id = u.keycloak_id) as follower_count,
    (SELECT COUNT(*) FROM user_follows WHERE follower_id = u.keycloak_id) as following_count
FROM app_users u;

-- 3. Trending Threads View (Simple SQL, No AI)
CREATE VIEW trending_threads AS
SELECT
    ft.id,
    ft.title,
    ft.category_id,
    ft.creator_id,
    ft.view_count,
    ft.post_count,
    ft.created_at,
    ft.last_activity_at,
    -- Trending score: recent activity + engagement
    (
        ft.post_count * 2 + -- More posts = more engaging
        ft.view_count / 10 + --  Views matter less than posts
        CASE
            WHEN ft.last_activity_at > NOW() - INTERVAL '1 day' THEN 50
            WHEN ft.last_activity_at > NOW() - INTERVAL '3 days' THEN 20
            ELSE 0
            END
        ) AS trending_score
FROM forum_threads ft
WHERE ft.is_deleted = FALSE
  AND ft.status = 'OPEN'
  AND ft.last_activity_at > NOW() - INTERVAL '7 days'  -- Only last week
ORDER BY trending_score DESC
LIMIT 50;


-- 4. User Category Activity View (from earlier discussion)
CREATE VIEW user_category_activity AS
SELECT
    fp.author_id AS user_id,
    ft.category_id,
    fc.name AS category_name,
    COUNT(DISTINCT fp.id) AS post_count,
    COUNT(DISTINCT ft.id) AS thread_count,
    MAX(fp.created_at) AS last_active_in_category_at,
    MIN(fp.created_at) AS first_active_in_category_at
FROM forum_posts fp
         JOIN forum_threads ft ON fp.thread_id = ft.id
         JOIN forum_categories fc ON ft.category_id = fc.id
WHERE fp.is_deleted = FALSE
  AND ft.is_deleted = FALSE
  AND fp.author_id IS NOT NULL
GROUP BY fp.author_id, ft.category_id, fc.name;


-- ============================================================================================================================
--                                      NOTIFICATIONS & ENGAGEMENT
-- ============================================================================================================================
-- Notification types (no MENTION for now)
CREATE TYPE notification_type_enum AS ENUM (
    'REPLY',        -- Reply to your post/thread
    'REACTION',     -- Someone reacted to your post (batched)
    'FOLLOW',       -- Someone followed you
    'MODERATION',   -- Moderator action affecting you
    'SYSTEM'        -- Platform announcements
    );

-- Main notifications table
CREATE TABLE notifications (
                               id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Recipient
                               recipient_id            UUID NOT NULL REFERENCES app_users(keycloak_id) ON DELETE CASCADE,

    -- Notification details
                               notification_type       notification_type_enum NOT NULL,
                               title                   VARCHAR(255) NOT NULL,
                               message                 TEXT NOT NULL,
                               action_url              VARCHAR(500),  -- Deep link: "/threads/{id}/posts/{id}"

    -- Related entities (who/what triggered this)
                               related_user_id         UUID REFERENCES app_users(keycloak_id) ON DELETE SET NULL,
                               related_post_id         UUID REFERENCES forum_posts(id) ON DELETE SET NULL,
                               related_thread_id       UUID REFERENCES forum_threads(id) ON DELETE SET NULL,
                               related_category_id     UUID REFERENCES forum_categories(id) ON DELETE SET NULL,

    -- Delivery tracking (Phase 1: in-app only)
                               sent_via                TEXT[] DEFAULT ARRAY['in_app'],  -- Future: add 'email'

    -- Read tracking
                               is_read                 BOOLEAN DEFAULT FALSE NOT NULL,
                               read_at                 TIMESTAMP ,

    -- Batching (for REACTION type)
                               is_batched              BOOLEAN DEFAULT FALSE,
                               batch_count             INTEGER,  -- "5 users reacted"
                               batch_metadata          JSONB,    -- {"HELPFUL": 3, "SUPPORTIVE": 2}

    -- Timestamps
                               created_at              TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
                               expires_at              TIMESTAMP GENERATED ALWAYS AS (created_at + INTERVAL '90 days') STORED
);

-- Indexes
CREATE INDEX idx_notifications_recipient ON notifications (recipient_id, created_at DESC);
CREATE INDEX idx_notifications_unread ON notifications (recipient_id, is_read, created_at DESC) WHERE is_read = FALSE;
CREATE INDEX idx_notifications_type ON notifications (notification_type, created_at DESC);
CREATE INDEX idx_notifications_expiry ON notifications (expires_at);

-- Update app_users notification_preferences to JSONB
-- (Replaces TEXT[] you currently have)
ALTER TABLE app_users
    ALTER COLUMN notification_preferences TYPE JSONB
        USING notification_preferences::jsonb;

ALTER TABLE app_users
    ALTER COLUMN notification_preferences SET DEFAULT '{
      "in_app": {
        "replies": true,
        "reactions": true,
        "follows": true,
        "moderation": true,
        "system": true
      },
      "email": {
        "replies": false,
        "reactions": false,
        "follows": false,
        "moderation": true,
        "system": false
      }
    }'::jsonb;

-- Cleanup function (runs daily via cron)
CREATE OR REPLACE FUNCTION cleanup_expired_notifications()
    RETURNS void AS $$
BEGIN
    DELETE FROM notifications WHERE expires_at < NOW();
END;
$$ LANGUAGE plpgsql;

-- Example notification creation trigger (for replies)
CREATE OR REPLACE FUNCTION notify_on_reply()
    RETURNS TRIGGER AS $$
DECLARE
    thread_creator_id UUID;
    parent_post_author_id UUID;
BEGIN
    -- If replying to a thread (top-level post)
    IF NEW.parent_post_id IS NULL THEN
        SELECT creator_id INTO thread_creator_id
        FROM forum_threads
        WHERE id = NEW.thread_id;

        -- Notify thread creator (if not replying to yourself)
        IF thread_creator_id IS NOT NULL AND thread_creator_id != NEW.author_id THEN
            INSERT INTO notifications (
                recipient_id,
                notification_type,
                title,
                message,
                action_url,
                related_user_id,
                related_post_id,
                related_thread_id
            )
            SELECT
                thread_creator_id,
                'REPLY',
                'New reply to your thread',
                (SELECT display_name FROM app_users WHERE keycloak_id = NEW.author_id) || ' replied to your thread',
                '/threads/' || NEW.thread_id || '/posts/' || NEW.id,
                NEW.author_id,
                NEW.id,
                NEW.thread_id
            WHERE EXISTS (
                -- Check user preferences
                SELECT 1 FROM app_users
                WHERE keycloak_id = thread_creator_id
                  AND notification_preferences->'in_app'->>'replies' = 'true'
            );
        END IF;
    ELSE
        -- If replying to a post (nested reply)
        SELECT author_id INTO parent_post_author_id
        FROM forum_posts
        WHERE id = NEW.parent_post_id;

        -- Notify parent post author (if not replying to yourself)
        IF parent_post_author_id IS NOT NULL AND parent_post_author_id != NEW.author_id THEN
            INSERT INTO notifications (
                recipient_id,
                notification_type,
                title,
                message,
                action_url,
                related_user_id,
                related_post_id,
                related_thread_id
            )
            SELECT
                parent_post_author_id,
                'REPLY',
                'New reply to your post',
                (SELECT display_name FROM app_users WHERE keycloak_id = NEW.author_id) || ' replied to your post',
                '/threads/' || NEW.thread_id || '/posts/' || NEW.id,
                NEW.author_id,
                NEW.id,
                NEW.thread_id
            WHERE EXISTS (
                -- Check user preferences
                SELECT 1 FROM app_users
                WHERE keycloak_id = parent_post_author_id
                  AND notification_preferences->'in_app'->>'replies' = 'true'
            );
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_notify_on_reply
    AFTER INSERT ON forum_posts
    FOR EACH ROW
EXECUTE FUNCTION notify_on_reply();


