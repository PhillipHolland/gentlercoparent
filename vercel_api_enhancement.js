// Enhanced Chat API with Knowledge Base Integration
// This should replace or enhance your existing /api/enhanced-chat endpoint

import { promises as fs } from 'fs';
import path from 'path';

// In-memory knowledge store (you might want to use a database in production)
let knowledgeBase = {
  chunks: [],
  categories: {},
  states: {},
  lastUpdated: null
};

// Vector similarity helper (simplified - you might want to use a proper embeddings service)
function calculateSimilarity(text1, text2) {
  const words1 = text1.toLowerCase().split(/\W+/);
  const words2 = text2.toLowerCase().split(/\W+/);
  
  const set1 = new Set(words1);
  const set2 = new Set(words2);
  
  const intersection = new Set([...set1].filter(x => set2.has(x)));
  const union = new Set([...set1, ...set2]);
  
  return intersection.size / union.size;
}

// Enhanced knowledge search with metadata filtering
function searchKnowledge(query, options = {}) {
  const {
    category = null,
    state = null,
    contentType = null,
    minSimilarity = 0.1,
    maxResults = 5
  } = options;
  
  let candidates = knowledgeBase.chunks;
  
  // Filter by metadata if specified
  if (category) {
    candidates = candidates.filter(chunk => chunk.category === category);
  }
  
  if (state) {
    candidates = candidates.filter(chunk => 
      chunk.state && chunk.state.toLowerCase() === state.toLowerCase()
    );
  }
  
  if (contentType) {
    candidates = candidates.filter(chunk => chunk.content_type === contentType);
  }
  
  // Calculate similarity scores
  const results = candidates.map(chunk => ({
    ...chunk,
    similarity: calculateSimilarity(query, chunk.content)
  }))
  .filter(chunk => chunk.similarity >= minSimilarity)
  .sort((a, b) => b.similarity - a.similarity)
  .slice(0, maxResults);
  
  return results;
}

// Extract user context from message
function extractContext(message, userProfile = {}) {
  const context = {
    state: null,
    category: 'general',
    contentType: null,
    urgency: 'normal'
  };
  
  const messageLower = message.toLowerCase();
  
  // Extract state information
  const states = [
    'alabama', 'alaska', 'arizona', 'arkansas', 'california', 'colorado',
    'connecticut', 'delaware', 'florida', 'georgia', 'hawaii', 'idaho',
    'illinois', 'indiana', 'iowa', 'kansas', 'kentucky', 'louisiana',
    'maine', 'maryland', 'massachusetts', 'michigan', 'minnesota',
    'mississippi', 'missouri', 'montana', 'nebraska', 'nevada',
    'new hampshire', 'new jersey', 'new mexico', 'new york',
    'north carolina', 'north dakota', 'ohio', 'oklahoma', 'oregon',
    'pennsylvania', 'rhode island', 'south carolina', 'south dakota',
    'tennessee', 'texas', 'utah', 'vermont', 'virginia', 'washington',
    'west virginia', 'wisconsin', 'wyoming'
  ];
  
  for (const state of states) {
    if (messageLower.includes(state)) {
      context.state = state;
      break;
    }
  }
  
  // Use user profile state if not found in message
  if (!context.state && userProfile.state) {
    context.state = userProfile.state.toLowerCase();
  }
  
  // Determine category from keywords
  if (messageLower.match(/(custody|visitation|parenting time|court order)/)) {
    context.category = 'state_law';
    context.contentType = 'custody_guidance';
  } else if (messageLower.match(/(child support|payment|financial)/)) {
    context.category = 'state_law';
    context.contentType = 'financial_guidance';
  } else if (messageLower.match(/(abuse|safety|domestic violence|protection)/)) {
    context.category = 'behavioral_psychology';
    context.contentType = 'safety_information';
  } else if (messageLower.match(/(communication|conflict|cooperation|coparenting)/)) {
    context.category = 'coparenting_guidance';
    context.contentType = 'coparenting_advice';
  } else if (messageLower.match(/(legal|statute|law|code|court)/)) {
    context.category = 'legal_documents';
    context.contentType = 'legal_statute';
  }
  
  // Detect urgency
  if (messageLower.match(/(urgent|emergency|immediately|asap|help)/)) {
    context.urgency = 'high';
  }
  
  return context;
}

