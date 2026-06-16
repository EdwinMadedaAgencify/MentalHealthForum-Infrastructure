-- ============================================================
-- EXTENSIONS
-- ============================================================
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================
-- ENUMS (All enums defined first for consistency)
-- ============================================================

-- Profile & Identity Enums
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'profile_visibility_enum') THEN
CREATE TYPE profile_visibility_enum AS ENUM (
            'MEMBERS_ONLY',
            'PRIVATE'
        );
END IF;
END $$;

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'support_role_enum') THEN
CREATE TYPE support_role_enum AS ENUM (
            'NOT_SPECIFIED',
            'SEEKING_SUPPORT',
            'OFFERING_SUPPORT',
            'BOTH'
        );
END IF;
END $$;

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'onboarding_stage_enum') THEN
CREATE TYPE onboarding_stage_enum AS ENUM (
            'AWAITING_VERIFICATION',
            'AWAITING_PASSWORD_RESET',
            'AWAITING_PROFILE_COMPLETION'
        );
END IF;
END $$;

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'otp_purpose_enum') THEN
CREATE TYPE otp_purpose_enum AS ENUM (
            'FORGOT_PASSWORD',
            'ADMIN_2FA'
        );
END IF;
END $$;

-- Forum Enums
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'content_warning_enum') THEN
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
END IF;
END $$;

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'thread_type_enum') THEN
CREATE TYPE thread_type_enum AS ENUM (
            'DISCUSSION',
            'QUESTION',
            'CRISIS_SUPPORT',
            'PEER_REVIEW',
            'POLL'
        );
END IF;
END $$;

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'thread_status_enum') THEN
CREATE TYPE thread_status_enum AS ENUM (
            'OPEN',
            'RESOLVED',
            'CLOSED',
            'ARCHIVED'
        );
END IF;
END $$;

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'post_type_enum') THEN
CREATE TYPE post_type_enum AS ENUM (
            'REPLY',
            'ANSWER',
            'SYSTEM_MESSAGE',
            'MODERATOR_NOTE'
        );
END IF;
END $$;

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'edit_reason_enum') THEN
CREATE TYPE edit_reason_enum AS ENUM (
            'TYPO_FIX',
            'ADDED_CONTEXT',
            'CLARIFICATION',
            'REMOVED_PERSONAL_INFO',
            'CONTENT_POLICY_VIOLATION',
            'CONTENT_WARNING_ADDED',
            'FORMATTING',
            'OTHER'
        );
END IF;
END $$;

-- Moderation Enums
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'moderation_action_enum') THEN
CREATE TYPE moderation_action_enum AS ENUM (
            -- Content actions
            'POST_DELETED',
            'POST_EDITED',
            'POST_FLAGGED',
            'POST_CONTENT_WARNING_ADDED',
            'POST_RESTORED',
            'POST_PERMANENTLY_DELETED',
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
            'THREAD_TYPE_CHANGED',
            'THREAD_STICKY_TOGGLED',
            'THREAD_RESTORED',
            'THREAD_PERMANENTLY_DELETED',
            'THREAD_METADATA_EDITED',
            'THREAD_CONTENT_WARNING_ADDED',
            'THREAD_ARCHIVED',
            'THREAD_UNARCHIVED',
            'THREAD_SOFT_DELETED',
            'THREAD_BEST_ANSWER_SET',
            'THREAD_BEST_ANSWER_CLEARED',
            'VIEW_DELETED_THREADS',
            'VIEW_DELETED_POSTS',
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
            'REPORT_DETAILS_UPDATED',
            -- System/bulk actions
            'BULK_ACTION',
            -- Category actions
            'CATEGORY_ACCESS_CHANGED',
            'CATEGORY_CREATED',
            'CATEGORY_UPDATED',
            'CATEGORY_SOFT_DELETED',
            'CATEGORY_REACTIVATED',
            'CATEGORY_PURGED',
            'CATEGORY_VIEW_INACTIVE',
            'CATEGORY_PURGE_OLD',
            'CATEGORY_TAG_CREATED',
            'CATEGORY_TAG_UPDATED',
            'CATEGORY_TAG_DELETED',
            'CATEGORY_TAG_ASSIGNED',
            'CATEGORY_TAG_UNASSIGNED',
            'CATEGORY_TAG_REPLACED',
            -- Best answer
            'BEST_ANSWER_SET',
            'BEST_ANSWER_CLEARED'
        );
END IF;
END $$;

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'dismissal_reason_enum') THEN
CREATE TYPE dismissal_reason_enum AS ENUM (
            'FALSE_POSITIVE',
            'NO_VIOLATION',
            'ALREADY_HANDLED',
            'CONTENT_GONE',
            'INSUFFICIENT_EVIDENCE',
            'USER_EDUCATED',
            'DUPLICATE_REPORT',
            'ALLOWED_CONTENT',
            'PROTECTED_CONTENT'
        );
END IF;
END $$;

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'report_reason_code_enum') THEN
CREATE TYPE report_reason_code_enum AS ENUM (
            'SPAM_PROMOTIONAL',
            'SPAM_OFFTOPIC',
            'HARASSMENT_BULLYING',
            'HARASSMENT_PERSONAL_ATTACK',
            'SELF_HARM_DETAILED',
            'SUICIDE_EXPRESSION',
            'VIOLENCE_THREATS',
            'MISINFORMATION_DANGEROUS',
            'PRIVACY_DOXING',
            'INAPPROPRIATE_CONTENT',
            'OTHER_REASON'
        );
END IF;
END $$;

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'report_target_type_enum') THEN
CREATE TYPE report_target_type_enum AS ENUM (
            'THREAD',
            'POST',
            'USER'
        );
END IF;
END $$;

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'report_category_enum') THEN
CREATE TYPE report_category_enum AS ENUM (
            'SPAM',
            'HARASSMENT',
            'SELF_HARM',
            'SUICIDE',
            'VIOLENCE',
            'MISINFORMATION',
            'PRIVACY_VIOLATION',
            'INAPPROPRIATE',
            'OTHER'
        );
END IF;
END $$;

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'severity_enum') THEN
CREATE TYPE severity_enum AS ENUM (
            'LOW',
            'MEDIUM',
            'HIGH',
            'CRITICAL'
        );
END IF;
END $$;

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'report_status_enum') THEN
CREATE TYPE report_status_enum AS ENUM (
            'PENDING',
            'UNDER_REVIEW',
            'ACTION_TAKEN',
            'DISMISSED',
            'ESCALATED'
        );
END IF;
END $$;

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'reaction_enum') THEN
CREATE TYPE reaction_enum AS ENUM (
            'UPVOTE',
            'HELPFUL',
            'SUPPORTIVE',
            'INSIGHTFUL',
            'HUGS',
            'RELATABLE',
            'BRAVE',
            'HOPE'
        );
END IF;
END $$;

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'queue_source_enum') THEN
CREATE TYPE queue_source_enum AS ENUM (
            'MODERATOR',
            'AI',
            'SYSTEM'
        );
END IF;
END $$;

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'visibility_enum') THEN
CREATE TYPE visibility_enum AS ENUM (
            'PUBLIC',
            'MODERATORS_ONLY',
            'ADMIN_ONLY'
        );
END IF;
END $$;

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'warning_type_enum') THEN
CREATE TYPE warning_type_enum AS ENUM (
            'INFORMAL',
            'FORMAL',
            'FINAL',
            'POLICY_VIOLATION'
        );
END IF;
END $$;

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'restriction_type_enum') THEN
CREATE TYPE restriction_type_enum AS ENUM (
            'MUTE',
            'POSTING_BAN',
            'CATEGORY_BAN',
            'SUSPENSION',
            'PERMANENT_BAN'
        );
END IF;
END $$;

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'realm_role_enum') THEN
CREATE TYPE realm_role_enum AS ENUM (
            'moderator',
            'forum_member',
            'peer_supporter',
            'trusted_member',
            'admin'
        );
END IF;
END $$;

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'groups_enum') THEN
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
END IF;
END $$;

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'connection_status_enum') THEN
CREATE TYPE connection_status_enum AS ENUM (
            'PENDING',
            'ACCEPTED',
            'DECLINED'
        );
END IF;
END $$;

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'notification_type_enum') THEN
CREATE TYPE notification_type_enum AS ENUM (
            'REPLY',
            'REACTION',
            'FOLLOW',
            'MODERATION',
            'SYSTEM'
        );
END IF;
END $$;

-- ============================================================
-- USER PROFILE & IDENTITY TABLES
-- ============================================================

