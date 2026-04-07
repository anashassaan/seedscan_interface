/**
 * ═══════════════════════════════════════════════════════════════════════════
 * SeedScan — Appwrite Collection Setup Script
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * This script creates ALL required collections & attributes in your
 * Appwrite database. Run it ONCE via Node.js.
 *
 * PREREQUISITES:
 *   1. npm install node-appwrite
 *   2. Set the API_KEY below (create one in Appwrite Console → Settings → API Keys
 *      with Database read/write scopes).
 *   3. node appwrite_setup.js
 *
 * It's safe to re-run — it skips collections/attributes that already exist.
 * ═══════════════════════════════════════════════════════════════════════════
 */

const sdk = require("node-appwrite");

// ══════════ CONFIGURATION — EDIT THESE ══════════
const ENDPOINT   = "https://sgp.cloud.appwrite.io/v1";
const PROJECT_ID = "6971de42002712d649b2";
const API_KEY    = "standard_8aa48787aedff6156ea1aa8a108ee7c52e19d56d9219bd4d1ef96606ac3e28b840ddafce5e3ee88c02630838fc51e86d15fe90945ea1ab2eb5814584d49d686ca677d2f771c48daae9fdcb78fc522cfeed263d5028bfb627a560541b8a4fc09c8b78abeafa02dacf97d91ed9cdf89eca0f111bce80f5c6e10c70c525dee12440";
const DATABASE_ID = "seedscan_main_db";
// ════════════════════════════════════════════════

const client = new sdk.Client();
client.setEndpoint(ENDPOINT).setProject(PROJECT_ID).setKey(API_KEY);

const databases = new sdk.Databases(client);
const storage = new sdk.Storage(client);

// Helper: create storage bucket if it doesn't exist
async function ensureBucket(id, name) {
  try {
    const existing = await storage.getBucket(id);
    console.log(`  ✓ Bucket "${name}" already exists`);
    // Fix: ensure fileSecurity is enabled and read is public on existing buckets
    if (!existing.fileSecurity) {
      await storage.updateBucket(id, name, [
        sdk.Permission.read(sdk.Role.any()),
        sdk.Permission.create(sdk.Role.users()),
        sdk.Permission.update(sdk.Role.users()),
        sdk.Permission.delete(sdk.Role.users()),
      ], true, true, 10485760);
      console.log(`  ↑ Updated bucket "${name}": enabled fileSecurity + Role.any() read`);
    }
  } catch {
    await storage.createBucket(id, name, [
      sdk.Permission.read(sdk.Role.any()),
      sdk.Permission.create(sdk.Role.users()),
      sdk.Permission.update(sdk.Role.users()),
      sdk.Permission.delete(sdk.Role.users()),
    ], true, undefined, undefined, 10485760); // fileSecurity: true, 10 MB max
    console.log(`  ✓ Created bucket "${name}"`);
  }
}

// Helper: create collection if it doesn't exist
async function ensureCollection(id, name) {
  try {
    await databases.getCollection(DATABASE_ID, id);
    console.log(`  ✓ Collection "${name}" already exists`);
  } catch {
    await databases.createCollection(DATABASE_ID, id, name, [
      sdk.Permission.read(sdk.Role.users()),
      sdk.Permission.create(sdk.Role.users()),
      sdk.Permission.update(sdk.Role.users()),
      sdk.Permission.delete(sdk.Role.users()),
    ]);
    console.log(`  ✓ Created collection "${name}"`);
  }
}