// Main API handler
export default async function handler(req, res) {
  if (req.method === 'POST') {
    try {
      const { message, systemPrompt, messages, userProfile } = req.body;
      
      if (!message) {
        return res.status(400).json({ error: 'Message is required' });
      }
      
      console.log('🔍 Processing enhanced chat request...');
      console.log('📝 Message:', message.substring(0, 100) + '...');
      
      // Extract context from the user's message
      const context = extractContext(message, userProfile);
      console.log('🎯 Extracted context:', context);
      
      // Search knowledge base
      const startTime = Date.now();
      const knowledgeResults = searchKnowledge(message, {
        category: context.category !== 'general' ? context.category : null,
        state: context.state,
        contentType: context.contentType,
        maxResults: context.urgency === 'high' ? 7 : 5
      });
      const retrievalTime = (Date.now() - startTime) / 1000;
      
      console.log(`📚 Found ${knowledgeResults.length} relevant knowledge chunks in ${retrievalTime}s`);
      
      // Build enhanced system prompt with retrieved knowledge
      let enhancedSystemPrompt = systemPrompt || 'You are a helpful co-parenting assistant.';
      
      if (knowledgeResults.length > 0) {
        enhancedSystemPrompt += '\n\n**RELEVANT KNOWLEDGE:**\n';
        
        knowledgeResults.forEach((chunk, index) => {
          enhancedSystemPrompt += `\n${index + 1}. **${chunk.category.replace('_', ' ').toUpperCase()}** `;
          if (chunk.state) {
            enhancedSystemPrompt += `(${chunk.state}) `;
          }
          enhancedSystemPrompt += `[Confidence: ${(chunk.similarity * 100).toFixed(1)}%]\n`;
          enhancedSystemPrompt += `${chunk.content}\n`;
          enhancedSystemPrompt += '---\n';
        });
        
        enhancedSystemPrompt += '\n**INSTRUCTIONS:** Use this knowledge to provide accurate, helpful responses. Always cite relevant legal requirements and co-parenting best practices from the knowledge above.';
      }
      
      // Call external AI service (Grok, OpenAI, etc.)
      const aiResponse = await callAIService(enhancedSystemPrompt, messages || [{ role: 'user', content: message }]);
      
      // Prepare response with metadata
      const response = {
        response: aiResponse,
        knowledgeUsed: knowledgeResults.map(chunk => `${chunk.filename} (${chunk.category})`),
        similarityScores: knowledgeResults.map(chunk => chunk.similarity),
        retrievalTime,
        context,
        topicMatch: knowledgeResults.length > 0,
        confidenceScore: knowledgeResults.length > 0 ? 
          knowledgeResults.reduce((sum, chunk) => sum + chunk.similarity, 0) / knowledgeResults.length : 0
      };
      
      console.log('✅ Enhanced chat response generated successfully');
      res.status(200).json(response);
      
    } catch (error) {
      console.error('❌ Enhanced chat error:', error);
      res.status(500).json({ 
        error: 'Failed to process enhanced chat request',
        details: error.message 
      });
    }
  } else if (req.method === 'PUT') {
    // Knowledge base upload endpoint
    try {
      const { knowledgeData, category, overwrite = false } = req.body;
      
      if (!knowledgeData) {
        return res.status(400).json({ error: 'Knowledge data is required' });
      }
      
      console.log('📚 Uploading knowledge base...');
      
      if (overwrite) {
        knowledgeBase = {
          chunks: [],
          categories: {},
          states: {},
          lastUpdated: null
        };
      }
      
      let chunksAdded = 0;
      
      // Process uploaded knowledge data
      if (knowledgeData.files) {
        // Handle structured knowledge base format
        Object.values(knowledgeData.files).forEach(fileData => {
          fileData.chunks.forEach(chunk => {
            const knowledgeChunk = {
              id: `${fileData.filename}_${chunk.index}`,
              filename: fileData.filename,
              category: fileData.category,
              state: fileData.state,
              content: chunk.content,
              content_type: chunk.content_type,
              word_count: chunk.word_count,
              key_phrases: chunk.key_phrases || [],
              priority: determinePriority(fileData.category),
              metadata: {
                chunk_index: chunk.index,
                total_chunks: fileData.total_chunks,
                key_concepts: fileData.key_concepts || []
              }
            };
            
            knowledgeBase.chunks.push(knowledgeChunk);
            chunksAdded++;
          });
        });
      } else if (Array.isArray(knowledgeData)) {
        // Handle simple array format
        knowledgeData.forEach(chunk => {
          knowledgeBase.chunks.push(chunk);
          chunksAdded++;
        });
      }
      
      // Update metadata
      knowledgeBase.lastUpdated = new Date().toISOString();
      
      // Rebuild category and state indexes
      knowledgeBase.categories = {};
      knowledgeBase.states = {};
      
      knowledgeBase.chunks.forEach(chunk => {
        // Category index
        if (!knowledgeBase.categories[chunk.category]) {
          knowledgeBase.categories[chunk.category] = [];
        }
        knowledgeBase.categories[chunk.category].push(chunk.id);
        
        // State index
        if (chunk.state) {
          if (!knowledgeBase.states[chunk.state]) {
            knowledgeBase.states[chunk.state] = [];
          }
          knowledgeBase.states[chunk.state].push(chunk.id);
        }
      });
      
      console.log(`✅ Knowledge base updated: ${chunksAdded} chunks added`);
      
      res.status(200).json({
        success: true,
        chunksAdded,
        totalChunks: knowledgeBase.chunks.length,
        categories: Object.keys(knowledgeBase.categories),
        states: Object.keys(knowledgeBase.states),
        lastUpdated: knowledgeBase.lastUpdated
      });
      
    } catch (error) {
      console.error('❌ Knowledge upload error:', error);
      res.status(500).json({ 
        error: 'Failed to upload knowledge base',
        details: error.message 
      });
    }
  } else if (req.method === 'GET') {
    // Knowledge base status endpoint
    res.status(200).json({
      totalChunks: knowledgeBase.chunks.length,
      categories: Object.keys(knowledgeBase.categories),
      states: Object.keys(knowledgeBase.states),
      lastUpdated: knowledgeBase.lastUpdated
    });
  } else {
    res.status(405).json({ error: 'Method not allowed' });
  }
}

// Helper function to determine priority
function determinePriority(category) {
  const priorityMap = {
    'coparenting_guidance': 1,
    'state_law': 2,
    'behavioral_psychology': 2,
    'legal_documents': 3,
    'case_studies': 4,
    'general': 5
  };
  return priorityMap[category] || 5;
}

// AI service call (replace with your actual implementation)
async function callAIService(systemPrompt, messages) {
  // This would call your actual AI service (Grok, OpenAI, etc.)
  // For now, returning a placeholder
  return "This would be the AI-generated response based on the enhanced system prompt with retrieved knowledge.";
}