CREATE TABLE IF NOT EXISTS app_users (
                                         id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    keycloak_id UUID NOT NULL,
    email VARCHAR(255) NOT NULL,
    username VARCHAR(255) NOT NULL,
    first_name VARCHAR(255) NOT NULL,
    last_name VARCHAR(255) NOT NULL,
    roles TEXT[],
    groups TEXT[],
    is_enabled BOOLEAN,
    last_synced_at TIMESTAMP WITH TIME ZONE DEFAULT NULL,
    date_joined TIMESTAMP WITH TIME ZONE NOT NULL,
                              display_name VARCHAR(100),
    avatar_url TEXT,
    bio TEXT,
    timezone VARCHAR(50) DEFAULT 'UTC',
    language VARCHAR(10) DEFAULT 'en',
    profile_visibility profile_visibility_enum DEFAULT 'MEMBERS_ONLY',
    support_role support_role_enum DEFAULT 'NOT_SPECIFIED',
    notification_preferences JSONB DEFAULT '{
        "inApp": {
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
    posts_count INT DEFAULT 0,
    reputation_score NUMERIC(10,2) DEFAULT 0.0,
    last_active_at TIMESTAMP WITH TIME ZONE,
    last_posted_at TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN DEFAULT TRUE,
    account_deletion_requested_at TIMESTAMP WITH TIME ZONE DEFAULT NULL
                              );

-- Indexes for app_users
CREATE UNIQUE INDEX IF NOT EXISTS idx_keycloak_id ON app_users (keycloak_id);
CREATE INDEX IF NOT EXISTS idx_app_users_display_name ON app_users (display_name);
CREATE INDEX IF NOT EXISTS idx_app_users_display_name_sort ON app_users (COALESCE(NULLIF(display_name, ''), 'zzzzzzzz'));
CREATE INDEX IF NOT EXISTS idx_app_users_date_joined ON app_users(date_joined DESC);
CREATE INDEX IF NOT EXISTS idx_app_users_posts_count ON app_users(posts_count DESC);
CREATE INDEX IF NOT EXISTS idx_app_users_reputation ON app_users(reputation_score DESC);
CREATE INDEX IF NOT EXISTS idx_app_users_active ON app_users (is_active, last_active_at DESC);
CREATE INDEX IF NOT EXISTS idx_app_users_roles ON app_users USING gin (roles);
CREATE INDEX IF NOT EXISTS idx_app_users_groups ON app_users USING gin (groups);

-- admin_invitations
CREATE TABLE IF NOT EXISTS admin_invitations (
                                                 id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    keycloak_id UUID NOT NULL,
    email VARCHAR(255) NOT NULL,
    username VARCHAR(255) NOT NULL,
    first_name VARCHAR(255) NOT NULL,
    last_name VARCHAR(255) NOT NULL,
    groups TEXT[],
    is_enabled BOOLEAN,
    is_email_verified BOOLEAN,
    date_created TIMESTAMP WITH TIME ZONE NOT NULL,
                               invited_by UUID NOT NULL REFERENCES app_users(keycloak_id),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
                               current_stage onboarding_stage_enum DEFAULT 'AWAITING_VERIFICATION',
                               is_initial_login BOOLEAN NOT NULL DEFAULT TRUE
                               );

CREATE UNIQUE INDEX IF NOT EXISTS idx_admin_invitations_keycloak_id ON admin_invitations(keycloak_id);
CREATE INDEX IF NOT EXISTS idx_admin_invitations_date_created ON admin_invitations(date_created DESC);
CREATE INDEX IF NOT EXISTS idx_admin_invitations_email_search ON admin_invitations(LOWER(email));

-- pending_users
CREATE TABLE IF NOT EXISTS pending_users (
                                             id BIGSERIAL PRIMARY KEY,
                                             username VARCHAR(255) NOT NULL UNIQUE,
    email VARCHAR(255) NOT NULL UNIQUE,
    encrypted_password TEXT NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
                             );

-- verification_tokens
CREATE TABLE IF NOT EXISTS verification_tokens (
                                                   id BIGSERIAL PRIMARY KEY,
                                                   token VARCHAR(255) NOT NULL UNIQUE,
    email VARCHAR(255) NOT NULL,
    expiry_date TIMESTAMP WITH TIME ZONE NOT NULL,
                              type VARCHAR(50) NOT NULL,
    group_path TEXT,
    new_value VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
                              );

CREATE INDEX IF NOT EXISTS idx_tokens_email_type ON verification_tokens(email, type);
CREATE INDEX IF NOT EXISTS idx_tokens_lookup ON verification_tokens(token, email);

-- otp_credentials
CREATE TABLE IF NOT EXISTS otp_credentials (
                                               id BIGSERIAL PRIMARY KEY,
                                               email VARCHAR(255) NOT NULL,
    code_hash VARCHAR(255) NOT NULL,
    purpose otp_purpose_enum NOT NULL,
    expiry_date TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
                             );

CREATE INDEX IF NOT EXISTS idx_otp_email_purpose ON otp_credentials(email, purpose);
CREATE INDEX IF NOT EXISTS idx_otp_expiry ON otp_credentials(expiry_date);

-- ============================================================
-- FORUM CATEGORIES
-- ============================================================

CREATE TABLE IF NOT EXISTS forum_categories (
                                                id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL UNIQUE,
    slug VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    color_theme VARCHAR(50),
    parent_category_id UUID REFERENCES forum_categories(id) ON DELETE CASCADE,
    participation_requirements JSONB DEFAULT '{}'::jsonb,
    content_warning_type content_warning_enum DEFAULT 'NONE',
    content_warning_custom_text VARCHAR(255) DEFAULT NULL,
    default_thread_settings JSONB DEFAULT '{}'::jsonb,
    is_active BOOLEAN DEFAULT TRUE NOT NULL,
    sort_order INTEGER DEFAULT 0 NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
                                                                );

-- Indexes
CREATE INDEX IF NOT EXISTS idx_category_active_sort ON forum_categories (is_active DESC, sort_order ASC);
CREATE INDEX IF NOT EXISTS idx_category_slug ON forum_categories (slug);
CREATE INDEX IF NOT EXISTS idx_category_parent_id ON forum_categories (parent_category_id);

-- Category depth validation function
CREATE OR REPLACE FUNCTION validate_category_depth()
RETURNS TRIGGER AS $$
DECLARE
parent_parent UUID;
BEGIN
    IF NEW.parent_category_id IS NOT NULL THEN
SELECT parent_category_id INTO parent_parent
FROM forum_categories
WHERE id = NEW.parent_category_id;
IF parent_parent IS NOT NULL THEN
            RAISE EXCEPTION 'Only one level of category hierarchy allowed';
END IF;
END IF;
RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_validate_category_depth
    BEFORE INSERT OR UPDATE ON forum_categories
                         FOR EACH ROW
                         EXECUTE FUNCTION validate_category_depth();

ALTER TABLE forum_categories ADD CONSTRAINT chk_no_self_parent CHECK (id <> parent_category_id);

-- ============================================================
-- CATEGORY TAGS (Central Library)
-- ============================================================

CREATE TABLE IF NOT EXISTS category_tags (
                                             id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(50) NOT NULL UNIQUE,
    slug VARCHAR(50) NOT NULL UNIQUE,
    description TEXT,
    created_by UUID REFERENCES app_users(keycloak_id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
                                                          );

CREATE TABLE IF NOT EXISTS category_tag_assignments (
                                                        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    category_id UUID NOT NULL REFERENCES forum_categories(id) ON DELETE CASCADE,
    tag_id UUID NOT NULL REFERENCES category_tags(id) ON DELETE CASCADE,
    assigned_by UUID REFERENCES app_users(keycloak_id) ON DELETE SET NULL,
    assigned_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
                                                                  UNIQUE(category_id, tag_id)
    );

-- Indexes
CREATE INDEX IF NOT EXISTS idx_category_tags_name ON category_tags(name);
CREATE INDEX IF NOT EXISTS idx_category_tags_slug ON category_tags(slug);
CREATE INDEX IF NOT EXISTS idx_category_tags_created_by ON category_tags(created_by);
CREATE INDEX IF NOT EXISTS idx_category_tag_assignments_category ON category_tag_assignments(category_id);
CREATE INDEX IF NOT EXISTS idx_category_tag_assignments_tag ON category_tag_assignments(tag_id);
CREATE INDEX IF NOT EXISTS idx_category_tag_assignments_assigned_by ON category_tag_assignments(assigned_by);

-- Trigger for category_tags updated_at
CREATE OR REPLACE FUNCTION update_category_tags_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_category_tags_updated_at
    BEFORE UPDATE ON category_tags
    FOR EACH ROW
    EXECUTE FUNCTION update_category_tags_updated_at();

-- ============================================================
-- THREAD TYPE & STATUS DEFINITIONS
-- ============================================================

CREATE TABLE IF NOT EXISTS thread_type_definitions (
                                                       thread_type thread_type_enum PRIMARY KEY,
                                                       display_name VARCHAR(50) NOT NULL,
    description TEXT NOT NULL,
    icon_hint VARCHAR(50),
    example TEXT
    );

INSERT INTO thread_type_definitions (thread_type, display_name, description, icon_hint, example) VALUES
                                                                                                     ('DISCUSSION', 'Discussion', 'Open-ended conversation on a topic. No specific outcome expected.', 'chat', 'Share your thoughts on coping with workplace anxiety'),
                                                                                                     ('QUESTION', 'Question', 'Seeking specific answers or advice from the community.', 'help-circle', 'How do I handle panic attacks in public?'),
                                                                                                     ('CRISIS_SUPPORT', 'Crisis Support', 'Urgent support needed. Peer supporters and moderators will be notified.', 'alert-circle', 'Feeling overwhelmed and need immediate support'),
                                                                                                     ('PEER_REVIEW', 'Peer Review', 'Sharing your story or approach for feedback from others.', 'users', 'I wrote about my journey with depression, would love your thoughts'),
                                                                                                     ('POLL', 'Poll', 'Community survey to gather opinions or preferences.', 'bar-chart', 'What coping strategies work best for you?')
    ON CONFLICT (thread_type) DO NOTHING;

CREATE TABLE IF NOT EXISTS thread_status_definitions (
                                                         thread_status thread_status_enum PRIMARY KEY,
                                                         display_name VARCHAR(50) NOT NULL,
    description TEXT NOT NULL,
    user_visible BOOLEAN NOT NULL
    );

INSERT INTO thread_status_definitions (thread_status, display_name, description, user_visible) VALUES
                                                                                                   ('OPEN', 'Open', 'Active discussion, accepting new posts', true),
                                                                                                   ('RESOLVED', 'Resolved', 'Question answered or issue addressed', true),
                                                                                                   ('CLOSED', 'Closed', 'No longer accepting posts, but still visible', true),
                                                                                                   ('ARCHIVED', 'Archived', 'Old/inactive, hidden from main view but searchable', false)
    ON CONFLICT (thread_status) DO NOTHING;

-- ============================================================
-- THREADS
-- ============================================================

CREATE TABLE IF NOT EXISTS forum_threads (
                                             id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title VARCHAR(255) NOT NULL,
    creator_id UUID REFERENCES app_users(keycloak_id) ON DELETE SET NULL,
    category_id UUID NOT NULL REFERENCES forum_categories(id) ON DELETE RESTRICT,
    thread_type thread_type_enum NOT NULL DEFAULT 'DISCUSSION',
    thread_status thread_status_enum NOT NULL DEFAULT 'OPEN',
    resolved_at TIMESTAMP WITH TIME ZONE DEFAULT NULL,
                                                          resolved_by_user_id UUID REFERENCES app_users(keycloak_id) ON DELETE SET NULL,
    best_answer_post_id UUID DEFAULT NULL,
    content_warning_type content_warning_enum DEFAULT 'NONE' NOT NULL,
    content_warning_custom_text VARCHAR(255) DEFAULT NULL,
    tags TEXT[],
    is_sticky BOOLEAN DEFAULT FALSE NOT NULL,
    is_featured BOOLEAN DEFAULT FALSE NOT NULL,
    is_deleted BOOLEAN DEFAULT FALSE NOT NULL,
    thread_settings JSONB DEFAULT '{}'::jsonb,
    lock_reason TEXT,
    locked_by UUID REFERENCES app_users(keycloak_id) ON DELETE SET NULL,
    locked_at TIMESTAMP WITH TIME ZONE,
    lock_expires_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    last_activity_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
                                                          post_count INTEGER DEFAULT 0 NOT NULL,
                                                          view_count INTEGER DEFAULT 0 NOT NULL,
                                                          CONSTRAINT chk_resolved_only_for_questions CHECK (thread_status != 'RESOLVED' OR thread_type = 'QUESTION')
    );

-- Indexes for forum_threads
CREATE INDEX IF NOT EXISTS idx_thread_activity ON forum_threads (category_id, is_sticky DESC, last_activity_at DESC);
CREATE INDEX IF NOT EXISTS idx_thread_status ON forum_threads (thread_status, updated_at DESC);
CREATE INDEX IF NOT EXISTS idx_thread_type ON forum_threads (thread_type);
CREATE INDEX IF NOT EXISTS idx_thread_featured ON forum_threads (is_featured DESC, created_at DESC) WHERE is_featured = TRUE;
CREATE INDEX IF NOT EXISTS idx_thread_creator ON forum_threads (creator_id, created_at DESC);

-- ============================================================
-- THREAD EDIT HISTORY
-- ============================================================

CREATE TABLE IF NOT EXISTS thread_edit_history (
                                                   id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    thread_id UUID NOT NULL REFERENCES forum_threads(id) ON DELETE CASCADE,
    previous_title VARCHAR(255),
    previous_tags TEXT[],
    previous_content_warning_type content_warning_enum,
    previous_content_warning_custom_text VARCHAR(255),
    edited_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
                                                             edited_by UUID REFERENCES app_users(keycloak_id),
    edit_reason_type edit_reason_enum,
    edit_reason_custom_text VARCHAR(255),
    is_moderator_edit BOOLEAN DEFAULT FALSE NOT NULL
    );

CREATE INDEX IF NOT EXISTS idx_thread_edit_history_thread ON thread_edit_history (thread_id, edited_at DESC);
CREATE INDEX IF NOT EXISTS idx_thread_edit_history_editor ON thread_edit_history (edited_by);

COMMENT ON TABLE thread_edit_history IS 'Tracks all edits made to threads (title, tags, content warnings)';

-- ============================================================
-- POSTS
-- ============================================================

CREATE TABLE IF NOT EXISTS forum_posts (
                                           id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    thread_id UUID NOT NULL REFERENCES forum_threads(id) ON DELETE CASCADE,
    author_id UUID REFERENCES app_users(keycloak_id) ON DELETE SET NULL,
    post_type post_type_enum DEFAULT 'REPLY' NOT NULL,
    parent_post_id UUID REFERENCES forum_posts(id) ON DELETE SET NULL,
    content TEXT NOT NULL,
    word_count INTEGER DEFAULT 0 NOT NULL,
    content_warning_type content_warning_enum DEFAULT 'NONE',
    content_warning_custom_text VARCHAR(255) DEFAULT NULL,
    flagged_for_review BOOLEAN DEFAULT FALSE NOT NULL,
    is_edited BOOLEAN DEFAULT FALSE NOT NULL,
    edit_reason_type edit_reason_enum DEFAULT NULL,
    edit_reason_custom_text VARCHAR(255) DEFAULT NULL,
    edited_by_user_id UUID REFERENCES app_users(keycloak_id) ON DELETE SET NULL,
    is_anonymous BOOLEAN DEFAULT FALSE NOT NULL,
    anonymous_identifier VARCHAR(50) DEFAULT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
                                                             is_deleted BOOLEAN DEFAULT FALSE NOT NULL,
                                                             reaction_count INTEGER DEFAULT 0 NOT NULL
                                                             );

-- Indexes for forum_posts
CREATE INDEX IF NOT EXISTS idx_posts_by_thread ON forum_posts (thread_id, created_at ASC);
CREATE INDEX IF NOT EXISTS idx_posts_by_author ON forum_posts (author_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_posts_flagged ON forum_posts (flagged_for_review, created_at DESC) WHERE flagged_for_review = TRUE;
CREATE INDEX IF NOT EXISTS idx_posts_parent ON forum_posts (parent_post_id) WHERE parent_post_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_posts_type ON forum_posts (post_type, thread_id);

ALTER TABLE forum_posts ADD CONSTRAINT uq_post_thread UNIQUE (id, thread_id);

-- word_count trigger
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

-- Post depth validation
CREATE OR REPLACE FUNCTION validate_post_depth()
RETURNS TRIGGER AS $$
DECLARE
parent_parent UUID;
BEGIN
    IF NEW.parent_post_id IS NOT NULL THEN
SELECT parent_post_id INTO parent_parent
FROM forum_posts
WHERE id = NEW.parent_post_id;
IF parent_parent IS NOT NULL THEN
            RAISE EXCEPTION 'Only one level of replies allowed';
END IF;
END IF;
RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_validate_post_depth
    BEFORE INSERT OR UPDATE ON forum_posts
                         FOR EACH ROW
                         EXECUTE FUNCTION validate_post_depth();

-- Update thread on post
CREATE OR REPLACE FUNCTION update_thread_on_post()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
UPDATE forum_threads
SET last_activity_at = NEW.created_at, post_count = post_count + 1
WHERE id = NEW.thread_id;
END IF;
RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_thread_on_post
    AFTER INSERT ON forum_posts
    FOR EACH ROW
    EXECUTE FUNCTION update_thread_on_post();

-- ============================================================
-- POST EDIT HISTORY
-- ============================================================

CREATE TABLE IF NOT EXISTS post_edit_history (
                                                 id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    post_id UUID NOT NULL REFERENCES forum_posts(id) ON DELETE CASCADE,
    previous_content TEXT NOT NULL,
    previous_word_count INTEGER,
    previous_content_warning_type content_warning_enum,
    previous_content_warning_custom_text VARCHAR(255),
    edited_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
                                                         edited_by UUID NOT NULL REFERENCES app_users(keycloak_id),
    edit_reason_type edit_reason_enum,
    edit_reason_custom_text VARCHAR(255),
    is_moderator_edit BOOLEAN DEFAULT FALSE
    );

CREATE INDEX IF NOT EXISTS idx_edit_history_post ON post_edit_history (post_id, edited_at DESC);
CREATE INDEX IF NOT EXISTS idx_edit_history_user ON post_edit_history (edited_by);

-- ============================================================
-- THREAD BEST ANSWER FK (after posts exist)
-- ============================================================

UPDATE forum_threads
SET best_answer_post_id = NULL
WHERE best_answer_post_id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM forum_posts
    WHERE forum_posts.id = forum_threads.best_answer_post_id
);

ALTER TABLE forum_threads
    ADD CONSTRAINT fk_best_answer_post
        FOREIGN KEY (best_answer_post_id, id)
            REFERENCES forum_posts(id, thread_id)
            ON DELETE SET NULL;

-- ============================================================
-- REACTIONS
-- ============================================================

CREATE TABLE IF NOT EXISTS reaction_definitions (
                                                    reaction_type reaction_enum PRIMARY KEY,
                                                    display_name VARCHAR(50) NOT NULL,
    icon_class VARCHAR(50),
    description TEXT NOT NULL,
    reputation_points INTEGER DEFAULT 0 NOT NULL,
    available_to_roles TEXT[],
    sort_order INTEGER DEFAULT 0 NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
                             );

INSERT INTO reaction_definitions (reaction_type, display_name, icon_class, description, reputation_points, available_to_roles, sort_order) VALUES
                                                                                                                                               ('UPVOTE', 'Upvote', '👍', 'General agreement or approval', 1, NULL, 1),
                                                                                                                                               ('HELPFUL', 'Helpful', '💡', 'This provided actionable advice', 3, NULL, 2),
                                                                                                                                               ('SUPPORTIVE', 'Supportive', '❤️', 'Offering emotional support', 2, NULL, 3),
                                                                                                                                               ('INSIGHTFUL', 'Insightful', '🧠', 'New perspective or deep insight', 3, NULL, 4),
                                                                                                                                               ('HUGS', 'Hugs', '🤗', 'Virtual comfort and warmth', 2, NULL, 5),
                                                                                                                                               ('RELATABLE', 'Relatable', '😔', 'I have the same experience', 1, NULL, 6),
                                                                                                                                               ('BRAVE', 'Brave', '🦁', 'Courage to share vulnerably', 2, NULL, 7),
                                                                                                                                               ('HOPE', 'Hope', '🌈', 'This gives me hope', 2, NULL, 8)
    ON CONFLICT (reaction_type) DO NOTHING;

CREATE TABLE IF NOT EXISTS post_reactions (
                                              id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    post_id UUID NOT NULL REFERENCES forum_posts(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES app_users(keycloak_id) ON DELETE CASCADE,
    reaction_type reaction_enum NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
                                                         CONSTRAINT uq_user_post_reaction UNIQUE (post_id, user_id, reaction_type)
    );

CREATE INDEX IF NOT EXISTS idx_reaction_post ON post_reactions (post_id, reaction_type);
CREATE INDEX IF NOT EXISTS idx_reaction_user ON post_reactions (user_id, created_at DESC);

-- Update post reaction count
CREATE OR REPLACE FUNCTION update_post_reaction_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
UPDATE forum_posts SET reaction_count = reaction_count + 1 WHERE id = NEW.post_id;
ELSIF TG_OP = 'DELETE' THEN
UPDATE forum_posts SET reaction_count = reaction_count - 1 WHERE id = OLD.post_id;
END IF;
RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_post_reaction_count
    AFTER INSERT OR DELETE ON post_reactions
    FOR EACH ROW
EXECUTE FUNCTION update_post_reaction_count();

-- Update author reputation
CREATE OR REPLACE FUNCTION update_author_reputation()
RETURNS TRIGGER AS $$
DECLARE
points INTEGER;
    author UUID;
BEGIN
SELECT reputation_points INTO points FROM reaction_definitions WHERE reaction_type = NEW.reaction_type;
SELECT author_id INTO author FROM forum_posts WHERE id = NEW.post_id;
IF author IS NOT NULL THEN
UPDATE app_users SET reputation_score = reputation_score + points WHERE keycloak_id = author;
END IF;
RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_author_reputation
    AFTER INSERT ON post_reactions
    FOR EACH ROW
    EXECUTE FUNCTION update_author_reputation();

-- ============================================================
-- CONTENT REPORTS
-- ============================================================

CREATE TABLE IF NOT EXISTS report_templates (
                                                id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    report_category report_category_enum NOT NULL,
    template_text TEXT NOT NULL,
    requires_details BOOLEAN DEFAULT FALSE NOT NULL,
    auto_severity severity_enum NOT NULL,
    display_order INTEGER DEFAULT 0 NOT NULL,
    is_active BOOLEAN DEFAULT TRUE NOT NULL,
    reason_code report_reason_code_enum,
    example_details TEXT,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
                             );

TRUNCATE report_templates RESTART IDENTITY CASCADE;

INSERT INTO report_templates (report_category, template_text, requires_details, auto_severity, display_order, reason_code, example_details) VALUES
                                                                                                                                                ('SPAM', 'This post contains spam or promotional content', FALSE, 'LOW', 1, 'SPAM_PROMOTIONAL', NULL),
                                                                                                                                                ('SPAM', 'This post is off-topic or irrelevant to the discussion', FALSE, 'LOW', 2, 'SPAM_OFFTOPIC', NULL),
                                                                                                                                                ('HARASSMENT', 'This post harasses or bullies another user', TRUE, 'HIGH', 3, 'HARASSMENT_BULLYING', 'Please provide specific examples of the harassing behavior'),
                                                                                                                                                ('HARASSMENT', 'This post contains personal attacks against another user', TRUE, 'HIGH', 4, 'HARASSMENT_PERSONAL_ATTACK', 'Please quote the specific personal attack'),
                                                                                                                                                ('SELF_HARM', 'This post discusses self-harm in concerning detail', TRUE, 'CRITICAL', 5, 'SELF_HARM_DETAILED', 'Please describe what concerns you about this content'),
                                                                                                                                                ('SUICIDE', 'This post expresses suicidal thoughts or plans', TRUE, 'CRITICAL', 6, 'SUICIDE_EXPRESSION', 'Is the user seeking help or expressing intent?'),
                                                                                                                                                ('VIOLENCE', 'This post contains threats of violence', TRUE, 'CRITICAL', 7, 'VIOLENCE_THREATS', 'Please quote the specific threat'),
                                                                                                                                                ('MISINFORMATION', 'This post contains dangerous mental health misinformation', TRUE, 'HIGH', 8, 'MISINFORMATION_DANGEROUS', 'Please explain why this information is harmful'),
                                                                                                                                                ('PRIVACY_VIOLATION', 'This post shares someone''s personal information without consent', TRUE, 'HIGH', 9, 'PRIVACY_DOXING', 'What personal information was shared?'),
                                                                                                                                                ('INAPPROPRIATE', 'This post contains inappropriate content for this community', TRUE, 'MEDIUM', 10, 'INAPPROPRIATE_CONTENT', 'Please explain why this content is inappropriate'),
                                                                                                                                                ('OTHER', 'Other reason (please explain in detail)', TRUE, 'MEDIUM', 11, 'OTHER_REASON', 'Please provide a detailed explanation')
    ON CONFLICT DO NOTHING;

CREATE TABLE IF NOT EXISTS content_reports (
                                               id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    reporter_id UUID NOT NULL REFERENCES app_users(keycloak_id) ON DELETE CASCADE,
    is_anonymous BOOLEAN DEFAULT FALSE NOT NULL,
    target_type report_target_type_enum NOT NULL,
    thread_id UUID REFERENCES forum_threads(id) ON DELETE CASCADE,
    post_id UUID REFERENCES forum_posts(id) ON DELETE CASCADE,
    reported_user_id UUID REFERENCES app_users(keycloak_id) ON DELETE SET NULL,
    report_category report_category_enum NOT NULL,
    severity severity_enum NOT NULL,
    reason VARCHAR(100) NOT NULL,
    details TEXT,
    status report_status_enum DEFAULT 'PENDING' NOT NULL,
    assigned_moderator_id UUID REFERENCES app_users(keycloak_id) ON DELETE SET NULL,
    assigned_at TIMESTAMP WITH TIME ZONE,
    reviewed_at TIMESTAMP WITH TIME ZONE,
                                                                    reviewed_by UUID REFERENCES app_users(keycloak_id) ON DELETE SET NULL,
    action_taken moderation_action_enum,
    action_taken_details TEXT,
    resolution_notes TEXT,
    dismissal_reason dismissal_reason_enum,
    auto_flagged BOOLEAN DEFAULT FALSE NOT NULL,
    related_report_ids UUID[],
    appeal_id UUID,
    reported_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    last_modified_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
                                                                    CONSTRAINT chk_report_target CHECK (
                                                                    (target_type = 'POST' AND post_id IS NOT NULL) OR
(target_type = 'THREAD' AND thread_id IS NOT NULL) OR
(target_type = 'USER' AND reported_user_id IS NOT NULL)
    ),
    CONSTRAINT chk_dismissal_reason_required CHECK (
(status != 'DISMISSED') OR
(status = 'DISMISSED' AND dismissal_reason IS NOT NULL)
    )
    );

-- Drop old unique constraint if exists
ALTER TABLE content_reports DROP CONSTRAINT IF EXISTS uq_user_report;

-- Partial unique indexes for active reports
CREATE UNIQUE INDEX IF NOT EXISTS uq_user_active_thread_report ON content_reports (reporter_id, thread_id) WHERE status IN ('PENDING', 'UNDER_REVIEW') AND thread_id IS NOT NULL;
CREATE UNIQUE INDEX IF NOT EXISTS uq_user_active_post_report ON content_reports (reporter_id, post_id) WHERE status IN ('PENDING', 'UNDER_REVIEW') AND post_id IS NOT NULL;
CREATE UNIQUE INDEX IF NOT EXISTS uq_user_active_user_report ON content_reports (reporter_id, reported_user_id) WHERE status IN ('PENDING', 'UNDER_REVIEW') AND reported_user_id IS NOT NULL;

-- Indexes for content_reports
CREATE INDEX IF NOT EXISTS idx_reports_pending ON content_reports (status, severity DESC, reported_at DESC) WHERE status = 'PENDING';
CREATE INDEX IF NOT EXISTS idx_reports_assigned ON content_reports (assigned_moderator_id, status) WHERE assigned_moderator_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_reports_reporter ON content_reports (reporter_id, reported_at DESC);
CREATE INDEX IF NOT EXISTS idx_reports_post ON content_reports (post_id) WHERE post_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_reports_thread ON content_reports (thread_id) WHERE thread_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_user_report_history ON content_reports (reporter_id, reported_at DESC);

-- Report history
CREATE TABLE IF NOT EXISTS report_history (
                                              id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    report_id UUID NOT NULL REFERENCES content_reports(id) ON DELETE CASCADE,
    action TEXT NOT NULL,
    old_value TEXT,
    new_value TEXT,
    acted_by UUID REFERENCES app_users(keycloak_id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
                                                               );

CREATE INDEX IF NOT EXISTS idx_report_history_report ON report_history(report_id, created_at DESC);

-- User report history
CREATE TABLE IF NOT EXISTS user_report_history (
                                                   user_id UUID PRIMARY KEY REFERENCES app_users(keycloak_id) ON DELETE CASCADE,
    total_reports_made INTEGER DEFAULT 0 NOT NULL,
    reports_upheld INTEGER DEFAULT 0 NOT NULL,
    reports_dismissed INTEGER DEFAULT 0 NOT NULL,
    accuracy_rate NUMERIC(5,2) GENERATED ALWAYS AS (
                                                       CASE WHEN total_reports_made > 0 THEN (reports_upheld::NUMERIC / total_reports_made * 100) ELSE 0 END
    ) STORED,
    last_report_at TIMESTAMP WITH TIME ZONE,
    is_report_banned BOOLEAN DEFAULT FALSE NOT NULL,
    report_ban_reason TEXT,
    report_ban_until TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
                                                                                                                  );

-- Triggers for content_reports
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

CREATE OR REPLACE FUNCTION update_report_history()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO user_report_history (user_id, total_reports_made, last_report_at)
        VALUES (NEW.reporter_id, 1, NEW.reported_at)
        ON CONFLICT (user_id) DO UPDATE
                                            SET total_reports_made = user_report_history.total_reports_made + 1,
                                            last_report_at = NEW.reported_at;
INSERT INTO report_history(report_id, action, new_value, acted_by)
VALUES (NEW.id, 'CREATED', NEW.status::text, NEW.reporter_id);
END IF;

    IF TG_OP = 'UPDATE' THEN
        IF OLD.status IS DISTINCT FROM NEW.status THEN
            INSERT INTO report_history(report_id, action, old_value, new_value, acted_by)
            VALUES (NEW.id, 'STATUS_CHANGED', OLD.status::text, NEW.status::text, NEW.reviewed_by);
            IF OLD.status = 'PENDING' AND NEW.status IN ('ACTION_TAKEN', 'DISMISSED') THEN
UPDATE user_report_history
SET reports_upheld = reports_upheld + CASE WHEN NEW.status = 'ACTION_TAKEN' THEN 1 ELSE 0 END,
    reports_dismissed = reports_dismissed + CASE WHEN NEW.status = 'DISMISSED' THEN 1 ELSE 0 END
WHERE user_id = NEW.reporter_id;
END IF;
END IF;
        IF OLD.assigned_moderator_id IS DISTINCT FROM NEW.assigned_moderator_id THEN
            INSERT INTO report_history(report_id, action, old_value, new_value, acted_by)
            VALUES (NEW.id, 'ASSIGNED', OLD.assigned_moderator_id::text, NEW.assigned_moderator_id::text, NEW.assigned_moderator_id);
END IF;
        IF OLD.severity IS DISTINCT FROM NEW.severity THEN
            INSERT INTO report_history(report_id, action, old_value, new_value, acted_by)
            VALUES (NEW.id, 'SEVERITY_CHANGED', OLD.severity::text, NEW.severity::text, NEW.reviewed_by);
END IF;
        IF OLD.action_taken IS DISTINCT FROM NEW.action_taken AND NEW.action_taken IS NOT NULL THEN
            INSERT INTO report_history(report_id, action, new_value, acted_by)
            VALUES (NEW.id, 'ACTION_TAKEN', NEW.action_taken::text, NEW.reviewed_by);
END IF;
END IF;

RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_report_history
    AFTER INSERT OR UPDATE ON content_reports
                        FOR EACH ROW
                        EXECUTE FUNCTION update_report_history();

-- Flag content on report
CREATE OR REPLACE FUNCTION flag_content_on_report()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.target_type = 'POST' AND NEW.post_id IS NOT NULL THEN
UPDATE forum_posts SET flagged_for_review = TRUE WHERE id = NEW.post_id;
END IF;
RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_flag_content_on_report
    AFTER INSERT ON content_reports
    FOR EACH ROW
    EXECUTE FUNCTION flag_content_on_report();

-- ============================================================
-- MODERATION TEMPLATES
-- ============================================================

CREATE TABLE IF NOT EXISTS moderation_action_templates (
                                                           id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    action_type moderation_action_enum NOT NULL UNIQUE,
    default_message TEXT NOT NULL,
    description TEXT,
    example_message TEXT,
    display_order INTEGER DEFAULT 0 NOT NULL,
    is_active BOOLEAN DEFAULT TRUE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
                             );

INSERT INTO moderation_action_templates (action_type, default_message, description, example_message, display_order) VALUES
                                                                                                                        ('POST_DELETED', 'Your post has been removed for violating community guidelines.', 'Remove inappropriate content', 'The post contained personal attacks which are not allowed', 1),
                                                                                                                        ('POST_EDITED', 'Your post has been edited by a moderator to comply with community guidelines.', 'Moderator edits to remove violating content', 'Edited to remove an offensive phrase', 2),
                                                                                                                        ('POST_FLAGGED', 'Your post has been flagged for review due to potential guideline violations.', 'Add flag/notice to post for further review', 'Flagged for potential misinformation', 3),
                                                                                                                        ('POST_CONTENT_WARNING_ADDED', 'A content warning has been added to your post to help users make informed choices.', 'Add trigger warning overlay', 'Added "self-harm" content warning', 4),
                                                                                                                        ('POST_RESTORED', 'Your post has been restored after review. We apologize for any inconvenience.', 'Undo a deletion', 'Post was incorrectly removed as spam', 5),
                                                                                                                        ('THREAD_LOCKED', 'This thread has been locked as it violates community guidelines.', 'Prevent new replies', 'Discussion became heated; locked to prevent escalation', 6),
                                                                                                                        ('THREAD_UNLOCKED', 'This thread has been unlocked and is now open for replies.', 'Reopen a locked thread', 'Thread was locked in error; now reopened', 7),
                                                                                                                        ('THREAD_DELETED', 'This thread has been removed for violating community guidelines.', 'Soft delete entire thread', 'Thread contained dangerous misinformation', 8),
                                                                                                                        ('THREAD_MOVED', 'This thread has been moved to a more appropriate category.', 'Move thread to different category', 'Moved from General to Self-Help category', 9),
                                                                                                                        ('THREAD_MERGED', 'Your thread has been merged with an existing discussion on the same topic.', 'Combine with another thread', 'Merged duplicate threads', 10),
                                                                                                                        ('THREAD_SPLIT', 'Some posts have been split from this thread to create a new discussion.', 'Split posts into new thread', 'Off-topic replies moved to separate thread', 11),
                                                                                                                        ('THREAD_STATUS_CHANGED', 'The status of this thread has been updated.', 'Change thread status', 'Thread marked as "RESOLVED"', 12),
                                                                                                                        ('THREAD_FEATURED', 'This thread has been featured as an important discussion.', 'Pin/promote thread', 'Featured for its helpful resources', 13),
                                                                                                                        ('THREAD_UNFEATURED', 'This thread is no longer featured.', 'Remove pin/promotion', 'Removed from featured after 30 days', 14),
                                                                                                                        ('USER_WARNED', 'You have received a formal warning for violating community guidelines.', 'Issue formal warning', 'Warning for repeatedly derailing discussions', 15),
                                                                                                                        ('USER_MUTED', 'You have been temporarily muted. You can read but cannot post for the specified duration.', 'Temporarily prevent posting', 'Muted for 24 hours after multiple violations', 16),
                                                                                                                        ('USER_UNMUTED', 'Your mute has been lifted. You may now post again.', 'Remove mute restriction', 'Mute expired or lifted early', 17),
                                                                                                                        ('USER_SUSPENDED', 'Your account has been temporarily suspended. You will regain access after the suspension period.', 'Temporary account suspension', 'Suspended for 7 days due to serious harassment', 18),
                                                                                                                        ('USER_UNSUSPENDED', 'Your suspension has been lifted. Welcome back.', 'End suspension early', 'Suspension lifted after successful appeal', 19),
                                                                                                                        ('USER_BANNED', 'Your account has been permanently banned for severe or repeated violations.', 'Permanent ban', 'Permanent ban for sharing self-harm methods', 20),
                                                                                                                        ('USER_UNBANNED', 'Your ban has been lifted. Please review community guidelines before posting.', 'Reverse permanent ban', 'Ban lifted after appeal', 21),
                                                                                                                        ('USER_REPUTATION_ADJUSTED', 'Your reputation score has been adjusted based on recent moderation actions.', 'Adjust user reputation', 'Reputation decreased by 50 points for spam', 22),
                                                                                                                        ('REPORT_ASSIGNED', 'Your report has been assigned to a moderator for review. We will update you once a decision has been made.', 'Report assigned to moderator', 'Report ID #123 assigned to Moderator Jane', 23),
                                                                                                                        ('REPORT_ACTIONED', 'Thank you for your report. Action has been taken based on your submission.', 'Report resolved with action', 'Post removed and user warned based on your report', 24),
                                                                                                                        ('REPORT_DISMISSED', 'Thank you for your report. After review, no action was taken.', 'Report closed without action', 'Report dismissed as no violation found', 25),
                                                                                                                        ('REPORT_ESCALATED', 'This report has been escalated to admin review due to its complexity or severity.', 'Report requires higher-level review', 'Escalated to admin due to potential legal implications', 26),
                                                                                                                        ('REPORT_DETAILS_UPDATED', 'Report details have been updated by a moderator.', 'Moderator updated report metadata', 'Severity changed from HIGH to CRITICAL after review', 27)
    ON CONFLICT (action_type) DO NOTHING;

-- Dismissal reason templates
CREATE TABLE IF NOT EXISTS dismissal_reason_templates (
                                                          id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    reason_code dismissal_reason_enum NOT NULL UNIQUE,
    default_message TEXT NOT NULL,
    description TEXT,
    example_message TEXT,
    display_order INTEGER DEFAULT 0 NOT NULL,
    is_active BOOLEAN DEFAULT TRUE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
                             );

INSERT INTO dismissal_reason_templates (reason_code, default_message, description, example_message, display_order) VALUES
                                                                                                                       ('FALSE_POSITIVE', 'This report was determined to be a false positive. No violation of community guidelines was found.', 'Content does not violate rules', 'Reported a post for "harassment" but it was politely disagreeing', 1),
                                                                                                                       ('NO_VIOLATION', 'After careful review, this content does not violate our community guidelines. No action will be taken.', 'Content is technically allowed', 'Discussion of sensitive mental health topics is permitted', 2),
                                                                                                                       ('ALREADY_HANDLED', 'This issue has already been addressed by moderators. The report is being closed.', 'Another moderator already acted', 'Another moderator already deleted the offending post', 3),
                                                                                                                       ('CONTENT_GONE', 'The reported content is no longer available or has been removed.', 'Content no longer exists', 'User deleted their own post before review', 4),
                                                                                                                       ('INSUFFICIENT_EVIDENCE', 'There is insufficient evidence to take action on this report at this time.', 'Cannot verify violation', 'No screenshots or clear evidence provided', 5),
                                                                                                                       ('USER_EDUCATED', 'The user has been privately contacted with guidance about community expectations. No formal action recorded.', 'Informal education', 'New user who didn''t know about self-promotion rule', 6),
                                                                                                                       ('DUPLICATE_REPORT', 'This report is a duplicate of an existing active report. Closing this instance.', 'Same content reported multiple times', 'Five users reported the same post; only one needs to stay open', 7),
                                                                                                                       ('ALLOWED_CONTENT', 'This content is explicitly allowed under our policies. Please review our guidelines.', 'Content is permitted by design', 'Reporting a support thread in a support category', 8),
                                                                                                                       ('PROTECTED_CONTENT', 'The reported behavior falls under protected discussion of mental health experiences. No violation.', 'Content is protected under safe space policy', 'User sharing their own struggle with self-harm (seeking help)', 9)
    ON CONFLICT (reason_code) DO NOTHING;

-- ============================================================
-- MODERATION QUEUE
-- ============================================================

CREATE TABLE IF NOT EXISTS moderation_queue (
                                                id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    source queue_source_enum NOT NULL,
    flagged_by UUID REFERENCES app_users(keycloak_id) ON DELETE SET NULL,
    flagged_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
                                                          target_type report_target_type_enum NOT NULL,
                                                          target_id UUID NOT NULL,
                                                          reason TEXT NOT NULL,
                                                          ai_confidence_score DECIMAL(3,2),
    cleared_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
                                                          );

CREATE INDEX IF NOT EXISTS idx_queue_active ON moderation_queue (cleared_at) WHERE cleared_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_queue_target ON moderation_queue (target_type, target_id);

-- ============================================================
-- MODERATION RULES
-- ============================================================

CREATE TABLE IF NOT EXISTS moderation_rules (
                                                id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    rule_name VARCHAR(100) NOT NULL,
    description TEXT,
    trigger_conditions JSONB NOT NULL,
    action_type moderation_action_enum NOT NULL,
    action_parameters JSONB,
    priority INTEGER DEFAULT 0 NOT NULL,
    is_active BOOLEAN DEFAULT TRUE NOT NULL,
    created_by UUID NOT NULL REFERENCES app_users(keycloak_id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    last_triggered_at TIMESTAMP WITH TIME ZONE,
                                    trigger_count INTEGER DEFAULT 0 NOT NULL
                                    );

CREATE INDEX IF NOT EXISTS idx_rules_active ON moderation_rules (is_active, priority DESC) WHERE is_active = TRUE;

-- ============================================================
-- MODERATION LOGS & RESTRICTIONS
-- ============================================================

CREATE TABLE IF NOT EXISTS moderation_tiers (
                                                tier_name VARCHAR(50) PRIMARY KEY,
    allowed_actions JSONB NOT NULL,
    action_limits JSONB DEFAULT '{}'
    );

INSERT INTO moderation_tiers (tier_name, allowed_actions, action_limits) VALUES
                                                                             ('moderator', '{"allowed_actions": ["POST_DELETED", "POST_EDITED", "POST_FLAGGED", "THREAD_LOCKED", "THREAD_UNLOCKED", "THREAD_MOVED", "USER_WARNED", "USER_MUTED", "REPORT_ASSIGNED", "REPORT_ACTIONED"], "restrictions": {"max_mute_duration_hours": 24, "cannot_permanent_ban": true, "cannot_change_roles": true}}', '{}'),
                                                                             ('admin', '{"allowed_actions": ["POST_DELETED", "POST_EDITED", "POST_FLAGGED", "POST_RESTORED", "THREAD_LOCKED", "THREAD_UNLOCKED", "THREAD_DELETED", "THREAD_MOVED", "USER_WARNED", "USER_MUTED", "USER_SUSPENDED", "USER_BANNED", "USER_REPUTATION_ADJUSTED", "ROLE_GRANTED", "ROLE_REVOKED"], "restrictions": {}}', '{}')
    ON CONFLICT (tier_name) DO NOTHING;

CREATE TABLE IF NOT EXISTS moderation_log (
                                              id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    moderator_id UUID NOT NULL REFERENCES app_users(keycloak_id),
    action_type moderation_action_enum NOT NULL,
    action_description VARCHAR(255) NOT NULL,
    rationale TEXT NOT NULL,
    target_user_id UUID REFERENCES app_users(keycloak_id) ON DELETE SET NULL,
    target_post_id UUID REFERENCES forum_posts(id) ON DELETE SET NULL,
    target_thread_id UUID REFERENCES forum_threads(id) ON DELETE SET NULL,
    report_id UUID REFERENCES content_reports(id) ON DELETE SET NULL,
    metadata JSONB,
    visibility visibility_enum DEFAULT 'MODERATORS_ONLY' NOT NULL,
    expires_at TIMESTAMP WITH TIME ZONE,
                                                              is_automated BOOLEAN DEFAULT FALSE NOT NULL,
                                                              automation_rule_id UUID REFERENCES moderation_rules(id) ON DELETE SET NULL,
    appeal_allowed BOOLEAN DEFAULT FALSE NOT NULL,
    appeal_deadline TIMESTAMP WITH TIME ZONE,
    action_taken_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
                                                              );

CREATE INDEX IF NOT EXISTS idx_moderator_actions ON moderation_log (moderator_id, action_taken_at DESC);
CREATE INDEX IF NOT EXISTS idx_user_history ON moderation_log (target_user_id, action_taken_at DESC);
CREATE INDEX IF NOT EXISTS idx_action_type ON moderation_log (action_type, action_taken_at DESC);
CREATE INDEX IF NOT EXISTS idx_report_actions ON moderation_log (report_id) WHERE report_id IS NOT NULL;

-- Warning type definitions
CREATE TABLE IF NOT EXISTS warning_type_definitions (
                                                        warning_type warning_type_enum PRIMARY KEY,
                                                        display_name VARCHAR(50) NOT NULL,
    description TEXT NOT NULL,
    severity_level INTEGER NOT NULL
    );

INSERT INTO warning_type_definitions (warning_type, display_name, description, severity_level) VALUES
                                                                                                   ('INFORMAL', 'Informal Reminder', 'Friendly nudge about community guidelines', 1),
                                                                                                   ('FORMAL', 'Formal Warning', 'Official warning on record', 2),
                                                                                                   ('FINAL', 'Final Warning', 'Last warning before suspension/ban', 3),
                                                                                                   ('POLICY_VIOLATION', 'Policy Violation', 'Specific community rule violated', 2)
    ON CONFLICT (warning_type) DO NOTHING;

CREATE TABLE IF NOT EXISTS user_warnings (
                                             id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES app_users(keycloak_id) ON DELETE CASCADE,
    warned_by UUID NOT NULL REFERENCES app_users(keycloak_id),
    warning_type warning_type_enum NOT NULL,
    warning_text TEXT NOT NULL,
    related_post_id UUID REFERENCES forum_posts(id) ON DELETE SET NULL,
    related_thread_id UUID REFERENCES forum_threads(id) ON DELETE SET NULL,
    related_report_id UUID REFERENCES content_reports(id) ON DELETE SET NULL,
    warned_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    acknowledged_at TIMESTAMP WITH TIME ZONE,
    expires_at TIMESTAMP WITH TIME ZONE,
                                                                is_active BOOLEAN DEFAULT TRUE NOT NULL
                                                                );

CREATE INDEX IF NOT EXISTS idx_warnings_user ON user_warnings (user_id, warned_at DESC);
CREATE INDEX IF NOT EXISTS idx_warnings_active ON user_warnings (user_id, is_active) WHERE is_active = TRUE;

CREATE TABLE IF NOT EXISTS user_restrictions (
                                                 id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES app_users(keycloak_id) ON DELETE CASCADE,
    restriction_type restriction_type_enum NOT NULL,
    reason TEXT NOT NULL,
    imposed_by UUID NOT NULL REFERENCES app_users(keycloak_id),
    related_report_id UUID REFERENCES content_reports(id) ON DELETE SET NULL,
    restricted_category_id UUID REFERENCES forum_categories(id) ON DELETE CASCADE,
    starts_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    expires_at TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN DEFAULT TRUE NOT NULL,
    lifted_at TIMESTAMP WITH TIME ZONE,
                                                                lifted_by UUID REFERENCES app_users(keycloak_id),
    lift_reason TEXT
    );

CREATE INDEX IF NOT EXISTS idx_restrictions_user ON user_restrictions (user_id, is_active);
CREATE INDEX IF NOT EXISTS idx_restrictions_active ON user_restrictions (expires_at) WHERE is_active = TRUE AND expires_at IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_restrictions_type ON user_restrictions (restriction_type, is_active);

-- ============================================================
-- ROLE & GROUP CONFIGURATIONS
-- ============================================================

CREATE TABLE IF NOT EXISTS role_configurations (
                                                   role_name realm_role_enum PRIMARY KEY,
                                                   capabilities JSONB NOT NULL DEFAULT '{}'
);

INSERT INTO role_configurations (role_name) VALUES
                                                ('moderator'), ('forum_member'), ('peer_supporter'), ('trusted_member'), ('admin')
    ON CONFLICT (role_name) DO NOTHING;

CREATE TABLE IF NOT EXISTS group_configurations (
                                                    group_path groups_enum PRIMARY KEY,
                                                    capabilities JSONB NOT NULL DEFAULT '{}'
);

INSERT INTO group_configurations (group_path) VALUES
                                                  ('members'), ('members/new'), ('members/active'), ('members/trusted'),
                                                  ('moderators'), ('moderators/peer'), ('moderators/professional'), ('administrators')
    ON CONFLICT (group_path) DO NOTHING;

-- ============================================================
-- DISCOVERY & SUPPORT GRAPH
-- ============================================================

-- Thread Bookmarks (Personal Favorites)
CREATE TABLE IF NOT EXISTS thread_bookmarks (
                                                id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES app_users(keycloak_id) ON DELETE CASCADE,
    thread_id UUID NOT NULL REFERENCES forum_threads(id) ON DELETE CASCADE,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
                                                                UNIQUE(user_id, thread_id)
    );

CREATE INDEX IF NOT EXISTS idx_bookmarks_user ON thread_bookmarks(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_bookmarks_thread ON thread_bookmarks(thread_id);

-- User Connections (Mutual Handshake) - This replaces user_follows
CREATE TABLE IF NOT EXISTS user_connections (
                                                id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_1 UUID NOT NULL REFERENCES app_users(keycloak_id) ON DELETE CASCADE,
    user_2 UUID NOT NULL REFERENCES app_users(keycloak_id) ON DELETE CASCADE,
    initiated_by UUID NOT NULL REFERENCES app_users(keycloak_id) ON DELETE CASCADE,
    status connection_status_enum NOT NULL DEFAULT 'PENDING',
    notification_enabled BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
                                                               CONSTRAINT chk_no_self_connection CHECK (user_1 <> user_2),
    CONSTRAINT chk_initiated_by_is_one_of_users CHECK (initiated_by = user_1 OR initiated_by = user_2),
    UNIQUE(user_1, user_2)
    );

CREATE INDEX IF NOT EXISTS idx_pending_incoming ON user_connections (user_1, user_2) WHERE status = 'PENDING';
CREATE INDEX IF NOT EXISTS idx_connections_active ON user_connections (user_1, user_2) WHERE status = 'ACCEPTED';
CREATE INDEX IF NOT EXISTS idx_connections_initiated ON user_connections (initiated_by) WHERE status = 'PENDING';
CREATE INDEX IF NOT EXISTS idx_user_connections_lookup ON user_connections (user_1, user_2);
CREATE INDEX IF NOT EXISTS idx_connections_updated ON user_connections (updated_at);

-- Focus Categories (Personal Dashboard Curation)
CREATE TABLE IF NOT EXISTS focus_categories (
                                                id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES app_users(keycloak_id) ON DELETE CASCADE,
    category_id UUID NOT NULL REFERENCES forum_categories(id) ON DELETE CASCADE,
    notification_enabled BOOLEAN DEFAULT FALSE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
                                                                UNIQUE(user_id, category_id)
    );

CREATE INDEX IF NOT EXISTS idx_focus_user ON focus_categories(user_id);

-- Thread Watches (Temporary Notification Monitors)
CREATE TABLE IF NOT EXISTS watch_threads (
                                             id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES app_users(keycloak_id) ON DELETE CASCADE,
    thread_id UUID NOT NULL REFERENCES forum_threads(id) ON DELETE CASCADE,
    notification_enabled BOOLEAN DEFAULT FALSE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
                                                                UNIQUE(user_id, thread_id)
    );

CREATE INDEX IF NOT EXISTS idx_watches_user ON watch_threads(user_id);

-- ============================================================
-- NOTIFICATIONS
-- ============================================================

CREATE TABLE IF NOT EXISTS notifications (
                                             id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    recipient_id UUID NOT NULL REFERENCES app_users(keycloak_id) ON DELETE CASCADE,
    notification_type notification_type_enum NOT NULL,
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    action_url VARCHAR(500),
    related_user_id UUID REFERENCES app_users(keycloak_id) ON DELETE SET NULL,
    related_post_id UUID REFERENCES forum_posts(id) ON DELETE SET NULL,
    related_thread_id UUID REFERENCES forum_threads(id) ON DELETE SET NULL,
    related_category_id UUID REFERENCES forum_categories(id) ON DELETE SET NULL,
    sent_via TEXT[] DEFAULT ARRAY['in_app'],
    is_read BOOLEAN DEFAULT FALSE NOT NULL,
    read_at TIMESTAMP WITH TIME ZONE,
    is_batched BOOLEAN DEFAULT FALSE,
    batch_count INTEGER,
    batch_metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    expires_at TIMESTAMP WITH TIME ZONE GENERATED ALWAYS AS (created_at + INTERVAL '90 days') STORED
    );

CREATE INDEX IF NOT EXISTS idx_notifications_recipient ON notifications (recipient_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notifications_unread ON notifications (recipient_id, is_read, created_at DESC) WHERE is_read = FALSE;
CREATE INDEX IF NOT EXISTS idx_notifications_type ON notifications (notification_type, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notifications_expiry ON notifications (expires_at);

-- ============================================================
-- NOTIFICATION TRIGGERS
-- ============================================================

CREATE OR REPLACE FUNCTION notify_on_reply()
RETURNS TRIGGER AS $$
DECLARE
thread_creator_id UUID;
    parent_post_author_id UUID;
BEGIN
    IF NEW.parent_post_id IS NULL THEN
SELECT creator_id INTO thread_creator_id FROM forum_threads WHERE id = NEW.thread_id;
IF thread_creator_id IS NOT NULL AND thread_creator_id != NEW.author_id THEN
            INSERT INTO notifications (recipient_id, notification_type, title, message, action_url, related_user_id, related_post_id, related_thread_id)
SELECT thread_creator_id, 'REPLY', 'New reply to your thread',
       (SELECT display_name FROM app_users WHERE keycloak_id = NEW.author_id) || ' replied to your thread',
       '/threads/' || NEW.thread_id || '/posts/' || NEW.id,
       NEW.author_id, NEW.id, NEW.thread_id
    WHERE EXISTS (SELECT 1 FROM app_users WHERE keycloak_id = thread_creator_id AND notification_preferences->'inApp'->>'replies' = 'true');
END IF;
ELSE
SELECT author_id INTO parent_post_author_id FROM forum_posts WHERE id = NEW.parent_post_id;
IF parent_post_author_id IS NOT NULL AND parent_post_author_id != NEW.author_id THEN
            INSERT INTO notifications (recipient_id, notification_type, title, message, action_url, related_user_id, related_post_id, related_thread_id)
SELECT parent_post_author_id, 'REPLY', 'New reply to your post',
       (SELECT display_name FROM app_users WHERE keycloak_id = NEW.author_id) || ' replied to your post',
       '/threads/' || NEW.thread_id || '/posts/' || NEW.id,
       NEW.author_id, NEW.id, NEW.thread_id
    WHERE EXISTS (SELECT 1 FROM app_users WHERE keycloak_id = parent_post_author_id AND notification_preferences->'inApp'->>'replies' = 'true');
END IF;
END IF;
RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_notify_on_reply
    AFTER INSERT ON forum_posts
    FOR EACH ROW
    EXECUTE FUNCTION notify_on_reply();

-- ============================================================
-- UPDATE USER CONNECTIONS TIMESTAMP
-- ============================================================

CREATE OR REPLACE FUNCTION update_user_connections_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_user_connections_updated_at
    BEFORE UPDATE ON user_connections
    FOR EACH ROW
    EXECUTE FUNCTION update_user_connections_updated_at();

-- ============================================================
-- CLEANUP FUNCTIONS
-- ============================================================

CREATE OR REPLACE FUNCTION expire_restrictions()
RETURNS void AS $$
BEGIN
UPDATE user_restrictions
SET is_active = FALSE
WHERE is_active = TRUE AND expires_at IS NOT NULL AND expires_at < NOW();
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION expire_warnings()
RETURNS void AS $$
BEGIN
UPDATE user_warnings
SET is_active = FALSE
WHERE is_active = TRUE AND expires_at IS NOT NULL AND expires_at < NOW();
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION cleanup_expired_notifications()
RETURNS void AS $$
BEGIN
DELETE FROM notifications WHERE expires_at < NOW();
END;
$$ LANGUAGE plpgsql;

-- ============================================================
-- VIEWS
-- ============================================================

CREATE OR REPLACE VIEW user_active_restrictions AS
SELECT
    user_id,
    array_agg(restriction_type) as active_restriction_types,
    MAX(expires_at) as latest_expiry
FROM user_restrictions
WHERE is_active = TRUE AND (expires_at IS NULL OR expires_at > NOW())
GROUP BY user_id;

CREATE OR REPLACE VIEW user_warning_counts AS
SELECT
    user_id,
    COUNT(*) FILTER (WHERE warning_type = 'INFORMAL') as informal_warnings,
    COUNT(*) FILTER (WHERE warning_type = 'FORMAL') as formal_warnings,
    COUNT(*) FILTER (WHERE warning_type = 'FINAL') as final_warnings,
    COUNT(*) as total_active_warnings
FROM user_warnings
WHERE is_active = TRUE AND (expires_at IS NULL OR expires_at > NOW())
GROUP BY user_id;

CREATE OR REPLACE VIEW user_connection_counts AS
SELECT
    u.keycloak_id as user_id,
    (SELECT COUNT(*) FROM user_connections WHERE (user_1 = u.keycloak_id OR user_2 = u.keycloak_id) AND status = 'ACCEPTED') as connection_count,
    (SELECT COUNT(*) FROM user_connections WHERE user_1 = u.keycloak_id AND status = 'ACCEPTED') as connections_initiated_count,
    (SELECT COUNT(*) FROM user_connections WHERE user_2 = u.keycloak_id AND status = 'ACCEPTED') as connections_received_count
FROM app_users u;

CREATE OR REPLACE VIEW trending_threads AS
SELECT
    ft.id,
    ft.title,
    ft.category_id,
    ft.creator_id,
    ft.view_count,
    ft.post_count,
    ft.created_at,
    ft.last_activity_at,
    (ft.post_count * 2 + ft.view_count / 10 + CASE
                                                  WHEN ft.last_activity_at > NOW() - INTERVAL '1 day' THEN 50
        WHEN ft.last_activity_at > NOW() - INTERVAL '3 days' THEN 20
        ELSE 0
        END) AS trending_score
FROM forum_threads ft
WHERE ft.is_deleted = FALSE
  AND ft.thread_status = 'OPEN'
  AND ft.last_activity_at > NOW() - INTERVAL '7 days'
ORDER BY trending_score DESC
    LIMIT 50;

CREATE OR REPLACE VIEW user_category_activity AS
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

-- ============================================================
-- FINAL VALIDATION QUERY
-- ============================================================

SELECT 'Schema validation complete!' as status;