#!/usr/bin/env node

// Test script for the enhanced chat API
// This script tests the improved similarity algorithm and knowledge retrieval

const testQueries = [
  "Texas custody laws modification requirements",
  "How to modify child custody in Texas",
  "Court requirements for custody changes",
  "Legal requirements for visitation changes",
  "Child support modification process"
];

// Mock knowledge base for testing
const mockKnowledgeBase = {
  chunks: [
    {
      id: "texas_custody_1",
      filename: "texas_custody_laws.pdf",
      category: "state_law",
      state: "texas",
      content: "Texas custody modification requirements include showing a material and substantial change in circumstances since the last court order. The petitioning parent must file a motion to modify with the court that has jurisdiction over the case.",
      content_type: "custody_guidance",
      word_count: 35
    },
    {
      id: "texas_custody_2", 
      filename: "texas_family_code.pdf",
      category: "legal_documents",
      state: "texas",
      content: "Under Texas Family Code Section 156.101, a court may modify a custody order if modification would be in the best interest of the child and the circumstances have substantially changed.",
      content_type: "legal_statute",
      word_count: 31
    },
    {
      id: "general_custody_1",
      filename: "custody_guide.pdf", 
      category: "coparenting_guidance",
      state: null,
      content: "When considering custody modifications, courts typically look at factors such as the child's best interests, changes in living situations, parental fitness, and the child's preferences if they are old enough.",
      content_type: "custody_guidance",
      word_count: 34
    }
  ],
  categories: {},
  states: {},
  lastUpdated: new Date().toISOString()
};

// Import and test the similarity function
function testSimilarityAlgorithm() {
  console.log("🧪 Testing Enhanced Similarity Algorithm\n");
  console.log("=".repeat(50));
  
  // Test query
  const query = "Texas custody laws modification requirements";
  
  testQueries.forEach((testQuery, index) => {
    console.log(`\nTest ${index + 1}: "${testQuery}"`);
    console.log("-".repeat(40));
    
    mockKnowledgeBase.chunks.forEach(chunk => {
      const similarity = calculateSimilarity(testQuery, chunk.content);
        console.log(`${chunk.filename}: ${similarity.toFixed(4)} (${chunk.category}, ${chunk.state || 'general'})`);
      console.log(`  Content: ${chunk.content.substring(0, 80)}...`);
    });
  });
}

// Enhanced similarity calculation for legal text matching (copied from API)
function calculateSimilarity(query, content) {
  // Normalize and tokenize text
  const normalizeText = (text) => text.toLowerCase()
    .replace(/[^\w\s]/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();
  
  const queryNorm = normalizeText(query);
  const contentNorm = normalizeText(content);
  
  const queryWords = queryNorm.split(' ').filter(word => word.length > 1);
  const contentWords = contentNorm.split(' ').filter(word => word.length > 1);
  
  if (queryWords.length === 0 || contentWords.length === 0) return 0;
  
  // Legal keywords get higher weight
  const legalKeywords = [
    'custody', 'visitation', 'support', 'court', 'judge', 'order', 'modification',
    'parenting', 'time', 'child', 'legal', 'law', 'statute', 'code', 'requirement',
    'filing', 'petition', 'motion', 'hearing', 'agreement', 'divorce', 'separation'
  ];
  
  // Simple stemming for common legal terms
  const stemWord = (word) => {
    if (word.endsWith('ing')) return word.slice(0, -3);
    if (word.endsWith('ed')) return word.slice(0, -2);
    if (word.endsWith('s') && word.length > 3) return word.slice(0, -1);
    return word;
  };
  
  const queryStemmed = queryWords.map(stemWord);
  const contentStemmed = contentWords.map(stemWord);
  
  // 1. Exact word matches with legal keyword weighting
  let exactMatches = 0;
  let weightedMatches = 0;
  
  queryStemmed.forEach(qWord => {
    if (contentStemmed.includes(qWord)) {
      exactMatches++;
      weightedMatches += legalKeywords.includes(qWord) ? 3 : 1;
    }
  });
  
  // 2. Partial matches (substring matching)
  let partialMatches = 0;
  queryStemmed.forEach(qWord => {
    if (qWord.length > 3) {
      contentStemmed.forEach(cWord => {
        if (cWord.includes(qWord) || qWord.includes(cWord)) {
          partialMatches += 0.5;
        }
      });
    }
  });
  
  // 3. Bigram matching for legal phrases
  const getBigrams = (words) => {
    const bigrams = [];
    for (let i = 0; i < words.length - 1; i++) {
      bigrams.push(words[i] + ' ' + words[i + 1]);
    }
    return bigrams;
  };
  
  const queryBigrams = getBigrams(queryStemmed);
  const contentBigrams = getBigrams(contentStemmed);
  
  let bigramMatches = 0;
  queryBigrams.forEach(qBigram => {
    if (contentBigrams.some(cBigram => 
      cBigram.includes(qBigram) || qBigram.includes(cBigram))) {
      bigramMatches += 2; // Bigrams are more valuable
    }
  });
  
  // 4. Calculate final score
  const totalMatches = weightedMatches + partialMatches + bigramMatches;
  const maxPossibleScore = queryWords.length * 3; // Max if all words are legal keywords
  
  let similarity = totalMatches / maxPossibleScore;
  
  // 5. Boost score for content containing query as substring
  if (contentNorm.includes(queryNorm) || queryNorm.includes(contentNorm)) {
    similarity += 0.2;
  }
  
  // 6. Length normalization bonus for shorter, more focused content
  const lengthRatio = Math.min(contentWords.length, queryWords.length) / 
                     Math.max(contentWords.length, queryWords.length);
  if (lengthRatio > 0.5) {
    similarity += 0.1;
  }
  
  return Math.min(similarity, 1.0);
}

// Test the API with a sample request
async function testAPI() {
  console.log("\n🌐 Testing API Endpoint\n");
  console.log("=".repeat(50));
  
  const testPayload = {
    message: "Texas custody laws modification requirements",
    systemPrompt: "You are a helpful co-parenting assistant.",
    userProfile: { state: "texas" }
  };
  
  try {
    const response = await fetch('https://gentler-coparent-simple-rag.vercel.app/api/enhanced-chat', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(testPayload)
    });
    
    if (!response.ok) {
      console.log(`❌ API request failed: ${response.status} ${response.statusText}`);
      return;
    }
    
    const data = await response.json();
    console.log("✅ API Response:");
    console.log(`   Knowledge Used: ${data.knowledgeUsed?.length || 0} chunks`);
    console.log(`   Similarity Scores: ${data.similarityScores?.map(s => s.toFixed(4)).join(', ') || 'none'}`);
    console.log(`   Confidence Score: ${data.confidenceScore?.toFixed(4) || 0}`);
    console.log(`   Retrieval Time: ${data.retrievalTime || 0}s`);
    
  } catch (error) {
    console.log(`❌ API test failed: ${error.message}`);
    console.log("Note: Make sure the API is running locally with 'npm run dev' or similar");
  }
}

// Run tests
async function runTests() {
  console.log("🚀 Testing Enhanced Chat API Improvements");
  console.log("==========================================\n");
  
  // Test similarity algorithm with mock data
  testSimilarityAlgorithm();
  
  // Test actual API (if running)
  await testAPI();
  
  console.log("\n✅ Test suite completed!");
  console.log("\nNext steps:");
  console.log("1. Deploy the updated API to Vercel");
  console.log("2. Test with the deployed endpoint");
  console.log("3. Monitor logs for debug output");
}

// Run the tests
runTests().catch(console.error);