# Vercel API Enhancement Implementation Guide

## Overview
This guide will help you enhance your existing Vercel API to integrate the processed knowledge base for better RAG (Retrieval Augmented Generation) responses.

## Step 1: Update Your Vercel API

### Replace/Update `/api/enhanced-chat.js` in your Vercel project

1. **Copy the enhanced API code** from `vercel_api_enhancement.js` to your Vercel project
2. **Replace your current** `/api/enhanced-chat.js` file with the enhanced version
3. **Update the AI service integration** in the `callAIService` function to use your actual Grok API

### Key Enhancements Added:

- **Knowledge Base Storage**: In-memory knowledge store with categories and states
- **Intelligent Search**: Context-aware knowledge retrieval with similarity scoring
- **PUT Endpoint**: New endpoint for uploading knowledge base data
- **Enhanced Context**: Automatic extraction of state, category, and urgency from user messages
- **Metadata Tracking**: Confidence scores, retrieval times, and knowledge source tracking

## Step 2: Deploy the Enhanced API

### Option A: Manual Deployment
1. Copy `vercel_api_enhancement.js` content to your Vercel project
2. Update the `callAIService` function with your Grok API integration:

```javascript
async function callAIService(systemPrompt, messages) {
  const apiKey = process.env.XAI_API_KEY; // set in Vercel project env — never commit the real key
  const apiURL = "https://api.x.ai/v1/chat/completions";
  
  // Construct the messages array with systemPrompt as the first message
  const fullMessages = [
    { role: "system", content: systemPrompt },
    ...messages
  ];
  
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
      temperature: 0
    })
  });
  
  if (!response.ok) {
    throw new Error(`AI API Error: ${response.status}`);
  }
  
  const data = await response.json();
  return data.choices[0]?.message?.content || "Sorry, I couldn't generate a response.";
}
```

3. Deploy to Vercel using `vercel --prod`

### Option B: Automatic Deployment (if you have CLI access)
```bash
cd your-vercel-project
cp /Users/phillipholland/Documents/GCP-xcodebackups/1.0.12/Gentler\ Coparent/vercel_api_enhancement.js pages/api/enhanced-chat.js
# Update the callAIService function as shown above
vercel --prod
```

## Step 3: Upload Your Knowledge Base

Once your enhanced API is deployed, run the deployment script:

```bash
cd "/Users/phillipholland/Documents/GCP-xcodebackups/1.0.12/Gentler Coparent"
python3 deploy_knowledge.py
```

This script will:
- ✅ Test API connectivity
- 📚 Upload all 144 knowledge chunks
- 🧪 Test enhanced retrieval with sample queries
- 📊 Report deployment success metrics

## Step 4: Verify Integration

### Test Queries to Try:
1. **State-specific**: "What are the custody modification requirements in California?"
2. **Co-parenting**: "How should I handle communication conflicts with my ex-spouse?"
3. **Safety**: "What should I do if I suspect domestic violence?"
4. **Legal**: "Can child support be modified without going to court?"

### Expected Improvements:
- **More accurate responses** based on legal statutes
- **State-specific guidance** automatically detected
- **Source citations** showing which knowledge was used
- **Higher confidence scores** for well-matched queries

## Step 5: Monitor and Optimize

### Key Metrics to Watch:
- **Knowledge Usage**: How often knowledge chunks are retrieved
- **Confidence Scores**: Average confidence of responses
- **Retrieval Time**: Speed of knowledge lookup
- **User Satisfaction**: Quality of responses

### Optimization Options:
1. **Adjust similarity thresholds** for better matching
2. **Add more knowledge sources** for gaps in coverage
3. **Implement embeddings** for better semantic search
4. **Add user feedback loops** to improve relevance

## Troubleshooting

### Common Issues:

**1. API Upload Fails (405 Error)**
- Ensure the enhanced API is deployed with PUT method support
- Check that the endpoint URL is correct

**2. Knowledge Not Retrieved**
- Verify knowledge upload was successful
- Check similarity threshold settings
- Test with more specific queries

**3. Slow Responses**
- Consider implementing caching for frequently accessed knowledge
- Optimize similarity calculation algorithm
- Use external vector database for large knowledge bases

### Debug Commands:
```bash
# Test API status
curl -X GET https://gentler-coparent-simple-rag.vercel.app/api/enhanced-chat

# Test knowledge upload
python3 deploy_knowledge.py

# Test enhanced retrieval
curl -X POST https://gentler-coparent-simple-rag.vercel.app/api/enhanced-chat \
  -H "Content-Type: application/json" \
  -d '{"message": "custody laws in Texas"}'
```

## Expected Results

After successful implementation:
- ✅ **144 knowledge chunks** available for retrieval
- ✅ **5 categories** of content (state law, co-parenting, psychology, legal docs, case studies)
- ✅ **23 states** covered with specific legal guidance
- ✅ **Intelligent context detection** for better responses
- ✅ **Source attribution** for knowledge-based answers

Your RAG system will now provide significantly more accurate, legally-informed, and contextually appropriate responses for co-parenting situations!