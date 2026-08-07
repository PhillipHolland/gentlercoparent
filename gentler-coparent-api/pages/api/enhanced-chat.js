// Enhanced Chat API with Knowledge Base Integration
// Gentler Coparent RAG System — expert identity + seed knowledge for cold starts

const GCP_IDENTITY = `You are **Gentler Coparent** (GCP), the AI assistant in the Gentler Coparent app.
IDENTITY (NON-NEGOTIABLE): Never say you are Grok, xAI, OpenAI, ChatGPT, Claude, Gemini, Llama, or any other model/provider. Never mention training companies. If asked what model you are, say: "I'm Gentler Coparent (GCP), your co-parenting communication assistant."
ROLE: Expert co-parenting and high-conflict post-separation communication coach. Children first. Businesslike communication. Not a lawyer or therapist.
HIGH-CONFLICT: Prefer parallel parenting when hostility is high. Use BIFF-style message drafts (Brief, Informative, Friendly, Firm). Gray rock when baited. Do not push couples counseling when abuse/coercive control is present. Prioritize safety and documentation.
LEGAL: Do not invent statutes. Urge users to confirm legal rights with a family-law attorney in their state.
STYLE: Practical, structured, use real names when provided. Send-ready drafts first when rewriting.`;

// Compact high-conflict / co-parenting playbooks always available (even before bulk upload)
const SEED_CHUNKS = [
  {
    id: "seed-parallel-parenting",
    filename: "playbook_parallel_parenting.txt",
    category: "coparenting_guidance",
    content_type: "coparenting_advice",
    state: null,
    content: "Parallel parenting is appropriate when cooperative co-parenting fails due to high conflict or hostility. Minimize direct interaction; use written communication for logistics only; separate calendars and drop-offs if needed; decisions stay in court-ordered lanes; do not use children as messengers. Goal: reduce conflict exposure for children, not win arguments with the other parent."
  },
  {
    id: "seed-biff",
    filename: "playbook_biff_messages.txt",
    category: "coparenting_guidance",
    content_type: "coparenting_advice",
    state: null,
    content: "BIFF communication for high-conflict co-parents: Brief (few sentences), Informative (facts/dates/logistics only), Friendly (civil, not sarcastic), Firm (clear request or boundary without threats). Avoid blame, history lectures, and emotional bait. Example: 'Confirming pickup Friday at 5:00 PM at the school. Reply yes if that works.'"
  },
  {
    id: "seed-no-counseling-dv",
    filename: "playbook_no_couples_counseling_dv.txt",
    category: "behavioral_psychology",
    content_type: "safety_information",
    state: null,
    content: "Couples counseling and unstructured joint mediation are often inappropriate or dangerous when domestic violence, coercive control, intimidation, or fear is present. Prioritize safety planning, documentation, and professional/legal resources. Do not coach the survivor to 'communicate better' as if the problem is mutual miscommunication."
  },
  {
    id: "seed-documentation",
    filename: "playbook_documentation.txt",
    category: "coparenting_guidance",
    content_type: "coparenting_advice",
    state: null,
    content: "In high conflict, document: dates, times, what was said/written, missed exchanges, expenses with receipts. Keep copies of messages. Summaries should be factual, not insulting. Documentation supports court, counsel, or parenting coordinators without escalating the chat thread."
  },
  {
    id: "seed-expenses",
    filename: "playbook_expenses.txt",
    category: "coparenting_guidance",
    content_type: "financial_guidance",
    state: null,
    content: "Discuss expenses with clarity: name the expense, amount, date incurred, why it is a shared/child-related cost, attach or offer receipt, propose a fair split and payment deadline/method. Avoid moralizing. If the order defines reimbursements, cite the relevant provision if known; otherwise suggest checking the decree with counsel."
  },
  {
    id: "seed-alienation-caution",
    filename: "playbook_children_and_conflict.txt",
    category: "behavioral_psychology",
    content_type: "safety_information",
    state: null,
    content: "Protect children from adult conflict: no badmouthing the other parent to the child, no interrogating the child about the other home, no using the child as messenger or spy. Support the child's right to love both parents when safe. Gatekeeping and alienation concerns need careful, evidence-based handling—do not invent accusations."
  },
  {
    id: "seed-rewrite",
    filename: "playbook_message_rewrite.txt",
    category: "coparenting_guidance",
    content_type: "coparenting_advice",
    state: null,
    content: "When rewriting a parent's draft: remove insults and absolute language; convert accusations to observations of logistics; keep one clear ask; use adult-to-adult business tone; offer a send-ready draft the user can copy. Explain changes in one short sentence."
  },
  {
    id: "seed-boundaries",
    filename: "playbook_boundaries.txt",
    category: "behavioral_psychology",
    content_type: "coparenting_advice",
    state: null,
    content: "Boundaries in high conflict: specify channels (e.g. parenting app only), topics (child logistics only), response windows, and that personal attacks will not be engaged. Enforce by not debating bait; restate the logistics ask once. Boundaries protect energy and children; they are not revenge."
  },
  {
    id: "seed-gray-rock",
    filename: "playbook_gray_rock.txt",
    category: "behavioral_psychology",
    content_type: "coparenting_advice",
    state: null,
    content: "Gray rock technique for high-conflict co-parents: respond with short, dull, factual answers on logistics only. Do not share personal details, emotions, or defenses that feed drama. Example: 'Received. Pickup is Friday 5 PM at school.' Useful when the other parent seeks reaction; not a substitute for safety planning if abuse is present."
  },
  {
    id: "seed-holidays",
    filename: "playbook_holidays_exchanges.txt",
    category: "coparenting_guidance",
    content_type: "coparenting_advice",
    state: null,
    content: "Holiday and exchange planning: propose one clear plan early (date, time, location, who transports). Reference the order if known. Avoid reopening old grievances in the same message. If the other parent rejects, offer one alternate and document. Keep kids out of adult negotiations."
  },
  {
    id: "seed-school-medical",
    filename: "playbook_school_medical.txt",
    category: "coparenting_guidance",
    content_type: "coparenting_advice",
    state: null,
    content: "School and medical logistics: share facts (appointment time, provider, forms due), confirm who attends, and request confirmation. Both parents should generally receive school notices when rights allow; do not use children as the only channel. For medical emergencies, prioritize the child's care first, then notify the other parent factually."
  }
];

