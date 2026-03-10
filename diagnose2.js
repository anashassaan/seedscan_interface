const sdk = require('node-appwrite');
const c = new sdk.Client();
c.setEndpoint('https://sgp.cloud.appwrite.io/v1')
 .setProject('6971de42002712d649b2')
 .setKey('standard_8aa48787aedff6156ea1aa8a108ee7c52e19d56d9219bd4d1ef96606ac3e28b840ddafce5e3ee88c02630838fc51e86d15fe90945ea1ab2eb5814584d49d686ca677d2f771c48daae9fdcb78fc522cfeed263d5028bfb627a560541b8a4fc09c8b78abeafa02dacf97d91ed9cdf89eca0f111bce80f5c6e10c70c525dee12440');
const db = new sdk.Databases(c);

async function main() {
  // 1. Users
  const users = await db.listDocuments('seedscan_main_db', 'users', [sdk.Query.limit(100)]);
  console.log('=== USERS (' + users.documents.length + ') ===');
  users.documents.forEach(u => {
    console.log(JSON.stringify({ doc_id: u['$id'], name: u.name, email: u.email, role: u.role }));
  });

  // 2. Communities
  const comms = await db.listDocuments('seedscan_main_db', 'communities', [sdk.Query.limit(100)]);
  console.log('\n=== COMMUNITIES (' + comms.documents.length + ') ===');
  comms.documents.forEach(cc => {
    console.log(JSON.stringify({ id: cc['$id'], name: cc.name, plant_count: cc.plant_count }));
  });

  // 3. Community members
  const members = await db.listDocuments('seedscan_main_db', 'community_members', [sdk.Query.limit(100)]);
  console.log('\n=== COMMUNITY_MEMBERS (' + members.documents.length + ') ===');
  members.documents.forEach(m => {
    console.log(JSON.stringify({ user_id: m.user_id, community_id: m.community_id, role: m.role }));
  });

  // 4. Plants
  const plants = await db.listDocuments('seedscan_main_db', 'plants', [sdk.Query.limit(100)]);
  console.log('\n=== PLANTS (' + plants.documents.length + ') ===');
  plants.documents.forEach(p => {
    console.log(JSON.stringify({ id: p['$id'], guardian_id: p.guardian_id, drive_id: p.drive_id, species: p.species }));
  });

  // 5. Activity logs
  const logs = await db.listDocuments('seedscan_main_db', 'activity_logs', [sdk.Query.limit(100), sdk.Query.orderDesc('$createdAt')]);
  console.log('\n=== ACTIVITY_LOGS (' + logs.documents.length + ') ===');
  logs.documents.forEach(l => {
    console.log(JSON.stringify({ user_id: l.user_id, plant_id: l.plant_id, action: l.action_type, coins: l.coins_awarded, species: l.plant_species, created: l['$createdAt'] }));
  });
}
main().catch(e => console.error('ERROR:', e.message));
