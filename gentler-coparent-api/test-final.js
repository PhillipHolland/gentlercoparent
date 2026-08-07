#!/usr/bin/env node

// Final test with the exact query mentioned in the issue

const API_BASE = 'https://gentler-coparent-simple-rag.vercel.app/api/enhanced-chat';

async function testOriginalQuery() {
  console.log('🧪 Testing Original Problematic Query\n');
  console.log('='.repeat(50));
  console.log('Query: "Texas custody laws modification requirements"');
  console.log('Expected: Should now return knowledge chunks with similarity scores > 0');
  console.log('-'.repeat(50));
  
  const testPayload = {
    message: "Texas custody laws modification requirements",
    systemPrompt: "You are a helpful co-parenting assistant providing compassionate, practical guidance for divorced and separated parents.",
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
    
    console.log('\n📊 RESULTS:');
    console.log(`✅ Knowledge Used: ${data.knowledgeUsed?.length || 0} chunks`);
    console.log(`✅ Similarity Scores: [${data.similarityScores?.map(s => s.toFixed(4)).join(', ') || 'none'}]`);
    console.log(`✅ Confidence Score: ${data.confidenceScore?.toFixed(4) || 0}`);
    console.log(`✅ Topic Match: ${data.topicMatch}`);
    console.log(`✅ Retrieval Time: ${data.retrievalTime}s`);
    
    console.log('\n📝 Context Analysis:');
    console.log(`   State: ${data.context?.state || 'not detected'}`);
    console.log(`   Category: ${data.context?.category || 'general'}`);
    console.log(`   Content Type: ${data.context?.contentType || 'not specified'}`);
    
    console.log('\n📚 Knowledge Files Used:');
    if (data.knowledgeUsed && data.knowledgeUsed.length > 0) {
      data.knowledgeUsed.forEach((file, index) => {
        console.log(`   ${index + 1}. ${file} (similarity: ${data.similarityScores[index]?.toFixed(4)})`);
      });
    } else {
      console.log('   None');
    }
    
    console.log('\n' + '='.repeat(50));
    
    if (data.knowledgeUsed?.length > 0 && data.confidenceScore > 0) {
      console.log('🎉 SUCCESS: Issue has been RESOLVED! 🎉');
      console.log('\nBEFORE (broken):');
      console.log('• "knowledgeUsed": []');
      console.log('• "similarityScores": []'); 
      console.log('• "confidenceScore": 0');
      
      console.log('\nAFTER (fixed):');
      console.log(`• "knowledgeUsed": ${JSON.stringify(data.knowledgeUsed)}`);
      console.log(`• "similarityScores": ${JSON.stringify(data.similarityScores?.map(s => parseFloat(s.toFixed(4))))}`);
      console.log(`• "confidenceScore": ${data.confidenceScore?.toFixed(4)}`);
      
      return true;
    } else {
      console.log('❌ Issue not fully resolved - still getting empty results');
      return false;
    }
    
  } catch (error) {
    console.log(`❌ Test failed: ${error.message}`);
    return false;
  }
}

// Additional test with different query types
async function testVariousQueries() {
  console.log('\n🔍 Testing Various Query Types\n');
  console.log('='.repeat(50));
  
  const queries = [
    { query: "How to modify custody in Texas", expectedKeywords: ["modify", "custody", "texas"] },
    { query: "Court requirements for visitation changes", expectedKeywords: ["court", "visitation", "changes"] },
    { query: "Child support modification process", expectedKeywords: ["child", "support", "modification"] },
    { query: "Coparenting communication tips", expectedKeywords: ["coparenting", "communication"] }
  ];
  
  let successCount = 0;
  
  for (const test of queries) {
    console.log(`\nTesting: "${test.query}"`);
    
    try {
      const response = await fetch(API_BASE, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          message: test.query,
          userProfile: { state: "texas" }
        })
      });
      
      const data = await response.json();
      const hasResults = data.knowledgeUsed?.length > 0;
      
      console.log(`   Results: ${hasResults ? '✅' : '❌'} ${data.knowledgeUsed?.length || 0} chunks (confidence: ${data.confidenceScore?.toFixed(4) || 0})`);
      
      if (hasResults) successCount++;
      
    } catch (error) {
      console.log(`   Error: ❌ ${error.message}`);
    }
  }
  
  console.log(`\nOverall Success Rate: ${successCount}/${queries.length} (${Math.round(successCount/queries.length*100)}%)`);
  return successCount >= queries.length * 0.75; // 75% success rate threshold
}

async function runFinalTest() {
  console.log('🚀 FINAL VERIFICATION TEST');
  console.log('Testing the deployed fix for knowledge retrieval issue\n');
  
  const primaryTestPassed = await testOriginalQuery();
  const varietyTestPassed = await testVariousQueries();
  
  console.log('\n' + '='.repeat(60));
  console.log('🎯 FINAL ASSESSMENT');
  console.log('='.repeat(60));
  
  if (primaryTestPassed && varietyTestPassed) {
    console.log('🎉 ALL TESTS PASSED! 🎉');
    console.log('\n✅ The knowledge retrieval issue has been successfully FIXED!');
    console.log('\nSUMMARY OF IMPROVEMENTS:');
    console.log('1. ✅ Enhanced similarity algorithm with legal keyword weighting');
    console.log('2. ✅ Lowered similarity threshold from 0.1 to 0.05');
    console.log('3. ✅ Added stemming and bigram matching for better text analysis');
    console.log('4. ✅ Implemented comprehensive debug logging');
    console.log('5. ✅ Successfully deployed to Vercel production environment');
    console.log('\nThe API now correctly identifies and returns relevant knowledge chunks!');
  } else {
    console.log('⚠️  PARTIAL SUCCESS');
    console.log(`Primary test: ${primaryTestPassed ? '✅ PASSED' : '❌ FAILED'}`);
    console.log(`Variety test: ${varietyTestPassed ? '✅ PASSED' : '❌ FAILED'}`);
    console.log('\nSome improvements are working, but further refinement may be needed.');
  }
}

runFinalTest().catch(console.error);