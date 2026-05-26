const admin = require('firebase-admin');
const path = require('path');
const fs = require('fs');

const serviceAccount = require('./firebase-key.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function run() {
  const command = process.argv[2];
  const arg1 = process.argv[3];
  const arg2 = process.argv[4];

  try {
    switch (command) {
      case 'get-doc':
        const doc = await db.doc(arg1).get();
        console.log(JSON.stringify(doc.data(), null, 2));
        break;
      case 'list-docs':
        const snapshot = await db.collection(arg1).get();
        const docs = snapshot.docs.map(d => ({id: d.id, ...d.data()}));
        console.log(JSON.stringify(docs, null, 2));
        break;
      case 'query':
        // Simple query: collection, field, value
        const qSnapshot = await db.collection(arg1).where(arg2, '==', process.argv[5]).get();
        const qDocs = qSnapshot.docs.map(d => ({id: d.id, ...d.data()}));
        console.log(JSON.stringify(qDocs, null, 2));
        break;
      default:
        console.log("Unknown command");
    }
  } catch (e) {
    console.error(e);
  } finally {
    process.exit();
  }
}

run();