function ensureSeedKnowledge() {
  if (!knowledgeBase.chunks || knowledgeBase.chunks.length === 0) {
    knowledgeBase.chunks = SEED_CHUNKS.map(c => ({ ...c }));
    knowledgeBase.categories = {};
    knowledgeBase.states = {};
    knowledgeBase.chunks.forEach(chunk => {
      if (!knowledgeBase.categories[chunk.category]) knowledgeBase.categories[chunk.category] = [];
      knowledgeBase.categories[chunk.category].push(chunk.id);
    });
    knowledgeBase.lastUpdated = new Date().toISOString();
    console.log(`🌱 Seeded ${knowledgeBase.chunks.length} expert playbook chunks for cold start`);
  }
}

// In-memory knowledge store (bulk upload can extend; seed always present)
let knowledgeBase = {
  chunks: [],
  categories: {},
  states: {},
  lastUpdated: null
};
ensureSeedKnowledge();

// Enhanced similarity calculation for legal text matching
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
    'filing', 'petition', 'motion', 'hearing', 'agreement', 'divorce', 'separation',
    'conflict', 'hostile', 'boundary', 'boundaries', 'abuse', 'violence', 'alienation',
    'parallel', 'biff', 'expense', 'reimburse', 'schedule', 'exchange', 'narcissist',
    'control', 'safety', 'protection', 'mediation', 'supervised', 'contempt'
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