// Helper: create attribute if it doesn't exist
async function attr(collectionId, type, key, opts = {}) {
  try {
    switch (type) {
      case "string":
        await databases.createStringAttribute(
          DATABASE_ID, collectionId, key,
          opts.size || 255, opts.required ?? false,
          opts.default ?? undefined, opts.array ?? false
        );
        break;
      case "integer":
        await databases.createIntegerAttribute(
          DATABASE_ID, collectionId, key,
          opts.required ?? false,
          opts.min ?? undefined, opts.max ?? undefined,
          opts.default ?? undefined, opts.array ?? false
        );
        break;
      case "float":
        await databases.createFloatAttribute(
          DATABASE_ID, collectionId, key,
          opts.required ?? false,
          opts.min ?? undefined, opts.max ?? undefined,
          opts.default ?? undefined, opts.array ?? false
        );
        break;
      case "boolean":
        await databases.createBooleanAttribute(
          DATABASE_ID, collectionId, key,
          opts.required ?? false,
          opts.default ?? undefined, opts.array ?? false
        );
        break;
      case "datetime":
        await databases.createDatetimeAttribute(
          DATABASE_ID, collectionId, key,
          opts.required ?? false,
          opts.default ?? undefined, opts.array ?? false
        );
        break;
    }
    console.log(`    + ${collectionId}.${key} (${type})`);
  } catch (e) {
    if (e.code === 409) {
      console.log(`    · ${collectionId}.${key} already exists`);
    } else {
      console.error(`    ✗ ${collectionId}.${key}: ${e.message}`);
    }
  }
}

// Helper: create a key index on a collection attribute if it doesn't exist.
// type: 'key' (default for equality queries), 'unique', or 'fulltext'.
async function ensureIndex(collectionId, indexKey, attributes, orders, type = 'key') {
  try {
    await databases.getIndex(DATABASE_ID, collectionId, indexKey);
    console.log(`    · index ${collectionId}[${indexKey}] already exists`);
  } catch {
    try {
      await databases.createIndex(DATABASE_ID, collectionId, indexKey, type, attributes, orders);
      console.log(`    + index ${collectionId}[${indexKey}] (${type})`);
    } catch (e) {
      if (e.code === 409) {
        console.log(`    · index ${collectionId}[${indexKey}] already exists`);
      } else {
        console.error(`    ✗ index ${collectionId}[${indexKey}]: ${e.message}`);
      }
    }
  }
}

// Small delay to let Appwrite index attributes
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

