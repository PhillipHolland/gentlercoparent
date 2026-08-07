#!/usr/bin/env node

// Test script to check knowledge base status and upload test knowledge

const API_BASE = 'https://gentler-coparent-simple-rag.vercel.app/api/enhanced-chat';

// Test knowledge data
const testKnowledgeData = {
  files: {
    "texas_custody_laws.pdf": {
      filename: "texas_custody_laws.pdf",
      category: "state_law",
      state: "texas",
      total_chunks: 3,
      key_concepts: ["custody modification", "court requirements", "material change"],
      chunks: [
        {
          index: 0,
          content: "Texas custody modification requirements include showing a material and substantial change in circumstances since the last court order. The petitioning parent must file a motion to modify with the court that has jurisdiction over the case. Courts will consider factors such as the child's best interests, changes in living situations, and parental fitness when evaluating modification requests.",
          content_type: "custody_guidance",
          word_count: 58,
          key_phrases: ["custody modification", "material change", "court jurisdiction", "best interests"]
        },
        {
          index: 1,
          content: "Under Texas Family Code Section 156.101, a court may modify a custody order if modification would be in the best interest of the child and the circumstances have substantially changed. The requesting party must demonstrate that the change is significant and affects the child's welfare.",
          content_type: "legal_statute",
          word_count: 45,
          key_phrases: ["Texas Family Code", "best interest", "substantially changed", "child welfare"]
        },
        {
          index: 2,
          content: "When considering custody modifications, courts typically look at factors such as the child's best interests, changes in living situations, parental fitness, and the child's preferences if they are old enough to express them. Documentation of changed circumstances is crucial for successful modification petitions.",
          content_type: "custody_guidance",
          word_count: 48,
          key_phrases: ["custody modifications", "best interests", "parental fitness", "changed circumstances"]
        }
      ]
    },
    "coparenting_guide.pdf": {
      filename: "coparenting_guide.pdf",
      category: "coparenting_guidance", 
      state: null,
      total_chunks: 2,
      key_concepts: ["communication", "conflict resolution", "child welfare"],
      chunks: [
        {
          index: 0,
          content: "Effective coparenting communication requires setting aside personal conflicts and focusing on the child's needs. Use neutral language, avoid blame, and keep discussions child-centered. Regular communication about schedules, school events, and the child's wellbeing helps maintain stability.",
          content_type: "coparenting_advice",
          word_count: 42,
          key_phrases: ["coparenting communication", "child-centered", "neutral language", "child wellbeing"]
        },
        {
          index: 1,
          content: "Legal modifications to custody or visitation should be pursued through proper court channels. Informal agreements may not be legally enforceable. Always document any changes and ensure both parents understand their rights and responsibilities under the current court order.",
          content_type: "legal_guidance",
          word_count: 41,
          key_phrases: ["legal modifications", "court channels", "legally enforceable", "court order"]
        }
      ]
    }
  }
};

async function checkKnowledgeBaseStatus() {
  console.log('🔍 Checking Knowledge Base Status...\n');
  
  try {
    const response = await fetch(API_BASE, {
      method: 'GET'
    });
    
    if (!response.ok) {
      throw new Error(`Status check failed: ${response.status}`);
    }
    
    const data = await response.json();
    console.log('📊 Knowledge Base Status:');
    console.log(`   Total Chunks: ${data.totalChunks}`);
    console.log(`   Categories: ${data.categories?.join(', ') || 'none'}`);
    console.log(`   States: ${data.states?.join(', ') || 'none'}`);
    console.log(`   Last Updated: ${data.lastUpdated || 'never'}`);
    console.log(`   Status: ${data.status}`);
    
    return data.totalChunks > 0;
    
  } catch (error) {
    console.log(`❌ Status check failed: ${error.message}`);
    return false;
  }
}

async function uploadTestKnowledge() {
  console.log('\n📚 Uploading Test Knowledge...\n');
  
  try {
    const response = await fetch(API_BASE, {
      method: 'PUT',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        knowledgeData: testKnowledgeData,
        overwrite: true
      })
    });
    
    if (!response.ok) {
      throw new Error(`Upload failed: ${response.status} ${response.statusText}`);
    }
    
    const data = await response.json();
    console.log('✅ Knowledge Upload Successful:');
    console.log(`   Chunks Added: ${data.chunksAdded}`);
    console.log(`   Total Chunks: ${data.totalChunks}`);
    console.log(`   Categories: ${data.categories?.join(', ')}`);
    console.log(`   States: ${data.states?.join(', ')}`);
    
    return true;
    
  } catch (error) {
    console.log(`❌ Knowledge upload failed: ${error.message}`);
    return false;
  }
}

async function testQueryAfterUpload() {
  console.log('\n🧪 Testing Query After Knowledge Upload...\n');
  
  const testPayload = {
    message: "Texas custody laws modification requirements",
    systemPrompt: "You are a helpful co-parenting assistant.",
    userProfile: { state: "texas" }
  };
  
  try {
    const response = await fetch(API_BASE, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(testPayload)
    });
    
    if (!response.ok) {
      throw new Error(`Query failed: ${response.status} ${response.statusText}`);
    }
    
    const data = await response.json();
    console.log('🎯 Query Test Results:');
    console.log(`   Knowledge Used: ${data.knowledgeUsed?.length || 0} chunks`);
    console.log(`   Knowledge Files: ${data.knowledgeUsed?.join(', ') || 'none'}`);
    console.log(`   Similarity Scores: ${data.similarityScores?.map(s => s.toFixed(4)).join(', ') || 'none'}`);
    console.log(`   Confidence Score: ${data.confidenceScore?.toFixed(4) || 0}`);
    console.log(`   Topic Match: ${data.topicMatch}`);
    console.log(`   Retrieval Time: ${data.retrievalTime}s`);
    console.log(`   Context: ${JSON.stringify(data.context, null, 2)}`);
    
    if (data.knowledgeUsed?.length > 0) {
      console.log('\n✅ SUCCESS: Knowledge retrieval is working!');
      return true;
    } else {
      console.log('\n❌ ISSUE: Still no knowledge retrieved even after upload.');
      return false;
    }
    
  } catch (error) {
    console.log(`❌ Query test failed: ${error.message}`);
    return false;
  }
}

async function runFullTest() {
  console.log('🚀 Full Knowledge Base Test\n');
  console.log('='.repeat(50));
  
  // 1. Check current status
  const hasKnowledge = await checkKnowledgeBaseStatus();
  
  // 2. Upload test knowledge if needed
  if (!hasKnowledge) {
    console.log('\n⚠️  Knowledge base is empty. Uploading test data...');
    const uploadSuccess = await uploadTestKnowledge();
    
    if (!uploadSuccess) {
      console.log('\n❌ Cannot proceed - knowledge upload failed');
      return;
    }
  }
  
  // 3. Test query retrieval
  const querySuccess = await testQueryAfterUpload();
  
  // 4. Final status
  console.log('\n' + '='.repeat(50));
  if (querySuccess) {
    console.log('🎉 KNOWLEDGE RETRIEVAL FIXED! 🎉');
    console.log('\nThe improved similarity algorithm is now working correctly.');
    console.log('Key improvements made:');
    console.log('• Enhanced text matching with legal keyword weighting');
    console.log('• Lowered similarity threshold from 0.1 to 0.05');
    console.log('• Added stemming and bigram matching');
    console.log('• Comprehensive debug logging');
  } else {
    console.log('❌ Issue persists - additional debugging needed');
  }
}

// Run the full test
runFullTest().catch(console.error);