// Enhanced knowledge search with metadata filtering
function searchKnowledge(query, options = {}) {
  ensureSeedKnowledge();
  const {
    category = null,
    state = null,
    contentType = null,
    minSimilarity = 0.05,  // Lowered threshold for more flexible matching
    maxResults = 5
  } = options;
  
  console.log(`🔍 Knowledge Search Debug:`);
  console.log(`   Query: "${query}"`);
  console.log(`   Options:`, { category, state, contentType, minSimilarity, maxResults });
  console.log(`   Total chunks in knowledge base: ${knowledgeBase.chunks.length}`);
  
  let candidates = knowledgeBase.chunks;
  
  // Debug: Show sample chunk structure
  if (candidates.length > 0) {
    console.log(`   Sample chunk structure:`, {
      id: candidates[0].id,
      category: candidates[0].category,
      state: candidates[0].state,
      content_type: candidates[0].content_type,
      contentPreview: candidates[0].content?.substring(0, 100) + '...'
    });
  }
  
  // Filter by metadata if specified
  if (category) {
    const beforeCount = candidates.length;
    candidates = candidates.filter(chunk => chunk.category === category);
    console.log(`   Filtered by category '${category}': ${beforeCount} -> ${candidates.length}`);
  }
  
  if (state) {
    const beforeCount = candidates.length;
    candidates = candidates.filter(chunk => 
      chunk.state && chunk.state.toLowerCase() === state.toLowerCase()
    );
    console.log(`   Filtered by state '${state}': ${beforeCount} -> ${candidates.length}`);
  }
  
  if (contentType) {
    const beforeCount = candidates.length;
    candidates = candidates.filter(chunk => chunk.content_type === contentType);
    console.log(`   Filtered by content_type '${contentType}': ${beforeCount} -> ${candidates.length}`);
  }
  
  console.log(`   Candidate chunks for similarity calculation: ${candidates.length}`);
  
  // Calculate similarity scores with detailed logging
  const scoredResults = candidates.map((chunk, index) => {
    const similarity = calculateSimilarity(query, chunk.content);
    
    // Log first few similarity calculations in detail
    if (index < 3) {
      console.log(`   Chunk ${index + 1} similarity: ${similarity.toFixed(4)} (${chunk.filename || chunk.id})`);
      console.log(`     Content preview: "${chunk.content?.substring(0, 80)}..."`);
    }
    
    return {
      ...chunk,
      similarity
    };
  });
  
  // Filter by minimum similarity
  const aboveThreshold = scoredResults.filter(chunk => chunk.similarity >= minSimilarity);
  console.log(`   Chunks above similarity threshold (${minSimilarity}): ${aboveThreshold.length}`);
  
  if (aboveThreshold.length > 0) {
    const topScores = aboveThreshold.slice(0, Math.min(5, aboveThreshold.length))
      .map(chunk => `${chunk.similarity.toFixed(4)} (${chunk.filename || chunk.id})`);
    console.log(`   Top similarity scores: ${topScores.join(', ')}`);
  } else {
    console.log(`   ⚠️  No chunks met minimum similarity threshold!`);
    // Show top 3 scores even if they don't meet threshold
    const top3 = scoredResults
      .sort((a, b) => b.similarity - a.similarity)
      .slice(0, 3)
      .map(chunk => `${chunk.similarity.toFixed(4)} (${chunk.filename || chunk.id})`);
    console.log(`   Top 3 scores (below threshold): ${top3.join(', ')}`);
  }
  
  // Sort and limit results
  const results = aboveThreshold
    .sort((a, b) => b.similarity - a.similarity)
    .slice(0, maxResults);
  
  console.log(`   Final results returned: ${results.length}`);
  
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
  } else if (messageLower.match(/(abuse|safety|domestic violence|protection|coercive|threat|scared|afraid)/)) {
    context.category = 'behavioral_psychology';
    context.contentType = 'safety_information';
  } else if (messageLower.match(/(high.?conflict|hostile|narciss|alienat|boundary|boundaries|parallel|biff|grey rock|gray rock)/)) {
    context.category = 'coparenting_guidance';
    context.contentType = 'coparenting_advice';
  } else if (messageLower.match(/(communication|conflict|cooperation|coparenting|message|rewrite|tone)/)) {
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


function sanitizeIdentity(text) {
  if (!text || typeof text !== 'string') return text;
  let t = text;
  // Never let the model identify as Grok/xAI/OpenAI/etc. to users.
  t = t.replace(/\bI(?:'m| am) (?:an? )?(?:AI )?(?:assistant |language model )?(?:called |named )?(?:Grok|ChatGPT|Claude|Gemini|Llama|Copilot)\b[^.!?\n]*[.!?]?/gi,
    "I'm Gentler Coparent (GCP), your co-parenting communication assistant.");
  t = t.replace(/\bI(?:'m| am) (?:built|created|developed|made|trained) by (?:xAI|OpenAI|Anthropic|Google|Meta)\b[^.!?\n]*[.!?]?/gi,
    "I'm Gentler Coparent (GCP).");
  t = t.replace(/\bmy (?:name is|creators? (?:are|is)|developers? (?:are|is)) (?:Grok|xAI|OpenAI|ChatGPT|Claude|Anthropic)\b[^.!?\n]*[.!?]?/gi,
    "I'm Gentler Coparent (GCP).");
  t = t.replace(/\bas (?:an? )?(?:AI )?(?:assistant )?(?:from )?(?:Grok|xAI|OpenAI|ChatGPT|Claude|Gemini|Anthropic)\b/gi, 'as Gentler Coparent');
  t = t.replace(/\bpowered by (?:Grok|xAI|OpenAI|Anthropic|ChatGPT|Claude|Gemini)[^.!?\n]*[.!?]?/gi, '');
  t = t.replace(/\bbuilt (?:on|with|using) (?:Grok|xAI|OpenAI|Anthropic|ChatGPT|Claude)\b[^.!?\n]*[.!?]?/gi, '');
  t = t.replace(/\b(?:Grok|ChatGPT|Claude|Gemini)[- ]?(?:4(?:\.\d+)?|3(?:\.\d+)?|2(?:\.\d+)?|Pro|Ultra|Max)?\b/gi, 'Gentler Coparent');
  t = t.replace(/\bxAI\b/gi, 'Gentler Coparent');
  t = t.replace(/\bOpenAI\b/gi, 'our systems');
  t = t.replace(/\bAnthropic\b/gi, 'our systems');
  t = t.replace(/\bChatGPT\b/gi, 'an AI assistant');
  t = t.replace(/\bGrok\b/gi, 'Gentler Coparent');
  t = t.replace(/\bClaude\b/gi, 'Gentler Coparent');
  t = t.replace(/\bGemini\b/gi, 'Gentler Coparent');
  t = t.replace(/\bLlama\b/gi, 'Gentler Coparent');
  return t.replace(/\n{3,}/g, '\n\n').trim();
}

// AI service call with cloud AI integration and enhanced error handling
async function callAIService(systemPrompt, messages) {
  const apiKey = process.env.XAI_API_KEY || process.env.GROK_API_KEY || "";
  if (!apiKey) {
    throw new Error("Missing XAI_API_KEY (or GROK_API_KEY) environment variable");
  }
  const apiURL = "https://api.x.ai/v1/chat/completions";
  
  // Limit system prompt size to prevent API timeouts
  // Higher budget so long decree context + knowledge can coexist (model supports large prompts)
  const maxPromptLength = 48000;
  let finalSystemPrompt = systemPrompt;
  
  if (systemPrompt.length > maxPromptLength) {
    console.log(`🔧 Truncating system prompt from ${systemPrompt.length} to ${maxPromptLength} characters`);
    // Prefer keeping identity + user/decree context; trim knowledge chunks first
    const knowledgeSplit = systemPrompt.split('**RELEVANT KNOWLEDGE');
    if (knowledgeSplit.length > 1) {
      const core = knowledgeSplit[0];
      const knowledge = knowledgeSplit.slice(1).join('**RELEVANT KNOWLEDGE');
      const available = Math.max(2000, maxPromptLength - core.length - 200);
      finalSystemPrompt = core + '**RELEVANT KNOWLEDGE' + knowledge.substring(0, available)
        + '\n\n**NOTE**: Knowledge truncated; decree/user context retained when present.';
    } else {
      // Keep the end (often user context) and start (identity)
      const head = Math.floor(maxPromptLength * 0.55);
      const tail = maxPromptLength - head - 40;
      finalSystemPrompt = systemPrompt.substring(0, head)
        + '\n\n…[middle truncated]…\n\n'
        + systemPrompt.substring(systemPrompt.length - tail);
    }
  }
  
  // Construct the messages array with systemPrompt as the first message
  const fullMessages = [
    { role: "system", content: finalSystemPrompt },
    ...messages
  ];
  
  // Create AbortController for timeout handling
  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), 25000); // 25 second timeout
  
  try {
    console.log(`🤖 Calling cloud AI API with ${finalSystemPrompt.length} char prompt...`);
    
    const response = await fetch(apiURL, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${apiKey}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        messages: fullMessages,
        model: "grok-4.5",
        stream: false,
        temperature: 0,
        max_tokens: 4000 // Reasonable response limit
      }),
      signal: controller.signal
    });
    
    clearTimeout(timeoutId);
    
    if (!response.ok) {
      const errorText = await response.text().catch(() => 'Unknown error');
      console.error(`❌ Grok API HTTP ${response.status}: ${errorText}`);
      throw new Error(`AI API Error: ${response.status} - ${errorText}`);
    }
    
    const data = await response.json();
    const content = data.choices?.[0]?.message?.content;
    
    if (!content) {
      console.error('❌ No content in Grok API response:', data);
      throw new Error('No content returned from AI API');
    }
    
    console.log(`✅ Grok API success: ${content.length} characters returned`);
    return content;
    
  } catch (error) {
    clearTimeout(timeoutId);
    
    if (error.name === 'AbortError') {
      console.error('❌ Grok API timeout after 25 seconds');
      return "I apologize, but my response is taking longer than expected. Could you please try rephrasing your question or breaking it into smaller parts?";
    }
    
    console.error('❌ Grok API Error:', error.message);
    
    // Provide more helpful error messages based on the type of error
    if (error.message.includes('401')) {
      return "I'm experiencing authentication issues with my AI service. Please try again in a moment.";
    } else if (error.message.includes('429')) {
      return "I'm currently experiencing high demand. Please wait a moment and try again.";
    } else if (error.message.includes('timeout') || error.message.includes('network')) {
      return "I'm having trouble connecting to my AI service. Please check your internet connection and try again.";
    }
    
    return "I encountered a technical issue while processing your request. Please try rephrasing your question or contact support if this continues.";
  }
}