async function main() {
  console.log("═══ SeedScan Appwrite Setup ═══\n");

  // ──────────────────────────────────
  // 1. USERS
  // ──────────────────────────────────
  console.log("1/15 users");
  await ensureCollection("users", "Users");
  await attr("users", "string",  "name");
  await attr("users", "string",  "username");
  await attr("users", "string",  "email");
  await attr("users", "string",  "role",             { size: 20, default: "user" });
  await attr("users", "integer", "wallet_balance",   { default: 0 });
  await attr("users", "integer", "current_streak",   { default: 0 });
  await attr("users", "string",  "joined_drives",    { array: true });
  await attr("users", "string",  "created_at");
  // Admin-specific optional fields
  await attr("users", "string",  "community_name");
  await attr("users", "string",  "organization");
  await attr("users", "string",  "admin_reason",     { size: 500 });
  await sleep(1000);

  // ──────────────────────────────────
  // 2. COMMUNITIES
  // ──────────────────────────────────
  console.log("2/15 communities");
  await ensureCollection("communities", "Communities");
  await attr("communities", "string",  "name");
  await attr("communities", "string",  "description",      { size: 1000 });
  await attr("communities", "string",  "location");
  await attr("communities", "string",  "creator_id");
  await attr("communities", "string",  "cover_image_id");
  await attr("communities", "string",  "image_url",        { size: 500 });
  await attr("communities", "string",  "qr_code_url",      { size: 500 });
  await attr("communities", "string",  "invite_code");
  await attr("communities", "integer", "member_count",      { default: 0 });
  await attr("communities", "integer", "plant_count",       { default: 0 });
  await attr("communities", "string",  "category");
  await attr("communities", "boolean", "is_active",         { default: true });
  await attr("communities", "string",  "created_at");
  await sleep(1000);

  // ──────────────────────────────────
  // 3. COMMUNITY MEMBERS
  // ──────────────────────────────────
  console.log("3/15 community_members");
  await ensureCollection("community_members", "Community Members");
  await attr("community_members", "string", "community_id");
  await attr("community_members", "string", "user_id");
  await attr("community_members", "string", "role",         { size: 20, default: "member" });
  await attr("community_members", "string", "joined_at");
  await sleep(2000);
  await ensureIndex("community_members", "idx_community_id", ["community_id"], ["ASC"]);
  await ensureIndex("community_members", "idx_user_id",      ["user_id"],      ["ASC"]);
  await sleep(1000);

  // ──────────────────────────────────
  // 4. COMMUNITY POSTS
  // ──────────────────────────────────
  console.log("4/15 community_posts");
  await ensureCollection("community_posts", "Community Posts");
  await attr("community_posts", "string",  "community_id");
  await attr("community_posts", "string",  "author_id");
  await attr("community_posts", "string",  "author_name");
  await attr("community_posts", "string",  "content",        { size: 2000 });
  await attr("community_posts", "string",  "image_id");
  await attr("community_posts", "string",  "post_type",      { size: 50, default: "general" });
  await attr("community_posts", "string",  "linked_plant_id");
  await attr("community_posts", "integer", "likes_count",    { default: 0 });
  await attr("community_posts", "integer", "comments_count", { default: 0 });
  await attr("community_posts", "string",  "created_at");
  await sleep(1000);

  // ──────────────────────────────────
  // 5. COMMUNITY COMMENTS
  // ──────────────────────────────────
  console.log("5/15 community_comments");
  await ensureCollection("community_comments", "Community Comments");
  await attr("community_comments", "string", "post_id");
  await attr("community_comments", "string", "author_id");
  await attr("community_comments", "string", "author_name");
  await attr("community_comments", "string", "content",     { size: 1000 });
  await attr("community_comments", "string", "created_at");
  await sleep(1000);

  // ──────────────────────────────────
  // 6. COMMUNITY LIKES
  // ──────────────────────────────────
  console.log("6/15 community_likes");
  await ensureCollection("community_likes", "Community Likes");
  await attr("community_likes", "string", "post_id");
  await attr("community_likes", "string", "user_id");
  await attr("community_likes", "string", "created_at");
  await sleep(1000);

  // ──────────────────────────────────
  // 7. PLANTS
  // ──────────────────────────────────
  console.log("7/15 plants");
  await ensureCollection("plants", "Plants");
  await attr("plants", "string",  "species");
  await attr("plants", "string",  "guardian_id");
  await attr("plants", "string",  "drive_id");
  await attr("plants", "string",  "nickname");
  await attr("plants", "float",   "location_lat");
  await attr("plants", "float",   "location_long");
  await attr("plants", "string",  "health_status",    { size: 20, default: "healthy" });
  await attr("plants", "string",  "image_url",        { size: 500 });
  await attr("plants", "string",  "last_watered");
  await attr("plants", "string",  "phash_history",    { array: true });
  await sleep(2000); // wait for attributes to be ready before creating indexes
  // Indexes required for Query.equal() filtering in the Flutter app
  await ensureIndex("plants", "idx_guardian_id",  ["guardian_id"],  ["ASC"]);
  await ensureIndex("plants", "idx_drive_id",     ["drive_id"],     ["ASC"]);
  await sleep(1000);

  // ──────────────────────────────────
  // 8. ACTIVITY LOGS
  // ──────────────────────────────────
  console.log("8/15 activity_logs");
  await ensureCollection("activity_logs", "Activity Logs");
  await attr("activity_logs", "string",  "user_id");
  await attr("activity_logs", "string",  "plant_id");
  await attr("activity_logs", "string",  "action_type",           { size: 50 });
  await attr("activity_logs", "integer", "coins_awarded",         { default: 0 });
  await attr("activity_logs", "string",  "verification_status",   { size: 20 });
  await attr("activity_logs", "string",  "proof_image_id");
  await attr("activity_logs", "string",  "rejection_reason",      { size: 500 });
  await attr("activity_logs", "string",  "plant_species");
  await attr("activity_logs", "string",  "community_id");
  await attr("activity_logs", "string",  "created_at");
  await sleep(2000); // wait for attributes before indexes
  await ensureIndex("activity_logs", "idx_plant_id",     ["plant_id"],     ["ASC"]);
  await ensureIndex("activity_logs", "idx_user_id",      ["user_id"],      ["ASC"]);
  await ensureIndex("activity_logs", "idx_community_id", ["community_id"], ["ASC"]);
  await sleep(1000);

  // ──────────────────────────────────
  // 9. DRIVES (Plantation Drives)
  // ──────────────────────────────────
  console.log("9/15 drives");
  await ensureCollection("drives", "Plantation Drives");
  await attr("drives", "string",  "title");
  await attr("drives", "string",  "org_name");
  await attr("drives", "string",  "status",        { size: 20, default: "active" });
  await attr("drives", "integer", "target_count",  { default: 0 });
  await attr("drives", "integer", "alive_count",   { default: 0 });
  await attr("drives", "string",  "start_date");
  await sleep(1000);

  // ──────────────────────────────────
  // 10. REWARDS
  // ──────────────────────────────────
  console.log("10/15 rewards");
  await ensureCollection("rewards", "Rewards Catalog");
  await attr("rewards", "string",  "title");
  await attr("rewards", "integer", "cost_coins",   { default: 0 });
  await attr("rewards", "integer", "stock",        { default: 0 });
  await sleep(1000);

  // ──────────────────────────────────
  // 11. NOTIFICATIONS
  // ──────────────────────────────────
  console.log("11/15 notifications");
  await ensureCollection("notifications", "Notifications");
  await attr("notifications", "string",  "recipient_id");
  await attr("notifications", "string",  "sender_id");
  await attr("notifications", "string",  "type",                   { size: 50 });
  await attr("notifications", "string",  "title");
  await attr("notifications", "string",  "body",                   { size: 1000 });
  await attr("notifications", "string",  "linked_post_id");
  await attr("notifications", "string",  "linked_community_id");
  await attr("notifications", "string",  "linked_plant_id");
  await attr("notifications", "string",  "plant_name");
  await attr("notifications", "string",  "plant_location");
  await attr("notifications", "string",  "schedule_frequency",     { size: 20, default: "none" });
  await attr("notifications", "integer", "custom_interval_days");
  await attr("notifications", "string",  "next_scheduled_at");
  await attr("notifications", "boolean", "is_recurring",           { default: false });
  await attr("notifications", "boolean", "is_read",                { default: false });
  await attr("notifications", "string",  "created_at");
  await sleep(1000);

  // ──────────────────────────────────
  // 12. USER FCM TOKENS
  // ──────────────────────────────────
  console.log("12/15 user_fcm_tokens");
  await ensureCollection("user_fcm_tokens", "User FCM Tokens");
  await attr("user_fcm_tokens", "string", "user_id");
  await attr("user_fcm_tokens", "string", "fcm_token",        { size: 500 });
  await attr("user_fcm_tokens", "string", "device_platform",  { size: 20 });
  await attr("user_fcm_tokens", "string", "updated_at");
  await sleep(1000);

  // ──────────────────────────────────
  // 13. MY GARDEN QR CODES
  // ──────────────────────────────────
  console.log("13/15 my_garden_qr_codes");
  await ensureCollection("my_garden_qr_codes", "My Garden QR Codes");
  await attr("my_garden_qr_codes", "string",  "unique_code");
  await attr("my_garden_qr_codes", "string",  "plant_name");
  await attr("my_garden_qr_codes", "string",  "local_name");
  await attr("my_garden_qr_codes", "string",  "category",         { size: 50 });
  await attr("my_garden_qr_codes", "string",  "best_season",      { size: 50 });
  await attr("my_garden_qr_codes", "string",  "qr_type",          { size: 20 });
  await attr("my_garden_qr_codes", "string",  "plant_age");
  await attr("my_garden_qr_codes", "string",  "notes",            { size: 1000 });
  await attr("my_garden_qr_codes", "string",  "owner_id");
  await attr("my_garden_qr_codes", "string",  "owner_name");
  await attr("my_garden_qr_codes", "string",  "owner_email");
  await attr("my_garden_qr_codes", "string",  "garden_id");
  await attr("my_garden_qr_codes", "string",  "source",           { size: 50, default: "my_garden" });
  await attr("my_garden_qr_codes", "string",  "created_at");
  await attr("my_garden_qr_codes", "float",   "location_lat");
  await attr("my_garden_qr_codes", "float",   "location_long");
  await attr("my_garden_qr_codes", "string",  "image_file_id");
  await attr("my_garden_qr_codes", "string",  "image_url",        { size: 500 });
  await attr("my_garden_qr_codes", "string",  "planted_at");
  await sleep(1000);

  // ──────────────────────────────────
  // 14. ADMIN QR CODES
  // ──────────────────────────────────
  console.log("14/15 admin_qr_codes");
  await ensureCollection("admin_qr_codes", "Admin QR Codes");
  await attr("admin_qr_codes", "string",  "community_id");
  await attr("admin_qr_codes", "string",  "community_name");
  await attr("admin_qr_codes", "string",  "plant_name");
  await attr("admin_qr_codes", "string",  "plant_type",      { size: 50 });
  await attr("admin_qr_codes", "string",  "best_season",     { size: 50 });
  await attr("admin_qr_codes", "boolean", "is_seed",         { default: true });
  await attr("admin_qr_codes", "string",  "plant_age");
  await attr("admin_qr_codes", "string",  "notes",           { size: 1000 });
  await attr("admin_qr_codes", "string",  "qr_data",         { size: 500 });
  await attr("admin_qr_codes", "boolean", "is_uploaded",     { default: false });
  await attr("admin_qr_codes", "string",  "created_at");
  await sleep(1000);

  // ──────────────────────────────────
  // 15. SYSTEM LOGS
  // ──────────────────────────────────
  console.log("15/15 system_logs");
  await ensureCollection("system_logs", "System Logs");
  await attr("system_logs", "string", "action",        { size: 500 });
  await attr("system_logs", "string", "performed_by");
  await attr("system_logs", "string", "level",         { size: 20, default: "INFO" });
  await attr("system_logs", "string", "details",       { size: 2000 });
  await attr("system_logs", "string", "created_at");

  // ──────────────────────────────────
  // 16. CUSTOM TASKS
  // ──────────────────────────────────
  console.log("16/16 custom_tasks");
  await ensureCollection("custom_tasks", "Custom Tasks");
  await attr("custom_tasks", "string",  "title",        { size: 255, required: true });
  await attr("custom_tasks", "string",  "description",  { size: 1000, required: true });
  await attr("custom_tasks", "string",  "category",     { size: 50, required: true });
  await attr("custom_tasks", "string",  "priority",     { size: 50, required: true });
  await attr("custom_tasks", "integer", "points",       { required: true });
  await attr("custom_tasks", "string",  "target_type",  { size: 100, required: true });
  await attr("custom_tasks", "string",  "target_value", { size: 255, required: false });
  await attr("custom_tasks", "datetime", "created_at",  { required: true });
  await sleep(1000);

  console.log("\n═══ Setup complete! ═══");
  console.log("All 16 collections are ready.");

  // ──────────────────────────────────
  // STORAGE BUCKETS
  // ──────────────────────────────────
  console.log("\nCreating storage buckets...");
  await ensureBucket("plant_images", "Plant Images");
  await ensureBucket("community_media", "Community Media");
  console.log("Storage buckets ready.\n");
}

main().catch(console.error);