// Build enhanced user context for personalized responses
function buildEnhancedUserContext(userProfile, message) {
  let context = "\n\n**USER CONTEXT:**\n";
  
  // User and co-parent names
  if (userProfile.userFirstName) {
    context += `User's name: ${userProfile.userFirstName}${userProfile.userLastName ? ' ' + userProfile.userLastName : ''}\n`;
  }
  if (userProfile.coparentFirstName) {
    context += `Co-parent's name: ${userProfile.coparentFirstName}${userProfile.coparentLastName ? ' ' + userProfile.coparentLastName : ''}\n`;
  }
  
  // State information for legal guidance
  if (userProfile.stateOfResidence) {
    context += `State of residence: ${userProfile.stateOfResidence}\n`;
  }
  
  // Schedule / custody notes from profile (often OCR-filled)
  if (userProfile.possessionSchedule) {
    context += `Custody / schedule notes:\n${String(userProfile.possessionSchedule).slice(0, 1000)}\n`;
  }
  
  // Decree excerpt (private — in prompt only, not stored in knowledge base)
  if (userProfile.decreeExcerpt) {
    const total = userProfile.decreeCharCount || String(userProfile.decreeExcerpt).length;
    context += `\n**Decree on file (${total} chars total; excerpt in prompt):**\n${String(userProfile.decreeExcerpt).slice(0, 5000)}\n`;
    context += `(Prefer these facts over generic law; not legal advice. Full extract is on the user's device.)\n`;
  }
  
  // Children information
  if (userProfile.children && userProfile.children.length > 0) {
    context += `Children: `;
    userProfile.children.forEach((child, index) => {
      context += child.firstName || `Child ${index + 1}`;
      if (child.age !== undefined) {
        context += ` (age ${child.age})`;
      }
      if (index < userProfile.children.length - 1) {
        context += ", ";
      }
    });
    context += "\n";
  }
  
  // Conflict level 1–10 (matches iOS profile setup)
  if (userProfile.conflictLevel !== undefined) {
    const level = Number(userProfile.conflictLevel) || 5;
    let band = "tense";
    let label = "Moderate tension";
    let policy = "Neutral diplomatic tone; structured proposals.";
    if (level <= 3) {
      band = "cooperative";
      label = "Cooperative / low conflict";
      policy = "Warm collaborative tone; shared goals; keep kids out of adult issues.";
    } else if (level >= 7) {
      band = "highConflict";
      label = "High conflict";
      policy = "Parallel parenting default; BIFF-style drafts; facts only; safety over forced cooperation.";
    }
    context += `Conflict level (1-10): ${level} → ${label}\n`;
    context += `Active policy mode: ${band}\n`;
    context += `Policy: ${policy}\n`;
  }
  
  // Possession schedule if available
  if (userProfile.possessionSchedule) {
    context += `Custody schedule: ${userProfile.possessionSchedule}\n`;
  }
  
  context += "\n**PERSONALIZATION INSTRUCTIONS:**\n";
  context += "- Use the actual names provided (don't use placeholders like [Name])\n";
  context += "- Follow conflict policy mode above\n";
  context += "- Consider the children's ages when giving advice\n";
  context += "- You are only Gentler Coparent (GCP); never claim to be Grok or any other AI brand\n";
  context += "- Not legal advice; suggest local counsel for statute-specific rights\n";
  
  return context;
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

// Main API handler
export default async function handler(req, res) {
  // Set CORS headers
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');
  
  if (req.method === 'OPTIONS') {
    res.status(200).end();
    return;
  }
  
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
      console.log(`\n🔍 Starting knowledge base search...`);
      console.log(`📊 Knowledge base stats: ${knowledgeBase.chunks.length} total chunks`);
      
      const startTime = Date.now();
      const knowledgeResults = searchKnowledge(message, {
        category: context.category !== 'general' ? context.category : null,
        state: context.state,
        contentType: context.contentType,
        maxResults: context.urgency === 'high' ? 7 : 5
      });
      const retrievalTime = (Date.now() - startTime) / 1000;
      
      console.log(`\n📚 Knowledge search completed:`);
      console.log(`   Found ${knowledgeResults.length} relevant knowledge chunks in ${retrievalTime}s`);
      
      if (knowledgeResults.length === 0) {
        console.log(`❌ NO KNOWLEDGE FOUND - This indicates the similarity algorithm may be too strict`);
        console.log(`   Consider lowering similarity threshold or improving text matching`);
      } else {
        console.log(`✅ Knowledge retrieved successfully:`)
        knowledgeResults.forEach((result, i) => {
          console.log(`   ${i + 1}. ${result.filename} (similarity: ${result.similarity.toFixed(4)})`);
        });
      }
      
      // Always ensure seed playbooks exist (serverless cold start)
      ensureSeedKnowledge();
      
      // Build enhanced system prompt: force GCP identity, never Grok/provider names
      let enhancedSystemPrompt = (systemPrompt && systemPrompt.length > 40)
        ? systemPrompt
        : GCP_IDENTITY;
      if (!enhancedSystemPrompt.includes('Gentler Coparent') && !enhancedSystemPrompt.includes('GCP')) {
        enhancedSystemPrompt = GCP_IDENTITY + '\n\n' + enhancedSystemPrompt;
      }
      enhancedSystemPrompt += '\n\n**IDENTITY LOCK:** You are only Gentler Coparent (GCP). Never name Grok, xAI, OpenAI, ChatGPT, Claude, or any other model.';
      
      // Add user profile context
      if (userProfile) {
        enhancedSystemPrompt += buildEnhancedUserContext(userProfile, message);
      }
      
      if (knowledgeResults.length > 0) {
        enhancedSystemPrompt += '\n\n**RELEVANT KNOWLEDGE (use when applicable; safety overrides):**\n';
        
        knowledgeResults.forEach((chunk, index) => {
          const cat = (chunk.category || 'general').replace('_', ' ').toUpperCase();
          enhancedSystemPrompt += `\n${index + 1}. **${cat}** `;
          if (chunk.state) {
            enhancedSystemPrompt += `(${chunk.state}) `;
          }
          enhancedSystemPrompt += `[Relevance: ${(chunk.similarity * 100).toFixed(1)}%]\n`;
          enhancedSystemPrompt += `${chunk.content}\n`;
          enhancedSystemPrompt += '---\n';
        });
        
        enhancedSystemPrompt += '\n**INSTRUCTIONS:** Prefer this knowledge for accuracy. Stay as Gentler Coparent. Be practical; include a sample message when rewriting or drafting. Not legal advice.';
      }
      
      // Call AI service
      const aiResponseRaw = await callAIService(enhancedSystemPrompt, messages || [{ role: 'user', content: message }]);
      const aiResponse = sanitizeIdentity(aiResponseRaw);
      
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
      lastUpdated: knowledgeBase.lastUpdated,
      status: 'Enhanced RAG API Active'
    });
  } else {
    res.status(405).json({ error: 'Method not allowed' });
  }
}